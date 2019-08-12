FROM hmlandregistry/db2_developer_c:11.1.4.4-x86_64

EXPOSE 50000 55000

VOLUME /database

HEALTHCHECK --interval=10s --start-period=60s --retries=20  \
  CMD pgrep db2fmcd || exit 1
