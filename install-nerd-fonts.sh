#!/bin/bash

# Nerd Fonts Installer for WSL Ubuntu
# This script downloads and installs popular Nerd Fonts for development

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
FONTS_DIR="$HOME/.local/share/fonts"
TEMP_DIR="/tmp/nerd-fonts"
NERD_FONTS_VERSION="v3.1.1"
NERD_FONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download"

# Popular Nerd Fonts to install
declare -A FONTS=(
    ["FiraCode"]="FiraCode.zip"
    ["JetBrainsMono"]="JetBrainsMono.zip"
    ["Hack"]="Hack.zip"
    ["SourceCodePro"]="SourceCodePro.zip"
    ["UbuntuMono"]="UbuntuMono.zip"
    ["DejaVuSansMono"]="DejaVuSansMono.zip"
    ["Meslo"]="Meslo.zip"
    ["RobotoMono"]="RobotoMono.zip"
    ["CascadiaCode"]="CascadiaCode.zip"
    ["Inconsolata"]="Inconsolata.zip"
)

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install required packages
install_dependencies() {
    print_header "Installing dependencies..."
    
    # Check if we need to install anything
    local packages_to_install=()
    
    if ! command_exists curl; then
        packages_to_install+=("curl")
    fi
    
    if ! command_exists unzip; then
        packages_to_install+=("unzip")
    fi
    
    if ! command_exists fc-cache; then
        packages_to_install+=("fontconfig")
    fi
    
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_status "Installing required packages: ${packages_to_install[*]}"
        sudo apt update -qq
        sudo apt install -y "${packages_to_install[@]}"
    else
        print_status "All dependencies are already installed"
    fi
}

# Create fonts directory
setup_fonts_directory() {
    print_header "Setting up fonts directory..."
    
    if [ ! -d "$FONTS_DIR" ]; then
        mkdir -p "$FONTS_DIR"
        print_status "Created fonts directory: $FONTS_DIR"
    else
        print_status "Fonts directory already exists: $FONTS_DIR"
    fi
    
    # Create temp directory
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    mkdir -p "$TEMP_DIR"
    print_status "Created temporary directory: $TEMP_DIR"
}

# Download and install a font
install_font() {
    local font_name="$1"
    local font_file="$2"
    local font_url="${NERD_FONTS_BASE_URL}/${NERD_FONTS_VERSION}/${font_file}"
    
    print_status "Installing ${font_name}..."
    
    # Download font
    local temp_file="${TEMP_DIR}/${font_file}"
    if curl -sL -o "$temp_file" "$font_url"; then
        print_status "Downloaded ${font_name}"
    else
        print_error "Failed to download ${font_name}"
        return 1
    fi
    
    # Extract font
    local extract_dir="${TEMP_DIR}/${font_name}"
    mkdir -p "$extract_dir"
    
    if unzip -q "$temp_file" -d "$extract_dir"; then
        print_status "Extracted ${font_name}"
    else
        print_error "Failed to extract ${font_name}"
        return 1
    fi
    
    # Install font files
    local installed_count=0
    while IFS= read -r -d '' font_file; do
        if [[ "$font_file" =~ \.(ttf|otf)$ ]]; then
            cp "$font_file" "$FONTS_DIR/"
            ((installed_count++))
        fi
    done < <(find "$extract_dir" -type f -print0)
    
    if [ $installed_count -gt 0 ]; then
        print_success "Installed ${font_name} (${installed_count} font files)"
    else
        print_warning "No font files found for ${font_name}"
    fi
    
    # Clean up
    rm -f "$temp_file"
    rm -rf "$extract_dir"
}

# Show available fonts
show_available_fonts() {
    print_header "Available Nerd Fonts:"
    echo
    local counter=1
    for font_name in "${!FONTS[@]}"; do
        printf "%2d. %-20s\n" $counter "$font_name"
        ((counter++))
    done
    echo
    printf "%2d. %-20s\n" $counter "All fonts"
    echo
}

