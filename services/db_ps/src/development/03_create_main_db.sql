--
-- PostgreSQL database dump
--

-- Started on 2020-03-24 16:17:23 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

ALTER DATABASE "EULER" OWNER TO euler;

ALTER DATABASE "EULER" SET search_path=public,pg_catalog,postgis,topology,tiger,pgcrypto,dblink,euler;

\connect "EULER"


CREATE SCHEMA euler;


ALTER SCHEMA euler OWNER TO postgres;

--
-- TOC entry 309 (class 1259 OID 19437)
-- Name: ps; Type: TABLE; Schema: euler; Owner: euler
--

CREATE TABLE euler.ps_measurements (
    scatterer_id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone DEFAULT now(),
    coherence real,
    geom postgis.geometry,
    height real,
    lat double precision,
    lon double precision,
    ordering integer DEFAULT trunc((random() * ((('4294967295'::bigint + 1) - '2147483648'::bigint))::double precision)) NOT NULL,
    geom_4326 postgis.geometry,
    periodic_properties jsonb,
    measurement text,
    last_measurement real
    
)
WITH (fillfactor='70', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='1000000', autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE euler.ps_measurements OWNER TO euler;