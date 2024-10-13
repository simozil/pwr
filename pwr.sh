#!/bin/bash

# Function to check if a command exists
exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to log messages with color
log() {
  local type="$1"
  local message="$2"
  local color

  case "$type" in
    info) color="\033[0;34m" ;;
    success) color="\033[0;32m" ;;
    error) color="\033[0;31m" ;;
    *) color="\033[0m" ;;
  esac

  echo -e "${color}${message}\033[0m"
}

# Update and upgrade system
log "info" "Updating and upgrading system..."
sudo apt update && sudo apt upgrade -y

# Install necessary packages if they don't exist
for pkg in curl wget ufw; do
  if ! exists $pkg; then
    log "error" "$pkg not found. Installing..."
    sudo apt install -y $pkg
  else
    log "success" "$pkg is already installed."
  fi
done

# Clear screen
clear

log "info" "Run and Install Start..."
sleep 1
curl -s https://raw.githubusercontent.com/Winnode/winnode/main/Logo.sh | bash
sleep 5

# Get user input
log "info" "Please provide the following information:"
read -p "Enter your desired password: " PASSWORD
echo
read -p "Enter your server IP (e.g., 185.192.97.28): " SERVER_IP

# Configuring firewall
log "info" "Configuring firewall..."
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 8231/tcp
sudo ufw allow 8085/tcp
sudo ufw allow 7621/udp

# Create PWR directory and navigate into it
log "info" "Creating PWR directory and navigating into it..."
mkdir -p $HOME/PWR
cd $HOME/PWR

# Install Java and PWR Validator Node
log "info" "Installing PWR Chain Validator Node..."
sleep 5
sudo apt update
sudo apt install -y openjdk-19-jre-headless

# Download validator and config files
wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar
wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json

# Save password to a file
echo "$PASSWORD" | sudo tee password > /dev/null

# Create and enable systemd service
sudo tee /etc/systemd/system/pwr.service > /dev/null <<EOF
[Unit]
Description=PWR node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/PWR
ExecStart=java -jar validator.jar password $SERVER_IP --compression-level 0
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Reload and start service
sudo systemctl daemon-reload
sudo systemctl enable pwr.service
sudo systemctl start pwr.service

# Final success message
log "success" "PWR node setup complete and service started."

# Clean up script
rm -- "$0"
