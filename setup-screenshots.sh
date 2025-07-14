#!/bin/bash

# Advanced Screenshot System Setup for BSPWM
# This script sets up a comprehensive screenshot system with clipboard integration

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_status "Setting up advanced screenshot system..."

# Install required packages
print_status "Installing screenshot dependencies..."
sudo apt update
sudo apt install -y scrot xclip maim slop dunst libnotify-bin

# Create screenshots directory
mkdir -p ~/Pictures/screenshots

# Create main screenshot script
print_status "Creating screenshot script..."
cat > ~/.local/bin/screenshot.sh << 'EOF'
#!/bin/bash

# Advanced Screenshot Script with multiple modes
# Usage: screenshot.sh [mode]
# Modes: selection, fullscreen, window, delay

SCREENSHOT_DIR="$HOME/Pictures/screenshots"
TEMP_FILE="/tmp/screenshot_temp.png"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Ensure screenshot directory exists
mkdir -p "$SCREENSHOT_DIR"

# Function to copy to clipboard and save file
process_screenshot() {
    local filename="$1"
    local mode="$2"
    
    if [[ -f "$TEMP_FILE" ]]; then
        # Copy to clipboard
        xclip -selection clipboard -t image/png -i "$TEMP_FILE"
        
        # Move to final location
        mv "$TEMP_FILE" "$filename"
        
        # Show notification
        notify-send -i "$filename" "Screenshot Saved" "$mode screenshot saved to $(basename "$filename")\nCopied to clipboard" -t 3000
        
        # Optional: Play sound (if available)
        # paplay /usr/share/sounds/alsa/Front_Right.wav 2>/dev/null &
        
        echo "Screenshot saved: $filename"
    else
        notify-send "Screenshot Failed" "No screenshot was taken" -t 3000
        echo "Screenshot failed or cancelled"
        exit 1
    fi
}

# Function for selection screenshot
selection_screenshot() {
    echo "Click and drag to select area for screenshot..."
    
    # Use maim with slop for better selection
    if command -v maim &> /dev/null && command -v slop &> /dev/null; then
        maim -s -u "$TEMP_FILE" 2>/dev/null
    else
        # Fallback to scrot
        scrot -s "$TEMP_FILE" 2>/dev/null
    fi
    
    local filename="$SCREENSHOT_DIR/selection_$TIMESTAMP.png"
    process_screenshot "$filename" "Selection"
}

# Function for fullscreen screenshot
fullscreen_screenshot() {
    echo "Taking fullscreen screenshot..."
    
    if command -v maim &> /dev/null; then
        maim -u "$TEMP_FILE"
    else
        scrot "$TEMP_FILE"
    fi
    
    local filename="$SCREENSHOT_DIR/fullscreen_$TIMESTAMP.png"
    process_screenshot "$filename" "Fullscreen"
}

# Function for active window screenshot
window_screenshot() {
    echo "Taking active window screenshot..."
    
    if command -v maim &> /dev/null; then
        maim -u -i $(xdotool getactivewindow) "$TEMP_FILE"
    else
        scrot -u "$TEMP_FILE"
    fi
    
    local filename="$SCREENSHOT_DIR/window_$TIMESTAMP.png"
    process_screenshot "$filename" "Window"
}

# Function for delayed screenshot
delay_screenshot() {
    local delay=${1:-3}
    echo "Taking screenshot in $delay seconds..."
    
    notify-send "Screenshot Countdown" "Screenshot in $delay seconds..." -t $((delay * 1000))
    sleep "$delay"
    
    if command -v maim &> /dev/null; then
        maim -u "$TEMP_FILE"
    else
        scrot "$TEMP_FILE"
    fi
    
    local filename="$SCREENSHOT_DIR/delayed_$TIMESTAMP.png"
    process_screenshot "$filename" "Delayed"
}

# Function to show screenshot menu
show_menu() {
    choice=$(echo -e "Selection\nFullscreen\nWindow\nDelay 3s\nDelay 5s\nCancel" | rofi -dmenu -p "Screenshot Mode" -i -lines 6)
    
    case "$choice" in
        "Selection")
            selection_screenshot
            ;;
        "Fullscreen")
            fullscreen_screenshot
            ;;
        "Window")
            window_screenshot
            ;;
        "Delay 3s")
            delay_screenshot 3
            ;;
        "Delay 5s")
            delay_screenshot 5
            ;;
        "Cancel"|"")
            echo "Screenshot cancelled"
            exit 0
            ;;
    esac
}

# Main logic
case "${1:-selection}" in
    "selection"|"s")
        selection_screenshot
        ;;
    "fullscreen"|"f")
        fullscreen_screenshot
        ;;
    "window"|"w")
        window_screenshot
        ;;
    "delay")
        delay_screenshot "${2:-3}"
        ;;
    "menu"|"m")
        show_menu
        ;;
    *)
        echo "Usage: $0 [selection|fullscreen|window|delay|menu]"
        echo "Default: selection"
        exit 1
        ;;
esac
EOF

# Make screenshot script executable
chmod +x ~/.local/bin/screenshot.sh

# Create additional utility scripts
print_status "Creating utility scripts..."

# Quick screenshot script for selection
cat > ~/.local/bin/quick-screenshot << 'EOF'
#!/bin/bash
~/.local/bin/screenshot.sh selection
EOF
chmod +x ~/.local/bin/quick-screenshot

