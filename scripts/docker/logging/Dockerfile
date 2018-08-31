FROM python:3.7.0
ENV PYTHONUNBUFFERED yes

ADD server.py .

# Run the app, copying all stdout to log.txt
CMD python ./server.py | tee /log-dir/log.txt