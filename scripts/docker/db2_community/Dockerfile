FROM ibmcom/db2:11.5.0.0a

EXPOSE 50000 55000

VOLUME /database

HEALTHCHECK --interval=10s --start-period=60s --retries=20  \
  CMD pgrep db2fmcd || exit 1
