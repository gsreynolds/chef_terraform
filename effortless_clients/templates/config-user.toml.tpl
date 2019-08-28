interval = 1800
splay = 1800
splay_first_run = 0
run_lock_timeout = 1800

[chef_license]
acceptance = "accept-no-persist"

[automate]
enable = true
server_url = "https://${automate_fqdn}/data-collector/v0"
token = "${data_collector_token}"
