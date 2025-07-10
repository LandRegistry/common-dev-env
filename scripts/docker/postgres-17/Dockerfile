FROM quay.io/lib/postgres:17

# Install the PostGIS extension
RUN apt-get update && \
	apt-get install -y postgresql-17-postgis-3 && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# This user will be created as the superuser
# PG* are for dev use - while in the container psql will just work (useful for the provisioning)
ENV POSTGRES_USER=root \
 POSTGRES_PASSWORD=superroot \
 PGUSER=root \
 PGPASSWORD=superroot

 HEALTHCHECK --interval=10s --retries=20  \
  CMD pg_isready -h localhost || exit 1
