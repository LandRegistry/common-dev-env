FROM quay.io/keycloak/keycloak:9.0.3

ADD development_realm.json /etc/keycloak/

ENV KEYCLOAK_USER=admin
ENV KEYCLOAK_PASSWORD=admin
ENV DB_VENDOR=h2
ENV KEYCLOAK_IMPORT=/etc/keycloak/development_realm.json
