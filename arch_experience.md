# Arch Linux + Hyprland — Complete Setup & Experience Guide

> **Reference Machine:** Lenovo IdeaPad Gaming 3 15IAH7 | Intel 12th Gen + NVIDIA RTX 3050 | Dual Boot Windows + rEFInd
>
> This document consolidates the full installation process, post-install configuration, theming, power optimization, security hardening, and daily-use tips into a single, step-by-step reference. A complete beginner should be able to follow every section from top to bottom.

---

## Table of Contents

1. [Part 1: Base Installation](#part-1-base-installation)
2. [Part 2: NVIDIA Driver & Secure Boot](#part-2-nvidia-driver--secure-boot)
3. [Part 3: Desktop Environment (Hyprland + UWSM + Greetd)](#part-3-desktop-environment-hyprland--uwsm--greetd)
4. [Part 4: Audio, Multimedia & Bluetooth](#part-4-audio-multimedia--bluetooth)
5. [Part 5: Tools & Utilities](#part-5-tools--utilities)
6. [Part 6: Theming (Catppuccin Mocha)](#part-6-theming-catppuccin-mocha)
7. [Part 7: Lenovo Hardware Management](#part-7-lenovo-hardware-management)
8. [Part 8: Power Management & Battery Optimization](#part-8-power-management--battery-optimization)
9. [Part 9: Security & Firewall](#part-9-security--firewall)
10. [Part 10: Maintenance & Troubleshooting](#part-10-maintenance--troubleshooting)
11. [Part 11: Tips for Windows Switchers](#part-11-tips-for-windows-switchers)
12. [Part 12: Keyboard Shortcuts Reference](#part-12-keyboard-shortcuts-reference)

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

# Part 3: Desktop Environment (Hyprland + UWSM + Greetd)

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
       gvfs polkit dbus gnome-keyring
```

### Group 5: Terminal, Shell, Fonts
```bash
yay -S kitty zsh fastfetch htop cozette-otb ipa-fonts noto-fonts
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

## 3.4. Display Manager: Greetd + Tuigreet

Greetd with tuigreet replaces SDDM entirely. It runs in pure TUI mode (no X11), which means the NVIDIA GPU stays completely powered off (0W) at the login screen — a significant battery saving on hybrid laptops.

### Install
```bash
yay -S greetd greetd-tuigreet
```

### Configure — Auto-launch Hyprland via UWSM
Edit `/etc/greetd/config.toml`:
```toml
[terminal]
# Run the greeter on TTY1
vt = 1

[default_session]
# --time: show clock, --remember: remember last user, --cmd: launch Hyprland via UWSM
command = "tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'"
# Run the greeter process under the dedicated "greeter" user
user = "greeter"
```

### Configure GNOME Keyring Auto-Unlock
Without this, Chrome/Coc Coc will prompt you for the keyring password on every launch.

Append two lines to the end of `/etc/pam.d/greetd`:
```text
auth optional pam_gnome_keyring.so
session optional pam_gnome_keyring.so auto_start
```

### Enable the Service
```bash
sudo systemctl enable greetd.service
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

## 5.6. Remote Desktop

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

## 5.8. Live Grep (Super + Shift + G)

Searches inside file contents in real time using `ripgrep`. Useful when you know what a file contains but not its name.

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
- **IdeaPad Gaming 3 limitation:** Only `channel <= 1` → set the hotspot channel to match the channel of the Wi-Fi network you are already connected to.
- View current channel: `nmcli device wifi`

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

A common misconception: "The system reports 20W idle, minus 6W for NVIDIA, so the CPU must be consuming 14W!" This is wrong. The 20W idle total is distributed across many components:

| Component | Typical Idle Draw |
|---|---|
| Display backlight | ~3–5W (varies with brightness) |
| NVMe SSD (Gen 4) | ~1.5–2W |
| RAM & Wi-Fi radio | ~2W |
| NVIDIA dGPU (if awake) | ~5–6W |
| **Intel CPU (H-Series, 12th Gen)** | **~4–6W** (excellent for a high-performance chip) |

### How to Verify Your Optimization
1. Unplug the charger.
2. Disable "Hardware Acceleration" in Chrome Settings to prevent it from waking NVIDIA.
3. Leave the system idle for 1 minute.
4. Run `sudo powertop` and read the top line: `The battery reports a discharge rate of...`
5. **Target:** 10–13W = fully optimized Arch Linux, comparable to Windows.

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
# ----- Cleanup -----
du -sh /var/cache/pacman/pkg/       # View pacman cache size
sudo paccache -rk1                  # Keep only 1 version of each cached package
sudo pacman -Rns $(pacman -Qtdq)    # Remove orphan packages
rm -rf ~/.cache/*                   # Clear user application caches

# ----- System Health -----
df -h                               # Check disk space
systemd-analyze blame | head        # See what slows down boot
systemctl --failed                  # Check for crashed services
systemctl list-timers               # View scheduled tasks (fstrim, etc.)
journalctl -p err -b                # View error logs from current boot session
```

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

---

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
