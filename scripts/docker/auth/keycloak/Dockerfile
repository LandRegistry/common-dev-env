FROM jboss/keycloak:7.0.0

ADD development_realm.json /etc/keycloak/


# Note we can't use KEYCLOAK_HOSTNAME and KEYCLOAK_HTTP_PORT due to the way it is implemented in the entry script
ENV SYS_PROPS="-Dkeycloak.hostname.provider=fixed -Dkeycloak.hostname.fixed.hostname=keycloak -Djboss.http.port=8180"
ENV KEYCLOAK_USER=admin
ENV KEYCLOAK_PASSWORD=admin
ENV DB_VENDOR=h2
ENV KEYCLOAK_IMPORT=/etc/keycloak/development_realm.json
