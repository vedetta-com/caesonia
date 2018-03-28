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
```sh
dhclient vio0
```

Download and edit the response file:
```sh
cd /tmp && ftp https://raw.githubusercontent.com/vedetta-com/caesonia/master/src/var/www/htdocs/mercury.example.com/install.conf
```

Install OpenBSD:
```sh
install -af /tmp/install.conf
```

After `reboot`, `syspatch`, and `mail`, configure [doas.conf](src/etc/doas.conf):
```sh
doas tmux
```

*n.b.*: if `syspatch` installed a kernel patch:
```sh
shutdown -r now
```

Verify if egress IP **matches** DNS record:
```sh
ping -vc1 \
	$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | \
	awk -vhostname="$(hostname)" '{if ($2 == hostname".") print $2;}')

ping6 -vc1 \
	$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | \
	awk -vhostname="$(hostname)" '{if ($2 == hostname".") print $2;}')
```

Update [hostname.if](src/etc/hostname.vio0) and reset:
```sh
sh /etc/netstart $(ifconfig egress | awk 'NR == 1{print $1;}' | sed 's/://')
```

Install packages:
```sh
pkg_add dovecot dovecot-pigeonhole dkimproxy rspamd opensmtpd-extras
```

*n.b.*: dovecot package comes with instructions for self-signed certificates, which are not used in this guide:
```sh
pkg_info -M dovecot
```

*n.b.*: python 2.7 is used by devel/glib2. If desired, the package contains instructions to set as default system python:
```sh
pkg_info -M python
```

Services:
```sh
rcctl enable httpd dkimproxy_out rspamd dovecot
rcctl disable check_quotas sndiod
```

