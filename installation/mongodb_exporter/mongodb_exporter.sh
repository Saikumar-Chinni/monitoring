#!/bin/bash

#Adjust 

# Variables
EXPORTER_BIN="/home/$USER/mongodb_exporter/mongodb_exporter"
DEST_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/mongodb_exporter.service"
MONGO_USER="monitor"  # MongoDB monitoring user
MONGO_PASS="monitor"  # MongoDB monitoring user password
MONGO_PORT="27017"
MONGODB_URI="mongodb://$MONGO_USER:$MONGO_PASS@localhost:$MONGO_PORT/admin"  # MongoDB URI for the exporter

check_mongodb_installation() {
    if which mongod > /dev/null; then
        echo "MongoDB is installed."
    else
        echo "MongoDB is not installed."
        echo "Please install MongoDB before proceeding with the MongoDB exporter setup."
        exit 1  # Exit the script with an error status
    fi
}

go_installation() {
if which go >/dev/null; then
   echo "Go is installed successfully"
else
   echo "Please wait installing the golang"
   wget https://go.dev/dl/go1.23.3.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   sudo echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
   source ~/.bashrc 
   echo "go installed this version: $(go version)"
fi
}

build_mongodb_exporter() {
if which git >/dev/null; then
    echo "git is found"
    git clone https://github.com/percona/mongodb_exporter.git
    cd mongodb_exporter
    go build
else
    echo "git is not installed"
    sudo apt install git
    build_mongodb_exporter
fi
}

create_mongo_user() {
    echo "Creating MongoDB user for monitoring..."

    mongosh --port $MONGO_PORT<<EOF
use admin
db.createUser({
    user: "$MONGO_USER",
    pwd: "$MONGO_PASS",
    roles: [
        { role: "clusterMonitor", db: "admin" }
    ]
})
EOF

    # Check if the user was created successfully
    if [ $? -eq 0 ]; then
        echo "MongoDB user $MONGO_USER created successfully."
    else
        echo "Failed to create MongoDB user $MONGO_USER."
        exit 1
    fi
}

# Step 1: Move the mongodb_exporter binary to /usr/local/bin
move_exporter() {
    if [ -f "$EXPORTER_BIN" ]; then
        echo "Moving $EXPORTER_BIN to $DEST_DIR..."
        sudo cp "$EXPORTER_BIN" "$DEST_DIR"
        sudo chmod +x "$DEST_DIR/$EXPORTER_BIN"
        echo "$EXPORTER_BIN has been moved to $DEST_DIR"
    else
        echo "$EXPORTER_BIN not found in the current directory!"
        exit 1
    fi
}

# Step 2: Create the systemd service file for mongodb_exporter
create_service_file() {
    echo "Creating systemd service file..."

    # Create the service file with username and password included
    sudo bash -c "cat > $SERVICE_FILE" << EOF
[Unit]
Description=MongoDB Exporter
User=mongodb
Group=mongodb
Restart=always
RestartSec=5
After=network.target

[Service]
Type=simple
Environment="MONGODB_URI=$MONGODB_URI"
ExecStart=/usr/local/bin/mongodb_exporter --mongodb.uri=$MONGODB_URI --collect-all
StandardOutput=journal
StandardError=journal
LimitNOFILE=4096  # Increase the limit on open file descriptors if necessary

[Install]
WantedBy=multi-user.target
EOF

    # Reload systemd to apply the new service
    echo "Reloading systemd..."
    sudo systemctl daemon-reload

    # Enable and start the MongoDB exporter service
    echo "Enabling and starting the MongoDB exporter service..."
    sudo systemctl enable mongodb_exporter
    sudo systemctl start mongodb_exporter
    # Check the service status
    echo "Checking the service status..."
    sudo systemctl restart mongodb_exporter
    sudo systemctl status mongodb_exporter
}
main() {
    check_mongodb_installation #checking the mongodb is found or not
    go_installation          #for building binary
    build_mongodb_exporter   #cloning the mongodb exporter latest code
    create_mongo_user        #creating the user for mongodb monitoring usign the clustermonitor role
    move_exporter            #move the binary to the /usr/local/bin
    create_service_file      #create the service file
}
main
