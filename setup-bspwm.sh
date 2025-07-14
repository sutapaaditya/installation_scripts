#!/bin/bash

# BSPWM + SXHKD + POLYBAR + PICOM + PLANK Setup Script for Ubuntu
# Optimized for productivity with 3-monitor setup

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
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Starting BSPWM productivity setup..."

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
print_status "Installing required packages..."
sudo apt install -y \
    bspwm sxhkd polybar picom plank \
    rofi feh scrot xclip \
    fonts-font-awesome fonts-powerline \
    pulseaudio-utils alsa-utils \
    nitrogen dunst \
    thunar thunar-archive-plugin \
    curl wget unzip \
    build-essential cmake \
    libxcb-xinerama0-dev libxcb-icccm4-dev libxcb-randr0-dev \
    libxcb-util0-dev libxcb-ewmh-dev libxcb-keysyms1-dev \
    libxcb-shape0-dev

# Create necessary directories
print_status "Creating configuration directories..."
mkdir -p ~/.config/{bspwm,sxhkd,polybar,picom,rofi,dunst}
mkdir -p ~/.local/share/fonts
mkdir -p ~/Pictures/wallpapers

# Download and install Nerd Fonts
print_status "Installing Nerd Fonts..."
if [ ! -f ~/.local/share/fonts/JetBrainsMono-Regular.ttf ]; then
    cd /tmp
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip
    unzip JetBrainsMono.zip -d JetBrainsMono
    cp JetBrainsMono/*.ttf ~/.local/share/fonts/
    fc-cache -fv
fi

# BSPWM Configuration
print_status "Configuring BSPWM..."
cat > ~/.config/bspwm/bspwmrc << 'EOF'
#!/bin/bash

# BSPWM Configuration for 3-monitor productivity setup

# Kill any existing processes
pgrep -x sxhkd > /dev/null && killall sxhkd
pgrep -x polybar > /dev/null && killall polybar
pgrep -x picom > /dev/null && killall picom
pgrep -x plank > /dev/null && killall plank

# Start sxhkd
sxhkd &

# Monitor setup (adjust monitor names as needed)
# Get monitor names automatically
MONITORS=$(xrandr --query | grep " connected" | cut -d" " -f1)
MONITOR_ARRAY=($MONITORS)

# Configure monitors (adjust according to your setup)
if [ ${#MONITOR_ARRAY[@]} -eq 3 ]; then
    bspc monitor ${MONITOR_ARRAY[0]} -d I II III
    bspc monitor ${MONITOR_ARRAY[1]} -d IV V VI
    bspc monitor ${MONITOR_ARRAY[2]} -d VII VIII IX
elif [ ${#MONITOR_ARRAY[@]} -eq 2 ]; then
    bspc monitor ${MONITOR_ARRAY[0]} -d I II III IV V
    bspc monitor ${MONITOR_ARRAY[1]} -d VI VII VIII IX
else
    bspc monitor -d I II III IV V VI VII VIII IX
fi

# BSPWM settings
bspc config border_width         2
bspc config window_gap          12
bspc config split_ratio          0.52
bspc config borderless_monocle   true
bspc config gapless_monocle      true
bspc config focus_follows_pointer true
bspc config pointer_follows_focus false
bspc config pointer_follows_monitor true

# Colors
bspc config normal_border_color   "#44475a"
bspc config active_border_color   "#bd93f9"
bspc config focused_border_color  "#ff79c6"
bspc config presel_feedback_color "#6272a4"

# Rules
bspc rule -a Gimp desktop='^8' state=floating follow=on
bspc rule -a Chromium desktop='^2'
bspc rule -a Firefox desktop='^2'
bspc rule -a Thunderbird desktop='^9'
bspc rule -a Spotify desktop='^9'
bspc rule -a Steam desktop='^7'
bspc rule -a Plank layer=above manage=on border=off
bspc rule -a Rofi state=floating center=true
bspc rule -a Pavucontrol state=floating center=true
bspc rule -a Thunar state=floating center=true

# Set wallpaper
if [ -f ~/Pictures/wallpapers/wallpaper.jpg ]; then
    feh --bg-scale ~/Pictures/wallpapers/wallpaper.jpg
fi

# Start compositor
picom &

# Start polybar
~/.config/polybar/launch.sh &

# Start plank
sleep 2 && plank &

# Start notification daemon
dunst &

# Start nitrogen for wallpaper management
nitrogen --restore &
EOF

chmod +x ~/.config/bspwm/bspwmrc

# SXHKD Configuration
print_status "Configuring SXHKD..."
cat > ~/.config/sxhkd/sxhkdrc << 'EOF'
# SXHKD Configuration for productivity

# Terminal emulator
super + Return
    kitty

# Program launcher
super + d
    rofi -show drun

# Window switcher
super + Tab
    rofi -show window

# Make sxhkd reload its configuration files
super + Escape
    pkill -USR1 -x sxhkd

# Quit/restart bspwm
super + alt + {q,r}
    bspc {quit,wm -r}

# Close and kill
super + {_,shift + }w
    bspc node -{c,k}

# Alternate between the tiled and monocle layout
super + m
    bspc desktop -l next

# Send the newest marked node to the newest preselected node
super + y
    bspc node newest.marked.local -n newest.!automatic.local

# Swap the current node and the biggest window
super + g
    bspc node -s biggest.window

# Set the window state
super + {t,shift + t,s,f}
    bspc node -t {tiled,pseudo_tiled,floating,fullscreen}

# Set the node flags
super + ctrl + {m,x,y,z}
    bspc node -g {marked,locked,sticky,private}

# Focus the node in the given direction
super + {_,shift + }{h,j,k,l}
    bspc node -{f,s} {west,south,north,east}

# Focus the node for the given path jump
super + {p,b,comma,period}
    bspc node -f @{parent,brother,first,second}

# Focus the next/previous window in the current desktop
super + {_,shift + }c
    bspc node -f {next,prev}.local.!hidden.window

# Focus the next/previous desktop in the current monitor
super + bracket{left,right}
    bspc desktop -f {prev,next}.local

# Focus the last node/desktop
super + {grave,Tab}
    bspc {node,desktop} -f last

# Focus the older or newer node in the focus history
super + {o,i}
    bspc wm -h off; \
    bspc node {older,newer} -f; \
    bspc wm -h on

# Focus or send to the given desktop
super + {_,shift + }{1-9,0}
    bspc {desktop -f,node -d} '^{1-9,10}'

# Preselect the direction
super + ctrl + {h,j,k,l}
    bspc node -p {west,south,north,east}

# Preselect the ratio
super + ctrl + {1-9}
    bspc node -o 0.{1-9}

# Cancel the preselection for the focused node
super + ctrl + space
    bspc node -p cancel

# Cancel the preselection for the focused desktop
super + ctrl + shift + space
    bspc query -N -d | xargs -I id -n 1 bspc node id -p cancel

# Expand a window by moving one of its side outward
super + alt + {h,j,k,l}
    bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}

# Contract a window by moving one of its side inward
super + alt + shift + {h,j,k,l}
    bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}

# Move a floating window
super + {Left,Down,Up,Right}
    bspc node -v {-20 0,0 20,0 -20,20 0}

# Volume controls
XF86AudioRaiseVolume
    pactl set-sink-volume @DEFAULT_SINK@ +5%

XF86AudioLowerVolume
    pactl set-sink-volume @DEFAULT_SINK@ -5%

XF86AudioMute
    pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness controls (if available)
XF86MonBrightnessUp
    xbacklight -inc 10

XF86MonBrightnessDown
    xbacklight -dec 10

# Screenshot
Print
    scrot ~/Pictures/screenshot_%Y%m%d_%H%M%S.png

# Screenshot selection
shift + Print
    scrot -s ~/Pictures/screenshot_%Y%m%d_%H%M%S.png

# File manager
super + e
    thunar

# Browser
super + shift + Return
    firefox

# Lock screen (if xss-lock is installed)
super + shift + x
    xset s activate
EOF

# Polybar Configuration
print_status "Configuring Polybar..."
mkdir -p ~/.config/polybar

cat > ~/.config/polybar/config.ini << 'EOF'
[colors]
background = #282a36
background-alt = #44475a
foreground = #f8f8f2
primary = #bd93f9
secondary = #8be9fd
alert = #ff5555
success = #50fa7b
warning = #ffb86c

[bar/main]
width = 100%
height = 30
radius = 0
fixed-center = false

background = ${colors.background}
foreground = ${colors.foreground}

line-size = 2
line-color = #f00

padding-left = 0
padding-right = 2

module-margin-left = 1
module-margin-right = 2

font-0 = JetBrainsMono Nerd Font:pixelsize=12;1
font-1 = Font Awesome 6 Free:pixelsize=12;1
font-2 = Font Awesome 6 Free Solid:pixelsize=12;1
font-3 = Font Awesome 6 Brands:pixelsize=12;1

modules-left = bspwm xwindow
modules-center = 
modules-right = filesystem pulseaudio memory cpu wlan eth battery date powermenu

tray-position = right
tray-padding = 2

wm-restack = bspwm

cursor-click = pointer
cursor-scroll = ns-resize

[module/xwindow]
type = internal/xwindow
label = %title:0:60:...%

[module/bspwm]
type = internal/bspwm

label-focused = %index%
label-focused-background = ${colors.primary}
label-focused-foreground = ${colors.background}
label-focused-underline = ${colors.primary}
label-focused-padding = 2

label-occupied = %index%
label-occupied-padding = 2

label-urgent = %index%!
label-urgent-background = ${colors.alert}
label-urgent-padding = 2

label-empty = %index%
label-empty-foreground = ${colors.background-alt}
label-empty-padding = 2

[module/filesystem]
type = internal/fs
interval = 25

mount-0 = /

label-mounted = %{F#0a81f5}%mountpoint%%{F-}: %percentage_used%%
label-unmounted = %mountpoint% not mounted
label-unmounted-foreground = ${colors.background-alt}

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.primary}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.primary}
label = %percentage_used%%

[module/wlan]
type = internal/network
interface = wlan0
interval = 3.0

format-connected = <ramp-signal> <label-connected>
format-connected-underline = ${colors.success}
label-connected = %essid%

format-disconnected =

ramp-signal-0 = 
ramp-signal-1 = 
ramp-signal-2 = 
ramp-signal-3 = 
ramp-signal-4 = 
ramp-signal-foreground = ${colors.primary}

[module/eth]
type = internal/network
interface = eth0
interval = 3.0

format-connected-underline = ${colors.success}
format-connected-prefix = " "
format-connected-prefix-foreground = ${colors.primary}
label-connected = %local_ip%

format-disconnected =

[module/date]
type = internal/date
interval = 5

date = " %Y-%m-%d"
date-alt = " %Y-%m-%d"

time = %H:%M
time-alt = %H:%M:%S

format-prefix = 
format-prefix-foreground = ${colors.primary}
format-underline = ${colors.secondary}

label = %date% %time%

[module/pulseaudio]
type = internal/pulseaudio

format-volume = <label-volume> <bar-volume>
label-volume = VOL %percentage%%
label-volume-foreground = ${root.foreground}

label-muted = 🔇 muted
label-muted-foreground = ${colors.background-alt}

bar-volume-width = 10
bar-volume-foreground-0 = ${colors.success}
bar-volume-foreground-1 = ${colors.success}
bar-volume-foreground-2 = ${colors.success}
bar-volume-foreground-3 = ${colors.success}
bar-volume-foreground-4 = ${colors.success}
bar-volume-foreground-5 = ${colors.warning}
bar-volume-foreground-6 = ${colors.alert}
bar-volume-gradient = false
bar-volume-indicator = |
bar-volume-indicator-font = 2
bar-volume-fill = ─
bar-volume-fill-font = 2
bar-volume-empty = ─
bar-volume-empty-font = 2
bar-volume-empty-foreground = ${colors.background-alt}

[module/battery]
type = internal/battery
battery = BAT0
adapter = ADP1
full-at = 98

format-charging = <animation-charging> <label-charging>
format-charging-underline = ${colors.warning}

format-discharging = <animation-discharging> <label-discharging>
format-discharging-underline = ${self.format-charging-underline}

format-full-prefix = " "
format-full-prefix-foreground = ${colors.success}
format-full-underline = ${self.format-charging-underline}

ramp-capacity-0 = 
ramp-capacity-1 = 
ramp-capacity-2 = 
ramp-capacity-foreground = ${colors.primary}

animation-charging-0 = 
animation-charging-1 = 
animation-charging-2 = 
animation-charging-foreground = ${colors.primary}
animation-charging-framerate = 750

animation-discharging-0 = 
animation-discharging-1 = 
animation-discharging-2 = 
animation-discharging-foreground = ${colors.primary}
animation-discharging-framerate = 750

[module/powermenu]
type = custom/menu

expand-right = true

format-spacing = 1

label-open = 
label-open-foreground = ${colors.secondary}
label-close =  cancel
label-close-foreground = ${colors.secondary}
label-separator = |
label-separator-foreground = ${colors.background-alt}

menu-0-0 = reboot
menu-0-0-exec = systemctl reboot
menu-0-1 = power off
menu-0-1-exec = systemctl poweroff

[settings]
screenchange-reload = true

[global/wm]
margin-top = 5
margin-bottom = 5
EOF

# Polybar launch script
cat > ~/.config/polybar/launch.sh << 'EOF'
#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar on all monitors
for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
    MONITOR=$m polybar --reload main &
done

echo "Polybar launched..."
EOF

chmod +x ~/.config/polybar/launch.sh

# Picom Configuration
print_status "Configuring Picom..."
cat > ~/.config/picom/picom.conf << 'EOF'
# Picom Configuration for BSPWM

# Backend
backend = "glx";
glx-no-stencil = true;
glx-copy-from-front = false;

# Opacity
active-opacity = 1.0;
inactive-opacity = 0.95;
frame-opacity = 1.0;
inactive-opacity-override = false;

# Blur
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 3;
blur-background-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "class_g = 'Plank'",
    "class_g = 'slop'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Fading
fading = true;
fade-delta = 10;
fade-in-step = 0.03;
fade-out-step = 0.03;
fade-exclude = [ ];

# Other
mark-wmwin-focused = true;
mark-ovredir-focused = true;
use-ewmh-active-win = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 60;
vsync = true;
dbe = false;
unredir-if-possible = false;
focus-exclude = [ ];
detect-transient = true;
detect-client-leader = true;

# Window type settings
wintypes:
{
    tooltip = { fade = true; shadow = false; opacity = 0.85; focus = true; };
    dock = { shadow = false; };
    dnd = { shadow = false; };
    popup_menu = { opacity = 0.95; };
    dropdown_menu = { opacity = 0.95; };
};

# Shadows
shadow = true;
shadow-radius = 12;
shadow-offset-x = -15;
shadow-offset-y = -15;
shadow-opacity = 0.75;
shadow-exclude = [
    "name = 'Notification'",
    "class_g = 'Conky'",
    "class_g ?= 'Notify-osd'",
    "class_g = 'Cairo-clock'",
    "class_g = 'Plank'",
    "_GTK_FRAME_EXTENTS@:c"
];

# Rounded corners
corner-radius = 8;
rounded-corners-exclude = [
    "window_type = 'dock'",
    "window_type = 'desktop'",
    "class_g = 'Plank'"
];
EOF

# Rofi Configuration
print_status "Configuring Rofi..."
cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    display-drun: "Apps";
    display-run: "Run";
    display-window: "Windows";
    drun-display-format: "{name}";
    font: "JetBrainsMono Nerd Font 12";
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus";
    location: 0;
    yoffset: 0;
    xoffset: 0;
    fixed-num-lines: true;
    hideselection: false;
    hide-scrollbar: true;
    bw: 0;
    fullscreen: false;
    show-match: false;
    color-normal: "#282a36, #f8f8f2, #282a36, #bd93f9, #f8f8f2";
    color-urgent: "#282a36, #ff5555, #282a36, #ff5555, #f8f8f2";
    color-active: "#282a36, #50fa7b, #282a36, #50fa7b, #f8f8f2";
    color-window: "#282a36, #6272a4, #6272a4";
    combi-modi: "drun,run";
}
EOF

# Dunst Configuration
print_status "Configuring Dunst..."
cat > ~/.config/dunst/dunstrc << 'EOF'
[global]
    font = JetBrainsMono Nerd Font 12
    allow_markup = yes
    format = "<b>%s</b>\n%b"
    sort = yes
    indicate_hidden = yes
    alignment = center
    bounce_freq = 0
    show_age_threshold = 60
    word_wrap = yes
    ignore_newline = no
    geometry = "300x5-30+50"
    shrink = no
    transparency = 0
    idle_threshold = 120
    monitor = 0
    follow = mouse
    sticky_history = yes
    history_length = 20
    show_indicators = yes
    line_height = 0
    separator_height = 2
    padding = 8
    horizontal_padding = 8
    separator_color = frame
    startup_notification = false
    dmenu = /usr/bin/rofi -dmenu -p dunst:
    browser = /usr/bin/firefox -new-tab
    icon_position = left
    max_icon_size = 32
    frame_width = 2
    frame_color = "#6272a4"

[urgency_low]
    background = "#282a36"
    foreground = "#f8f8f2"
    timeout = 10

[urgency_normal]
    background = "#282a36"
    foreground = "#f8f8f2"
    timeout = 10

[urgency_critical]
    background = "#ff5555"
    foreground = "#f8f8f2"
    timeout = 0
EOF

# Configure Plank
print_status "Configuring Plank..."
mkdir -p ~/.config/plank/dock1
cat > ~/.config/plank/dock1/settings << 'EOF'
[PlankDockPreferences]
Alignment=3
AutoPinning=true
CurrentWorkspaceOnly=false
DockItems=kitty.dockitem;;firefox.dockitem;;thunar.dockitem;;code.dockitem;;
HideDelay=0
HideMode=3
IconSize=48
ItemsAlignment=3
LockItems=false
MonitorNumber=0
Offset=0
PinOnlyRunning=false
Position=3
PressureReveal=false
ShowDockItem=false
Theme=Gtk+
UnhideDelay=0
ZoomEnabled=true
ZoomPercent=150
EOF

# Download a nice wallpaper
print_status "Downloading wallpaper..."
if [ ! -f ~/Pictures/wallpapers/wallpaper.jpg ]; then
    wget -O ~/Pictures/wallpapers/wallpaper.jpg "https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1920&h=1080&fit=crop"
fi

# Create .xsessionrc for starting bspwm
print_status "Creating .xsessionrc..."
cat > ~/.xsessionrc << 'EOF'
#!/bin/bash
exec bspwm
EOF
chmod +x ~/.xsessionrc

# Create desktop entry for bspwm
print_status "Creating desktop entry..."
sudo tee /usr/share/xsessions/bspwm.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=bspwm
Comment=Binary space partitioning window manager
Exec=bspwm
Type=Application
X-LightDM-DesktopName=bspwm
DesktopNames=bspwm
Keywords=tiling;wm;windowmanager;window;manager;
EOF

# Final setup
print_status "Final setup..."

# Make scripts executable
chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/polybar/launch.sh

# Create autostart directory
mkdir -p ~/.config/autostart

# Create autostart entries
cat > ~/.config/autostart/nitrogen.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Nitrogen
Exec=nitrogen --restore
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

print_status "Setup complete!"
print_warning "Please note the following:"
echo "1. Log out and select 'bspwm' from the login manager"
echo "2. Basic keybindings:"
echo "   - Super + Return: Open terminal (kitty)"
echo "   - Super + d: Application launcher"
echo "   - Super + Tab: Window switcher"
echo "   - Super + w: Close window"
echo "   - Super + f: Fullscreen toggle"
echo "   - Super + 1-9: Switch workspaces"
echo "   - Super + Shift + 1-9: Move window to workspace"
echo "   - Super + h/j/k/l: Navigate windows"
echo "   - Super + Shift + h/j/k/l: Move windows"
echo "   - Super + e: File manager"
echo ""
echo "3. You may need to adjust monitor names in ~/.config/bspwm/bspwmrc"
echo "4. Run 'xrandr' to see your monitor configuration"
echo "5. Wallpaper can be changed using nitrogen or feh"
echo ""
echo "Enjoy your new productive BSPWM setup!"
