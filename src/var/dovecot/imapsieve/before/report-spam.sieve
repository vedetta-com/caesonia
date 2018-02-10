# https://rspamd.com/doc/tutorials/feedback_from_users_with_IMAPSieve.html
# https://wiki2.dovecot.org/Pigeonhole/Sieve/Plugins/Pipe
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
