#!/bin/bash

version="1.8.2"

downlaod() {
    wget https://github.com/prometheus/node_exporter/releases/download/v$version/node_exporter-$version.linux-amd64.tar.gz
    tar -xvzf node_exporter-$version.linux-amd64.tar.gz
    cd node_exporter-$version.linux-amd64
    sudo mv node_exporter /usr/local/bin

}

service_file() {
#!/bin/bash

# Create the systemd service file for Node Exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service > /dev/null
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target 

[Service]
ExecStart=/usr/local/bin/node_exporter --collector.systemd
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new service
sudo systemctl daemon-reload

# Enable and start the Node Exporter service
sudo systemctl enable node_exporter.service
sudo systemctl start node_exporter.service

# Check the status of the Node Exporter service
sudo systemctl status node_exporter.service

}
downlaod
service_file