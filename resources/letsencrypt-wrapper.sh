#!/bin/bash

NOTIFICATION_EMAIL_ACTIVE=${NOTIFICATION_EMAIL_ACTIVE:-false}
NOTIFICATION_EMAIL_SUBJECT="Let's Encrypt certificates renewal on $(hostname)"
NOTIFICATION_EMAIL_BODY="Let's Encrypt certificates for server $(hostname) have been renewed"

LETSENCRYPT_COMMAND="${LETSENCRYPT_HOME}/bin/certbot-auto"
LETSENCRYPT_LIVE_DIR="/etc/letsencrypt/live"
LETSENCRYPT_HTTP_PORT=${LETSENCRYPT_HTTP_PORT:-80}
LETSENCRYPT_HTTPS_PORT=${LETSENCRYPT_HTTPS_PORT:-443}
LETSENCRYPT_CERT_KEY_SIZE=${LETSENCRYPT_CERT_KEY_SIZE:-4096}
LETSENCRYPT_PROCESS_DOMAINS_ARRAY=()

if ${NOTIFICATION_EMAIL_ACTIVE} ; then
   if [ -z "${NOTIFICATION_EMAIL_SENDER}" ]; then
      echo "No environment variable set for notification email sender \$NOTIFICATION_EMAIL_SENDER"
      exit 1
   fi

   if [ -z "${NOTIFICATION_EMAIL_RECIPIENTS}" ]; then
      echo "No environment variable set for notification email recipients \$NOTIFICATION_EMAIL_RECIPIENTS"
      exit 1
   else
      IFS=',' read -r -a NOTIFICATION_EMAIL_RECIPIENTS_ARRAY <<< "${NOTIFICATION_EMAIL_RECIPIENTS}"
   fi
fi

if [ -z "${LETSENCRYPT_DOMAINS}" ]; then
   echo "No environment variable set for Let's Encrypt domains \$LETSENCRYPT_DOMAINS"
   exit 1
else
   IFS=',' read -r -a LETSENCRYPT_DOMAINS_ARRAY <<< "${LETSENCRYPT_DOMAINS}"
fi

if [ -z "${LETSENCRYPT_REG_EMAIL}" ]; then
   echo "No environment variable set for Let's Encrypt registration email \$LETSENCRYPT_REG_EMAIL"
   exit 1
fi

if [ -z "${LETSENCRYPT_HOME}" ]; then
   echo "No environment variable set for Let's Encrypt home folder \$LETSENCRYPT_HOME"
   exit 1
fi

if [ ! -d "${LETSENCRYPT_HOME}" ]; then
   echo "Let's Encrypt home folder does not exist as specified in \$LETSENCRYPT_HOME environment variable: ${LETSENCRYPT_HOME}"
   exit 1
fi

if [ -z "${LETSENCRYPT_CERTS_DIR}" ]; then
   echo "No environment variable set for Let's Encrypt certificates folder \$LETSENCRYPT_CERTS_DIR"
   exit 1
fi

if [ ! -d "${LETSENCRYPT_CERTS_DIR}" ]; then
   echo "Let's Encrypt certificates folder does not exist as specified in \$LETSENCRYPT_CERTS_DIR environment variable: ${LETSENCRYPT_CERTS_DIR}"
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

if [ ! -f "${LETSENCRYPT_COMMAND}" ]; then
   echo "Can not find Let's Encrypt script as specified in \$LETSENCRYPT_COMMAND environment variable: ${LETSENCRYPT_COMMAND}"
   exit 1
fi

MESSAGE=""

log() {
   local message=$1
   local level=${2:-INFO}

   echo "$(date +'%F %T.%3N %Z') ${level} - ${message}"
}

send_email() {
   local sender=$1
   local recipient=$2
   local subject=$3
   local body=$4

   if [ -z "${recipient}" ]; then
      log "Email recipient is not set"
      return 1
   fi

   if [ -z "${subject}" ]; then
      log "Email subject is not set"
      return 1
   fi

   if [ -z "${body}" ]; then
      body="${subject}"
   fi

   if echo "${body}" | mail -s "${subject}" "${recipient}" -aFrom:${sender} ; then
      log "Email sent to recipient ${recipient} from sender ${sender}"
      return 0
   else
      log "Unable to send email to recipient ${recipient} from sender ${sender}"
      return 1
   fi
}

