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

bash -c "${LETSENCRYPT_HOME}/bin/letsencrypt-wrapper.sh"
