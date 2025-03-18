#!/bin/bash
#update the version based on requirement

set -e

version="3.2.0"

download() {
    # Check if unzip is installed, install if missing
    if ! command -v unzip &> /dev/null; then
        echo "Unzip not found. Installing unzip..."
        sudo apt update -y && sudo apt install -y unzip
    fi
    curl -O -L "https://github.com/grafana/loki/releases/download/v$version/loki-linux-amd64.zip"
    unzip "loki-linux-amd64.zip"
    chmod a+x "loki-linux-amd64"
    sudo mv loki-linux-amd64 /usr/local/bin
}

create_config() {
    sudo mkdir /etc/loki
    cd /etc/loki
    sudo wget https://raw.githubusercontent.com/grafana/loki/v$version/cmd/loki/loki-local-config.yaml
}
service_file() {
    sudo tee /etc/systemd/system/loki.service > /dev/null <<EOF
[Unit]
Description=loki service
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/loki-linux-amd64 -config.file /etc/loki/loki-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start loki
sudo systemctl enable loki
sudo systemctl status loki
}

download
create_config
service_file