# Install selected fonts
install_selected_fonts() {
    local selections=("$@")
    local total_fonts=${#FONTS[@]}
    
    if [[ " ${selections[*]} " =~ " $((total_fonts + 1)) " ]]; then
        # Install all fonts
        print_header "Installing all Nerd Fonts..."
        for font_name in "${!FONTS[@]}"; do
            install_font "$font_name" "${FONTS[$font_name]}"
        done
    else
        # Install selected fonts
        local font_names=($(printf '%s\n' "${!FONTS[@]}" | sort))
        for selection in "${selections[@]}"; do
            if [ "$selection" -ge 1 ] && [ "$selection" -le "$total_fonts" ]; then
                local font_name="${font_names[$((selection - 1))]}"
                install_font "$font_name" "${FONTS[$font_name]}"
            else
                print_warning "Invalid selection: $selection"
            fi
        done
    fi
}

# Update font cache
update_font_cache() {
    print_header "Updating font cache..."
    if fc-cache -fv >/dev/null 2>&1; then
        print_success "Font cache updated successfully"
    else
        print_warning "Failed to update font cache, but fonts should still work"
    fi
}

# List installed Nerd Fonts
list_installed_fonts() {
    print_header "Installed Nerd Fonts:"
    echo
    
    # Use fc-list to find Nerd Fonts
    if command_exists fc-list; then
        local nerd_fonts=$(fc-list | grep -i "nerd\|nf-" | cut -d: -f2 | sort -u)
        if [ -n "$nerd_fonts" ]; then
            echo "$nerd_fonts"
        else
            print_status "No Nerd Fonts detected by fc-list yet. Try restarting your terminal."
        fi
    else
        print_status "Listing fonts in $FONTS_DIR:"
        find "$FONTS_DIR" -name "*Nerd*" -o -name "*NF*" | sort
    fi
    echo
}

# Show usage instructions
show_usage_instructions() {
    print_header "How to use your new Nerd Fonts:"
    echo
    echo "1. ${CYAN}For WSL Terminal:${NC}"
    echo "   - Open Windows Terminal"
    echo "   - Go to Settings (Ctrl+,)"
    echo "   - Select your WSL profile"
    echo "   - Under 'Appearance', change the font face to a Nerd Font"
    echo "   - Recommended: 'FiraCode Nerd Font', 'JetBrainsMono Nerd Font'"
    echo
    echo "2. ${CYAN}For VS Code:${NC}"
    echo "   - Open VS Code settings (Ctrl+,)"
    echo "   - Search for 'terminal font'"
    echo "   - Set 'Terminal › Integrated: Font Family' to a Nerd Font"
    echo "   - Example: 'FiraCode Nerd Font', 'JetBrainsMono Nerd Font'"
    echo
    echo "3. ${CYAN}For other terminals:${NC}"
    echo "   - Look for font settings in your terminal preferences"
    echo "   - Select any font with 'Nerd Font' in the name"
    echo
    echo "4. ${CYAN}Test your fonts:${NC}"
    echo "   - Install a tool like 'neofetch' or 'exa' to see icons"
    echo "   - Try: echo '   '"
    echo
}

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        print_status "Cleaned up temporary files"
    fi
}

# Main interactive menu
interactive_install() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                    Nerd Fonts Installer                     ║${NC}"
    echo -e "${PURPLE}║                      for WSL Ubuntu                         ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    show_available_fonts
    
    echo -e "${CYAN}Enter your choices (space-separated numbers, e.g., '1 3 5'):${NC}"
    echo -e "${CYAN}Or press Enter for recommended fonts (FiraCode, JetBrainsMono, Hack):${NC}"
    read -r user_input
    
    local selections=()
    if [ -z "$user_input" ]; then
        # Default selection: FiraCode, JetBrainsMono, Hack
        local font_names=($(printf '%s\n' "${!FONTS[@]}" | sort))
        for i in "${!font_names[@]}"; do
            if [[ "${font_names[$i]}" =~ ^(FiraCode|JetBrainsMono|Hack)$ ]]; then
                selections+=($((i + 1)))
            fi
        done
    else
        read -ra selections <<< "$user_input"
    fi
    
    return 0
}

# Main function
main() {
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Check if running on Ubuntu/Debian
    if ! command_exists apt; then
        print_error "This script is designed for Ubuntu/Debian systems with apt package manager"
        exit 1
    fi
    
    # Handle command line arguments
    if [ $# -eq 0 ]; then
        # Interactive mode
        interactive_install
        local selections=()
        if [ -z "$user_input" ]; then
            # Default selection
            local font_names=($(printf '%s\n' "${!FONTS[@]}" | sort))
            for i in "${!font_names[@]}"; do
                if [[ "${font_names[$i]}" =~ ^(FiraCode|JetBrainsMono|Hack)$ ]]; then
                    selections+=($((i + 1)))
                fi
            done
        else
            read -ra selections <<< "$user_input"
        fi
    elif [ "$1" = "--all" ]; then
        # Install all fonts
        local total_fonts=${#FONTS[@]}
        selections=($((total_fonts + 1)))
    elif [ "$1" = "--list" ]; then
        # List available fonts and exit
        show_available_fonts
        exit 0
    elif [ "$1" = "--installed" ]; then
        # List installed fonts and exit
        list_installed_fonts
        exit 0
    else
        # Install specific fonts by number
        selections=("$@")
    fi
    
    # Install dependencies
    install_dependencies
    
    # Setup fonts directory
    setup_fonts_directory
    
    # Install fonts
    install_selected_fonts "${selections[@]}"
    
    # Update font cache
    update_font_cache
    
    # List installed fonts
    list_installed_fonts
    
    # Show usage instructions
    show_usage_instructions
    
    print_success "Nerd Fonts installation completed!"
    print_status "Restart your terminal or VS Code to use the new fonts."
}

# Show help
show_help() {
    echo "Nerd Fonts Installer for WSL Ubuntu"
    echo
    echo "Usage:"
    echo "  $0                    # Interactive mode"
    echo "  $0 --all              # Install all fonts"
    echo "  $0 --list             # List available fonts"
    echo "  $0 --installed        # List installed fonts"
    echo "  $0 1 3 5              # Install specific fonts by number"
    echo "  $0 --help             # Show this help"
    echo
    echo "Examples:"
    echo "  $0                    # Interactive selection"
    echo "  $0 1 2 3              # Install first 3 fonts"
    echo "  $0 --all              # Install everything"
    echo
}

# Check for help flag
if [ $# -eq 1 ] && [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
