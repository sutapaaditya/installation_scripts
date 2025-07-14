#!/bin/bash

# Theme and Icon Customization for BSPWM Setup

print_status() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

print_status "Setting up theme and icon customization..."

# Install theme and icon management tools
sudo apt update
sudo apt install -y \
    lxappearance qt5ct \
    papirus-icon-theme \
    arc-theme \
    numix-gtk-theme \
    numix-icon-theme \
    breeze-icon-theme \
    elementary-xfce-icon-theme \
    gtk2-engines-murrine \
    gtk2-engines-pixbuf \
    sassc \
    git

# Install popular icon themes
print_status "Installing popular icon themes..."

# Papirus Icon Theme (already installed above)
# Tela Icon Theme
cd /tmp
if [ ! -d ~/.local/share/icons/Tela ]; then
    git clone https://github.com/vinceliuice/Tela-icon-theme.git
    cd Tela-icon-theme
    ./install.sh
    cd ..
fi

# WhiteSur Icon Theme
if [ ! -d ~/.local/share/icons/WhiteSur ]; then
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
    cd WhiteSur-icon-theme
    ./install.sh
    cd ..
fi

# Fluent Icon Theme
if [ ! -d ~/.local/share/icons/Fluent ]; then
    git clone https://github.com/vinceliuice/Fluent-icon-theme.git
    cd Fluent-icon-theme
    ./install.sh
    cd ..
fi

# Install popular GTK themes
print_status "Installing GTK themes..."

# Dracula Theme (matches your current color scheme)
if [ ! -d ~/.local/share/themes/Dracula ]; then
    cd /tmp
    git clone https://github.com/dracula/gtk.git dracula-gtk
    mkdir -p ~/.local/share/themes
    cp -r dracula-gtk ~/.local/share/themes/Dracula
fi

# Nordic Theme
if [ ! -d ~/.local/share/themes/Nordic ]; then
    cd /tmp
    git clone https://github.com/EliverLara/Nordic.git
    cp -r Nordic ~/.local/share/themes/
fi

# Orchis Theme
if [ ! -d ~/.local/share/themes/Orchis ]; then
    cd /tmp
    git clone https://github.com/vinceliuice/Orchis-theme.git
    cd Orchis-theme
    ./install.sh
    cd ..
fi

# Ensure local bin directory exists
mkdir -p ~/.local/bin

# Create theme switcher script
print_status "Creating theme switcher..."

cat > ~/.local/bin/theme-switcher << 'THEME_SWITCHER_EOF'
#!/bin/bash

# Theme Switcher for BSPWM Setup

# Available themes and icons
GTK_THEMES=(
    "Dracula"
    "Nordic"
    "Orchis"
    "Arc"
    "Arc-Dark"
    "Numix"
    "Numix-Light"
)

ICON_THEMES=(
    "Papirus"
    "Papirus-Dark"
    "Tela"
    "Tela-dark"
    "WhiteSur"
    "WhiteSur-dark"
    "Fluent"
    "Fluent-dark"
    "elementary-xfce"
    "breeze"
    "Numix"
)

# BSPWM color schemes
declare -A BSPWM_COLORS
BSPWM_COLORS[dracula]="normal=#44475a active=#bd93f9 focused=#ff79c6 presel=#6272a4"
BSPWM_COLORS[nordic]="normal=#3b4252 active=#5e81ac focused=#88c0d0 presel=#434c5e"
BSPWM_COLORS[gruvbox]="normal=#3c3836 active=#fabd2f focused=#fb4934 presel=#665c54"
BSPWM_COLORS[onedark]="normal=#3e4451 active=#61afef focused=#e06c75 presel=#4b5263"
BSPWM_COLORS[catppuccin]="normal=#45475a active=#cba6f7 focused=#f38ba8 presel=#585b70"

