--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.23
-- Dumped by pg_dump version 11.6

-- Started on 2019-12-17 11:15:16

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 559 (class 1247 OID 1128295)
-- Name: property_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.property_type AS ENUM (
    'string',
    'entity',
    'item',
    'time',
    'point in time'
);


ALTER TYPE public.property_type OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 199 (class 1259 OID 1128305)
-- Name: entities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entities (
    id integer NOT NULL,
    name text NOT NULL,
    stemmed_name text NOT NULL,
    code_id integer NOT NULL,
    CONSTRAINT entities_name_check CHECK ((name <> ''::text))
);


ALTER TABLE public.entities OWNER TO postgres;

--
-- TOC entry 200 (class 1259 OID 1128312)
-- Name: entities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entities_id_seq OWNER TO postgres;

--
-- TOC entry 2100 (class 0 OID 0)
-- Dependencies: 200
-- Name: entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entities_id_seq OWNED BY public.entities.id;


--
-- TOC entry 201 (class 1259 OID 1128314)
-- Name: entity_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.entity_codes (
    id integer NOT NULL,
    code text NOT NULL,
    canonical_name text NOT NULL,
    weight integer DEFAULT 1,
    CONSTRAINT entity_codes_canonical_name_check CHECK ((canonical_name <> ''::text)),
    CONSTRAINT entity_codes_code_check CHECK ((code <> ''::text))
);


ALTER TABLE public.entity_codes OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 1128323)
-- Name: entity_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.entity_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.entity_codes_id_seq OWNER TO postgres;

--
-- TOC entry 2101 (class 0 OID 0)
-- Dependencies: 202
-- Name: entity_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.entity_codes_id_seq OWNED BY public.entity_codes.id;


--
-- TOC entry 203 (class 1259 OID 1128325)
-- Name: facts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.facts (
    entity_code text NOT NULL,
    property_code text NOT NULL,
    property_value text NOT NULL,
    qualifier_combination integer NOT NULL,
    source_id integer NOT NULL
);


ALTER TABLE public.facts OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 1173751)
-- Name: pending_facts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pending_facts (
    hash uuid NOT NULL,
    source text NOT NULL,
    date text,
    "timestamp" bigint
);


ALTER TABLE public.pending_facts OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 1128331)
-- Name: properties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.properties (
    id integer NOT NULL,
    name text NOT NULL,
    stemmed_name text NOT NULL,
    code_id integer NOT NULL,
    CONSTRAINT properties_name_check CHECK ((name <> ''::text))
);


ALTER TABLE public.properties OWNER TO postgres;

--
-- TOC entry 205 (class 1259 OID 1128338)
-- Name: properties_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.properties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.properties_id_seq OWNER TO postgres;

--
-- TOC entry 2102 (class 0 OID 0)
-- Dependencies: 205
-- Name: properties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.properties_id_seq OWNED BY public.properties.id;


--
-- TOC entry 206 (class 1259 OID 1128340)
-- Name: property_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.property_codes (
    id integer NOT NULL,
    code text NOT NULL,
    canonical_name text NOT NULL,
    type public.property_type DEFAULT 'string'::public.property_type,
    CONSTRAINT property_codes_canonical_name_check CHECK ((canonical_name <> ''::text)),
    CONSTRAINT property_codes_code_check CHECK ((code <> ''::text))
);


ALTER TABLE public.property_codes OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 1128349)
-- Name: property_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.property_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.property_codes_id_seq OWNER TO postgres;

--
-- TOC entry 2103 (class 0 OID 0)
-- Dependencies: 207
-- Name: property_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.property_codes_id_seq OWNED BY public.property_codes.id;


--
-- TOC entry 208 (class 1259 OID 1128351)
-- Name: qualifiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.qualifiers (
    qualifier_combination integer NOT NULL,
    qualifier_code text NOT NULL,
    qualifier_value text NOT NULL
);


ALTER TABLE public.qualifiers OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 1128357)
-- Name: qualifier_combination_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.qualifier_combination_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.qualifier_combination_seq OWNER TO postgres;

--
-- TOC entry 2104 (class 0 OID 0)
-- Dependencies: 209
-- Name: qualifier_combination_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.qualifier_combination_seq OWNED BY public.qualifiers.qualifier_combination;


--
-- TOC entry 210 (class 1259 OID 1128359)
-- Name: security_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.security_types (
    id integer NOT NULL,
    friendly_name text NOT NULL
);


ALTER TABLE public.security_types OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 1128365)
-- Name: sources; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sources (
    id integer NOT NULL,
    source text,
    acl text,
    security_type_id integer
);


ALTER TABLE public.sources OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 1128371)
-- Name: sources_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sources_id_seq
    START WITH 4
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sources_id_seq OWNER TO postgres;

--
-- TOC entry 2105 (class 0 OID 0)
-- Dependencies: 212
-- Name: sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sources_id_seq OWNED BY public.sources.id;


--
-- TOC entry 1941 (class 2604 OID 1128373)
-- Name: entities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entities ALTER COLUMN id SET DEFAULT nextval('public.entities_id_seq'::regclass);


