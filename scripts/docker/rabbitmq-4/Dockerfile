FROM docker.io/rabbitmq:4.2.6-management-alpine@sha256:cef1d5e13ce97724aa78b94e36e50fbe174a7623b8912da8b293dec1510a947f
# Copy the configuration file to rabbitmq
# https://www.rabbitmq.com/configure.html#configuration-files
COPY rabbitmq.conf /etc/rabbitmq/
# Copy certs for TLS
# Nice tool here from rabbit for generating https://github.com/rabbitmq/tls-gen
COPY certs/ca_certificate.pem certs/server_certificate.pem certs/server_key.pem certs/
# rabbitmq_consistent_hash_exchange: This plugin adds a consistent-hash exchange type to RabbitMQ. This exchange type uses consistent hashing to 
# distribute messages between the bound queues
# rabbitmq_shovel: This is a RabbitMQ plugin adds message transfer and management functionality.
# Handy for tasks such as bulk moving msgs for a DLQ.
# https://www.rabbitmq.com/shovel.html
# rabbitmq_stream: This is a RabbitMQ plugin that exposes streams. 
# Streams are a new persistent and replicated data structure, handy to persist historic messages for a period of time
# https://www.rabbitmq.com/stream.html
# rabbitmq_prometheus: Expose Prometheus metrics for monitoring/dashboards.
RUN rabbitmq-plugins --offline enable rabbitmq_consistent_hash_exchange rabbitmq_shovel rabbitmq_shovel_management rabbitmq_stream rabbitmq_prometheus
