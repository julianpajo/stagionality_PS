--
-- PostgreSQL database dump
--

-- Dumped from database version 11.1 (Debian 11.1-1.pgdg90+1)
-- Dumped by pg_dump version 11.4 (Ubuntu 11.4-1.pgdg16.04+1)

-- Started on 2020-03-24 16:17:23 UTC

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

ALTER DATABASE "UNIBA" OWNER TO uniba;

ALTER DATABASE "UNIBA" SET search_path=public,pg_catalog,postgis,topology,tiger,pgcrypto,dblink,uniba;

\connect "UNIBA"

-- Tablespace: hdd1
-- DROP TABLESPACE hdd1;

CREATE TABLESPACE hdd1
  OWNER uniba
  LOCATION '/var/lib/postgresql/hdd1';

ALTER TABLESPACE hdd1
  OWNER TO uniba;

ALTER TABLESPACE hdd1
    SET (seq_page_cost=1, random_page_cost=4, effective_io_concurrency=1);


-- Tablespace: ssd1
-- DROP TABLESPACE ssd1;

CREATE TABLESPACE ssd1
  OWNER uniba
  LOCATION '/var/lib/postgresql/ssd1';


ALTER TABLESPACE ssd1
  OWNER TO uniba;



CREATE SCHEMA uniba;


ALTER SCHEMA uniba OWNER TO postgres;

-- FUNCTION: uniba.refresh_vwm_ps_organization(character varying)

-- DROP FUNCTION uniba.refresh_vwm_ps_organization(character varying);

CREATE OR REPLACE FUNCTION uniba.refresh_vwm_ps_organization(
	company_alias character varying)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE

g_an_idx character varying;
g_v_idx character varying;
geom_coherence_idx character varying;
geom_coherence_norm_idx character varying;
geom_partial_coherence_idx character varying;
geom_partial_coherence_norm_idx character varying;
ly_an_idx character varying;
ly_v_idx character varying;
ordering_coherence_idx character varying;
ordering_coherence_norm_idx character varying;
pass_idx character varying;

view_name character varying;
tmp_view_name character varying;

