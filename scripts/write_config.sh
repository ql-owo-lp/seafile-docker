#!/bin/bash

CONFIG_DIR="./conf"
CCNET_CONFIG_FILE="$CONFIG_DIR/ccnet.conf"
GUNICORN_CONFIG_FILE="$CONFIG_DIR/gunicorn.conf.py"
SEAHUB_CONFIG_FILE="$CONFIG_DIR/seahub_settings.py"

if [[ -z "${COLLABORA_OFFICE_SERVER}" ]]; then
  COLLABORA_OFFICE_ENABLE="False"
fi

if [[ -z "${ONLYOFFICE_SERVER}" ]]; then
  ONLYOFFICE_ENABLE="False"
fi

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
    sed -ni '/8000/!p' $GUNICORN_CONFIG_FILE
    echo "bind = \"0.0.0.0:${SEAHUB_PORT}\"" >> $GUNICORN_CONFIG_FILE
}

function writeSeahubConfiguration() {
    echo "# Memcached
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

# Email Setup
EMAIL_USE_TLS                       = ${EMAIL_SMTP_TLS}
EMAIL_HOST                          = '${EMAIL_SMTP_SERVER}'
EMAIL_HOST_USER                     = '${EMAIL_SMTP_USER}'
EMAIL_HOST_PASSWORD                 = '${EMAIL_SMTP_PASSWORD}'
EMAIL_PORT                          = '${EMAIL_SMTP_PORT}'
DEFAULT_FROM_EMAIL                  = EMAIL_HOST_USER
SERVER_EMAIL                        = EMAIL_HOST_USER

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
ENABLE_OFFICE_WEB_APP = ${COLLABORA_OFFICE_ENABLE}
OFFICE_WEB_APP_BASE_URL = 'https://${COLLABORA_OFFICE_SERVER}/hosting/discovery'
WOPI_ACCESS_TOKEN_EXPIRATION = 30 * 60   # seconds
OFFICE_WEB_APP_FILE_EXTENSION = ('odp', 'ods', 'odt', 'xls', 'xlsb', 'xlsm', 'xlsx','ppsx', 'ppt', 'pptm', 'pptx', 'doc', 'docm', 'docx')
ENABLE_OFFICE_WEB_APP_EDIT = True
OFFICE_WEB_APP_EDIT_FILE_EXTENSION = ('odp', 'ods', 'odt', 'xls', 'xlsb', 'xlsm', 'xlsx','ppsx', 'ppt', 'pptm', 'pptx', 'doc', 'docm', 'docx')

# Only office
ENABLE_ONLYOFFICE = ${ONLYOFFICE_ENABLE}
VERIFY_ONLYOFFICE_CERTIFICATE = False
ONLYOFFICE_APIJS_URL = 'https://${ONLYOFFICE_SERVER}/web-apps/apps/api/documents/api.js'
ONLYOFFICE_FILE_EXTENSION = ('doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'odt', 'fodt', 'odp', 'fodp', 'ods', 'fods')
ONLYOFFICE_EDIT_FILE_EXTENSION = ('docx', 'pptx', 'xlsx')
ONLYOFFICE_JWT_SECRET = '${ONLYOFFICE_JWT_SECRET}'
# Enable force save to let user can save file when he/she press the save button on OnlyOffice file edit page.
ONLYOFFICE_FORCE_SAVE = True

" >> $SEAHUB_CONFIG_FILE
}

cd /opt/seafile

echo "Writing ccnet configuration"
writeCcnetConfig

echo "Writing gunicorn configuration"
writeGunicornSettings

echo "Writing seahub configuration"
writeSeahubConfiguration
