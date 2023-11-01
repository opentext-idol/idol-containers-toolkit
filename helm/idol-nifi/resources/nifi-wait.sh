#!/bin/bash
set -ex -o allexport
timeout 10m bash -c "until ${NIFI_TOOLKIT_HOME}/bin/cli.sh nifi current-user >/dev/null; do echo [\$(date)] Waiting for NiFi CLI...; sleep 5; done"