send_emails() {
   if ${NOTIFICATION_EMAIL_ACTIVE} ; then
      for email_recipient in "${NOTIFICATION_EMAIL_RECIPIENTS_ARRAY[@]}" ; do
         send_email "${EMAIL_SENDER}" "${email_recipient}" "${MESSAGE}"
      done
   else
      log "Email sending inactive"
   fi
}

handle_error() {
   if [ ! -z "${MESSAGE}" ]; then
      log "$MESSAGE" "ERROR"
   fi

   send_emails

   echo "###  Certificate renewal process completed with error at $(date +'%F %T.%3N %Z')  ###"

   exit 1
}

handle_success() {
   if [ ! -z "${MESSAGE}" ]; then
      log "$MESSAGE"
   fi

   send_emails

   echo "###  Certificate renewal process completed successfully at $(date +'%F %T.%3N %Z')  ###"

   exit 0
}

handle_exit() {
   local status=$?

   case ${status} in
      0) handle_success
         ;;
      *) handle_error
         ;;
   esac
}

letsencrypt_retrieve_new_certificate() {
   local domain=$1
   
   ${LETSENCRYPT_COMMAND} certonly \
               --standalone \
               --email ${LETSENCRYPT_REG_EMAIL} \
               --agree-tos \
               --noninteractive \
               --preferred-challenges http \
               --http-01-port ${LETSENCRYPT_HTTP_PORT} \
               --tls-sni-01-port ${LETSENCRYPT_HTTPS_PORT} \
               --rsa-key-size ${LETSENCRYPT_CERT_KEY_SIZE} \
               --domains ${domain} \
               > ${LETSENCRYPT_LOG_DIR}/retrieve_${domain}.log 2>&1
   
   return $?
}

letsencrypt_renew_old_certificates() {
   ${LETSENCRYPT_COMMAND} renew \
               --standalone \
               --email ${LETSENCRYPT_REG_EMAIL} \
               --agree-tos \
               --noninteractive \
               --preferred-challenges http \
               --http-01-port ${LETSENCRYPT_HTTP_PORT} \
               --tls-sni-01-port ${LETSENCRYPT_HTTPS_PORT} \
               --rsa-key-size ${LETSENCRYPT_CERT_KEY_SIZE} \
               > ${LETSENCRYPT_LOG_DIR}/renew.log 2>&1
   
   return $?
}

find_text_in_file() {
   local text_file=$1
   local text_to_find=$2

   tail "${text_file}" | grep "${text_to_find}" > /dev/null 2>&1

   return $?
}

retrieve_new_certificate() {
   local domain=$1

   log "Retrieving new certificate for domain ${domain}..."
   if ! letsencrypt_retrieve_new_certificate "${domain}" ; then
      MESSAGE="Automated retrieval of certificates for domain ${domain} failed. Check ${LETSENCRYPT_LOG_DIR}/retrieve_${domain}.log for details."
      exit 1
   else
      LETSENCRYPT_PROCESS_DOMAINS_ARRAY+=("${domain}")
   fi
}

retrieve_new_certificates() {
   log "Executing automated retrieval of new certificates."
   for domain in "${LETSENCRYPT_DOMAINS_ARRAY[@]}" ; do
      if [ ! -d "${LETSENCRYPT_LIVE_DIR}/${domain}" ]; then
         retrieve_new_certificate "${domain}"
      else
         log "Certificate for domain ${domain} already exists."
      fi
   done
}

