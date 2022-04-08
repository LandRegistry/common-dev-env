FROM ibmcom/mq:9.2.4.0-r1

# Auto-accept the license
# Create default users and channels
ENV LICENSE=accept \
  MQ_DEV=true \
  MQ_QMGR_NAME=LOCAL_QM

# For persistence
VOLUME /mnt/mqm