# Polybar color schemes
declare -A POLYBAR_COLORS
POLYBAR_COLORS[dracula]="bg=#282a36 bg-alt=#44475a fg=#f8f8f2 primary=#bd93f9 secondary=#8be9fd alert=#ff5555"
POLYBAR_COLORS[nordic]="bg=#2e3440 bg-alt=#3b4252 fg=#eceff4 primary=#5e81ac secondary=#88c0d0 alert=#bf616a"
POLYBAR_COLORS[gruvbox]="bg=#282828 bg-alt=#3c3836 fg=#ebdbb2 primary=#fabd2f secondary=#83a598 alert=#fb4934"
POLYBAR_COLORS[onedark]="bg=#282c34 bg-alt=#3e4451 fg=#abb2bf primary=#61afef secondary=#56b6c2 alert=#e06c75"
POLYBAR_COLORS[catppuccin]="bg=#1e1e2e bg-alt=#45475a fg=#cdd6f4 primary=#cba6f7 secondary=#89b4fa alert=#f38ba8"

# Function to set GTK theme
set_gtk_theme() {
    local theme=$1
    local icon_theme=$2
    
    # Set theme using gsettings
    gsettings set org.gnome.desktop.interface gtk-theme "$theme"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
    
    # Create GTK 2.0 config
    cat > ~/.gtkrc-2.0 << GTK2_EOF
gtk-theme-name="$theme"
gtk-icon-theme-name="$icon_theme"
gtk-font-name="JetBrainsMono Nerd Font 10"
gtk-cursor-theme-name="breeze_cursors"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
gtk-xft-rgba="rgb"
GTK2_EOF

    # Create GTK 3.0 config
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini << GTK3_EOF
[Settings]
gtk-theme-name=$theme
gtk-icon-theme-name=$icon_theme
gtk-font-name=JetBrainsMono Nerd Font 10
gtk-cursor-theme-name=breeze_cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
GTK3_EOF
}

# Function to set BSPWM colors
set_bspwm_colors() {
    local color_scheme=$1
    local colors=${BSPWM_COLORS[$color_scheme]}
    
    if [ -n "$colors" ]; then
        # Parse colors
        local normal=$(echo $colors | grep -o 'normal=[^[:space:]]*' | cut -d= -f2)
        local active=$(echo $colors | grep -o 'active=[^[:space:]]*' | cut -d= -f2)
        local focused=$(echo $colors | grep -o 'focused=[^[:space:]]*' | cut -d= -f2)
        local presel=$(echo $colors | grep -o 'presel=[^[:space:]]*' | cut -d= -f2)
        
        # Apply colors
        bspc config normal_border_color "$normal"
        bspc config active_border_color "$active"
        bspc config focused_border_color "$focused"
        bspc config presel_feedback_color "$presel"
    fi
}

# Function to update polybar colors
update_polybar_colors() {
    local color_scheme=$1
    local colors=${POLYBAR_COLORS[$color_scheme]}
    
    if [ -n "$colors" ]; then
        # Check if polybar config exists
        if [ ! -f ~/.config/polybar/config.ini ]; then
            echo "Polybar config not found, skipping color update"
            return
        fi
        
        # Backup current config
        cp ~/.config/polybar/config.ini ~/.config/polybar/config.ini.backup
        
        # Parse colors
        local bg=$(echo $colors | grep -o 'bg=[^[:space:]]*' | cut -d= -f2)
        local bg_alt=$(echo $colors | grep -o 'bg-alt=[^[:space:]]*' | cut -d= -f2)
        local fg=$(echo $colors | grep -o 'fg=[^[:space:]]*' | cut -d= -f2)
        local primary=$(echo $colors | grep -o 'primary=[^[:space:]]*' | cut -d= -f2)
        local secondary=$(echo $colors | grep -o 'secondary=[^[:space:]]*' | cut -d= -f2)
        local alert=$(echo $colors | grep -o 'alert=[^[:space:]]*' | cut -d= -f2)
        
        # Update polybar config
        sed -i "s/background = #[0-9a-fA-F]*/background = $bg/" ~/.config/polybar/config.ini
        sed -i "s/background-alt = #[0-9a-fA-F]*/background-alt = $bg_alt/" ~/.config/polybar/config.ini
        sed -i "s/foreground = #[0-9a-fA-F]*/foreground = $fg/" ~/.config/polybar/config.ini
        sed -i "s/primary = #[0-9a-fA-F]*/primary = $primary/" ~/.config/polybar/config.ini
        sed -i "s/secondary = #[0-9a-fA-F]*/secondary = $secondary/" ~/.config/polybar/config.ini
        sed -i "s/alert = #[0-9a-fA-F]*/alert = $alert/" ~/.config/polybar/config.ini
        
        # Restart polybar if launch script exists
        if [ -f ~/.config/polybar/launch.sh ]; then
            ~/.config/polybar/launch.sh &
        fi
    fi
}

