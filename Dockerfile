FROM ubuntu

MAINTAINER Thomas Johansen "thomas.johansen@accenture.com"


ARG CERTBOT_URL=https://dl.eff.org/certbot-auto


ENV LETSENCRYPT_HOME /opt/letsencrypt
ENV LETSENCRYPT_BIN_DIR ${LETSENCRYPT_HOME}/bin
ENV LETSENCRYPT_CERTS_DIR ${LETSENCRYPT_HOME}/certs
ENV LETSENCRYPT_LOG_DIR ${LETSENCRYPT_HOME}/logs
ENV PATH $PATH:${LETSENCRYPT_BIN_DIR}
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install apt-utils wget vim cron

RUN mkdir -p ${LETSENCRYPT_BIN_DIR}/

RUN mkdir -p ${LETSENCRYPT_CERTS_DIR}/

RUN mkdir -p ${LETSENCRYPT_LOG_DIR}/

RUN wget --no-cookies \
         --no-check-certificate \
         ${CERTBOT_URL} \
         -O ${LETSENCRYPT_BIN_DIR}/certbot-auto

RUN chmod a+x ${LETSENCRYPT_BIN_DIR}/certbot-auto


COPY resources/letsencrypt-wrapper.sh ${LETSENCRYPT_BIN_DIR}/letsencrypt-wrapper.sh

COPY resources/crontab.sh ${LETSENCRYPT_BIN_DIR}/crontab.sh

COPY resources/entrypoint.sh /entrypoint.sh


RUN crontab ${LETSENCRYPT_BIN_DIR}/crontab.sh


VOLUME ${LETSENCRYPT_CERTS_DIR}

VOLUME ${LETSENCRYPT_LOG_DIR}


EXPOSE 80 443


CMD ["/entrypoint.sh"]
