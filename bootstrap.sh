#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to safely remove directories/files
safe_remove() {
    if [ -e "$1" ]; then
        rm -rf "$1"
        print_status "Removed existing $1"
    fi
}

# Function to safely create directory
safe_mkdir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        print_status "Created directory $1"
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Get the real user who executed sudo
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo ~${REAL_USER})

# Clean up existing installations
print_status "Cleaning up existing installations..."
safe_remove "$HOME_DIR/.config/voidrice"
safe_remove "$HOME_DIR/.config/dwm"
safe_remove "$HOME_DIR/.config/st"
safe_remove "$HOME_DIR/.config/lf"
safe_remove "$HOME_DIR/.config/shell/inputrc"
safe_remove "$HOME_DIR/.local/bin/remaps"

# Create base directories
print_status "Creating directories..."
safe_mkdir "$HOME_DIR/.local/bin"
safe_mkdir "$HOME_DIR/.config/shell"
safe_mkdir "$HOME_DIR/.config/dwm"
safe_mkdir "$HOME_DIR/.config/st"
safe_mkdir "$HOME_DIR/.config/lf"

# Update system and install required packages
print_status "Updating system packages..."
apt update && apt upgrade -y

print_status "Installing required packages..."
apt install -y git build-essential libx11-dev libxft-dev libxinerama-dev \
    libxrandr-dev libxss-dev libxcb1-dev libx11-xcb-dev libxcb-util0-dev \
    libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-xinerama0-dev \
    libxcb-xtest0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libxcb-shape0-dev libxcb-xfixes0-dev libxcb-render-util0-dev \
    xcape xdotool x11-xkb-utils golang-go

# Set up Go environment
print_status "Setting up Go environment..."
export GOPATH=$HOME_DIR/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
safe_mkdir "$GOPATH"

# Install Win-KeX
print_status "Installing Win-KeX..."
apt install -y kali-win-kex

# Clone LukeSmith's dotfiles
print_status "Cloning LukeSmith's dotfiles..."
cd "$HOME_DIR/.config"
git clone https://github.com/LukeSmithxyz/voidrice.git || {
    print_error "Failed to clone voidrice repository"
    print_warning "Continuing without voidrice configs"
}

# Install dwm
print_status "Installing dwm..."
cd "$HOME_DIR/.config/dwm"
git clone https://git.suckless.org/dwm . || {
    print_error "Failed to clone dwm repository"
    exit 1
}

if [ -f ../voidrice/.config/dwm/config.h ]; then
    cp ../voidrice/.config/dwm/config.h config.h
else
    print_warning "Using default dwm config"
    cp config.def.h config.h
fi

make clean
make && make install || {
    print_error "Failed to compile dwm"
    exit 1
}

# Install st
print_status "Installing st..."
cd "$HOME_DIR/.config/st"
git clone https://git.suckless.org/st . || {
    print_error "Failed to clone st repository"
    exit 1
}

if [ -f ../voidrice/.config/st/config.h ]; then
    cp ../voidrice/.config/st/config.h config.h
else
    print_warning "Using default st config"
    cp config.def.h config.h
fi

make clean
make && make install || {
    print_error "Failed to compile st"
    exit 1
}

# Install lf
print_status "Installing lf..."
go install github.com/gokcehan/lf@latest || {
    print_error "Failed to install lf"
    print_warning "Make sure Go is properly installed"
}

if [ -f "$GOPATH/bin/lf" ]; then
    cp "$GOPATH/bin/lf" /usr/local/bin/
fi

# Set up remaps script
print_status "Setting up key remapping..."
cat > "$HOME_DIR/.local/bin/remaps" << 'EOF'
#!/bin/sh

# This script is called on startup to remap keys.
# Decrease key repeat delay to 300ms and increase key repeat rate to 50 per second.
xset r rate 300 50

# Map the caps lock key to super, and map the menu key to right super.
setxkbmap -option caps:super,altwin:menu_win

# When caps lock is pressed only once, treat it as escape.
killall xcape 2>/dev/null ; xcape -e 'Super_L=Escape'

# Turn off caps lock if on since there is no longer a key for it.
xset -q | grep -q "Caps Lock:\s*on" && xdotool key Caps_Lock
EOF

chmod +x "$HOME_DIR/.local/bin/remaps"

# Set up inputrc
print_status "Setting up inputrc configuration..."
cat > "$HOME_DIR/.config/shell/inputrc" << 'EOF'
$include /etc/inputrc
set editing-mode vi
$if mode=vi

set show-mode-in-prompt on
set vi-ins-mode-string \1\e[6 q\2
set vi-cmd-mode-string \1\e[2 q\2

set keymap vi-command
Control-l: clear-screen
Control-a: beginning-of-line

set keymap vi-insert
Control-l: clear-screen
Control-a: beginning-of-line
Control-b: backward-char
Control-f: forward-char
Control-p: previous-history
Control-n: next-history
Control-a: beginning-of-line
Control-e: end-of-line
Control-h: backward-delete-char
Control-w: backward-kill-word
Control-k: kill-line
Control-u: unix-line-discard

$endif

set colored-stats On
set visible-stats On
set mark-symlinked-directories On
set colored-completion-prefix On
set menu-complete-display-prefix On
EOF

# Fix permissions
chown -R ${REAL_USER}:${REAL_USER} "$HOME_DIR/.config" "$HOME_DIR/.local"

print_status "Installation complete!"
print_warning "Please restart your WSL instance to apply all changes."
print_warning "To start Win-KeX, run: kex" 