# caesonia (beta) *draft* **please report errors**
*Open*BSD Email Service

## Preface
While there are many ways to install, on different hosts, this guide will focus on Kernel-based Virtual Machine (KVM), a popular offer for Virtual Private Server (VPS).

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

At the (I)nstall, (U)pgrade, (S)hell prompt, pick "shell"

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

After `reboot`, configure [doas.conf](src/etc/doas.conf):
```sh
doas tmux
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

Update OpenBSD:
```sh
syspatch
```

Install packages:
```sh
pkg_add dovecot dovecot-pigeonhole dkimproxy rspamd opensmtpd-extras
```

Services:
```sh
rcctl enable httpd dkimproxy_out rspamd dovecot
rcctl disable check_quotas sndiod
```

Add users:
```sh
useradd -m -u 2000 -g =uid -c "Virtual Mail" -d /var/vmail -s /sbin/nologin vmail
useradd -m -u 2001 -g =uid -c "Dsync Replication" -d /home/dsync -s /bin/sh dsync
```

dsync SSH:
```sh
su - dsync
ssh-keygen
echo "command=\"doas -u vmail \${SSH_ORIGINAL_COMMAND#*}\" $(cat ~/.ssh/id_rsa.pub)" | \
	ssh puffy@hermes.example.com "cat >> ~/.ssh/authorized_keys"
exit
```

Update `/root/.ssh/known_hosts`:
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

Update [default values](README.md#a-quick-way-around) in the local copy:
```sh
cd src/
```

*n.b.*: Backup MX instructions may be skipped, if not necessary, and disable replication:
```sh
mv src/etc/dovecot/conf.d/90-replication.conf src/etc/dovecot/conf.d/90-replication.conf.optional
```

Backup MX role may be enabled in [`src/etc/mail/smtpd.conf`](src/etc/mail/smtpd.conf) and depends on DNS record.

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

Virtua domain name (from `example.net` to `example.org`):
```sh
grep -r example.net .
find . -t`ype f -exec sed -i 's|example.net|example.org|g' {} +
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

Update primary and backup MX IP in [`src/etc/mail/relays`](src/etc/mail/relays)

Update wheel user name "puffy":
```sh
cd ../
sed -e -i "s|puffy|$USER|g" \
	src/etc/pf.conf \
	src/etc/mail/aliases \
	src/etc/ssh/sshd_config
```

Update virtual users and domains:
```console
src/etc/mail/passwd
src/etc/mail/virtual
```

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

install -o root -g wheel -m 0755 -d src/var/dovecot/sieve-pipe /var/dovecot/sieve-pipe

install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/after /var/dovecot/imapsieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/imapsieve/before /var/dovecot/imapsieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-ham.sieve /var/dovecot/imapsieve/before/
install -o root -g vmail -m 0640 -b src/var/dovecot/imapsieve/before/report-spam.sieve /var/dovecot/imapsieve/before/

install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/after /var/dovecot/sieve/after
install -o root -g vmail -m 0750 -d src/var/dovecot/sieve/before /var/dovecot/sieve/before
install -o root -g vmail -m 0640 -b src/var/dovecot/sieve/before/spamtest.sieve /var/dovecot/sieve/before/

install -o root -g daemon -m 0755 -d src/var/www/htdocs/mercury.example.com /var/www/htdocs/$(hostname)
install -o root -g daemon -m 0644 -b src/var/www/htdocs/mercury.example.com/index.html /var/www/htdocs/$(hostname)/

install -o root -g wheel -m 0644 -b src/root/.ssh/config /root/.ssh/

mkdir -m 700 /var/crash/rspamd
```

## Sieve

Compile sieve scripts:
```sh
sievec /var/dovecot/imapsieve/before/report-ham.sieve
sievec /var/dovecot/imapsieve/before/report-spam.sieve
sievec /var/dovecot/sieve/before/spamtest.sieve
```

## LetsEncrypt

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
acme-client -vAD mercury.example.com
```

OCSP response:
```sh
/usr/local/bin/get-ocsp.sh mercury.example.com
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

## Restart

Restart:
```sh
pfctl -f /etc/pf.conf
rcctl restart sshd dkimproxy_out rspamd dovecot smtpd
```

If `syspatch` installed a kernel patch:
```sh
shutdown -r now
```

## Logs

```console
/var/log/messages
/var/log/daemon
/var/log/maillog
/var/log/rspamd/rspamd.log
/var/www/logs/access.log
/var/www/logs/error.log
```

## What's next

Add your own sieve scripts in `/var/vmail/example.com/puffy/sieve`, then:
```sh
cd /var/vmail/example.com/puffy/
ln -s sieve/script.sieve .dovecot.sieve
sievec .dovecot.sieve
```

