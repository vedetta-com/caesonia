# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.3.3-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.3-beta) to [`6.4.0-beta`](https://github.com/vedetta-com/caesonia/tree/v6.4.0-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. -- [OpenBSD Upgrade Guide](https://www.openbsd.org/faq/index.html)

## Upgrade Guide

Before upgrading to OpenBSD 6.4

[OpenSMTPD queue is not backward compatible](https://poolp.org/posts/2018-05-21/switching-to-opensmtpd-new-config/)
```console
smtpctl pause smtp
smtpctl schedule all
smtpctl show queue
```

When the mail queue is empty
```console
rcctl stop httpd rspamd dkimproxy_out dovecot smtpd
rcctl disable httpd rspamd dkimproxy_out dovecot smtpd
```

Update
```console
cd src/

grep -r example.com .
find . -type f -exec sed -i "s|example.com|$(hostname | sed "s/$(hostname -s).//")|g" {} +

grep -r mercury .
find . -type f -exec sed -i "s|mercury|$(hostname -s)|g" {} +

cd ../

install -o root -g wheel -m 0644 -b src/etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/
install -o root -g wheel -m 0640 -b src/etc/httpd.conf /etc/
cp -p /etc/resolv.conf /etc/resolv.conf.old
cp src/etc/resolv.conf /etc/
install -o root -g wheel -m 0644 -b src/etc/rspamd/local.d/rbl.conf.optional /etc/rspamd/local.d/
install -o root -g wheel -m 0644 -b src/etc/ssh/sshd_config /etc/ssh/
install -o root -g wheel -m 0500 -b src/usr/local/bin/get-ocsp.sh /usr/local/bin/
install -o root -g wheel -m 0644 -b src/etc/daily.local /etc/
install -o root -g wheel -m 0600 -b src/etc/mtree/special.local /etc/mtree/
install -o root -g wheel -m 0644 -b src/var/unbound/etc/unbound.conf /var/unbound/etc/
crontab -u root src/var/cron/tabs/root
```

*n.b.*: Without backup MX, remove configuration for user "dsync"
```console
sed -i 's/dsync\ //g' src/etc/pf.conf
```

*n.b.*: Select the "backup" dispatcher in [`smtpd.conf`](https://github.com/vedetta-com/caesonia/blob/v6.4.0-beta/src/etc/mail/smtpd.conf) for Backup MX role: `action "mda" # "backup"`

```console
install -o root -g wheel -m 0644 -b src/etc/mail/smtpd.conf /etc/mail/

install -o root -g wheel -m 0600 -b src/etc/pf.conf /etc/
install -o root -g wheel -m 0600 -b src/etc/pf.conf.table.martians /etc/
```

Upgrade
```console
cd /tmp
ftp https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/bsd.rd
ftp https://cdn.openbsd.org/pub/OpenBSD/6.4/amd64/SHA256.sig
signify -C -p /etc/signify/openbsd-64-base.pub -x SHA256.sig bsd.rd && \
	cp -p /bsd.rd /bsd.rd-6.3 && cp /tmp/bsd.rd /
echo "https://cdn.openbsd.org/pub/OpenBSD" > /etc/installurl

rm /dev/audio /dev/audioctl
rm /etc/rc.d/rtadvd /usr/sbin/rtadvd /usr/share/man/man5/rtadvd.conf.5 /usr/share/man/man8/rtadvd.8
userdel _rtadvd
groupdel _rtadvd

reboot
boot: bsd.rd
...
(I)nstall, (U)pgrade, (A)utoinstall or (S)hell? U
...
Set name(s) = -comp* -game* -x*

reboot

sysmerge
===> Displaying differences between ./etc/changelist and installed version:
  Use 'i' to install the temporary ./etc/changelist
How should I deal with this? [Leave it for later] i

pkg_add -u

sievec /var/dovecot/imapsieve/before/report-ham.sieve
sievec /var/dovecot/imapsieve/before/report-spam.sieve
sievec /var/dovecot/sieve/before/00-wks.sieve
sievec /var/dovecot/sieve/before/spamtest.sieve

rcctl enable httpd rspamd dkimproxy_out dovecot smtpd
rcctl start httpd rspamd dkimproxy_out dovecot smtpd
cp -p /etc/changelist /etc/changelist-6.4
cat /etc/changelist.local >> /etc/changelist
rm /etc/changelist-6.3
rm /bsd.rd-6.2
```

*n.b.*: Train rspamd with messages from all users' Spam folder (if installing new database)
```console
/usr/local/bin/learn_all_spam.sh
```

Consider using [SSH certificates](https://github.com/vedetta-com/caesonia/blob/v6.4.0-beta/usr/local/share/doc/caesonia/OpenSSH_Principals.md) and manage access to local users with principals.
```console
install -o root -g wheel -m 0755 -d src/usr/local/share/doc/caesonia /usr/local/share/doc/caesonia
install -o root -g wheel -m 0644 -b src/usr/local/share/doc/caesonia/OpenSSH_Principals.md /usr/local/share/doc/caesonia/
```

