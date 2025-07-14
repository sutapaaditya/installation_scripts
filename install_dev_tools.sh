#!/bin/bash

# This script installs the latest Node.js LTS, npm, and Angular CLI v17.

echo "--- Starting the installation of development tools ---"

# --- 1. Update system packages ---
echo "Updating package lists..."
sudo apt-get update
sudo apt-get install -y curl # Ensure curl is installed

# --- 2. Add NodeSource repository and install Node.js LTS ---
# This setup script adds the repository for the latest Node.js LTS version (currently v20).
echo "Adding NodeSource repository for Node.js LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# --- 3. Install Node.js and npm ---
# Installing the 'nodejs' package from the NodeSource repo will get you
# both Node.js and npm.
echo "Installing Node.js and npm..."
sudo apt-get install -y nodejs

# --- 4. Install Angular CLI version 17 ---
echo "Installing Angular CLI version 17..."
# We use sudo for a global (-g) installation.
sudo npm install -g @angular/cli@17

# --- 5. Verification ---
echo "--- Installation Complete ---"
echo "Verifying the installed versions:"
echo "Node.js version:"
node -v
echo "npm version:"
npm -v
echo "Angular CLI version:"
ng version

echo "--- Setup finished successfully! ---"
