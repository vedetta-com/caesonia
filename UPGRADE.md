# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.3.1-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.1-beta) to [`6.3.2p1-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.2p1-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. -- [OpenBSD Upgrade Guide](https://www.openbsd.org/faq/index.html)

## Upgrade Guide

### Introducing OpenPGP Web Key Service (WKS) to OpenBSD

To start implementing Web Key Service, please make sure the new DNS [prerequisites](README.md#openpgp-web-key-directory-wkd) are met.

```sh
pkg_add gnupg-2.2.4
```

Edit [`/etc/httpd.conf`](src/etc/httpd.conf) to add WKD alias and location:
```console
# Host:443
server "mercury.example.com" {
	alias "autoconfig.*"
	alias "wkd.*"

	listen on $IPv4 tls port https
	listen on $IPv6 tls port https

	hsts subdomains

	tls certificate "/etc/ssl/acme/mercury.example.com.fullchain.pem"
	tls key "/etc/ssl/acme/private/mercury.example.com.key"
	# (!) see usr/local/bin/get-ocsp.sh
	tls ocsp "/etc/ssl/acme/mercury.example.com.ocsp.resp.der"

	# Cipher Strength <https://man.openbsd.org/SSL_CTX_set_cipher_list>
	tls ciphers "HIGH:!AES128:!kRSA:!aNULL" # default: "HIGH:!aNULL"
	# Key Exchange <https://man.openbsd.org/tls_config_set_ecdhecurves>
	tls ecdhe "P-384,P-256,X25519" # default: "X25519,P-256,P-384"

	tcp nodelay
	connection { max requests 500, timeout 3600 }

	log { access "access.log", error "error.log" }

	block

	# OpenPGP Web Key Directory
	location "/.well-known/openpgpkey/*" {
		root "/openpgpkey"
		root strip 2
		pass
	}

	location "/*" {
		root "/htdocs/mercury.example.com"
		pass
	}
}

# Host:80
server "mercury.example.com" {
	alias "autoconfig.*"
	alias "wkd.*"
...
```

Add WKD LetsEncrypt certificate:
```sh
acme-client -vr mercury.example.com
```

Edit [`/etc/acme-client.conf`](src/etc/acme-client.conf) to add every service (virtual) WKD subdomains as alternative names:
```console
...
	alternative names { \
		autoconfig.example.com \
		autoconfig.example.net \
		wkd.example.com \
		wkd.example.net }
...
```

```sh
acme-client -v mercury.example.com
get-ocsp.sh mercury.example.com
```

Edit [`/etc/doas.conf`](src/etc/doas.conf) to add WKS permissions:
```console
# WKS: expire non confirmed publication requests
permit nopass root as vmail cmd env args \
    -i HOME=/var/vmail /usr/local/bin/gpg-wks-server --cron
```

Edit [`/var/cron/tabs/root`](src/var/cron/tabs/root) to add WKS expiration:
```console
30	11	*	*	*	doas -u vmail env -i HOME=/var/vmail /usr/local/bin/gpg-wks-server --cron
```

Edit [`/etc/mail/smtpd.conf`](src/etc/mail/smtpd.conf) to add WKS table:
```console
table wks-recipients		{ "key-submission@example.com" } # OpenPGP WKS Submission Address
```

OpenPGP Web Key Service (WKS) Trust Management for primary and backup MX:
```sh
sed -i 's/accept tagged MTA from any/& recipient ! <wks-recipients>/g' /etc/mail/smtpd.conf
```

Add OpenPGP Web Key Service (WKS) Submission Address
```sh
echo "key-submission@example.com \tvmail" >> /etc/mail/virtual
```

Install OpenPGP Web Key Service (WKS) Server Tool:
```sh
install -o root -g wheel -m 0644 -b src/etc/dovecot/conf.d/90-sieve-extprograms.conf /etc/dovecot/conf.d/
install -o root -g vmail -m 0550 -b src/usr/local/bin/wks-server.sh /usr/local/bin/
install -o root -g vmail -m 0640 -b src/var/dovecot/sieve/before/00-wks.sieve /var/dovecot/sieve/before/
sievec /var/dovecot/sieve/before/00-wks.sieve
```

Install OpenPGP Web Key Directory:
```sh
install -o root -g daemon -m 0755 -d src/var/www/openpgpkey /var/www/openpgpkey
install -o root -g daemon -m 0644 -b src/var/www/openpgpkey/policy /var/www/openpgpkey/
install -o root -g daemon -m 0644 -b src/var/www/openpgpkey/submission-address /var/www/openpgpkey/

install -o vmail -g daemon -m 0755 -d src/var/www/openpgpkey/hu /var/www/openpgpkey/hu

install -o root -g wheel -m 0755 -d src/var/lib /var/lib   
install -o root -g wheel -m 0755 -d src/var/lib/gnupg /var/lib/gnupg
install -o root -g wheel -m 2750 -d src/var/lib/gnupg/wks /var/lib/gnupg/wks
```

Follow the [Web Key Service Configuration Guide](INSTALL.md#openpgp-web-key-service-wks) to finish the upgrade.

Restart:
```sh
rcctl restart smtpd dovecot httpd
```

