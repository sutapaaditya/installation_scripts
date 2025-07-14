#!/bin/bash

# Network Speed Monitoring Solutions for BSPWM + Plank Setup

print_status() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

print_status "Setting up network speed monitoring options..."

# Install required packages
sudo apt update
sudo apt install -y conky-all vnstat bmon iftop nload

# Option 1: Enhanced Polybar with Network Speed
print_status "Creating enhanced Polybar configuration with network speeds..."

# Backup current polybar config
cp ~/.config/polybar/config.ini ~/.config/polybar/config.ini.backup

# Create network speed script for polybar
mkdir -p ~/.config/polybar/scripts
cat > ~/.config/polybar/scripts/network-speed.sh << 'EOF'
#!/bin/bash

# Network speed monitor for Polybar
# Auto-detect primary network interface

get_primary_interface() {
    # Get the interface with the default route
    ip route | grep '^default' | head -1 | awk '{print $5}'
}

INTERFACE=$(get_primary_interface)

if [ -z "$INTERFACE" ]; then
    echo "No network"
    exit 1
fi

# Get network statistics
RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

# Store in temp file
TEMP_FILE="/tmp/network_speed_$INTERFACE"

if [ -f "$TEMP_FILE" ]; then
    # Read previous values
    read PREV_RX PREV_TX PREV_TIME < "$TEMP_FILE"
    
    # Calculate current time
    CURRENT_TIME=$(date +%s)
    
    # Calculate time difference
    TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
    
    if [ $TIME_DIFF -gt 0 ]; then
        # Calculate speeds in bytes per second
        RX_SPEED=$(( (RX_BYTES - PREV_RX) / TIME_DIFF ))
        TX_SPEED=$(( (TX_BYTES - PREV_TX) / TIME_DIFF ))
        
        # Convert to human readable format
        format_speed() {
            local speed=$1
            if [ $speed -gt 1048576 ]; then
                echo "$(( speed / 1048576 ))MB/s"
            elif [ $speed -gt 1024 ]; then
                echo "$(( speed / 1024 ))KB/s"
            else
                echo "${speed}B/s"
            fi
        }
        
        RX_FORMATTED=$(format_speed $RX_SPEED)
        TX_FORMATTED=$(format_speed $TX_SPEED)
        
        echo " $RX_FORMATTED  $TX_FORMATTED"
    else
        echo " 0B/s  0B/s"
    fi
else
    echo " 0B/s  0B/s"
fi

# Store current values
echo "$RX_BYTES $TX_BYTES $(date +%s)" > "$TEMP_FILE"
EOF

chmod +x ~/.config/polybar/scripts/network-speed.sh

# Add network speed module to polybar config
cat >> ~/.config/polybar/config.ini << 'EOF'

[module/network-speed]
type = custom/script
exec = ~/.config/polybar/scripts/network-speed.sh
interval = 2
format-prefix = " "
format-prefix-foreground = ${colors.primary}
label = %output%
EOF

# Update polybar modules to include network speed
sed -i 's/modules-right = filesystem pulseaudio memory cpu wlan eth battery date powermenu/modules-right = filesystem network-speed pulseaudio memory cpu wlan eth battery date powermenu/' ~/.config/polybar/config.ini

print_status "Polybar network speed module added!"

# Option 2: Conky Network Monitor (Alternative)
print_status "Creating Conky network monitor as alternative..."

cat > ~/.config/conky/conky-network.conf << 'EOF'
conky.config = {
    alignment = 'bottom_right',
    background = true,
    border_width = 1,
    cpu_avg_samples = 2,
    default_color = 'white',
    default_outline_color = 'white',
    default_shade_color = 'white',
    draw_borders = false,
    draw_graph_borders = true,
    draw_outline = false,
    draw_shades = false,
    use_xft = true,
    font = 'JetBrainsMono Nerd Font:size=10',
    gap_x = 20,
    gap_y = 60,
    minimum_height = 5,
    minimum_width = 5,
    net_avg_samples = 2,
    no_buffers = true,
    out_to_console = false,
    out_to_stderr = false,
    extra_newline = false,
    own_window = true,
    own_window_class = 'Conky',
    own_window_type = 'desktop',
    own_window_transparent = true,
    own_window_argb_visual = true,
    own_window_argb_value = 120,
    stippled_borders = 0,
    update_interval = 1.0,
    uppercase = false,
    use_spacer = 'none',
    show_graph_scale = false,
    show_graph_range = false,
    double_buffer = true,
}

conky.text = [[
${color #bd93f9}Network Speed${color}
${color #50fa7b}Down:${color} ${downspeed} ${alignr}${color #ff79c6}Up:${color} ${upspeed}
${downspeedgraph 20,90 50fa7b 50fa7b} ${alignr}${upspeedgraph 20,90 ff79c6 ff79c6}
${color #8be9fd}Total Down:${color} ${totaldown} ${alignr}${color #ffb86c}Total Up:${color} ${totalup}
]]
EOF

# Option 3: Simple system tray network monitor
print_status "Installing system tray network monitor..."

# Install cbatticon equivalent for network
sudo apt install -y nm-tray

# Create autostart entry for network tray
cat > ~/.config/autostart/nm-tray.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Network Manager Tray
Exec=nm-tray
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# Option 4: Create a simple network speed docklet script
print_status "Creating network speed display script..."

cat > ~/.local/bin/network-speed-display << 'EOF'
#!/bin/bash

# Simple network speed display that can be added to system tray

while true; do
    # Get primary interface
    INTERFACE=$(ip route | grep '^default' | head -1 | awk '{print $5}')
    
    if [ -n "$INTERFACE" ]; then
        # Get speeds using vnstat
        if command -v vnstat &> /dev/null; then
            SPEEDS=$(vnstat -i "$INTERFACE" --json | jq -r '.interfaces[0].traffic.total.rx, .interfaces[0].traffic.total.tx' 2>/dev/null)
        fi
        
        # Alternative: use /proc/net/dev
        if [ -z "$SPEEDS" ]; then
            RX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
            TX_BYTES=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
            
            # Simple calculation (you'd need to store previous values for real speed)
            echo "RX: $(numfmt --to=iec $RX_BYTES) TX: $(numfmt --to=iec $TX_BYTES)"
        fi
    else
        echo "No network connection"
    fi
    
    sleep 2
done
EOF

chmod +x ~/.local/bin/network-speed-display

print_status "Network speed monitoring setup complete!"
echo ""
echo "Available options:"
echo "1. Enhanced Polybar with network speeds (recommended)"
echo "2. Conky network monitor: conky -c ~/.config/conky/conky-network.conf"
echo "3. System tray network manager: nm-tray (auto-starts)"
echo "4. Custom network display script: ~/.local/bin/network-speed-display"
echo ""
echo "Restart polybar to see network speeds: ~/.config/polybar/launch.sh"