Dovecot [Virtual Users](https://wiki.dovecot.org/VirtualUsers) are mapped to system user "vmail":
```sh
useradd -m -u 2000 -g =uid -c "Virtual Mail" -d /var/vmail -s /sbin/nologin vmail
```

With backup MX, Dovecot [Replication](https://wiki.dovecot.org/Replication) needs a user to `dsync`:
```sh
useradd -m -u 2001 -g =uid -c "Dsync Replication" -d /home/dsync -s /bin/sh dsync
```

dsync [SSH](src/etc/ssh/sshd_config) limited to one "[command](src/home/dsync/.ssh/authorized_keys)" restricted in [`doas.conf`](src/etc/doas.conf) to match "[dsync_remote_cmd](src/etc/dovecot/conf.d/90-replication.conf)":
```sh
su - dsync
ssh-keygen
echo "command=\"doas -u vmail \${SSH_ORIGINAL_COMMAND#*}\" $(cat ~/.ssh/id_rsa.pub)" | \
	ssh puffy@hermes.example.com "cat >> ~/.ssh/authorized_keys"
exit
```

Update [/home/dsync](src/home/dsync), on primary and backup MX:
```sh
chown -R root:dsync /home/dsync
chmod 750 /home/dsync/.ssh
chmod 640 /home/dsync/.ssh/{authorized_keys,id_rsa.pub,config}
chmod 400 /home/dsync/.ssh/id_rsa
chown dsync /home/dsync/.ssh/id_rsa
```

Update [`/root/.ssh/known_hosts`](src/root/.ssh/known_hosts):
```sh
ssh -4 -i/home/dsync/.ssh/id_rsa -ldsync hermes.example.com "exit"
ssh -6 -i/home/dsync/.ssh/id_rsa -ldsync hermes.example.com "exit"
```

## Email Service Configuration

Download a recent [release](https://github.com/vedetta-com/caesonia/releases):
```sh
cd ~ && ftp https://github.com/vedetta-com/caesonia/archive/vX.X.X.tar.gz
tar -C ~ -xzf ~/vX.X.X.tar.gz
```

*n.b.*: to use [Git or SVN](https://help.github.com/articles/which-remote-url-should-i-use/):
```sh
pkg_add git
```

*n.b.*: Backup MX instructions may be skipped, if not necessary, and disable replication:
```sh
mv src/etc/dovecot/conf.d/90-replication.conf src/etc/dovecot/conf.d/90-replication.conf.optional
```

Update [default values](README.md#a-quick-way-around) in the local copy:
```sh
cd src/
```

Backup MX role may be enabled in [`etc/mail/smtpd.conf`](src/etc/mail/smtpd.conf) and depends on DNS record.

Update interface name:
```sh
grep -r vio0 .
find . -type f -exec sed -i "s|vio0|$(ifconfig egress | awk 'NR == 1{print $1;}' | sed 's/://')|g" {} +
```

Primary domain name (from `example.com` to `domainname`):
```sh
grep -r example.com .
find . -type f -exec sed -i "s|example.com|$(hostname | sed "s/$(hostname -s).//")|g" {} +
```

Virtual domain name (from `example.net` to `example.org`):
```sh
grep -r example.net .
find . -type f -exec sed -i 's|example.net|example.org|g' {} +
```

Primary's hostname (from `mercury` to `hostname -s`):
```sh
grep -r mercury .
find . -type f -exec sed -i "s|mercury|$(hostname -s)|g" {} +
```

Backup's hostname (from `hermes` to DNS record):
```sh
grep -r hermes .
find . -type f -exec sed -i "s|hermes|$(dig +short $(hostname | sed "s/$(hostname -s).//") mx | awk -vhostname="$(hostname)" '{if ($2 != hostname".") print $2;}')|g" {} +
```

Update the allowed mail relays [source table](https://man.openbsd.org/table.5#Source_tables) [`etc/mail/relays`](src/etc/mail/relays).

Update wheel user name "puffy":
```sh
cd ../
sed -i "s|puffy|$USER|g" \
	src/etc/pf.conf \
	src/etc/mail/aliases \
	src/etc/ssh/sshd_config
```

Update virtual users [credentials table](https://man.openbsd.org/table.5#Credentials_tables) [`src/etc/mail/passwd`](src/etc/mail/passwd) using [`smtpctl encrypt`](https://man.openbsd.org/smtpctl#encrypt).

*n.b.*: user [quota](src/etc/dovecot/conf.d/90-quota.conf) limit can be [overriden](src/etc/dovecot/conf.d/auth-passwdfile.conf.ext) from [src/etc/mail/passwd](src/etc/mail/passwd):
```console
user@example.com:$2b$...encrypted...passphrase...::::::userdb_quota_rule=*:storage=7G
```

Update [virtual domains](https://man.openbsd.org/makemap#VIRTUAL_DOMAINS) [aliasing table](https://man.openbsd.org/table.5#Aliasing_tables)  [`src/etc/mail/virtual`](src/etc/mail/virtual).

## Email Service Installation

After review:
```sh
install -o root -g wheel -m 0640 -b src/etc/acme-client.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/dhclient.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/dkimproxy_out.conf /etc/
install -o root -g wheel -m 0640 -b src/etc/doas.conf /etc/
install -o root -g wheel -m 0644 -b src/etc/hosts /etc/
install -o root -g wheel -m 0640 -b src/etc/httpd.conf* /etc/
install -o root -g wheel -m 0644 -b src/etc/login.conf /etc/
install -o root -g wheel -m 0644 -b src/etc/newsyslog.conf /etc/
install -o root -g wheel -m 0600 -b src/etc/pf.conf* /etc/
install -o root -g wheel -m 0644 -b src/etc/resolv.conf.tail /etc/
install -o root -g wheel -m 0644 -b src/etc/sysctl.conf /etc/

install -o root -g wheel -m 0755 -d src/etc/dovecot/conf.d /etc/dovecot/conf.d
install -o root -g wheel -m 0644 -b src/etc/dovecot/local.conf /etc/local.conf
install -o root -g wheel -m 0644 -b src/etc/dovecot/dovecot-trash.conf.ext /etc/dovecot/
install -o root -g wheel -m 0644 -b src/etc/dovecot/conf.d/* /etc/dovecot/conf.d/

install -o root -g wheel -m 0644 -b src/etc/mail/aliases /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/blacklist /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/mailname /etc/mail/
install -o _dovecot -g _smtpd -m 0640 -b src/etc/mail/passwd /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/relays /etc/mail/
install -o root -g wheel -m 0644 -b src/etc/mail/smtpd.conf /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/vdomains /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/virtual /etc/mail/
install -o root -g _smtpd -m 0640 -b src/etc/mail/whitelist /etc/mail/

install -o root -g wheel -m 0755 -d src/etc/rspamd/local.d /etc/mail/rspamd/local.d
install -o root -g wheel -m 0755 -d src/etc/rspamd/override.d /etc/mail/rspamd/override.d
install -o root -g wheel -m 0644 -b src/etc/rspamd/local.d/* /etc/mail/rspamd/local.d/
install -o root -g wheel -m 0644 -b src/etc/rspamd/override.d/* /etc/mail/rspamd/override.d/

install -o root -g wheel -m 0644 -b src/etc/ssh/sshd_config /etc/ssh/
install -o root -g wheel -m 0644 -b src/etc/ssh/sshd_banner /etc/ssh/

install -o root -g wheel -m 0500 -b src/usr/local/bin/get-ocsp.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/dovecot-lda.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/learn_ham.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/learn_spam.sh /usr/local/bin/
install -o root -g vmail -m 0550 -b src/usr/local/bin/quota-warning.sh /usr/local/bin/

install -o root -g crontab -m 0640 -b src/var/cron/cron.allow /var/cron/

install -o root -g wheel -m 0755 -d src/var/dovecot/sieve-pipe /var/dovecot/sieve-pipe

install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/after /var/dovecot/imapsieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/before /var/dovecot/imapsieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-ham.sieve /var/dovecot/imapsieve/before/
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-spam.sieve /var/dovecot/imapsieve/before/

install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/after /var/dovecot/sieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/before /var/dovecot/sieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/sieve/before/spamtest.sieve /var/dovecot/sieve/before/

install -o root -g wheel -m 0644 -b src/var/unbound/etc/unbound.conf /var/unbound/etc/

install -o root -g daemon -m 0755 -d src/var/www/htdocs/mercury.example.com /var/www/htdocs/$(hostname)
install -o root -g daemon -m 0644 -b src/var/www/htdocs/mercury.example.com/index.html /var/www/htdocs/$(hostname)/

install -o root -g wheel -m 0644 -b src/root/.ssh/config /root/.ssh/

mkdir -m 700 /var/crash/rspamd
```

### DNS resolver

Unbound DNS validating resolver from root nameservers, with fallback:
```sh
unbound-anchor -a "/var/unbound/db/root.key"
ftp -o /var/unbound/etc/root.hints https://FTP.INTERNIC.NET/domain/named.cache
rcctl restart unbound
cp src/etc/resolv.conf /etc/
```

### Sieve

Compile sieve scripts:
```sh
sievec /var/dovecot/imapsieve/before/report-ham.sieve
sievec /var/dovecot/imapsieve/before/report-spam.sieve
sievec /var/dovecot/sieve/before/spamtest.sieve
```

### LetsEncrypt

Turn off `httpd` tls:
```sh
sed -i "s|^$(echo -e "\t")tls|$(echo -e "\t")#tls|" /etc/httpd.conf
```

Start `httpd`:
```sh
rcctl start httpd
```

Initialize a new account and domain key:
```sh
acme-client -vAD $(hostname)
```

OCSP response:
```sh
/usr/local/bin/get-ocsp.sh $(hostname)
```

Turn on `httpd` tls:
```sh
sed -i "s|^$(echo -e "\t")#tls|$(echo -e "\t")tls|" /etc/httpd.conf
```

Restart `httpd`:
```sh
rcctl restart httpd
```

Edit [`crontab`](src/var/cron/tabs/root):
```sh
crontab -e
```

### Restart

Restart the email service:
```sh
pfctl -f /etc/pf.conf
rcctl restart sshd dkimproxy_out rspamd dovecot smtpd
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
```sh
echo "example.ca" >> /etc/mail/vdomains
```

Add DKIM signature:
```sh
sed -i '/^domain/s/$/,example.ca/' /etc/dkimproxy_out.conf
```

Whitelist local sender:
```sh
echo "@example.ca" >> /etc/mail/whitelist
```

Add virtual alias:
```sh
echo "johndoe@example.ca \t\tjohn@example.ca" >> /etc/mail/virtual
```

Add virtual user:
```sh
echo "john@example.ca \t\tvmail" >> /etc/mail/virtual
```

Add virtual password:
```sh
smtpctl encrypt
> secret
> $2b$...encrypted...passphrase...
vi /etc/mail/passwd
> john@example.ca:$2b$...encrypted...passphrase...::::::
```

Reload:
```sh
rcctl restart dkimproxy_out
rcctl reload dovecot
smtpctl update table virtuals
smtpctl update table vdomains                                   
smtpctl update table passwd   
smtpctl update table whitelist-senders
```

Suppose the foreign address "jane@example.meh" behaves badly.

Blacklist external sender:
```sh
echo "jane@example.meh" >> /etc/mail/blacklist
smtpctl update table blacklist-senders
```

or blacklist everybody "@example.meh" for bad behavior:
```sh
echo "@example.meh" >> /etc/mail/blacklist
smtpctl update table blacklist-senders
```

Suppose "example.meh" is a lost cause:

Gather relevant bad subdomains:
```sh
dig +short example.meh mx
```

for each bad subdomain, add its IP (A and AAAA record) to `pf`:
```sh
echo IP >> /etc/pf.permanentban
```

and reload the `pf` table:
```sh
pfctl -t permanentban -T replace -f /etc/pf.permanentban
```

### Microsoft Network

When sending emails to the Microsoft network from a new IP, the following error may occur:
```console
Mar 22 17:56:37 mercury smtpd[45037]: 8f4864084ecc48f4 mta event=delivery evpid=7077717e797a776e from=<puffy@example.com> to=<bill@hotmail.com> rcpt=<-> source="203.0.113.1" relay="104.47.38.33 (104.47.38.33)" delay=1s result="PermFail" stat="550 5.7.1 Unfortunately, messages from [203.0.113.1] weren't sent. Please contact your Internet service provider since part of their network is on our block list (AS3150). You can also refer your provider to http://mail.live.com/mail/troubleshooting.aspx#errors. [BL2NAM02FT031.eop-nam02.prod.protection.outlook.com]"
```

To add a new IPv4 to Microsoft's reputation based greylist, manual intervention from postmasters is required:
1. Delist IP from other blocking lists http://multirbl.valli.org/

2. Add IP to Microsoft's greylist
  * If sending to hotmail.com live.com msn.com outlook.com or any domain hosted on those services, use the following form: http://go.microsoft.com/fwlink/?LinkID=614866
  * If sending to office.com or any domain hosted on this service, use the following form: https://sender.office.com/

3. Check Inbox/ for an auto-reply email, followed by a response
  * "conditionally mitigated" meaning the IP has been added to the greylist
  * or that the IP is not eligible for delisting
    * Politely reply, asking the reason why the IP is not eligible for delisting
    * A human will delist the IP in a few hours

Microsoft recommends postmasters to join [Smart Network Data Service](https://postmaster.live.com/snds/) to monitor the new IP's reputation score, and the associated Junk Mail Reporting Program (*n.b.* requires Microsoft account)

## What's next

Add your own [Sieve](https://tools.ietf.org/html/rfc6785) scripts in `/var/vmail/example.com/puffy/sieve`, then:
```sh
cd /var/vmail/example.com/puffy/
ln -s sieve/script.sieve .dovecot.sieve
sievec .dovecot.sieve
```

To disable filtering based on 3rd party blocking lists:
```sh
mv /etc/rspamd/local.d/rbl.conf.optional \
   /etc/rspamd/local.d/rbl.conf

sed -i '|enabled|s|^#||' /etc/rspamd/local.d/surbl.conf

mv /etc/rspamd/override.d/emails.conf.optional \
   /etc/rspamd/override.d/emails.conf
vi /etc/rspamd/override.d/bad_emails.list
rcctl reload rspamd
```

