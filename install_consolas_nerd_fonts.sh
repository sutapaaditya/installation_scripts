#!/bin/bash

# A script to download and install Consolas Nerd Fonts from a specific GitHub repository.

# --- Configuration ---
# GitHub repository details from your screenshot.
GITHUB_USER="barungh"
REPO_NAME="my-nerd-fonts"
# The directory path on GitHub. Spaces must be URL-encoded (e.g., ' ' becomes '%20').
FONT_DIR="Consolas%20NF"
BRANCH="master"

# List of font files to install, based on your screenshot.
FONT_FILES=(
    "Consolas Bold Italic Nerd Font Complete Mono Windows Compatible.ttf"
    "Consolas Bold Nerd Font Complete Mono Windows Compatible.ttf"
    "Consolas Italic Nerd Font Complete Mono Windows Compatible.ttf"
    "Consolas Nerd Font Complete Mono Windows Compatible.ttf"
)

# The local directory to install fonts into for the current user.
# This is the standard location and doesn't require root privileges.
INSTALL_DIR="${HOME}/.local/share/fonts"

# --- Script Logic ---

# Create the font installation directory if it doesn't already exist.
echo "Ensuring font directory exists: ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"

# Loop through each font file, download it, and place it in the installation directory.
for font_file in "${FONT_FILES[@]}"; do
    # URL-encode spaces in the font filename for the download URL.
    font_file_encoded="${font_file// /%20}"
    
    # Construct the full raw download URL for the font file.
    font_url="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO_NAME}/${BRANCH}/${FONT_DIR}/${font_file_encoded}"
    
    # Define the final destination path for the font file on the local machine.
    dest_path="${INSTALL_DIR}/${font_file}"

    echo "Downloading: ${font_file}"
    
    # Use curl to download the font file.
    # -f: Fail silently on server errors (so we can check the exit code).
    # -L: Follow any redirects.
    # -o: Specify the output file.
    curl -fLo "${dest_path}" "${font_url}"

    # Check if the download was successful.
    if [ $? -eq 0 ]; then
        echo " -> Successfully installed to ${dest_path}"
    else
        echo " -> ERROR: Failed to download ${font_file}."
        echo "    Please check the repository path and filename."
        # Exit the script if any download fails.
        exit 1
    fi
done

# After installing the fonts, update the system's font cache.
# -f: Force rebuild.
# -v: Verbose output.
echo "Updating font cache... (This may take a moment)"
fc-cache -f -v

echo ""
echo "✅ Consolas Nerd Fonts installation complete."
echo "You may need to restart your terminal or applications to see the new fonts."
