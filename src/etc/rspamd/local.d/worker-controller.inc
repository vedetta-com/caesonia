# https://www.rspamd.com/doc/workers/controller.html

# generate a password hash using `rspamadm pw`
password = "$2$wmt7yi4sdj7gfq4yt8ib3eamz4ahze9r$1rzdhjh4buwxweikdwd3equzuzbt95qttby54o91ywk3ic398osb";

# dovecot will use this socket to communicate with rspamd
bind_socket = "/var/run/rspamd/rspamd.sock mode=0660 owner=vmail"; # _rspamd

# web interface
#bind_socket = "127.0.0.1:11334";

max_tasks = 20;
