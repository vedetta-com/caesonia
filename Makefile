#	$OpenBSD$

# Put overrides in "Makefile.local"

PREFIX ?=	/usr/local
GH_PROJECT ?=	caesonia
BINDIR ?=	${PREFIX}/bin
BASESYSCONFDIR ?=	/etc
VARBASE ?=	/var
DOCDIR ?=	${PREFIX}/share/doc/${GH_PROJECT}
EXAMPLESDIR ?=	${PREFIX}/share/examples/${GH_PROJECT}

# Server

DOMAIN_NAME =	example.com
VHOSTS_NAME =	example.net \
		example.org

PRIMARY =	yes

PRIMARY_HOST =	mercury
PRIMARY_IPv4 =	207.148.16.212
PRIMARY_IPv6 =	2001:0db8::1

BACKUP_HOST =	hermes
BACKUP_IPv4 =	203.0.113.2
BACKUP_IPv6 =	2001:0db8::2

DKIM_SELECTOR =	obsd
EGRESS =	vio0

WHEEL_USER =	puffy
REPLICATION_USER =	dsync
VIRTUAL_USER =	${WHEEL_USER}

AUTOEXPUNGE =	30d
MAIL_QUOTA =	15G
MAX_MESSAGE_SIZE =	35M
FULL_SYNC_INTERVAL =	1h

UPGRADE =	yes

CAESONIA =	${SCRIPT} ${SYSCONF} ${PFCONF} ${MAILCONF} ${SSHCONF} \
		${MTREECONF} ${DKIMPROXYCONF} ${DOVECOTCONF} ${SIEVE} \
		${RSPAMDCONF} ${WKD} ${TLSRPT} ${WWW} ${UNBOUNDCONF} \
		${CRONALLOW} ${CRONTAB}

# Caesonia

SCRIPT =	${BINDIR:S|^/||}/dovecot-lda.sh \
		${BINDIR:S|^/||}/learn_all_spam.sh \
		${BINDIR:S|^/||}/learn_ham.sh \
		${BINDIR:S|^/||}/learn_spam.sh \
		${BINDIR:S|^/||}/quota-warning.sh \
		${BINDIR:S|^/||}/rmchangelist.sh \
		${BINDIR:S|^/||}/wks-server.sh

SYSCONF =	${BASESYSCONFDIR:S|^/||}/acme-client.conf \
		${BASESYSCONFDIR:S|^/||}/changelist.local \
		${BASESYSCONFDIR:S|^/||}/daily.local \
		${BASESYSCONFDIR:S|^/||}/dhclient.conf \
		${BASESYSCONFDIR:S|^/||}/doas.conf \
		${BASESYSCONFDIR:S|^/||}/httpd.conf \
		${BASESYSCONFDIR:S|^/||}/login.conf \
		${BASESYSCONFDIR:S|^/||}/newsyslog.conf \
		${BASESYSCONFDIR:S|^/||}/resolv.conf \
		${BASESYSCONFDIR:S|^/||}/sysctl.conf

PFCONF =	${BASESYSCONFDIR:S|^/||}/pf.conf \
		${BASESYSCONFDIR:S|^/||}/pf.conf.anchor.block \
		${BASESYSCONFDIR:S|^/||}/pf.conf.anchor.icmp \
		${BASESYSCONFDIR:S|^/||}/pf.conf.table.ban \
		${BASESYSCONFDIR:S|^/||}/pf.conf.table.martians

MAILCONF =	${BASESYSCONFDIR:S|^/||}/mail/aliases \
		${BASESYSCONFDIR:S|^/||}/mail/blacklist \
		${BASESYSCONFDIR:S|^/||}/mail/mailname \
		${BASESYSCONFDIR:S|^/||}/mail/passwd \
		${BASESYSCONFDIR:S|^/||}/mail/relays \
		${BASESYSCONFDIR:S|^/||}/mail/smtpd.conf \
		${BASESYSCONFDIR:S|^/||}/mail/vdomains \
		${BASESYSCONFDIR:S|^/||}/mail/virtual \
		${BASESYSCONFDIR:S|^/||}/mail/whitelist

SSHCONF =	${BASESYSCONFDIR:S|^/||}/ssh/sshd_banner \
		${BASESYSCONFDIR:S|^/||}/ssh/sshd_config

MTREECONF =	${BASESYSCONFDIR:S|^/||}/mtree/special.local

DKIMPROXYCONF =	${BASESYSCONFDIR:S|^/||}/dkimproxy_out.conf

