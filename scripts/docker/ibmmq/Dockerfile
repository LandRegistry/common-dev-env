FROM icr.io/ibm-messaging/mq:9.3.3.0-r2

# Auto-accept the license
# Create default users and channels
ENV LICENSE=accept \
  MQ_DEV=true \
  MQ_ENABLE_METRICS=false \
  MQ_QMGR_NAME=LOCAL_QM

# Add a special run script that stops the web server manually when stop signal received
# Due to https://github.com/ibm-messaging/mq-container/issues/523
COPY tini run.sh /tmp/
USER 0
RUN chmod +x /tmp/tini && chmod +x /tmp/run.sh
USER 1001
ENTRYPOINT ["/tmp/tini", "-g", "--", "/tmp/run.sh"]

# For persistence
VOLUME /mnt/mqm
