# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.3.0-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.0-beta) to [`6.3.1-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.1-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. -- [OpenBSD Upgrade Guide](https://www.openbsd.org/faq/index.html)

## Upgrade Guide

Split TLS and non-TLS configuration, update TLS cipher strength and key exchange (score A+ with 100% on every [ssllabs.com](https://www.ssllabs.com/ssltest/) test while supporting all devices), and improve Mozilla [Autoconfiguration](https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration) with the following `httpd.conf` changes:
```console
# Host:443
server "mercury.example.com" {
	alias "autoconfig.*"

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

	location "/*" {
		root "/htdocs/mercury.example.com"
		pass
	}
}

# Host:80
server "mercury.example.com" {
	alias "autoconfig.*"

	listen on $IPv4 port http
	listen on $IPv6 port http

	tcp nodelay
	connection { max requests 500, timeout 3600 }

	log { access "access.log", error "error.log" }

	block

	location "/.well-known/acme-challenge/*" {
		root "/acme"
		root strip 2
		pass
	}

	# Mozilla Autoconfiguration
	location "/mail/*" {
		block return 302 "https://autoconfig.example.com$REQUEST_URI"
	}

	location "/*" {
		root "/htdocs/mercury.example.com"
		pass
	}
}
```

Update TLS (cipher strength) for dovecot:
```sh
sed -i 's/HIGH:!aNULL/HIGH:!AES128:!kRSA:!aNULL/' /etc/dovecot/conf.d/10-ssl.conf
```

LetsEncrypt certificate updates, now with service *virtual* subdomains:
```sh
acme-client -vr mercury.example.com 
sed -i 's/autoconfig.example.com/& autoconfig.example.net/' /etc/acme-client.conf
acme-client -v mercury.example.com
get-ocsp.sh mercury.example.com
rcctl restart smtpd dovecot
```

Update crontab to restart smtpd and dovecot on certificate update:
```sh
crontab -e
```
```console
20	6	*	*	*	acme-client mercury.example.com && /usr/local/bin/get-ocsp.sh mercury.example.com && rcctl restart smtpd dovecot
```

Increase waiting for reply timeout to 120s, giving rspamd ample time to tell the truth:
```sh
sed -i 's|/bin/rspamc|& -t 120|' /etc/mail/smtpd.conf
rcctl restart smtpd
```

New rspamd statistics update script, to relearn Spam/ from all users:
```sh
install -o root -g wheel -m 0550 -b src/usr/local/bin/learn_all_spam.sh /usr/local/bin/
learn_all_spam.sh
```

