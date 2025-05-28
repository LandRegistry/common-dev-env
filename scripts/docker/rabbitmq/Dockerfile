# This is so a reset (dc down) won't remove the base rabbit image, only the one created from this dockerfile
FROM quay.io/lib/rabbitmq:3-management
# Copy the configuration file to rabbitmq
# https://www.rabbitmq.com/configure.html#configuration-files
COPY rabbitmq.conf /etc/rabbitmq/
# Copy certs for TLS
# Nice tool here from rabbit for generating https://github.com/rabbitmq/tls-gen
COPY certs/ca_certificate.pem certs/server_certificate.pem certs/server_key.pem certs/
# This plugin adds a consistent-hash exchange type to RabbitMQ. This exchange type uses consistent hashing to 
# distribute messages between the bound queues
RUN rabbitmq-plugins --offline enable rabbitmq_consistent_hash_exchange
# This is a RabbitMQ plugin adds message transfer and management functionality.
# Handy for tasks such as bulk moving msgs for a DLQ.
# https://www.rabbitmq.com/shovel.html
RUN rabbitmq-plugins --offline enable rabbitmq_shovel rabbitmq_shovel_management
# This is a RabbitMQ plugin that exposes streams. 
# Streams are a new persistent and replicated data structure, handy to persist historic messages for a period of time
# https://www.rabbitmq.com/stream.html
RUN rabbitmq-plugins --offline enable rabbitmq_stream
