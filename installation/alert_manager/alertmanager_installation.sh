#!/bin/bash

set -e

version="0.28.0-rc.0"

downlaod() {
    wget https://github.com/prometheus/alertmanager/releases/download/v$version/alertmanager-$version.linux-amd64.tar.gz
    tar -xvzf alertmanager-$version.linux-amd64.tar.gz
    sudo mv alertmanager-$version.linux-amd64 /etc/alertmanager
    sudo mv /etc/alertmanager/alertmanager /usr/local/bin

}
service_file() {
sudo mkdir /var/lib/alertmanager
    sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF

[Unit]
Description=Alertmanager Service
Documentation=https://prometheus.io/docs/alerting/latest/alertmanager/
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager

Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl status alertmanager
}
downlaod
service_file