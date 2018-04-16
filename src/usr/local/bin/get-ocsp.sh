#!/bin/sh
# Get OCSP response "example.com.ocsp.resp.der":
# `./get-ocsp.sh example.com`

set -o errexit
set -o nounset

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

SITE="$1"
DIR="/etc/ssl/acme"

# Get root certificate bundle signed by ISRG Root X1 https://letsencrypt.org/certificates/
ftp -o "${DIR}"/letsencryptauthorityx3.pem https://letsencrypt.org/certs/letsencryptauthorityx3.pem.txt

# (!) No nounce (-N) is a security risk
# It should not be used unless the OCSP server does not support the use of OCSP nonces
ocspcheck -N \
          -C "${DIR}"/letsencryptauthorityx3.pem \
          -o "${DIR}"/"${SITE}".ocsp.resp.der \
          "${DIR}"/"${SITE}".fullchain.pem \
&& rcctl restart httpd \
|| logger "ocspcheck fail for ${SITE}.fullchain.pem"
