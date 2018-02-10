#require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

#if environment :matches "imap.user" "*" {
#  set "username" "${1}";
#}

#pipe :copy "learn_spam" [ "${username}" ];

# https://rspamd.com/doc/tutorials/feedback_from_users_with_IMAPSieve.html
# https://wiki2.dovecot.org/Pigeonhole/Sieve/Plugins/Pipe
# http://hg.rename-it.nl/pigeonhole-0.2-sieve-pipe/raw-file/tip/doc/rfc/spec-bosch-sieve-pipe.txt
require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables", "imap4flags"];

if environment :matches "imap.user" "*" {
  set "username" "${1}";
}

if environment :is "imap.cause" "COPY" {
    pipe :copy :try "learn_spam" [ "${username}" ];
}

# Catch replied or forwarded spam
elsif anyof (allof (hasflag "\\Answered",
		    environment :contains "imap.changedflags" "\\Answered"),
             allof (hasflag "$Forwarded",
		    environment :contains "imap.changedflags" "$Forwarded")) {
    pipe :copy :try "learn_spam" [ "${username}" ];
}
