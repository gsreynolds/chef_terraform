#!/bin/bash
set -eu -o pipefail

export ssh_user
export ssh_key
export a2_ip

eval "$(jq -r '@sh "export ssh_user=\(.ssh_user) ssh_key=\(.ssh_key) a2_ip=\(.a2_ip)"')"
mkdir -p .chef/
scp -o stricthostkeychecking=no -i ${ssh_key} ${ssh_user}@${a2_ip}:/home/${ssh_user}/automate-credentials.toml .chef/automate-credentials.toml

a2_admin="$(cat .chef/automate-credentials.toml | sed -n -e 's/^username = //p' | tr -d '"')"
a2_password="$(cat .chef/automate-credentials.toml | sed -n -e 's/^password = //p' | tr -d '"')"
a2_admin_token="$(cat .chef/automate-credentials.toml | sed -n -e 's/^admin-token = //p' | tr -d '"')"
a2_ingest_token="$(cat .chef/automate-credentials.toml | sed -n -e 's/^ingest-token = //p' | tr -d '"')"
a2_url="$(cat .chef/automate-credentials.toml | sed -n -e 's/^url = //p' | tr -d '"')"

jq -n --arg a2_admin "$a2_admin" \
      --arg a2_password "$a2_password" \
      --arg a2_admin_token "$a2_admin_token" \
      --arg a2_ingest_token "$a2_ingest_token" \
      --arg a2_url "$a2_url" \
      '{"a2_admin":$a2_admin,"a2_password":$a2_password,"a2_admin_token":$a2_admin_token,"a2_ingest_token":$a2_ingest_token,"a2_url":$a2_url}'
