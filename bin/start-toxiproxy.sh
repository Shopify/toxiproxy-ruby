#!/bin/bash -e

VERSION='0eef7f44653b07ee0e0f8de1cc64b09a'

echo "[start toxiproxy]"
curl --silent http://shopify-vagrant.s3.amazonaws.com/toxiproxy/toxiproxy-$VERSION -o ./bin/toxiproxy
chmod +x ./bin/toxiproxy
nohup bash -c "./bin/toxiproxy > ${CIRCLE_ARTIFACTS}/toxiproxy.log 2>&1 &"
