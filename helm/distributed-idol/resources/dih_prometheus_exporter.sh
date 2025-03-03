#! /bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

echo "Copying files"
mkdir -p /usr/src/app
cp /mnt/python/* /usr/src/app
cd /usr/src/app || exit 1

echo "Installing"
pip install --no-cache-dir -r requirements.txt

echo "Running"
python dih_prometheus_exporter.py &
RUN_PID=$!
trap 'kill "${RUN_PID}"; wait "${RUN_PID}"' SIGINT SIGTERM
wait "${RUN_PID}"
echo "python exited"