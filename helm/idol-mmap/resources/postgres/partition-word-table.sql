/**
  insertWord automatically creates child tables of the word table based on date and stream.
  This improves query speed when constraint_exclusion is enabled (which is the default) as the query planner
  can quickly discard tables that can't contain results.
  It also removes the need to rebuild indexes after deletion expired content, as an entire day can be expired by
  dropping the whole table
  Hibernate fails if an insert doesn't effect any rows, so this function returns a copy of NEW with a modified id
  this is then inserted into the parent table. We set up a second trigger to call deleteDuplicateFromParentTable
  which will remove this duplicate.
 */

CREATE OR REPLACE FUNCTION insertWord()
  RETURNS trigger AS
$BODY$
DECLARE
_tablename text;
_startdate text;
_enddate text;
BEGIN
_startdate := to_char(NEW."starttime", 'YYYY-MM-DD');

-- Construct child table name. Postgres limits table names to 63 chars, so truncate where required before appending date
_tablename := left('word_' || NEW.stream, 52) || '_' || _startdate;

-- Check if the partition needed for the current record exists
PERFORM 1
FROM   pg_catalog.pg_class c
JOIN   pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE  c.relkind = 'r'
AND    c.relname = _tablename
AND    n.nspname = 'public';

-- If the partition needed does not yet exist, then we create it:
IF NOT FOUND THEN
  _enddate:=_startdate::timestamp + INTERVAL '1 day';
  EXECUTE 'CREATE TABLE '|| quote_ident(_tablename) ||' ( CHECK ( "stream" = '|| quote_literal(NEW.stream) || ' AND starttime >= ' || quote_literal(_startdate) || ' AND starttime < ' || quote_literal(_enddate) ||' )) INHERITS (word)';

  -- Indexes are defined per child table so we add them now (including one for the primary key)
  EXECUTE 'CREATE INDEX ON ' || quote_ident(_tablename) || ' USING btree (stream COLLATE pg_catalog."default", starttime, endtime)';
  EXECUTE 'CREATE INDEX ON ' || quote_ident(_tablename) || ' USING btree (stream COLLATE pg_catalog."default", starttime, id COLLATE pg_catalog."default", endtime)';
  EXECUTE 'CREATE INDEX ON ' || quote_ident(_tablename) || ' USING btree (id COLLATE pg_catalog."default")';
  EXECUTE 'CREATE INDEX ON ' || quote_ident(_tablename) || ' USING btree (stream COLLATE pg_catalog."default", lower(text::text) COLLATE pg_catalog."default", starttime)';
END IF;

-- Insert the row into the correct child table
EXECUTE 'INSERT INTO public.' || quote_ident(_tablename) || ' VALUES ($1.*)' USING NEW;

-- return a fake duplicate that can satisfy hibernate, will be deleted by deleteDuplicateFromParentTable
NEW.id := 'temp_' || quote_literal(NEW.id);
RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

/**
  Add insert trigger to word table to enable automatic partitioning
 */
CREATE TRIGGER word_partition_trigger BEFORE INSERT ON word FOR EACH ROW EXECUTE PROCEDURE insertWord();

CREATE OR REPLACE FUNCTION deleteDuplicateFromParentTable()
  RETURNS trigger AS
$BODY$
BEGIN
  EXECUTE 'DELETE FROM word where word.id = ' || quote_literal(NEW.id);
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER word_partition_after_insert_trigger AFTER INSERT ON public.word FOR EACH ROW EXECUTE PROCEDURE deleteDuplicateFromParentTable();

/**
  function for expiring words older than the given day
 */

CREATE OR REPLACE FUNCTION expirewordsbefore(startdate text)
  RETURNS void AS
$BODY$
DECLARE
  _result record;
BEGIN
  RAISE NOTICE 'deleting words before: %', startdate;
  FOR _result IN SELECT child.relname  AS child FROM pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child             ON pg_inherits.inhrelid   = child.oid
    JOIN pg_namespace nmsp_parent   ON nmsp_parent.oid  = parent.relnamespace
    JOIN pg_namespace nmsp_child    ON nmsp_child.oid   = child.relnamespace
  WHERE parent.relname='word' LOOP
    IF startdate::timestamp > to_timestamp(right(_result.child, 10), 'YYYY-MM-DD') THEN
      RAISE NOTICE 'dropping table: %', _result.child;
     EXECUTE 'DROP TABLE ' || quote_ident(_result.child);
    END IF;
  END LOOP;
END;
$BODY$
LANGUAGE plpgsql;


/**
  function for expiring content older than the given number of days.
 */
CREATE OR REPLACE FUNCTION expireolderthan(days integer)
  RETURNS void AS
$BODY$
DECLARE
  _startdate text;
  _interval text;
  _result record;
BEGIN
  _startdate := CURRENT_DATE;
  _interval = days || ' day';
  _startdate := to_char(_startdate::timestamp - _interval::INTERVAL, 'YYYY-MM-DD');

  EXECUTE 'select expirewordsbefore(' || quote_literal(_startdate) || ')';
  EXECUTE 'delete from keyframe where time < ' || quote_literal(_startdate);
  EXECUTE 'delete from videoevent where starttime < ' || quote_literal(_startdate);

END;
$BODY$
LANGUAGE plpgsql;