--
-- TOC entry 1944 (class 2604 OID 1128374)
-- Name: entity_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_codes ALTER COLUMN id SET DEFAULT nextval('public.entity_codes_id_seq'::regclass);


--
-- TOC entry 1947 (class 2604 OID 1128375)
-- Name: properties id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.properties ALTER COLUMN id SET DEFAULT nextval('public.properties_id_seq'::regclass);


--
-- TOC entry 1950 (class 2604 OID 1128376)
-- Name: property_codes id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_codes ALTER COLUMN id SET DEFAULT nextval('public.property_codes_id_seq'::regclass);


--
-- TOC entry 1953 (class 2604 OID 1128377)
-- Name: sources id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources ALTER COLUMN id SET DEFAULT nextval('public.sources_id_seq'::regclass);


--
-- TOC entry 1956 (class 2606 OID 1128379)
-- Name: entities entities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_pkey PRIMARY KEY (id);


--
-- TOC entry 1959 (class 2606 OID 1128381)
-- Name: entity_codes entity_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entity_codes
    ADD CONSTRAINT entity_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 1963 (class 2606 OID 1128383)
-- Name: facts facts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.facts
    ADD CONSTRAINT facts_pkey PRIMARY KEY (entity_code, property_code, property_value, qualifier_combination, source_id);


--
-- TOC entry 1984 (class 2606 OID 1173758)
-- Name: pending_facts pending_facts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pending_facts
    ADD CONSTRAINT pending_facts_pkey PRIMARY KEY (hash, source);


--
-- TOC entry 1969 (class 2606 OID 1128385)
-- Name: properties properties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_pkey PRIMARY KEY (id);


--
-- TOC entry 1972 (class 2606 OID 1128387)
-- Name: property_codes property_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.property_codes
    ADD CONSTRAINT property_codes_pkey PRIMARY KEY (id);


--
-- TOC entry 1976 (class 2606 OID 1128389)
-- Name: qualifiers qualifiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.qualifiers
    ADD CONSTRAINT qualifiers_pkey PRIMARY KEY (qualifier_combination, qualifier_code, qualifier_value);


--
-- TOC entry 1978 (class 2606 OID 1128391)
-- Name: security_types security_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.security_types
    ADD CONSTRAINT security_types_pkey PRIMARY KEY (id);


--
-- TOC entry 1980 (class 2606 OID 1128393)
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (id);


--
-- TOC entry 1954 (class 1259 OID 1128394)
-- Name: entities_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entities_name_index ON public.entities USING btree (name);


--
-- TOC entry 1957 (class 1259 OID 1128395)
-- Name: entities_stemmed_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entities_stemmed_name_index ON public.entities USING btree (stemmed_name);


--
-- TOC entry 1960 (class 1259 OID 1128396)
-- Name: entity_code_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX entity_code_index ON public.facts USING btree (entity_code);


--
-- TOC entry 1961 (class 1259 OID 1128397)
-- Name: fact_qualifier_combination_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX fact_qualifier_combination_index ON public.facts USING btree (qualifier_combination);


--
-- TOC entry 1964 (class 1259 OID 1128398)
-- Name: facts_source_id_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX facts_source_id_index ON public.facts USING btree (source_id);


--
-- TOC entry 1982 (class 1259 OID 1173759)
-- Name: pending_facts_hash_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX pending_facts_hash_idx ON public.pending_facts USING btree (hash);


--
-- TOC entry 1967 (class 1259 OID 1128399)
-- Name: properties_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX properties_name_index ON public.properties USING btree (name);


--
-- TOC entry 1970 (class 1259 OID 1128400)
-- Name: properties_stemmed_name_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX properties_stemmed_name_index ON public.properties USING btree (stemmed_name);


--
-- TOC entry 1965 (class 1259 OID 1128401)
-- Name: property_code_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX property_code_index ON public.facts USING btree (property_code);


--
-- TOC entry 1966 (class 1259 OID 1128402)
-- Name: property_value_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX property_value_index ON public.facts USING btree (property_value);


--
-- TOC entry 1973 (class 1259 OID 1128403)
-- Name: qualifier_code_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX qualifier_code_index ON public.qualifiers USING btree (qualifier_code);


--
-- TOC entry 1974 (class 1259 OID 1128404)
-- Name: qualifier_value_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX qualifier_value_index ON public.qualifiers USING btree (qualifier_value);


--
-- TOC entry 1981 (class 1259 OID 1128405)
-- Name: sources_source_index; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX sources_source_index ON public.sources USING btree (source);


--
-- TOC entry 1985 (class 2606 OID 1128406)
-- Name: entities entities_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.entities
    ADD CONSTRAINT entities_code_id_fkey FOREIGN KEY (code_id) REFERENCES public.entity_codes(id);


--
-- TOC entry 1986 (class 2606 OID 1128411)
-- Name: properties properties_code_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.properties
    ADD CONSTRAINT properties_code_id_fkey FOREIGN KEY (code_id) REFERENCES public.property_codes(id);


--
-- TOC entry 2099 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2019-12-17 11:15:18

--
-- PostgreSQL database dump complete
--
