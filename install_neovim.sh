#!/bin/bash

# A script to compile and install Neovim from source.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
NVIM_VERSION="v0.11.0" # The version of Neovim to install

# --- Dependencies ---
echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y ninja-build gettext cmake unzip curl build-essential

# --- Cloning Neovim ---
echo "Cloning Neovim repository..."
if [ -d "neovim" ]; then
    echo "'neovim' directory already exists. Removing it."
    rm -rf neovim
fi

git clone https://github.com/neovim/neovim.git
cd neovim

# --- Building Neovim ---
echo "Checking out version ${NVIM_VERSION} and building..."
git checkout "${NVIM_VERSION}"

make CMAKE_BUILD_TYPE=Release

# --- Installing Neovim ---
echo "Installing Neovim..."
sudo make install

# --- Cleanup ---
echo "Cleaning up..."
cd ..
rm -rf neovim

echo "Neovim ${NVIM_VERSION} installation complete!"
