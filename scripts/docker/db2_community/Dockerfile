FROM docker.io/hmlandregistry/db2-cgroupaware:11.5.9.0@sha256:b505db3567ca183260f3d946c2c2d86f5c5ee1def45148fbe15eb0d85b41539e

EXPOSE 50000 55000

VOLUME /database

HEALTHCHECK --interval=10s --start-period=20s --retries=40  \
  CMD /database/config/$DB2INSTANCE/sqllib/bin/db2gcf -s && [ -f /var/readiness/ready ] && echo 'File is present'
