#!/bin/bash

# Enhanced Bashrc Setup Script for WSL Ubuntu
# This script modifies your .bashrc with productivity utilities, aliases, and functions

set -euo pipefail

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
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_package() {
    local package="$1"
    if ! dpkg -l | grep -q "^ii  $package "; then
        print_status "Installing $package..."
        sudo apt update -qq
        sudo apt install -y "$package"
    else
        print_status "$package is already installed"
    fi
}

# Function to install packages with apt-get
install_packages() {
    local packages=("$@")
    local to_install=()
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            to_install+=("$package")
        fi
    done
    
    if [ ${#to_install[@]} -gt 0 ]; then
        print_status "Installing packages: ${to_install[*]}"
        sudo apt update -qq
        sudo apt install -y "${to_install[@]}"
    else
        print_status "All required packages are already installed"
    fi
}

# Backup original bashrc
backup_bashrc() {
    if [ -f ~/.bashrc ]; then
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
        print_status "Backed up original .bashrc"
    fi
}

# Install required packages
install_required_packages() {
    print_status "Installing required packages..."
    install_packages tree htop curl wget git vim neofetch bat eza fd-find ripgrep fzf ncdu
    
    # Install additional useful tools
    if ! command_exists tldr; then
        print_status "Installing tldr..."
        sudo apt install -y tldr || {
            print_warning "tldr not available in repos, installing via npm if available"
            if command_exists npm; then
                sudo npm install -g tldr
            fi
        }
    fi
}

# Create the enhanced bashrc content
create_enhanced_bashrc() {
    cat > ~/.bashrc << 'EOF'
# ~/.bashrc: Enhanced version with productivity utilities
# Backup created before modification

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=10000
HISTFILESIZE=20000
HISTTIMEFORMAT="%Y-%m-%d %T "
shopt -s histappend
shopt -s histverify
shopt -s checkwinsize

# ============================================================================
# SHELL OPTIONS
# ============================================================================
shopt -s cdspell        # Auto-correct minor spelling errors in cd
shopt -s dirspell       # Auto-correct minor spelling errors in directory names
shopt -s globstar       # Enable ** for recursive globbing
shopt -s nocaseglob     # Case-insensitive globbing
shopt -s autocd         # cd into directory by just typing its name

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
export EDITOR=vim
export VISUAL=vim
export PAGER=less
export LESS='-R -i -w -M -z-4'
export GREP_COLOR='1;32'
export CLICOLOR=1

# ============================================================================
# PATH MODIFICATIONS
# ============================================================================
# Add local bin directories to PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ============================================================================
# PROMPT CONFIGURATION
# ============================================================================
# Git branch in prompt
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

# Enhanced prompt with git branch and color
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi

# ============================================================================
# ALIASES - BASIC COMMANDS
# ============================================================================
# Enhanced ls commands
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --color=auto'
    alias ll='eza -alF --color=auto --group-directories-first'
    alias la='eza -A --color=auto'
    alias l='eza -CF --color=auto'
    alias lt='eza --tree --level=2'
    alias lx='eza -lbhHigUmuSa --color=auto'
elif command -v exa >/dev/null 2>&1; then
    alias ls='exa --color=auto'
    alias ll='exa -alF --color=auto --group-directories-first'
    alias la='exa -A --color=auto'
    alias l='exa -CF --color=auto'
    alias lt='exa --tree --level=2'
    alias lx='exa -lbhHigUmuSa --color=auto'
else
    alias ls='ls --color=auto --group-directories-first'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi

# Enhanced cat with bat
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias ccat='/bin/cat'  # original cat
elif command -v batcat >/dev/null 2>&1; then
    alias cat='batcat --paging=never'
    alias ccat='/bin/cat'
fi

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias -- -='cd -'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# ============================================================================
# ALIASES - SYSTEM & PROCESS MANAGEMENT
# ============================================================================
alias h='history'
alias hg='history | grep'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias top='htop'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mount='mount | column -t'

# System information
alias sysinfo='neofetch'
alias ports='netstat -tulanp'
alias myip='curl -s ifconfig.me'
alias localip="ip route get 1.1.1.1 | awk '{print \$7}'"

# ============================================================================
# ALIASES - FILE OPERATIONS
# ============================================================================
# Find commands
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
    alias cgrep='/bin/grep'  # original grep
fi

# Archive operations
alias tar='tar -v'
alias untar='tar -xvf'
alias targz='tar -czvf'
alias untargz='tar -xzvf'

# File size
alias usage='du -h --max-depth=1 | sort -hr'
alias biggest='find . -type f -printf "%s %p\n" | sort -rn | head -20'

# ============================================================================
# ALIASES - GIT SHORTCUTS
# ============================================================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gr='git remote -v'
alias gf='git fetch'
alias gclone='git clone'

# ============================================================================
# ALIASES - DEVELOPMENT
# ============================================================================
alias py='python3'
alias py2='python2'
alias pip='pip3'
alias serve='python3 -m http.server'
alias json='python3 -m json.tool'

# Node.js shortcuts
alias ni='npm install'
alias ns='npm start'
alias nt='npm test'
alias nr='npm run'

# ============================================================================
# ALIASES - UTILITIES
# ============================================================================
alias c='clear'
alias cls='clear'
alias q='exit'
alias reload='source ~/.bashrc'
alias bashrc='vim ~/.bashrc'
alias profile='vim ~/.profile'

# Quick file editing
alias hosts='sudo vim /etc/hosts'

# Network
alias ping='ping -c 5'
alias fastping='ping -c 100 -s.2'
alias ports='netstat -tulanp'

# ============================================================================
# FUNCTIONS
# ============================================================================

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find and kill process by name
killp() {
    ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs sudo kill -9
}

# Search for text in files
search() {
    if command -v rg >/dev/null 2>&1; then
        rg -i "$1" .
    else
        grep -r -i "$1" .
    fi
}

# Quick backup of file
backup() {
    cp "$1" "$1.backup.$(date +%Y%m%d_%H%M%S)"
}

# Show PATH in readable format
path() {
    echo $PATH | tr ':' '\n' | nl
}

# Weather function (requires curl)
weather() {
    local city="${1:-}"
    if [ -n "$city" ]; then
        curl -s "wttr.in/$city"
    else
        curl -s "wttr.in"
    fi
}

# Create a data URL from a file
dataurl() {
    local mimeType=$(file -b --mime-type "$1")
    if [[ $mimeType == text/* ]]; then
        mimeType="${mimeType};charset=utf-8"
    fi
    echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Get HTTP status code
httpstatus() {
    curl -o /dev/null -s -w "%{http_code}\n" "$1"
}

# Show disk usage of current directory
dirsize() {
    du -sh "${1:-.}" | cut -f1
}

# Convert seconds to human readable time
sec2time() {
    local seconds=$1
    printf "%02d:%02d:%02d\n" $((seconds/3600)) $((seconds%3600/60)) $((seconds%60))
}

# Generate random password
genpass() {
    local length=${1:-16}
    tr -dc 'A-Za-z0-9!@#$%^&*()_+=' < /dev/urandom | head -c "$length" && echo
}

# Quick server for current directory
server() {
    local port="${1:-8000}"
    echo "Starting server at http://localhost:$port"
    python3 -m http.server "$port"
}

# File/directory size in human readable format
sizeof() {
    du -sh "$1"
}

# Show which commands you use the most
topcmds() {
    history | awk '{print $2}' | sort | uniq -c | sort -nr | head -20
}

# ============================================================================
# FZF CONFIGURATION (if available)
# ============================================================================
if command -v fzf >/dev/null 2>&1; then
    # Setup fzf key bindings and fuzzy completion
    if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
    fi
    if [ -f /usr/share/doc/fzf/examples/completion.bash ]; then
        source /usr/share/doc/fzf/examples/completion.bash
    fi
    
    # Custom fzf functions
    alias fcd='cd $(find . -type d -not -path "*/\.*" | fzf)'
    alias fvim='vim $(fzf)'
fi

# ============================================================================
# COMPLETION ENHANCEMENTS
# ============================================================================
# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Git completion
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
fi

# ============================================================================
# CUSTOM ADDITIONS
# ============================================================================
# Load custom aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Load custom functions if they exist
if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi

# ============================================================================
# WELCOME MESSAGE
# ============================================================================
# Show system info on login (comment out if you don't want this)
if command -v neofetch >/dev/null 2>&1; then
    echo "Welcome back! Here's your system info:"
    neofetch --config off --disable theme icons --ascii_distro ubuntu_small
fi

# Show useful tip
echo -e "\n${GREEN}💡 Tip:${NC} Type 'cheat' to see available custom commands and aliases"
EOF
}

# Create cheatsheet function
create_cheatsheet() {
    cat > ~/.bash_cheatsheet << 'EOF'
# ============================================================================
# ENHANCED BASHRC CHEATSHEET
# ============================================================================

# DIRECTORY NAVIGATION
# --------------------
mkcd <dir>         # Create directory and cd into it
..                 # Go up one directory
...                # Go up two directories
....               # Go up three directories
.....              # Go up four directories
~                  # Go to home directory
-                  # Go to previous directory

# FILE OPERATIONS (with modern tools)
# -----------------------------------
ls, ll, la, l      # Enhanced listing (with eza/exa if available)
lt                 # Tree view (level 2)
lx                 # Extended listing with details
cat                # Enhanced cat (with bat if available)
find               # Enhanced find (with fd if available)
grep               # Enhanced grep (with ripgrep if available)

# SYSTEM MONITORING
# -----------------
top                # Enhanced top (htop)
df                 # Disk usage (human readable)
du                 # Directory usage (human readable)
free               # Memory usage (human readable)
ps                 # Process list
psg <name>         # Search processes by name
ports              # Show network ports
sysinfo            # System information (neofetch)
myip               # Show external IP
localip            # Show local IP

# FILE UTILITIES
# --------------
extract <file>     # Extract any archive format
backup <file>      # Quick backup with timestamp
sizeof <file/dir>  # Show size in human readable format
usage              # Show directory sizes sorted
biggest            # Find 20 largest files

# GIT SHORTCUTS
# -------------
g                  # git
gs                 # git status
ga <file>          # git add
gaa                # git add .
gc                 # git commit
gcm "message"      # git commit -m
gp                 # git push
gpl                # git pull
gl                 # git log (pretty format)
gd                 # git diff
gb                 # git branch
gco <branch>       # git checkout
gcb <branch>       # git checkout -b (create new branch)

# DEVELOPMENT
# -----------
py                 # python3
serve [port]       # Start HTTP server (default port 8000)
server [port]      # Same as serve
json               # Pretty print JSON
ni                 # npm install
ns                 # npm start
nt                 # npm test
nr                 # npm run

# SEARCH & TEXT
# -------------
search <text>      # Search for text in files (ripgrep/grep)
hg <text>          # Search command history

# PROCESS MANAGEMENT
# ------------------
killp <name>       # Find and kill process by name

# UTILITIES
# ---------
weather [city]     # Show weather (default: current location)
genpass [length]   # Generate random password (default: 16 chars)
path               # Show PATH in readable format
topcmds            # Show most used commands
sec2time <seconds> # Convert seconds to HH:MM:SS
httpstatus <url>   # Get HTTP status code
dataurl <file>     # Create data URL from file

# SYSTEM SHORTCUTS
# ----------------
c, cls             # Clear screen
q                  # Exit
reload             # Reload .bashrc
bashrc             # Edit .bashrc
hosts              # Edit /etc/hosts (with sudo)

# FZF SHORTCUTS (if fzf is installed)
# -----------------------------------
Ctrl+R             # Fuzzy search command history
Ctrl+T             # Fuzzy search files
Alt+C              # Fuzzy search directories and cd
fcd                # Fuzzy find and cd to directory
fvim               # Fuzzy find and open file in vim

# ARCHIVE OPERATIONS
# ------------------
targz <file> <dir> # Create tar.gz archive
untargz <file>     # Extract tar.gz archive
untar <file>       # Extract tar archive

# SAFETY ALIASES (will prompt before action)
# ------------------------------------------
rm                 # Remove with confirmation
cp                 # Copy with confirmation
mv                 # Move with confirmation
ln                 # Link with confirmation

# NETWORKING
# ----------
ping               # Ping with 5 packets
fastping           # Ping with 100 packets quickly

# ============================================================================
# TIPS
# ============================================================================
# - Use Tab completion extensively - it's enhanced!
# - Use Ctrl+R for reverse history search
# - Use !! to repeat last command
# - Use !$ to use last argument of previous command
# - Use !^ to use first argument of previous command
# - All original commands are still available (e.g., /bin/cat for original cat)
# - Type 'cheat' anytime to see this cheatsheet
# - Your original .bashrc is backed up with timestamp

EOF

    # Add cheat function to bashrc
    cat >> ~/.bashrc << 'EOF'

# Show cheatsheet
cheat() {
    if command -v bat >/dev/null 2>&1; then
        bat ~/.bash_cheatsheet
    elif command -v batcat >/dev/null 2>&1; then
        batcat ~/.bash_cheatsheet
    else
        less ~/.bash_cheatsheet
    fi
}
EOF
}

# Main execution
main() {
    echo -e "${BLUE}Enhanced Bashrc Setup Script${NC}"
    echo "==============================="
    
    # Check if running on Ubuntu/Debian
    if ! command_exists apt; then
        print_error "This script is designed for Ubuntu/Debian systems with apt package manager"
        exit 1
    fi
    
    # Ask for confirmation
    echo -e "${YELLOW}This script will:${NC}"
    echo "1. Backup your current .bashrc"
    echo "2. Install useful packages (tree, htop, curl, wget, git, vim, neofetch, bat, eza, fd-find, ripgrep, fzf, ncdu)"
    echo "3. Replace your .bashrc with an enhanced version"
    echo "4. Create a cheatsheet for new commands"
    echo
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled by user"
        exit 0
    fi
    
    # Execute setup steps
    backup_bashrc
    install_required_packages
    create_enhanced_bashrc
    create_cheatsheet
    
    print_status "Setup completed successfully!"
    echo
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Run 'source ~/.bashrc' or restart your terminal"
    echo "2. Type 'cheat' to see all available commands"
    echo "3. Your original .bashrc is backed up in your home directory"
    echo
    echo -e "${BLUE}Enjoy your enhanced bash experience!${NC}"
}

# Run main function
main "$@"
