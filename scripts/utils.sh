#!/bin/bash

FSCK_LOG_FILE='/shared/logs/fsck.log'
SEAFILE_DIR='/opt/seafile/seafile-server-latest'
OPTIONS="$1"

LOCK='/tmp/utils.lock'

function delete_lock() {
  rm -rf "${LOCK}"
  echo 'Script unlocked.'
}

function stop_seafile() {
  ${SEAFILE_DIR}/seafile.sh stop
  sleep 5
}

function start_seafile() {
  ${SEAFILE_DIR}/seafile.sh start
}

if [ -f "${LOCK}" ]; then
    echo "This script is already running."
    exit 0
fi
echo "$$" > "${LOCK}"
echo 'Script locked.'

echo "$(date) starting.."
exit_code=0

# When options contains "c", do fsck check.
if [[ "$OPTIONS" == *c* ]]; then
  ${SEAFILE_DIR}/seaf-fsck.sh &> "${FSCK_LOG_FILE}"
  exit_code=$?

  cat "${FSCK_LOG_FILE}"
  echo "fsck finished with exit code $exit_code."

  # There was a typo in fsck message "curropted".
  if grep -iq "curropted\|corrupted\|missing" "${FSCK_LOG_FILE}" ; then
    exit_code=2
  fi

  if [[ "$exit_code" != "0" ]]; then
    delete_lock
    exit $exit_code
  fi
fi

# When options contains "g", do garbage collection.
if [[ "$OPTIONS" == *g* ]]; then
  stop_seafile
  (
    set +e
    $SEAFILE_DIR/seaf-gc.sh "$@"
    # We want to presevent the exit code of seaf-gc.sh
    exit "${PIPESTATUS[0]}"
  )

  exit_code=$?
  start_seafile

  if [[ "$exit_code" != "0" ]]; then
    delete_lock
    exit $exit_code
  fi
fi

# When options contains "r", do rsync backup.
if [[ "$OPTIONS" == *r* ]]; then
  RSYNC_OPTS=''
  # When options contains "d", do rsync with --delete
  if [[ "$OPTIONS" == *d* ]]; then
    RSYNC_OPTS="${RSYNC_OPTS} --delete"
  fi
  rsync -avhpxSH --numeric-ids --force ${RSYNC_OPTS} /shared/seafile-data/ /shared/seafile-data-backup/
  exit_code=$?
fi

delete_lock
exit $exit_code;