# Screenshot menu script
cat > ~/.local/bin/screenshot-menu << 'EOF'
#!/bin/bash
~/.local/bin/screenshot.sh menu
EOF
chmod +x ~/.local/bin/screenshot-menu

# Create improved sxhkd configuration for screenshots
print_status "Creating enhanced screenshot keybindings..."
cat > /tmp/screenshot_keybindings.txt << 'EOF'
# Screenshot keybindings - Add these to your ~/.config/sxhkd/sxhkdrc

# Selection screenshot (Print Screen)
Print
    ~/.local/bin/screenshot.sh selection

# Fullscreen screenshot (Shift + Print Screen)
shift + Print
    ~/.local/bin/screenshot.sh fullscreen

# Window screenshot (Alt + Print Screen)
alt + Print
    ~/.local/bin/screenshot.sh window

# Delayed screenshot (Ctrl + Print Screen)
ctrl + Print
    ~/.local/bin/screenshot.sh delay 3

# Screenshot menu (Super + Print Screen)
super + Print
    ~/.local/bin/screenshot.sh menu

# Quick screenshot with selection (Super + Shift + s)
super + shift + s
    ~/.local/bin/screenshot.sh selection

# Copy last screenshot to clipboard (Super + Shift + c)
super + shift + c
    find ~/Pictures/screenshots -name "*.png" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2- | xargs -I {} xclip -selection clipboard -t image/png -i "{}"
EOF

# Backup current sxhkd config and add screenshot bindings
print_status "Updating sxhkd configuration..."
if [[ -f ~/.config/sxhkd/sxhkdrc ]]; then
    cp ~/.config/sxhkd/sxhkdrc ~/.config/sxhkd/sxhkdrc.backup
    echo "" >> ~/.config/sxhkd/sxhkdrc
    echo "# Screenshot keybindings" >> ~/.config/sxhkd/sxhkdrc
    cat /tmp/screenshot_keybindings.txt | grep -v "^#" | grep -v "^$" >> ~/.config/sxhkd/sxhkdrc
fi

# Create a desktop entry for screenshot tool
print_status "Creating desktop entry..."
cat > ~/.local/share/applications/screenshot.desktop << 'EOF'
[Desktop Entry]
Name=Screenshot Tool
Comment=Take screenshots with various modes
Exec=/home/$USER/.local/bin/screenshot.sh menu
Icon=applets-screenshooter
Type=Application
Categories=Graphics;Photography;
Keywords=screenshot;capture;image;
EOF

# Create a simple screenshot manager script
print_status "Creating screenshot manager..."
cat > ~/.local/bin/screenshot-manager << 'EOF'
#!/bin/bash

# Screenshot Manager - View and manage screenshots

SCREENSHOT_DIR="$HOME/Pictures/screenshots"

if ! command -v feh &> /dev/null; then
    echo "Installing feh for image viewing..."
    sudo apt install -y feh
fi

case "${1:-view}" in
    "view"|"v")
        # View screenshots in feh
        cd "$SCREENSHOT_DIR"
        feh --sort mtime --reverse --scale-down --auto-zoom --borderless --geometry 800x600 *.png 2>/dev/null || echo "No screenshots found"
        ;;
    "clean"|"c")
        # Clean old screenshots (older than 30 days)
        find "$SCREENSHOT_DIR" -name "*.png" -type f -mtime +30 -delete
        echo "Cleaned old screenshots"
        ;;
    "recent"|"r")
        # Show recent screenshots
        ls -lt "$SCREENSHOT_DIR"/*.png 2>/dev/null | head -10
        ;;
    "open"|"o")
        # Open screenshots directory
        if command -v thunar &> /dev/null; then
            thunar "$SCREENSHOT_DIR"
        else
            xdg-open "$SCREENSHOT_DIR"
        fi
        ;;
    *)
        echo "Usage: $0 [view|clean|recent|open]"
        echo "  view   - View screenshots in image viewer"
        echo "  clean  - Remove screenshots older than 30 days"
        echo "  recent - List recent screenshots"
        echo "  open   - Open screenshots directory"
        ;;
esac
EOF
chmod +x ~/.local/bin/screenshot-manager

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    print_warning "Added ~/.local/bin to PATH. Please restart your terminal or run: source ~/.bashrc"
fi

# Reload sxhkd configuration
print_status "Reloading sxhkd configuration..."
pkill -USR1 -x sxhkd 2>/dev/null || true

print_status "Screenshot system setup complete!"
echo ""
echo "Available screenshot modes:"
echo "  Print Screen                 - Selection screenshot"
echo "  Shift + Print Screen         - Fullscreen screenshot"
echo "  Alt + Print Screen           - Window screenshot"
echo "  Ctrl + Print Screen          - Delayed screenshot (3s)"
echo "  Super + Print Screen         - Screenshot menu"
echo "  Super + Shift + s            - Quick selection screenshot"
echo "  Super + Shift + c            - Copy last screenshot to clipboard"
echo ""
echo "Additional commands:"
echo "  screenshot-manager view      - View all screenshots"
echo "  screenshot-manager clean     - Clean old screenshots"
echo "  screenshot-manager recent    - List recent screenshots"
echo "  screenshot-manager open      - Open screenshots folder"
echo ""
echo "Screenshots are saved to: ~/Pictures/screenshots/"
echo "All screenshots are automatically copied to clipboard!"
