# Arch Linux + Hyprland — Complete Setup & Experience Guide

> **Reference Machine:** Lenovo IdeaPad Gaming 3 15IAH7 | Intel 12th Gen + NVIDIA RTX 3050 | Dual Boot Windows + rEFInd
>
> This document consolidates the full installation process, post-install configuration, theming, power optimization, security hardening, and daily-use tips into a single, step-by-step reference. A complete beginner should be able to follow every section from top to bottom.

---

## Table of Contents

1. [Part 1: Base Installation](#part-1-base-installation)
2. [Part 2: NVIDIA Driver & Secure Boot](#part-2-nvidia-driver--secure-boot)
3. [Part 3: Desktop Environment (Hyprland + UWSM + SDDM)](#part-3-desktop-environment-hyprland--uwsm--sddm)
4. [Part 4: Audio, Multimedia & Bluetooth](#part-4-audio-multimedia--bluetooth)
5. [Part 5: Tools & Utilities](#part-5-tools--utilities)
6. [Part 6: Theming (Catppuccin Mocha)](#part-6-theming-catppuccin-mocha)
7. [Part 7: Lenovo Hardware Management](#part-7-lenovo-hardware-management)
8. [Part 8: Power Management & Battery Optimization](#part-8-power-management--battery-optimization)
9. [Part 9: Security & Firewall](#part-9-security--firewall)
10. [Part 10: Maintenance & Troubleshooting](#part-10-maintenance--troubleshooting)
11. [Part 11: Tips for Windows Switchers](#part-11-tips-for-windows-switchers)
12. [Part 12: Keyboard Shortcuts Reference](#part-12-keyboard-shortcuts-reference)
13. [Part 13: Development Environment & Utilities](#part-13-development-environment--utilities)

---

# Part 1: Base Installation

## 1.1. Boot into Arch ISO (Without a USB Drive)

Instead of burning a USB, leverage the EFI firmware's ability to auto-detect `.efi` files on any FAT32 partition:

1. Create a small partition (~3 GB), format it as `FAT32`.
2. Extract the entire Arch Linux ISO contents onto that partition.
3. Reboot → press `F12` for Boot Menu → select the new partition.
4. Choose **Arch Linux install medium** → **minimal** mode.

## 1.2. Connect to Wi-Fi

```bash
iwctl                                       # Enter the wireless management shell

# Inside iwctl:
[iwd]# device list                          # Find your wireless device name (e.g. wlan0)
[iwd]# station wlan0 scan                   # Scan for networks
[iwd]# station wlan0 get-networks           # List discovered networks
[iwd]# station wlan0 connect "Your_SSID"    # Connect (you will be prompted for a password)
[iwd]# exit
```

> **Note:** After the base install, you will switch to `nmtui` (NetworkManager) for Wi-Fi management:
> ```bash
> nmtui                                       # TUI network manager
> sudo systemctl enable --now NetworkManager   # Enable if not already
> ping -c 3 google.com                        # Verify connectivity
> ```

## 1.3. Partition & Mount

```bash
lsblk                    # List all block devices and partitions
cgdisk /dev/nvme0n1      # Inspect partition layout in detail
```

Assuming the following layout (adjust device names to match your machine):
- `/dev/nvme0n1p4` — Root partition for Arch (~240 GB)
- `/dev/nvme0n1p3` — Dedicated EFI partition for Arch (~700 MB)

```bash
# Mount Root
mount /dev/nvme0n1p4 /mnt

# Create mount points
mkdir -p /mnt/{home,boot}

# Mount EFI → /boot
mount /dev/nvme0n1p3 /mnt/boot

# Verify
lsblk
```

## 1.4. Install the Base System & Chroot

```bash
# Install the base system, kernel, firmware, and build tools
pacstrap -K /mnt base linux linux-firmware base-devel

# Generate fstab using UUIDs (resilient to disk reordering)
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab    # Double-check the output

# Enter the new system
arch-chroot /mnt
```

## 1.5. Core Configuration (Inside Chroot)

### Create User & Set Passwords
```bash
passwd                                          # Set the root password
useradd -g users -m -s /bin/bash neitnd          # Create your user
passwd neitnd                                    # Set the user password
```

### Grant Sudo Privileges
```bash
pacman -S nano                                   # Install a text editor
nano /etc/sudoers.d/neitnd
```
Write the following line:
```text
neitnd ALL=(ALL:ALL) ALL
```

> **Alternative method (via wheel group):**
> ```bash
> sudo useradd -m -g users -G wheel neitnd
> sudo passwd neitnd
> sudo EDITOR=nano visudo
> # → Find the line "# %wheel ALL=(ALL:ALL) ALL" and remove the leading #
> ```

### Locale, Timezone & Hostname
```bash
# Locale
nano /etc/locale.gen
# → Find "en_US.UTF-8 UTF-8", remove the leading #
locale-gen
nano /etc/locale.conf
# → Add: LANG=en_US.UTF-8

# Timezone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

# Hostname
nano /etc/hostname
# → Type your hostname, e.g.: arch-lig3
```

## 1.6. Install Bootloader (rEFInd) & NetworkManager

```bash
pacman -S networkmanager refind git
refind-install
systemctl enable NetworkManager
```

### Configure Boot Entry with UUID
```bash
lsblk -f
# → Copy the UUID of your Root partition (the one mounted at /)

nano /boot/refind_linux.conf
# → Replace "root=/dev/nvme..." with "root=UUID=<your-uuid>"
# Example: "Boot with standard options"  "rw root=UUID=a1b2c3d4-... quiet"
```

### Finish & Reboot
```bash
exit
umount -R /mnt
reboot
```

## 1.7. After First Reboot

Boot into Arch from rEFInd. Log in with your user.

```bash
# Refresh rEFInd config
sudo rm -rf /boot/refind_linux.conf
sudo mkrlconf
ls -la /boot

# Connect to Wi-Fi
nmtui

# Install AUR Helper (Yay)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~
```

---

# Part 2: NVIDIA Driver & Secure Boot

## 2.1. Install NVIDIA Driver

```bash
# Install DKMS (Dynamic Kernel Module Support) for automatic driver rebuilds on kernel updates
yay -S dkms

# Configure signing keys for DKMS (required if using Secure Boot)
sudo nano /etc/dkms/framework.conf
# → Uncomment the sign_tool line pointing to your security keys

# Install the NVIDIA driver stack
# If version mismatch errors occur, run: yay -Syu && yay -S linux linux-headers
yay -S nvidia-dkms nvidia-utils libva-nvidia-driver linux-headers
sudo dkms autoinstall
```

### Configure Initramfs for NVIDIA
```bash
sudo nano /etc/mkinitcpio.conf
# → Find the line MODULES=() and change it to:
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

sudo mkinitcpio -P    # Rebuild initramfs with the new modules
```

### Add Kernel Parameters for rEFInd
```bash
sudo nano /boot/refind_linux.conf
# → Append to the end of the "Boot with standard options" line:
# nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

### Verify
```bash
lsmod | grep nvidia    # You should see: nvidia, nvidia_modeset, nvidia_drm, nvidia_uvm
```

## 2.2. Set Up Secure Boot with sbctl

> **Before starting:** Boot into Windows → open *Manage BitLocker* → **Suspend protection** on the C: drive to prevent lockout.

### Step 1: Put BIOS into "Setup Mode"
1. Reboot → press `F2` to enter BIOS.
2. Go to *Security* → *Secure Boot* → *Clear All Secure Boot Keys* → *Yes*.
3. Status should change to *Setup Mode*. Press `F10` to save → boot into Arch.

### Step 2: Create Keys & Sign Binaries
```bash
sudo pacman -S sbctl
sbctl status                # Must show: "Setup Mode: ✔ Enabled"

# Create your own signing keys
sudo sbctl create-keys
sudo sbctl enroll-keys -m   # -m: keep Microsoft keys so Windows can still boot

# List unsigned files
sudo sbctl verify

# Sign each boot binary (-s flag = auto-re-sign on OS updates)
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/EFI/refind/refind_x64.efi
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI

# Verify — all entries must show ✔
sudo sbctl verify
```

### Step 3: Enable Secure Boot
Reboot → BIOS → *Security* → *Secure Boot* → **Enabled** → `F10` to save.

---

# Part 3: Desktop Environment (Hyprland + UWSM + SDDM)

## 3.1. Install Hyprland & Related Packages

### Group 1: Hyprland Core
```bash
yay -S hyprland hyprlock hypridle hyprpolkitagent \
       xdg-desktop-portal-hyprland xdg-desktop-portal-gtk uwsm
```

### Group 2: Status Bar, Notifications, Launcher
```bash
yay -S waybar swaync rofi-wayland
```

### Group 3: Wallpaper, Clipboard, Screenshot
```bash
yay -S awww wl-clipboard cliphist grim slurp
```

### Group 4: File Manager & Support Libraries
```bash
yay -S thunar thunar-volman thunar-archive-plugin tumbler ffmpegthumbnailer \
       gvfs polkit dbus gnome-keyring wget
```

### Group 5: Terminal, Shell, Fonts
```bash
yay -S kitty zsh fastfetch htop cozette-otb ipa-fonts noto-fonts tmux
```

### Group 6: Browser & Editors
```bash
yay -S firefox
yay -S visual-studio-code-bin    # Official Microsoft VS Code
yay -S sublime-text-4
```

### Group 7: Display, Brightness, Appearance
```bash
yay -S nwg-displays brightnessctl nwg-look
```

## 3.2. Download & Apply Dotfiles

```bash
cd ~
git clone https://github.com/HighDelay/dotfiles.git
cd dotfiles/
cp -rv .* ~/
cd ~
rm -rf .git    # Remove the dotfiles repo's .git — not your own
```

## 3.3. First Launch of Hyprland

Launch command: `start-hypland` or `Hyprland` (never use `sudo`).

### Fix Black Screen on NVIDIA
```bash
nano ~/.zprofile
```
Add:
```bash
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec start-hypland
fi
```

### Minimal Config (if still failing)
```bash
mkdir -p ~/.config/hypr
cat <<EOF > ~/.config/hypr/hyprland.conf
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

cursor {
    no_hardware_cursors = true
}

monitor=,preferred,auto,auto
bind = SUPER, Q, exec, kitty
bind = SUPER, M, exit
EOF
```

## 3.4. Display Manager: SDDM (X11 with Intel Only)

SDDM is used with the Catppuccin Mocha theme for a beautiful, auto-focused login screen. To ensure SDDM's X11 server does not wake the NVIDIA GPU (which saves battery), we explicitly configure Xorg to only see the Intel GPU.

### Install
```bash
yay -S sddm xorg-server qt5-graphicaleffects qt5-quickcontrols2 qt5-svg
```

### Configure Xorg (Force Intel GPU)
Create a config to block NVIDIA and use the Intel device:
```bash
sudo mkdir -p /etc/X11/xorg.conf.d
sudo bash -c 'cat << EOF > /etc/X11/xorg.conf.d/10-intel-sddm.conf
Section "ServerFlags"
    Option "AutoAddGPU" "false"
EndSection

Section "Device"
    Identifier  "Intel Graphics"
    Driver      "modesetting"
    BusID       "PCI:0:2:0"
EndSection
EOF'
```

### Install Custom SDDM Theme
We use a customized version of the Catppuccin theme (with a dropdown user selector and repositioned buttons) which is included in this repository.

Copy it to the system themes directory:
```bash
sudo cp -r ~/neitnd_dotfiles/my-sddm-theme /usr/share/sddm/themes/
```

### Configure SDDM
Edit `/etc/sddm.conf` to use the custom theme:
```bash
sudo bash -c 'cat << EOF > /etc/sddm.conf
[Theme]
Current=my-sddm-theme
EOF'
```

### Enable the Service
```bash
sudo systemctl enable sddm.service
```

> **GNOME Keyring management:** Install `seahorse` (`sudo pacman -S seahorse`) for a GUI to view, edit, or delete stored passwords. If you change your Linux login password, you must also update the keyring password inside Seahorse.

## 3.5. Configure UWSM & Hyprland Services

### Move Environment Variables to UWSM
Create `~/.config/uwsm/env`:
```bash
mkdir -p ~/.config/uwsm
nano ~/.config/uwsm/env
```
Contents:
```bash
XCURSOR_SIZE=24
QT_QPA_PLATFORMTHEME=qt6ct      # Must use qt6ct, not qt5ct
GVIM_ENABLE_WAYLAND=1

XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland

# NVIDIA
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
```

### Standard Startup Lines in hyprland.conf
Replace old `dbus-update-activation-environment` and `systemctl --user import-environment` lines with:
```bash
# --- Startup (UWSM-compliant) ---
exec-once = uwsm app -- waybar
exec-once = uwsm app -- swaync
exec-once = systemctl --user start hyprpolkitagent
exec-once = uwsm app -- awww-daemon --quiet
exec-once = uwsm app -- awww img $HOME/.config/wallpaper_custom/window11_wallpaper_ani.jpg
exec-once = uwsm app -- easyeffects --gapplication-service
exec-once = uwsm app -- wl-paste --type text --watch cliphist store
exec-once = uwsm app -- wl-paste --type image --watch cliphist store
exec-once = uwsm app -- fcitx5
```

> **UWSM Rule of Thumb:** Wrap all long-running graphical apps with `uwsm app --`. Short-lived trigger commands (e.g. `swaync-client -t`, `brightnessctl`, `wpctl`) do NOT need wrapping.

### Enable Systemd User Services
Apps that ship their own `.service` files should be managed by systemd:
```bash
systemctl --user enable --now hyprpolkitagent.service
systemctl --user enable --now pipewire.service
systemctl --user enable --now swaync.service
systemctl --user enable --now waybar.service
systemctl --user enable --now wireplumber.service
systemctl --user enable --now hypridle.service
```

Verify:
```bash
systemctl --user list-unit-files --type=service --state=enabled
```

## 3.6. Configure Rofi to Launch Apps via UWSM

Open `~/.config/rofi/config.rasi`, add inside the `configuration {}` block:
```rasi
run-command: "uwsm app -- {cmd}";
```
This ensures every app launched from Rofi is properly sandboxed by UWSM.

---

# Part 4: Audio, Multimedia & Bluetooth

## 4.1. Audio (PipeWire + EasyEffects)

```bash
yay -S pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack
yay -S easyeffects lsp-plugins
```

### Microphone Noise Cancellation
1. Open EasyEffects from Rofi.
2. Switch to the **Input** tab → **Add Effect** → select **RNNoise** (neural noise removal).
3. Open `pavucontrol` (Volume Control) → **Input Devices** tab → set EasyEffects as the default input device.

### Fix: EasyEffects Shows No Signal
Open EasyEffects Settings → manually select your specific input/output devices instead of "Default" or "Auto".

## 4.2. Brightness & Volume Keys

```bash
yay -S brightnessctl    # Already included above
```

Hotkeys are configured in `hyprland.conf`:

| Shortcut | Function |
|---|---|
| `Super+Shift+U` | Volume Up |
| `Super+Shift+D` | Volume Down |
| `Super+Ctrl+U` | Brightness Up |
| `Super+Ctrl+D` | Brightness Down |
| `XF86MonBrightnessUp/Down` | Physical brightness keys |
| `XF86AudioRaiseVolume/Lower/Mute` | Physical volume keys |

## 4.3. Bluetooth

```bash
sudo pacman -S bluez bluez-utils blueman
```
Open Blueman from Rofi to pair/connect devices.

**Enable Bluetooth Headset Microphone:** Right-click the device in Blueman → select the **Head Set** profile.

## 4.4. Laptop Camera

```bash
ls /dev/video*                      # Verify hardware (make sure the physical camera switch is ON)
sudo usermod -aG video $USER        # Grant video device access
```
Test on any web-based camera test site.

---

# Part 5: Tools & Utilities

## 5.1. Vietnamese Input (Fcitx5 + Bamboo)

```bash
yay -S fcitx5-bamboo fcitx5-im
```

Configuration:
1. Open `fcitx5-configtool` from Rofi.
2. In the right column → untick *Only Show Current Language* → search "bamboo" → add it to the left column.
3. Order: `Keyboard - English (US)` → `Bamboo`.
4. To use VNI instead of Telex: right-click on Bamboo in the tray → select VNI.

Switch language: **Ctrl + Space**.

## 5.2. Dual-Boot Time Synchronization

Windows uses local time for the hardware clock; Linux defaults to UTC. Fix it for dual-boot:
```bash
sudo ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
timedatectl set-local-rtc 1 --adjust-system-clock    # Use local time (Windows-compatible)
sudo hwclock --systohc
sudo timedatectl set-ntp true                          # Enable NTP sync
timedatectl                                            # Verify
```

## 5.3. Zsh & Powerlevel10k

1. Install Oh My Zsh (follow the official site, use `curl`).
2. Install plugins:
   ```bash
   # zsh-autosuggestions — suggests commands as you type (grey text)
   git clone https://github.com/zsh-users/zsh-autosuggestions \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

   # zsh-syntax-highlighting — colors valid/invalid commands in real time
   git clone https://github.com/zsh-users/zsh-syntax-highlighting \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

   # zsh-completions — extra tab-completion definitions
   git clone https://github.com/zsh-users/zsh-completions \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

   # powerlevel10k — beautiful, fast prompt theme
   git clone --depth=1 https://github.com/romkatv/powerlevel10k \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
   ```
3. Edit `~/.zshrc`:
   ```bash
   ZSH_THEME="powerlevel10k/powerlevel10k"
   plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
   # Place this line ABOVE "source $ZSH/oh-my-zsh.sh":
   fpath+=(<path-to-zsh-completions>/src $fpath)
   ```
4. Open a new terminal → the p10k configuration wizard will launch automatically.

### ZSH Enhancements Already Applied
- **History substring search:** Type part of a command (e.g. `pacman`) then press **Up/Down arrows** to filter through matching history entries.
- **Word-by-word cursor navigation:** `Ctrl + Left/Right Arrow` jumps the cursor one word at a time.
- **Modern aliases:** `ls`/`ll`/`la` auto-use `eza` (colorful icons, directory grouping); `cat` auto-uses `bat` (syntax highlighting).
- **Vi mode:** `bindkey -v` in `.zshrc`. The `Ctrl+R` history search is restored via explicit `bindkey '^R' history-incremental-search-backward`.

## 5.4. Sublime Text — Multi-Window Support

By default, Sublime Text reuses a single window. To open a new window when the app is already running:
```bash
mkdir -p ~/.local/share/applications/
cp /usr/share/applications/sublime-text.desktop ~/.local/share/applications/
nano ~/.local/share/applications/sublime-text.desktop
```
Replace the first `Exec` line with:
```bash
Exec=bash -c 'if pgrep -x "sublime_text" > /dev/null; then /usr/bin/subl -n "%F"; else /usr/bin/subl "%F"; fi'
```

## 5.5. Chrome — Middle-Click Autoscroll

```bash
nano ~/.config/chrome-flags.conf
```
Add:
```
--enable-blink-features=MiddleClickAutoscroll
```

## 5.6. Remote Access (SSH & Remote Desktop)

### Terminal (CLI) — SSH Server
```bash
sudo pacman -S openssh
sudo systemctl enable --now sshd
ip a      # Find your IP address (e.g., 192.168.x.x)
```
On your other machine, connect using:
```bash
ssh username@192.168.x.x
```
#### Securing SSH (Disable Password Login)
To prevent brute-force attacks, it is highly recommended to use **SSH Keys** instead of passwords.

**Step 1: Generate a Key Pair (Run on your CLIENT machine)**
Run this on the machine you are connecting *from* (e.g., Windows PC, Mac, or another Linux):
```bash
ssh-keygen -t ed25519
```
Press Enter to accept defaults. This creates a public key (`id_ed25519.pub`) and a private key (`id_ed25519`).

**Step 2: Copy the Public Key to the Arch Server (Run on your CLIENT machine)**
```bash
ssh-copy-id neitnd@192.168.x.x
```
*(Note: If you are using Windows CMD where `ssh-copy-id` isn't available, you can copy the contents of `C:\Users\YourUser\.ssh\id_ed25519.pub` and paste it into `~/.ssh/authorized_keys` on your Arch server).*

**Step 3: Disable Password Authentication (Run on the Arch SERVER)**
Once you verify that `ssh neitnd@192.168.x.x` logs you in automatically *without* asking for a password, edit the SSH config on Arch:
```bash
sudo nano /etc/ssh/sshd_config
```
Find the line `PasswordAuthentication` (remove the `#` at the beginning if there is one) and set it to `no`:
```ini
PasswordAuthentication no
```

**Step 4: Restart SSH Service**
```bash
sudo systemctl restart sshd
```
Your server is now immune to password guessing attacks!

### Remote (Internet) — SSH via Tailscale (Zero-Config VPN)
To SSH into your Arch machine from anywhere in the world **without** opening router ports (which is insecure and often blocked by ISPs), the industry standard is **Tailscale**. It creates a secure, private network between your devices.

1. **Install and Enable on Arch Server:**
```bash
sudo pacman -S tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
```
*(This will provide a link in the terminal. Open it in a browser to log in. Once logged in, your Arch machine gets a static, private IP like `100.x.y.z`)*

2. **Connect from your Client:**
Install Tailscale on your phone, Windows, or Mac. Log in with the same account.
Find the Arch machine's Tailscale IP (`100.x.y.z`) in the Tailscale app, then connect:
```bash
ssh neitnd@100.x.y.z
```

### Local (LAN) — WayVNC
```bash
sudo pacman -S wayvnc
wayvnc 0.0.0.0                    # Keep terminal open while connected
ip a                               # Find your local IP
```
On your phone: install a VNC Viewer app → enter the IP → connect.

### Remote (Internet) — RustDesk
```bash
# Install the correct XDG portal stack
sudo pacman -Rns xdg-desktop-portal-gnome xdg-desktop-portal-kde xdg-desktop-portal-wlr
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

Configure portal priorities (`~/.config/xdg-desktop-portal/portals.conf`):
```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.RemoteDesktop=hyprland
```

Configure Hyprland's screencopy (`~/.config/hypr/xdph.conf`):
```ini
screencopy {
    max_fps = 60
    allow_token_by_default = true
}
```

Fix repeated screen-picker prompts by running RustDesk in the tray:
```bash
# Add to hyprland.conf:
exec-once = uwsm app -- rustdesk --tray
```
On first connection → tick "Remember this selection" → subsequent connections will be automatic.

## 5.7. Rofi File Finder (Super + Shift + F)

A custom script at `~/.config/hypr/scripts/rofi-finder.sh` provides a fast file search:
- **Recent files first:** Reads `~/.local/share/recently-used.xbel` and pins the 25 most recent files to the top of results.
- **Real-time search with `fd`:** Scans `$HOME` in parallel (excludes `.git`, `node_modules`, `.vscode`, etc.), processing 10,000+ files instantly.

| Key | Action | Description |
|---|---|---|
| `Enter` | **Open default** | Uses `gio open` (same as Thunar — .conf opens in editor, images in viewer, folders in Thunar) |
| `Alt + D` | **Open parent folder** | Opens Thunar at the file's location |
| `Alt + T` | **Open terminal here** | Opens Kitty in the file's directory |
| `Alt + E` | **Open in editor** | Opens Neovim for quick editing |

## 5.8. Super Live Grep (Super + Shift + G)

Searches inside file contents in real time using `ripgrep` and `fzf` via a 4-Stage Wizard. Useful when you know what a file contains but not its name.
Features:
- Toggle support (Press `Super + Shift + G` to open, and again to close).
- Step 1: Select root directory (ignores system caches by default but allows searching in `.config`).
- Step 2: Multi-select specific file types (`conf`, `lua`, `python`, etc.).
- Step 3: Smart ignore toggles.
- Step 4: Live search with syntax-highlighted preview (`bat`).

Hold SHIFT to use mouse and copy in that interface (kitty)

### Adding Custom Ignores / File Types
The script is located at `~/.config/hypr/scripts/live-grep.sh`.
If you encounter massive unneeded folders in the future (e.g., Docker volumes, Android Studio caches), you should manually add them to the script to keep Live Grep lightning fast.

**To add a new hard-ignored folder:**
1. Open `~/.config/hypr/scripts/live-grep.sh`.
2. Find the variable `RG_IGNORE_OPTS` inside the `# Bỏ qua các rác hệ thống vĩnh viễn` section.
3. Append `-g '!.tên_thư_mục/*'` to the string.
   *(Suggestions for future ignores if you install them: `!.android/*`, `!.npm/*`, `!.java/*`, `!.gradle/*`, `!.docker/*`)*

**To add a new File Type option:**
1. Find the `TYPE_SELECTION` variable.
2. Add your extension to the echo string (e.g., `\nphp` or `\nxml`).

## 5.9. Dotfile Management with Stow

```bash
sudo pacman -S stow
```

### Backup .config
```bash
mkdir -p ~/neitnd_dotfiles/.config && cd ~/neitnd_dotfiles && \
for item in hypr waybar cmus htop swaync rofi kitty wallpaper_custom fastfetch \
            MangoHud easyeffects fcitx5 nwg-displays chrome-flags.conf mimeapps.list \
            mpd rustdesk xdg-desktop-portal uwsm sublime-text; do
  [ -e ~/.config/"$item" ] && [ ! -L ~/.config/"$item" ] && [ ! -e .config/"$item" ] && \
  mv ~/.config/"$item" .config/
done && stow .
```

### Backup .local
```bash
mkdir -p ~/neitnd_dotfiles/.local/share && cd ~/neitnd_dotfiles && \
[ -e ~/.local/share/fonts ] && [ ! -L ~/.local/share/fonts ] && \
[ ! -e .local/share/fonts ] && mv ~/.local/share/fonts .local/share/ && stow .
```

### Backup dotfiles in $HOME
```bash
cd ~/neitnd_dotfiles && \
for item in .zshrc .p10k.zsh .zprofile .gitconfig .vimrc; do
  [ -e ~/"$item" ] && [ ! -L ~/"$item" ] && [ ! -e "$item" ] && mv ~/"$item" ./ && stow .
done
```

### EasyEffects Preset
```bash
# Presets live in ~/.local/share/easyeffects/output/ (NOT .config)
mkdir -p ~/neitnd_dotfiles/.local/share/easyeffects/output/
cp ~/dotfiles/easyeffects-presets/HighDelay\'s\ EZFx\ Preset.json \
   ~/neitnd_dotfiles/.local/share/easyeffects/output/
cd ~/neitnd_dotfiles && stow .
```

### Stow Ignore File
```bash
echo -e "\\.git\n\\.gitignore\n\\.stow-local-ignore\nREADME\\.md\narch_install\\.md\nsystem_guide\\.md" \
  > ~/neitnd_dotfiles/.stow-local-ignore
cd ~/neitnd_dotfiles && stow -R .
```

> **Note:** `stow -R .` recreates symlinks but may not remove old symlinks that are now ignored. Manually delete them if found (e.g. `rm -f ~/.git` if it is a symlink).

## 5.10. Wi-Fi Hotspot

```bash
yay -S linux-wifi-hotspot
sudo pacman -S dnsmasq hostapd
```
- Check your Wi-Fi card: `nmcli device`
- Check simultaneous AP+STA support: `iw list | grep -A 10 "valid interface combinations"`
- **IdeaPad Gaming 3 limitation:** Only `channel <= 1` → set the hotspot channel to match the channel of the Wi-Fi network you are already connected to., and look like my latop can only share wifi 2.4Ghz, so i need to go to `Edit Connection...` (network-manager-applet to edit current dual bands wifi to specific 2.4ghz by edit it BSSID and Chanel to 2.4Ghz, 
- View current channel and 2.4Ghz wifi BSSID: `nmcli device wifi`

## 5.11. Cloud Storage Sync (OneDrive & Google Drive)

> **Dual-Boot Warning:** Never point Linux sync clients directly to the existing NTFS Windows sync folder. Due to independent database states and file system metadata differences (ext4 vs NTFS), this can cause severe data loss, conflict loops, or duplicate files. Always use separate local sync folders for Linux.

### OneDrive (abraunegg's client)
The ultimate 2-way offline sync daemon for OneDrive on Linux.

1. **Install & Authenticate:**
   ```bash
   yay -S onedrive-abraunegg
   onedrive
   ```
   *Follow the prompts to sign in and paste the redirect URL.*

2. **Selective Sync (Optional):**
   ```bash
   mkdir -p ~/.config/onedrive
   nano ~/.config/onedrive/sync_list
   ```
   Example for sync_list (root folders):
  ```bash
  Documents
  Music
  Pictures
  Videos
  ```
3. **Resync & Enable Daemon:**
   ```bash
   onedrive --sync --resync
   systemctl --user enable --now onedrive
   ```
`systemctl --user disable onedrive.service`
`systemctl --user edit onedrive.service`

Write this to make it turn off gracefully with graphical turned off.
```bash
[Unit]
PartOf=graphical-session.target
OnFailure=onedrive-failure.service

[Service]
ExecStartPre= #fix lag time when hyprland up and uwsm have to wait 15s (default of onedrive) for onedrive up
KillSignal=SIGINT
SuccessExitStatus=SIGINT 2
```
Create `~/.config/systemd/user/onedrive-failure.service`:
```
[Unit]
Description=Notify on onedrive failure
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u critical -i dialog-error "OneDrive Lỗi" "OneDrive Client bị crash hoặc gặp lỗi!\nKiểm tra: journalctl --user -u onedrive -n 20"
```
Check if it overide successfully: `systemctl --user daemon-reload && systemctl --user show onedrive.service | grep OnFailure`
`systemctl --user daemon-reload`


4. **How to Update Sync List Later:**
   If you modify `~/.config/onedrive/sync_list` to add or remove folders, you MUST resync and restart the service:
   ```bash
   systemctl --user stop onedrive.service
   onedrive --sync --resync
   systemctl --user start onedrive.service
   ```

5. **Error check:**
`journalctl --user -u onedrive.service -e -f`

### Google Drive (Rclone)
Rclone is extremely powerful but requires manual setup. You can choose to either **Mount as a Network Drive** (saves space, requires internet) or use **2-Way Offline Sync** (acts like OneDrive).

#### 1. Generate Google Cloud Credentials (Client ID & Secret)
To avoid rate limits and connection issues, you must create your own Google API project.
1. Go to the [Google Cloud Console](https://console.cloud.google.com/). Create a new project.
2. Search for "Google Drive API" and click **Enable**.
3. **OAuth Consent Screen (Branding):**
   - Click *OAuth consent screen* on the left menu.
   - User Type: *External*.
   - App name: `rclone`, User support email: *your email*, Developer contact: *your email*.
   - Click *Save and Continue*.
4. **Test Users (Audience):**
   - Click *Add Users* and enter your exact Google Drive email address.
   - **CRITICAL:** To prevent the token from expiring every 7 days, click **PUBLISH APP** on the OAuth consent screen. (Ignore Google's verification warnings since you are the only user).
5. **Data Access (Scopes):**
   - Click *Add or Remove Scopes*.
   - Select the scope with `.../auth/drive` (Full access to all files).
   - Click *Update* then *Save and Continue*.
6. **Create Credentials (Clients):**
   - Go to *Credentials* on the left menu.
   - Click *+ CREATE CREDENTIALS* → *OAuth client ID*.
   - Application type: *Desktop app*.
   - Click *Create*. Copy the generated **Client ID** and **Client Secret**.

#### 2. Configure Rclone
```bash
sudo pacman -S rclone
rclone config
```
Follow the interactive prompts:
- `n` (New remote) → name it `gdrive`.
- Type the number for Google Drive (usually `18` or `19` or `24`).
- **client_id:** Paste your Client ID here.
- **client_secret:** Paste your Client Secret here.
- **scope:** `1` (Full access).
- Leave `service_account_file` and advanced config blank (press Enter).
- **Use web browser to automatically authenticate:** `y`. Log in to your Google account and grant permission.
- **Configure this as a Shared Drive:** `n`.
- Finally, type `y` to confirm and `q` to quit.

#### Option A: Network Mount (Space Saving)
Mounts Google Drive directly into your file manager without taking up local disk space.
1. Create a systemd service to auto-mount on boot:
   ```bash
   mkdir -p ~/.config/systemd/user/
   nano ~/.config/systemd/user/rclone-gdrive.service
   ```
2. Add the following (if targeting a specific folder in the "Computers" tab, use its Folder ID from the web URL; you need to create GDrive/ folder):
   ```ini
   [Unit]
   Description=Rclone Mount Google Drive
   After=network-online.target
   Wants=network-online.target
   PartOf=graphical-session.target

   [Service]
   Type=simple
   ExecStart=/usr/bin/rclone mount gdrive: %h/GDrive --drive-root-folder-id "YOUR_FOLDER_ID" --vfs-cache-mode full
   ExecStop=/usr/bin/fusermount3 -u %h/GDrive
   ProtectSystem=full
   ProtectHostname=true
   ProtectKernelTunables=true
   ProtectControlGroups=true
   RestrictRealtime=true
   Restart=on-failure
   RestartSec=5
   TimeoutStopSec=90

   [Install]
   WantedBy=graphical-session.target

   ```
3. Enable and start the service:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now rclone-gdrive.service
   ```
To stop and move to Option B:
   ```bash
   systemctl --user disable --now rclone-gdrive.service
   ```

#### Option B: Offline 2-Way Sync (Like OneDrive)
Use `rclone bisync` coupled with a systemd timer. **Do not run this on a folder that is currently mounted!**
1. **First Sync (Resync):**
You need to create /GDrive_bisync folder
   ```bash
   mkdir -p ~/GDrive_bisync
   rclone bisync gdrive: ~/GDrive_bisync --drive-root-folder-id "YOUR_FOLDER_ID" --exclude "/YOUR_EXCLUDE_FOLDER/**" --exclude "/YOUR_EXCLUDE_FOLDER/**" --resync -v --drive-acknowledge-abuse
   ```
2. **Automate via Systemd Timer (Every 5 minutes):**
   Create `~/.config/systemd/user/rclone-bisync.service`:
```ini
[Unit]
Description=Rclone 2-way Sync for Google Drive
After=network-online.target
Wants=network-online.target
PartOf=graphical-session.target
OnFailure=rclone-bisync-failure.service

[Service]
Type=oneshot
ExecStart=/usr/bin/rclone bisync gdrive: %h/GDrive_bisync --drive-root-folder-id "YOUR_FOLDER_ID" --exclude "/YOUR_EXCLUDE_FOLDER/**" --exclude "/YOUR_EXCLUDE_FOLDER/**" -q --drive-acknowledge-abuse
ProtectSystem=full
ProtectHostname=true
ProtectKernelTunables=true
ProtectControlGroups=true
RestrictRealtime=true
SuccessExitStatus=143
TimeoutStopSec=90
```
Create `~/.config/systemd/user/rclone-bisync.timer`:
```ini
[Unit]
Description=Run Rclone Bisync every 5 minutes
PartOf=graphical-session.target
[Timer]
OnActiveSec=1min
OnUnitActiveSec=5min
Unit=rclone-bisync.service
[Install]
WantedBy=graphical-session.target
```
To start it manually: `systemctl --user start rclone-bisync.service`
Create `~/.config/systemd/user/rclone-bisync-falure.service` for norification:
```bash
[Unit]
Description=Notify on rclone-bisync failure
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=/usr/bin/notify-send -u critical -i dialog-error "Rclone Bisync Lỗi" "Đồng bộ GDrive thất bại!\nNếu lỗi liên tục, chạy:\nrclone bisync gdrive: ~/GDrive_bisync --drive-root-folder-id "YORU_FOLDER_ID" --exclude "/YOUR_EXCLUDE_FOLDER/**" --exclude "/YOUR_EXCLUDE_FOLDER/**" -P -v --drive-acknowledge-abuse --resync"

```
3. Enable it:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now rclone-bisync.timer
   ```

4. **How to Update Exclude Rules Later:**
   If you want to add or remove `--exclude` rules, you CANNOT just edit the service file. Changing filters causes a database mismatch in Bisync. You MUST manually resync:
   1. Stop the timer: `systemctl --user stop rclone-bisync.timer`
   2. Edit your `~/.config/systemd/user/rclone-bisync.service` to update the `--exclude` flags.
   3. Apply changes: `systemctl --user daemon-reload`
   4. **CRITICAL:** Run the MANUAL terminal command (from Step 1) using your NEW `--exclude` flags and the `--resync` flag.
   5. Once the manual resync finishes successfully, turn the timer back on: `systemctl --user start rclone-bisync.timer`

5. **Error check:**
`journalctl --user -u rclone-bisync.service -e -f`

## 5.12. Default app for picture, audio, video, pdf, text,..
picture: imv
video and audio: mpv
pdf: browser
text: nvim, sublimetext

## 5.13. Install Obsidian and OBS Studio
Both Obsidian and OBS Studio are available in the official Arch repositories and work great on Wayland natively.

```bash
sudo pacman -S obsidian obs-studio
```

*(Note: OBS Studio on Hyprland/Wayland uses `xdg-desktop-portal-hyprland` and `pipewire` for screen capturing. You also **MUST** install `hyprland-guiutils` (the UI dialog for selecting screens/windows): `sudo pacman -S hyprland-guiutils`. You can just open OBS, add a "Screen Capture (PipeWire)" source, and click "Open Selector" to pick a screen or a specific window!)*

### Enable OBS Virtual Camera (for Zoom, Meet, etc.)
To use OBS as a camera in Zoom or Google Meet, you need to install and load the `v4l2loopback` kernel module:
1. Install packages: `sudo pacman -S v4l2loopback-dkms linux-headers`
2. Auto-load the module on boot by creating these two files:
   ```bash
   echo "v4l2loopback" | sudo tee /etc/modules-load.d/v4l2loopback.conf
   echo "options v4l2loopback devices=1 video_nr=10 card_label=\"OBS Virtual Camera\" exclusive_caps=1" | sudo tee /etc/modprobe.d/v4l2loopback.conf
   ```
   or remove it:
   `sudo rm -f /etc/modules-load.d/v4l2loopback.conf`
3. Load it right now without rebooting:
   ```bash
   sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="OBS Virtual Camera" exclusive_caps=1
   ```
Restart OBS, and the **"Start Virtual Camera"** button will appear!

### Conflict between OBS Studio and RustDesk Unattended Access
If you use RustDesk for remote access, you might have configured an auto-bypass script (`auto_share.sh`) in `~/.config/hypr/xdph.conf`.
- **When the script is ENABLED:** RustDesk works perfectly without human interaction, but OBS Studio will **NOT** show the UI dialog (it auto-selects the main screen and hides the Window sharing feature).
- **When the script is DISABLED:** OBS Studio works perfectly with the UI dialog, but RustDesk will require someone sitting at the computer to click "Share" when you connect remotely.

To toggle between these two modes, edit `~/.config/hypr/xdph.conf` and comment/uncomment this line:
```ini
screencopy {
    # Uncomment the line below for RustDesk unattended, comment it out for OBS UI picker
    # custom_picker_binary = /home/neitnd/.config/hypr/scripts/auto_share.sh
}
```
**CRITICAL:** Every time you modify `xdph.conf`, you MUST run the following command to apply the changes:
```bash
systemctl --user restart xdg-desktop-portal-hyprland
```

## 5.14. Keyboard-driven Mouse (Mouseless)

`mouseless` is a Wayland-native, daemon-based tool that intercepts keys at the `/dev/input/` level, allowing full mouse control without crashing Hyprland protocols.

### 1. Install & Configure Permissions
```bash
yay -S mouseless-bin
# Grant your user permission to read keyboard events
sudo usermod -aG input $USER
# Allow the input group to create virtual mice via uinput
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-uinput.rules > /dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger
```
**CRITICAL:** You must Logout and Login again (or Reboot) for the `input` group permissions to apply.

### 2. Configuration (`~/.config/mouseless/config.yaml`)
Create the config file to use `Capslock` as a `tap-hold` toggle:
- **Tap Capslock:** Toggles normal uppercase functionality.
- **Hold Capslock:** Enters Mouse Mode (Momentary). Release Capslock to exit. (Previously: Hold 400ms to toggle permanently).

```yaml
baseMouseSpeed: 750.0
baseScrollSpeed: 20.0
mouseAccelerationTime: 200.0
mouseAccelerationCurve: 2.0

layers:
- name: initial
  bindings:
    # --- Cấu hình cũ (Giữ 400ms để khóa chết mouse mode) ---
    # Tap for normal capslock, hold for 400ms to enter mouse mode
    # capslock: tap-hold capslock ; layer mouse ; 400
    
    # --- Cấu hình mới (Tap để bật/tắt Capslock, Giữ để kích hoạt chuột) ---
    capslock: tap-hold capslock ; toggle-layer mouse ; 150
    
    # Prevent default esc behavior to stop notification spam
    esc: esc
- name: mouse
  passThrough: true
  bindings:
    # --- Cấu hình cũ (Bấm phím để thoát mouse mode) ---
    # Exit mouse mode
    # capslock: layer initial
    # esc: layer initial
    # enter: layer initial

    # Movement
    l: move  1  0
    h: move -1  0
    k: move  0 -1
    j: move  0  1
    
    # Scrolling
    u: scroll up
    i: scroll down

    # Speeds
    f: speed 4.0
    s: speed 0.3

    # Clicks
    space: button left
    semicolon: button right
    apostrophe: button middle
```

### 3. Create & Enable Systemd Service
The AUR package `mouseless-bin` does not provide a systemd service file by default. You must create it manually:

```bash
mkdir -p ~/.config/systemd/user
cat << 'EOF' > ~/.config/systemd/user/mouseless.service
[Unit]
Description=Mouseless keyboard-driven mouse
After=graphical-session.target

[Service]
ExecStart=/bin/bash -c 'set -o pipefail; state="OFF"; /usr/bin/mouseless -d 2>&1 | while read -r line; do echo "$line"; if [[ "$line" == *"Switching to layer mouse"* ]]; then if [[ "$state" != "ON" ]]; then notify-send -a "Mouseless" -t 1000 "Mouse Mode" "ON"; state="ON"; fi; elif [[ "$line" == *"Switching to layer initial"* ]]; then if [[ "$state" != "OFF" ]]; then notify-send -a "Mouseless" -t 1000 "Mouse Mode" "OFF"; state="OFF"; fi; fi; done'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now mouseless
```

## 5.15. TTY Mouse Support (GPM)
To use the mouse for selecting, copying, and pasting text in the raw TTY (Virtual Console), install and start the General Purpose Mouse (GPM) daemon:
```bash
sudo pacman -S gpm
sudo systemctl enable --now gpm
```
*Usage:* In a TTY (`Ctrl+Alt+F2`), highlight text by dragging the left mouse button. To paste, press the middle mouse button.

## 5.16. Tmux (Terminal Multiplexer)
Tmux is an essential tool for managing multiple terminal sessions, splitting windows, keeping processes running in the background, and scrolling/copying output natively in a raw TTY.

### Purpose and Benefits
- **Persistent Sessions**: Keep terminal sessions alive even when disconnected, closed, or switching between GUI and TTY.
- **Multitasking**: Split the terminal into panes (horizontally and vertically) without a window manager.
- **Scrollback Buffer**: Crucial for pure TTY usage. Since Linux Kernel 5.9 removed native TTY scrollback, Tmux (Copy Mode) is the standard way to scroll up and view long outputs.

### Installation & Configuration
Installed earlier via `pacman -S tmux`. By default, Tmux uses `Ctrl+B` as the prefix key, which can be unergonomic. We customize it to `Ctrl+A`, add Vim-like pane navigation, enable mouse support, and install the Tmux Plugin Manager (TPM).

For the full setup instructions (the `~/.tmux.conf` config) and a complete usage guide (from basic to advanced), refer to the dedicated documentation file:
👉 **[Tmux Setup & Usage Guide](arch_experience_assets/tmux_guide.md)**

---

# Part 6: Theming (Catppuccin Mocha)

## 6.1. GTK & Qt Theme Setup

### Install Theme Management Tools
```bash
sudo pacman -S nwg-look qt6ct
```

### Fix the Qt Environment Variable
Edit `~/.config/uwsm/env`:
```
QT_QPA_PLATFORMTHEME=qt6ct    # Must be qt6ct, NOT qt5ct
```

### Install Catppuccin GTK Theme
```bash
yay -S catppuccin-gtk-theme-mocha
```
Open `nwg-look` from Rofi:
1. **Widget Theme** → select `catppuccin-mocha-blue-standard+default`.
2. **Icon Theme** → keep `Adwaita` or install a nicer set:
   ```bash
   sudo pacman -S papirus-icon-theme
   ```
   Then select `Papirus-Dark`.
3. **Cursor Theme** → optionally install:
   ```bash
   yay -S catppuccin-cursors-mocha
   ```
4. Click **Apply**.

### Configure Qt6
Open `qt6ct` from Rofi:
1. **Appearance** tab → Style: `Fusion`.
2. **Fonts** tab → choose your preferred font (suggestion: `Noto Sans`, size 10).
3. Click **Apply** → **OK**.

**(Optional) Catppuccin for Qt via Kvantum:**
```bash
sudo pacman -S kvantum
yay -S kvantum-theme-catppuccin-git
```
Open `kvantummanager` from Rofi:
1. Under **Change/Delete Theme** dropdown → find `catppuccin-mocha-blue` → click **Use this theme**.
2. Return to `qt6ct` → **Appearance** tab → Style: change to `kvantum` → **Apply**.

### Logout & Login for Changes to Take Effect

## 6.2. Wayland-Native App Status

| App | Wayland Native? | Notes |
|---|---|---|
| Google Chrome | ✅ Yes | Via `chrome-flags.conf`: `--ozone-platform-hint=auto` |
| Firefox | ✅ Yes | `MOZ_ENABLE_WAYLAND=1` set by default |
| Kitty | ✅ Yes | Native Wayland terminal |
| Thunar | ✅ Yes | GTK4 app, automatic |
| Sublime Text | ❌ No | Runs via XWayland (no Wayland support yet) |
| VS Code / Antigravity | ✅ Yes | Electron with Ozone |

Check which apps are using XWayland:
```bash
hyprctl clients -j | python3 -c \
  "import json,sys; [print(f'{c[\"class\"]} | xwayland={c[\"xwayland\"]}') for c in json.load(sys.stdin)]"
```

## 6.3. SwayNC Notification Center

- Fully restyled with Catppuccin Mocha (CSS at `~/.config/swaync/style.css`).
- Config at `~/.config/swaync/config.json`.
- Toggle: **Super + N**.

## 6.4. Hyprlock (Lock Screen)

- Input field: dark `Base` background, `Text` color, `Blue` border.
- Visual feedback: Blue border (typing), Green flash (success), Red flash (wrong password).

## 6.5. Power Menu (Alt + F4)

- Vertical list layout (5 rows) with Nerd Font icons.
- Keyboard shortcuts while the menu is open (hold `Alt`):
  - `Alt + S` = Shutdown
  - `Alt + R` = Reboot
  - `Alt + L` = Lock
  - `Alt + U` = Suspend (Sleep)
  - `Alt + E` = Logout
- Confirmation dialog: `Alt + Y` (Yes) / `Alt + N` (No).

## 6.6. Dynamic Theming (Wallust)
`yay -S wallust`
The system now supports dynamic colors matching your wallpaper using **Wallust**.

- **How it works:** When you change the wallpaper using `awww`, Wallust automatically analyzes the image and generates a custom color palette.
- **Affected Components:**
  - **Hyprland:** Window borders (active/inactive) dynamically change colors.
  - **Waybar:** The bar's text colors and hover states are generated by Wallust. The bar uses a `.modules > button:hover` strategy with a translucent white overlay to ensure perfect visibility on any wallpaper.
  - **Rofi (Launcher & Powermenu):** Fully adopts the dynamic theme.
- **Persistence:** Wallust templates generate CSS/Rasi files in `~/.config/wallust/templates/` which are exported to standard config directories. These colors persist across reboots, meaning your dynamic theme is active even if Wallust doesn't run at startup.

## 6.7. Automatic Wallpaper Changer (Systemd Timer)

To change the wallpaper automatically every 5 minutes with **zero memory overhead** (avoiding bash `sleep` loops), we use a Systemd Timer.

1. **Service (`~/.config/systemd/user/random-wallpaper.service`):**
```ini
[Unit]
Description=Change Wallpaper Randomly
After=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.config/hypr/scripts/random_wallpaper.sh
```

2. **Timer (`~/.config/systemd/user/random-wallpaper.timer`):**
```ini
[Unit]
Description=Run random wallpaper script every 5 minutes
PartOf=graphical-session.target

[Timer]
OnActiveSec=10
OnUnitActiveSec=5m

[Install]
WantedBy=timers.target
```

Enable it: `systemctl --user enable --now random-wallpaper.timer`.

---

# Part 7: Lenovo Hardware Management

## 7.1. Conservation Mode (Battery Longevity)

Limits charging to ~60% to extend battery lifespan — equivalent to Lenovo Vantage's "Conservation Mode".

```bash
# Check status (1 = enabled, 0 = disabled)
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Disable (charge to 100%)
echo 0 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Enable (charge to ~60% then stop)
echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

## 7.2. Platform Profile (Fan Speed & Performance — Equivalent to Fn+Q)

Fan speed is controlled through the Platform Profile. Three modes:
- `low-power` — Quiet fans, battery saving.
- `balanced` — Default.
- `performance` — Max fans, max performance (for gaming).

```bash
# View current profile
cat /sys/firmware/acpi/platform_profile

# View available profiles
cat /sys/firmware/acpi/platform_profile_choices

# Switch profiles (requires sudo)
echo "low-power" | sudo tee /sys/firmware/acpi/platform_profile
echo "balanced" | sudo tee /sys/firmware/acpi/platform_profile
echo "performance" | sudo tee /sys/firmware/acpi/platform_profile
```

### Optional: Keyboard Shortcuts for Profile Switching
Add to `~/.config/hypr/hyprland.conf`:
```bash
bind = $mainMod, F1, exec, echo low-power | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Low Power"
bind = $mainMod, F2, exec, echo balanced | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Balanced"
bind = $mainMod, F3, exec, echo performance | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Performance"
```

To make these work without a password prompt:
```bash
sudo nano /etc/sudoers.d/power-profile
```
Add:
```
neitnd ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/firmware/acpi/platform_profile
neitnd ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

## 7.3. Battery Information
```bash
cat /sys/class/power_supply/BAT1/capacity           # Current percentage
cat /sys/class/power_supply/BAT1/status              # Charging / Discharging / Full
cat /sys/class/power_supply/BAT1/energy_full         # Actual full capacity (µWh)
cat /sys/class/power_supply/BAT1/energy_full_design  # Design capacity (µWh)
# If energy_full < 80% of energy_full_design → battery has degraded significantly
```

## 7.4. Lid Switch Behavior

### systemd configuration
```bash
sudo nano /etc/systemd/logind.conf
```
Set (uncomment and change):
```
HandlePowerKey=ignore
HandleLidSwitch=ignore
```

### Hyprland configuration (`hyprland.conf`)
```bash
# Lid closed → Lock screen & turn off display signal
bindl = , switch:on:Lid Switch, exec, loginctl lock-session && hyprctl dispatch dpms off
# Lid opened → Turn display back on
bindl = , switch:off:Lid Switch, exec, hyprctl dispatch dpms on
```

### Hypridle configuration (`hypridle.conf`)
```bash
general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

listener { timeout = 300; on-timeout = brightnessctl -s set 10%; on-resume = brightnessctl -r }
listener { timeout = 360; on-timeout = hyprctl dispatch dpms off; on-resume = hyprctl dispatch dpms on }
listener { timeout = 600; on-timeout = loginctl lock-session }
listener { timeout = 1800; on-timeout = systemctl suspend }
```

---

# Part 8: Power Management & Battery Optimization

## 8.1. TLP — Automatic Power Management

TLP replaces `power-profiles-daemon` and automatically manages CPU frequency scaling, PCI/USB/Wi-Fi power states.

### Install
> **Warning:** Do NOT install `intel-undervolt` on 12th Gen Intel. Intel has hardware-locked undervolting on Alder Lake.

```bash
yay -S tlp tlp-rdw
```

### Enable
```bash
sudo systemctl mask power-profiles-daemon    # Prevent conflicts
sudo systemctl enable --now tlp.service
```

### Configure — Prevent Mouse Lag & Speaker Crackling
Edit `/etc/tlp.conf`, find and uncomment/modify these lines:
```text
# Disable USB autosuspend (prevents mouse/keyboard input delay)
USB_AUTOSUSPEND=0

# Disable audio codec power saving (prevents crackling/popping sounds)
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=0
```
Reload: `sudo tlp start`

note: disable rustdesk service can save 5w and disable easyeffect save 1 - 2w.

### Prevent Platform Profile Auto-Switching
TLP may forcefully switch your laptop's platform profile (fan speed/power mode) to `performance` on AC and `balanced` on battery, overriding your manual `Fn+Q` settings. Prevent this by forcing it to `balanced`:
```bash
sudo bash -c 'echo -e "PLATFORM_PROFILE_ON_AC=balanced\nPLATFORM_PROFILE_ON_BAT=balanced" > /etc/tlp.d/99-platform-profile.conf'
sudo tlp start
```

### Aggressive Battery Power Saving
By default, TLP leaves CPU frequency/turbo settings untouched, causing the CPU to boost up to 4.3GHz and use `balance_performance` EPP even on battery (10-15W idle). Windows aggressively clamps these down when unplugged (~5W idle). Create a drop-in config to match:
```bash
sudo tee /etc/tlp.d/01-power-saving.conf << 'EOF'
# CPU EPP: power = maximum power saving on battery
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power

# Turbo Boost: disable on battery (cap at base clock ~2.3GHz, saves 3-8W)
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# HWP Dynamic Boost: disable on battery (prevents random frequency spikes)
CPU_HWP_DYN_BOOST_ON_AC=1
CPU_HWP_DYN_BOOST_ON_BAT=0

# Intel GPU: limit boost frequency on battery
INTEL_GPU_BOOST_FREQ_ON_BAT=0

# Wi-Fi: enable power saving on battery (adds ~50ms latency, saves ~0.5W)
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# PCIE ASPM: use powersupersave on battery for max PCIe link power saving
PCIE_ASPM_ON_AC=default
PCIE_ASPM_ON_BAT=powersupersave
EOF
sudo tlp start
```

## 8.2. Install Intel Vulkan Driver

On hybrid NVIDIA+Intel laptops, apps that use Vulkan rendering (like SwayNC) will default to the NVIDIA GPU if no Intel Vulkan driver is installed — wasting battery and causing stutter.

```bash
yay -S vulkan-intel
```

## 8.3. Force SwayNC onto the Intel iGPU

Even with `vulkan-intel` installed, SwayNC may still cling to NVIDIA via EGL. Create a systemd service override to force all rendering paths to Intel:

```bash
mkdir -p ~/.config/systemd/user/swaync.service.d/

cat << 'EOF' > ~/.config/systemd/user/swaync.service.d/override.conf
[Service]
# Force Direct Rendering to primary (Intel) GPU
Environment="DRI_PRIME=0"
# Force EGL to use Mesa (Intel) instead of NVIDIA's EGL implementation
Environment="__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json"
# Force Vulkan to use the Intel ICD (Installable Client Driver)
Environment="VK_DRIVER_FILES=/usr/share/vulkan/icd.d/intel_icd.json"
EOF

systemctl --user daemon-reload
systemctl --user restart swaync.service
```

### Disable Blur for SwayNC in Hyprland
In `~/.config/hypr/hyprland.conf`, set `blur = off` for SwayNC layers:
```text
layerrule {
    name = swaync-blur
    match:namespace = swaync-control-center
    blur = off
    ignore_alpha = 1
}
layerrule {
    name = swaync-notification-blur
    match:namespace = swaync-notification-window
    blur = off
    ignore_alpha = 1
}
```

## 8.4. Monitoring Tools

| Tool | Install | Purpose |
|---|---|---|
| `btop` / `htop` | `yay -S btop` | CPU, RAM, process management |
| `nvtop` | `yay -S nvtop` | GPU monitoring — shows exactly which apps use Intel vs NVIDIA and power draw |
| `powertop` | `yay -S powertop` | Total system power draw (Overview tab only visible **on battery**) |
| `nvidia-smi` | (included with nvidia-utils) | NVIDIA-specific dashboard |

> **Warning:** Do NOT run `watch -n 1 nvidia-smi` continuously. It wakes the NVIDIA GPU every second, causing it to draw 5–6W indefinitely instead of sleeping.

## 8.5. Understanding Power Consumption on a Hybrid Laptop

A common misconception: "The system reports 20W idle. The 20W idle total is distributed across many components:

| Component | Typical Idle Draw |
|---|---|
| Display backlight | ~3–5W (varies with brightness) |
| NVMe SSD (Gen 4) | ~1.5–2W |
| RAM & Wi-Fi radio | ~2W |
| NVIDIA dGPU (if awake) | ~5–6W (**0W with RTD3 + AQ_DRM_DEVICES**) |
| **Intel CPU (H-Series, 12th Gen)** | ~10W default → **~5W with TLP EPP=power + no turbo** |

### How to Verify Your Optimization
1. Unplug the charger.
2. Disable "Hardware Acceleration" in Chrome Settings to prevent it from waking NVIDIA.
3. Leave the system idle for 1 minute.
4. Run `sudo powertop` and read the top line: `The battery reports a discharge rate of...`
5. Verify NVIDIA is sleeping: `cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status` → should say `suspended`.
6. Verify CPU EPP: `cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference` → should say `power` on battery.
`cat /sys/firmware/acpi/platform_profile`
`tlp-stat -s`
`lsof /dev/nvidia*`
7. **Target:** 10–13W = fully optimized Arch Linux, comparable to Windows.

## 8.6. PRIME Offloading (Running Specific Apps on NVIDIA)

Since our global environment variables force the system to use the Intel iGPU to save battery, you must explicitly tell heavy graphical apps (Games, Blender, OBS Studio) to wake up and use the NVIDIA card.

### 1. Install the offload utility
```bash
sudo pacman -S nvidia-prime
```

### 2. How to use (Terminal)
Prefix any command with `prime-run`:
```bash
prime-run blender
prime-run obs
```

### 3. How to use (GUI/Launcher — Permanent setup)
To make an app always launch with the NVIDIA GPU when you click its icon in the app launcher (Rofi):
1. Copy its `.desktop` shortcut to your local applications folder (so updates don't overwrite your changes):
   ```bash
   cp /usr/share/applications/obs.desktop ~/.local/share/applications/
   ```
2. Edit the copied file:
   ```bash
   nano ~/.local/share/applications/obs.desktop
   ```
3. Find the `Exec=` line and add `prime-run` right after it:
   - **Before:** `Exec=obs`
   - **After:** `Exec=prime-run obs`
4. Save and close. Rofi will automatically apply `uwsm app -- prime-run obs`, seamlessly putting the app inside the systemd scope while offloading graphics to NVIDIA!

### 4. Steam Games
Right-click the game in Steam → **Properties** → **General** → **Launch Options**, and paste:
```text
prime-run %command%
```

*(Note: AI/Data Science libraries like PyTorch/TensorFlow use CUDA and automatically wake up the GPU. You do **not** need `prime-run` for them.)*

## 8.7. Enable NVIDIA Deep Sleep (RTD3) ✅ CONFIRMED WORKING
Even if no apps are running on the NVIDIA GPU, the driver might keep it in an "Idle" state (P8) drawing ~5-6W continuously. To allow Turing/Ampere GPUs (like RTX 3050) to completely power off (0W / D3cold state) when not in use:

1. Create a modprobe configuration file to pass the dynamic power management parameter to the kernel:
   ```bash
   echo "options nvidia NVreg_DynamicPowerManagement=0x02" | sudo tee /etc/modprobe.d/nvidia-pm.conf
   ```
   --sudo systemctl enable --now nvidia-persistenced.service--
2. Because NVIDIA modules are loaded early in the boot process (configured in `mkinitcpio.conf`), you MUST rebuild the initramfs for this change to take effect:
   ```bash
   sudo mkinitcpio -P
   ```
3. Create a `udev` rule to allow the OS to auto-suspend the NVIDIA VGA and Audio controllers:
   ```bash
   sudo bash -c 'cat << EOF > /etc/udev/rules.d/80-nvidia-pm.rules
   # Bật tính năng auto-suspend cho NVIDIA VGA và Audio controller
   ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
   ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"
   ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", TEST=="power/control", ATTR{power/control}="auto"
   EOF'
   ```
4. **Crucial for Wayland/Hyprland:** You must explicitly tell Aquamarine (Hyprland's backend) to use ONLY the Intel iGPU. Without this, Hyprland opens `/dev/nvidia0` and keeps the GPU awake at ~6W 24/7 even with RTD3 configured!
   Edit your UWSM environment file `~/.config/uwsm/env` and add:
   ```bash
   # Intel-only mode (maximum power saving, NVIDIA sleeps at 0W)
   AQ_DRM_DEVICES=/dev/dri/by-path/pci-0000:00:02.0-card

   # If you need an external monitor via HDMI (NVIDIA wakes only when plugged in):
   # AQ_DRM_DEVICES=/dev/dri/by-path/pci-0000:00:02.0-card:/dev/dri/by-path/pci-0000:01:00.0-card
   ```
   *(Note: `00:02.0` = Intel, `01:00.0` = NVIDIA. Verify with `ls -la /dev/dri/by-path/ | grep card`)*

5. Reboot. Now verify the GPU entered deep sleep (0W):
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
   # Should show: suspended
   ```

## 8.8. **NOT SURE IT WORK** Complete iGPU-Only Mode (Optional)
If you want to completely hide the NVIDIA GPU from the OS (similar to Lenovo Vantage's iGPU mode) so that it is never powered on under any circumstances, you can use **EnvyControl**.
*(Note: With RTD3 Deep Sleep configured in 8.7, your NVIDIA card already consumes 0W. EnvyControl is only needed if you maystrictly want to disable it at the hardware level and don't plan to use `prime-run`).
This may cause window dual boot false to find NVIDIA GPU too*

1. Install EnvyControl:
   ```bash
   yay -S envycontrol
   ```
2. Switch modes:
   - **Integrated Only (NVIDIA completely disabled):**
     ```bash
     sudo envycontrol -s integrated
     ```
   - **Hybrid Mode (Re-enable NVIDIA + `prime-run`):**
     ```bash
     sudo envycontrol -s hybrid
     ```
3. **Reboot** the machine to apply the hardware changes.

---

# Part 9: Security & Firewall

## 9.1. Current Security Status

| Feature | Status |
|---|---|
| Secure Boot | ✅ Enabled (sbctl) |
| GNOME Keyring | ✅ Working |
| Polkit | ✅ Enabled (hyprpolkitagent) |
| Firewall | ✅ Configured (UFW) |
| Encrypted DNS | ⚠️ Optional (see below) |

## 9.2. Firewall (UFW)

```bash
sudo pacman -S ufw
sudo ufw default deny incoming     # Block all incoming connections by default
sudo ufw default allow outgoing    # Allow all outgoing connections
# sudo ufw allow ssh               # Uncomment if you need SSH access
# sudo ufw allow 21115:21119/tcp   # Uncomment for RustDesk
# sudo ufw allow 21116/udp
sudo ufw enable
sudo ufw status verbose
sudo systemctl enable ufw
```

## 9.3. Encrypted DNS (Optional)

```bash
sudo nano /etc/NetworkManager/conf.d/dns.conf
```
Add:
```ini
[main]
dns=systemd-resolved
```

```bash
sudo systemctl enable --now systemd-resolved
sudo nano /etc/systemd/resolved.conf
```
Modify:
```ini
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google
FallbackDNS=9.9.9.9#dns.quad9.net
DNSOverTLS=yes
```

```bash
sudo systemctl restart systemd-resolved NetworkManager
resolvectl status    # Verify DNS-over-TLS is active
```

## 9.4. General Security Practices
1. Never log in as root. Always use your regular user + `sudo`.
2. Keep the system updated regularly (see Part 10).
3. Read the PKGBUILD before installing AUR packages (see section 10.4).
4. **Location services:** Linux desktop has no location service running by default (unlike Windows/macOS).

---

# Part 10: Maintenance & Troubleshooting

## 10.1. Swap File (8 GB)

Without swap, the system will hard-freeze when RAM is exhausted. Swap also enables hibernation.

```bash
# Create an 8 GB swap file
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
# Alternative (faster, only for ext4): sudo fallocate -l 8G /swapfile

sudo chmod 600 /swapfile     # Restrict permissions
sudo mkswap /swapfile        # Format as swap
sudo swapon /swapfile        # Activate immediately
```

Register in fstab for automatic activation on boot:
```bash
sudo nano /etc/fstab
```
Add at the end:
```
/swapfile none swap defaults 0 0
```

Reduce swappiness (optional — tells the kernel to prefer RAM over swap):
```bash
cat /proc/sys/vm/swappiness                    # View current value (default: 60)
sudo sysctl vm.swappiness=10                   # Set temporarily
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf   # Set permanently
```

Verify:
```bash
swapon --show
free -h
```

## 10.2. Enable SSD TRIM & OOM Protection

```bash
sudo systemctl enable --now fstrim.timer   # Weekly TRIM for SSD health & speed
sudo systemctl enable --now systemd-oomd   # Out-of-memory killer to prevent freezes
```

## 10.3. System Update Procedure

### Pre-Update Checklist
1. Read [archlinux.org/news](https://archlinux.org/news/) for any manual intervention notices.
2. Ensure battery is sufficient or charger is plugged in.

### Perform the Update
```bash
sudo pacman -Syu         # Update official repos
yay -Sua                 # Update AUR packages
pacman -Qdt              # Check for orphaned packages
# sudo pacman -Rns $(pacman -Qdtq)  # Remove orphans (if any)
```

### After Updating
- Kernel or NVIDIA driver updates → **reboot the machine**.
- Other updates → usually no restart needed.

### Periodic Maintenance Commands
```bash
# ----- Cleanup & Optimization -----
sudo du -sh /var/cache/pacman/pkg/       # View pacman cache size
sudo paccache -rk2                  # Keep only 2 versions of each cached package
yay -Yc                             # Remove unused dependencies (AUR & Official)
sudo pacman -Rns $(pacman -Qtdq)    # Same as above
rm -rf ~/.cache/*                   # Clear user application caches
journalctl --disk-usage             # Check how much space system logs are taking
sudo journalctl --vacuum-size=50M   # Clear old system logs (keep 50MB)
flatpak uninstall --unused          # Remove unused Flatpak runtimes (if any)

# ----- System Health & Info -----
df -h                               # Check disk space
yay -Ps                             # Print system stats (package count, sizes)
systemd-analyze blame | head        # See what slows down boot
systemd-analyze critical-chain      # Detailed tree of boot bottlenecks
systemctl --failed                  # Check for crashed services
systemctl list-timers               # View scheduled tasks (fstrim, paccache)
journalctl -p err -b                # View error logs from current boot session
journalctl -b | grep -i "login" | tail -n 20 
systemd-analyze --user critical-chain graphical-session.target
systemd-analyze --user critical-chain default.target
systemd-analyze --user
ystemd-analyze critical-chain 
systemctl --user list-dependencies graphical-session.target 

```

Or turn on paccache remove timer (keep 2 or 3 nearest version for rollback): 
`sudo systemctl enable --now paccache.timer`

### Restarting UI Components (Without Rebooting)
```bash
# Waybar (status bar)
killall -SIGUSR2 waybar                       # Reload config (smoothest method)
hyprctl dispatch exec "uwsm app -- waybar"    # Restart if killed

# Hyprland
hyprctl reload                                # Reload all config (Hyprland auto-reloads on file save)
```

## 10.4. AUR Safety

### What is a PKGBUILD?
A bash script describing how to build a package: name, version, source URL, build commands, install commands, dependencies.

### Safety Checklist
1. **Read the PKGBUILD before installing:** `yay -S <package> --editmenu`
2. **Red flags:** URLs from untrusted sources, `curl | bash`, unusual file deletions.
3. **Read AUR comments:** Visit `https://aur.archlinux.org/packages/<package>` → check Comments.
4. **Check post-install scripts:** `pacman -Qi <package> | grep "Install Script"`
5. **Prefer official packages** (`pacman -S`) over AUR (`yay -S`) when available.

## 10.5. Build Optimization
Edit `/etc/makepkg.conf`, uncomment `MAKEFLAGS="-j$(nproc)"` to use all CPU threads when building AUR packages (dramatically faster compilation).

## 10.6. Troubleshooting: Lost rEFInd EFI Entry

### Method 1: Chroot & Reinstall
```bash
# Boot from Arch ISO
mount /dev/nvme0n1p3 /mnt          # Mount Root
mount /dev/nvme0n1p1 /mnt/boot     # Mount EFI
arch-chroot /mnt
refind-install
exit && umount -R /mnt && reboot
```

### Method 2: Use efibootmgr
```bash
efibootmgr -c -d /dev/nvme0n1 -p 1 -L "rEFInd" -l "\\EFI\\refind\\refind_x64.efi"
efibootmgr                          # Verify
efibootmgr -o XXXX,YYYY             # Set boot order
```

### Fallback Copy
```bash
sudo mkdir -p /boot/EFI/BOOT
sudo cp /boot/EFI/refind/refind_x64.efi /boot/EFI/BOOT/BOOTX64.EFI
```

## 10.7. Troubleshooting: Screen Freeze After Disabling Laptop Display via nwg-displays

**How to reproduce:** Disable laptop display via GUI while using external monitor → shut down → unplug external monitor → power on → freeze.

**Fix:**
1. At the rEFInd boot screen, press Tab on the Arch entry → select **single user**.
2. Enter the sudo user password.
3. Edit the Hyprland config:
   ```bash
   nano /home/neitnd/.config/hypr/hyprland.conf
   ```
4. Comment out `source = ...monitors.conf` with `#`.
5. Uncomment `monitor=,preferred,auto,auto`.
6. Save → reboot.
7. Once booted, restore the config:
   ```
   monitor = , preferred, auto, 1
   source = ~/.config/hypr/monitors.conf
   ```

## 10.8. Disk Space Management

If your disk is filling up, do not use third-party cleaner apps. Use the built-in commands or dedicated Linux tools.

### Analyze Disk Usage (TreeSize alternatives)
- **`ncdu`** (Terminal): Extremely fast TUI disk usage analyzer.
  ```bash
  yay -S ncdu
  sudo ncdu /         # Scan entire system
  sudo ncdu -x /      # Scan entire system without vitual folder

  ncdu ~              # Scan home folder
  ```
- **`baobab`** (GUI): GNOME Disk Usage Analyzer for visual pie charts.
  ```bash
  yay -S baobab
  ```

### Reclaim Disk Space
In addition to clearing the pacman cache (`paccache`) and user cache (`~/.cache/`) mentioned in section 10.3, you can clean up the systemd journal logs, which can grow to several gigabytes over time:
```bash
sudo journalctl --vacuum-size=50M    # Keep only the latest 50MB of logs
```

## 10.9. Troubleshooting: Slow Login / Hang on Logout (Systemd Stop Job)

**Issue:** When logging out (e.g., using `uwsm stop`), logging back in takes a very long time (up to 90 seconds). This happens because systemd waits for up to 90 seconds for stuck user services to close before forcefully killing them.

**Fix:** Reduce the default `Stop` timeout to 10 seconds.
1. Run these two commands to automatically replace the 90s timeout with 10s in the systemd configuration files:
   ```bash
   sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g' /etc/systemd/system.conf
   sudo sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=10s/g' /etc/systemd/user.conf
   ```
   *(Note: Do **NOT** change `DefaultTimeoutStartSec`, as some services genuinely need more time to start up.)*
2. Reload systemd configurations (or just reboot):
   ```bash
   sudo systemctl daemon-reload && systemctl --user daemon-reload
   ```
or just simple: `mkdir -p ~/.config/systemd && echo -e "[Manager]\nDefaultTimeoutStopSec=10s" > ~/.config/systemd/user.conf`

## 10.10. Troubleshooting: Black Screen After Suspend/Wake — Control Hyprland from TTY

**Scenario:** After waking from suspend, the screen is completely black. Hyprland is still running but you cannot see or interact with it. You can still switch to another TTY (`Ctrl+Alt+F2`).

**Root cause (Hyprland Lua mode):** `hyprctl dispatch "hl.dsp.dpms('...')"` acts as a **toggle** (argument `'on'`/`'off'` is ignored — it always just flips the current state). If both `after_sleep_cmd` AND `on-resume` of the dpms listener fire after wake, they double-toggle and leave the screen off. **Fix:** Remove `after_sleep_cmd` from `hypridle.conf` — the `on-resume` of the dpms listener already handles turning the display back on.

> **Note:** `hyprctl eval "hl.dsp.dpms('...')"` returns `ok` but **does nothing** — it cannot control DPMS. Only `hyprctl dispatch` works.

### Recovery: Turn the Screen Back On from TTY

Switch to a free TTY (`Ctrl+Alt+F2`), log in, then run:

```bash
# Step 1: Find the running Hyprland instance signature
hyprctl instances
# Output example:
# instance a0136d8c04687bb36eb8a28eb9d1ff92aea99704_1783431067_1016137192:
#         wl socket: wayland-1

# Step 2: Export the required environment variables
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export HYPRLAND_INSTANCE_SIGNATURE="<paste the full instance ID here>"

# Step 3: Toggle the display back on (dispatch toggles state)
# If screen is off, one call turns it on:
hyprctl dispatch "hl.dsp.dpms('on')"
```

Then switch back to your session TTY (`Ctrl+Alt+F1` or whichever VT Hyprland runs on, usually F1 or F4).

### Faster Alternative: `hypr-recover` function in `.zshrc`

Already added to `~/.zshrc`. From any TTY, just run:

```bash
hypr-recover
# → Automatically finds the Hyprland instance, sets env vars, and toggles screen on
# → Then: Ctrl+Alt+F1 to return to your session
```

The function:
```bash
hypr-recover() {
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  local sig
  sig=$(ls /run/user/$(id -u)/hypr/ 2>/dev/null | head -1)
  export HYPRLAND_INSTANCE_SIGNATURE="$sig"
  hyprctl dispatch "hl.dsp.dpms('on')"
  echo "Màn hình đã bật. Ctrl+Alt+F1 để quay lại session Hyprland."
}
```

## 10.3. System Debugging & Logging Toolkit

When configuring Linux (like Wayland, Hyprland, or background services), tools will often fail silently. Here are the core commands used to debug, test, and trace errors effectively:

### 1. Systemd Service Management & Status
Systemd manages both system-wide and user-specific background services.
- `systemctl status <service>`: Check the health of a system service (e.g., `sshd`, `NetworkManager`). It shows if it's running, crashed, or disabled, and displays the last few log lines.
- `systemctl --user status <service>`: Check a user-specific service (e.g., `mouseless`, `waybar`). The `--user` flag is crucial for GUI/Wayland apps because they run under your user account, not root.
- `systemctl --user daemon-reload`: If you edit a `.service` file on disk, you MUST run this command so Systemd re-reads the file before you restart the service.

### 2. Reading Full Logs (Journalctl)
The `status` command only shows the last 10 lines. To read full logs:
- `journalctl -u <service>`: Read the entire history of a system service.
- `journalctl --user -u <service>`: Read the history of a user service.
- `journalctl --user -u <service> -n 50`: Show only the last 50 lines.
- `journalctl --user -u <service> -f`: **Follow** the logs in real-time (like a live feed). Press `Ctrl+C` to exit.

### 3. Quick Text Searching (Grep)
`grep` is used to search for specific text inside files or command outputs.
- `grep "keyword" /path/to/file`: Search for "keyword" in a file.
- `grep -n "keyword" /path/to/file`: Same as above, but prints the exact **line numbers**.
- `journalctl --user \| grep "mouseless"`: Pipe (`|`) the output of the logs into `grep` to only show lines containing "mouseless".

### 4. Viewing & Isolating File Content
- `cat /path/to/file`: Dump the whole file to the terminal.
- `head -n 20 /path/to/file`: Read the first 20 lines.
- `tail -n 20 /path/to/file`: Read the last 20 lines (great for checking the newest errors in a log file).

### 5. Safe Testing & Prototyping
When you want to test a configuration without breaking your actual system files:
1. **Create a temporary directory:** `mkdir -p /tmp/test_dir`
2. **Create a test config using Heredoc:** 
   ```bash
   cat << 'EOF' > /tmp/test_dir/config.yaml
   # Your test code here
   EOF
   ```
3. **Run the program in debug mode pointing to the test file:** e.g., `mouseless -c /tmp/test_dir/config.yaml -d`. If it crashes, it outputs the error without affecting your real setup.

### 6. Reading Manuals
- `man <command>`: Opens the official manual page for a command (e.g., `man sshd_config`). Press `q` to quit, use `/` to search within the manual.
- `<command> --help`: A quicker, shorter summary of flags and parameters.

# Part 11: Tips for Windows Switchers

## 11.1. Middle-Click Paste (Primary Selection)
- **How:** Select any text (highlight it) → press the **middle mouse button** (or tap both left+right touchpad buttons simultaneously) at the target location → text is pasted instantly.
- This is a **second, independent clipboard** — it works in parallel with `Ctrl+C` / `Ctrl+V`.

## 11.2. Workspaces (Virtual Desktops)
Hyprland provides **10 workspaces** (`Super+1` through `Super+0`). Each is a separate virtual screen.

| Shortcut | Action |
|---|---|
| `Super + [1-0]` | Switch to workspace |
| `Super + Shift + [1-0]` | Move current window to workspace |
| `Super + Alt + [1-0]` | Move ALL windows from current workspace to target |
| `Super + Shift + Alt + [1-0]` | Swap ALL windows between current and target workspace |
| `Super + Shift + W` | Close ALL windows on the current workspace |

## 11.3. Tiling Window Manager Basics
Unlike Windows (overlapping windows), Hyprland **auto-tiles windows to fill the screen**.

| Shortcut | Action |
|---|---|
| `Super + S` | Toggle floating mode (like traditional Windows) |
| `Super + F` | Toggle fullscreen |
| `Super + O` | Rotate split direction (horizontal ↔ vertical) |

## 11.4. Terminal Essentials
| Shortcut / Command | Action |
|---|---|
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Copy/Paste in terminal (NOT `Ctrl+C/V` — `Ctrl+C` sends a kill signal!) |
| `Tab` | Auto-complete commands and filenames |
| `Ctrl+R` | Search command history |
| `!!` | Repeat last command. `sudo !!` = re-run last command with root privileges |

## 11.5. Package Management (Pacman / Yay)
```bash
sudo pacman -Syu          # Update the entire system
pacman -Ss <name>          # Search for a package
pacman -Q | grep <name>    # Check if a package is installed
sudo pacman -Rns <name>    # Remove a package and its dependencies
paccache -r                # Clean old cached packages
```

## 11.6. No Control Center Needed
Hyprland follows the philosophy of "each tool does one thing":

| Function | Tool | How to Open |
|---|---|---|
| Notifications | SwayNC | `Super + N` |
| Audio | pavucontrol + EasyEffects | Rofi |
| Bluetooth | blueman-manager | Rofi or Waybar icon |
| Wi-Fi | nmtui / network-manager-applet | Waybar icon or terminal |
| Display | nwg-displays | Rofi |
| Brightness | brightnessctl | Keyboard shortcuts |
| Clipboard | cliphist | `Super + V` |

---

# Part 12: Keyboard Shortcuts Reference

| Shortcut | Function |
|---|---|
| `Super + Enter` | Open terminal (Kitty) |
| `Super + Space` | Open app launcher (Rofi) |
| `Super + E` | Open file manager (Thunar) |
| `Super + W` | Close current window |
| `Super + L` | Lock screen |
| `Super + V` | Open clipboard history |
| `Super + N` | Toggle notification center |
| `Super + Tab` | Window switcher |
| `Super + Shift + F` | File search (Rofi Finder) |
| `Super + Shift + G` | Content search (Live Grep) |
| `Super + Shift + S` | Screenshot (region select) |
| `Super + Shift + Scroll` | Zoom screen |
| `Alt + F4` | Power menu (Shutdown/Reboot/...) |
| `Print` | Screenshot (full screen) |
| `Ctrl + Space` | Switch input language |

---

# Part 13: Development Environment & Utilities

## 13.1. Installed Programming Tools & Usage Guide

Below is a guide to the primary development tools installed on the system and how to use them effectively.

### C/C++ Development
The system relies on the GCC compiler, CMake for build configuration, and Ninja for blazing fast builds.
* **GCC / G++:** The GNU Compiler Collection for C/C++.
  * *Compile a single file:* `gcc main.c -o app` or `g++ main.cpp -o app`
* **CMake:** Cross-platform build system generator.
* **Ninja:** A small build system with a focus on speed, designed to have its input files generated by a higher-level build system like CMake.
  * *Standard CMake + Ninja Workflow:*
    ```bash
    # Generate build files into the 'build' directory using Ninja
    cmake -B build -G Ninja
    
    # Execute the build
    cmake --build build
    ```

### Python (Managed by `uv`)
`uv` is an extremely fast, all-in-one Python package and project manager written in Rust.
* **Python Version Management:**
  * *List available Python versions:* `uv python list`
  * *Install a specific version:* `uv python install 3.12`
* **Virtual Environment Management:**
  * *Create a virtual environment in the current directory:* `uv venv`
  * *Activate the environment:* `source .venv/bin/activate`
  * *Install packages:* `uv pip install <package_name>`
* **Using `uv tool`:** Allows you to run or install independent Python CLI tools globally without manually setting up virtual environments.
  * *Run a tool without installing it globally:* `uv tool run black main.py` (runs the black formatter)
  * *Safely install a global CLI tool:* `uv tool install yt-dlp`

### Java (JVM Development)
* **archlinux-java:** Arch Linux's official helper script for setting the default Java environment.
  * *List installed JDKs:* `archlinux-java status`
  * *Set the default JDK:* `sudo archlinux-java set java-21-openjdk`
* **javac & java:**
  * *Compile a Java file:* `javac Main.java` (outputs `Main.class`)
  * *Run a Java class:* `java Main`

### Antigravity CLI (Terminal AI Agent)
Antigravity CLI is an advanced autonomous AI coding assistant developed by Google DeepMind that runs directly in the terminal, capable of modifying codebases, planning, and debugging.
* **Installation:**
  ```bash
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  ```
  *(Note: The installer automatically downloads the binary to `~/.local/bin/agy` and adds it to your `~/.zshrc` PATH).*
* **Setup & Usage:**
  * Reload your shell: `source ~/.zshrc`
  * Authenticate: `agy login`
  * Execute a task: `agy "Find the network bug in config.yaml and fix it"`

---

## 13.2. CLI Tools for Directory Tracking (Including Hidden Files)

To track and export the directory structure (including dotfiles and hidden folders), use the following terminal tools:

### Using `tree` (Installed)
The standard `tree` command ignores hidden files by default. Add the `-a` (all) flag to include them:
```bash
# Display the directory tree up to level 2, including hidden files and recursive sizes
tree -a -h -L 2 --du /home/neitnd

# Export the output to a markdown file
tree -a -h -L 2 --du /home/neitnd > tree_output.md
```
*Flag Explanations:*
* `-a`: Show all files (including hidden ones starting with a dot).
* `-h`: Human-readable sizes (KB, MB, GB).
* `-L 2`: Limit the depth of the directory tree to level 2.
* `--du`: Print the accumulated size of each directory.

### Using `eza` (Modern `ls` replacement in Rust)
Add the `-a` or `-la` flag to show hidden files in a detailed list format:
```bash
# Display the directory tree up to level 2, with detailed listing and hidden files
eza -la --tree --level=2 /home/neitnd

# Export the output to a markdown file
eza -la --tree --level=2 /home/neitnd > eza_output.md
```
*Flag Explanations:*
* `-l` and `-a`: Display in long format and show all hidden files.
* `--tree`: Display the output as a hierarchical tree.
* `--level=2`: Limit the tree depth to 2.

---

## 13.3. Neovim (LazyVim IDE Setup)

Instead of configuring Neovim from scratch, the system utilizes **LazyVim**, an extremely fast, fully-featured Neovim distribution built around `lazy.nvim` that provides a complete IDE experience out of the box.

### Installation & Integration
Because configuration is managed by GNU Stow, LazyVim is deployed by cloning its starter template directly into the dotfiles repository:
```bash
git clone https://github.com/LazyVim/starter ~/neitnd_dotfiles/.config/nvim
rm -rf ~/neitnd_dotfiles/.config/nvim/.git
cd ~/neitnd_dotfiles && stow .
```

### Customization (Catppuccin Theme)
To maintain visual consistency with the rest of the Catppuccin Mocha desktop environment, the default TokyoNight theme is replaced with Catppuccin with a transparent background by creating `lua/plugins/colorscheme.lua`:
```lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      integrations = { cmp = true, gitsigns = true, nvimtree = true, treesitter = true, notify = true, mini = true },
    },
  },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
```

### Usage Guide
For a quick reference on how to navigate files, use LSP features, and manage plugins within LazyVim, refer to the:
**👉 [LazyVim Basic Usage Guide](arch_experience_assets/lazyvim_guide.md)**

## Development Environment

### Docker & Docker Compose
To set up Docker on Arch Linux:

1. **Install packages:**
```bash
sudo pacman -S docker docker-compose
```

2. **Enable and start the service:**
```bash
sudo systemctl enable --now docker.service
```

3. **Add your user to the Docker group** (so you don't need `sudo` for every command):
```bash
sudo usermod -aG docker $USER
```
*Note: You may need to log out and log back in (or run `newgrp docker`) for the group changes to take effect.*

4. **Verify installation:**
```bash
docker info
docker-compose --version
```
