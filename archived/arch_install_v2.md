# Hướng dẫn Cài đặt Arch Linux + Hyprland (Dual Boot với Windows)

> [!NOTE]
> Tài liệu này là bản tổng hợp và viết lại gọn gàng từ file ghi chép gốc `arch_install.md`. Mọi thông tin gốc đều được giữ nguyên, chỉ bổ sung giải thích và sắp xếp lại cho dễ theo dõi.
>
> **Máy tham khảo:** Lenovo IdeaPad Gaming 3 15IAH7 | GPU Nvidia | Dual Boot Windows + rEFInd

---

## Mục lục
1. [Phần 1: Cài đặt Cơ sở](#phần-1-cài-đặt-cơ-sở)
2. [Phần 2: Driver Nvidia & Secure Boot](#phần-2-driver-nvidia--secure-boot)
3. [Phần 3: Giao diện Desktop (Hyprland + UWSM + SDDM)](#phần-3-giao-diện-desktop-hyprland--uwsm--sddm)
4. [Phần 4: Âm thanh, Đa phương tiện & Bluetooth](#phần-4-âm-thanh-đa-phương-tiện--bluetooth)
5. [Phần 5: Công cụ & Tiện ích](#phần-5-công-cụ--tiện-ích)
6. [Phần 6: Quản lý phần cứng Lenovo](#phần-6-quản-lý-phần-cứng-lenovo)
7. [Phần 7: Bảo trì & Khắc phục sự cố](#phần-7-bảo-trì--khắc-phục-sự-cố)

---

# Phần 1: Cài đặt Cơ sở

## 1.1. Boot vào Arch ISO (Không cần USB)

Thay vì dùng USB, ta tận dụng tính năng tự phát hiện file `.efi` trong phân vùng FAT32:
1. Tạo phân vùng nhỏ (~3GB), định dạng `FAT32`.
2. Giải nén toàn bộ nội dung file ISO Arch Linux vào phân vùng đó.
3. Khởi động lại, nhấn `F12` để vào Boot Menu → chọn boot vào phân vùng vừa tạo.
4. Chọn **Arch Linux install medium** → chế độ **minimal**.

## 1.2. Kết nối Mạng (Wi-Fi)

```bash
# Vào giao diện quản lý mạng
iwctl

# Trong iwctl:
[iwd]# device list                          # Tìm tên thiết bị (vd: wlan0)
[iwd]# station wlan0 scan                   # Quét mạng
[iwd]# station wlan0 get-networks           # Liệt kê mạng
[iwd]# station wlan0 connect "Tên_WiFi"     # Kết nối (nhập pass khi hỏi)
[iwd]# exit
```

> [!NOTE]
> Sau khi cài xong Arch, bạn sẽ dùng `nmtui` (NetworkManager) thay cho `iwctl`:
> ```bash
> nmtui                                       # Giao diện quản lý mạng
> sudo systemctl enable --now NetworkManager   # Nếu lệnh trên lỗi
> ping -c 3 google.com                        # Kiểm tra kết nối
> ```

## 1.3. Phân vùng & Mount ổ đĩa

```bash
lsblk                    # Xem danh sách phân vùng
cgdisk /dev/nvme0n1p1    # Xem chi tiết (thay tên cho đúng máy bạn)
```

Giả sử bố cục phân vùng:
- `/dev/nvme0n1p4` — Phân vùng Root cho Arch (~240GB)
- `/dev/nvme0n1p3` — Phân vùng EFI mới cho Arch (~700MB)

```bash
# Mount Root
mount /dev/nvme0n1p4 /mnt

# Tạo thư mục Boot và Home
mkdir -p /mnt/{home,boot}

# Mount EFI vào /boot
mount /dev/nvme0n1p3 /mnt/boot

# Kiểm tra
lsblk
```

## 1.4. Cài đặt Hệ điều hành & Chroot

```bash
# Cài base system + kernel + firmware + công cụ build
pacstrap -K /mnt base linux linux-firmware base-devel

# Tạo fstab (dùng UUID để tránh lỗi khi thay đổi ổ đĩa)
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab    # Kiểm tra lại

# Chuyển vào hệ thống mới
arch-chroot /mnt
```

## 1.5. Cấu hình Cơ bản trong Chroot

### Tạo User & Mật khẩu
```bash
passwd                                          # Đặt mật khẩu root
useradd -g users -m -s /bin/bash neitnd          # Tạo user (đổi tên cho phù hợp)
passwd neitnd                                    # Đặt mật khẩu user
```

### Cấp quyền Sudo
```bash
pacman -S nano                                   # Cài trình soạn thảo
nano /etc/sudoers.d/neitnd
```
Ghi vào:
```text
neitnd ALL=(ALL:ALL) ALL
```

> [!TIP]
> Nếu gặp lỗi quyền ở bước trên, dùng cách thay thế:
> ```bash
> sudo useradd -m -g users -G wheel neitnd
> sudo passwd neitnd
> sudo EDITOR=nano visudo
> # → Tìm dòng "# %wheel ALL=(ALL:ALL) ALL" → xóa dấu # ở đầu
> ```

### Ngôn ngữ, Múi giờ & Hostname
```bash
# Locale
nano /etc/locale.gen
# → Tìm "en_US.UTF-8", xóa dấu # ở đầu dòng
locale-gen
nano /etc/locale.conf
# → Thêm: LANG=en_US.UTF-8

# Timezone
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

# Hostname
nano /etc/hostname
# → Ghi tên máy, ví dụ: arch-lig3
```

## 1.6. Cài Bootloader (rEFInd) & NetworkManager

```bash
pacman -S networkmanager refind git
refind-install
systemctl enable NetworkManager
```

### Cấu hình Boot với UUID
```bash
lsblk -f
# → Copy UUID của phân vùng Root (dòng có mount point /)

nano /boot/refind_linux.conf
# → Sửa "root=/dev/nvme..." thành "root=UUID=<chuỗi-uuid>"
# Ví dụ: "Boot with standard options"  "rw root=UUID=a1b2c3d4-... quiet"
```

### Hoàn tất & Reboot
```bash
exit
umount -R /mnt
reboot
```

## 1.7. Sau Reboot lần đầu

Boot vào Arch từ rEFInd. Đăng nhập bằng user vừa tạo.

```bash
# Làm mới cấu hình rEFInd
sudo rm -rf /boot/refind_linux.conf
sudo mkrlconf
ls -la /boot

# Kết nối mạng
nmtui

# Cài AUR Helper (Yay)
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~
```

---

# Phần 2: Driver Nvidia & Secure Boot

## 2.1. Cài Driver Nvidia

```bash
# Cài DKMS (Dynamic Kernel Module Support)
yay -S dkms

# Cấu hình khóa bảo mật cho DKMS (nếu dùng Secure Boot)
sudo nano /etc/dkms/framework.conf
# → Thêm/bỏ comment dòng sign_tool trỏ tới khóa bảo mật

# Cài driver Nvidia (nếu lỗi version, chạy: yay -Syu && yay -S linux linux-headers)
yay -S nvidia-dkms nvidia-utils libva-nvidia-driver linux-headers
sudo dkms autoinstall
```

### Cấu hình Initramfs cho Nvidia
```bash
sudo nano /etc/mkinitcpio.conf
# → Tìm dòng MODULES=() và sửa thành:
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

sudo mkinitcpio -P    # Build lại initramfs
```

### Thêm tham số Kernel cho rEFInd
```bash
sudo nano /boot/refind_linux.conf
# → Nối thêm vào cuối dòng "Boot with standard options":
# nvidia_drm.modeset=1 nvidia_drm.fbdev=1
```

### Kiểm tra
```bash
lsmod | grep nvidia    # Phải thấy nvidia, nvidia_modeset, nvidia_drm...
```

## 2.2. Thiết lập Secure Boot với sbctl

> [!WARNING]
> **Trước khi bắt đầu:** Vào Windows → Mở *Manage BitLocker* → **Suspend protection** ở ổ C: để tránh bị khóa.

### Bước 1: Đưa BIOS về "Setup Mode"
1. Khởi động lại → nhấn `F2` vào BIOS.
2. Tab *Security* → *Secure Boot* → *Clear All Secure Boot Keys* → *Yes*.
3. Trạng thái chuyển sang *Setup Mode*. Nhấn `F10` lưu → boot vào Arch.

### Bước 2: Tạo Keys & Ký số
```bash
sudo pacman -S sbctl
sbctl status                # Phải có: "Setup Mode: ✔ Enabled"

# Tạo chìa khóa
sudo sbctl create-keys
sudo sbctl enroll-keys -m   # -m: giữ khóa Microsoft cho Windows

# Xem file thiếu chữ ký
sudo sbctl verify

# Ký số (cờ -s = tự động ký lại khi update OS)
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/EFI/refind/refind_x64.efi
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI

# Kiểm tra — tất cả phải ✔ xanh
sudo sbctl verify
```

### Bước 3: Bật Secure Boot
Khởi động lại → BIOS → *Security* → *Secure Boot* → **Enabled** → `F10` lưu.

---

# Phần 3: Giao diện Desktop (Hyprland + UWSM + SDDM)

## 3.1. Cài đặt Hyprland & các công cụ

> [!NOTE]
> Đây là danh sách gói gộp theo nhóm chức năng. Bạn có thể cài từng nhóm hoặc cài tất cả cùng lúc.

### Nhóm 1: Hyprland Core & WM
```bash
yay -S hyprland hyprlock hypridle hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk uwsm sddm
```

### Nhóm 2: Thanh tác vụ, Thông báo, Launcher
```bash
yay -S waybar swaync rofi-wayland
```

### Nhóm 3: Hình nền, Clipboard, Screenshot
```bash
yay -S awww wl-clipboard cliphist grim slurp
```

### Nhóm 4: File Manager & công cụ hỗ trợ
```bash
yay -S thunar thunar-volman thunar-archive-plugin tumbler ffmpegthumbnailer gvfs polkit dbus gnome-keyring
```

### Nhóm 5: Terminal, Shell, Font
```bash
yay -S kitty zsh fastfetch htop cozette-otb ipa-fonts noto-fonts
```

### Nhóm 6: Trình duyệt, Editor
```bash
yay -S firefox
yay -S visual-studio-code-bin    # VS Code chính thức của Microsoft
yay -S sublime-text-4
```

### Nhóm 7: Hiển thị, Độ sáng, Tiện ích
```bash
yay -S nwg-displays brightnessctl nwg-look
```

## 3.2. Tải & Áp dụng Dotfiles

```bash
cd ~
git clone https://github.com/HighDelay/dotfiles.git
cd dotfiles/
cp -rv .* ~/
cd ~
rm -rf .git    # Xóa .git của dotfiles, không phải .git của bạn
```

## 3.3. Khởi chạy Hyprland lần đầu

Lệnh khởi động: `start-hypland` hoặc `Hyprland` (không dùng `sudo`).

### Khắc phục màn hình đen (Nvidia)
```bash
nano ~/.zprofile
```
Thêm:
```bash
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec start-hypland
fi
```

### File cấu hình tối thiểu (nếu vẫn lỗi)
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

## 3.4. Cài SDDM & UWSM (Display Manager chuẩn)

> [!IMPORTANT]
> SDDM thay thế hoàn toàn cơ chế auto-login qua Getty (TTY). UWSM quản lý phiên Hyprland qua systemd, giúp hệ thống ổn định và cô lập ứng dụng tốt hơn.

```bash
sudo pacman -S uwsm sddm
sudo systemctl enable sddm.service
```

### Xóa auto-login Getty cũ (nếu có)
```bash
sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

### Cấu hình hyprland.conf cho UWSM

**Xóa 3 dòng cũ (nếu có):**
```bash
# XÓA:
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user start hyprland-session.target
```

**Thay bằng các dòng khởi động chuẩn UWSM:**
```bash
# --- Startup (Chuẩn hóa UWSM) ---
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

> [!TIP]
> **Quy tắc UWSM:** Mọi app đồ họa chạy lâu dài đều nên bọc bằng `uwsm app --`. Ngoại lệ: các lệnh trigger nhanh như `swaync-client -t -sw`, `brightnessctl`, `wpctl` thì KHÔNG CẦN.

### Chuyển biến môi trường sang UWSM
Tạo file `~/.config/uwsm/env`:
```bash
mkdir -p ~/.config/uwsm
nano ~/.config/uwsm/env
```
Nội dung:
```bash
XCURSOR_SIZE=24
QT_QPA_PLATFORMTHEME=qt6ct
GVIM_ENABLE_WAYLAND=1

XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland

# NVIDIA
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
```

> [!WARNING]
> Lưu ý dùng `qt6ct` (không phải `qt5ct`). Cần cài package `qt6ct` trước: `sudo pacman -S qt6ct`.

### Chuẩn hóa services (dùng systemd thay exec-once)
Các app có sẵn service file nên bật bằng systemd:
```bash
systemctl --user enable --now hyprpolkitagent.service
systemctl --user enable --now pipewire.service
systemctl --user enable --now swaync.service
systemctl --user enable --now waybar.service
systemctl --user enable --now wireplumber.service
systemctl --user enable --now hypridle.service
```

Kiểm tra:
```bash
systemctl --user list-unit-files --type=service --state=enabled
```

### Reboot & Chọn session
Khởi động lại. Tại màn hình SDDM → chọn **Hyprland (uwsm managed)**.

### Cấu hình SDDM Auto-login (KHÔNG KHUYẾN KHÍCH)

> [!CAUTION]
> Auto-login qua SDDM sẽ khiến PAM không truyền mật khẩu cho GNOME Keyring → Chrome, VS Code sẽ hỏi mật khẩu Keyring mỗi lần mở.

```bash
sudo mkdir -p /etc/sddm.conf.d
sudo nano /etc/sddm.conf.d/autologin.conf
```
```ini
[Autologin]
User=neitnd
Session=hyprland
```

## 3.5. Cấu hình Rofi mở app qua UWSM

Mở `~/.config/rofi/config.rasi`, thêm vào block `configuration {}`:
```rasi
run-command: "uwsm app -- {cmd}";
```

## 3.6. GNOME Keyring (Quản lý mật khẩu)

Khi mở Chrome/VS Code, hệ thống yêu cầu tạo mật khẩu Keyring → **chọn mật khẩu trùng với mật khẩu đăng nhập Linux** để PAM tự động mở khóa.

```bash
sudo pacman -S seahorse    # Công cụ quản lý khóa GUI
```

Kiểm tra PAM đã cấu hình:
```bash
sudo nano /etc/pam.d/sddm
```
Đảm bảo có:
```
auth optional pam_gnome_keyring.so
session optional pam_gnome_keyring.so auto_start
```

> [!TIP]
> Dùng `seahorse` từ Rofi để xem/sửa/xóa các khóa. Khi đổi mật khẩu user, cần vào seahorse đổi pass Keyring tương ứng.

---

# Phần 4: Âm thanh, Đa phương tiện & Bluetooth

## 4.1. Âm thanh (Pipewire + EasyEffects)

```bash
# Đã cài ở bước trước. Kiểm tra:
yay -S pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack
yay -S easyeffects lsp-plugins
```

### Khử nhiễu Micro
1. Mở EasyEffects từ Rofi.
2. Chọn tab **Input** → **Add Effect** → chọn **RNNoise** (Noise Removal).
3. Mở `pavucontrol` (Volume Control) → tab **Input Devices** → chọn EasyEffects làm mặc định.

### Fix lỗi EasyEffects không có tín hiệu
Mở Settings của EasyEffects → chọn lại thiết bị vào/ra cụ thể thay vì "Default" hoặc "Auto".

## 4.2. Độ sáng & Âm lượng

```bash
yay -S brightnessctl    # Đã cài
```

Phím tắt đã cấu hình trong `hyprland.conf`:

| Phím tắt | Chức năng |
|---|---|
| `Super+Shift+U` | Tăng volume |
| `Super+Shift+D` | Giảm volume |
| `Super+Ctrl+U` | Tăng độ sáng |
| `Super+Ctrl+D` | Giảm độ sáng |
| `XF86MonBrightnessUp/Down` | Phím vật lý tăng/giảm sáng |
| `XF86AudioRaiseVolume/Lower/Mute` | Phím vật lý âm lượng |

## 4.3. Bluetooth

```bash
sudo pacman -S bluez bluez-utils blueman
```
Mở app Blueman từ Rofi để kết nối thiết bị.

**Mở micro tai nghe Bluetooth:** Chuột phải vào thiết bị trong Blueman → chọn profile **Head Set**.

## 4.4. Camera Laptop

```bash
ls /dev/video*                      # Kiểm tra phần cứng (nhớ mở khóa vật lý cam)
sudo usermod -aG video $USER        # Cấp quyền
```
Kiểm tra trên các trang web test cam online.

---

# Phần 5: Công cụ & Tiện ích

## 5.1. Viết tiếng Việt (Fcitx5 + Bamboo)

```bash
yay -S fcitx5-bamboo fcitx5-im
```

Cấu hình:
1. Mở `fcitx5-configtool` từ Rofi.
2. Cột phải → bỏ tích *Only Show Current Language* → tìm "bamboo" → thêm sang cột trái.
3. Thứ tự: `Keyboard - English (US)` → `Bamboo`.
4. Để dùng VNI thay Telex: chuột phải vào Bamboo → chọn VNI.

Trong `hyprland.conf` (nếu chưa dùng UWSM):
```bash
env = GTK_IM_MODULE,fcitx
env = QT_IM_MODULE,fcitx
env = XMODIFIERS,@im=fcitx
env = GLFW_IM_MODULE,ibus
exec-once = fcitx5 -d
```

Phím chuyển ngôn ngữ: **Ctrl + Space**.

## 5.2. Đồng bộ giờ Dual Boot

```bash
sudo ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
timedatectl set-local-rtc 1 --adjust-system-clock    # Dùng Local time (tương thích Windows)
sudo hwclock --systohc
sudo timedatectl set-ntp true                          # Đồng bộ qua Internet

timedatectl    # Kiểm tra
```

## 5.3. Zsh & Powerlevel10k

1. Cài Oh My Zsh (theo trang chủ, dùng `curl`).
2. Cài plugins:
   ```bash
   # zsh-autosuggestions
   git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

   # zsh-syntax-highlighting
   git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

   # zsh-completions
   git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions

   # powerlevel10k
   git clone --depth=1 https://github.com/romkatv/powerlevel10k ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
   ```
3. Chỉnh `~/.zshrc`:
   ```bash
   ZSH_THEME="powerlevel10k/powerlevel10k"
   plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
   # Đặt TRÊN dòng source "$ZSH/oh-my-zsh.sh":
   fpath+=(<đường-dẫn-zsh-completions>/src $fpath)
   ```
4. Mở terminal, gõ `zsh` để chạy wizard cấu hình giao diện p10k.

## 5.4. Sublime Text — Mở nhiều cửa sổ

```bash
mkdir -p ~/.local/share/applications/
cp /usr/share/applications/sublime-text.desktop ~/.local/share/applications/
nano ~/.local/share/applications/sublime-text.desktop
```
Thay dòng `Exec` đầu tiên bằng:
```bash
Exec=bash -c 'if pgrep -x "sublime_text" > /dev/null; then /usr/bin/subl -n "%F"; else /usr/bin/subl "%F"; fi'
```

## 5.5. Copy/Paste & Điều khiển con trỏ (Kitty/Zsh)

Các tổ hợp phím `Ctrl+Shift+C`, `Ctrl+Shift+V`, `Ctrl+Delete`, `Shift+Mũi tên` đã config trong `~/.config/kitty/kitty.conf` và `~/.zshrc`.

Thêm chế độ Vim trong zsh:
```bash
# Thêm vào ~/.zshrc:
bindkey -v
```

### Scrollback (xem lại lịch sử terminal)
Gán `Ctrl+Shift+H` cho `show_scrollback` trong `kitty.conf`, cấu hình mở bằng `nvim` để tránh lỗi mã màu.

## 5.6. Chrome — Drag and Search, Middle Click Scroll

```bash
nano ~/.config/chrome-flags.conf
```
Thêm:
```
--enable-blink-features=MiddleClickAutoscroll
```

## 5.7. Zoom màn hình

Đã cấu hình phím tắt `Super+Shift+MouseUp/Down` trong `hyprland.conf` và script `~/.config/hypr/zoom.sh` (đã cấp quyền thực thi).

## 5.8. Remote Desktop

### Local (LAN) — WayVNC
```bash
sudo pacman -S wayvnc
wayvnc 0.0.0.0                    # Giữ terminal mở
ip a                               # Xem IP nội bộ
```
Trên điện thoại: tải VNC Viewer → nhập IP → connect.

### Remote (Internet) — RustDesk

**Cài XDG Desktop Portal đúng:**
```bash
sudo pacman -Rns xdg-desktop-portal-gnome xdg-desktop-portal-kde xdg-desktop-portal-wlr
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```

**Cấu hình Portal cho Screencast:**
```bash
mkdir -p ~/.config/xdg-desktop-portal
nano ~/.config/xdg-desktop-portal/portals.conf
```
```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.RemoteDesktop=hyprland
```

**Cấu hình xdph.conf:**
```bash
nano ~/.config/hypr/xdph.conf
```
```ini
screencopy {
    max_fps = 60
    allow_token_by_default = true
}
```

**Fix lỗi hỏi chọn màn hình mỗi lần kết nối:**
Do RustDesk không lưu được `wayland_restore_token`, cách tốt nhất là cho GUI RustDesk chạy ngầm:
```bash
# Thêm vào hyprland.conf:
exec-once = uwsm app -- rustdesk --tray
```
Lần đầu kết nối → tick "Remember this selection" → từ đó về sau không hỏi nữa.

## 5.9. Quản lý Dotfiles với Stow

```bash
sudo pacman -S stow
```

### Backup .config
```bash
mkdir -p ~/neitnd_dotfiles/.config && cd ~/neitnd_dotfiles && for item in hypr waybar cmus htop swaync rofi kitty wallpaper_custom fastfetch MangoHud easyeffects fcitx5 nwg-displays chrome-flags.conf mimeapps.list mpd rustdesk xdg-desktop-portal uwsm sublime-text; do [ -e ~/.config/"$item" ] && [ ! -L ~/.config/"$item" ] && [ ! -e .config/"$item" ] && mv ~/.config/"$item" .config/; done && stow .
```

### Backup .local
```bash
mkdir -p ~/neitnd_dotfiles/.local/share && cd ~/neitnd_dotfiles && [ -e ~/.local/share/fonts ] && [ ! -L ~/.local/share/fonts ] && [ ! -e .local/share/fonts ] && mv ~/.local/share/fonts .local/share/ && stow .

mkdir -p ~/neitnd_dotfiles/.local/share/applications && cd ~/neitnd_dotfiles && [ -e ~/.local/share/applications/sublime_text.desktop ] && [ ! -L ~/.local/share/applications/sublime_text.desktop ] && [ ! -e .local/share/applications/sublime_text.desktop ] && mv ~/.local/share/applications/sublime_text.desktop .local/share/applications/ && stow .
```

### Backup các file gốc
```bash
cd ~/neitnd_dotfiles && for item in .zshrc .p10k.zsh .zprofile .gitconfig .vimrc; do [ -e ~/"$item" ] && [ ! -L ~/"$item" ] && [ ! -e "$item" ] && mv ~/"$item" ./ && stow .; done
```

### Backup EasyEffects Preset
```bash
# Preset nằm ở ~/.local/share/easyeffects/output/ (KHÔNG phải .config)
mkdir -p ~/neitnd_dotfiles/.local/share/easyeffects/output/
cp ~/dotfiles/easyeffects-presets/HighDelay\'s\ EZFx\ Preset.json ~/neitnd_dotfiles/.local/share/easyeffects/output/
cd ~/neitnd_dotfiles && stow .
```

> [!WARNING]
> Phần mềm EasyEffects phiên bản mới đã chuyển thư mục preset từ `~/.config/easyeffects/output/` sang `~/.local/share/easyeffects/output/`. Nếu để preset ở thư mục cũ, EasyEffects sẽ tự động di chuyển và xóa file cũ — khiến file bị mất trong Git!

### Ignore file cho Stow
```bash
echo -e "\\.git\n\\.gitignore\n\\.stow-local-ignore\nREADME\\.md\narch_install\\.md\nsystem_guide\\.md" > ~/neitnd_dotfiles/.stow-local-ignore
cd ~/neitnd_dotfiles && stow -R .
```

> [!NOTE]
> `stow -R .` sẽ tạo lại symlink nhưng **có thể không xóa** symlink cũ đã bị ignore. Cần xóa thủ công nếu phát hiện (ví dụ: `rm -f ~/.git` nếu nó là symlink).

## 5.10. Mạng Wi-Fi

### Rescan Wi-Fi
```bash
nmcli device wifi rescan
nmtui
```

### Giao diện mạng GUI
```bash
sudo pacman -S network-manager-applet
```
Mở từ Rofi hoặc icon trên Waybar.

### Phát Wi-Fi Hotspot
```bash
yay -S linux-wifi-hotspot
sudo pacman -S dnsmasq hostapd
```
- Kiểm tra card Wi-Fi: `nmcli device`
- Kiểm tra khả năng thu/phát đồng thời: `iw list | grep -A 10 "valid interface combinations"`
- **Lưu ý:** IdeaPad Gaming 3 chỉ có `channel <= 1` → phải chọn channel hotspot trùng channel Wi-Fi đang kết nối.
- Xem channel: `nmcli device wifi`

---

# Phần 6: Quản lý phần cứng Lenovo

## 6.1. Conservation Mode (Bảo trì pin)
```bash
# Xem (1 = bật, 0 = tắt)
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Bật (sạc đến ~60% rồi dừng)
echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Tắt (sạc đầy 100%)
echo 0 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

## 6.2. Chế độ hiệu năng (Platform Profile)
```bash
cat /sys/firmware/acpi/platform_profile_choices    # low-power balanced performance custom
cat /sys/firmware/acpi/platform_profile            # Xem hiện tại

echo performance | sudo tee /sys/firmware/acpi/platform_profile   # Game
echo balanced | sudo tee /sys/firmware/acpi/platform_profile      # Thường
echo low-power | sudo tee /sys/firmware/acpi/platform_profile     # Tiết kiệm
```

## 6.3. Gập màn hình Laptop (Lid Switch)

Cấu hình systemd:
```bash
sudo nano /etc/systemd/logind.conf
```
Sửa (bỏ # và đặt giá trị):
```bash
HandlePowerKey=ignore
HandleLidSwitch=ignore
```

Cấu hình hành vi trong `hyprland.conf`:
```bash
# Gập màn → Khóa máy & tắt tín hiệu màn hình
bindl = , switch:on:Lid Switch, exec, loginctl lock-session && hyprctl dispatch dpms off
# Mở màn → Bật lại
bindl = , switch:off:Lid Switch, exec, hyprctl dispatch dpms on
```

Cấu hình trong `hypridle.conf`:
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

# Phần 7: Bảo trì & Khắc phục sự cố

## 7.1. Tạo Swap File

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Thêm vào /etc/fstab:
# /swapfile none swap defaults 0 0

# Giảm swappiness (tùy chọn):
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
```

## 7.2. Bật SSD TRIM & OOM Protection

```bash
sudo systemctl enable --now fstrim.timer
sudo systemctl enable --now systemd-oomd
```

## 7.3. Tường lửa (UFW)

```bash
sudo pacman -S ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw
```

## 7.4. Cài thêm tiện ích thiếu

```bash
sudo pacman -S imv xarchiver unzip unrar p7zip nwg-look qt6ct
```

## 7.5. Cập nhật hệ thống

```bash
# Đọc tin tức trước: https://archlinux.org/news/
sudo pacman -Syu          # Update official repos
yay -Sua                  # Update AUR
paccache -r               # Dọn cache gói cũ
```

## 7.6. Khắc phục: Mất rEFInd EFI

### Cách 1: Chroot cài lại
```bash
# Boot vào Arch ISO
mount /dev/nvme0n1p3 /mnt          # Mount Root
mount /dev/nvme0n1p1 /mnt/boot     # Mount EFI
arch-chroot /mnt
refind-install
exit && umount -R /mnt && reboot
```

### Cách 2: Dùng efibootmgr
```bash
efibootmgr -c -d /dev/nvme0n1 -p 1 -L "rEFInd" -l "\\EFI\\refind\\refind_x64.efi"
efibootmgr                          # Kiểm tra
efibootmgr -o XXXX,YYYY             # Ưu tiên boot order
```

### Dự phòng Fallback
```bash
sudo mkdir -p /boot/EFI/BOOT
sudo cp /boot/EFI/refind/refind_x64.efi /boot/EFI/BOOT/BOOTX64.EFI
```

## 7.7. Khắc phục: Treo khi tắt màn laptop qua nwg-displays

**Tái hiện:** Tắt màn laptop qua GUI khi dùng màn ngoài → tắt máy → rút màn ngoài → bật lại → treo.

**Fix:**
1. Nhấn Tab ở icon Arch trên rEFInd → chọn **single user**.
2. Nhập password sudo user.
3. ```bash
   nano /home/neitnd/.config/hypr/hyprland.conf
   ```
4. Comment dòng `source = ...monitors.conf` bằng `#`.
5. Bỏ comment dòng `monitor=,preferred,auto,auto`.
6. Lưu → reboot.
7. Sau khi vào được, sửa lại:
   ```
   monitor = , preferred, auto, 1
   source = ~/.config/hypr/monitors.conf
   ```

---

> [!TIP]
> Xem thêm file `system_guide.md` để biết các hướng dẫn nâng cao: cài theme Catppuccin Mocha, quản lý phần cứng Lenovo chi tiết, bảo mật DNS, và tips dành cho người dùng Windows chuyển sang.
