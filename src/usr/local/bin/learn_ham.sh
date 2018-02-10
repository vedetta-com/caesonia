#!/bin/sh
exec /usr/local/bin/rspamc -h /var/run/rspamd/rspamd.sock learn_ham
# we don't care about the exit status in this case
exit 0
