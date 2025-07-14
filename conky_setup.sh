#!/bin/bash

# Conky Setup Script for Ubuntu MATE Developer Environment
# Designed for 3-monitor setup with development-focused widgets

echo "Setting up Conky for developer productivity..."

# Install Conky and dependencies
sudo apt update
sudo apt install -y conky-all curl git htop

# Create conky config directory
mkdir -p ~/.config/conky

# Create main system monitor config (Monitor 1 - Primary)
cat > ~/.config/conky/system_monitor.conf << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = false,
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
    font = 'DejaVu Sans Mono:size=10',
    gap_x = 5,
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
    own_window_argb_value = 200,
    stippled_borders = 0,
    update_interval = 1.0,
    uppercase = false,
    use_spacer = 'none',
    show_graph_scale = false,
    show_graph_range = false,
    double_buffer = true,
}

conky.text = [[
${color orange}SYSTEM INFO${color}
${color grey}Uptime:$color $uptime
${color grey}RAM Usage:$color $mem/$memmax - $memperc% ${membar 4}
${color grey}Swap Usage:$color $swap/$swapmax - $swapperc% ${swapbar 4}
${color grey}CPU Usage:$color $cpu% ${cpubar 4}
${color grey}Processes:$color $processes  ${color grey}Running:$color $running_processes

${color orange}CPU CORES${color}
${color grey}Core 1: ${color}${cpu cpu1}% ${cpubar cpu1 4}
${color grey}Core 2: ${color}${cpu cpu2}% ${cpubar cpu2 4}
${color grey}Core 3: ${color}${cpu cpu3}% ${cpubar cpu3 4}
${color grey}Core 4: ${color}${cpu cpu4}% ${cpubar cpu4 4}

${color orange}MEMORY${color}
${color grey}${top_mem name 1} ${top_mem pid 1} ${top_mem cpu 1} ${top_mem mem 1}
${color grey}${top_mem name 2} ${top_mem pid 2} ${top_mem cpu 2} ${top_mem mem 2}
${color grey}${top_mem name 3} ${top_mem pid 3} ${top_mem cpu 3} ${top_mem mem 3}

${color orange}DISK USAGE${color}
${color grey}/ $color${fs_used /}/${fs_size /} ${fs_bar 6 /}
${color grey}/home $color${fs_used /home}/${fs_size /home} ${fs_bar 6 /home}

${color orange}NETWORK${color}
${color grey}Down:$color ${downspeed eth0} k/s ${color grey}Up:$color ${upspeed eth0} k/s
${downspeedgraph eth0 32,150 ff0000 0000ff} ${upspeedgraph eth0 32,150 0000ff ff0000}

${color orange}GPU (NVIDIA)${color}
${color grey}GPU Temp: ${color}${nvidia temp}°C
${color grey}GPU Usage: ${color}${nvidia gpuutil}%
${color grey}VRAM: ${color}${nvidia memutil}%
]]
EOF

# Create development tools monitor (Monitor 2 - Secondary)
cat > ~/.config/conky/dev_tools.conf << 'EOF'
conky.config = {
    alignment = 'top_left',
    background = false,
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
    font = 'DejaVu Sans Mono:size=10',
    gap_x = 5,
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
    own_window_argb_value = 200,
    stippled_borders = 0,
    update_interval = 2.0,
    uppercase = false,
    use_spacer = 'none',
    show_graph_scale = false,
    show_graph_range = false,
    double_buffer = true,
}

conky.text = [[
${color orange}DEVELOPMENT TOOLS${color}
${color grey}Git Status:
${color}${exec cd ~/Projects 2>/dev/null && find . -name ".git" -type d | head -5 | while read dir; do echo "  $(basename $(dirname $dir)): $(cd $(dirname $dir) && git status --porcelain | wc -l) changes"; done}

${color orange}DOCKER${color}
${color grey}Containers: ${color}${exec docker ps -q | wc -l} running
${color grey}Images: ${color}${exec docker images -q | wc -l} total
${color}${exec docker ps --format "table {{.Names}}\t{{.Status}}" | head -6}

${color orange}SERVICES${color}
${color grey}Apache: ${color}${exec systemctl is-active apache2 2>/dev/null || echo "inactive"}
${color grey}Nginx: ${color}${exec systemctl is-active nginx 2>/dev/null || echo "inactive"}
${color grey}MySQL: ${color}${exec systemctl is-active mysql 2>/dev/null || echo "inactive"}
${color grey}PostgreSQL: ${color}${exec systemctl is-active postgresql 2>/dev/null || echo "inactive"}
${color grey}Redis: ${color}${exec systemctl is-active redis-server 2>/dev/null || echo "inactive"}
${color grey}MongoDB: ${color}${exec systemctl is-active mongod 2>/dev/null || echo "inactive"}

${color orange}PROCESSES${color}
${color grey}Node.js: ${color}${exec pgrep -f node | wc -l} processes
${color grey}Python: ${color}${exec pgrep -f python | wc -l} processes
${color grey}Java: ${color}${exec pgrep -f java | wc -l} processes

${color orange}RECENT LOGS${color}
${color grey}Last errors:
${color}${exec tail -3 /var/log/syslog | grep -i error | cut -c1-50}
]]
EOF

