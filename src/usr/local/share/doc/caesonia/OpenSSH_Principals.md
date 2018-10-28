# OpenSSH Principals

> [OpenSSH](https://www.openssh.com/) is incorporated into many commercial products, but very few of those companies assist OpenSSH with funding.

Table of contents:
- [Introduction](#openssh-principals)
- [Principals](#principals)
- [Certificate Authority](#certificate-authority)
  - [Host Certificates](#host-certificates)
  - [User Certificates](#user-certificates)
  - [Key Revocation List](#key-revocation-list)
- [Daemon Configuration](#daemon-configuration)
- [Client Configuration](#client-configuration)
- [Gateway](#gateway)

OpenSSH daemon, in its default configuration, is more than sufficient for one user to remote login into one machine, with sophisticated security.

A typical fresh install has SSH host keys, and the OpenSSH daemon started on first boot.

The machine's public host key is extracted on first use:
```console
laptop$ ssh 2001:0db8::1
The authenticity of host '2001:0db8::1 (2001:0db8::1)' can't be established.
```

As another option:
```console
laptop$ ssh-keyscan -t ed25519 2001:0db8::1
```

At this moment, the public host key to be added in `~/.ssh/known_hosts` (by the SSH protocol) is validated, completing the trust on first use (TOFU) security model.
```console
Are you sure you want to continue connecting (yes/no)? yes
```

The identified public host key's fingerprint will be added to the DNS zone of the name associated with the host's IP address:
```console
mercury.example.com	IN	AAAA	2001:0db8::1
```

Print the Secure Shell (Key) Fingerprint (SSHFP) Resource Record (RR) for the public host key:
```console
laptop$ ssh-keygen -r 2001:0db8::1 -f ssh_host_ed25519_key.pub
laptop$ ssh-keyscan -D -t ed25519 2001:0db8::1
```

SSHFP RR are added to the DNS zone for the chosen name, and signed:
```console
mercury.example.com	IN	SSHFP	4 1 ec3fdef6b0bsd2dc3f8163a1e08069c92ff96d49
mercury.example.com	IN	SSHFP	4 2 f510394a7e4490800bsd15d066ecd0ae131ec6b03c7ca269a9013a62730ab2ca
```

After the DNS zone propagates, SSH fingerprints can be verified by a DNSSEC aware resolver:
```console
laptop$ ssh -o "VerifyHostKeyDNS ask" puffy@mercury.example.com
```

In addition, the configuration option "VisualHostKey yes" generates "random art" on every login, for comparison:
```console
laptop$ ssh -o "VisualHostKey yes" puffy@mercury.example.com
+-[ED25519-CERT]--+
|  +  ....+o.     |
|.o *.   o +.     |
|=.B.   o oo.     |
|+X.=    o..o     |
|BoO .   S.  .    |
|XX o             |
|B+B              |
|+o               |
|oE               |
+----[SHA256]-----+
```

The operating system installation script may include the system administrator's public key, for OpenSSH "publickey" authentication (on first boot):
```console
Next authentication method: publickey
```

Otherwise, she must login using the interractive "password" authentication method, to add her public key on the host:
```console
laptop$ cat ~/.ssh/id_ed25519.pub | ssh puffy@mercury.example.com "cat >> .ssh/authorized_keys"
```

*i.e.* Remote access to local user "puffy" on host "mercury.example.com" is now under control.

As more systems and users are added to the mix, it becomes cumbersome to manage and keep remote access secure solely with the TOFU model.

To scale, OpenSSH implements a mechanism for using a trusted third party in the form of Certificate Authority (CA).

## Principals

While the concept is similar to X.509 (commonly used in TLS), OpenSSH certificates are a different format. They contain much less information, which doesn't mean they are less useful. In fact, OpenSSH certificates allow fine-grained control to local users and hosts with security principal.

OpenSSH provides both identification and authentication of hosts and users, which are distinct entities, as seen earlier with TOFU. Certificates expand this security model.

Hosts and users still need to go through TOFU, but only once, which greatly improves security and usability of OpenSSH keys, and a fortiori the TOFU model itself.

Moreoever, instead of configuring access on each host, principal permissions are set inside the certificate, and signed by a central authority.

In computer security, and in OpenSSL, principals can be hosts, users, or groups of various types.

Each principal has a distinct security identifier (SID):
- Host identities can be part of individual hostname principals, or groups.
- User identities can be part of individual user principals, or groups.

Expanding on the previous scenario, let's introduce a CA and combine these characteristics by adding a second host.

To make it tangible, we'll focus on the [email service](https://github.com/vedetta-com/caesonia) of a simple network, and our two hosts in this example will become the primary and backup MX.

## Certificate Authority

OpenSSH Certificate Authorities may be created on encrypted flash memory card/drive, and operated on single purpose secure machines, with no network access.

```console
/etc
 |-ssh/
 | |-ca/
 | | |-.ssh/
 | | | |-ssh_ca_ed25519
 | | | |-ssh_ca_ed25519.pub
 | | |-ssh_ca.krl
 | | |-host/
 | | | |-hermes.example.com/
 | | | | |-.ssh/
 | | | | | |-ssh_host_ed25519_key.pub
 | | | | | |-ssh_host_ed25519_key-cert.pub
 | | | |-mercury.example.com/
 | | | | |-.ssh/
 | | | | | |-ssh_host_ed25519_key.pub
 | | | | | |-ssh_host_ed25519_key-cert.pub
 | | |-user/
 | | | |-puffy/
 | | | | |-.ssh/
 | | | | | |-id_ed25519.pub
 | | | | | |-id_ed25519-cert.pub
 | | |-auth/
 | | | |-all
 | | | |-backup
 | | | |-database
 | | | |-dns
 | | | |-email
 | | | |-router
 | | | |-nas
 | | | |-web
```

Since two hosts are part of the same service, they'll be part of the same "email" group principal. In this way, authentication is based on service type, instead on each host in the service group.

*n.b.* The files under `/etc/ssh/ca/auth` represent other services on the network, and are informational cues.

Let's create each part of this sample CA, starting with its layout:
```console
airtight# mkdir -pm 755 /etc/ssh/ca/.ssh
```

Generate a new password protected CA key:
```console
airtight# ssh-keygen -t ed25519 -C ca@example.com -f /etc/ssh/ca/.ssh/ssh_ca_ed25519
```

Transfer the public CA key from CA to sysadmin's laptop, and further to the host:
```console
laptop$ scp /etc/ssh/ca/.ssh/ssh_ca_ed25519.pub \
	puffy@mercury.example.com:/etc/ssh/ca/.ssh/
```

The CA is now ready to issue signed certificates with the following information:
- public key
- ([-I](https://man.openbsd.org/ssh-keygen#I)) identity
- ([-n](https://man.openbsd.org/ssh-keygen#n)) principal(s)
- ([-V](https://man.openbsd.org/ssh-keygen#V)) validity interval
- ([-z](https://man.openbsd.org/ssh-keygen#z)) serial number
- ([-O](https://man.openbsd.org/ssh-keygen#O)) configuration options

### Host certificates

OpenSSH host certificates authenticate server hosts to users.

Add a new host to CA:
```console
airtight# mkdir -pm 755 /etc/ssh/ca/host/mercury.example.com/.ssh
```

Add the identified public host key:
```console
airtight# cp ssh_host_ed25519_key.pub /etc/ssh/ca/host/mercury.example.com/.ssh/
```

Generate a (-h) host certificate, using the `hostname` as identity and principal:
```console
airtight# ssh-keygen -s /etc/ssh/ca/.ssh/ssh_ca_ed25519 \
	-h \
	-I mercury.example.com \
	-n mercury.example.com \
	-V always:forever \
	-z 1 \
	/etc/ssh/ca/host/mercury.example.com/.ssh/ssh_host_ed25519_key.pub
```

Verify:
```console
airtight# ssh-keygen -L \
	-f /etc/ssh/ca/host/mercury.example.com/.ssh/ssh_host_ed25519_key-cert.pub

	Type: ssh-ed25519-cert-v01@openssh.com host certificate
	Public key: ED25519-CERT SHA256:OBsd...
	Signing CA: ED25519 SHA256:Zszg...
	Key ID: "mercury.example.com"
	Serial: 1
	Valid: forever
	Principals:
		mercury.example.com
	Critical Options: (none)
	Extensions: (none)
```

Transfer the host certificate from CA to sysadmin's laptop, and further to the host:
```console
laptop$ scp /etc/ssh/ca/host/mercury.example.com/.ssh/ssh_host_ed25519_key-cert.pub \
	puffy@mercury.example.com:/etc/ssh/
```

The second host, "hermes.example.com" is added to the CA and processed as above.

### User certificates

OpenSSH user certificates authenticate users to servers.

On her end, the user generates a new password protected key:
```console
laptop$ ssh-keygen -t ed25519 -C puffy@example.com
> Enter file in which to save the key (/home/puffy/.ssh/id_ed25519):
```

The user sends her public key to her system administrator, to generate a user certificate, using "email" group principal:
```console
airtight# ssh-keygen -s /etc/ssh/ca/.ssh/ssh_ca_ed25519 \
	-I puffy \
	-n email \
        -O no-x11-forwarding \
	-V +31d \
	-z 2 \
	/etc/ssh/ca/user/puffy/.ssh/id_ed25519.pub
> Signed user key /etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub: id "puffy" serial 2 for puffy valid from 2018-10-02T13:41:00 to 2018-10-31T13:42:37
```

Verify: 
```console
airtight# ssh-keygen -L \
	-f /etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub

	Type: ssh-ed25519-cert-v01@openssh.com user certificate
	Public key: ED25519-CERT SHA256:0B5d...
	Signing CA: ED25519 SHA256:Zszg...
	Key ID: "puffy"
	Serial: 2
	Valid: from 2018-10-02T13:41:00 to 2018-10-31T13:42:37
	Principals:
		email
	Critical Options: (none)
	Extensions:
		permit-agent-forwarding
		permit-port-forwarding
		permit-pty
		permit-user-rc
```

Transfer the user certificate from CA to sysadmin's laptop (and further to the user):
```console
laptop$ scp /etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub \
	puffy@mercury.example.com:/home/puffy/.ssh/
```

### Key Revocation List

Key revocation lists (KRL) avoid the process of recreating the CA on each change.

Create a new KRL
```console
airtight# ssh-keygen -k \
	-f /etc/ssh/ca/ssh_ca.krl \
	-s /etc/ssh/ca/.ssh/ssh_ca_ed25519.pub \
	-z 2 \
	/etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub
```

Update an existing KRL
```console
airtight# ssh-keygen -k \
	-f /etc/ssh/ca/ssh_ca.krl \
	-u \
	-s /etc/ssh/ca/.ssh/ssh_ca_ed25519.pub \
	-z 2 \
	/etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub
```

Query KRL
```console
airtight# ssh-keygen -Q \
	-f /etc/ssh/ca/ssh_ca.krl \
	/etc/ssh/ca/user/puffy/.ssh/id_ed25519-cert.pub
```

On each update, transfer the KRL to a distribution location for all hosts, or:
```console
laptop$ scp /etc/ssh/ca/ssh_ca.krl puffy@mercury.example.com:/etc/ssh/ca/
laptop$ scp /etc/ssh/ca/ssh_ca.krl puffy@hermes.example.com:/etc/ssh/ca/
```

By now, hosts and users are in possession of their certificates, and OpenSSH needs to be aware of this.

## Daemon configuration
```console
/etc
 |-ssh/
 | |-ca/
 | | |-ssh_ca.krl
 | |-principals/
 | | |-puffy
 | |-ssh_host_ed25519_key
 | |-ssh_host_ed25519_key-cert.pub
 | |-ssh_host_ed25519_key.pub
```

On hosts, we associate principals with local users:
```console
mercury# mkdir -m 755 /etc/ssh/principals
mercury# echo -e 'email' > /etc/ssh/principals/puffy
```

*i.e.* The "email" group principal has access to local user "puffy", on hosts "mercury.example.com" and "hermes.example.com".

Relevant daemon configuration snippet:
```console
mercury# cat /etc/ssh/sshd_config
...
#HostKey /etc/ssh/ssh_host_ed25519_key

# https://man.openbsd.org/sshd_config.5#HostKeyAlgorithms
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-ed25519
HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

# Certificate Authority
TrustedUserCAKeys /etc/ssh/ca/.ssh/ssh_ca_ed25519.pub
RevokedKeys /etc/ssh/ca/ssh_ca.krl
# http://man.openbsd.org/sshd_config.5#CASignatureAlgorithms
CASignatureAlgorithms  ssh-ed25519

PermitRootLogin no # default: prohibit-password

#PubkeyAuthentication yes
# http://man.openbsd.org/sshd_config.5#PubkeyAcceptedKeyTypes
PubkeyAcceptedKeyTypes ssh-ed25519-cert-v01@openssh.com,ssh-ed25519

AuthorizedKeysFile	none # default: .ssh/authorized_keys

# http://man.openbsd.org/sshd_config.5#AuthorizedPrincipalsFile
AuthorizedPrincipalsFile /etc/ssh/principals/%u # default: none

PasswordAuthentication no # default: yes
...
```

## Client configuration
```console
~
 |-.ssh/
 | |-config
 | |-known_hosts
 | |-id_ed25519
 | |-id_ed25519-cert.pub
 | |-id_ed25519.pub
```

Relevant client configuration snippet for CA public key:
```console
laptop$ cat ~/.ssh/known_hosts
@cert-authority *.example.com ssh-ed25519 AAAA... ca@example.com
```

[Hash](https://man.openbsd.org/ssh-keygen#H) "known_hosts" file:
```console
laptop$ ssh-keygen -H \
	-f ~/.ssh/known_hosts
```

Relevant client configuration snippet for SSHFP:
```console
laptop$ cat ~/.ssh/config
Host *
	VerifyHostKeyDNS ask
	VisualHostKey yes
```

## Gateway

OpenSSH configuration is flexible, and it is well worth upgrading to certificates, even for a single user.

It is possible to further centralize with [OpenSSH gateway](https://github.com/vedetta-com/vedetta/blob/master/src/etc/relayd.conf.relay.ssh), using `relayd` and `rdomain`:
```console
gateway$ cat /etc/ssh/sshd_config
...
#http://man.openbsd.org/rdomain

#http://man.openbsd.org/sshd_config#ListenAddress
ListenAddress :: rdomain 1

#http://man.openbsd.org/sshd_config#RDomain
#http://man.openbsd.org/sshd_config#Match
RDomain %D
...
```

Contributions welcome, please open a [Pull Request](https://github.com/vedetta-com/vedetta/pulls)

