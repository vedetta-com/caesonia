#!/bin/sh
# Get OCSP response "example.com.ocsp.resp.der":
# `./get-ocsp.sh example.com`

set -o errexit
set -o nounset

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

SITE="$1"
DIR="/etc/ssl/acme"
CA="letsencryptauthorityx3.pem"

# Get root certificate bundle signed by ISRG Root X1
# https://letsencrypt.org/certificates/
if [ "$(stat -f "%Sm" -t "%a %b %e %Y" "${DIR}"/"${CA}")" !=\
     "$(date -j '+%a %b %e %Y')" ]
  then
    ftp -Mo "${DIR}"/"${CA}" https://letsencrypt.org/certs/"${CA}".txt
fi

# (!) No nounce (-N) is a security risk
# It should not be used unless the OCSP server does not support the use of OCSP nonces
ocspcheck -Nv \
          -C "${DIR}"/"${CA}" \
          -o "${DIR}"/"${SITE}".ocsp.resp.der \
             "${DIR}"/"${SITE}".fullchain.pem \
2>&1 | grep -A 1 -B 2 "$(date -j '+%a %b %e')"
