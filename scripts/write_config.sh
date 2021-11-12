#!/bin/bash

CONFIG_DIR="./conf"
CCNET_CONFIG_FILE="$CONFIG_DIR/ccnet.conf"
GUNICORN_CONFIG_FILE="$CONFIG_DIR/gunicorn.conf.py"
SEAHUB_CONFIG_FILE="$CONFIG_DIR/seahub_settings.py"
# Environment variables starting with the following prefix will be written to config file.
# Number can also be added right after the prefix to allow controlling the order of the variables
# in the generated file. e.g. SEAHUB_ABC='val' -> ABC='val', SEAHUB_001_DEF='val' -> DEF='val'
SEAHUB_SETTING_ENV_PREFIX='SEAHUB_'
GENERATED_CONTENT_HEADER='###### Generated Content Starts ######'

function clearGeneratedContent() {
    sed "/^${GENERATED_CONTENT_HEADER}$/,$d" "$1"
}

function generateConfig() {
    local cfg='# Generated Configuration..'$'\n'
    local env_var
    local var_name
    local var_value

    local env_vars="$(compgen -A variable | grep -E "$1.+" | sort)"
    for env_var in ${env_vars}; do
      var_name=$(echo ${env_var} | sed -r "s/^$1([0-9]+_)?//")
      var_value="${!var_name}"
      cfg="${cfg}"$'\n'"${var_name} = ${!var_value}"
    done

    echo "${cfg}"$'\n'
}

function writeCcnetConfig() {
    sed -ni '/General/!p' $CCNET_CONFIG_FILE
    sed -ni '/SERVICE_URL/!p' $CCNET_CONFIG_FILE
    echo "[General]" >> $CCNET_CONFIG_FILE
    echo "SERVICE_URL = http${HTTPS_SUFFIX}://${SERVER_IP}" >> $CCNET_CONFIG_FILE

    if [ "$HTTPS_SUFFIX" ]
    then
        echo "USE_X_FORWARDED_HOST = True" >> $CCNET_CONFIG_FILE
        echo "SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')" >> $CCNET_CONFIG_FILE
    fi
}

function writeGunicornSettings() {
    sed -ni '/bind/!p' $GUNICORN_CONFIG_FILE
    echo "bind = \"0.0.0.0:${SEAHUB_PORT}\"" >> $GUNICORN_CONFIG_FILE
}

function writeSeahubConfiguration() {
    clearGeneratedContent "${SEAHUB_CONFIG_FILE}"

    echo "${GENERATED_CONTENT_HEADER}

# Memcached
CACHES = {
  'default': {
    'BACKEND': 'django_pylibmc.memcached.PyLibMCCache',
    'LOCATION': 'seafile-memcached:11211',
  },
  'locmem': {
    'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
  },
}
COMPRESS_CACHE_BACKEND = 'locmem'

TIME_ZONE                           = '${TZ}'
SITE_BASE                           = 'http${HTTPS_SUFFIX}://${SERVER_IP}'
SITE_NAME                           = '${SEAFILE_SITE_NAME}'
SITE_TITLE                          = '${SEAFILE_SITE_NAME}'
SITE_ROOT                           = '/'
ENABLE_SIGNUP                       = False
ACTIVATE_AFTER_REGISTRATION         = False
SEND_EMAIL_ON_ADDING_SYSTEM_MEMBER  = True
SEND_EMAIL_ON_RESETTING_USER_PASSWD = True
CLOUD_MODE                          = False
FILE_PREVIEW_MAX_SIZE               = 100 * 1024 * 1024
SESSION_COOKIE_AGE                  = 60 * 60 * 24 * 7 * 2
SESSION_SAVE_EVERY_REQUEST          = False
SESSION_EXPIRE_AT_BROWSER_CLOSE     = False
LOGIN_ATTEMPT_LIMIT                 = 3
UPLOAD_LINK_EXPIRE_DAYS_DEFAULT     = 14
ENABLE_THUMBNAIL                    = True
THUMBNAIL_IMAGE_SIZE_LIMIT          = 60
ENABLE_VIDEO_THUMBNAIL              = True
THUMBNAIL_VIDEO_FRAME_TIME          = 5 
THUMBNAIL_SIZE_FOR_ORIGINAL         = 1024
MAX_NUMBER_OF_FILES_FOR_FILEUPLOAD  = 2500
LANGUAGE_CODE                       = '${LANGUAGE_CODE}'
FILE_SERVER_ROOT                    = 'http${HTTPS_SUFFIX}://${SERVER_IP}/seafhttp'

# Enable LibreOffice Online
OFFICE_SERVER_TYPE = 'CollaboraOffice'
OFFICE_WEB_APP_BASE_URL = 'http${HTTPS_SUFFIX}://${SERVER_IP}/hosting/discovery'
WOPI_ACCESS_TOKEN_EXPIRATION = 30 * 60   # seconds
OFFICE_WEB_APP_FILE_EXTENSION = ('odp', 'ods', 'odt', 'xls', 'xlsb', 'xlsm', 'xlsx','ppsx', 'ppt', 'pptm', 'pptx', 'doc', 'docm', 'docx')
ENABLE_OFFICE_WEB_APP_EDIT = True
OFFICE_WEB_APP_EDIT_FILE_EXTENSION = ('odp', 'ods', 'odt', 'xls', 'xlsb', 'xlsm', 'xlsx','ppsx', 'ppt', 'pptm', 'pptx', 'doc', 'docm', 'docx')

# Only office
VERIFY_ONLYOFFICE_CERTIFICATE = False
ONLYOFFICE_APIJS_URL = 'http${HTTPS_SUFFIX}://${SERVER_IP}/web-apps/apps/api/documents/api.js'
ONLYOFFICE_FILE_EXTENSION = ('doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'odt', 'fodt', 'odp', 'fodp', 'ods', 'fods')
ONLYOFFICE_EDIT_FILE_EXTENSION = ('docx', 'pptx', 'xlsx')
# Enable force save to let user can save file when he/she press the save button on OnlyOffice file edit page.
ONLYOFFICE_FORCE_SAVE = True

" > "${SEAHUB_CONFIG_FILE}"

    # Write generated config
    generateConfig "${SEAHUB_SETTING_ENV_PREFIX}" >> "${SEAHUB_CONFIG_FILE}"
}

cd /opt/seafile

echo "Writing ccnet configuration"
writeCcnetConfig

echo "Writing gunicorn configuration"
writeGunicornSettings

echo "Writing seahub configuration"
writeSeahubConfiguration
