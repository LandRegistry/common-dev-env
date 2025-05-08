FROM docker.elastic.co/elasticsearch/elasticsearch:5.6.16

ENV ES_JAVA_OPTS="-Xms1024m -Xmx1024m"

# Remove default heap size and add low-memory optimisations
RUN echo "bootstrap.memory_lock: true" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.fielddata.cache.size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 echo "indices.memory.index_buffer_size: 50%" >> /usr/share/elasticsearch/config/elasticsearch.yml && \
 sed -i -e 's/.*Xms2g.*//' /etc/elasticsearch/jvm.options && \
 sed -i -e 's/.*Xmx2g.*//' /etc/elasticsearch/jvm.options
