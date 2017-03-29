#!/bin/bash

set -e

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

echo "Let's Encrypt Docker container ready to run!"
echo "Start certificat retrieval and renewal process by executing:"
echo "   docker exec -it <container name> /letsencrypt.sh"

tail -f "${LETSENCRYPT_LOG_DIR}/letsencrypt.log"
