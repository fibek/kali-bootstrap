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
    xcape xdotool x11-xkb-utils golang-go libharfbuzz-dev

# Install packages from packages.txt
PACKAGES_FILE="$HOME_DIR/dev/kali-bootstrap/packages.txt" # Assuming script is run from workspace root
if [ -f "$PACKAGES_FILE" ]; then
    print_status "Installing packages from packages.txt..."
    # Read uncommented lines, trim whitespace, filter empty lines
    PACKAGES_TO_INSTALL=$(grep -v '^#' "$PACKAGES_FILE" | sed 's/#.*//' | sed 's/^[ \t]*//;s/[ \t]*$//' | grep -v '^$')
    if [ -n "$PACKAGES_TO_INSTALL" ]; then
        # Attempt to install, allow failures for individual packages
        sudo apt install -y $PACKAGES_TO_INSTALL || print_warning "Some packages from packages.txt might have failed to install. Please check logs."
    else
        print_warning "No uncommented packages found in packages.txt"
    fi
else
    print_warning "packages.txt not found. Skipping custom package installation."
fi

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

# --- Optional DWM Installation ---
install_dwm=false
for arg in "$@"; do
    case $arg in
        --dwm)
        install_dwm=true
        shift # Remove --dwm from processing
        ;;
        *)
        # Unknown option
        ;;
    esac
done

if [ "$install_dwm" = true ] ; then
    print_status "--dwm flag detected. Installing dwm (LukeSmith's version)..."
    cd "$HOME_DIR/.config"
    rm -rf dwm
    # Clone Luke's patched dwm
    GIT_SSL_NO_VERIFY=1 git clone https://github.com/LukeSmithxyz/dwm.git
    if [ -d "dwm" ]; then
        cd dwm
        sudo make clean install || print_error "Failed to build/install dwm"
    else
        print_error "Failed to clone LukeSmith's dwm repository."
    fi
else
    print_status "Skipping DWM installation (no --dwm flag)."
fi

# Install st (Luke's version)
print_status "Installing st (LukeSmith's version)..."
cd "$HOME_DIR/.config"
rm -rf st
GIT_SSL_NO_VERIFY=1 git clone https://github.com/LukeSmithxyz/st.git
cd st
sudo make clean install || print_error "Failed to build/install st"

# Install lf (Official Repo + Luke's Config)
print_status "Installing lf (Official Repo)..."
cd "$HOME_DIR/.config"
rm -rf lf # Remove potential old clone
# Clone the official lf repository
git clone https://github.com/gokcehan/lf.git
cd lf
go build || print_error "Failed to build lf"
if [ -f ./lf ]; then
    sudo cp lf /usr/local/bin/
    print_status "lf binary installed to /usr/local/bin/"
else
    print_error "lf build failed, binary not found."
fi

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
    ln -sf "$HOME_DIR/.config/voidrice/.config/lf" "$HOME_DIR/.config/" || print_error "Failed to link lf config from voidrice."
    print_status "Linked lf configuration from voidrice."
else
    print_warning "Luke's lf configuration not found in voidrice clone. Using default lf behavior."
    # If no voidrice config, ensure the lf source dir we built from exists for reference
    # The binary is already installed, so this dir isn't strictly needed at runtime.
    # safe_mkdir "$HOME_DIR/.config/lf" # Re-create if removed above, or ensure it exists
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

# Verify dwm installation
if ! command -v dwm >/dev/null 2>&1 || ! [ -x "$(command -v dwm)" ]; then
    print_error "dwm installation failed or binary not found in PATH."
else
    print_status "dwm binary found at: $(command -v dwm)"
fi

# Verify st installation
if ! command -v st >/dev/null 2>&1 || ! [ -x "$(command -v st)" ]; then
    print_error "st installation failed or binary not found in PATH."
else
    print_status "st binary found at: $(command -v st)"
fi

# Verify lf installation
if ! command -v lf >/dev/null 2>&1 || ! [ -x "$(command -v lf)" ]; then
    print_error "lf installation failed or binary not found in PATH."
else
    print_status "lf binary found at: $(command -v lf)"
fi

# Add Xresources loading and dwm execution to .xprofile
print_status "Updating .xprofile for Xresources and dwm..."
touch "$HOME_DIR/.xprofile"
if ! grep -q "xrdb.*Xresources" "$HOME_DIR/.xprofile"; then
    echo "[ -f ~/.Xresources ] && xrdb ~/.Xresources" >> "$HOME_DIR/.xprofile"
fi
# Ensure remaps runs before dwm
if grep -q "remaps &" "$HOME_DIR/.xprofile" && ! grep -q "exec dwm" "$HOME_DIR/.xprofile"; then
    # If remaps exists but exec dwm doesn't, add exec dwm after remaps
    sed -i '/remaps &/a exec dwm' "$HOME_DIR/.xprofile"
elif ! grep -q "exec dwm" "$HOME_DIR/.xprofile"; then
    # If neither exists, add both (remaps first)
    echo "remaps &" >> "$HOME_DIR/.xprofile"
    echo "exec dwm" >> "$HOME_DIR/.xprofile"
fi

# Fix permissions
chown -R ${REAL_USER}:${REAL_USER} "$HOME_DIR/.config" "$HOME_DIR/.local"

# Configure Win-KeX startup
if [ "$install_dwm" = true ] ; then
    print_status "Configuring Win-KeX xstartup for DWM..."
    CONFIGURE_KEX_SCRIPT="$HOME_DIR/dev/kali-bootstrap/scripts/configure-win-kex" # Adjust path if needed
    if [ -f "$CONFIGURE_KEX_SCRIPT" ]; then
        sudo "$CONFIGURE_KEX_SCRIPT"
    else
        print_error "configure-win-kex script not found!"
    fi
else
    print_status "Skipping Win-KeX configuration for DWM (no --dwm flag)."
fi

print_status "Installation complete!"
print_warning "Please restart your WSL instance to apply all changes."
print_warning "To start Win-KeX, run: kex" 