# Create TODO/Notes widget (Monitor 3 - Tertiary)
cat > ~/.config/conky/todo_notes.conf << 'EOF'
conky.config = {
    alignment = 'top_right',
    background = false,
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
    font = 'DejaVu Sans Mono:size=10',
    gap_x = 5,
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
    own_window_argb_value = 200,
    stippled_borders = 0,
    update_interval = 30.0,
    uppercase = false,
    use_spacer = 'none',
    show_graph_scale = false,
    show_graph_range = false,
    double_buffer = true,
}

conky.text = [[
${color orange}TODO & NOTES${color}
${color grey}Today: ${color}${exec date +"%A, %B %d, %Y"}
${color grey}Time: ${color}${exec date +"%H:%M:%S"}

${color orange}QUICK TODOS${color}
${color}${exec if [ -f ~/todo.txt ]; then head -10 ~/todo.txt; else echo "Create ~/todo.txt to see todos here"; fi}

${color orange}SYSTEM SHORTCUTS${color}
${color grey}Ctrl+Alt+T: ${color}Terminal
${color grey}Super+E: ${color}File Manager
${color grey}Super+R: ${color}Run Dialog
${color grey}Ctrl+Alt+L: ${color}Lock Screen

${color orange}CUSTOM ALIASES${color}
${color grey}ll: ${color}ls -la
${color grey}la: ${color}ls -la
${color grey}...: ${color}cd ../../
${color grey}gits: ${color}git status
${color grey}gitl: ${color}git log --oneline -10

${color orange}WEATHER${color}
${color}${exec curl -s "wttr.in/Siliguri?format=3" 2>/dev/null || echo "Weather unavailable"}
]]
EOF

# Create startup script
cat > ~/.config/conky/start_conky.sh << 'EOF'
#!/bin/bash

# Kill existing conky processes
killall conky

# Wait a moment
sleep 2

# Start conky instances for each monitor
DISPLAY=:0 conky -c ~/.config/conky/system_monitor.conf &
DISPLAY=:0 conky -c ~/.config/conky/dev_tools.conf &
DISPLAY=:0 conky -c ~/.config/conky/todo_notes.conf &

echo "Conky started on all monitors"
EOF

# Make startup script executable
chmod +x ~/.config/conky/start_conky.sh

# Create a simple todo.txt file if it doesn't exist
if [ ! -f ~/todo.txt ]; then
    cat > ~/todo.txt << 'EOF'
□ Set up development environment
□ Configure IDE preferences
□ Clone important repositories
□ Set up database connections
□ Configure backup strategy
□ Optimize system performance
□ Learn new framework/tool
□ Review code documentation
□ Update system packages
□ Plan next project phase
EOF
fi

# Create desktop entry for easy launching
cat > ~/.local/share/applications/conky-dev.desktop << 'EOF'
[Desktop Entry]
Name=Conky Developer Setup
Comment=Start Conky with developer-focused widgets
Exec=/home/$USER/.config/conky/start_conky.sh
Icon=utilities-system-monitor
Terminal=false
Type=Application
Categories=System;Monitor;
EOF

# Add to autostart
mkdir -p ~/.config/autostart
cp ~/.local/share/applications/conky-dev.desktop ~/.config/autostart/

echo "Conky setup complete!"
echo "Files created:"
echo "  - ~/.config/conky/system_monitor.conf"
echo "  - ~/.config/conky/dev_tools.conf"
echo "  - ~/.config/conky/todo_notes.conf"
echo "  - ~/.config/conky/start_conky.sh"
echo "  - ~/todo.txt"
echo ""
echo "To start Conky now: ~/.config/conky/start_conky.sh"
echo "Conky will auto-start on next login"
echo ""
echo "Customize ~/todo.txt for your personal todos"
echo "Modify the .conf files to adjust positioning and content"
EOF
