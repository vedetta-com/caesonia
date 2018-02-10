#!/bin/sh

#set -eu
set -o errexit
set -o nounset

chmod 600 /etc/{dhclient.conf,doas.conf,pf.conf,pf.permanentban}

chmod 640 /etc/mail/{blacklist,mailname,relays,vdomains,virtual,whitelist}
chown root:_smtpd /etc/mail/{blacklist,mailname,relays,vdomains,virtual,whitelist}

chmod 440 /etc/mail/passwd
chown _smtpd:_dovecot /etc/mail/passwd

mkdir -p /etc/ssl/dkim/private
chmod 550 /etc/ssl/dkim/private
chmod 440 /etc/ssl/dkim/private/private.key
chown -R _rspamd:_dkimproxy /etc/ssl/dkim/private

chown -R root:dsync /home/dsync
chmod 750 /home/dsync/.ssh
chmod 640 /home/dsync/.ssh/{authorized_keys,id_rsa.pub,config}
chmod 400 /home/dsync/.ssh/id_rsa
chown dsync /home/dsync/.ssh/id_rsa

mkdir -p /var/dovecot/imapsieve/{after,before}
mkdir -p /var/dovecot/sieve/{after,before}
chown -R root:vmail /var/dovecot/{imapsieve,sieve}
chmod 750 /var/dovecot/{imapsieve,sieve}
chmod 750 /var/dovecot/imapsieve/{after,before}
chmod 750 /var/dovecot/sieve/{after,before}
chmod 640 /var/dovecot/imapsieve/before/*
chmod 640 /var/dovecot/sieve/before/*
mkdir -p /var/dovecot/sieve-pipe

mkdir -p /etc/rspamd/local.d

chmod 750 /var/vmail
mkdir -p /var/vmail/sieve
chown -R vmail:vmail /var/vmail

chmod 500 /usr/local/bin/{backup.sh,get-ocsp.sh,hier.sh}

chmod 550 /usr/local/bin/{dovecot-lda.sh,learn_ham.sh,learn_spam.sh,quota-warning.sh}
chgrp vmail /usr/local/bin/{dovecot-lda.sh,learn_ham.sh,learn_spam.sh,quota-warning.sh}

mkdir -m 700 /var/crash/rspamd
