# https://www.rspamd.com/doc/workers/rspamd_proxy.html
enabled = false;

# this worker will be used as postfix milter
milter = yes;

# note to self - tighten up these permissions
bind_socket = "/var/run/rspamd/milter.sock mode=0666 owner=nobody";

# the following specifies self-scan mode, for when rspamd is on the same
# machine as postfix
timeout = 120s;
upstream "local" {
  default = yes;
  self_scan = yes;
}
