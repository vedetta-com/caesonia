# caesonia (beta)
*Open*BSD Email Service - Installation Guide

* [OpenBSD Installation](#openbsd-installation)
* [Email Service Configuration](#email-service-configuration)
* [Email Service Installation](#email-service-installation)
* [Client Configuration](#client-configuration)
* [Administration](#administration)

## Preface
While there are many ways to [install](https://www.openbsd.org/faq/faq4.html), on different hosts, this guide will focus on Kernel-based Virtual Machine (KVM), a popular offer for Virtual Private Server (VPS).

## Hosting
When searching for a hosting company, some useful keywords are "KVM" and "VPS", with "unmanaged" or "self-managed" type of service.

Popular forums: 
- https://lowendbox.com/
- https://www.webhostingtalk.com/forumdisplay.php?f=104

Minimum system requirements:
- 512MB RAM
- 20GB SSD/HDD

The host must be able to mount a recent [OpenBSD ISO](https://www.openbsd.org/faq/faq4.html#Download) image. Some hosting companies do not advertise OpenBSD in their offering, but will mount cdXX.iso or installXX.iso when asked. It may be a good idea to open a ticket with them, and verify if mounting a custom ISO is supported.

**n.b.** now is a good time to make sure the [prerequisites](README.md#prerequisites) are met. The substitutions below depend on DNS records, otherwise customize.

## OpenBSD Installation

A response file is used to provide [answers](src/var/www/htdocs/mercury.example.com/install.conf) to the installation questions, as well as an autopartitioning template for [disklabel](src/var/www/htdocs/mercury.example.com/disklabel.min). Edit and upload these files to a web server, or use default as presented.

At the (I)nstall, (U)pgrade, (**S**)hell prompt, pick "shell"

Next, aquire an IP address:
```console
dhclient vio0
```

Download and edit the response file:
```console
cd /tmp && ftp https://raw.githubusercontent.com/vedetta-com/caesonia/master/src/var/www/htdocs/mercury.example.com/install.conf
```

Install OpenBSD:
```console
install -af /tmp/install.conf
```

After `reboot`, `syspatch`, and `mail`, configure [doas.conf](src/etc/doas.conf):
```console
doas tmux
```

*n.b.*: if `syspatch` installed a kernel patch:
```console
shutdown -r now
```

Verify if egress IP **matches** DNS record:
```console
ping -vc1 \
	$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | \
	awk -vhostname="$(hostname)" '{if ($2 == hostname".") print $2;}')

ping6 -vc1 \
	$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | \
	awk -vhostname="$(hostname)" '{if ($2 == hostname".") print $2;}')
```

Update [hostname.if](src/etc/hostname.vio0) and reset:
```console
sh /etc/netstart $(ifconfig egress | awk 'NR == 1{print $1;}' | sed 's/://')
```

Install packages:
```console
pkg_add dovecot dovecot-pigeonhole dkimproxy rspamd opensmtpd-extras gnupg-2.2.10
```

*n.b.*: dovecot package comes with instructions for self-signed certificates, which are not used in this guide:
```console
pkg_info -M dovecot
```

*n.b.*: python 2.7 is used by devel/glib2. If desired, the package contains instructions to set as default system python:
```console
pkg_info -M python
```

Services:
```console
rcctl enable httpd dkimproxy_out rspamd dovecot
rcctl disable check_quotas sndiod
```

Dovecot [Virtual Users](https://wiki.dovecot.org/VirtualUsers) are mapped to system user "vmail":
```console
useradd -m -u 2000 -g =uid -c "Virtual Mail" -d /var/vmail -s /sbin/nologin vmail
```

With backup MX, Dovecot [Replication](https://wiki.dovecot.org/Replication) needs a user to `dsync`:
```console
useradd -m -u 2001 -g =uid -c "Dsync Replication" -d /home/dsync -s /bin/sh dsync
```

dsync [SSH](src/etc/ssh/sshd_config) limited to one "[command](src/home/dsync/.ssh/authorized_keys)" restricted in [`doas.conf`](src/etc/doas.conf) to match "[dsync_remote_cmd](src/etc/dovecot/conf.d/90-replication.conf)":
```console
su - dsync
ssh-keygen
echo "command=\"doas -u vmail \${SSH_ORIGINAL_COMMAND#*}\" $(cat ~/.ssh/id_rsa.pub)" | \
	ssh puffy@hermes.example.com "cat >> /home/dsync/.ssh/authorized_keys"
exit
```

Update [/home/dsync](src/home/dsync), on primary and backup MX:
```console
chown -R root:dsync /home/dsync
chmod 750 /home/dsync/.ssh
chmod 640 /home/dsync/.ssh/{authorized_keys,id_rsa.pub}
chmod 400 /home/dsync/.ssh/id_rsa
chown dsync /home/dsync/.ssh/id_rsa
```

Update [`/root/.ssh/known_hosts`](src/root/.ssh/known_hosts):
```console
ssh -4 -i/home/dsync/.ssh/id_rsa -ldsync hermes.example.com "exit"
ssh -6 -i/home/dsync/.ssh/id_rsa -ldsync hermes.example.com "exit"
```

## Email Service Configuration

Download a recent [release](https://github.com/vedetta-com/caesonia/releases):
```console
cd ~ && ftp https://github.com/vedetta-com/caesonia/archive/v6.4.0-beta.tar.gz
tar -C ~ -xzf ~/v6.4.0-beta.tar.gz
```

*n.b.*: to use [Git or SVN](https://help.github.com/articles/which-remote-url-should-i-use/):
```console
pkg_add git
```

Update [default values](README.md#a-quick-way-around) in the local copy:
```console
cd src/
```

Backup MX role may be enabled in [`etc/mail/smtpd.conf`](src/etc/mail/smtpd.conf) and depends on DNS record.

*n.b.*: Backup MX instructions may be skipped, if not applicable.

Update interface name:
```console
grep -r vio0 .
find . -type f -exec sed -i "s|vio0|$(ifconfig egress | awk 'NR == 1{print $1;}' | sed 's/://')|g" {} +
```

Primary domain name (from `example.com` to `domainname`):
```console
grep -r example.com .
find . -type f -exec sed -i "s|example.com|$(hostname | sed "s/$(hostname -s).//")|g" {} +
```

Virtual domain name (from `example.net` to `example.org`):
```console
grep -r example.net .
find . -type f -exec sed -i 's|example.net|example.org|g' {} +
```

Primary's hostname (from `mercury` to `hostname -s`):
```console
grep -r mercury .
find . -type f -exec sed -i "s|mercury|$(hostname -s)|g" {} +
```

Backup's hostname (from `hermes` to DNS record):
```console
grep -r hermes .
find . -type f -exec sed -i "s|hermes|$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | awk -vhostname="$(hostname)" '{if ($2 != hostname".") print $2;}')|g" {} +
```

Update the allowed mail relays [source table](https://man.openbsd.org/table.5#Source_tables) [`src/etc/mail/relays`](src/etc/mail/relays) to add the primary and backup MX IPs:
```console
cd ../
echo "# primary's IP" > src/etc/mail/relays
dig +short mercury.example.com a >> src/etc/mail/relays
dig +short mercury.example.com aaaa >> src/etc/mail/relays
echo "# backup's IP" >> src/etc/mail/relays
dig +short hermes.example.com a >> src/etc/mail/relays
dig +short hermes.example.com aaaa >> src/etc/mail/relays
```

Update wheel user name "puffy":
```console
sed -i "s|puffy|$USER|g" \
	src/etc/mail/aliases \
	src/etc/mail/passwd \
	src/etc/mail/virtual \
```

*n.b.*: Without backup MX, remove configuration for user "dsync":
```console
sed -i 's/dsync\ //g' src/etc/pf.conf
```

*n.b.*: Select the "backup" dispatcher in [`smtpd.conf`](https://github.com/vedetta-com/caesonia/blob/v6.4.0-beta/src/etc/mail/smtpd.conf) for Backup MX role: `action "mda" # "backup"`

Update virtual users [credentials table](https://man.openbsd.org/table.5#Credentials_tables) [`src/etc/mail/passwd`](src/etc/mail/passwd) using [`smtpctl encrypt`](https://man.openbsd.org/smtpctl#encrypt):
```console
smtpctl encrypt
> secret
> $2b$...encrypted...passphrase...
vi src/etc/mail/passwd
> puffy@example.com:$2b$...encrypted...passphrase...::::::
```

*n.b.*: user [quota](src/etc/dovecot/conf.d/90-quota.conf) limit can be [overriden](src/etc/dovecot/conf.d/auth-passwdfile.conf.ext) from [src/etc/mail/passwd](src/etc/mail/passwd):
```console
puffy@example.com:$2b$...encrypted...passphrase...::::::userdb_quota_rule=*:storage=7G
```

Review [virtual domains](https://man.openbsd.org/makemap#VIRTUAL_DOMAINS) [aliasing table](https://man.openbsd.org/table.5#Aliasing_tables) [`src/etc/mail/virtual`](src/etc/mail/virtual).

## Email Service Installation

After review:
```console
install -o root -g wheel -m 0640 -b src/etc/acme-client.conf /etc/
install -o root -g wheel -m 0644 -b src/etc/daily.local /etc/
install -o root -g wheel -m 0644 -b src/etc/changelist.local /etc/
install -o root -g wheel -m 0640 -b src/etc/dhclient.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/dkimproxy_out.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/doas.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/httpd.conf* /etc/
install -o root -g wheel -m 0644 -b src/etc/login.conf /etc/
install -o root -g wheel -m 0644 -b src/etc/newsyslog.conf /etc/
install -o root -g wheel -m 0600 -b src/etc/pf.conf* /etc/
install -o root -g wheel -m 0644 -b src/etc/resolv.conf.tail /etc/
install -o root -g wheel -m 0644 -b src/etc/sysctl.conf /etc/

install -o root -g wheel -m 0755 -d src/etc/dovecot/conf.d /etc/dovecot/conf.d
install -o root -g wheel -m 0644 -b src/etc/dovecot/local.conf /etc/dovecot/
install -o root -g wheel -m 0644 -b src/etc/dovecot/dovecot-trash.conf.ext /etc/dovecot/
install -o root -g wheel -m 0644 -b src/etc/dovecot/conf.d/* /etc/dovecot/conf.d/

install -o root -g wheel -m 0644 -b src/etc/mail/aliases /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/sender-blacklist /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/mailname /etc/mail/
install -o _dovecot -g _smtpd -m 0640 -b src/etc/mail/passwd /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/relays /etc/mail/
install -o root -g wheel -m 0644 -b src/etc/mail/smtpd.conf /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/vdomains /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/virtual /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/whitelist /etc/mail/

install -o root -g wheel -m 0600 -b src/etc/mtree/special.local /etc/mtree/

install -o root -g wheel -m 0755 -d src/etc/rspamd/local.d /etc/rspamd/local.d
install -o root -g wheel -m 0755 -d src/etc/rspamd/override.d /etc/rspamd/override.d
install -o root -g wheel -m 0644 -b src/etc/rspamd/local.d/* /etc/rspamd/local.d/
install -o root -g wheel -m 0644 -b src/etc/rspamd/override.d/* /etc/rspamd/override.d/

mkdir -m 700 /var/crash/rspamd

install -o root -g wheel -m 0644 -b src/etc/ssh/sshd_banner /etc/ssh/
install -o root -g wheel -m 0644 -b src/etc/ssh/sshd_config /etc/ssh/

install -o root -g wheel -m 0644 -b src/root/.ssh/config /root/.ssh/

install -o root -g wheel -m 0755 -d src/etc/ssl/acme /etc/ssl/acme
install -o root -g wheel -m 0700 -d src/etc/ssl/acme/private /etc/ssl/acme/private

install -o root -g wheel -m 0500 -b src/usr/local/bin/get-ocsp.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/dovecot-lda.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/learn_*.sh /usr/local/bin/
install -o root -g wheel -m 0500 -b src/usr/local/bin/rmchangelist.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/quota-warning.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/wks-server.sh /usr/local/bin/

install -o root -g crontab -m 0640 -b src/var/cron/cron.allow /var/cron/
crontab -u root src/var/cron/tabs/root

mkdir -p -m 750 /var/dovecot/{imapsieve,sieve,sieve-pipe}
chgrp vmail /var/dovecot/{imapsieve,sieve,sieve-pipe}

install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/after /var/dovecot/imapsieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/before /var/dovecot/imapsieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-ham.sieve /var/dovecot/imapsieve/before/
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-spam.sieve /var/dovecot/imapsieve/before/

install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/after /var/dovecot/sieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/before /var/dovecot/sieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/sieve/before/spamtest.sieve /var/dovecot/sieve/before/
install -o root -g vmail -m 0640 -b src/var/dovecot/sieve/before/00-wks.sieve /var/dovecot/sieve/before/

install -o root -g wheel -m 0644 -b src/var/unbound/etc/unbound.conf /var/unbound/etc/

install -o root -g daemon -m 0755 -d src/var/www/htdocs/mercury.example.com /var/www/htdocs/$(hostname)
install -o root -g daemon -m 0644 -b src/var/www/htdocs/mercury.example.com/index.html /var/www/htdocs/$(hostname)/

install -o root -g daemon -m 0755 -d src/var/www/htdocs/mercury.example.com/mail /var/www/htdocs/$(hostname)/mail
install -o root -g daemon -m 0644 -b src/var/www/htdocs/mercury.example.com/mail/config-v1.1.xml /var/www/htdocs/$(hostname)/mail/

install -o root -g daemon -m 0755 -d src/var/www/openpgpkey /var/www/openpgpkey
install -o root -g daemon -m 0644 -b src/var/www/openpgpkey/policy /var/www/openpgpkey/
install -o root -g daemon -m 0644 -b src/var/www/openpgpkey/submission-address /var/www/openpgpkey/

install -o vmail -g daemon -m 0755 -d src/var/www/openpgpkey/hu /var/www/openpgpkey/hu

install -o root -g wheel -m 0755 -d src/var/lib /var/lib
install -o root -g wheel -m 0755 -d src/var/lib/gnupg /var/lib/gnupg
install -o root -g wheel -m 2750 -d src/var/lib/gnupg/wks /var/lib/gnupg/wks
```

### DNS resolver

Unbound DNS validating resolver from root nameservers, with fallback:
```console
unbound-anchor -a "/var/unbound/db/root.key"
ftp -o /var/unbound/etc/root.hints https://FTP.INTERNIC.NET/domain/named.cache
rcctl enable unbound
rcctl restart unbound
cp -p /etc/resolv.conf /etc/resolv.conf.old
cp src/etc/resolv.conf /etc/
```

### Sieve

Compile sieve scripts:
```console
sievec /var/dovecot/imapsieve/before/report-ham.sieve
sievec /var/dovecot/imapsieve/before/report-spam.sieve
sievec /var/dovecot/sieve/before/00-wks.sieve
sievec /var/dovecot/sieve/before/spamtest.sieve
```

### Replication

Master/Master replication, on primary and backup MX:
```console
mv /etc/dovecot/conf.d/90-replication.conf.optional /etc/dovecot/conf.d/90-replication.conf
```

### Backup local files

Install "changelist.local":
```console
cp -p /etc/changelist /etc/changelist-6.4
cat /etc/changelist.local >> /etc/changelist
```

*n.b.*: Uninstall "changelist.local":
```console
sed -i '/changelist.local/,$d' /etc/changelist
```

*n.b.*: Remove from "/var/backups":
```console
/usr/local/bin/rmchangelist.sh
```

### Let's Encrypt

Turn off `httpd` tls:
```console
sed -i -e "s|^$(echo -e "\t")tls|$(echo -e "\t")#tls|" \
	-e "/# (\!) TLS/ s|listen on \$IP tls port https|listen on ::1 port http|" \
	/etc/httpd.conf
```

Start `httpd`:
```console
rcctl start httpd
```

Initialize a new account and domain key:
```console
acme-client -vAD $(hostname)
```

Turn on `httpd` tls:
```console
sed -i -e "s|^$(echo -e "\t")#tls|$(echo -e "\t")tls|" \
	-e "/# (\!) TLS/ s|listen on ::1 port http|listen on \$IP tls port https|" \
	/etc/httpd.conf
```

OCSP response:
```console
rcctl restart httpd && /usr/local/bin/get-ocsp.sh $(hostname)
```

### OpenPGP Web Key Service ([WKS](https://tools.ietf.org/html/draft-koch-openpgp-webkey-service-06))

An important aspect of using OpenPGP is trusting the (public) key. Off-channel key exchange is not always practical, OpenPGP DANE protocol lacks confidentially, and HKPS' a mess. OpenPGP proposed a new protocol to automate and build trust in the process of exchanging public keys.

Web Key Service has two main functions for our Email Service:
1. Allow all users to locate and retreive public keys by email address using HTTPS
2. Allow local user's email client to automatically publish and revoke public keys

Self-hosting has the advantage of full authority on the user mail addresses for their domain name. By design, only one WKS can exist for a domain name. Furthermore, only local users can make requests to WKS Submission Address, and replies to local users only. Moreover, the service automatically verifies the sender is in possesion of the secret key, before publishing their public key. Self-hosting the public key server finally makes OpenPGP oportunistic encryption user friendly.

To get started, a GnuPG 2.1 safe configuration is provided: [`gpg.conf`](src/home/puffy/.gnupg/gpg.conf)

*n.b.*: temp WKS installation patch for doas.conf
```console
echo "permit nopass root as vmail cmd env" >> /etc/doas.conf
```

Web Key Service maintains a Web Key Directory ([WKD](https://wiki.gnupg.org/WKD)) which needs the following configuration for each *virtual* domain:
```console
mkdir -m 755 /var/lib/gnupg/wks/example.com
chown -R vmail:vmail /var/lib/gnupg/wks

cd /var/lib/gnupg/wks/example.com

ln -sf /var/www/openpgpkey/hu .
chown -h vmail:vmail hu

ln -s /var/www/openpgpkey/submission-address .
chown -h vmail:vmail submission-address

doas -u vmail \
	env -i HOME=/var/vmail \
	gpg-wks-server --list-domains
```

Web Key Service uses a Submission Address, which needs the following configuration:

Add *virtual* password for the Submission Address:
```console
smtpctl encrypt
> secret
> $2b$...encrypted...passphrase...
vi /etc/mail/passwd
> key-submission@example.com:$2b$...encrypted...passphrase...::::::
```

Create the submission key:
```console
doas -u vmail \
	env -i HOME=/var/vmail \
	gpg2 --batch --passphrase '' --quick-gen-key key-submission@example.com
```

Verify:
```console
doas -u vmail \
	env -i HOME=/var/vmail \
	gpg2 -K --with-fingerprint
```

List the z-Base-32 encoded SHA-1 hash of the mail address' local-part (i.e. key-submission):
```console
doas -u vmail \
	env -i HOME=/var/vmail \
	gpg2 --with-wkd-hash -K key-submission@example.com
> 54f6ry7x1qqtpor16txw5gdmdbbh6a73@example.com
```

Publish the key, using the hash of the string "key-submission" (i.e. 54f6ry7x1qqtpor16txw5gdmdbbh6a73):
```console
doas -u vmail \
	env -i HOME=/var/vmail \
	gpg2 -o /var/lib/gnupg/wks/example.com/hu/54f6ry7x1qqtpor16txw5gdmdbbh6a73 \
		--export-options export-minimal --export key-submission@example.com
```

*n.b.*: To delete this key:
```console
gpg2 --delete-secret-key "key-submission@example.com"
gpg2 --delete-key "key-submission@example.com"
```

*n.b.*: (!) revert temp WKS installation patch for doas.conf
```console
sed -i '/permit nopass root as vmail cmd env$/ d' /etc/doas.conf
```

*n.b.*: [Enigmail](https://www.enigmail.net)/Thunderbird, [Kmail](https://userbase.kde.org/KMail) and [Mutt](http://www.mutt.org/) (perhaps other MUA) support the Web Key Service. Once published, a communication partner's MUA automatically downloads the public key with the following `gpg.conf` directive:
```console
#expert
#no-emit-version
#interactive
auto-key-retrieve
auto-key-locate		local,wkd
```

The key can be manually retreived too:
```console
gpg2 --auto-key-locate clear,wkd --locate-keys puffy@example.com
```

To simply check a key:
```console
$(gpgconf --list-dirs libexecdir)/gpg-wks-client -v --check puffy@example.com
```

Or a hex listing:
```console
gpg-connect-agent --dirmngr --hex 'wkd_get puffy@example.com' /bye
```

*n.b*: If the local-part of an email address exists alike for multiple domains (e.g. **puffy**@example.com and **puffy**@example.net), the hash of the (local-part) string is identical and each key publication overwrites the same web key. This is desired behavior when the same key is used for both uid. To have different keys, the *workaround* is using a subaddress (i.e. +tag) to create the uid (e.g. puffy+enc@example.com) for the key, and go through the process of key submission and confirmation using the MUA interface with the tagged email address (e.g. puffy+enc@example.com).

Following [Bernhard's recommendation](https://wiki.gnupg.org/EasyGpg2016/PubkeyDistributionConcept#Ask_the_mail_service_provider_.28MSP.29) to support WKD implementations without [SRV](README.md#srv-records-for-openpgp-web-key-directory) lookup (e.g. [Mailvelope](https://www.mailvelope.com), [Enigmail](https://www.enigmail.net)), the apex domain (i.e. **example.com**) must have A and AAAA records, and its http server must return codes `301` or `302` to send a `Location:` header for redirection to `https://wkd.example.com`:

```console
server "example.com" {
	listen on "*" tls port https
...
	# OpenPGP Web Key Directory
	location "/.well-known/openpgpkey/*" {
		block return 302 "https://wkd.example.com$REQUEST_URI"
	}
...
}
```

*n.b.*: assuming [DKIM](https://github.com/vedetta-com/caesonia/blob/master/README.md#domain-keys-identified-mail-dkim) keys are set.

### Restart

Restart the email service:
```console
pfctl -f /etc/pf.conf
rcctl restart sshd httpd dkimproxy_out rspamd dovecot smtpd
```

### Logs

```console
/var/log/messages
/var/log/daemon
/var/log/maillog
/var/log/rspamd/rspamd.log
/var/www/logs/access.log
/var/www/logs/error.log
```

## Client Configuration

*n.b.*: MUA auto-configuration via [Autoconfiguration](README.md#mozilla-autoconfiguration) and SRV Records for [Locating Email Services](README.md#srv-records-for-locating-email-services)

- IMAP server: mercury.example.com (or hermes.example.com)
  - Security: TLS
  - Port: 993
  - Username: puffy@example.com
  - Password: ********
  - Autodetect IMAP namespace :ballot_box_with_check:
  - Use compression :ballot_box_with_check:
  - Poll when connecting for push :ballot_box_with_check:

- SMTP server: mercury.example.com (or hermes.example.com)
  - Security: STARTTLS
  - Port: 587
  - Require sign-in :ballot_box_with_check:
  - Username: puffy@example.com
  - Authentication: Normal password
  - Password: ********

## Administration

Suppose the address "john@example.ca" needs to be hosted, with a "johndoe" alias.

*n.b.*: Assuming DNS [Prerequisites](README.md#prerequisites) for Virtual Domains are met

Add virtual domain:
```console
echo "example.ca" >> /etc/mail/vdomains
```

Add DKIM signature:
```console
sed -i '/^domain/s/$/,example.ca/' /etc/dkimproxy_out.conf
```

Whitelist local sender:
```console
echo "@example.ca" >> /etc/mail/whitelist
```

Add virtual alias:
```console
echo "johndoe@example.ca \t\tjohn@example.ca" >> /etc/mail/virtual
```

Add virtual user:
```console
echo "john@example.ca \t\tvmail" >> /etc/mail/virtual
```

Add virtual password:
```console
smtpctl encrypt
> secret
> $2b$...encrypted...passphrase...
vi /etc/mail/passwd
> john@example.ca:$2b$...encrypted...passphrase...::::::
```

Reload:
```console
rcctl restart dkimproxy_out
rcctl reload dovecot
smtpctl update table virtuals
smtpctl update table vdomains
smtpctl update table vpasswd
smtpctl update table whitelist-senders
```

Suppose the foreign address "jane@example.meh" behaves badly.

Blacklist external sender:
```console
echo "jane@example.meh" >> /etc/mail/sender-blacklist
smtpctl update table sender-blacklist
```

or blacklist everybody "@example.meh" for bad behavior:
```console
echo "@example.meh" >> /etc/mail/sender-blacklist
smtpctl update table sender-blacklist
```

Suppose "example.meh" is a lost cause:

Gather relevant bad subdomains:
```console
dig +short example.meh mx
```

for each bad subdomain, add its IP (A and AAAA record) to `pf`:
```console
echo $IP >> /etc/pf.conf.table.ban
```

and reload the `pf` table:
```console
pfctl -t ban -T replace -f /etc/pf.conf.table.ban
```

### Microsoft Network

When sending emails to Microsoft network from a new IP, the following error 550 may occur:
```console
Mar 22 17:56:37 mercury smtpd[45037]: 8f4864084ecc48f4 mta event=delivery evpid=7077717e797a776e from=<puffy@example.com> to=<bill@hotmail.com> rcpt=<-> source="203.0.113.1" relay="104.47.38.33 (104.47.38.33)" delay=1s result="PermFail" stat="550 5.7.1 Unfortunately, messages from [203.0.113.1] weren't sent. Please contact your Internet service provider since part of their network is on our block list (AS3150). You can also refer your provider to http://mail.live.com/mail/troubleshooting.aspx#errors. [BL2NAM02FT031.eop-nam02.prod.protection.outlook.com]"
```

To add a new IPv4 to Microsoft's reputation based greylist, manual intervention from postmasters is required:
1. Delist IP from other blocking lists: http://multirbl.valli.org/

2. Add IP to Microsoft's greylist:
   * If sending to *hotmail.com*, *live.com*, *msn.com*, *outlook.com*, or any domain hosted on these services, use the following form: http://go.microsoft.com/fwlink/?LinkID=614866
   * If sending to *office.com*, or any domain hosted on this service, use the following form: https://sender.office.com/

3. Check Inbox/ for an auto-reply email, followed by a response:
   * *conditionally mitigated*, meaning the IP has been added to the greylist
   * or the IP is not eligible for delisting, meaning
     1. Politely reply, asking the reason why the IP is not eligible for delisting
     1. A human will delist the IP in a few hours

Microsoft recommends postmasters to join [Smart Network Data Service](https://postmaster.live.com/snds/) for monitoring the new IP's reputation score, and the associated Junk Mail Reporting Program (*n.b.* requires Microsoft account)

## What's next

Add your own [Sieve](https://tools.ietf.org/html/rfc6785) scripts in `/var/vmail/example.com/puffy/sieve`, then:
```console
cd /var/vmail/example.com/puffy/
ln -s sieve/script.sieve .dovecot.sieve
sievec .dovecot.sieve
```

To disable filtering based on 3rd party blocking lists:
```console
mv /etc/rspamd/local.d/rbl.conf.optional \
   /etc/rspamd/local.d/rbl.conf

sed -i '|enabled|s|^#||' /etc/rspamd/local.d/surbl.conf

mv /etc/rspamd/override.d/emails.conf.optional \
   /etc/rspamd/override.d/emails.conf
vi /etc/rspamd/override.d/bad_emails.list
rcctl reload rspamd
```

