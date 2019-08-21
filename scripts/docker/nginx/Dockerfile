FROM nginx:1.16

RUN apt-get update && apt-get install openssl && \
  rm /etc/nginx/conf.d/default.conf && \
  mkdir /etc/nginx/ssl && \
  mkdir /etc/nginx/configs && \
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/ssl.key -out /etc/nginx/ssl/ssl.crt -subj "/C=GB/ST=devon/L=plymouth/O=land_registry/OU=seaton_court/CN=testsslkey/emailAddress=testsslkey@landregistry.gov.uk"

# The base server config, which sets up the SSL etc.
COPY server.conf /etc/nginx/conf.d/server.conf

# To ensure our changes and config fragments we copy in are actually persisted in between container recreates.
# This has to go at the end as the data is frozen once the volume is declared
VOLUME /etc/nginx
