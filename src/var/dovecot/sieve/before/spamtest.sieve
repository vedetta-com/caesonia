require "spamtestplus";
require "fileinto";
require "relational";
require "comparator-i;ascii-numeric";
require "imap4flags";

if spamtest :value "gt" :comparator "i;ascii-numeric" :percent "95" {
/*  discard;*/
    fileinto "Spam";
    setflag "\\seen";
    stop;
} elsif spamtest :value "ge" :comparator "i;ascii-numeric" :percent "50" {
    fileinto "Spam";
/*  setflag "\\seen";*/
    stop;
}

/* Other messages get filed into INBOX */
