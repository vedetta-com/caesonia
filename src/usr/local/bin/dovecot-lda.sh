#!/bin/sh
exec /usr/local/libexec/dovecot/dovecot-lda "${1}" "${2}" "${3}" "${4}" -e
# we don't care about the exit status in this case
exit 0
