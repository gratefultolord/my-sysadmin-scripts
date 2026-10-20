FROM ubuntu:22.04

WORKDIR /app

COPY script.sh /app/script.sh

RUN chmod +x /app/script.sh

CMD ["/app/script.sh"]
