CREATE DATABASE skeleton; 
CREATE ROLE skeletonapiuser WITH LOGIN PASSWORD 'skeletonapipassword';

# Need to connect to the database we have just created in order to create the extensions
\c skeleton

-- Enable PostGIS (includes raster)
CREATE EXTENSION postgis;