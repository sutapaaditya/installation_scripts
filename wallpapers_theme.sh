#!/bin/bash

# Triple Monitor Wallpaper & Theme Setup Script for Ubuntu MATE
# This script downloads cool wallpapers, sets them for each monitor, and installs themes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for wallpaper settings"
   exit 1
fi

# Create directories
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THEME_DIR="$HOME/.themes"
ICON_DIR="$HOME/.icons"

mkdir -p "$WALLPAPER_DIR"
mkdir -p "$THEME_DIR"
mkdir -p "$ICON_DIR"

print_status "Created directories for wallpapers, themes, and icons"

# Install required packages
print_status "Installing required packages..."
sudo apt update
sudo apt install -y wget curl unzip git nitrogen feh imagemagick

# Function to download wallpaper
download_wallpaper() {
    local url="$1"
    local filename="$2"
    local description="$3"
    
    print_status "Downloading $description..."
    if wget -q -O "$WALLPAPER_DIR/$filename" "$url"; then
        print_status "Successfully downloaded $filename"
    else
        print_warning "Failed to download $filename"
    fi
}

# Download high-quality wallpapers for each monitor
print_status "Downloading wallpapers for triple monitor setup..."

# Monitor 1 (VGA-0) - Left monitor - Nature/Landscape
download_wallpaper "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1920&q=80" "monitor1_nature.jpg" "Nature landscape for left monitor"

# Monitor 2 (DVI-D-0) - Center monitor - Space/Abstract
download_wallpaper "https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1920&q=80" "monitor2_space.jpg" "Space theme for center monitor"

# Monitor 3 (HDMI-0) - Right monitor - Cyberpunk/Tech
download_wallpaper "https://images.unsplash.com/photo-1518709268805-4e9042af2176?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1920&q=80" "monitor3_tech.jpg" "Tech theme for right monitor"

# Alternative wallpapers (solid colors as backup)
print_status "Creating backup solid color wallpapers..."
convert -size 1920x1080 xc:"#2E3440" "$WALLPAPER_DIR/dark_blue.png"
convert -size 1920x1080 xc:"#3B4252" "$WALLPAPER_DIR/dark_gray.png"
convert -size 1920x1080 xc:"#434C5E" "$WALLPAPER_DIR/slate_gray.png"

# Download and install themes
print_status "Installing themes..."

# Install Papirus Icon Theme
print_status "Installing Papirus icon theme..."
sudo add-apt-repository ppa:papirus/papirus -y
sudo apt update
sudo apt install -y papirus-icon-theme

# Install Arc Theme
print_status "Installing Arc theme..."
sudo apt install -y arc-theme

# Install Numix Theme
print_status "Installing Numix theme..."
sudo apt install -y numix-gtk-theme numix-icon-theme

# Download additional cool themes
print_status "Downloading additional themes..."

# Download Orchis Theme
cd /tmp
if git clone https://github.com/vinceliuice/Orchis-theme.git; then
    cd Orchis-theme
    ./install.sh -d "$THEME_DIR"
    cd ..
    rm -rf Orchis-theme
    print_status "Orchis theme installed"
else
    print_warning "Failed to download Orchis theme"
fi

# Download Tela Icon Theme
cd /tmp
if git clone https://github.com/vinceliuice/Tela-icon-theme.git; then
    cd Tela-icon-theme
    ./install.sh -d "$ICON_DIR"
    cd ..
    rm -rf Tela-icon-theme
    print_status "Tela icon theme installed"
else
    print_warning "Failed to download Tela icon theme"
fi

# Function to set wallpaper for specific monitor
set_monitor_wallpaper() {
    local monitor="$1"
    local wallpaper="$2"
    
    print_status "Setting wallpaper for $monitor"
    
    # Create nitrogen config if it doesn't exist
    mkdir -p "$HOME/.config/nitrogen"
    
    # Use feh as backup method
    if command -v feh > /dev/null; then
        case $monitor in
            "VGA-0")
                feh --bg-fill "$wallpaper" --geometry 1920x1080+0+0
                ;;
            "DVI-D-0")
                feh --bg-fill "$wallpaper" --geometry 1920x1080+1920+0
                ;;
            "HDMI-0")
                feh --bg-fill "$wallpaper" --geometry 1920x1080+3840+0
                ;;
        esac
    fi
}

# Set wallpapers for each monitor
print_status "Setting wallpapers for each monitor..."

# Check if wallpapers were downloaded successfully, use backups if not
if [[ -f "$WALLPAPER_DIR/monitor1_nature.jpg" ]]; then
    set_monitor_wallpaper "VGA-0" "$WALLPAPER_DIR/monitor1_nature.jpg"
else
    set_monitor_wallpaper "VGA-0" "$WALLPAPER_DIR/dark_blue.png"