BEGIN
	view_name := 'vwm_ps_' || company_alias;
    tmp_view_name := 'vwm_ps_' || company_alias || '_tmp';

    g_an_idx := 'vwm_ps_' || company_alias || '_g_an_idx';
    g_v_idx := 'vwm_ps_' || company_alias || '_g_v_idx';
    geom_coherence_idx := 'vwm_ps_' || company_alias || '_geom_coherence_idx';
    geom_coherence_norm_idx := 'vwm_ps_' || company_alias || '_geom_coherence_norm_idx';
	geom_partial_coherence_idx := 'vwm_ps_' || company_alias || '_geom_partial_coherence_idx';
	geom_partial_coherence_norm_idx := 'vwm_ps_' || company_alias || '_geom_partial_coherence_norm_idx';
    ly_an_idx := 'vwm_ps_' || company_alias || '_ly_an_idx';
    ly_v_idx := 'vwm_ps_' || company_alias || '_ly_v_idx';
    ordering_coherence_idx := 'vwm_ps_' || company_alias || '_ordering_coherence_idx';
    ordering_coherence_norm_idx := 'vwm_ps_' || company_alias || '_ordering_coherence_norm_idx';
    pass_idx := 'vwm_ps_' || company_alias || '_pass_idx';

    EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS uniba.%I', tmp_view_name);

    EXECUTE format('CREATE MATERIALIZED VIEW uniba.%I AS
					(WITH clipped_crop AS (
						SELECT crop.id,
							   ST_Intersection(crop.geom,  organization_deals.geom_4326) as geom,
							   crop.pass,
							   crop_parameter.coh_suggested,
							   crop_parameter.coh_min,
							   sensor.name as sensor_name
						FROM (SELECT sensor_id, st_union(geom) geom_4326
							  FROM uniba.deal
							  WHERE EXISTS (SELECT 1
											FROM uniba.organization
											WHERE organization.id = deal.organization_id AND organization.alias::text = %L::text) AND deal.service_type=''displacement''
							  GROUP BY sensor_id) organization_deals
						JOIN sensor ON sensor.id = organization_deals.sensor_id
						JOIN crop ON ST_Intersects(crop.geom, organization_deals.geom_4326) AND
									 NOT EXISTS (SELECT 1
												 FROM organization
												 JOIN crop_blacklist ON crop_blacklist.organization_id = organization.id
												 WHERE crop_blacklist.crop_id = crop.id AND organization.alias =  %L::text)
						JOIN crop_parameter ON crop_parameter.crop_id = crop.id AND crop_parameter.type=''PS''
						WHERE EXISTS (SELECT 1
									  FROM dataset
									  WHERE dataset.id = crop.dataset_id AND dataset.sensor_id = organization_deals.sensor_id)
					)
					SELECT
				   		null as crcode,
						ps.scatterer_id as scattererid,
						''PS'' as scatterer_type,
						clipped_crop.sensor_name as sensorid,
						ps.geom as geom,
						ps.height,
						ps.coherence,
							CASE
								WHEN ps.coherence IS NULL OR ps.coherence = 0::double precision THEN 0::double precision
								WHEN ps.coherence > clipped_crop.coh_suggested THEN 0.5::double precision + 0.5::double precision * ((ps.coherence - clipped_crop.coh_suggested) / (1::double precision - clipped_crop.coh_suggested))
								WHEN ps.coherence = clipped_crop.coh_suggested THEN 0.5::double precision
								WHEN ps.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested = clipped_crop.coh_min THEN 0.5::double precision
								WHEN ps.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested != clipped_crop.coh_min THEN 0.5::double precision - 0.5::double precision * (clipped_crop.coh_suggested - ps.coherence) / (clipped_crop.coh_suggested - clipped_crop.coh_min)
								ELSE 0::double precision
							END AS coherence_norm,
						ps.lat,
						ps.lon,

						(ps.periodic_properties -> ''g'' ->> ''v'')::real as g_v,
						(ps.periodic_properties -> ''g'' ->> ''a'')::real as g_a,
						(ps.periodic_properties -> ''g'' ->> ''an'')::real as g_an,
                        (ps.periodic_properties -> ''g'' ->> ''e'')::real as sea_los,
						(ps.periodic_properties -> ''ly'' ->> ''v'')::real as ly_v,
						(ps.periodic_properties -> ''ly'' ->> ''a'')::real as ly_a,
						(ps.periodic_properties -> ''ly'' ->> ''an'')::real as ly_an,

						clipped_crop.pass,
						ps.ordering
					FROM clipped_crop
					JOIN scatterer ON scatterer.crop_id = clipped_crop.id
					JOIN ps ON scatterer.id = ps.scatterer_id AND ST_Within(ps.geom_4326, clipped_crop.geom))
					UNION ALL
					(WITH clipped_crop AS (
						SELECT crop.id,
							   ST_Intersection(crop.geom,  organization_deals.geom_4326) as geom,
							   crop.pass,
							   crop_parameter.coh_suggested,
							   crop_parameter.coh_min,
							   sensor.name as sensor_name
						FROM (SELECT sensor_id, st_union(geom) geom_4326
							  FROM uniba.deal
							  WHERE EXISTS (SELECT 1
											FROM uniba.organization
											WHERE organization.id = deal.organization_id AND organization.alias::text = %L::text) AND deal.service_type=''displacement''
							  GROUP BY sensor_id) organization_deals
						JOIN sensor ON sensor.id = organization_deals.sensor_id
						JOIN crop ON ST_Intersects(crop.geom, organization_deals.geom_4326) AND
									 NOT EXISTS (SELECT 1
												 FROM organization
												 JOIN crop_blacklist ON crop_blacklist.organization_id = organization.id
												 WHERE crop_blacklist.crop_id = crop.id AND organization.alias =  %L::text)
						JOIN crop_parameter ON crop_parameter.crop_id = crop.id AND crop_parameter.type=''DS''
						WHERE EXISTS (SELECT 1
									  FROM dataset
									  WHERE dataset.id = crop.dataset_id AND dataset.sensor_id = organization_deals.sensor_id)
					)
					SELECT
				   		null as crcode,
						ds.scatterer_id as scattererid,
						''DS'' as scatterer_type,
						clipped_crop.sensor_name as sensorid,
						ds.geom as geom,
						ds.height,
						ds.coherence,
							CASE
								WHEN ds.coherence IS NULL OR ds.coherence = 0::double precision THEN 0::double precision
								WHEN ds.coherence > clipped_crop.coh_suggested THEN 0.5::double precision + 0.5::double precision * ((ds.coherence - clipped_crop.coh_suggested) / (1::double precision - clipped_crop.coh_suggested))
								WHEN ds.coherence = clipped_crop.coh_suggested THEN 0.5::double precision
								WHEN ds.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested = clipped_crop.coh_min THEN 0.5::double precision
								WHEN ds.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested != clipped_crop.coh_min THEN 0.5::double precision - 0.5::double precision * (clipped_crop.coh_suggested - ds.coherence) / (clipped_crop.coh_suggested - clipped_crop.coh_min)
								ELSE 0::double precision
							END AS coherence_norm,
						ds.lat,
						ds.lon,

						(ds.periodic_properties -> ''g'' ->> ''v'')::real as g_v,
						(ds.periodic_properties -> ''g'' ->> ''a'')::real as g_a,
						(ds.periodic_properties -> ''g'' ->> ''an'')::real as g_an,
                        (ds.periodic_properties -> ''g'' ->> ''e'')::real as sea_los,
						(ds.periodic_properties -> ''ly'' ->> ''v'')::real as ly_v,
						(ds.periodic_properties -> ''ly'' ->> ''a'')::real as ly_a,
						(ds.periodic_properties -> ''ly'' ->> ''an'')::real as ly_an,

						clipped_crop.pass,
						ds.ordering
					FROM clipped_crop
					JOIN scatterer ON scatterer.crop_id = clipped_crop.id
					JOIN ds ON scatterer.id = ds.scatterer_id AND ST_Within(ds.geom_4326, clipped_crop.geom))
				   UNION ALL
					(WITH clipped_crop AS (
						SELECT crop.id,
							   ST_Intersection(crop.geom,  crop.geom) as geom,
							   crop.pass,
							   crop_parameter.coh_suggested,
							   crop_parameter.coh_min,
							   sensor.name as sensor_name
						FROM (SELECT sensor_id, st_union(geom) geom_4326
							  FROM uniba.deal
							  WHERE EXISTS (SELECT 1
											FROM uniba.organization
											WHERE organization.id = deal.organization_id AND organization.alias::text = %L::text) AND deal.service_type=''displacement''
							  GROUP BY sensor_id) organization_deals
						JOIN sensor ON sensor.id = organization_deals.sensor_id
						JOIN crop ON ST_Intersects(crop.geom, crop.geom) AND
									 NOT EXISTS (SELECT 1
												 FROM organization
												 JOIN crop_blacklist ON crop_blacklist.organization_id = organization.id
												 WHERE crop_blacklist.crop_id = crop.id AND organization.alias =  %L::text)
						JOIN crop_parameter ON crop_parameter.crop_id = crop.id AND crop_parameter.type=''CR''
						WHERE EXISTS (SELECT 1
									  FROM dataset
									  WHERE dataset.id = crop.dataset_id AND dataset.sensor_id = organization_deals.sensor_id)
					)
					SELECT
				   		corner_reflector.code as crcode,
						cr_scatterer.scatterer_id as scattererid,
						''CR'' as scatterer_type,
						clipped_crop.sensor_name as sensorid,
						cr_scatterer.geom as geom,
						cr_scatterer.height,
						cr_scatterer.coherence,
							CASE
								WHEN cr_scatterer.coherence IS NULL OR cr_scatterer.coherence = 0::double precision THEN 0::double precision
								WHEN cr_scatterer.coherence > clipped_crop.coh_suggested THEN 0.5::double precision + 0.5::double precision * ((cr_scatterer.coherence - clipped_crop.coh_suggested) / (1::double precision - clipped_crop.coh_suggested))
								WHEN cr_scatterer.coherence = clipped_crop.coh_suggested THEN 0.5::double precision
								WHEN cr_scatterer.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested = clipped_crop.coh_min THEN 0.5::double precision
								WHEN cr_scatterer.coherence < clipped_crop.coh_suggested AND clipped_crop.coh_suggested != clipped_crop.coh_min THEN 0.5::double precision - 0.5::double precision * (clipped_crop.coh_suggested - cr_scatterer.coherence) / (clipped_crop.coh_suggested - clipped_crop.coh_min)
								ELSE 0::double precision
							END AS coherence_norm,
						cr_scatterer.lat,
						cr_scatterer.lon,

						(cr_scatterer.periodic_properties -> ''g'' ->> ''v'')::real as g_v,
						(cr_scatterer.periodic_properties -> ''g'' ->> ''a'')::real as g_a,
						(cr_scatterer.periodic_properties -> ''g'' ->> ''an'')::real as g_an,
                        (cr_scatterer.periodic_properties -> ''g'' ->> ''e'')::real as sea_los,
						(cr_scatterer.periodic_properties -> ''ly'' ->> ''v'')::real as ly_v,
						(cr_scatterer.periodic_properties -> ''ly'' ->> ''a'')::real as ly_a,
						(cr_scatterer.periodic_properties -> ''ly'' ->> ''an'')::real as ly_an,

						clipped_crop.pass,
						cr_scatterer.ordering
					FROM clipped_crop
					JOIN scatterer ON scatterer.crop_id = clipped_crop.id
					JOIN cr_scatterer ON scatterer.id = cr_scatterer.scatterer_id AND ST_Within(cr_scatterer.geom_4326, clipped_crop.geom)
				  	JOIN corner_reflector ON cr_scatterer.corner_reflector_id = corner_reflector.id)
        WITH NO DATA', tmp_view_name, company_alias, company_alias, company_alias, company_alias, company_alias, company_alias);

    EXECUTE format('ALTER MATERIALIZED VIEW uniba.%I SET (
                autovacuum_enabled = false, toast.autovacuum_enabled = false
                )', tmp_view_name);

	SET  join_collapse_limit TO 1;
    EXECUTE format('REFRESH MATERIALIZED VIEW uniba.%I WITH DATA', tmp_view_name);
	RESET  join_collapse_limit;

	EXECUTE format('COMMENT ON COLUMN uniba.%I.geom IS ''POSTLOAD_NOTNULL''',
				   tmp_view_name);

    -- indices and autovacuum
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (g_an)
				    WITH (fillfactor = 100)
                    TABLESPACE pg_default', g_an_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (g_v)
				    WITH (fillfactor = 100)
                    TABLESPACE pg_default', g_v_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING gist
                    (geom, coherence)
					WITH (fillfactor=100)
                    TABLESPACE pg_default', geom_coherence_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING gist
                    (geom, coherence_norm)
					WITH (fillfactor=100)
                    TABLESPACE pg_default', geom_coherence_norm_idx || '_tmp', tmp_view_name);
	EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING gist
                    (geom)
					WITH (fillfactor=100)
                    TABLESPACE pg_default  WHERE coherence >= 0.85::double precision AND coherence IS NOT NULL', geom_partial_coherence_idx || '_tmp', tmp_view_name);
	EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING gist
                    (geom)
					WITH (fillfactor=100)
                    TABLESPACE pg_default  WHERE coherence_norm >= 0.5::double precision AND coherence_norm IS NOT NULL', geom_partial_coherence_norm_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (ly_an)
				    WITH (fillfactor = 100)
                    TABLESPACE pg_default', ly_an_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (ly_v)
					WITH (fillfactor = 100)
                    TABLESPACE pg_default', ly_v_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (ordering, coherence)
					INCLUDE (g_v, g_an, ly_v, ly_an, pass, scatterer_type, geom)
				    WITH (fillfactor = 100)
                    TABLESPACE pg_default', ordering_coherence_idx || '_tmp', tmp_view_name);
    EXECUTE format('CREATE INDEX %I
                    ON uniba.%I USING btree
                    (ordering, coherence_norm)
					INCLUDE (g_v, g_an, ly_v, ly_an, pass, scatterer_type, geom)
				    WITH (fillfactor = 100)
                    TABLESPACE pg_default', ordering_coherence_norm_idx || '_tmp', tmp_view_name);

 	EXECUTE format('CLUSTER uniba.%I USING %I', tmp_view_name, geom_coherence_norm_idx || '_tmp');

	EXECUTE format('ANALYZE uniba.%I', tmp_view_name);
	EXECUTE format('ALTER MATERIALIZED VIEW uniba.%I SET (
                        autovacuum_enabled = true, toast.autovacuum_enabled = true
                    )', tmp_view_name);

    EXECUTE format('ALTER MATERIALIZED VIEW IF EXISTS uniba.%I RENAME TO %I', view_name, view_name || '_old');
    EXECUTE format('ALTER MATERIALIZED VIEW uniba.%I RENAME TO %I', tmp_view_name, view_name);
    EXECUTE format('DROP MATERIALIZED VIEW IF EXISTS uniba.%I', view_name || '_old');

    -- rename indices
    EXECUTE format('ALTER INDEX %I RENAME TO %I', g_an_idx || '_tmp', g_an_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', g_v_idx || '_tmp', g_v_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', geom_coherence_idx || '_tmp', geom_coherence_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', geom_coherence_norm_idx || '_tmp', geom_coherence_norm_idx);
	EXECUTE format('ALTER INDEX %I RENAME TO %I', geom_partial_coherence_idx || '_tmp', geom_partial_coherence_idx);
	EXECUTE format('ALTER INDEX %I RENAME TO %I', geom_partial_coherence_norm_idx || '_tmp', geom_partial_coherence_norm_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', ly_an_idx || '_tmp', ly_an_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', ly_v_idx || '_tmp', ly_v_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', ordering_coherence_idx || '_tmp', ordering_coherence_idx);
    EXECUTE format('ALTER INDEX %I RENAME TO %I', ordering_coherence_norm_idx || '_tmp', ordering_coherence_norm_idx);

	RETURN 0;

END;
$BODY$;

ALTER FUNCTION uniba.refresh_vwm_ps_organization(character varying) OWNER TO uniba;


--
-- TOC entry 1930 (class 1255 OID 19278)
-- Name: update_acceleration_norm(integer); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_acceleration_norm(crop_id_value integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$

DECLARE

cursor_ps REFCURSOR;
row_ps record;

cursor_ds REFCURSOR;
row_ds record;

cursor_cr_scatterer REFCURSOR;
row_cr_scatterer record;

min_g float;
delta_g float;
min_ly float;
delta_ly float;

periodic_properties_updated jsonb;

BEGIN

    SELECT
        min((periodic_properties -> 'g' ->> 'a')::float) as min_g,
        max((periodic_properties -> 'g' ->> 'a')::float) - min((periodic_properties -> 'g' ->> 'a')::float) as delta_g,
        min((periodic_properties -> 'ly' ->> 'a')::float) as min_ly,
        max((periodic_properties -> 'ly' ->> 'a')::float) - min((periodic_properties -> 'ly' ->> 'a')::float) as delta_ly      
    FROM uniba.ps INNER
	JOIN uniba.scatterer ON ps.scatterer_id = scatterer.id
    WHERE crop_id = crop_id_value
    INTO min_g, delta_g, min_ly, delta_ly;

	IF min_g IS NULL THEN
		min_g = 0;
	END IF;
	IF min_ly IS NULL THEN
		min_ly = 0;
	END IF;	

	IF delta_g = 0 THEN
		delta_g = 1;
	END IF;
	IF delta_ly = 0 THEN
		delta_ly = 1;
	END IF;	

    OPEN cursor_ps NO SCROLL FOR
        SELECT periodic_properties, scatterer_id
        FROM uniba.ps INNER JOIN uniba.scatterer ON ps.scatterer_id = scatterer.id
        WHERE crop_id = crop_id_value;

    LOOP

        FETCH cursor_ps INTO row_ps;
        EXIT WHEN NOT FOUND;

        periodic_properties_updated = jsonb_set(row_ps.periodic_properties,
                                                '{g, an}'::text[],
                                                COALESCE((ROUND((((row_ps.periodic_properties -> 'g' ->> 'a')::float - min_g) / delta_g)::numeric, 4)::text), 'null')::jsonb);

        periodic_properties_updated = jsonb_set(periodic_properties_updated,
                                                '{ly, an}'::text[],
                                                COALESCE((ROUND((((periodic_properties_updated -> 'ly' ->> 'a')::float - min_ly) / delta_ly)::numeric, 4)::text), 'null')::jsonb);        

        UPDATE ps SET periodic_properties = periodic_properties_updated WHERE scatterer_id = row_ps.scatterer_id;

    END LOOP;
    CLOSE cursor_ps;

	SELECT
        min((periodic_properties -> 'g' ->> 'a')::float) as min_g,
        max((periodic_properties -> 'g' ->> 'a')::float) - min((periodic_properties -> 'g' ->> 'a')::float) as delta_g,
        min((periodic_properties -> 'ly' ->> 'a')::float) as min_ly,
        max((periodic_properties -> 'ly' ->> 'a')::float) - min((periodic_properties -> 'ly' ->> 'a')::float) as delta_ly        
    FROM uniba.ds INNER
	JOIN uniba.scatterer ON ds.scatterer_id = scatterer.id
    WHERE crop_id = crop_id_value
    INTO min_g, delta_g, min_ly, delta_ly;

	IF min_g IS NULL THEN
		min_g = 0;
	END IF;
	IF min_ly IS NULL THEN
		min_ly = 0;
	END IF;	

	IF delta_g = 0 THEN
		delta_g = 1;
	END IF;
	IF delta_ly = 0 THEN
		delta_ly = 1;
	END IF;	

    OPEN cursor_ds NO SCROLL FOR
        SELECT periodic_properties, scatterer_id
        FROM uniba.ds INNER JOIN uniba.scatterer ON ds.scatterer_id = scatterer.id
        WHERE crop_id = crop_id_value;

    LOOP

        FETCH cursor_ds INTO row_ds;
        EXIT WHEN NOT FOUND;

        periodic_properties_updated = jsonb_set(row_ds.periodic_properties,
                                                '{g, an}'::text[],
                                                COALESCE((ROUND((((row_ds.periodic_properties -> 'g' ->> 'a')::float - min_g) / delta_g)::numeric, 4)::text), 'null')::jsonb);

        periodic_properties_updated = jsonb_set(periodic_properties_updated,
                                                '{ly, an}'::text[],
                                                COALESCE((ROUND((((periodic_properties_updated -> 'ly' ->> 'a')::float - min_ly) / delta_ly)::numeric, 4)::text), 'null')::jsonb);

        UPDATE ds SET periodic_properties = periodic_properties_updated WHERE scatterer_id = row_ds.scatterer_id;

    END LOOP;
    CLOSE cursor_ds;

    SELECT
        min((periodic_properties -> 'g' ->> 'a')::float) as min_g,
        max((periodic_properties -> 'g' ->> 'a')::float) - min((periodic_properties -> 'g' ->> 'a')::float) as delta_g,
        min((periodic_properties -> 'ly' ->> 'a')::float) as min_ly,
        max((periodic_properties -> 'ly' ->> 'a')::float) - min((periodic_properties -> 'ly' ->> 'a')::float) as delta_ly
    FROM uniba.cr_scatterer INNER
	JOIN uniba.scatterer ON cr_scatterer.scatterer_id = scatterer.id
    WHERE crop_id = crop_id_value
    INTO min_g, delta_g, min_ly, delta_ly;

	IF min_g IS NULL THEN
		min_g = 0;
	END IF;
	IF min_ly IS NULL THEN
		min_ly = 0;
	END IF;

	IF delta_g = 0 THEN
		delta_g = 1;
	END IF;
	IF delta_ly = 0 THEN
		delta_ly = 1;
	END IF;

    OPEN cursor_cr_scatterer NO SCROLL FOR
        SELECT periodic_properties, scatterer_id
        FROM uniba.cr_scatterer INNER JOIN uniba.scatterer ON cr_scatterer.scatterer_id = scatterer.id
        WHERE crop_id = crop_id_value;

    LOOP

        FETCH cursor_cr_scatterer INTO row_cr_scatterer;
        EXIT WHEN NOT FOUND;

        periodic_properties_updated = jsonb_set(row_cr_scatterer.periodic_properties,
                                                '{g, an}'::text[],
                                                COALESCE((ROUND((((row_cr_scatterer.periodic_properties -> 'g' ->> 'a')::float - min_g) / delta_g)::numeric, 4)::text), 'null')::jsonb);

        periodic_properties_updated = jsonb_set(periodic_properties_updated,
                                                '{ly, an}'::text[],
                                                COALESCE((ROUND((((periodic_properties_updated -> 'ly' ->> 'a')::float - min_ly) / delta_ly)::numeric, 4)::text), 'null')::jsonb);

        UPDATE cr_scatterer SET periodic_properties = periodic_properties_updated WHERE scatterer_id = row_cr_scatterer.scatterer_id;

    END LOOP;
    CLOSE cursor_cr_scatterer;

    RETURN 0;

END;

$$;


ALTER FUNCTION uniba.update_acceleration_norm(crop_id_value integer) OWNER TO uniba;

--
-- TOC entry 1931 (class 1255 OID 19279)
-- Name: update_geo_json_from_geom(); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_geo_json_from_geom() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  new.geom_geo_json := ST_AsGeoJSON(new.geom);
  RETURN new;
END;
$$;


ALTER FUNCTION uniba.update_geo_json_from_geom() OWNER TO uniba;

--
-- TOC entry 1932 (class 1255 OID 19280)
-- Name: update_geom_from_geo_json(); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_geom_from_geo_json() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  new.geom := ST_SetSRID(ST_GeomFromGeoJSON(new.geom_geo_json),4326);
  RETURN new;
END;
$$;


ALTER FUNCTION uniba.update_geom_from_geo_json() OWNER TO uniba;

--
-- TOC entry 1933 (class 1255 OID 19281)
-- Name: update_geom_from_lat_lon(); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_geom_from_lat_lon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

        DECLARE
            geom geometry(Point,4326);
        BEGIN
          geom := ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat),4326);
          NEW.geom_4326 := geom;
		  NEW.geom := ST_Transform(geom, 3857);
          RETURN new;
        END;

$$;


ALTER FUNCTION uniba.update_geom_from_lat_lon() OWNER TO uniba;

--
-- TOC entry 1934 (class 1255 OID 19282)
-- Name: update_geom_from_lat_lon_elevation(); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_geom_from_lat_lon_elevation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  new.geom := ST_MakePoint(new.lon, new.lat, new.elevation);
  RETURN new;
END;
$$;


ALTER FUNCTION uniba.update_geom_from_lat_lon_elevation() OWNER TO uniba;

--
-- TOC entry 1935 (class 1255 OID 19283)
-- Name: update_update_date(); Type: FUNCTION; Schema: uniba; Owner: uniba
--

CREATE FUNCTION uniba.update_update_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            NEW.update_date = now();
            RETURN NEW;
        END;
    $$;


ALTER FUNCTION uniba.update_update_date() OWNER TO uniba;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 280 (class 1259 OID 19284)
-- Name: aoi; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.aoi (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    description text NOT NULL,
    name text NOT NULL,
    geom postgis.geometry
);


ALTER TABLE uniba.aoi OWNER TO uniba;

--
-- TOC entry 281 (class 1259 OID 19291)
-- Name: aoi_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.aoi_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.aoi_id_seq OWNER TO uniba;

--
-- TOC entry 5588 (class 0 OID 0)
-- Dependencies: 281
-- Name: aoi_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.aoi_id_seq OWNED BY uniba.aoi.id;


--
-- TOC entry 329 (class 1259 OID 19781)
-- Name: bookmark; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.bookmark (
    id integer NOT NULL,
    name text,
    geom postgis.geometry,
    geom_geo_json text,
    user_id integer,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone
);


ALTER TABLE uniba.bookmark OWNER TO uniba;

--
-- TOC entry 328 (class 1259 OID 19779)
-- Name: bookmark_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.bookmark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.bookmark_id_seq OWNER TO uniba;

--
-- TOC entry 5589 (class 0 OID 0)
-- Dependencies: 328
-- Name: bookmark_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.bookmark_id_seq OWNED BY uniba.bookmark.id;


--
-- TOC entry 282 (class 1259 OID 19293)
-- Name: crop; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.crop (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    name text,
    geom postgis.geometry,
    geom_geo_json text,
    pass text,
    dataset_id integer,
    code text
);


ALTER TABLE uniba.crop OWNER TO uniba;

--
-- TOC entry 5590 (class 0 OID 0)
-- Dependencies: 282
-- Name: COLUMN crop.name; Type: COMMENT; Schema: uniba; Owner: uniba
--

COMMENT ON COLUMN uniba.crop.name IS 'Deprecated: only used for recognizing the crop area of interest';


--
-- TOC entry 283 (class 1259 OID 19300)
-- Name: crop_blacklist; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.crop_blacklist (
    organization_id integer NOT NULL,
    crop_id integer NOT NULL
);


ALTER TABLE uniba.crop_blacklist OWNER TO uniba;

--
-- TOC entry 284 (class 1259 OID 19303)
-- Name: crop_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.crop_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE uniba.crop_id_seq OWNER TO uniba;

--
-- TOC entry 5591 (class 0 OID 0)
-- Dependencies: 284
-- Name: crop_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.crop_id_seq OWNED BY uniba.crop.id;


--
-- TOC entry 285 (class 1259 OID 19305)
-- Name: crop_parameter; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.crop_parameter (
    id integer NOT NULL,
    crop_id integer,
    status smallint,
    coh_min double precision,
    coh_suggested double precision,
    type text,
    metadata jsonb,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    CONSTRAINT crop_parameter_type_check CHECK ((type = ANY (ARRAY['PS'::text, 'DS'::text])))
);


ALTER TABLE uniba.crop_parameter OWNER TO uniba;

--
-- TOC entry 286 (class 1259 OID 19313)
-- Name: crop_parameter_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.crop_parameter_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE uniba.crop_parameter_id_seq OWNER TO uniba;

--
-- TOC entry 5592 (class 0 OID 0)
-- Dependencies: 286
-- Name: crop_parameter_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.crop_parameter_id_seq OWNED BY uniba.crop_parameter.id;


--
-- TOC entry 287 (class 1259 OID 19315)
-- Name: dataset; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.dataset (
    id integer NOT NULL,
    supermaster_uid text NOT NULL,
    sensor_id integer NOT NULL,
    beam text NOT NULL,
    name text NOT NULL
);


ALTER TABLE uniba.dataset OWNER TO uniba;

--
-- TOC entry 288 (class 1259 OID 19321)
-- Name: dataset_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.dataset_id_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.dataset_id_seq OWNER TO uniba;

--
-- TOC entry 5593 (class 0 OID 0)
-- Dependencies: 288
-- Name: dataset_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.dataset_id_seq OWNED BY uniba.dataset.id;


--
-- TOC entry 289 (class 1259 OID 19323)
-- Name: deal; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.deal (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    activation_date text,
    end_period date,
    geom postgis.geometry,
    geom_geo_json text,
    last_update date,
    product_name text,
    seller_id text,
    service_type text,
    signature_date date,
    start_period date,
    status smallint NOT NULL,
    update_frequency integer NOT NULL,
    organization_id integer NOT NULL,
    sensor_id integer NOT NULL,
    CONSTRAINT deal_service_type_check CHECK (((service_type = 'displacement'::text) OR (service_type = 'marine'::text) OR (service_type = 'saimon'::text)))
);


ALTER TABLE uniba.deal OWNER TO uniba;

--
-- TOC entry 290 (class 1259 OID 19331)
-- Name: deal_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.deal_id_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.deal_id_seq OWNER TO uniba;

--
-- TOC entry 5594 (class 0 OID 0)
-- Dependencies: 290
-- Name: deal_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.deal_id_seq OWNED BY uniba.deal.id;


--
-- TOC entry 291 (class 1259 OID 19333)
-- Name: ds; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.ds (
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
    scatterer_id integer NOT NULL
)
WITH (fillfactor='70', autovacuum_vacuum_threshold='1000000', autovacuum_vacuum_scale_factor='0', autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE uniba.ds OWNER TO uniba;

SET default_tablespace = 'hdd1';

--
-- TOC entry 292 (class 1259 OID 19342)
-- Name: ds_measurement; Type: TABLE; Schema: uniba; Owner: uniba; Tablespace: hdd1
--

CREATE TABLE uniba.ds_measurement (
    measurement text,
    scatterer_id integer NOT NULL
)
WITH (fillfactor='70', autovacuum_vacuum_threshold='1000000', autovacuum_vacuum_scale_factor='0', autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE uniba.ds_measurement OWNER TO uniba;


SET default_tablespace = '';

--
-- TOC entry 293 (class 1259 OID 19348)
-- Name: layer; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.layer (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    description text NOT NULL,
    name text NOT NULL
);


ALTER TABLE uniba.layer OWNER TO uniba;

--
-- TOC entry 294 (class 1259 OID 19355)
-- Name: layer_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.layer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.layer_id_seq OWNER TO uniba;

--
-- TOC entry 5595 (class 0 OID 0)
-- Dependencies: 294
-- Name: layer_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.layer_id_seq OWNED BY uniba.layer.id;


--
-- TOC entry 295 (class 1259 OID 19357)
-- Name: meteo_stations; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.meteo_stations (
    id text NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    cod text NOT NULL,
    codcountry text NOT NULL,
    description text NOT NULL,
    elevation integer,
    geom postgis.geometry,
    geom_geo_json text,
    lat double precision,
    lon double precision
);


ALTER TABLE uniba.meteo_stations OWNER TO uniba;

--
-- TOC entry 296 (class 1259 OID 19364)
-- Name: meteo_stations_measure_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.meteo_stations_measure_id_seq
    START WITH 1
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.meteo_stations_measure_id_seq OWNER TO uniba;

--
-- TOC entry 297 (class 1259 OID 19366)
-- Name: meteo_stations_measure; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.meteo_stations_measure (
    id bigint DEFAULT nextval('uniba.meteo_stations_measure_id_seq'::regclass) NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    data date,
    measure double precision,
    type text NOT NULL,
    id_station text NOT NULL
);


ALTER TABLE uniba.meteo_stations_measure OWNER TO uniba;

--
-- TOC entry 298 (class 1259 OID 19374)
-- Name: meteo_stations_measure_old; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.meteo_stations_measure_old (
    id bigint NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    data date,
    measure double precision,
    type text NOT NULL,
    id_station text NOT NULL
);


ALTER TABLE uniba.meteo_stations_measure_old OWNER TO uniba;

--
-- TOC entry 299 (class 1259 OID 19381)
-- Name: meteo_stations_measure_old_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.meteo_stations_measure_old_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.meteo_stations_measure_old_id_seq OWNER TO uniba;

--
-- TOC entry 5596 (class 0 OID 0)
-- Dependencies: 299
-- Name: meteo_stations_measure_old_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.meteo_stations_measure_old_id_seq OWNED BY uniba.meteo_stations_measure_old.id;


--
-- TOC entry 300 (class 1259 OID 19383)
-- Name: meteo_stations_old; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.meteo_stations_old (
    id text NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    cod text NOT NULL,
    codcountry text NOT NULL,
    description text NOT NULL,
    elevation integer,
    geom postgis.geometry,
    geom_geo_json text,
    lat double precision,
    lon double precision
);


ALTER TABLE uniba.meteo_stations_old OWNER TO uniba;

--
-- TOC entry 301 (class 1259 OID 19390)
-- Name: oauth_access_token; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_access_token (
    token_id character varying(255),
    token bytea,
    authentication_id character varying(255) NOT NULL,
    user_name character varying(255),
    client_id character varying(255),
    authentication bytea,
    refresh_token character varying(255)
);


ALTER TABLE uniba.oauth_access_token OWNER TO uniba;

--
-- TOC entry 302 (class 1259 OID 19396)
-- Name: oauth_approvals; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_approvals (
    userid character varying(255),
    clientid character varying(255),
    scope character varying(255),
    status character varying(10),
    expiresat timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    lastmodifiedat timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE uniba.oauth_approvals OWNER TO uniba;

--
-- TOC entry 303 (class 1259 OID 19404)
-- Name: oauth_client_details; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_client_details (
    client_id character varying(255) NOT NULL,
    resource_ids character varying(255),
    client_secret character varying(255),
    scope character varying(255),
    authorized_grant_types character varying(255),
    web_server_redirect_uri character varying(255),
    authorities character varying(255),
    access_token_validity integer,
    refresh_token_validity integer,
    additional_information character varying(4096),
    autoapprove character varying(255)
);


ALTER TABLE uniba.oauth_client_details OWNER TO uniba;

--
-- TOC entry 304 (class 1259 OID 19410)
-- Name: oauth_client_token; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_client_token (
    token_id character varying(255),
    token bytea,
    authentication_id character varying(255) NOT NULL,
    user_name character varying(255),
    client_id character varying(255)
);


ALTER TABLE uniba.oauth_client_token OWNER TO uniba;

--
-- TOC entry 305 (class 1259 OID 19416)
-- Name: oauth_code; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_code (
    code character varying(255),
    authentication bytea
);


ALTER TABLE uniba.oauth_code OWNER TO uniba;

--
-- TOC entry 306 (class 1259 OID 19422)
-- Name: oauth_refresh_token; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.oauth_refresh_token (
    token_id character varying(255),
    token bytea,
    authentication bytea
);


ALTER TABLE uniba.oauth_refresh_token OWNER TO uniba;

--
-- TOC entry 307 (class 1259 OID 19428)
-- Name: organization; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.organization (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    company_name text,
    alias text,
    geoserver_password text,
    geoserver_username text
);


ALTER TABLE uniba.organization OWNER TO uniba;

--
-- TOC entry 308 (class 1259 OID 19435)
-- Name: organization_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.organization_id_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.organization_id_seq OWNER TO uniba;

--
-- TOC entry 5597 (class 0 OID 0)
-- Dependencies: 308
-- Name: organization_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.organization_id_seq OWNED BY uniba.organization.id;


--
-- TOC entry 309 (class 1259 OID 19437)
-- Name: ps; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.ps (
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
    scatterer_id integer NOT NULL
)
WITH (fillfactor='70', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='1000000', autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE uniba.ps OWNER TO uniba;

SET default_tablespace = 'hdd1';

--
-- TOC entry 310 (class 1259 OID 19446)
-- Name: ps_measurement; Type: TABLE; Schema: uniba; Owner: uniba; Tablespace: hdd1
--

CREATE TABLE uniba.ps_measurement (
    measurement text,
    scatterer_id integer NOT NULL
)
WITH (fillfactor='70', autovacuum_vacuum_scale_factor='0', autovacuum_vacuum_threshold='1000000', autovacuum_enabled='true', toast.autovacuum_enabled='true');


ALTER TABLE uniba.ps_measurement OWNER TO uniba;

SET default_tablespace = '';

--
-- TOC entry 311 (class 1259 OID 19452)
-- Name: role; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.role (
    id bigint NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    description text NOT NULL,
    name text NOT NULL
);


ALTER TABLE uniba.role OWNER TO uniba;

--
-- TOC entry 312 (class 1259 OID 19459)
-- Name: role_aoi; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.role_aoi (
    role_id bigint NOT NULL,
    aoi_id integer NOT NULL
);


ALTER TABLE uniba.role_aoi OWNER TO uniba;

--
-- TOC entry 313 (class 1259 OID 19462)
-- Name: role_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.role_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.role_id_seq OWNER TO uniba;

--
-- TOC entry 5598 (class 0 OID 0)
-- Dependencies: 313
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.role_id_seq OWNED BY uniba.role.id;


--
-- TOC entry 314 (class 1259 OID 19464)
-- Name: role_layer; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.role_layer (
    role_id bigint NOT NULL,
    layer_id integer NOT NULL
);


ALTER TABLE uniba.role_layer OWNER TO uniba;

--
-- TOC entry 315 (class 1259 OID 19467)
-- Name: role_style; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.role_style (
    role_id bigint NOT NULL,
    style_id integer NOT NULL
);


ALTER TABLE uniba.role_style OWNER TO uniba;

--
-- TOC entry 316 (class 1259 OID 19470)
-- Name: scatterer; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.scatterer (
    id integer NOT NULL,
    code text NOT NULL,
    dataset_id integer NOT NULL,
    crop_id integer NOT NULL
)
WITH (fillfactor='70');


ALTER TABLE uniba.scatterer OWNER TO uniba;

--
-- TOC entry 317 (class 1259 OID 19476)
-- Name: scatterer_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.scatterer_id_seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    MAXVALUE 2147483647
    CACHE 1;


ALTER TABLE uniba.scatterer_id_seq OWNER TO uniba;

--
-- TOC entry 5599 (class 0 OID 0)
-- Dependencies: 317
-- Name: scatterer_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.scatterer_id_seq OWNED BY uniba.scatterer.id;


--
-- TOC entry 318 (class 1259 OID 19478)
-- Name: sensor; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.sensor (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    description text NOT NULL,
    name text NOT NULL,
    code text DEFAULT 1 NOT NULL
);


ALTER TABLE uniba.sensor OWNER TO uniba;

--
-- TOC entry 319 (class 1259 OID 19486)
-- Name: sensor_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.sensor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.sensor_id_seq OWNER TO uniba;

--
-- TOC entry 5600 (class 0 OID 0)
-- Dependencies: 319
-- Name: sensor_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.sensor_id_seq OWNED BY uniba.sensor.id;


--
-- TOC entry 320 (class 1259 OID 19488)
-- Name: style; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.style (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    description text NOT NULL,
    name text NOT NULL,
    content xml NOT NULL
);


ALTER TABLE uniba.style OWNER TO uniba;

--
-- TOC entry 321 (class 1259 OID 19495)
-- Name: style_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.style_id_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.style_id_seq OWNER TO uniba;

--
-- TOC entry 5601 (class 0 OID 0)
-- Dependencies: 321
-- Name: style_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.style_id_seq OWNED BY uniba.style.id;


--
-- TOC entry 322 (class 1259 OID 19497)
-- Name: user; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba."user" (
    id integer NOT NULL,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    email text,
    flag_period boolean,
    layer text,
    name text,
    password text,
    service_layer text,
    status smallint NOT NULL,
    surname text,
    username text,
    organization_id integer NOT NULL
);


ALTER TABLE uniba."user" OWNER TO uniba;

--
-- TOC entry 323 (class 1259 OID 19504)
-- Name: user_aoi; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.user_aoi (
    user_id integer NOT NULL,
    aoi_id integer NOT NULL
);


ALTER TABLE uniba.user_aoi OWNER TO uniba;

--
-- TOC entry 324 (class 1259 OID 19507)
-- Name: user_id_seq; Type: SEQUENCE; Schema: uniba; Owner: uniba
--

CREATE SEQUENCE uniba.user_id_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uniba.user_id_seq OWNER TO uniba;

--
-- TOC entry 5602 (class 0 OID 0)
-- Dependencies: 324
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: uniba; Owner: uniba
--

ALTER SEQUENCE uniba.user_id_seq OWNED BY uniba."user".id;


--
-- TOC entry 325 (class 1259 OID 19509)
-- Name: user_layer; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.user_layer (
    user_id integer NOT NULL,
    layer_id integer NOT NULL
);


ALTER TABLE uniba.user_layer OWNER TO uniba;

--
-- TOC entry 326 (class 1259 OID 19512)
-- Name: user_role; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.user_role (
    user_id integer NOT NULL,
    role_id bigint NOT NULL
);


ALTER TABLE uniba.user_role OWNER TO uniba;

--
-- TOC entry 327 (class 1259 OID 19515)
-- Name: user_style; Type: TABLE; Schema: uniba; Owner: uniba
--

CREATE TABLE uniba.user_style (
    user_id integer NOT NULL,
    style_id integer NOT NULL
);


ALTER TABLE uniba.user_style OWNER TO uniba;

--
-- TOC entry 5145 (class 2604 OID 19518)
-- Name: aoi id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.aoi ALTER COLUMN id SET DEFAULT nextval('uniba.aoi_id_seq'::regclass);


--
-- TOC entry 5183 (class 2604 OID 19784)
-- Name: bookmark id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.bookmark ALTER COLUMN id SET DEFAULT nextval('uniba.bookmark_id_seq'::regclass);


--
-- TOC entry 5147 (class 2604 OID 19519)
-- Name: crop id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop ALTER COLUMN id SET DEFAULT nextval('uniba.crop_id_seq'::regclass);


--
-- TOC entry 5149 (class 2604 OID 19520)
-- Name: crop_parameter id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_parameter ALTER COLUMN id SET DEFAULT nextval('uniba.crop_parameter_id_seq'::regclass);


--
-- TOC entry 5151 (class 2604 OID 19521)
-- Name: dataset id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.dataset ALTER COLUMN id SET DEFAULT nextval('uniba.dataset_id_seq'::regclass);


--
-- TOC entry 5153 (class 2604 OID 19522)
-- Name: deal id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.deal ALTER COLUMN id SET DEFAULT nextval('uniba.deal_id_seq'::regclass);


--
-- TOC entry 5159 (class 2604 OID 19523)
-- Name: layer id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.layer ALTER COLUMN id SET DEFAULT nextval('uniba.layer_id_seq'::regclass);


--
-- TOC entry 5164 (class 2604 OID 19524)
-- Name: meteo_stations_measure_old id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_measure_old ALTER COLUMN id SET DEFAULT nextval('uniba.meteo_stations_measure_old_id_seq'::regclass);


--
-- TOC entry 5169 (class 2604 OID 19525)
-- Name: organization id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.organization ALTER COLUMN id SET DEFAULT nextval('uniba.organization_id_seq'::regclass);


--
-- TOC entry 5174 (class 2604 OID 19526)
-- Name: role id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role ALTER COLUMN id SET DEFAULT nextval('uniba.role_id_seq'::regclass);


--
-- TOC entry 5175 (class 2604 OID 19527)
-- Name: scatterer id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.scatterer ALTER COLUMN id SET DEFAULT nextval('uniba.scatterer_id_seq'::regclass);


--
-- TOC entry 5178 (class 2604 OID 19528)
-- Name: sensor id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.sensor ALTER COLUMN id SET DEFAULT nextval('uniba.sensor_id_seq'::regclass);


--
-- TOC entry 5180 (class 2604 OID 19529)
-- Name: style id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.style ALTER COLUMN id SET DEFAULT nextval('uniba.style_id_seq'::regclass);


--
-- TOC entry 5182 (class 2604 OID 19530)
-- Name: user id; Type: DEFAULT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba."user" ALTER COLUMN id SET DEFAULT nextval('uniba.user_id_seq'::regclass);


--
-- TOC entry 5306 (class 2606 OID 19532)
-- Name: aoi aoi_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.aoi
    ADD CONSTRAINT aoi_pkey PRIMARY KEY (id);


--
-- TOC entry 5392 (class 2606 OID 19789)
-- Name: bookmark bookmark_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.bookmark
    ADD CONSTRAINT bookmark_pkey PRIMARY KEY (id);


--
-- TOC entry 5313 (class 2606 OID 19534)
-- Name: crop_blacklist crop_blacklist_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_blacklist
    ADD CONSTRAINT crop_blacklist_pkey PRIMARY KEY (organization_id, crop_id);


--
-- TOC entry 5308 (class 2606 OID 19536)
-- Name: crop crop_dataset_id_code_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop
    ADD CONSTRAINT crop_dataset_id_code_key UNIQUE (dataset_id, code);


--
-- TOC entry 5315 (class 2606 OID 19538)
-- Name: crop_parameter crop_parameter_crop_id_type_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_parameter
    ADD CONSTRAINT crop_parameter_crop_id_type_key UNIQUE (crop_id, type);


--
-- TOC entry 5317 (class 2606 OID 19540)
-- Name: crop_parameter crop_parameter_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_parameter
    ADD CONSTRAINT crop_parameter_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5311 (class 2606 OID 19542)
-- Name: crop crop_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop
    ADD CONSTRAINT crop_pkey PRIMARY KEY (id);


--
-- TOC entry 5319 (class 2606 OID 19544)
-- Name: dataset dataset_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.dataset
    ADD CONSTRAINT dataset_pkey PRIMARY KEY (id);


--
-- TOC entry 5321 (class 2606 OID 19546)
-- Name: dataset dataset_sensor_id_supermaster_uid_beam_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.dataset
    ADD CONSTRAINT dataset_sensor_id_supermaster_uid_beam_key UNIQUE (sensor_id, supermaster_uid, beam);


--
-- TOC entry 5323 (class 2606 OID 19548)
-- Name: deal deal_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.deal
    ADD CONSTRAINT deal_id_pkey PRIMARY KEY (id);

SET default_tablespace = 'hdd1';

--
-- TOC entry 5330 (class 2606 OID 19550)
-- Name: ds_measurement ds_measurement_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba; Tablespace: hdd1
--

ALTER TABLE ONLY uniba.ds_measurement
    ADD CONSTRAINT ds_measurement_pkey PRIMARY KEY (scatterer_id) WITH (fillfactor='70');

SET default_tablespace = '';

--
-- TOC entry 5328 (class 2606 OID 19552)
-- Name: ds ds_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.ds
    ADD CONSTRAINT ds_pkey PRIMARY KEY (scatterer_id) WITH (fillfactor='70');


--
-- TOC entry 5332 (class 2606 OID 19554)
-- Name: layer layer_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.layer
    ADD CONSTRAINT layer_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5334 (class 2606 OID 19556)
-- Name: meteo_stations meteo_stations_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations
    ADD CONSTRAINT meteo_stations_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5336 (class 2606 OID 19558)
-- Name: meteo_stations_measure meteo_stations_measure_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_measure
    ADD CONSTRAINT meteo_stations_measure_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5339 (class 2606 OID 19560)
-- Name: meteo_stations_measure_old meteo_stations_measure_old_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_measure_old
    ADD CONSTRAINT meteo_stations_measure_old_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5342 (class 2606 OID 19562)
-- Name: meteo_stations_old meteo_stations_old_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_old
    ADD CONSTRAINT meteo_stations_old_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5344 (class 2606 OID 19564)
-- Name: oauth_access_token oauth_access_token_authentication_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.oauth_access_token
    ADD CONSTRAINT oauth_access_token_authentication_id_pkey PRIMARY KEY (authentication_id);


--
-- TOC entry 5346 (class 2606 OID 19566)
-- Name: oauth_client_details oauth_client_details_client_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.oauth_client_details
    ADD CONSTRAINT oauth_client_details_client_id_pkey PRIMARY KEY (client_id);


--
-- TOC entry 5348 (class 2606 OID 19568)
-- Name: oauth_client_token oauth_client_token_authentication_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.oauth_client_token
    ADD CONSTRAINT oauth_client_token_authentication_id_pkey PRIMARY KEY (authentication_id);


--
-- TOC entry 5351 (class 2606 OID 19570)
-- Name: organization organization_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.organization
    ADD CONSTRAINT organization_id_pkey PRIMARY KEY (id);

SET default_tablespace = 'hdd1';

--
-- TOC entry 5356 (class 2606 OID 19572)
-- Name: ps_measurement ps_measurement_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba; Tablespace: hdd1
--

ALTER TABLE ONLY uniba.ps_measurement
    ADD CONSTRAINT ps_measurement_pkey PRIMARY KEY (scatterer_id) WITH (fillfactor='70');

SET default_tablespace = '';

--
-- TOC entry 5354 (class 2606 OID 19574)
-- Name: ps ps_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.ps
    ADD CONSTRAINT ps_pkey PRIMARY KEY (scatterer_id) WITH (fillfactor='70');


--
-- TOC entry 5360 (class 2606 OID 19576)
-- Name: role_aoi role_aoi_role_id_aoi_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_aoi
    ADD CONSTRAINT role_aoi_role_id_aoi_id_pkey PRIMARY KEY (role_id, aoi_id);


--
-- TOC entry 5358 (class 2606 OID 19578)
-- Name: role role_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role
    ADD CONSTRAINT role_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5362 (class 2606 OID 19580)
-- Name: role_layer role_layer_role_id_layer_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_layer
    ADD CONSTRAINT role_layer_role_id_layer_id_pkey PRIMARY KEY (role_id, layer_id);


--
-- TOC entry 5364 (class 2606 OID 19582)
-- Name: role_style role_style_role_id_style_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_style
    ADD CONSTRAINT role_style_role_id_style_id_pkey PRIMARY KEY (role_id, style_id);


--
-- TOC entry 5368 (class 2606 OID 19584)
-- Name: scatterer scatterer_dataset_id_code_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.scatterer
    ADD CONSTRAINT scatterer_dataset_id_code_key UNIQUE (dataset_id, code) WITH (fillfactor='70');


--
-- TOC entry 5371 (class 2606 OID 19586)
-- Name: scatterer scatterer_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.scatterer
    ADD CONSTRAINT scatterer_pkey PRIMARY KEY (id) WITH (fillfactor='70');


--
-- TOC entry 5373 (class 2606 OID 19588)
-- Name: sensor sensor_code_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.sensor
    ADD CONSTRAINT sensor_code_key UNIQUE (code);


--
-- TOC entry 5375 (class 2606 OID 19590)
-- Name: sensor sensor_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.sensor
    ADD CONSTRAINT sensor_pkey PRIMARY KEY (id);


--
-- TOC entry 5377 (class 2606 OID 19592)
-- Name: style style_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.style
    ADD CONSTRAINT style_id_pkey PRIMARY KEY (id);


--
-- TOC entry 5384 (class 2606 OID 19594)
-- Name: user_aoi user_aoi_user_id_aoi_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_aoi
    ADD CONSTRAINT user_aoi_user_id_aoi_id_pkey PRIMARY KEY (user_id, aoi_id);


--
-- TOC entry 5386 (class 2606 OID 19596)
-- Name: user_layer user_layer_user_id_layer_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_layer
    ADD CONSTRAINT user_layer_user_id_layer_id_pkey PRIMARY KEY (user_id, layer_id);


--
-- TOC entry 5380 (class 2606 OID 19598)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 5388 (class 2606 OID 19600)
-- Name: user_role user_role_user_id_role_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_role
    ADD CONSTRAINT user_role_user_id_role_id_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 5390 (class 2606 OID 19602)
-- Name: user_style user_style_user_id_style_id_pkey; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_style
    ADD CONSTRAINT user_style_user_id_style_id_pkey PRIMARY KEY (user_id, style_id);


--
-- TOC entry 5382 (class 2606 OID 19604)
-- Name: user user_username_key; Type: CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba."user"
    ADD CONSTRAINT user_username_key UNIQUE (username);


--
-- TOC entry 5309 (class 1259 OID 19605)
-- Name: crop_geom_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX crop_geom_idx ON uniba.crop USING gist (geom);


--
-- TOC entry 5324 (class 1259 OID 19606)
-- Name: deal_organization_id_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX deal_organization_id_idx ON uniba.deal USING btree (organization_id);


--
-- TOC entry 5325 (class 1259 OID 19607)
-- Name: deal_sensor_id_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX deal_sensor_id_idx ON uniba.deal USING btree (sensor_id);


--
-- TOC entry 5326 (class 1259 OID 19608)
-- Name: ds_geom_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX ds_geom_idx ON uniba.ds USING gist (geom_4326) WITH (fillfactor='70');


--
-- TOC entry 5337 (class 1259 OID 19609)
-- Name: meteo_stations_measure_id_station_type_data_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX meteo_stations_measure_id_station_type_data_idx ON uniba.meteo_stations_measure USING btree (id_station, type, data) WITH (fillfactor='70');

ALTER TABLE uniba.meteo_stations_measure CLUSTER ON meteo_stations_measure_id_station_type_data_idx;


--
-- TOC entry 5340 (class 1259 OID 19610)
-- Name: meteo_stations_measure_old_id_station_type_data_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX meteo_stations_measure_old_id_station_type_data_idx ON uniba.meteo_stations_measure_old USING btree (id_station, type, data) WITH (fillfactor='70');

ALTER TABLE uniba.meteo_stations_measure_old CLUSTER ON meteo_stations_measure_old_id_station_type_data_idx;


--
-- TOC entry 5349 (class 1259 OID 19611)
-- Name: organization_alias_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX organization_alias_idx ON uniba.organization USING btree (alias);


--
-- TOC entry 5352 (class 1259 OID 19612)
-- Name: ps_geom_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX ps_geom_idx ON uniba.ps USING gist (geom_4326) WITH (fillfactor='70');


--
-- TOC entry 5365 (class 1259 OID 19613)
-- Name: scatterer_code_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX scatterer_code_idx ON uniba.scatterer USING btree (code) WITH (fillfactor='70');


--
-- TOC entry 5366 (class 1259 OID 19614)
-- Name: scatterer_crop_id_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX scatterer_crop_id_idx ON uniba.scatterer USING btree (crop_id) INCLUDE (id) WITH (fillfactor='70');


--
-- TOC entry 5369 (class 1259 OID 19615)
-- Name: scatterer_dataset_id_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX scatterer_dataset_id_idx ON uniba.scatterer USING btree (dataset_id) WITH (fillfactor='70');


--
-- TOC entry 5378 (class 1259 OID 19616)
-- Name: user_organization_id_idx; Type: INDEX; Schema: uniba; Owner: uniba
--

CREATE INDEX user_organization_id_idx ON uniba."user" USING btree (organization_id);


--
-- TOC entry 5419 (class 2620 OID 19617)
-- Name: aoi aoi_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER aoi_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.aoi FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5444 (class 2620 OID 19797)
-- Name: bookmark bookmark_tr_update_geom_from_geo_json; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER bookmark_tr_update_geom_from_geo_json BEFORE INSERT OR UPDATE ON uniba.bookmark FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_geo_json();


--
-- TOC entry 5443 (class 2620 OID 19795)
-- Name: bookmark bookmark_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER bookmark_tr_update_update_date AFTER INSERT OR UPDATE ON uniba.bookmark FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5422 (class 2620 OID 19618)
-- Name: crop_parameter crop_parameter_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER crop_parameter_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.crop_parameter FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5420 (class 2620 OID 19619)
-- Name: crop crop_tr_update_geom_geo_json_from_geom; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER crop_tr_update_geom_geo_json_from_geom BEFORE INSERT OR UPDATE OF geom ON uniba.crop FOR EACH ROW EXECUTE PROCEDURE uniba.update_geo_json_from_geom();


--
-- TOC entry 5421 (class 2620 OID 19620)
-- Name: crop crop_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER crop_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.crop FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5423 (class 2620 OID 19621)
-- Name: deal deal_tr_update_geom_from_geo_json; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER deal_tr_update_geom_from_geo_json BEFORE INSERT OR UPDATE ON uniba.deal FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_geo_json();


--
-- TOC entry 5424 (class 2620 OID 19622)
-- Name: deal deal_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER deal_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.deal FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5425 (class 2620 OID 19623)
-- Name: ds ds_tr_get_ds_geom_from_lat_lon; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER ds_tr_get_ds_geom_from_lat_lon BEFORE INSERT OR UPDATE OF lat, lon ON uniba.ds FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_lat_lon();


--
-- TOC entry 5426 (class 2620 OID 19624)
-- Name: ds ds_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER ds_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.ds FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5427 (class 2620 OID 19625)
-- Name: layer layer_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER layer_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.layer FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5432 (class 2620 OID 19626)
-- Name: meteo_stations_measure_old meteo_stations_measurement_old_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_measurement_old_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.meteo_stations_measure_old FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5431 (class 2620 OID 19627)
-- Name: meteo_stations_measure meteo_stations_measurement_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_measurement_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.meteo_stations_measure FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5433 (class 2620 OID 19628)
-- Name: meteo_stations_old meteo_stations_tr_update_geo_json_from_geom; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_geo_json_from_geom BEFORE INSERT OR UPDATE ON uniba.meteo_stations_old FOR EACH ROW EXECUTE PROCEDURE uniba.update_geo_json_from_geom();


--
-- TOC entry 5428 (class 2620 OID 19629)
-- Name: meteo_stations meteo_stations_tr_update_geo_json_from_geom; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_geo_json_from_geom BEFORE INSERT OR UPDATE ON uniba.meteo_stations FOR EACH ROW EXECUTE PROCEDURE uniba.update_geo_json_from_geom();


--
-- TOC entry 5434 (class 2620 OID 19630)
-- Name: meteo_stations_old meteo_stations_tr_update_geom_from_lat_lon_elevation; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_geom_from_lat_lon_elevation BEFORE INSERT OR UPDATE ON uniba.meteo_stations_old FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_lat_lon_elevation();


--
-- TOC entry 5429 (class 2620 OID 19631)
-- Name: meteo_stations meteo_stations_tr_update_geom_from_lat_lon_elevation; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_geom_from_lat_lon_elevation BEFORE INSERT OR UPDATE ON uniba.meteo_stations FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_lat_lon_elevation();


--
-- TOC entry 5435 (class 2620 OID 19632)
-- Name: meteo_stations_old meteo_stations_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.meteo_stations_old FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5430 (class 2620 OID 19633)
-- Name: meteo_stations meteo_stations_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER meteo_stations_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.meteo_stations FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5436 (class 2620 OID 19634)
-- Name: organization organization_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER organization_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.organization FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5437 (class 2620 OID 19635)
-- Name: ps ps_tr_get_ps_geom_from_lat_lon; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER ps_tr_get_ps_geom_from_lat_lon BEFORE INSERT OR UPDATE OF lat, lon ON uniba.ps FOR EACH ROW EXECUTE PROCEDURE uniba.update_geom_from_lat_lon();


--
-- TOC entry 5438 (class 2620 OID 19636)
-- Name: ps ps_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER ps_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.ps FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5439 (class 2620 OID 19637)
-- Name: role role_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER role_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.role FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5440 (class 2620 OID 19638)
-- Name: sensor sensor_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER sensor_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.sensor FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5441 (class 2620 OID 19639)
-- Name: style style_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER style_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba.style FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5442 (class 2620 OID 19640)
-- Name: user user_tr_update_update_date; Type: TRIGGER; Schema: uniba; Owner: uniba
--

CREATE TRIGGER user_tr_update_update_date BEFORE INSERT OR UPDATE ON uniba."user" FOR EACH ROW EXECUTE PROCEDURE uniba.update_update_date();


--
-- TOC entry 5418 (class 2606 OID 19790)
-- Name: bookmark bookmark_user_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.bookmark
    ADD CONSTRAINT bookmark_user_id_fkey FOREIGN KEY (user_id) REFERENCES uniba."user"(id);


--
-- TOC entry 5394 (class 2606 OID 19641)
-- Name: crop_blacklist crop_blacklist_crop_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_blacklist
    ADD CONSTRAINT crop_blacklist_crop_id_fkey FOREIGN KEY (crop_id) REFERENCES uniba.crop(id);


--
-- TOC entry 5395 (class 2606 OID 19646)
-- Name: crop_blacklist crop_blacklist_organization_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_blacklist
    ADD CONSTRAINT crop_blacklist_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES uniba.organization(id);


--
-- TOC entry 5393 (class 2606 OID 19651)
-- Name: crop crop_dataset_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop
    ADD CONSTRAINT crop_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES uniba.dataset(id);


--
-- TOC entry 5396 (class 2606 OID 19656)
-- Name: crop_parameter crop_parameter_crop_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.crop_parameter
    ADD CONSTRAINT crop_parameter_crop_id_fkey FOREIGN KEY (crop_id) REFERENCES uniba.crop(id);


--
-- TOC entry 5397 (class 2606 OID 19661)
-- Name: dataset dataset_sensor_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.dataset
    ADD CONSTRAINT dataset_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES uniba.sensor(id);


--
-- TOC entry 5398 (class 2606 OID 19666)
-- Name: deal deal_organization_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.deal
    ADD CONSTRAINT deal_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES uniba.organization(id);


--
-- TOC entry 5399 (class 2606 OID 19671)
-- Name: deal deal_sensor_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.deal
    ADD CONSTRAINT deal_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES uniba.sensor(id);


--
-- TOC entry 5400 (class 2606 OID 19676)
-- Name: meteo_stations_measure meteo_stations_measure_id_station_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_measure
    ADD CONSTRAINT meteo_stations_measure_id_station_fkey FOREIGN KEY (id_station) REFERENCES uniba.meteo_stations(id);


--
-- TOC entry 5401 (class 2606 OID 19681)
-- Name: meteo_stations_measure_old meteo_stations_measure_old_id_station_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.meteo_stations_measure_old
    ADD CONSTRAINT meteo_stations_measure_old_id_station_fkey FOREIGN KEY (id_station) REFERENCES uniba.meteo_stations_old(id);


--
-- TOC entry 5402 (class 2606 OID 19686)
-- Name: role_aoi role_aoi_aoi_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_aoi
    ADD CONSTRAINT role_aoi_aoi_id_fkey FOREIGN KEY (aoi_id) REFERENCES uniba.aoi(id);


--
-- TOC entry 5403 (class 2606 OID 19691)
-- Name: role_aoi role_aoi_role_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_aoi
    ADD CONSTRAINT role_aoi_role_id_fkey FOREIGN KEY (role_id) REFERENCES uniba.role(id);


--
-- TOC entry 5404 (class 2606 OID 19696)
-- Name: role_layer role_layer_layer_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_layer
    ADD CONSTRAINT role_layer_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES uniba.layer(id);


--
-- TOC entry 5406 (class 2606 OID 19701)
-- Name: role_style role_layer_role_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_style
    ADD CONSTRAINT role_layer_role_id_fkey FOREIGN KEY (role_id) REFERENCES uniba.role(id);


--
-- TOC entry 5405 (class 2606 OID 19706)
-- Name: role_layer role_layer_role_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_layer
    ADD CONSTRAINT role_layer_role_id_fkey FOREIGN KEY (role_id) REFERENCES uniba.role(id);


--
-- TOC entry 5407 (class 2606 OID 19711)
-- Name: role_style role_layer_style_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.role_style
    ADD CONSTRAINT role_layer_style_id_fkey FOREIGN KEY (style_id) REFERENCES uniba.style(id);


--
-- TOC entry 5408 (class 2606 OID 19716)
-- Name: scatterer scatterer_crop_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.scatterer
    ADD CONSTRAINT scatterer_crop_id_fkey FOREIGN KEY (crop_id) REFERENCES uniba.crop(id);


--
-- TOC entry 5410 (class 2606 OID 19721)
-- Name: user_aoi user_aoi_aoi_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_aoi
    ADD CONSTRAINT user_aoi_aoi_id_fkey FOREIGN KEY (aoi_id) REFERENCES uniba.aoi(id);


--
-- TOC entry 5411 (class 2606 OID 19726)
-- Name: user_aoi user_aoi_user_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_aoi
    ADD CONSTRAINT user_aoi_user_id_fkey FOREIGN KEY (user_id) REFERENCES uniba."user"(id);


--
-- TOC entry 5412 (class 2606 OID 19731)
-- Name: user_layer user_layer_layer_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_layer
    ADD CONSTRAINT user_layer_layer_id_fkey FOREIGN KEY (layer_id) REFERENCES uniba.layer(id);


--
-- TOC entry 5413 (class 2606 OID 19736)
-- Name: user_layer user_layer_user_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_layer
    ADD CONSTRAINT user_layer_user_id_fkey FOREIGN KEY (user_id) REFERENCES uniba."user"(id);


--
-- TOC entry 5409 (class 2606 OID 19741)
-- Name: user user_organization_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba."user"
    ADD CONSTRAINT user_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES uniba.organization(id);


--
-- TOC entry 5414 (class 2606 OID 19746)
-- Name: user_role user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES uniba.role(id);


--
-- TOC entry 5415 (class 2606 OID 19751)
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES uniba."user"(id);


--
-- TOC entry 5416 (class 2606 OID 19756)
-- Name: user_style user_style_style_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_style
    ADD CONSTRAINT user_style_style_id_fkey FOREIGN KEY (style_id) REFERENCES uniba.style(id);


--
-- TOC entry 5417 (class 2606 OID 19761)
-- Name: user_style user_style_user_id_fkey; Type: FK CONSTRAINT; Schema: uniba; Owner: uniba
--

ALTER TABLE ONLY uniba.user_style
    ADD CONSTRAINT user_style_user_id_fkey FOREIGN KEY (user_id) REFERENCES uniba."user"(id);


-- Completed on 2020-03-24 16:17:27 UTC

--
-- PostgreSQL database dump complete
--

-- FUNCTION: uniba.delete_ps_ds_cr_and_crop(integer)

-- DROP FUNCTION uniba.delete_ps_ds_cr_and_crop(integer);

CREATE OR REPLACE FUNCTION uniba.delete_ps_ds_cr_and_crop(
	crop_id integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
cur_features REFCURSOR;
row_feature record;
BEGIN
 OPEN cur_features NO SCROLL FOR EXECUTE FORMAT('SELECT scatterer.id as scatterer_id
												   FROM scatterer, ps
												   WHERE scatterer.id = ps.scatterer_id
												   AND crop_id = %s',crop_id);

    LOOP

        FETCH cur_features INTO row_feature;
        EXIT WHEN NOT FOUND;

            EXECUTE FORMAT('DELETE FROM ps_measurement WHERE scatterer_id = %s', row_feature.scatterer_id);
            EXECUTE FORMAT('DELETE FROM ps WHERE scatterer_id = %s', row_feature.scatterer_id);

            EXECUTE FORMAT('DELETE FROM ds_measurement WHERE scatterer_id = %s', row_feature.scatterer_id);
            EXECUTE FORMAT('DELETE FROM ds WHERE scatterer_id = %s', row_feature.scatterer_id);

            EXECUTE FORMAT('DELETE FROM scatterer WHERE id = %s', row_feature.scatterer_id);

    END LOOP;
    CLOSE cur_features;

OPEN cur_features NO SCROLL FOR EXECUTE FORMAT('SELECT scatterer.id as scatterer_id
												   FROM scatterer, ds
												   WHERE scatterer.id = ds.scatterer_id
												   AND crop_id = %s',crop_id);

    LOOP

        FETCH cur_features INTO row_feature;
        EXIT WHEN NOT FOUND;


            EXECUTE FORMAT('DELETE FROM ds_measurement WHERE scatterer_id = %s', row_feature.scatterer_id);
            EXECUTE FORMAT('DELETE FROM ds WHERE scatterer_id = %s', row_feature.scatterer_id);

            EXECUTE FORMAT('DELETE FROM scatterer WHERE id = %s', row_feature.scatterer_id);

    END LOOP;
    CLOSE cur_features;

OPEN cur_features NO SCROLL FOR EXECUTE FORMAT('SELECT scatterer.id as scatterer_id
												   FROM scatterer, cr_scatterer
												   WHERE scatterer.id = cr_scatterer.scatterer_id
												   AND crop_id = %s',crop_id);

    LOOP

        FETCH cur_features INTO row_feature;
        EXIT WHEN NOT FOUND;


            EXECUTE FORMAT('DELETE FROM cr_scatterer_measurement WHERE scatterer_id = %s', row_feature.scatterer_id);
            EXECUTE FORMAT('DELETE FROM cr_scatterer WHERE scatterer_id = %s', row_feature.scatterer_id);

            EXECUTE FORMAT('DELETE FROM scatterer WHERE id = %s', row_feature.scatterer_id);

    END LOOP;
    CLOSE cur_features;
	EXECUTE FORMAT('DELETE FROM crop_parameter WHERE crop_id = %s', crop_id);
	EXECUTE FORMAT('DELETE FROM crop_blacklist WHERE crop_id = %s', crop_id);
	EXECUTE FORMAT('DELETE FROM crop WHERE id = %s', crop_id);

	return 0;
	END;
$BODY$;

ALTER FUNCTION uniba.delete_ps_ds_cr_and_crop(integer) OWNER TO uniba;

ALTER TABLE uniba.crop_parameter DROP CONSTRAINT crop_parameter_type_check;

ALTER TABLE uniba.crop_parameter
    ADD CONSTRAINT crop_parameter_type_check CHECK (type = ANY (ARRAY['PS'::text, 'DS'::text, 'CR'::text]));

-- Table: uniba.corner_reflector

-- DROP TABLE uniba.corner_reflector;

CREATE TABLE uniba.corner_reflector
(
    id SERIAL,
    code text COLLATE pg_catalog."default" NOT NULL,
    group_id text COLLATE pg_catalog."default" NOT NULL,
    owner_id text COLLATE pg_catalog."default" NOT NULL,
    install_date timestamp without time zone NOT NULL,
    dismiss_date timestamp without time zone,
    create_date timestamp without time zone NOT NULL DEFAULT now(),
    update_date timestamp without time zone NOT NULL DEFAULT now(),
    CONSTRAINT corner_reflector_pkey PRIMARY KEY (id)
        WITH (FILLFACTOR=70),
    CONSTRAINT corner_reflector_code_group_id_owner_key UNIQUE (code, group_id, owner_id)
)
WITH (
    OIDS = FALSE,
    FILLFACTOR = 70,
    autovacuum_enabled = TRUE,
    toast.autovacuum_enabled = TRUE,
    autovacuum_vacuum_scale_factor = 0,
    autovacuum_vacuum_threshold = 1000000
)
TABLESPACE pg_default;

ALTER TABLE uniba.corner_reflector
    OWNER to uniba;

-- Trigger: corner_reflector_tr_update_update_date

-- DROP TRIGGER corner_reflector_tr_update_update_date ON uniba.corner_reflector;

CREATE TRIGGER corner_reflector_tr_update_update_date
    BEFORE INSERT OR UPDATE
    ON uniba.corner_reflector
    FOR EACH ROW
    EXECUTE PROCEDURE uniba.update_update_date();


-- Table: uniba.corner_reflector_version

-- DROP TABLE uniba.corner_reflector_version;

CREATE TABLE uniba.corner_reflector_version
(
    id SERIAL,
    date timestamp without time zone NOT NULL,
    event_type text COLLATE pg_catalog."default" NOT NULL,
    model text COLLATE pg_catalog."default",
    notes text COLLATE pg_catalog."default",
    geom geometry,
	geom_4326 geometry,
    quote integer,
	lat double precision,
    lon double precision,
    create_date timestamp without time zone NOT NULL DEFAULT now(),
    update_date timestamp without time zone NOT NULL DEFAULT now(),
    corner_reflector_id integer NOT NULL,
    picture bytea,
    CONSTRAINT corner_reflector_version_pkey PRIMARY KEY (id)
        WITH (FILLFACTOR=70),
    CONSTRAINT corner_reflector_version_date_corner_reflector_id_key UNIQUE (date, corner_reflector_id),
    CONSTRAINT corner_reflector_version_corner_reflector_id_fkey FOREIGN KEY (corner_reflector_id)
        REFERENCES uniba.corner_reflector (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)
WITH (
    OIDS = FALSE,
    FILLFACTOR = 70,
    autovacuum_enabled = TRUE,
    toast.autovacuum_enabled = TRUE,
    autovacuum_vacuum_scale_factor = 0,
    autovacuum_vacuum_threshold = 1000000
)
TABLESPACE pg_default;

ALTER TABLE uniba.corner_reflector_version
    OWNER to uniba;

-- Trigger: corner_reflector_version_tr_update_update_date

-- DROP TRIGGER corner_reflector_version_tr_update_update_date ON uniba.corner_reflector_version;

CREATE TRIGGER corner_reflector_version_tr_update_update_date
    BEFORE INSERT OR UPDATE
    ON uniba.corner_reflector_version
    FOR EACH ROW
    EXECUTE PROCEDURE uniba.update_update_date();


-- Trigger: ps_tr_get_ps_geom_from_lat_lon

-- DROP TRIGGER ps_tr_get_ps_geom_from_lat_lon ON uniba.corner_reflector_version;

CREATE TRIGGER corner_reflector_version_tr_get_cr_geom_from_lat_lon
    BEFORE INSERT OR UPDATE OF lat, lon
    ON uniba.corner_reflector_version
    FOR EACH ROW
    EXECUTE PROCEDURE uniba.update_geom_from_lat_lon();


-- Table: uniba.cr_scatterer

-- DROP TABLE uniba.cr_scatterer;

CREATE TABLE uniba.cr_scatterer
(
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone DEFAULT now(),
    coherence real,
    geom geometry,
    height real,
    lat double precision,
    lon double precision,
    ordering integer NOT NULL DEFAULT trunc((random() * ((('4294967295'::bigint + 1) - '2147483648'::bigint))::double precision)),
    geom_4326 geometry,
    periodic_properties jsonb,
    scatterer_id integer NOT NULL,
    corner_reflector_id integer NOT NULL,
    CONSTRAINT cr_scatterer_pkey PRIMARY KEY (scatterer_id)
        WITH (FILLFACTOR=70),
    CONSTRAINT cr_scatterer_corner_reflector_id_fkey FOREIGN KEY (corner_reflector_id)
        REFERENCES uniba.corner_reflector (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
        NOT VALID
)
WITH (
    OIDS = FALSE,
    FILLFACTOR = 70,
    autovacuum_enabled = TRUE,
    toast.autovacuum_enabled = TRUE,
    autovacuum_vacuum_scale_factor = 0,
    autovacuum_vacuum_threshold = 1000000
)
TABLESPACE pg_default;

ALTER TABLE uniba.cr_scatterer
    OWNER to uniba;
-- Index: cr_scatterer_geom_idx

-- DROP INDEX uniba.cr_scatterer_geom_idx;

CREATE INDEX cr_scatterer_geom_idx
    ON uniba.cr_scatterer USING gist
    (geom_4326)
    WITH (FILLFACTOR=70)
    TABLESPACE pg_default;

-- Trigger: cr_scatterer_tr_get_cr_scatterer_geom_from_lat_lon

-- DROP TRIGGER cr_scatterer_tr_get_cr_scatterer_geom_from_lat_lon ON uniba.cr_scatterer;

CREATE TRIGGER cr_scatterer_tr_get_cr_scatterer_geom_from_lat_lon
    BEFORE INSERT OR UPDATE OF lat, lon
    ON uniba.cr_scatterer
    FOR EACH ROW
    EXECUTE PROCEDURE uniba.update_geom_from_lat_lon();

-- Trigger: cr_scatterer_tr_update_update_date

-- DROP TRIGGER cr_scatterer_tr_update_update_date ON uniba.cr_scatterer;

CREATE TRIGGER cr_scatterer_tr_update_update_date
    BEFORE INSERT OR UPDATE
    ON uniba.cr_scatterer
    FOR EACH ROW
    EXECUTE PROCEDURE uniba.update_update_date();


-- Table: uniba.cr_scatterer_measurement

-- DROP TABLE uniba.cr_scatterer_measurement;

CREATE TABLE uniba.cr_scatterer_measurement
(
    measurement text COLLATE pg_catalog."default",
    scatterer_id integer NOT NULL,
    CONSTRAINT cr_scatterer_measurement_pkey PRIMARY KEY (scatterer_id)
        WITH (FILLFACTOR=70)
)
WITH (
    OIDS = FALSE,
    FILLFACTOR = 70,
    autovacuum_enabled = TRUE,
    toast.autovacuum_enabled = TRUE,
    autovacuum_vacuum_scale_factor = 0,
    autovacuum_vacuum_threshold = 1000000
);

ALTER TABLE uniba.cr_scatterer_measurement
    OWNER to uniba;


-- Table: uniba.bookmark_scatterer

-- DROP TABLE uniba.bookmark_scatterer;

CREATE TABLE uniba.bookmark_scatterer
(
    id serial,
    name text COLLATE pg_catalog."default",
    user_id integer,
    scatterer_id integer,
    create_date timestamp without time zone DEFAULT now(),
    update_date timestamp without time zone,
    CONSTRAINT bookmark_scatterer_pkey PRIMARY KEY (id),
    CONSTRAINT bookmark_scatterer_scatterer_id_fkey FOREIGN KEY (scatterer_id)
        REFERENCES uniba.scatterer (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION,
    CONSTRAINT bookmark_scatterer_user_id_2_fkey FOREIGN KEY (user_id)
        REFERENCES uniba."user" (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE uniba.bookmark_scatterer
    OWNER to uniba;
