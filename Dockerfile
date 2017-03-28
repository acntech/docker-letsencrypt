FROM ubuntu
MAINTAINER Thomas Johansen "thomas.johansen@accenture.com"


ARG CERTBOT_URL=https://dl.eff.org/certbot-auto


ENV LETSENCRYPT_HOME /opt/letsencrypt
ENV LETSENCRYPT_CERTS_DIR ${LETSENCRYPT_HOME}/certs
ENV LETSENCRYPT_LOG_DIR ${LETSENCRYPT_HOME}/logs
ENV PATH $PATH:${LETSENCRYPT_HOME}/bin
ENV DEBIAN_FRONTEND noninteractive


RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install apt-utils wget

RUN mkdir -p ${LETSENCRYPT_HOME}/bin

RUN mkdir -p ${LETSENCRYPT_CERTS_DIR}

RUN mkdir -p ${LETSENCRYPT_LOG_DIR}

RUN wget --no-cookies \
         --no-check-certificate \
         ${CERTBOT_URL} \
         -O ${LETSENCRYPT_HOME}/bin/certbot-auto

RUN chmod a+x ${LETSENCRYPT_HOME}/bin/certbot-auto


COPY resources/letsencrypt-wrapper.sh ${LETSENCRYPT_HOME}/bin/letsencrypt-wrapper.sh

COPY resources/entrypoint.sh /entrypoint.sh


EXPOSE 80 443


CMD ["/entrypoint.sh"]