FROM quay.io/lib/eclipse-temurin:21-jre-ubi9-minimal

ARG WM_VERSION=3.9.1

RUN mkdir -p /wiremock/mappings && cd /wiremock && \
    curl -sSL -o wiremock.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/$WM_VERSION/wiremock-standalone-$WM_VERSION.jar

WORKDIR /wiremock

# To ensure our fragments we copy in are actually persisted in between container recreates.
VOLUME /wiremock/mappings

CMD ["java","-jar","wiremock.jar", "--global-response-templating"]
