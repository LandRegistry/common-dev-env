FROM docker.io/postgres:17.9@sha256:5b96f1a16bd9768b060dd2ffe55cb6225c4d9ef4d214a8b21eb08134869a97e4

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
