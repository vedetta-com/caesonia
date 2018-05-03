# Web Key Service Server Tool
require ["envelope", "vnd.dovecot.pipe"];

if envelope :all :contains ["To"] "key-submission@example.com" {
  if address :DOMAIN :contains ["From"] ".example.com" {
    discard;
    stop;
  }
  if allof (NOT envelope :all :contains "From" "key-submission@example.com",
            NOT header :is ["X-WKS-Loop"] ["wks.example.com"]) {
    pipe "wks-server" [ "key-submission@example.com" ];
    discard;
  }
}
