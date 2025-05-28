FROM docker.elastic.co/elasticsearch/elasticsearch:7.17.28

ENV ES_JAVA_OPTS="-Xms1024m -Xmx1024m"
ENV discovery.type=single-node

# Remove default heap size and add low-memory optimisations
RUN echo "bootstrap.memory_lock: true" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.fielddata.cache.size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.memory.index_buffer_size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml
