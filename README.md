# caesonia (beta)
*Open*BSD Email Service

![Public Domain](src/var/www/htdocs/mercury.example.com/Milonia_Caesonia-250x259.jpg)

## About
> a free-email alternative

Root your Inbox :mailbox_with_mail:

## Features
- Efficient: configured to run on min. 512MB RAM and 20GB SSD, a KVM (cloud) VPS for around $2.50/mo
- 15GB+ uncompressed Maildir, rivals top free-email providers (grow by upgrading SSD)
- Email messages are gzip compressed, at least 1/3 more space with level 6 default
- Server side full text search (headers and body) can be enabled (to use the extra space)
- Mobile data friendly: IMAPS connections are compressed
- Subaddress (+tag) support, to filter and monitor email addresses
- Virtual domains, aliases, and credentials in files, Berkeley DB, or [SQLite3](https://github.com/OpenSMTPD/OpenSMTPD-extras/tree/master/extras/tables/table-sqlite)
- Naive Bayes rspamd filtering with supervised learning: the lowest false positive spam detection rates
- Carefree automated Spam/ and Trash/ cleaning service (default: older than 30 days)
- Automated quota management, gently assists when over quota
- Easy backup MX setup: using the same configuration, install in minutes on a different host
- Worry-free automated master/master replication with backup MX, prevents accidental loss of email messages
- Resilient: the backup MX can be used as primary, even when the primary is not down, both perfect replicas
- Flexible: switching roles is easy, making the process of changing VPS hosts a breeze (no downtime)
- DMARC (with DKIM and SPF) email-validation system, to detect and prevent email spoofing
- Uncensored DNS validating resolver from root nameservers
- OpenPGP Web Key Service with Web Key Directory, automatic key exchange protocol
- MUA Autoconfiguration, for modern clients
- Daily (spartan) stats, to keep track of things
- Your sieve scripts and managesieve configuration, let's get started

## Considerations
By design, email message headers need to be public, for exchanges to happen. The body of the message can be [encrypted](INSTALL.md#openpgp-web-key-service-wks) by the user, if desired. Moreover, there is no way to prevent the host from having access to the virtual machine. Therefore, [full disk encryption](https://www.openbsd.org/faq/faq14.html#softraidFDE) (at rest) may not be necessary.

Given our low memory requirements, and the single-purpose concept of email service, Roundcube or other web-based IMAP email clients should be on a different VPS.

Antivirus software users (usually) have the service running on their devices. ClamAV can easily be incorporated into this configuration, if affected by the [types of malware](https://www.shadowserver.org/wiki/pmwiki.php/AV/Virus180-DayStats) it protects against, but will require around 1GB additional RAM (or another VPS).

Every email message is important, if properly delivered, for Bayes classification. At least 200 ham and 200 spam messages are required to learn what one considers junk. By default (change to use case), a rspamd score above 50% will send the message to Spam/. Moving messages in and out of Spam/ changes this score. After 95%, the message is flagged as "seen" and can be safely ignored.

[spamd](https://man.openbsd.org/spamd) is effective at greylisting and stopping high volume spam, if it becomes a problem. It will be an option when IPv6 is supported, along with [bgp-spamd](https://bgp-spamd.net/). To build IP lists for greylisting, please use [spfwalk](https://github.com/akpoff/spfwalk) with [spf_fetch](https://github.com/akpoff/spf_fetch).

System mail is delivered to an alias mapped to a virtual user served by the service. This way, messages are guaranteed to be delivered via encrypted connection. It is not possible for real users to alias, nor `mail` an external mail address with the default configuration.
e.g. puffy@mercury.example.com is wheel, with an alias mapped to (virtual) puffy@example.com, and user (puffy) can be different for each.

## Getting started

See the [**Installation Guide**](INSTALL.md) for details.

Install packages:
```sh
pkg_add dovecot dovecot-pigeonhole dkimproxy rspamd opensmtpd-extras gnupg-2.2.10
```
Add users:
```sh
useradd -m -u 2000 -g =uid -c "Virtual Mail" -d /var/vmail -s /sbin/nologin vmail
useradd -m -u 2001 -g =uid -c "Dsync Replication" -d /home/dsync -s /bin/sh dsync
```
## Cheatsheet
#### A quick way around
Let's assume we want to change the (default) *virtual* domain name from `example.net` to `example.org`
```sh
cd src/
grep -r example.net .
```
After close inspection, apply the substitution:
```sh
find . -type f -exec sed -i 's|example.net|example.org|g' {} +
```

#### Defaults to customize
```console
primary domain name: example.com
virtual domain name: example.com
                     example.net

primary MX host: mercury.example.com
primary MX IPv4: 203.0.113.1
primary MX IPv6: 2001:0db8::1

backup MX host: hermes.example.com
backup MX IPv4: 203.0.113.2
backup MX IPv6: 2001:0db8::2

DKIM selector: obsd
external (egress) interface: vio0

wheel user: puffy
replication user: dsync
virtual user: puffy

autoexpunge: autoexpunge\ =\ 30d
quota: storage=15G
max message size: 35M
full text search: fts
full sync: replication_full_sync_interval\ =\ 1h
```
#### Layout

| Filesystem | Mount       | Size    |
|:---------- |:----------- | -------:|
| a          | /           |    256M |
| b          | /swap       |   1024M |
| d          | /var/log    |    128M |
| e          | /tmp        |   1024M |
| f          | /usr        |   1024M |
| g          | /usr/local  |    512M |
| h          | /home       |      8M |
| i          | /var        |   15G-* |
| *Total*    |             |**20G-***|

## Prerequisites
A DNS name server (from a registrar, a free service, VPS host, or self-hosted) is required, which allows editing the following record types: [A](#forward-confirmed-reverse-dns-fcrdns), [AAAA](#forward-confirmed-reverse-dns-fcrdns), [CNAME](#mozilla-autoconfiguration), [SRV](#srv-records-for-locating-email-services), [MX](#mail-exchanger-mx), [CAA](#certification-authority-authorization-caa), [SSHFP](#secure-shell-fingerprint-sshfp), [TXT](#sender-policy-framework-spf)

#### Forward-confirmed reverse DNS ([FCrDNS](https://tools.ietf.org/html/draft-ietf-dnsop-reverse-mapping-considerations-06))
Each MX subdomain has record types A, and AAAA with the VPS' IPv4, and IPv6:
```console
mercury.example.com	86400	IN	A	203.0.113.1
mercury.example.com	86400	IN	AAAA	2001:0db8::1
```
Each IPv4 and IPv6 has record type PTR with the MX subdomain (reverse DNS configured on VPS host):
```console
...6				IN	PTR 	mercury.example.com
```
Verify:
```sh
dig +short mercury.example.com a
> 203.0.113.1
dig +short -x 203.0.113.1
> mercury.example.com.

dig +short mercury.example.com aaaa
> 2001:0db8::1
dig +short -x 2001:0db8::1
> mercury.example.com.
```

#### Mozilla [Autoconfiguration](https://developer.mozilla.org/en-US/docs/Mozilla/Thunderbird/Autoconfiguration)
Each autoconfig subdomain has record type CNAME pointing to Autoconfiguration server:
```console
autoconfig.example.com	86400	IN	CNAME	mercury.example.com
```

Each *virtual* autoconfig subdomain has record type CNAME pointing to Autoconfiguration server:
```console
autoconfig.example.net	86400	IN	CNAME	mercury.example.com
```

#### OpenPGP Web Key Directory ([WKD](https://tools.ietf.org/html/draft-koch-openpgp-webkey-service-07))
Each WKD subdomain has record type CNAME pointing to Web Key Server:
```console
wkd.example.com		86400	IN	CNAME	mercury.example.com
```

Each *virtual* WKD subdomain has record type CNAME pointing to Web Key Server:
```console
wkd.example.net		86400	IN	CNAME	mercury.example.com
```

#### SRV Records for OpenPGP [Web Key Directory](https://wiki.gnupg.org/WKD)
Each domain has record type SRV for WKD subdomain
```console
_openpgpkey._tcp.example.com	86400	IN	SRV	0 0 443	wkd.example.com
```

Each *virtual* domain has record type SRV for *virtual* WKD subdomain
```console
_openpgpkey._tcp.example.net	86400	IN	SRV	0 0 443	wkd.example.net
```

#### SRV Records for [Locating Email Services](https://tools.ietf.org/html/rfc6186)
Each domain and *virtual* domain has record types SRV for simple MUA auto-configuration:
```console
_submission._tcp.example.com	86400	IN	SRV	0 1 587	mercury.example.com
_imap._tcp.example.com		86400	IN	SRV	0 0 0	.
_imaps._tcp.example.com		86400	IN	SRV	0 1 993	mercury.example.com
_pop3._tcp.example.com		86400	IN	SRV	0 0 0	.
_pop3s._tcp.example.com		86400	IN	SRV	0 0 0	.
```

#### Mail eXchanger ([MX](https://tools.ietf.org/html/rfc5321))
Each domain has first priority MX record *mercury.example.com*

Each domain has second priority MX record *hermes.example.com*
```console
example.com	86400	IN	MX	10 mercury.example.com
example.com	86400	IN	MX	20 hermes.example.com
```

Each *virtual* domain has first priority MX record *mercury.example.com*

Each *virtual* domain has second priority MX record *hermes.example.com*
```console
example.net	86400	IN	MX	10 mercury.example.com
example.net	86400	IN	MX	20 hermes.example.com
```

#### Certification Authority Authorization ([CAA](https://tools.ietf.org/html/rfc6844))
Primary domain name's CAA record sets *[letsencrypt.org](https://letsencrypt.org/)* as the only CA allowed to issue certificates:
```console
example.com	86400	IN	CAA	128 issue "letsencrypt.org"
example.com	86400	IN	CAA	128 issuewild ";"
```

#### Secure Shell Fingerprint ([SSHFP](https://man.openbsd.org/ssh#VERIFYING_HOST_KEYS))
Each MX subdomain needs their hosts's SSHFP records:
```sh
ssh-keygen -r mercury.example.com
```
```console
mercury.example.com	86400	IN	SSHFP	1 1 2...
mercury.example.com	86400	IN	SSHFP	1 2 5...
mercury.example.com	86400	IN	SSHFP	2 1 a...
mercury.example.com	86400	IN	SSHFP	2 2 c...
mercury.example.com	86400	IN	SSHFP	3 1 6...
mercury.example.com	86400	IN	SSHFP	3 2 8...
mercury.example.com	86400	IN	SSHFP	4 1 7...
mercury.example.com	86400	IN	SSHFP	4 2 a...
```

#### Sender Policy Framework ([SPF](http://www.openspf.org/))
Each domain and subdomain needs a TXT record with SPF data:
```console
example.com		86400	IN	TXT	"v=spf1 mx mx:example.com -all"
mercury.example.com	86400	IN	TXT	"v=spf1 a mx ip4:203.0.113.1 ip6:2001:0db8::1 -all"
hermes.example.com	86400	IN	TXT	"v=spf1 a mx ip4:203.0.113.2 ip6:2001:0db8::2 -all"
autoconfig.example.com	86400	IN	TXT	"v=spf1 -all"
```

Each *virtual* domain and *virtual* subdomain needs a TXT record with SPF data:
```console
example.net		86400	IN	TXT	"v=spf1 include:example.com ~all"
```

#### Domain Keys Identified Mail ([DKIM](http://www.dkim.org))
Generate a private and public key:
```sh
mkdir -p /etc/ssl/dkim/private
chmod 750 /etc/ssl/dkim/private
```
Some web-interfaces allow TXT record with max **1024** bits [key](https://tools.ietf.org/html/rfc8301#section-3.2):
```sh
openssl genrsa -out /etc/ssl/dkim/private/private.key 2048
openssl rsa -in /etc/ssl/dkim/private/private.key -pubout -out /etc/ssl/dkim/public.key
chgrp -R _dkimproxy /etc/ssl/dkim/private
chmod 440 /etc/ssl/dkim/private/private.key
```
Add public key in TXT record:
```console
obsd._domainkey.example.com	86400	IN	TXT	"v=DKIM1; k=rsa; p=M..."
```

Each *virtual* domain name needs a TXT record with the (same) public key:
```console
obsd._domainkey.example.net	86400	IN	TXT	"v=DKIM1; k=rsa; p=M..."
```

#### Domain-based Message Authentication, Reporting & Conformance ([DMARC](https://dmarc.org/))
Each domain name needs a TXT record for subdomain *_dmarc* with DMARC data:
```console
_dmarc.example.com	86400	IN	TXT	"v=DMARC1; p=reject; pct=100; rua=mailto:dmarcreports@example.com"
```

Each *virtual* domain name needs a TXT record for subdomain *_dmarc* with DMARC data:
```console
_dmarc.example.net	86400	IN	TXT	"v=DMARC1; p=reject; pct=100; rua=mailto:dmarcreports@example.net"
```

## Support
[Issues](https://github.com/vedetta-com/caesonia/issues)

## Social
[#caesonia:matrix.org](https://riot.im/app/#/room/#caesonia:matrix.org) (deadish)

[#caesonia@bsd.network](https://bsd.network/tags/caesonia)

## Contribute
Contributions welcome, [fork](https://github.com/vedetta-com/caesonia/fork)
Hosted by Open Source Collective 501c6, [contribute](https://opencollective.com/caesonia)

