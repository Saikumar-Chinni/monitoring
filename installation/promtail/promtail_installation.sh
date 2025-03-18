#!/bin/bash
#update the version based on requirement
#after script run completed go to the /etc/promail/promtail-local-config.yaml
#in the clent URL place change the ip based on your requirement
#defaultly it will collect /var/lib/*log if you want customize that one
set -e

version="3.2.0"

download() {
    # Check if unzip is installed, install if missing
    if ! command -v unzip &> /dev/null; then
        echo "Unzip not found. Installing unzip..."
        sudo apt update -y && sudo apt install -y unzip
    fi
    curl -O -L "https://github.com/grafana/loki/releases/download/v$version/promtail-linux-amd64.zip"
    unzip "promtail-linux-amd64.zip"
    chmod a+x "promtail-linux-amd64"
    sudo mv promtail-linux-amd64 /usr/local/bin
}

create_config() {
    sudo mkdir /etc/promtail
    cd /etc/promtail
    sudo wget https://raw.githubusercontent.com/grafana/loki/v$version/clients/cmd/promtail/promtail-local-config.yaml
}
service_file() {
    sudo tee /etc/systemd/system/promtail.service > /dev/null <<EOF
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/usr/local/bin/promtail-linux-amd64 -config.file /etc/promtail/promtail-local-config.yaml

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start promtail
sudo systemctl enable promtail
sudo systemctl status promtail
}

download
create_config
service_file