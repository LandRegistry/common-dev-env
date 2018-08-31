FROM hmlandregistry/dev_base_java:4

ENV WM_PACKAGE wiremock
ARG WM_VERSION=2.18.0

RUN mkdir /$WM_PACKAGE
WORKDIR /$WM_PACKAGE
RUN curl -sSL -o $WM_PACKAGE.jar https://repo1.maven.org/maven2/com/github/tomakehurst/$WM_PACKAGE-standalone/$WM_VERSION/$WM_PACKAGE-standalone-$WM_VERSION.jar

CMD ["java","-jar","wiremock.jar"]