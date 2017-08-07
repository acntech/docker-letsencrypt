#
# Crontab for Let's Encrypt
#

10 5 * * * "${LETSENCRYPT_HOME}/bin/letsencrypt-wrapper.sh" > "${LETSENCRYPT_LOG_DIR}/letsencrypt.log"
