FROM ubuntu:latest
RUN apt-get update
RUN apt-get install -y jq
COPY check in out /opt/resource/
RUN chmod +x /opt/resource/*