# Function to show menu
show_menu() {
    echo "Theme Switcher"
    echo "=============="
    echo "1. GTK Theme"
    echo "2. Icon Theme"
    echo "3. Color Scheme (BSPWM + Polybar)"
    echo "4. Complete Theme Set"
    echo "5. Open LXAppearance"
    echo "6. Exit"
    echo ""
    read -p "Choose option: " choice
    
    case $choice in
        1)
            echo "Available GTK themes:"
            for i in "${!GTK_THEMES[@]}"; do
                echo "$((i+1)). ${GTK_THEMES[$i]}"
            done
            read -p "Select theme (1-${#GTK_THEMES[@]}): " theme_choice
            if [[ $theme_choice -ge 1 && $theme_choice -le ${#GTK_THEMES[@]} ]]; then
                selected_theme=${GTK_THEMES[$((theme_choice-1))]}
                current_icon=$(gsettings get org.gnome.desktop.interface icon-theme | tr -d "'")
                set_gtk_theme "$selected_theme" "$current_icon"
                echo "GTK theme set to: $selected_theme"
            fi
            ;;
        2)
            echo "Available Icon themes:"
            for i in "${!ICON_THEMES[@]}"; do
                echo "$((i+1)). ${ICON_THEMES[$i]}"
            done
            read -p "Select icon theme (1-${#ICON_THEMES[@]}): " icon_choice
            if [[ $icon_choice -ge 1 && $icon_choice -le ${#ICON_THEMES[@]} ]]; then
                selected_icon=${ICON_THEMES[$((icon_choice-1))]}
                current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")
                set_gtk_theme "$current_theme" "$selected_icon"
                echo "Icon theme set to: $selected_icon"
            fi
            ;;
        3)
            echo "Available color schemes:"
            echo "1. Dracula (current)"
            echo "2. Nordic"
            echo "3. Gruvbox"
            echo "4. OneDark"
            echo "5. Catppuccin"
            read -p "Select color scheme (1-5): " color_choice
            case $color_choice in
                1) set_bspwm_colors "dracula"; update_polybar_colors "dracula" ;;
                2) set_bspwm_colors "nordic"; update_polybar_colors "nordic" ;;
                3) set_bspwm_colors "gruvbox"; update_polybar_colors "gruvbox" ;;
                4) set_bspwm_colors "onedark"; update_polybar_colors "onedark" ;;
                5) set_bspwm_colors "catppuccin"; update_polybar_colors "catppuccin" ;;
            esac
            ;;
        4)
            echo "Complete theme sets:"
            echo "1. Dracula Dark (GTK: Dracula, Icons: Papirus-Dark)"
            echo "2. Nordic Blue (GTK: Nordic, Icons: Tela-dark)"
            echo "3. Gruvbox (GTK: Numix, Icons: Papirus)"
            echo "4. Modern Light (GTK: Orchis, Icons: WhiteSur)"
            read -p "Select theme set (1-4): " set_choice
            case $set_choice in
                1) 
                    set_gtk_theme "Dracula" "Papirus-Dark"
                    set_bspwm_colors "dracula"
                    update_polybar_colors "dracula"
                    ;;
                2) 
                    set_gtk_theme "Nordic" "Tela-dark"
                    set_bspwm_colors "nordic"
                    update_polybar_colors "nordic"
                    ;;
                3) 
                    set_gtk_theme "Numix" "Papirus"
                    set_bspwm_colors "gruvbox"
                    update_polybar_colors "gruvbox"
                    ;;
                4) 
                    set_gtk_theme "Orchis" "WhiteSur"
                    set_bspwm_colors "catppuccin"
                    update_polybar_colors "catppuccin"
                    ;;
            esac
            ;;
        5)
            lxappearance &
            ;;
        6)
            exit 0
            ;;
    esac
}

