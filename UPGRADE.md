# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

`[6.2.4-beta](https://github.com/vedetta-com/caesonia/tree/v6.2.4-beta)` to `[6.2.5-beta](https://github.com/vedetta-com/caesonia/tree/v6.2.5-beta)`

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. - [OpenBSD Upgrade Guide](http://www.openbsd.org/faq/index.html)

## Upgrade Guide

Fix rspamd log rotation
```sh
sed '/rspamd.log/s|HUP|USR1|' /etc/newsyslog.conf
```

Disable block log in pf, with small /var/log
```sh
install -o root -g wheel -m 0600 -b src/etc/pf.conf.anchor.block /etc/
```

Include quota usage in daily stats, with formatting for small screens
```sh
crontab -e
> 30 7 * * * smtpctl show stats; printf '\n'; /usr/local/bin/rspamc -h /var/run/rspamd/rspamd.sock stat; /usr/local/bin/doveadm -f pager replicator status '*'; printf '\n'; /usr/local/bin/doveadm -f pager quota get -A
```

Mailbox auto-creation <https://wiki2.dovecot.org/MailLocation>
```sh
sed -i 's|^#mail_location =|mail_location = maildir:/var/vmail/%d/%n/Maildir:LAYOUT=fs|' \
	/etc/dovecot/conf.d/10-mail.conf
```

Optional Listescape plugin <https://wiki2.dovecot.org/Plugins/Listescape>
```sh
sed -i '/^mail_plugins/s|$mail_plugins|& listescape|' \
	/etc/dovecot/conf.d/10-mail.conf
```

crontab whitelist
```sh
echo root > /var/cron/cron.allow
chgrp crontab /var/cron/cron.allow
chmod 640 /var/cron/cron.allow
```

Unbound DNS validating resolver from root nameservers, with fallback:
```sh
rcctl enable unbound
install -o root -g wheel -m 0644 -b src/var/unbound/etc/unbound.conf /var/unbound/etc/
unbound-anchor -a "/var/unbound/db/root.key"
ftp -o /var/unbound/etc/root.hints https://FTP.INTERNIC.NET/domain/named.cache
rcctl restart unbound

install -o root -g wheel -m 0640 -b src/etc/dhclient.conf /etc/
sh /etc/netstart vio0
install -o root -g wheel -m 0644 -b src/etc/resolv.conf /etc/

crontab -e
> 20	2	1,14	*	*	unbound-anchor -a "/var/unbound/db/root.key" && rcctl restart unbound
> 20	4	1	May,Nov	*	ftp -o /var/unbound/etc/root.hints https://FTP.INTERNIC.NET/domain/named.cache && rcctl restart unbound
```

Apply changes
```sh
pfctl -f /etc/pf.conf
rcctl reload dovecot
rcctl stop rspamd && rm /tmp/*.shm && rcctl start rspamd
```

