FROM ibmcom/db2express-c:10.5.0.5-3.10.0

# Default user
ENV DB2INST1_PASSWORD db2inst1-pwd
ENV DB2INST1_USERNAME db2inst1
ENV LICENSE accept

EXPOSE 50000

VOLUME /home/db2inst1

CMD ["db2start"]
