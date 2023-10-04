FROM docker.io/postgres:13

# For some reason some people get hash mismatch issues. This tries to resolve that.
# See https://askubuntu.com/questions/1121093/hash-sum-mismatches-in-18-04-on-laptop-and-in-docker
RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

# Install the PostGIS extension
RUN apt-get update && \
	apt-get install -y postgresql-13-postgis-3 && \
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
