CREATE OR REPLACE FUNCTION reverse_geocode(latitude DOUBLE PRECISION, longitude DOUBLE PRECISION, OUT country_iso VARCHAR, OUT country VARCHAR, OUT city VARCHAR, OUT street VARCHAR, OUT housenumber VARCHAR, OUT distance DOUBLE PRECISION) STABLE AS $$
DECLARE
	MAX_HOUSENUMBER_DISTANCE CONSTANT SMALLINT := 50;
	MAX_STREET_DISTANCE CONSTANT SMALLINT := 200;
	level SMALLINT;
	loc geometry;
	rec RECORD;
BEGIN
	loc := ST_Transform(ST_SetSRID(ST_Point(longitude, latitude), 4326), 3857);
	SELECT osm_id, "addr:housenumber" AS housenumber, tags, way, ST_Distance(loc, way) AS distance INTO rec FROM planet_osm_point WHERE ST_DWithin(loc, way, MAX_HOUSENUMBER_DISTANCE) AND "addr:housenumber" IS NOT NULL ORDER BY distance LIMIT 1;
	IF FOUND THEN
		housenumber := rec.housenumber;
		street := rec.tags->'addr:street';
		city := rec.tags->'addr:city';
		distance := rec.distance;
		loc := rec.way;
	END IF;
	IF street IS NULL THEN
		SELECT osm_id, COALESCE(ref, name) AS name, ST_Distance(loc, way) AS distance INTO rec FROM planet_osm_line WHERE ST_DWithin(loc, way, MAX_STREET_DISTANCE) AND highway IS NOT NULL AND (ref IS NOT NULL OR name IS NOT NULL) ORDER BY distance LIMIT 1;
		IF FOUND THEN
			street := rec.name;
			IF distance IS NULL THEN
				distance := rec.distance;
			END IF;
		END IF;
	END IF;
	FOR rec IN
		SELECT * FROM (SELECT regexp_replace(admin_level, E'\\D', '', 'g')::SMALLINT AS admin_level, name, tags FROM planet_osm_polygon WHERE ST_Within(loc, way) AND admin_level IS NOT NULL AND name IS NOT NULL) AS s ORDER BY admin_level LIMIT 100
	LOOP
		IF (rec.admin_level = 2) THEN
			country := rec.tags->'name:en';
			country_iso := rec.tags->'ISO3166-1';
			IF (city IS NOT NULL) THEN
				EXIT;
			END IF;
			IF (country_iso = 'NL') THEN
				level := 9;
			ELSIF (country_iso = 'GB') THEN
				level := 10;
			ELSE
				level := 8;
			END IF;
		ELSIF ((rec.admin_level > 2) AND (rec.admin_level <= level)) THEN
			city := rec.name;
		END IF;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
