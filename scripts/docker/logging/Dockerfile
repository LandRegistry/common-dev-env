FROM python:3.10.4-slim
ENV PYTHONUNBUFFERED yes

# Add Tini
COPY tini .
RUN chmod +x tini
ENTRYPOINT ["/tini", "-e", "143", "--"]

CMD ["/run.sh"]

COPY server.py .
COPY run.sh .
RUN chmod +x run.sh
