/**
  Finds newest keyframes where minTime <= startTime < maxTime, spaced out at intervalSeconds
 */
CREATE OR REPLACE FUNCTION getNewestKeyframes(
  streamName      VARCHAR,
  minTime         TIMESTAMP,
  maxTime         TIMESTAMP,
  intervalSeconds INTEGER,
  maxResults      INTEGER
)
  RETURNS SETOF keyframe AS $BODY$
DECLARE
  rec                keyframe%ROWTYPE;
  last_time          TIMESTAMP;
  i                  INTEGER;
  intervalAsInterval INTERVAL;
BEGIN
  i := 0;
  intervalAsInterval := intervalSeconds * INTERVAL '1 second';

  FOR rec IN (
    SELECT
      *
    FROM keyframe
    WHERE time >= minTime
          AND time < maxTime
          AND stream = streamName
    ORDER BY time DESC
  )
  LOOP
    IF last_time IS NULL OR (last_time - intervalAsInterval) >= rec.time
    THEN
      last_time := rec.time;

      RETURN NEXT rec;

      i := i + 1;
      EXIT WHEN i >= maxResults;
    END IF;

  END LOOP;
END;
$BODY$ LANGUAGE plpgsql;

/**
  Finds oldest keyframes where minTime <= startTime < maxTime, spaced out at intervalSeconds
 */
CREATE OR REPLACE FUNCTION getOldestKeyframes(
  streamName      VARCHAR,
  minTime         TIMESTAMP,
  maxTime         TIMESTAMP,
  intervalSeconds INTEGER,
  maxResults      INTEGER
)
  RETURNS SETOF keyframe AS $BODY$
DECLARE
  rec       keyframe%ROWTYPE;
  last_time TIMESTAMP;
  i         INTEGER;
  intervalAsInterval INTERVAL;
BEGIN
  i := 0;
  intervalAsInterval := intervalSeconds * INTERVAL '1 second';

  FOR rec IN (
    SELECT
      *
    FROM keyframe
    WHERE time >= minTime
          AND time < maxTime
          AND stream = streamName
    ORDER BY time
  )
  LOOP
    IF last_time IS NULL OR (last_time + intervalAsInterval) <= rec.time
    THEN
      last_time := rec.time;

      RETURN NEXT rec;

      i := i + 1;
      EXIT WHEN i >= maxResults;
    END IF;

  END LOOP;
END;
$BODY$ LANGUAGE plpgsql;

/**
  Finds keyframes where minTime <= startTime < cursor, spaced out at intervalSeconds
 */
CREATE OR REPLACE FUNCTION getKeyframesBeforeCursor(
  streamName      VARCHAR,
  minTime         TIMESTAMP,
  cursorId        VARCHAR,
  cursorTime      TIMESTAMP,
  intervalSeconds INTEGER,
  maxResults      INTEGER
)
  RETURNS SETOF keyframe AS $BODY$
DECLARE
  rec       keyframe%ROWTYPE;
  last_time TIMESTAMP;
  i         INTEGER;
  intervalAsInterval INTERVAL;
BEGIN
  i := 0;
  intervalAsInterval := intervalSeconds * INTERVAL '1 second';

  FOR rec IN (
    SELECT
      *
    FROM keyframe
    WHERE time >= minTime
          AND (time < cursorTime OR time = cursorTime AND id < cursorId)
          AND stream = streamName
    ORDER BY time DESC
  )
  LOOP
    IF last_time IS NULL OR (last_time - intervalAsInterval) >= rec.time
    THEN
      last_time := rec.time;

      RETURN NEXT rec;

      i := i + 1;
      EXIT WHEN i >= maxResults;
    END IF;

  END LOOP;
END;
$BODY$ LANGUAGE plpgsql;

/**
  Finds keyframes where cursor < startTime < maxTime, spaced out at intervalSeconds
 */
CREATE OR REPLACE FUNCTION getKeyframesAfterCursor(
  streamName      VARCHAR,
  maxTime         TIMESTAMP,
  cursorId        VARCHAR,
  cursorStartTime TIMESTAMP,
  intervalSeconds INTEGER,
  maxResults      INTEGER
)
  RETURNS SETOF keyframe AS $BODY$
DECLARE
  rec       keyframe%ROWTYPE;
  last_time TIMESTAMP;
  i         INTEGER;
  intervalAsInterval INTERVAL;
BEGIN
  i := 0;
  intervalAsInterval := intervalSeconds * INTERVAL '1 second';

  FOR rec IN (
    SELECT
      *
    FROM keyframe
    WHERE time < maxTime
          AND (time > cursorStartTime OR time = cursorStartTime AND id > cursorId)
          AND stream = streamName
    ORDER BY time
  )
  LOOP
    IF last_time IS NULL OR (last_time + intervalAsInterval) <= rec.time
    THEN
      last_time := rec.time;

      RETURN NEXT rec;

      i := i + 1;
      EXIT WHEN i >= maxResults;
    END IF;


  END LOOP;
END;
$BODY$ LANGUAGE plpgsql;