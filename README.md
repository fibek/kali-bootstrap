# Kali Linux WSL Bootstrap

A bootstrapping script for Kali Linux WSL that sets up a customized development environment.

## Features

- Installs and configures essential tools:
  - Win-KeX (Kali Desktop Experience for Windows)
  - dwm (Dynamic Window Manager)
  - lf (Terminal file manager)
  - st (Simple Terminal)
- Uses LukeSmith's dotfiles for configuration
- Customizable package installation
- Modular design for easy extension

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/kali-bootstrap.git
cd kali-bootstrap
```

2. Make the script executable:
```bash
chmod +x bootstrap.sh
```

3. Run the bootstrap script:
```bash
./bootstrap.sh
```

## Configuration

The script is modular and can be customized by editing the following files:
- `packages.txt` - List of packages to install
- `config/` - Configuration files for various tools
- `scripts/` - Individual installation scripts

## Structure

```
kali-bootstrap/
├── bootstrap.sh        # Main installation script
├── packages.txt        # List of packages to install
├── config/            # Configuration files
│   ├── dwm/          # dwm configuration
│   ├── st/           # st terminal configuration
│   └── lf/           # lf configuration
└── scripts/          # Individual installation scripts
    ├── win-kex.sh    # Win-KeX installation
    ├── dwm.sh        # dwm installation
    ├── st.sh         # st installation
    └── lf.sh         # lf installation
```

## Credits

- LukeSmith's dotfiles: https://github.com/LukeSmithxyz/voidrice
- Win-KeX: https://www.kali.org/docs/wsl/win-kex/
