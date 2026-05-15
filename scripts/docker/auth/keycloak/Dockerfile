FROM quay.io/keycloak/keycloak:9.0.3@sha256:828e92baa29aee2fdf30cca0e0aeefdf77ca458d6818ebbd08bf26f1c5c6a7cf

ADD development_realm.json /etc/keycloak/

ENV KEYCLOAK_USER=admin
ENV KEYCLOAK_PASSWORD=admin
ENV DB_VENDOR=h2
ENV KEYCLOAK_IMPORT=/etc/keycloak/development_realm.json
