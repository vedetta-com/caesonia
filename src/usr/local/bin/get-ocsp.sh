#!/bin/sh
# Get OCSP response "example.com.ocsp.resp.der":
# `./get-ocsp.sh example.com`

set -o errexit
set -o nounset

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

SITE="$1"
DIR="/etc/ssl/acme"

# (!) No nonce [-N] is a security risk
# It should not be used unless the OCSP server does not support the use of OCSP nonces
ocspcheck -Nv \
          -o "${DIR}"/"${SITE}".ocsp.resp.der \
             "${DIR}"/"${SITE}".fullchain.pem \
2>&1 | grep -A 1 -B 2 "$(date -j '+%a %b %e')"
