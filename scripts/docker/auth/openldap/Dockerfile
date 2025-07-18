FROM quay.io/lib/debian:11

# For some reason some people get hash mismatch issues. This tries to resolve that.
# See https://askubuntu.com/questions/1121093/hash-sum-mismatches-in-18-04-on-laptop-and-in-docker
RUN printf "Acquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy true;" > /etc/apt/apt.conf.d/99fixbadproxy

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils ldapscripts && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /etc/ldap/schema

ADD schema/* /etc/ldap/schema/
ADD slapd.conf base.ldif config.ldif /etc/ldap/
RUN rm -rf /etc/ldap/slapd.d/* && \
  mkdir -p /var/run/openldap && \
  slaptest -f /etc/ldap/slapd.conf -F /etc/ldap/slapd.d && \
  slapadd -F /etc/ldap/slapd.d -l /etc/ldap/base.ldif && \
  slapadd -n 0 -F /etc/ldap/slapd.d -l /etc/ldap/config.ldif && \
  rm /etc/ldap/base.ldif && \
  rm /etc/ldap/config.ldif && \
  chown -R openldap:openldap /etc/ldap/slapd.d /var/run/openldap

COPY tini /
RUN chmod +x tini

EXPOSE 389
VOLUME /var/lib/ldap

ENTRYPOINT ["/tini", "--", "slapd", "-u", "openldap", "-g", "openldap", "-h", "ldap:///", "-d", "stats,stats2"]
