FROM docker.io/nginx:1.30.0@sha256:1a9ab83e2892b75773978e8d91f42a7a2a0d8bb704959a51ff17c0377481973d

RUN rm /etc/nginx/conf.d/default.conf && \
  mkdir /etc/nginx/ssl && \
  mkdir /etc/nginx/configs && \
  openssl req -x509 -noenc -newkey rsa:2048 -keyout /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/req.pem -days 90 -subj "/C=GB/ST=Devon/L=Plymouth/O=HM Land Registry/OU=DDaT/CN=localhost"

# The base server config, which sets up the SSL etc.
COPY nginx.conf /etc/nginx/conf.d

# To ensure our changes and config fragments we copy in are actually persisted in between container recreates.
# This has to go at the end as the data is frozen once the volume is declared
VOLUME /etc/nginx
