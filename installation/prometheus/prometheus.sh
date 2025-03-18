#!/bin/bash

set -e

version="2.53.3"

downlaod() {
    wget https://github.com/prometheus/prometheus/releases/download/v$version/prometheus-$version.linux-amd64.tar.gz
    tar -xvzf prometheus-$version.linux-amd64.tar.gz
    sudo mv prometheus-$version.linux-amd64 /etc/prometheus
    sudo mv /etc/prometheus/prometheus /usr/local/bin
}
service_file() {
    sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
}
downlaod
service_file