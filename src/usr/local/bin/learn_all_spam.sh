#!/bin/sh
# Train rspamd with messages from all users' Spam folder
# https://community.nethserver.org/t/email-2-with-rspamd-1-7-x/9439

set -o errexit
set -o nounset

for USER in $(doveadm user '*'); do
  echo "Loading $USER"

  doveadm search -u "$USER" mailbox Spam ALL |

  while read guid uid; do
    doveadm -f pager fetch -u "$USER" text mailbox-guid "$guid" uid "$uid" \
    | sed '1d;$d' \
    | rspamc -h /var/run/rspamd/rspamd.sock -d "$USER" learn_spam
  done

done

