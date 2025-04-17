FROM quay.io/lib/nginx:1.26

RUN rm /etc/nginx/conf.d/default.conf && \
  mkdir /etc/nginx/ssl && \
  mkdir /etc/nginx/configs && \
  openssl req -x509 -noenc -newkey rsa:2048 -keyout /etc/nginx/ssl/key.pem -out /etc/nginx/ssl/req.pem -days 90 -subj "/C=GB/ST=Devon/L=Plymouth/O=HM Land Registry/OU=DDaT/CN=localhost"

# The base server config, which sets up the SSL etc.
COPY nginx.conf /etc/nginx/conf.d

# To ensure our changes and config fragments we copy in are actually persisted in between container recreates.
# This has to go at the end as the data is frozen once the volume is declared
VOLUME /etc/nginx
