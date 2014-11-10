#!/bin/bash -e

VERSION='9c4096dfa4028caf4de933cbc2edd88d'

echo "[start toxiproxy]"
curl --silent http://shopify-vagrant.s3.amazonaws.com/toxiproxy/toxiproxy-$VERSION -o ./bin/toxiproxy
chmod +x ./bin/toxiproxy
nohup bash -c "./bin/toxiproxy > ${CIRCLE_ARTIFACTS}/toxiproxy.log 2>&1 &"
