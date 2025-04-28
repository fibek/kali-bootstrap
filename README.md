# Kali Linux WSL Bootstrap

A bootstrapping script for Kali Linux WSL that sets up a customized development environment based on Luke Smith's configurations.

## Features

- Installs and configures essential tools:
  - **Win-KeX**: Kali Desktop Experience for Windows.
  - **dwm**: Luke Smith's patched version of the Dynamic Window Manager.
  - **st**: Luke Smith's patched version of the Simple Terminal.
  - **lf**: Luke Smith's patched version of the Terminal file manager.
- Applies Luke Smith's `remaps` script and `inputrc` settings.
- Sets a **Gruvbox Dark** theme via `~/.Xresources`.
- **Customizable Package Installation**: Installs packages listed in `packages.txt`.

## Installation

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/yourusername/kali-bootstrap.git
    cd kali-bootstrap
    ```
    *(Replace `yourusername` with your actual GitHub username)*

2.  **Review `packages.txt`:**
    Edit `packages.txt` and uncomment any additional Kali Linux tools you want to install.

3.  **Make the script executable:**
    ```bash
    chmod +x bootstrap.sh
    ```

4.  **Run the bootstrap script (as root):**
    ```bash
    # To install everything INCLUDING DWM:
    sudo ./kali-bootstrap/bootstrap.sh --dwm

    # To install everything EXCEPT DWM (keeps default Kali DE):
    sudo ./kali-bootstrap/bootstrap.sh
    ```
    *(The script needs root for package installation and system configuration, but installs user configs to your actual user's home directory.)*

5.  **Restart WSL:**
    Shut down and restart your WSL instance. You can do this from Windows PowerShell/CMD:
    ```powershell
    wsl --shutdown
    ```
    Then restart your Kali WSL distribution.

6.  **Start Win-KeX:**
    ```bash
    kex
    ```
    This should now launch directly into your configured DWM session with the Gruvbox theme.

## Configuration Files

The script installs configurations directly into your user's home directory (`~/.config`, `~/.local/bin`, `~/.Xresources`, etc.). Key files managed:

-   `bootstrap.sh`: The main installation script.
-   `packages.txt`: List of packages to install (uncomment lines to enable).
-   `~/.config/dwm/`: Contains the source code for Luke Smith's DWM (built and installed).
-   `~/.config/st/`: Contains the source code for Luke Smith's ST (built and installed).
-   `~/.config/lf/`: Contains the source code for Luke Smith's LF (built and installed).
-   `~/.config/shell/inputrc`: Custom inputrc settings (vi mode, etc.).
-   `~/.local/bin/remaps`: Luke Smith's key remapping script.
-   `~/.Xresources`: Defines the X color theme (Gruvbox Dark).
-   `~/.xprofile`: X session startup script (loads Xresources, runs remaps, starts dwm).
-   `/usr/lib/win-kex/xstartup`: Modified to launch the user's X session configured by `.xprofile` (specifically `dwm`).

## Credits

-   Luke Smith's LARBS, dotfiles, and patched software: [https://github.com/LukeSmithxyz](https://github.com/LukeSmithxyz)
-   Win-KeX: [https://www.kali.org/docs/wsl/win-kex/](https://www.kali.org/docs/wsl/win-kex/)
