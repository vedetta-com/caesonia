# caesonia (beta)
*Open*BSD Email Service - Upgrade an existing installation

[`6.4.0-beta`](https://github.com/vedetta-com/caesonia/tree/v6.4.0-beta) to [`6.5.0-beta`](https://github.com/vedetta-com/caesonia/tree/v6.5.0-beta)

> Upgrades are only supported from one release to the release immediately following it. Read through and understand this process before attempting it. For critical or physically remote machines, test it on an identical, local system first. -- [OpenBSD Upgrade Guide](https://www.openbsd.org/faq/index.html)

## Upgrade Guide

Upgrade
```console
cd /tmp
ftp https://cdn.openbsd.org/pub/OpenBSD/6.5/amd64/bsd.rd
ftp https://cdn.openbsd.org/pub/OpenBSD/6.5/amd64/SHA256.sig
signify -C -p /etc/signify/openbsd-65-base.pub -x SHA256.sig bsd.rd && \
	cp -p /bsd.rd /bsd.rd-6.4 && cp /tmp/bsd.rd /

rm /usr/include/openssl/asn1_mac.h

rm /usr/bin/c2ph \
 /usr/bin/pstruct \
 /usr/libdata/perl5/Locale/Codes/API.pod \
 /usr/libdata/perl5/Module/CoreList/TieHashDelta.pm \
 /usr/libdata/perl5/Unicode/Collate/Locale/bg.pl \
 /usr/libdata/perl5/Unicode/Collate/Locale/fr.pl \
 /usr/libdata/perl5/Unicode/Collate/Locale/ru.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Cham.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Ethi.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Hebr.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Hmng.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Khar.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Khmr.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Lana.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Lao.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Talu.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Tibt.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Xsux.pl \
 /usr/libdata/perl5/unicore/lib/Sc/Zzzz.pl \
 /usr/share/man/man1/c2ph.1 \
 /usr/share/man/man1/pstruct.1 \
 /usr/share/man/man3p/Locale::Codes::API.3p

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
syspatch
reboot
```

Upgrade caesonia (see [Makefile](https://github.com/vedetta-com/caesonia/blob/master/Makefile).local):
```console
rm /usr/local/bin/get-ocsp.sh
cd caesonia
env UPGRADE=yes make install
```

OpenSSH 8.0 [new features](https://www.openbsd.org/65.html):
> ssh(1), ssh-agent(1), ssh-add(1): Add support for ECDSA keys in PKCS#11 tokens.

> ssh-keygen(1): Increase the default RSA key size to 3072 bits, following NIST Special Publication 800-57's guidance for a 128-bit equivalent symmetric security level.

*n.b.*: Train rspamd with messages from all users' Spam folder (if installing new database)
```console
/usr/local/bin/learn_all_spam.sh
```

Consider using [SSH certificates](https://github.com/vedetta-com/vedetta/blob/master/src/usr/local/share/doc/vedetta/OpenSSH_Principals.md) and manage access to local users with principals.

