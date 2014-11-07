#!/bin/bash -e

VERSION='fad1365c087d6ad53944c8201a6131cb'

echo "[start toxiproxy]"
curl --silent http://shopify-vagrant.s3.amazonaws.com/toxiproxy/toxiproxy-$VERSION -o ./bin/toxiproxy
chmod +x ./bin/toxiproxy
nohup bash -c "./bin/toxiproxy > ${CIRCLE_ARTIFACTS}/toxiproxy.log 2>&1 &"
