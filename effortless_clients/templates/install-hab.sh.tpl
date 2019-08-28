#!/usr/bin/env bash
set -euo pipefail

export HAB_NONINTERACTIVE=true
export HAB_NOCOLORING=true
export HAB_LICENSE=accept-no-persist

groupadd hab
useradd -g hab hab
curl https://raw.githubusercontent.com/habitat-sh/habitat/master/components/hab/install.sh | sudo bash
hab license accept
mv hab-sup.service /etc/systemd/system/hab-sup.service
chmod 664 /etc/systemd/system/hab-sup.service
systemctl daemon-reload
systemctl enable hab-sup.service
systemctl start hab-sup.service
sleep 15
