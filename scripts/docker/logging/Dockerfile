FROM docker.io/python:3.14.4-slim@sha256:c11aee3b3cae066f55d1e9318fc812673aa6557073b0db0d792b59491b262e0c

ENV PYTHONUNBUFFERED=yes
COPY tini server.py run.sh /
RUN chmod 755 /tini /server.py /run.sh

ENTRYPOINT ["/tini", "-e", "143", "--"]
CMD ["/run.sh"]
