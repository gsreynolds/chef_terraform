interval = 1800
splay = 1800
splay_first_run = 0
log_level = 'warn'

[chef_license]
acceptance = "accept-no-persist"

[automate]
enable = true
server_url = "https://${automate_fqdn}"
token = "${data_collector_token}"