# Main execution
if [ "$1" = "menu" ]; then
    show_menu
else
    echo "Usage: $0 menu"
    echo "or run: theme-switcher menu"
fi
THEME_SWITCHER_EOF

chmod +x ~/.local/bin/theme-switcher

# Create Plank theme switcher
print_status "Creating Plank theme switcher..."

cat > ~/.local/bin/plank-theme-switcher << 'PLANK_EOF'
#!/bin/bash

# Plank Theme Switcher

PLANK_THEMES=(
    "Gtk+"
    "Transparent"
    "Matte"
    "Glass"
)

echo "Available Plank themes:"
for i in "${!PLANK_THEMES[@]}"; do
    echo "$((i+1)). ${PLANK_THEMES[$i]}"
done

read -p "Select theme (1-${#PLANK_THEMES[@]}): " choice

if [[ $choice -ge 1 && $choice -le ${#PLANK_THEMES[@]} ]]; then
    selected_theme=${PLANK_THEMES[$((choice-1))]}
    
    # Kill plank
    pkill plank
    
    # Create plank config directory if it doesn't exist
    mkdir -p ~/.config/plank/dock1
    
    # Update plank settings
    if [ -f ~/.config/plank/dock1/settings ]; then
        sed -i "s/Theme=.*/Theme=$selected_theme/" ~/.config/plank/dock1/settings
    else
        echo "Theme=$selected_theme" > ~/.config/plank/dock1/settings
    fi
    
    # Restart plank
    sleep 1
    plank &
    
    echo "Plank theme set to: $selected_theme"
else
    echo "Invalid selection"
fi
PLANK_EOF

chmod +x ~/.local/bin/plank-theme-switcher

# Create quick access to theme tools
print_status "Creating quick access scripts..."

cat > ~/.local/bin/customize << 'CUSTOMIZE_EOF'
#!/bin/bash

echo "Customization Menu"
echo "=================="
echo "1. Theme Switcher"
echo "2. Plank Theme"
echo "3. LXAppearance (GTK themes)"
echo "4. Wallpaper (Nitrogen)"
echo "5. Rofi theme"
echo ""
read -p "Choose option: " choice

case $choice in
    1) theme-switcher menu ;;
    2) plank-theme-switcher ;;
    3) lxappearance & ;;
    4) nitrogen & ;;
    5) rofi-theme-selector & ;;
esac
CUSTOMIZE_EOF

chmod +x ~/.local/bin/customize

# Create autostart directory if it doesn't exist
mkdir -p ~/.config/autostart

# Create autostart for theme application
cat > ~/.config/autostart/theme-apply.desktop << 'DESKTOP_EOF'
[Desktop Entry]
Type=Application
Name=Apply Theme
Exec=lxappearance
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=true
DESKTOP_EOF

print_status "Theme and icon customization setup complete!"
echo ""
echo "Available commands:"
echo "  theme-switcher menu     - Complete theme switcher"
echo "  plank-theme-switcher    - Change Plank dock theme"
echo "  customize               - Quick customization menu"
echo "  lxappearance           - GTK theme manager"
echo "  nitrogen               - Wallpaper manager"
echo ""
echo "Installed themes:"
echo "  GTK: Dracula, Nordic, Orchis, Arc, Numix"
echo "  Icons: Papirus, Tela, WhiteSur, Fluent, Elementary"
echo ""
echo "Plank themes: Gtk+, Transparent, Matte, Glass"
echo ""
echo "To change themes, run: customize"
