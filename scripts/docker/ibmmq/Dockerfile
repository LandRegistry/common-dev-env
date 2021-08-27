FROM ibmcom/mq:9.2.0.0-r1

# Auto-accept the license
# Do not create default users and channels
# Ensure the created queue manager is the name we want
ENV LICENSE=accept \
  MQ_DEV=false \
  MQ_QMGR_NAME=LOCAL_QM

# For persistence
VOLUME /mnt/mqm

# Get our scripts into a place they will be auto-run on first startup
COPY queue_manager.mqsc /etc/mqm/queue_manager.mqsc
COPY queues.mqsc /etc/mqm/queues.mqsc