fi

if [[ -f "$WALLPAPER_DIR/monitor2_space.jpg" ]]; then
    set_monitor_wallpaper "DVI-D-0" "$WALLPAPER_DIR/monitor2_space.jpg"
else
    set_monitor_wallpaper "DVI-D-0" "$WALLPAPER_DIR/dark_gray.png"
fi

if [[ -f "$WALLPAPER_DIR/monitor3_tech.jpg" ]]; then
    set_monitor_wallpaper "HDMI-0" "$WALLPAPER_DIR/monitor3_tech.jpg"
else
    set_monitor_wallpaper "HDMI-0" "$WALLPAPER_DIR/slate_gray.png"
fi

# Apply theme settings
print_status "Applying theme settings..."

# Set GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "Arc-Dark"
gsettings set org.gnome.desktop.wm.preferences theme "Arc-Dark"

# Set icon theme
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"

# Set cursor theme
gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"

# MATE specific settings
if command -v mate-appearance-properties > /dev/null; then
    # Set MATE theme
    gsettings set org.mate.interface gtk-theme "Arc-Dark"
    gsettings set org.mate.interface icon-theme "Papirus-Dark"
    gsettings set org.mate.Marco.general theme "Arc-Dark"
fi

# Create autostart entry for wallpaper restoration
print_status "Creating autostart entry for wallpaper restoration..."
mkdir -p "$HOME/.config/autostart"

cat > "$HOME/.config/autostart/wallpaper-restore.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Wallpaper Restore
Comment=Restore wallpapers for multiple monitors
Exec=sh -c 'sleep 5 && feh --bg-fill "$WALLPAPER_DIR/monitor1_nature.jpg" --bg-fill "$WALLPAPER_DIR/monitor2_space.jpg" --bg-fill "$WALLPAPER_DIR/monitor3_tech.jpg"'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Create a script for manual wallpaper switching
print_status "Creating wallpaper switching script..."
cat > "$HOME/bin/switch-wallpapers.sh" << 'EOF'
#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# Function to set random wallpaper
set_random_wallpaper() {
    local monitor="$1"
    local wallpapers=("$WALLPAPER_DIR"/*.jpg "$WALLPAPER_DIR"/*.png)
    local random_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"
    
    echo "Setting $random_wallpaper for $monitor"
    
    case $monitor in
        "left"|"VGA-0")
            feh --bg-fill "$random_wallpaper" --geometry 1920x1080+0+0
            ;;
        "center"|"DVI-D-0")
            feh --bg-fill "$random_wallpaper" --geometry 1920x1080+1920+0
            ;;
        "right"|"HDMI-0")
            feh --bg-fill "$random_wallpaper" --geometry 1920x1080+3840+0
            ;;
        "all")
            feh --bg-fill "$random_wallpaper"
            ;;
    esac
}

# Parse command line arguments
case "$1" in
    "left"|"center"|"right"|"all")
        set_random_wallpaper "$1"
        ;;
    *)
        echo "Usage: $0 [left|center|right|all]"
        echo "Sets random wallpaper for specified monitor(s)"
        ;;
esac
EOF

mkdir -p "$HOME/bin"
chmod +x "$HOME/bin/switch-wallpapers.sh"

# Create desktop shortcut for theme switching
print_status "Creating desktop shortcuts..."
cat > "$HOME/Desktop/Switch-Themes.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Switch Themes
Comment=Switch between installed themes
Exec=mate-appearance-properties
Icon=preferences-desktop-theme
Terminal=false
Categories=Settings;
EOF

chmod +x "$HOME/Desktop/Switch-Themes.desktop"

# Summary
print_status "Setup complete!"
echo
echo -e "${BLUE}=== SUMMARY ===${NC}"
echo -e "${GREEN}✓${NC} Wallpapers downloaded to: $WALLPAPER_DIR"
echo -e "${GREEN}✓${NC} Themes installed: Arc, Numix, Orchis"
echo -e "${GREEN}✓${NC} Icons installed: Papirus, Numix, Tela"
echo -e "${GREEN}✓${NC} Wallpapers set for each monitor"
echo -e "${GREEN}✓${NC} Autostart entry created for wallpaper restoration"
echo -e "${GREEN}✓${NC} Manual wallpaper switching script created"
echo
echo -e "${BLUE}Usage:${NC}"
echo "• Run 'nitrogen' to manage wallpapers with GUI"
echo "• Run '~/bin/switch-wallpapers.sh left' to set random wallpaper on left monitor"
echo "• Use 'mate-appearance-properties' to change themes"
echo "• Wallpapers will be restored automatically on login"
echo
echo -e "${YELLOW}Note:${NC} You may need to log out and log back in for all theme changes to take effect."
echo
print_status "Enjoy your new multi-monitor setup!"
