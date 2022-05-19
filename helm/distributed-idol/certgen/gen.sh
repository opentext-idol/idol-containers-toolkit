#!/bin/bash

# expects the PURPOSE, SERVICE_NAME and NAMESPACE env variables to be 
# set appropriately.

ALT_NAMES='"${SERVICE_NAME}.${NAMESPACE}","${SERVICE_NAME}.${NAMESPACE}.svc"'

echo '{"CN":"'${SERVICE_NAME}'","hosts":['${ALT_NAMES}'],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=/ca/front-proxy-ca.crt -ca-key=/ca/front-proxy-ca.key -config=/ca/front-proxy-ca-config.json - | cfssljson -bare apiserver

cp apiserver-key.pem /certs/${PURPOSE}.key
cp apiserver.pem /certs/${PURPOSE}.crt
chmod 777 /certs/${PURPOSE}.key
chmod 777 /certs/${PURPOSE}.crt
touch /certs/${PURPOSE}.gen