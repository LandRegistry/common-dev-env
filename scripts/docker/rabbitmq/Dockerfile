# This is so a reset (dc down) won't remove the base rabbit image, only the one created from this dockerfile
FROM rabbitmq:3-management
RUN rabbitmq-plugins enable rabbitmq_consistent_hash_exchange
