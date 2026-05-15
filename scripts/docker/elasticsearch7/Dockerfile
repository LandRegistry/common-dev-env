FROM docker.elastic.co/elasticsearch/elasticsearch:7.17.29@sha256:3f55a7f6f29b95345dc33808d6e914f81d125d4ca90a414e26c81a3521400980

ENV ES_JAVA_OPTS="-Xms1024m -Xmx1024m"
ENV discovery.type=single-node

# Remove default heap size and add low-memory optimisations
RUN echo "bootstrap.memory_lock: true" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.fielddata.cache.size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.memory.index_buffer_size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml
