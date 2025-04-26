#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the real user who executed sudo
REAL_USER=${SUDO_USER:-$USER}
HOME_DIR=$(eval echo ~${REAL_USER})

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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Clean up existing installations
print_status "Cleaning up existing installations..."
safe_remove() {
    rm -rf "$HOME_DIR/.config/voidrice"
    rm -rf "$HOME_DIR/.config/dwm"
    rm -rf "$HOME_DIR/.config/st"
    rm -rf "$HOME_DIR/.config/lf"
    rm -f "$HOME_DIR/.config/shell/inputrc"
    rm -f "$HOME_DIR/.local/bin/remaps"
}
safe_remove

# Create base directories
print_status "Creating directories..."
safe_mkdir() {
    mkdir -p "$HOME_DIR/.local/bin"
    mkdir -p "$HOME_DIR/.config/shell"
    mkdir -p "$HOME_DIR/.config/{dwm,st,lf}"
}
safe_mkdir

# Update system
print_status "Updating system packages..."
apt update

# Install required packages
print_status "Installing required packages..."
apt install -y git build-essential libx11-dev libxft-dev libxinerama-dev \
    libxrandr-dev libxss-dev libxcb1-dev libx11-xcb-dev libxcb-util0-dev \
    libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-randr0-dev libxcb-xinerama0-dev \
    libxcb-xtest0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev \
    libxcb-shape0-dev libxcb-xfixes0-dev libxcb-render-util0-dev \
    xcape xdotool x11-xkb-utils golang-go

# Set up Go environment
print_status "Setting up Go environment..."
export GOPATH="$HOME_DIR/go"
export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin
mkdir -p $GOPATH

# Install Win-KeX
print_status "Installing Win-KeX..."
apt install -y kali-win-kex

# Clone LukeSmith's dotfiles
print_status "Cloning LukeSmith's dotfiles..."
cd "$HOME_DIR/.config"
rm -rf voidrice
git clone https://github.com/LukeSmithxyz/voidrice.git

# Install dwm (Luke's version)
print_status "Installing dwm (LukeSmith's version)..."
cd "$HOME_DIR/.config"
rm -rf dwm
# Clone Luke's patched dwm
GIT_SSL_NO_VERIFY=1 git clone https://github.com/LukeSmithxyz/dwm.git
cd dwm
sudo make clean install

# Install st (Luke's version)
print_status "Installing st (LukeSmith's version)..."
cd "$HOME_DIR/.config"
rm -rf st
GIT_SSL_NO_VERIFY=1 git clone https://github.com/LukeSmithxyz/st.git
cd st
sudo make clean install

# Install lf (Luke's version)
print_status "Installing lf (LukeSmith's version)..."
cd "$HOME_DIR/.config"
rm -rf lf
GIT_SSL_NO_VERIFY=1 git clone https://github.com/LukeSmithxyz/lf.git
cd lf
sudo make clean install

# Set up Xresources (Gruvbox dark)
print_status "Setting up Xresources (Gruvbox dark)..."
cat > "$HOME_DIR/.Xresources" << 'EOF'
! Gruvbox Dark Xresources
*.foreground:   #ebdbb2
*.background:   #282828
*.cursorColor:  #ebdbb2
*.color0:       #282828
*.color1:       #cc241d
*.color2:       #98971a
*.color3:       #d79921
*.color4:       #458588
*.color5:       #b16286
*.color6:       #689d6a
*.color7:       #a89984
*.color8:       #928374
*.color9:       #fb4934
*.color10:      #b8bb26
*.color11:      #fabd2f
*.color12:      #83a598
*.color13:      #d3869b
*.color14:      #8ec07c
*.color15:      #ebdbb2
EOF

# Set up remaps script
print_status "Setting up key remapping..."
cat > "$HOME_DIR/.local/bin/remaps" << 'EOF'
#!/bin/sh

# This script is called on startup to remap keys.
# Increase key speed via a rate change
xset r rate 300 50
# Map the caps lock key to super...
setxkbmap -option caps:super
# But when it is pressed only once, treat it as escape.
killall xcape 2>/dev/null ; xcape -e 'Super_L=Escape'
# Map the menu button to right super as well.
xmodmap -e 'keycode 135 = Super_R'
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
# these are for vi-command mode
Control-l: clear-screen
Control-a: beginning-of-line

set keymap vi-insert
# these are for vi-insert mode
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

# Color files by types
set colored-stats On
# Append char to indicate type
set visible-stats On
# Mark symlinked directories
set mark-symlinked-directories On
# Color the common prefix
set colored-completion-prefix On
# Color the common prefix in menu-complete
set menu-complete-display-prefix On

# Intelligent completion
set skip-completed-text on
set completion-ignore-case on

# Show all completions as soon as I press tab, even if there's more than one
set show-all-if-ambiguous on
# Show extra file information when completing, like `ls -F` does
set visible-stats on
EOF

# Configure shell to use inputrc
print_status "Configuring shell..."
if ! grep -q "INPUTRC" "$HOME_DIR/.bashrc"; then
    echo "export INPUTRC=\"$HOME_DIR/.config/shell/inputrc\"" >> "$HOME_DIR/.bashrc"
fi

if [ -f "$HOME_DIR/.zshrc" ] && ! grep -q "INPUTRC" "$HOME_DIR/.zshrc"; then
    echo "export INPUTRC=\"$HOME_DIR/.config/shell/inputrc\"" >> "$HOME_DIR/.zshrc"
fi

# Create symlinks for configurations
print_status "Setting up configurations..."
if [ -d "$HOME_DIR/.config/voidrice/.config/lf" ]; then
    rm -rf "$HOME_DIR/.config/lf"  # Remove existing directory first
    ln -sf "$HOME_DIR/.config/voidrice/.config/lf" "$HOME_DIR/.config/"
fi

# Add remaps to X startup
print_status "Adding remaps to X startup..."
touch "$HOME_DIR/.xprofile"
if ! grep -q "remaps &" "$HOME_DIR/.xprofile"; then
    echo "remaps &" >> "$HOME_DIR/.xprofile"
fi

# Add Go environment variables to shell rc files
print_status "Adding Go environment variables to shell..."
if ! grep -q "GOPATH" "$HOME_DIR/.bashrc"; then
    echo "export GOPATH=$HOME_DIR/go" >> "$HOME_DIR/.bashrc"
    echo 'export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin' >> "$HOME_DIR/.bashrc"
fi

if [ -f "$HOME_DIR/.zshrc" ] && ! grep -q "GOPATH" "$HOME_DIR/.zshrc"; then
    echo "export GOPATH=$HOME_DIR/go" >> "$HOME_DIR/.zshrc"
    echo 'export PATH=$PATH:/usr/lib/go/bin:$GOPATH/bin' >> "$HOME_DIR/.zshrc"
fi

# Fix permissions
chown -R ${REAL_USER}:${REAL_USER} "$HOME_DIR/.config" "$HOME_DIR/.local"

print_status "Installation complete!"
print_warning "Please restart your WSL instance to apply all changes."
print_warning "To start Win-KeX, run: kex" 