#!/bin/sh
exec /usr/local/bin/gpg-wks-server -v --receive \
        --header X-WKS-Loop=wks.example.com \
        --from "${1}" \
        --send
# we don't care about the exit status in this case
exit 0
