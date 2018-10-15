# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.3.2p1-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.2p1-beta) to [`6.3.3-beta`](https://github.com/vedetta-com/caesonia/tree/v6.3.3-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. -- [OpenBSD Upgrade Guide](https://www.openbsd.org/faq/index.html)

## Upgrade Guide

### Packet filter configuration

Rename "[pf.permanentban](https://github.com/vedetta-com/caesonia/blob/v6.3.2p1-beta/src/etc/pf.permanentban)" to "[pf.conf.table.ban](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/pf.conf.table.ban)"

```console
install -o root -g wheel -m 0600 -b src/etc/pf.conf /etc/
cp -p /etc/permanentban /etc/pf.conf.table.ban
```

Update "[pf.conf.anchor.block](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/pf.conf.anchor.block)"
- new macro "logblock"
- rename table "permanentban" to "ban"

```console
install -o root -g wheel -m 0600 -b src/etc/pf.conf.anchor.block /etc/
```

Update "[pf.conf.anchor.icmp](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/pf.conf.anchor.icmp)"
- new macro "logicmp"
- switched to max-pkt-rate

```console
install -o root -g wheel -m 0600 -b src/etc/pf.conf.anchor.icmp /etc/
```

Restart `pf`

```console
pfctl -nf /etc/pf.conf && pfctl -f /etc/pf.conf
rm /etc/permanentban
```

### OCSP

Patch "[get-ocsp.sh](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/usr/local/bin/get-ocsp.sh)" to run daily
```console
install -o root -g wheel -m 0500 -b src/usr/local/bin/get-ocsp.sh /usr/local/bin/
```

### User crontab

Moved from user [crontab](https://github.com/vedetta-com/caesonia/blob/v6.3.2p1-beta/src/var/cron/tabs/root) to "daily.local":
- Let's Encrypt update
- email service statistics reports

Install the [new crontab](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/var/cron/tabs/root)
```console
crontab -u root src/var/cron/tabs/root
```

Install "[daily.local](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/daily.local)"
```console
install -o root -g wheel -m 0644 -b src/etc/daily.local /etc/
```

### Security complement

"[special.local](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/mtree/special.local)" complements [security(8)](https://man.openbsd.org/security.8) for local special files
```console
install -o root -g wheel -m 0600 -b src/etc/mtree/special.local /etc/mtree/
```

### Backup local files

"[changelist.local](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/src/etc/changelist.local)" extends [changelist(5)](https://man.openbsd.org/changelist.5) to [backup local files](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/INSTALL.md#backup-local-files)
```console
install -o root -g wheel -m 0644 -b src/etc/changelist.local /etc/
```

"rmchangelist.sh" removes local changelist backups
```console
install -o root -g wheel -m 0500 -b src/usr/local/bin/rmchangelist.sh /usr/local/bin/
```

*n.b.*: see [INSTALL.md](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/INSTALL.md#backup-local-files) for usage

### Calendar

Optional "[calendar](https://github.com/vedetta-com/caesonia/tree/v6.3.3-beta/src/home/puffy/.calendar)" reminder service for domain names and hosting anniversaries

```console
install -o puffy -g puffy -m 0755 -d src/home/puffy/.calendar /home/puffy/.calendar
install -o puffy -g puffy -m 0644 -b src/home/puffy/.calendar/* /home/puffy/.calendar/
```

### DNS

New DNS [SRV records](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/README.md#srv-records-for-locating-email-services) to indicate IMAP, POP3, and POP3S are not supported, rfc6186
```console
_imap._tcp.example.com	86400	IN	SRV	0 0 0 .
_pop3._tcp.example.com	86400	IN	SRV	0 0 0 .
_pop3s._tcp.example.com	86400	IN	SRV	0 0 0 .
```

### Installation guide

Renamed "90-replication.conf" to "90-replication.conf.optional", see [INSTALL.md](https://github.com/vedetta-com/caesonia/blob/v6.3.3-beta/INSTALL.md#backup-mx)