DOVECOTCONF =	${BASESYSCONFDIR:S|^/||}/dovecot/dovecot-trash.conf.ext \
		${BASESYSCONFDIR:S|^/||}/dovecot/local.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/10-auth.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/10-mail.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/10-master.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/10-ssl.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/15-lda.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/15-mailboxes.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/20-imap.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/20-lmtp.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/20-managesieve.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-plugin.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-quota.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-sieve-extprograms.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-sieve.conf \
		${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/auth-passwdfile.conf.ext

SIEVE =		${VARBASE:S|^/||}/dovecot/imapsieve/before/report-ham.sieve \
		${VARBASE:S|^/||}/dovecot/imapsieve/before/report-spam.sieve \
		${VARBASE:S|^/||}/dovecot/sieve/before/00-wks.sieve \
		${VARBASE:S|^/||}/dovecot/sieve/before/spamtest.sieve

RSPAMDCONF =	${BASESYSCONFDIR:S|^/||}/rspamd/local.d/antivirus.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/classifier-bayes.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/mime_types.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/multimap.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/options.inc \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/phishing.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/rbl.conf.optional \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/replies.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/surbl.conf \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/worker-controller.inc \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/worker-normal.inc \
		${BASESYSCONFDIR:S|^/||}/rspamd/local.d/worker-proxy.inc \
		${BASESYSCONFDIR:S|^/||}/rspamd/override.d/bad_emails.list \
		${BASESYSCONFDIR:S|^/||}/rspamd/override.d/emails.conf.optional

UNBOUNDCONF =	${VARBASE:S|^/||}/unbound/etc/unbound.conf

WKD =		${VARBASE:S|^/||}/www/openpgpkey/policy \
		${VARBASE:S|^/||}/www/openpgpkey/submission-address

TLSRPT =	${VARBASE:S|^/||}/www/mta-sts/mta-sts.txt

WWW =		${VARBASE:S|^/||}/www/htdocs/${HOSTNAME}/index.html \
		${VARBASE:S|^/||}/www/htdocs/${HOSTNAME}/mail/config-v1.1.xml

CRONALLOW =	${VARBASE:S|^/||}/cron/cron.allow
CRONTAB =	${VARBASE:S|^/||}/cron/tabs/root

WRKSRC ?=	${HOSTNAME:S|^|${.CURDIR}/|}
RELEASE !!=	uname -r
QUEUE !!=	openssl rand -hex 16

PKG =		dkimproxy \
		dovecot \
		dovecot-pigeonhole \
		rspamd \
		opensmtpd-extras \
		gnupg-2.2.12

#-8<-----------	[ cut here ] --------------------------------------------------^

.if exists(Makefile.local)
. include "Makefile.local"
.endif

.if empty(BACKUP_HOST)
DOVECOTCONF +=	${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-replication.conf.optional
PRIMARY =	yes
.else
DOVECOTCONF +=	${BASESYSCONFDIR:S|^/||}/dovecot/conf.d/90-replication.conf
.endif

.if ${PRIMARY} == "yes"
HOSTNAME =	${PRIMARY_HOST}.${DOMAIN_NAME}
.else
HOSTNAME =	${BACKUP_HOST}.${DOMAIN_NAME}
.endif

# Specifications (target rules)

.if ${UPGRADE} == "yes"
upgrade: config .WAIT ${CAESONIA}
	@echo Upgrade
.else
upgrade: config
	@echo Fresh install
.endif

config:
	mkdir -m750 ${WRKSRC}
	(umask 077; cp -R ${.CURDIR}/src/* ${WRKSRC})
.if !empty(VHOSTS_NAME)
. for _VHOSTS_NAME in ${VHOSTS_NAME}
	echo ${_VHOSTS_NAME} >> ${WRKSRC}/${MAILCONF:M*vdomains}
	sed -i \
		-e '/autoconfig.example.net/{p;s|.*|		autoconfig.${_VHOSTS_NAME} \\|;}' \
		-e '/mta-sts.example.net/{p;s|.*|		mta-sts.${_VHOSTS_NAME} \\|;}' \
		-e '/wkd.example.net/{p;s|.*|		wkd.${_VHOSTS_NAME} \\|;}' \
		${WRKSRC}/${SYSCONF:M*acme-client.conf}
	sed -i \
		-e '/^puffy@example.net/{p;s|.*|${VIRTUAL_USER}@${_VHOSTS_NAME}		\
			${VIRTUAL_USER}@${DOMAIN_NAME}|;}' \
		${WRKSRC}/${MAILCONF:M*virtual}
	echo @${_VHOSTS_NAME} >> ${WRKSRC}/${MAILCONF:M*whitelist}
	sed -i \
		-e '/^domain/ s|$$|,${_VHOSTS_NAME}|' \
		${WRKSRC}/${DKIMPROXYCONF:M*dkimproxy_out.conf}
. endfor
.endif
	sed -i \
		-e '/^domain/s|,example.net||' \
		${WRKSRC}/${DKIMPROXYCONF:M*dkimproxy_out.conf}
	sed -i \
		-e '/example.net/d' \
		${WRKSRC}/${MAILCONF:M*vdomains} \
		${WRKSRC}/${MAILCONF:M*whitelist} \
		${WRKSRC}/${SYSCONF:M*acme-client.conf}
	sed -i \
		-e '/^puffy@example.net/d' \
		${WRKSRC}/${MAILCONF:M*virtual}
	sed -i \
		-e 's|^puffy|${WHEEL_USER}|' \
		${WRKSRC}/${MAILCONF:M*aliases}
	sed -i \
		-e "s/5101bef20f4d02c826bffc243e15a7c0/${QUEUE}/" \
		${WRKSRC}/${MAILCONF:M*smtpd.conf}
	find ${WRKSRC} -type f -exec sed -i \
		-e 's|vio0|${EGRESS}|' \
		-e 's|obsd|${DKIM_SELECTOR}|' \
		-e 's|puffy|${VIRTUAL_USER}|' \
		-e 's|example.com|${DOMAIN_NAME}|' \
		-e 's|203.0.113.1|${PRIMARY_IPv4}|' \
		-e 's|2001:0db8::1|${PRIMARY_IPv6}|' \
		-e '/autoexpunge /s|30d|${AUTOEXPUNGE}|' \
		-e '/storage=/s|15G|${MAIL_QUOTA}|' \
		-e 's|35M|${MAX_MESSAGE_SIZE}|' \
		-e '/full_sync_interval/s|1h|${FULL_SYNC_INTERVAL}|' \
		{} +
.if empty(BACKUP_HOST)
	sed -i \
		-e 's/dsync\ //g' \
		${WRKSRC}/${PFCONF:M*pf.conf}
	sed -i \
		-e '/203.0.113.2/d' \
		-e '/2001:0db8::2/d' \
		${WRKSRC}/${MAILCONF:M*relays}
	sed -i \
		-e '/hermes/d' \
		${WRKSRC}/${TLSRPT:M*mta-sts.txt} \
		${WRKSRC}/${SYSCONF:M*acme-client.conf}
	find ${WRKSRC} -type f -exec sed -i \
		-e 's|mercury|${PRIMARY_HOST}|' \
		{} +
.else
	find ${WRKSRC} -type f -exec sed -i \
		-e 's|203.0.113.2|${BACKUP_IPv4}|' \
		-e 's|2001:0db8::2|${BACKUP_IPv6}|' \
		{} +
	cp -p ${WRKSRC}${BASESYSCONFDIR}/dovecot/conf.d/90-replication.conf.optional \
		${WRKSRC}${BASESYSCONFDIR}/dovecot/conf.d/90-replication.conf
. if ${PRIMARY} == "yes"
	find ${WRKSRC} -type f -exec sed -i \
		-e 's|mercury|${PRIMARY_HOST}|' \
		-e 's|hermes|${BACKUP_HOST}|' \
		{} +
	@echo Primary MX
. else
	find ${WRKSRC} -type f -exec sed -i \
		-e 's|mercury|${BACKUP_HOST}|' \
		-e 's|hermes|${PRIMARY_HOST}|' \
		{} +
	sed -i \
		-e 's|action "mda"|action "backup"|' \
		${WRKSRC}/${MAILCONF:M*smtpd.conf}
	sed -i \
		-e '/^[[:space:]]alternative/,/^[[:space:]]}/d' \
		${WRKSRC}/${SYSCONF:M*acme-client.conf}
	@echo Backup MX
. endif
.endif
	mv ${WRKSRC}${VARBASE}/www/htdocs/mercury.example.com \
		${WRKSRC}${VARBASE}/www/htdocs/${HOSTNAME}
	@echo Configured

${CAESONIA}:
	[[ -r ${DESTDIR}/$@ ]] \
	&& (umask 077; diff -u ${DESTDIR}/$@ ${WRKSRC}/$@ >/dev/null \
		|| sdiff -as -w $$(tput -T $${TERM:-vt100} cols) \
			-o ${WRKSRC}/$@.merged \
			${DESTDIR}/$@ \
			${WRKSRC}/$@) \
	|| [[ "$$?" -eq 1 ]]

clean:
	@rm -r ${WRKSRC}

beforeinstall: upgrade
	-rcctl stop smtpd httpd dkimproxy_out rspamd dovecot
.for _PKG in ${PKG}
	env PKG_PATH= pkg_info ${_PKG} > /dev/null || pkg_add ${_PKG}
.endfor
.if ${UPGRADE} == "yes"
. for _CAESONIA in ${CAESONIA}
	[[ -r ${_CAESONIA:S|^|${WRKSRC}/|:S|$|.merged|} ]] \
	&& cp -p ${WRKSRC}/${_CAESONIA}.merged ${WRKSRC}/${_CAESONIA} \
	|| [[ "$$?" -eq 1 ]]
. endfor
.endif

realinstall:
	${INSTALL} -d ${VARBASE}/dovecot/imapsieve/{after,before}
	${INSTALL} -d ${VARBASE}/dovecot/sieve/{after,before}
	${INSTALL} -d ${BASESYSCONFDIR}/rspamd/{local.d,override.d}
	${INSTALL} -d ${VARBASE}/www/openpgpkey/hu
	${INSTALL} -d ${VARBASE}/www/mta-sts
	${INSTALL} -d ${VARBASE}/www/htdocs/${HOSTNAME}/mail
	${INSTALL} -d ${BASESYSCONFDIR}/ssl/dkim/private
.for _NAME in ${DOMAIN_NAME} ${VHOSTS_NAME}
	${INSTALL} -d ${VARBASE}/lib/gnupg/wks/${_NAME}/pending
	ln -sf ${VARBASE}/www/openpgpkey/hu \
		${VARBASE}/lib/gnupg/wks/${_NAME}
	ln -sf ${VARBASE}/www/openpgpkey/submission-address \
		${VARBASE}/lib/gnupg/wks/${_NAME}
.endfor
.for _CAESONIA in ${CAESONIA:N*cron/tabs*}
	${INSTALL} -S -o ${LOCALEOWN} -g ${LOCALEGRP} -m 440 \
		${_CAESONIA:S|^|${WRKSRC}/|} \
		${_CAESONIA:S|^|${DESTDIR}/|}
.endfor

afterinstall:
.if !empty(CRONTAB)
	crontab -u root ${WRKSRC}/${CRONTAB}
.endif
	user info -e vmail \
		|| user add -u 2000 -g =uid -c "Virtual Mail" -s /sbin/nologin -b ${VARBASE} -m vmail
.if !empty(BACKUP_HOST)
	user info -e dsync \
		|| user add -u 2001 -g =uid -c "Dsync Replication" -s /bin/ksh -m dsync
.endif
	[[ -r ${BASESYSCONFDIR}/changelist-${RELEASE} ]] \
		|| cp ${BASESYSCONFDIR}/changelist ${BASESYSCONFDIR}/changelist-${RELEASE}
	sed -i '/changelist.local/,$$d' ${BASESYSCONFDIR}/changelist
	cat ${BASESYSCONFDIR}/changelist.local >> ${BASESYSCONFDIR}/changelist
.for _SIEVE in ${SIEVE}
	sievec /${_SIEVE}
.endfor
	doas -u vmail /usr/local/bin/gpg2 -K --with-wkd-hash key-submission@${DOMAIN_NAME} || \
		doas -u vmail /usr/local/bin/gpg2 --batch --passphrase "" \
			--quick-gen-key key-submission@${DOMAIN_NAME}
	chown vmail ${VARBASE}/www/openpgpkey/hu
	[[ -r ${VARBASE}/www/openpgpkey/hu/54f6ry7x1qqtpor16txw5gdmdbbh6a73 ]] || \
		doas -u vmail /usr/local/bin/gpg2 \
			-o ${VARBASE}/lib/gnupg/wks/${DOMAIN_NAME}/hu/54f6ry7x1qqtpor16txw5gdmdbbh6a73 \
			--export-options export-minimal --export key-submission@${DOMAIN_NAME}
	[[ -r ${BASESYSCONFDIR}/ssl/dkim/private/private.key ]] || (umask 077; \
		openssl genrsa -out ${BASESYSCONFDIR}/ssl/dkim/private/private.key 2048; \
		openssl rsa -in ${BASESYSCONFDIR}/ssl/dkim/private/private.key \
			-pubout -out ${BASESYSCONFDIR}/ssl/dkim/public.key)
	sed -i '/^console/s/ secure//' ${BASESYSCONFDIR}/ttys
	mtree -qef ${BASESYSCONFDIR}/mtree/special -p / -U
	mtree -qef ${BASESYSCONFDIR}/mtree/special.local -p / -U
	pfctl -f /etc/pf.conf
	rcctl disable check_quotas sndiod
	-rcctl check sndiod && rcctl stop sndiod
	rcctl enable unbound sshd httpd dkimproxy_out rspamd dovecot smtpd
	rcctl restart unbound sshd httpd
	ftp -o - https://${HOSTNAME}/index.html \
		|| acme-client -ADv ${HOSTNAME}
	ocspcheck -vNo ${BASESYSCONFDIR}/ssl/acme/${HOSTNAME}.ocsp.resp.der \
		${BASESYSCONFDIR}/ssl/acme/${HOSTNAME}.fullchain.pem
	rcctl restart httpd dkimproxy_out rspamd dovecot smtpd

.PHONY: upgrade
.USE: upgrade

.include <bsd.prog.mk>
