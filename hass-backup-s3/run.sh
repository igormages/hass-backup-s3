#!/usr/bin/with-contenv bashio

CONFIG_PATH=/data/options.json

#####################
## USER PARAMETERS ##
#####################

# REQUIRED
BUCKET_NAME="s3://$(bashio::config 'bucketName')"
export ENDPOINT_URL="$(bashio::config 'endpointUrl')"
export REGION="$(bashio::config 'region')"
export AWS_ACCESS_KEY_ID="$(bashio::config 'accessKey')"
export AWS_SECRET_ACCESS_KEY="$(bashio::config 'secretKey')"
export GPG_FINGERPRINT="$(bashio::config 'GPGFingerprint')"
export PASSPHRASE="$(bashio::config 'GPGPassphrase')"
export SOURCE_DIR="$(bashio::config 'sourceDir')"
RESTORE="$(bashio::config 'restore')"

# OPTIONNAL
DAY_BEFORE_FULL_BACKUP="$(bashio::config 'incrementalFor')"
DAY_BEFORE_REMOVING_OLD_BACKUP="$(bashio::config 'removeOlderThan')"

###########
## MAIN  ##
###########

############################
## SET DUPLICITY OPTIONS  ##
############################

NO_ENCRYPTION=""
if [[ -z "${GPG_FINGERPRINT}" ]] || [[ -z "${PASSPHRASE}" ]]; then
    NO_ENCRYPTION='--no-encryption'
else
    echo "🔐 Encrypting snapshots before upload $(ls -l /backup)"
fi

DUPLICITY_FULL_BACKUP_AFTER=""
if [[ -n ${DAY_BEFORE_FULL_BACKUP} ]]; then
	DUPLICITY_FULL_BACKUP_AFTER="--full-if-older-than=${DAY_BEFORE_FULL_BACKUP}"
fi

# Exclude paths — left empty but preserved for extensibility
EXCLUDE_ARGS=""

echo "🌀 Duplicity version: $(duplicity --version)"

############################
## BACKUP or RESTORE MODE ##
############################

if [[ ${RESTORE} == "true" ]]; then
    echo "♻️  Restoring backups from ${BUCKET_NAME} to ${SOURCE_DIR}"
    duplicity restore \
      ${NO_ENCRYPTION} \
      --file-prefix-manifest manifest- \
      --s3-endpoint-url "${ENDPOINT_URL}" \
      --s3-region-name "${REGION}" \
      --force \
      "${BUCKET_NAME}" \
      "${SOURCE_DIR}"
else
    echo "📦 Backing up content of ${SOURCE_DIR} to ${BUCKET_NAME}"
    duplicity \
      incr \
      ${NO_ENCRYPTION} \
      ${EXCLUDE_ARGS} \
      --allow-source-mismatch \
      --s3-endpoint-url "${ENDPOINT_URL}" \
      --s3-region-name "${REGION}" \
      --file-prefix-manifest manifest- \
      ${DUPLICITY_FULL_BACKUP_AFTER} \
      "${SOURCE_DIR}" \
      "${BUCKET_NAME}"

    if [[ -n ${DAY_BEFORE_REMOVING_OLD_BACKUP} ]]; then
        echo "🧹 Removing backups older than ${DAY_BEFORE_REMOVING_OLD_BACKUP} from ${BUCKET_NAME}"
        duplicity \
          remove-older-than ${DAY_BEFORE_REMOVING_OLD_BACKUP} \
          --force \
          ${NO_ENCRYPTION} \
          ${EXCLUDE_ARGS} \
          --allow-source-mismatch \
          --s3-endpoint-url "${ENDPOINT_URL}" \
          --s3-region-name "${REGION}" \
          --file-prefix-manifest manifest- \
          "${BUCKET_NAME}"
    fi
fi
