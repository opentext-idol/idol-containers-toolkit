#!/bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2023 Open Text.
#
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

set -ex -o allexport

ORGANISATION_UNIT=${ORGANISATION_UNIT:-'Cloud Services Application'}
ORGANISATION=${ORGANISATION:-'Cloud Services'}
#PUBLIC_DNS=${POD_NAME:-'nifi.tld'}
CITY=${CITY:-'London'}
STATE=${STATE:-'London'}
COUNTRY_CODE=${COUNTRY_CODE:-'GB'}
KEY_PASS=${KEY_PASS:-$KEYSTORE_PASS}
KEYSTORE_PASS=${KEYSTORE_PASS:-$NIFI_SENSITIVE_PROPS_KEY}
KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-$NIFI_SENSITIVE_PROPS_KEY}
#KEYSTORE_PATH=${NIFI_HOME}/keytool/keystore.p12
#KEYSTORE_TYPE=jks
TRUSTSTORE_PASS=${TRUSTSTORE_PASS:-$NIFI_SENSITIVE_PROPS_KEY}
TRUSTSTORE_PASSWORD=${TRUSTSTORE_PASSWORD:-$NIFI_SENSITIVE_PROPS_KEY}
#TRUSTSTORE_PATH=${NIFI_HOME}/keytool/truststore.jks
#TRUSTSTORE_TYPE=jks

if [[ ! -f "${NIFI_HOME}/keytool/keystore.p12" ]]
then
    echo "[$(date)] Creating keystore"
    keytool -genkey -noprompt -alias nifi-keystore \
    -dname "CN=${POD_NAME},OU=${ORGANISATION_UNIT},O=${ORGANISATION},L=${CITY},S=${STATE},C=${COUNTRY_CODE}" \
    -keystore "${NIFI_HOME}/keytool/keystore.p12" \
    -storepass "${KEYSTORE_PASS:-$NIFI_SENSITIVE_PROPS_KEY}" \
    -KeySize 2048 \
    -keypass "${KEY_PASS:-$NIFI_SENSITIVE_PROPS_KEY}" \
    -keyalg RSA \
    -storetype pkcs12
fi

if [[ ! -f "${NIFI_HOME}/keytool/truststore.jks" ]]
then
    echo "[$(date)] Creating truststore"
    keytool -genkey -noprompt -alias nifi-truststore \
    -dname "CN=${POD_NAME},OU=${ORGANISATION_UNIT},O=${ORGANISATION},L=${CITY},S=${STATE},C=${COUNTRY_CODE}" \
    -keystore "${NIFI_HOME}/keytool/truststore.jks" \
    -storetype jks \
    -keypass "${KEYSTORE_PASS:-$NIFI_SENSITIVE_PROPS_KEY}" \
    -keyalg RSA \
    -storepass "${KEY_PASS:-$NIFI_SENSITIVE_PROPS_KEY}" \
    -KeySize 2048
fi

#/usr/bin/bash ${NIFI_HOME}/../scripts/secure.sh
#eval ${NIFI_HOME}/../scripts/secure.sh