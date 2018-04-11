# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.2.5-beta`](https://github.com/vedetta-com/caesonia/tree/v6.2.5-beta) to [`6.3.0-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.0-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. - [OpenBSD Upgrade Guide](http://www.openbsd.org/faq/index.html)

## Upgrade Guide

Before upgrading to OpenBSD 6.3, backup `/var/rspamd` and:
```sh
cd /tmp
ftp https://fastly.cdn.openbsd.org/pub/OpenBSD/6.3/amd64/bsd.rd
ftp https://fastly.cdn.openbsd.org/pub/OpenBSD/6.3/amd64/SHA256.sig
signify -C -p /etc/signify/openbsd-63-base.pub -x SHA256.sig bsd.rd && \
	cp -p /bsd.rd /bsd.rd-6.2 && cp /tmp/bsd.rd /
rm -r /usr/share/man
rm -r /usr/share/compile
cd /usr/X11R6/lib
rm libpthread-stubs.a \
	libpthread-stubs.so.2.0 \
	pkgconfig/pthread-stubs.pc
reboot
boot: bsd.rd
> (I)nstall, (U)pgrade, (A)utoinstall or (S)hell? U
...
Set name(s) = -comp* -game* -x*
...
reboot
sysmerge
pkg_add -u
sievec /var/dovecot/imapsieve/before/report-ham.sieve
sievec /var/dovecot/imapsieve/before/report-spam.sieve
sievec /var/dovecot/sieve/before/spamtest.sieve
rcctl restart smtpd dovecot rspamd dkimproxy_out
rm /bsd.rd-6.2
```

[RFC 7217](https://tools.ietf.org/html/rfc7217) style IPv6 addresses enabled by default. If you need the old style:
```sh
echo "inet6 -soii" >> /etc/hostname.vio0
```

Enable syncookie adaptive mode:
```sh
sed -i '/block-policy/a\
	set syncookies adaptive (start 25%, end 12%)
	' /etc/pf.conf
pfctl -f /etc/pf.conf
```

Mozilla [Autoconfiguration](https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration)
```sh 
vi src/var/www/htdocs/mercury.example.com/mail/config-v1.1.xml
install -o root -g daemon -m 0755 -d src/var/www/htdocs/mercury.example.com/mail /var/www/htdocs/$(hostname)/mail
install -o root -g daemon -m 0644 -b src/var/www/htdocs/mercury.example.com/mail/config-v1.1.xml /var/www/htdocs/$(hostname)/mail/
```

Each autoconfig subdomain has record type CNAME pointing to Autoconfiguration server:
```console
autoconfig.example.com.	86400	IN	CNAME	mercury.example.com
```  

Each *virtual* autoconfig subdomain has record type CNAME pointing to Autoconfiguration server:
```console
autoconfig.example.net.	86400	IN	CNAME	autoconfig.example.com.
```

Each domain and *virtual* domain has record types SRV for simple MUA [auto-configuration]((https://tools.ietf.org/html/rfc6186)):
```console
_submission._tcp.example.com.	86400	IN	SRV	0 1 587 mercury.example.com.
_imaps._tcp.example.com.	86400	IN	SRV	0 1 993 mercury.example.com.
```

Each autoconfig subdomain needs a TXT record with SPF data:
```console
autoconfig.example.com.	86400	IN	TXT	"v=spf1 -all"
```

Edit *autoconfig.example.com*, and add the following configuration directive to [`/etc/httpd.conf`](src/etc/httpd.conf):
```console
...
# Host
server "mercury.example.com" {
	alias "autoconfig.example.com"

	listen on $IPv4 port http
...
}

# Mozilla Autoconfiguration
server "autoconfig.*" {
	listen on $IPv4 port http
	listen on $IPv6 port http

	tcp nodelay
	connection { max requests 500, timeout 3600 }

	log syslog

	block

	location "/*" {
		block return 302 "https://autoconfig.example.com$REQUEST_URI"
	}
}
...
```

Revoke `mercury.example.com` certificate:
```sh
acme-client -vr mercury.example.com
```

Update [`/etc/acme-client.conf`](src/etc/acme-client.conf):
```sh
sed -i -e '/alternative names/s|secure.example.com|autoconfig.example.com|' \
	-e '/alternative names/s/^#//' /etc/acme-client.conf
```

Get a new certificate for *mercury.example.com*:
```sh
acme-client -v mercury.example.com
get-ocsp.sh mercury.example.com
```

Restart:
```sh
rcctl restart smtpd dovecot
```

When relaying as backup MX, enforce STARTTLS and certificate verification:
```sh
sed -i 's|relay backup|& tls verify|g' /etc/mail/smtpd.conf
```

Restart backup MX:
```sh
rcctl restart smtpd
```

Add `per_user` and `per_language` bayes classification of messages:
```sh
rcctl stop rspamd
rm /tmp/*.shm
cp src/etc/rspamd/local.d/classifier-bayes.conf /etc/rspamd/local.d/
cp src/usr/local/bin/learn_*.sh /usr/local/bin/
```

Start with a fresh database:
```
rm /var/rspamd/*
rcctl start rspamd
```

