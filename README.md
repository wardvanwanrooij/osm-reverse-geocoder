# osm-reverse-geocoder

## Overview
osm-reverse-geocoder is a simple reverse geocoder for OpenStreetMaps. It does not require the installation of Nominatim or other packages, only the imported PostgreSQL database. 
Latest version at https://github.com/wardvanwanrooij/osm-reverse-geocoder

## Performance
It takes about 0.2sec to reverse geocode a coordinate on my VPS (uncached, after reboot). You can benchmark your own installation with the included script by reverse geocoding 500 random (though fixed) coordinates in Europe. 

	export DBI_DSN="DBI:Pg:dbname=osm;host=127.0.0.1"
	export DBI_USER="osm"
	export DBI_PASS="***yourpassword***"
	perl benchmark.pl
	(...)
	took 98 seconds to process 500 coordinates, 0.20 sec/coordinate

## Installation
Install by loading the reverse_geocoder.sql script in your OSM database:

        $ psql osm -f reverse_geocoder.sql
        CREATE FUNCTION
        $       

Installation requirements are:

* Tags must be present in the database (--hstore option in osm2pgsql)
* OSM import must be done in the default coordinate system (EPSG:3857)

## Usage
Invoke the reverse geocoder by calling the reverse_geocode function with latitude and longitude (in WGS84) as parameters:

	osm=> SELECT * FROM reverse_geocode(52.380021, 5.195351);
	 country_iso |     country     |  city  |   street    | housenumber |     distance     
	-------------+-----------------+--------+-------------+-------------+------------------
	 NL          | The Netherlands | Almere | Sesamstraat | 32          | 8.68894216514979
	(1 row)
	osm=> 

Any or all return values can be NULL.

