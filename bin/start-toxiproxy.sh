#!/bin/bash -e

VERSION='21a264cc75549c3ae837b606eb6e17ea'
TOXIPROXY_LOG_DIR=${CIRCLE_ARTIFACTS:-'/tmp'}

echo "[start toxiproxy]"
curl --silent http://shopify-vagrant.s3.amazonaws.com/toxiproxy/toxiproxy-$VERSION -o ./bin/toxiproxy
chmod +x ./bin/toxiproxy
nohup bash -c "./bin/toxiproxy > ${TOXIPROXY_LOG_DIR}/toxiproxy.log 2>&1 &"
