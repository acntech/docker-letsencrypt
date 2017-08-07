#!/bin/bash

set -e

if [ -z "${LETSENCRYPT_HOME}" ]; then
   echo "No environment variable set for Let's Encrypt home folder \$LETSENCRYPT_HOME"
   exit 1
fi

if [ ! -d "${LETSENCRYPT_HOME}" ]; then
   echo "Let's Encrypt home folder does not exist as specified in \$LETSENCRYPT_HOME environment variable: ${LETSENCRYPT_HOME}"
   exit 1
fi

if [ ! -f "${LETSENCRYPT_HOME}/bin/letsencrypt-wrapper.sh" ]; then
   echo "Can not find Let's Encrypt wrapper script in Let's Encrypt home folder: ${LETSENCRYPT_HOME}/bin"
   exit 1
fi

if [ -z "${LETSENCRYPT_LOG_DIR}" ]; then
   echo "No environment variable set for Let's Encrypt log folder \$LETSENCRYPT_LOG_DIR"
   exit 1
fi

if [ ! -d "${LETSENCRYPT_LOG_DIR}" ]; then
   echo "Let's Encrypt log folder does not exist as specified in \$LETSENCRYPT_LOG_DIR environment variable: ${LETSENCRYPT_LOG_DIR}"
   exit 1
fi

if [ ! -f "${LETSENCRYPT_LOG_DIR}/letsencrypt.log" ]; then
   touch "${LETSENCRYPT_LOG_DIR}/letsencrypt.log"
fi

echo ""
echo "########################################################"
echo "#                                                      #"
echo "#     Let's Encrypt Docker container ready to run!     #"
echo "#                                                      #"
echo "########################################################"
echo ""

cron && tail -f "${LETSENCRYPT_LOG_DIR}/letsencrypt.log"
