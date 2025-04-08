ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

RUN apk add --no-cache duplicity py3-boto3

COPY run.sh /
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
