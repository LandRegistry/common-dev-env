FROM icr.io/ibm-messaging/mq:9.3.3.0-r2

# Auto-accept the license
# Create default users and channels
ENV LICENSE=accept \
  MQ_DEV=true \
  MQ_ENABLE_METRICS=false \
  MQ_QMGR_NAME=LOCAL_QM

# For persistence
VOLUME /mnt/mqm
