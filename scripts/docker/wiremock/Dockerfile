FROM hmlandregistry/dev_base_java:5.1

ARG WM_VERSION=2.32.0

RUN mkdir -p /wiremock/mappings && cd /wiremock && \
  curl -sSL -o wiremock.jar https://repo1.maven.org/maven2/com/github/tomakehurst/wiremock-jre8-standalone/$WM_VERSION/wiremock-jre8-standalone-$WM_VERSION.jar

WORKDIR /wiremock

# To ensure our fragments we copy in are actually persisted in between container recreates.
VOLUME /wiremock/mappings

CMD ["java","-jar","wiremock.jar", "--global-response-templating"]
