# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.2.5-beta`](https://github.com/vedetta-com/caesonia/tree/v6.2.5-beta) to [`6.2.6-beta`](https://github.com/vedetta-com/caesonia/tree/v6.2.6-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. - [OpenBSD Upgrade Guide](http://www.openbsd.org/faq/index.html)

## Upgrade Guide

Mozilla [Autoconfiguration](https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration)
```sh 
vi src/var/www/htdocs/autoconfig.example.com/index.html
install -o root -g daemon -m 0755 -d src/var/www/htdocs/autoconfig.example.com /var/www/htdocs/autoconfig.$(hostname | sed "s/$(hostname -s).//")
install -o root -g daemon -m 0644 -b src/var/www/htdocs/autoconfig.example.com/index.html /var/www/htdocs/autoconfig.$(hostname | sed "s/$(hostname -s).//")/

vi src/var/www/htdocs/autoconfig.example.com/mail/config-v1.1.xml
install -o root -g daemon -m 0755 -d src/var/www/htdocs/autoconfig.example.com/mail /var/www/htdocs/autoconfig.$(hostname | sed "s/$(hostname -s).//")/mail
install -o root -g daemon -m 0644 -b src/var/www/htdocs/autoconfig.example.com/mail/config-v1.1.xml /var/www/htdocs/autoconfig.$(hostname | sed "s/$(hostname -s).//")/mail/
```

Each autoconfig subdomain has record types A, and AAAA with the VPS IPv4, and IPv6:
```console   
autoconfig.example.com.	86400	IN	A	203.0.113.1
autoconfig.example.com.	86400	IN	AAAA	2001:0db8::1
```  

Each *virtual* autoconfig subdomain has record type CNAME pointing to *autoconfig.example.com*:
```console
autoconfig.example.net.	86400	IN	CNAME	autoconfig.example.com.
```

Each domain and *virtual* domain has record types SRV for simple MUA [auto-configuration]((https://tools.ietf.org/html/rfc6186)):
```console
_submission._tcp.example.com.	86400	IN	SRV	0 1 587 mercury.example.com.
_imaps._tcp.example.com.	86400	IN	SRV	0 1 993 mercury.example.com.
```

Each domain and subdomain needs a TXT record with SPF data:
```console
autoconfig.example.com.	86400	IN	TXT	"v=spf1 -all"
```

Edit and add the following configuration directive to [`/etc/httpd.conf`](src/etc/httpd.conf):
```console
# Mozilla Autoconfiguration
server "autoconfig.*" {
	listen on $IPv4 port http
	listen on $IPv6 port http

	tcp nodelay
	connection { max requests 500, timeout 3600 }

	log syslog

	block

	location "/*" {
		root "/htdocs/autoconfig.example.com"
		pass
	}
}
```

Reload:
```sh
rcctl reload httpd
```

