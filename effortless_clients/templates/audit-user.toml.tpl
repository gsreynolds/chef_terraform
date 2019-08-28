sleep_time = 30

[reporter]
stdout = false
url = "https://${automate_fqdn}/data-collector/v0"
token = "${data_collector_token}"
verify_ssl = true

[chef_license]
acceptance = "accept-no-persist"
