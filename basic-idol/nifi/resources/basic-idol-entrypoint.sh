#!/bin/bash

START_SH="/opt/nifi/nifi-current/start-idol-nifi.sh"
NIFI_API_URL="http://idol-nifi:8081/nifi-api"

function check_nifi_ready() {
    local retries=120
    local wait=5
    local url="${NIFI_API_URL}/system-diagnostics"

    echo "Waiting for NiFi to be ready..."

    for i in $(seq 1 $retries); do
        if curl --fail --silent "$url" >/dev/null; then
            return 0
        else
            sleep $wait
        fi
    done

    return 1
}

# Run start.sh in the background
echo "Starting NiFi using start-idol-nifi.sh"
$START_SH &
start_pid=$!

if check_nifi_ready; then
    echo "Running import-flow.sh..."
    /opt/nifi/scripts/import-flow.sh
else
    echo "NiFi did not become ready in time. Exiting."
    kill $start_pid
    exit 1
fi

# Keep running until start.sh exits
wait
