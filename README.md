# neitnd's Dotfiles

Hyprland rice on Arch Linux with **Catppuccin Mocha Blue** theming.

**Machine:** Lenovo IdeaPad Gaming 3 15IAH7 (Intel 12th Gen + NVIDIA RTX 3050)

![Hyprland](https://img.shields.io/badge/WM-Hyprland-blue?style=flat-square)
![Arch](https://img.shields.io/badge/OS-Arch%20Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)
![Catppuccin](https://img.shields.io/badge/Theme-Catppuccin%20Mocha-89b4fa?style=flat-square)

---

## Stack

| Component | Tool |
|---|---|
| Window Manager | [Hyprland](https://hyprland.org/) (Wayland) |
| Session Manager | [UWSM](https://github.com/Vladimir-csp/uwsm) (systemd-managed) |
| Display Manager | [SDDM](https://github.com/sddm/sddm) (X11, Intel only) |
| Status Bar | [Waybar](https://github.com/Alexays/Waybar) |
| Notifications | [SwayNC](https://github.com/ErikReider/SwayNotificationCenter) |
| App Launcher | [Rofi (Wayland)](https://github.com/lbonn/rofi) |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) |
| Shell | Zsh + [Powerlevel10k](https://github.com/romkatv/powerlevel10k) + Oh My Zsh |
| File Manager | [Thunar](https://docs.xfce.org/xfce/thunar/start) |
| Wallpaper | [awww](https://github.com/raybb/awww) |
| Lock Screen | [Hyprlock](https://github.com/hyprwm/hyprlock) |
| Idle Daemon | [Hypridle](https://github.com/hyprwm/hypridle) |
| Audio | PipeWire + [EasyEffects](https://github.com/wwmm/easyeffects) |
| Input Method | [Fcitx5](https://fcitx-im.org/) + Bamboo (Vietnamese) |
| Power Management | [TLP](https://linrunner.de/tlp/) |

## Structure

Managed with [GNU Stow](https://www.gnu.org/software/stow/). Clone into `~/neitnd_dotfiles/` and run `stow .` to create symlinks.

```
neitnd_dotfiles/
├── .config/
│   ├── hypr/               # Hyprland WM — keybindings, animations, monitors, scripts
│   ├── waybar/             # Status bar — modules, style, layout
│   ├── swaync/             # Notification center — config.json & Catppuccin CSS
│   ├── rofi/               # App launcher, power menu, clipboard picker
│   ├── kitty/              # Terminal — font, colors, transparency, keymaps
│   ├── fastfetch/          # System info display on terminal launch
│   ├── htop/               # Process monitor layout & color scheme
│   ├── easyeffects/        # Audio equalizer presets (speaker/headphone profiles)
│   ├── fcitx5/             # Vietnamese input method (Bamboo) settings
│   ├── uwsm/              # UWSM environment variables (NVIDIA, Qt, XDG)
│   ├── wallpaper_custom/   # Custom wallpapers referenced by Hyprland
│   ├── nwg-displays/       # Monitor layout (resolution, refresh rate, position)
│   ├── MangoHud/           # Gaming FPS/temperature overlay
│   ├── cmus/               # Terminal music player config
│   ├── mpd/                # Music Player Daemon config
│   ├── rustdesk/           # Remote desktop settings
│   ├── sublime-text/       # Sublime Text preferences
│   ├── xdg-desktop-portal/ # Portal priority config (Hyprland > GTK)
│   ├── chrome-flags.conf   # Chrome flags (middle-click scroll, Ozone/Wayland)
│   └── mimeapps.list       # Default applications for file types
├── .local/
│   └── share/
│       ├── applications/   # Custom .desktop entries (Sublime multi-window)
│       ├── easyeffects/    # EasyEffects presets (output/)
│       └── fonts/          # Custom fonts
├── .zshrc                  # Zsh configuration (plugins, aliases, keybindings)
├── .zprofile               # Login shell environment
├── .vimrc                  # Vim settings
├── .p10k.zsh               # Powerlevel10k prompt theme
├── .gitconfig              # Git user config
├── arch_experience.md      # Complete setup & configuration guide (English)
└── README.md
```

## Installation

> **Prerequisites:** A fresh Arch Linux install with an active internet connection. See `arch_experience.md` for the full step-by-step guide from zero.

```bash
# Clone dotfiles
git clone https://github.com/neitnd/neitnd_dotfiles.git ~/neitnd_dotfiles

# Deploy symlinks
cd ~/neitnd_dotfiles
stow .
```

### Key System Configurations (not managed by Stow)

These files live outside `$HOME` and must be configured manually:

| File | Purpose |
|---|---|
| `/etc/X11/xorg.conf.d/10-intel-sddm.conf` | Xorg — force Intel GPU to keep NVIDIA asleep |
| `/etc/sddm.conf` | SDDM — enable Catppuccin Mocha theme |
| `/etc/tlp.conf` | TLP — USB autosuspend off, audio power save off |
| `/etc/mkinitcpio.conf` | Initramfs — NVIDIA modules |
| `/boot/refind_linux.conf` | rEFInd bootloader — kernel params |
| `/etc/sudoers.d/power-profile` | Passwordless platform profile switching |

## NVIDIA + Battery Optimization

This setup aggressively minimizes NVIDIA dGPU wake-ups on hybrid laptops:

- **SDDM on X11** is configured to explicitly ignore the NVIDIA GPU (`AutoAddGPU false`), keeping it at 0W.
- **`vulkan-intel`** is installed so Vulkan apps default to Intel instead of waking NVIDIA.
- **SwayNC** is forced onto Intel via a systemd override (`DRI_PRIME=0` + EGL + Vulkan env vars).
- **TLP** auto-suspends PCI, Wi-Fi, and SSD while keeping USB (mouse) and audio always on.
- **Blur is disabled** for SwayNC layers to prevent GPU stutter on notifications.

Idle power draw target: **10–13W on battery** (verified with `powertop`).

## Documentation

The comprehensive setup guide is included in this repo:

- **[`arch_experience.md`](arch_experience.md)** — Full walkthrough from Arch ISO boot to a fully configured Hyprland desktop, covering installation, NVIDIA drivers, Secure Boot, theming, power optimization, security, and daily-use tips.

## Credits

- Base dotfiles adapted from [HighDelay/dotfiles](https://github.com/HighDelay/dotfiles)
- Color scheme: [Catppuccin Mocha](https://github.com/catppuccin/catppuccin)
