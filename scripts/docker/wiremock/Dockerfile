FROM docker.io/eclipse-temurin:25.0.2_10-jre-ubi10-minimal@sha256:c897ce903faf6736e4b5cbb2dd5e05e6b74909d71105f3cfe33840b3ce7b8b21

ARG WM_VERSION=3.13.2

RUN mkdir -p /wiremock/mappings && cd /wiremock && \
    curl -sSL -o wiremock.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/$WM_VERSION/wiremock-standalone-$WM_VERSION.jar

WORKDIR /wiremock

# To ensure our fragments we copy in are actually persisted in between container recreates.
VOLUME /wiremock/mappings

CMD ["java","-jar","wiremock.jar", "--global-response-templating"]