combine_new_certificate() {
   local domain=$1
   local letsencrypt_domain_dir="${LETSENCRYPT_LIVE_DIR}/${domain}"
   local letsencrypt_cert_file="${LETSENCRYPT_CERTS_DIR}/${domain}.pem"

   log "Activating certificate from ${letsencrypt_domain_dir} to ${letsencrypt_cert_file}."
   if ! cat "${letsencrypt_domain_dir}/fullchain.pem" "${letsencrypt_domain_dir}/privkey.pem" > ${letsencrypt_cert_file} ; then
      MESSAGE="Failed to activate certificate ${letsencrypt_cert_file}."
      exit 1
   fi
}

backup_certificate() {
   local domain=$1
   local letsencrypt_domain_dir="${LETSENCRYPT_LIVE_DIR}/${domain}"
   local letsencrypt_cert_file="${LETSENCRYPT_CERTS_DIR}/${domain}.pem"
   local letsencrypt_cert_file_backup_file="${letsencrypt_domain_dir}/${domain}.pem.$(date +'%Y%m%d%H%M%S')"

   if [ -f "${letsencrypt_cert_file}" ]; then
      log "Backing up old certificate ${letsencrypt_cert_file} to ${letsencrypt_cert_file_backup_file}..."
      if ! mv "${letsencrypt_cert_file}" "${letsencrypt_cert_file_backup_file}" ; then
         MESSAGE="Failed to backup old certificate ${letsencrypt_cert_file}."
         exit 1
      fi
   else
      log "Certificate ${letsencrypt_cert_file} for domain ${domain} not found, so skipping backup."
   fi
}

renew_old_certificates() {
   log "Executing automated renewal of certificates."
   if ! letsencrypt_renew_old_certificates ; then
      MESSAGE="Automated renewal of certificates failed. Check ${LETSENCRYPT_LOG_DIR}/renew.log for details."
      exit 1
   fi
}

process_old_certificate() {
   local domain=$1
   local skipped_line="${domain}/fullchain.pem (skipped)"

   if ! find_text_in_file "${LETSENCRYPT_LOG_DIR}/renew.log" "${skipped_line}" ; then
      log "Certificate for domain ${domain} has been renewed, processing..."
      backup_certificate "${domain}"
      combine_new_certificate "${domain}"
   else
      log "Certificate for domain ${domain} has not been renewed"
   fi
}

process_new_certificate() {
   local domain=$1

   log "Certificate for domain ${domain} was retrieved, processing..."
   combine_new_certificate "${domain}"
}

process_certificates() {
   local all_skipped_line="No renewals were attempted"
   
   if ! find_text_in_file "${LETSENCRYPT_LOG_DIR}/renew.log" "${all_skipped_line}" ; then
      log "One or more certificates was renewed"
      for domain in "${LETSENCRYPT_DOMAINS_ARRAY[@]}" ; do
         process_old_certificate "${domain}"
      done
      MESSAGE="One or more certificates renewed successfully"
   elif [ ${#LETSENCRYPT_PROCESS_DOMAINS_ARRAY[@]} -ne 0 ]; then
      for domain in "${LETSENCRYPT_PROCESS_DOMAINS_ARRAY[@]}" ; do
         process_new_certificate "${domain}"
      done
   else
      log "No certificates needed renewal"
      NOTIFICATION_EMAIL_ACTIVE=false
   fi
}

run_pre_hook() {
   if [ ! -z "${PRE_HOOK_COMMAND}" ]; then
      bash -c "${PRE_HOOK_COMMAND}"
      if [ $? ]; then
         log "Pre hook command completed successfully"
      else
         log "Pre hook command failed" "ERROR"
      fi
   else
      log "No pre hook command set"
   fi
}

run_post_hook() {
   if [ ! -z "${POST_HOOK_COMMAND}" ]; then
      bash -c "${POST_HOOK_COMMAND}"
      if [ $? ]; then
         log "Post hook command completed successfully"
      else
         log "Post hook command failed" "ERROR"
      fi
   else
      log "No post hook command set"
   fi
}

echo "###  Starting certificate renewal process at $(date +'%F %T.%3N %Z')  ###"

trap handle_error ERR
trap handle_exit EXIT

run_pre_hook
retrieve_new_certificates
renew_old_certificates
process_certificates
run_post_hook

exit 0;