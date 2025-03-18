#!/bin/bash
set -e
check_and_install_grafana() {
    # Check if Grafana is installed
    if which grafana-server > /dev/null 2>&1; then
        echo "Grafana is already installed."
    else
        echo "Grafana is not installed. Installing now..."

        # Install required dependencies
        echo "Installing dependencies..."
        sudo apt-get update
        sudo apt-get install -y adduser libfontconfig1 musl

        # Download Grafana package
        echo "Downloading Grafana package..."
        wget https://dl.grafana.com/enterprise/release/grafana-enterprise_11.3.1_amd64.deb

        # Install Grafana
        echo "Installing Grafana..."
        sudo dpkg -i grafana-enterprise_11.3.1_amd64.deb
        sudo systemctl enable grafana-server
        sudo systemctl start grafana-server
        sudo systemctl status grafana-server

        # Check if installation succeeded
        if which grafana-server > /dev/null 2>&1; then
            echo "Grafana installed successfully."
        else
            echo "Failed to install Grafana."
            exit 1
        fi
    fi
}

# Call the function
check_and_install_grafana
