# Arch Linux Dual Boot Installation Guide (No USB)

## 1. Booting the Arch ISO without a USB
Thay vì sử dụng USB, chúng ta có thể tận dụng tính năng tự phát hiện file `.efi` trong phân vùng FAT32 của hệ thống:
1. Tạo một phân vùng nhỏ (khoảng 3GB) và định dạng nó là `FAT32`.
2. Giải nén (hoặc mount) toàn bộ nội dung của file ISO Arch Linux và copy vào phân vùng vừa tạo.
3. Khởi động lại máy, nhấn phím `F12` (hoặc phím tắt tương ứng của máy bạn) để chọn Boot Menu và boot vào phân vùng đó.
4. Chọn boot vào **Arch Linux install medium**.
5. Chọn khởi động vào chế độ **minimal Arch Linux**.

## 2. Kết nối Mạng (Wi-Fi)
Ở giai đoạn cài đặt ban đầu (môi trường ISO), bạn cần dùng lệnh `iwctl` để kết nối Wi-Fi:
```bash
# Gõ iwctl để vào giao diện quản lý mạng không dây
iwctl

# Tìm thiết bị mạng của bạn (ví dụ: wlan0)
[iwd]# device list

# Quét mạng Wi-Fi
[iwd]# station wlan0 scan

# Liệt kê danh sách các mạng Wi-Fi xung quanh
[iwd]# station wlan0 get-networks

# Kết nối vào mạng (nhập mật khẩu khi được yêu cầu)
[iwd]# station wlan0 connect "Tên_WiFi"

# Thoát iwctl
[iwd]# exit
```
> **Lưu ý sau khi cài đặt xong:** Khi đã cài đặt Arch cơ bản vào máy, cách phổ biến và dễ dàng nhất là sử dụng công cụ NetworkManager thông qua `nmtui`:
> 1. Chạy lệnh `nmtui` trong terminal để mở giao diện quản lý mạng.
> 2. Nếu lệnh lỗi, bật dịch vụ bằng: `sudo systemctl enable --now NetworkManager`.
> 3. Kiểm tra mạng thành công bằng lệnh: `ping -c 3 google.com`.

## 3. Phân vùng và Mount (Gắn) Ổ đĩa
Kiểm tra danh sách các phân vùng hiện có:
```bash
lsblk
```
Bạn có thể xem chi tiết một phân vùng để chắc chắn:
```bash
cgdisk /dev/nvme0n1p1
```
Giả sử (bạn **cần thay đổi** tên `/dev/nvme...` cho phù hợp với máy của mình):
- `/dev/nvme0n1p4`: Phân vùng chính cho hệ điều hành Arch (vd: 240GB).
- `/dev/nvme0n1p3`: Phân vùng EFI mới cho Arch (vd: 700MB).

Mount phân vùng Root và tạo cấu trúc thư mục Boot & Home:
```bash
# Mount phân vùng Root
mount /dev/nvme0n1p4 /mnt

# Tạo các thư mục cần thiết
mkdir -p /mnt/{home,boot}

# Mount phân vùng EFI vào /boot
mount /dev/nvme0n1p3 /mnt/boot

# Kiểm tra lại việc mount xem đã chính xác chưa
lsblk
```

## 4. Cài đặt Hệ điều hành Cơ bản
Cài đặt các gói cốt lõi của Linux (Base system, Kernel và Firmware):
```bash
pacstrap -K /mnt base linux linux-firmware base-devel
```
Tạo file cấu hình phân vùng `fstab`:
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```
> *Lưu ý: Cờ `-U` trong `genfstab` sẽ giúp hệ thống tự động dùng mã định danh UUID thay vì tên đường dẫn `/dev/...` dễ bị thay đổi. Bạn có thể kiểm tra lại file bằng lệnh `cat /mnt/etc/fstab`.*

Chuyển quyền điều khiển vào hệ thống mới (Chroot):
```bash
arch-chroot /mnt
```

## 5. Cấu hình Cơ bản trong Chroot
### Thiết lập Mật khẩu Root và Tạo User
```bash
# Đổi mật khẩu cho user root
passwd

# Tạo user mới (ví dụ: neitnd) và cấp nhóm sudo (users)
useradd -g users -m -s /bin/bash neitnd
passwd neitnd
```
Cài đặt trình soạn thảo `nano` và cấp quyền sudo cho user mới:
```bash
pacman -S nano
nano /etc/sudoers.d/neitnd
```
Viết nội dung sau vào file, lưu lại và thoát (Ctrl+O, Enter, Ctrl+X):
```text
neitnd ALL=(ALL:ALL) ALL
```

### Cấu hình Ngôn ngữ, Múi giờ & Hostname
```bash
# 1. Cấu hình Locale
nano /etc/locale.gen
# -> Nhấn Ctrl+W để tìm kiếm "en_US.UTF-8", xóa dấu # ở đầu dòng để bỏ comment.
locale-gen

nano /etc/locale.conf
# -> Thêm dòng nội dung: LANG=en_US.UTF-8

# 2. Cấu hình Timezone (Ví dụ: Hồ Chí Minh)
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

# 3. Cấu hình Hostname (Tên thiết bị)
nano /etc/hostname
# -> Thêm tên máy, ví dụ: arch-lig3
```

## 6. Cài đặt Bootloader (rEFInd) và Dịch vụ Mạng
```bash
# Cài đặt NetworkManager và boot manager rEFInd
pacman -S networkmanager refind

# Cài đặt rEFInd vào phân vùng EFI
refind-install

# Đăng ký bật NetworkManager tự động khởi chạy khi mở máy
systemctl enable NetworkManager
```

**Quan trọng: Cấu hình Boot với UUID cho rEFInd**
Tìm UUID của phân vùng Root:
```bash
lsblk -f
# Tại cột UUID, hãy copy chuỗi ký tự của dòng ứng với phân vùng có điểm mount là `/` 
# Ví dụ: a1b2c3d4-e5f6-7890-1234-56789abcdef0
```
Mở file cấu hình boot của rEFInd và thay đổi `root=/dev/nvme...` thành `root=UUID=<chuỗi-uuid>`:
```bash
nano /boot/refind_linux.conf
# Ví dụ thay đổi ở mục "Boot with standard options":
# "Boot with standard options"  "rw root=UUID=a1b2c3d4-e5f6-7890-1234-56789abcdef0 quiet"
```

Hoàn tất giai đoạn này và Khởi động lại:
```bash
exit
umount -R /mnt
reboot
```

---

## 7. Cấu hình sau Cài đặt & Cài đặt Yay (AUR Helper)
Khởi động vào Arch từ giao diện chọn OS của rEFInd (chọn chế độ minimal/boot bình thường nếu bị lỗi giao diện đồ họa). Đăng nhập bằng user bạn vừa tạo.

Khởi tạo và làm mới cấu hình rEFInd:
```bash
sudo rm -rf /boot/refind_linux.conf
sudo mkrlconf
ls -la /boot
```

Cài đặt trình quản lý gói AUR (Yay):
```bash
sudo pacman -S git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

*Ghi chú thêm về thiết lập quyền User (Nếu làm ở bước 5 bị lỗi):*
```bash
sudo useradd -m -g users -G wheel neitnd
sudo passwd neitnd 

# Cấp quyền cho nhóm wheel
sudo EDITOR=nano visudo 
# -> Tìm dòng "# %wheel ALL=(ALL:ALL) ALL" và xóa dấu # ở đầu dòng đi
```

## 8. Cài đặt Nvidia Driver
```bash
# Cài đặt công cụ DKMS
yay -S dkms

# Cấu hình DKMS để tương thích khóa bảo mật
sudo nano /etc/dkms/framework.conf
# -> Tìm đến cuối tệp và thêm (hoặc bỏ dấu #) ở dòng lệnh trỏ tới khóa bảo mật của bạn:
# sign_tool="/usr/bin/kmodsign sha512 /usr/share/secureboot/keys/db/db.key /usr/share/secureboot/keys/db/db.pem" 

# Cài driver (Nếu gặp lỗi version, chạy `yay -Syu` và `yay -S linux linux-headers` trước)
yay -S nvidia-dkms nvidia-utils libva-nvidia-driver linux-headers
sudo dkms autoinstall
```

Cấu hình Initramfs bổ sung module cho Nvidia:
```bash
sudo nano /etc/mkinitcpio.conf
# -> Tìm dòng MODULES=() và bổ sung các thành phần sau vào trong ngoặc:
# MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)

# Sau khi lưu tệp, build lại initramfs:
sudo mkinitcpio -P
```

Thêm tham số Kernel hỗ trợ Nvidia vào rEFInd:
```bash
sudo nano /boot/refind_linux.conf
# -> Tìm dòng "Boot with standard options" và nối thêm: `nvidia_drm.modeset=1 nvidia_drm.fbdev=1` vào trong ngoặc kép.
# Ví dụ: "Boot with standard options"  "root=PARTUUID=xxxx-xxxx rw rootfstype=ext4 nvidia_drm.modeset=1 nvidia_drm.fbdev=1"
```

Kiểm tra xem driver Nvidia đã được load thành công chưa:
```bash
lsmod | grep nvidia
```

---

## 9. Thiết lập Secure Boot với `sbctl`
*(Bước này có thể làm ngay bây giờ hoặc để lại sau khi đã thiết lập xong theme cho rEFInd).*

**Bước 0: Tạm dừng BitLocker trên Windows (Bắt buộc)**
*Cảnh báo: Việc xóa khóa trong BIOS sẽ ngay lập tức kích hoạt khóa an toàn của BitLocker.*
1. Khởi động vào Windows > Mở *Manage BitLocker*.
2. Chọn **Suspend protection** (Tạm dừng bảo vệ) ở ổ `C:`.

**Bước 1: Đưa BIOS Lenovo về "Setup Mode"**
1. Khởi động lại máy, nhấn liên tục `F2` để vào BIOS.
2. Chuyển sang tab *Security* > mục *Secure Boot*.
3. Bấm vào *Clear All Secure Boot Keys* (hoặc *Reset to Setup Mode / Delete All Keys* tùy phiên bản). Bấm *Enter* > *Yes*.
4. Trạng thái (Platform Mode) sẽ chuyển từ *User Mode* sang *Setup Mode*. Nhấn `F10` lưu và boot lại vào Arch.

**Bước 2 & 3: Cài đặt sbctl và Tạo Keys**
```bash
sudo pacman -S sbctl
sbctl status 
# => Kết quả bắt buộc phải có dòng: "Setup Mode: ✔ Enabled".

# Tạo chìa khóa riêng và nạp vào Mainboard 
# (Lệnh số 2 có chữ `-m` rất quan trọng để giữ lại khóa của Microsoft giúp Windows vẫn khởi động được)
sudo sbctl create-keys
sudo sbctl enroll-keys -m

sbctl status 
# => Lúc này bo mạch chủ đã bị khóa lại, dòng Setup Mode sẽ là "✔ Disabled".
```

**Bước 4: Ký số cho rEFInd và Kernel**
```bash
# Xem các file đang thiếu chữ ký (chú ý các file bị dấu ✘ đỏ)
sudo sbctl verify

# Thực hiện ký số bằng cờ -s (Cờ này nhắc hệ thống tự động ký lại mỗi khi bạn update OS)
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/EFI/refind/refind_x64.efi
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
# Lưu ý: Thay đổi đường dẫn cho chính xác với những file efi bị gạch chéo đỏ ở lệnh verify trên.

# Kiểm tra lại lần cuối, tất cả phải chuyển sang dấu ✔ xanh
sudo sbctl verify
```

**Bước 5: Bật lại Secure Boot**
Khởi động lại máy > Vào lại BIOS > Tab *Security* > *Secure Boot*, chuyển trạng thái thành **Enabled**. Nhấn `F10` lưu lại.

---

## 10. Cài đặt Giao diện Desktop (Hyprland + Dotfiles)
Tại đây, chúng ta sẽ cài đặt WM Hyprland dựa trên cấu hình lấy từ `GitHub.com/HighDelay/dotfiles.git`.

```bash
# Cài đặt Hyprland và hàng loạt công cụ liên quan
# Lưu ý: Nếu bạn có hybrid GPU hoặc màn hình phụ, có thể bạn sẽ cần cài thêm các package tương ứng.
yay -Sy hyprland hyprlock xdg-desktop-portal-hyprland waybar swww grim slurp wl-clipboard wtype cliphist rofi-wayland swaync htop cozette-otb ipa-fonts noto-fonts zsh fastfetch thunar thunar-volman thunar-archive-plugin polkit hyprpolkitagent dbus gnome-keyring tumbler ffmpegthumbnailer gvfs nwg-look cmus mpd mpc rmpc kitty lsp-plugins easyeffects fcitx5-bamboo fcitx5-im pipewire pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack brightnessctl nwg-displays 

# Trở về thư mục Home, tải và apply dotfiles
cd ~
git clone https://github.com/HighDelay/dotfiles.git
cd dotfiles/
cp -rv .* ~/
cd ~
rm -rf .git
```

**Khởi chạy Hyprland:**
Lệnh khởi động chuẩn là `start-hypland` hoặc `Hyprland` (*Không sử dụng sudo*).

**Khắc phục lỗi màn hình đen với Nvidia/XDG:**
Mở cấu hình profile bằng dòng lệnh: `nano ~/.zprofile`, thêm đoạn sau vào cuối tệp:
```bash
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

# Tự động khởi chạy Hyprland khi đăng nhập thành công ở TTY1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec start-hypland
fi
```

**Nếu lỗi hiển thị với Nvidia vẫn tiếp diễn**, tạo file cấu hình cơ bản cho Hyprland:
```bash
mkdir -p ~/.config/hypr

cat <<EOF > ~/.config/hypr/hyprland.conf
# Biến môi trường quan trọng cho Nvidia
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

cursor {
    no_hardware_cursors = true
}

# Cấu hình màn hình (Sửa thông số này sau khi vào được giao diện)
monitor=,preferred,auto,auto

# Phím tắt chống kẹt (Mở Terminal và Thoát Hyprland)
bind = SUPER, Q, exec, kitty
bind = SUPER, M, exit
EOF
```

## 11. Các công cụ Tùy biến Mở rộng
- Trình duyệt web: `yay -Sy firefox`
- Phím tắt tuỳ chỉnh (sxhkd): `nano ~/.config/sxhkd/sxhkdrc`. Mặc định phím gọi terminal là `Super + Enter`.
- Giao diện và Icon: Bạn có thể tải các theme và mở ứng dụng *Customize Look and Feel* để áp dụng thay đổi.
- Cài Theme cho rEFInd: Lên trang chủ plugin/theme trên Github qua Firefox và làm theo hướng dẫn README của họ.

### Thiết lập Zsh và Powerlevel10k
1. Cài đặt Oh My Zsh qua trang chủ (`curl ...`).
2. Tải các plugin vào Oh My Zsh (Sử dụng `git clone` theo trang chủ các plugin): 
   - `zsh-autosuggestions`
   - `zsh-syntax-highlighting`
   - `zsh-completions` (Cần add thư mục vào `.zshrc`)
   - `powerlevel10k` (Theme giao diện)
3. Chỉnh sửa cấu hình `~/.zshrc`:
```bash
nano ~/.zshrc

# Đổi theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Thêm plugin (bỏ vào trong ngoặc đơn, cách nhau bởi dấu cách)
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Kích hoạt zsh-completions (Đặt phía TRÊN dòng `source "$ZSH/oh-my-zsh.sh"`)
fpath+=(<đường-dẫn-của-zsh-completions>/src $fpath)
```
4. Cuối cùng mở terminal gõ `zsh` để đi qua các bước cài đặt thiết kế UI tự động của *powerlevel10k*.

## 12. Tự Động Đăng Nhập (Auto Login)
Bỏ qua bước gõ mật khẩu tại terminal để boot thẳng vào môi trường Hyprland.
```bash
# Tạo thư mục config cho getty service
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf
```
Dán cấu hình này vào (*nhớ thay `neitnd` thành tên user của bạn*):
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noreset --noclear --autologin neitnd - ${TERM}
```
Sau đó khởi động lại, máy sẽ tự động đăng nhập và chạy cấu hình `exec start-hypland` đã cấu hình ở bước ~/.zprofile.

---

## 13. Khắc phục sự cố: Mất rEFInd EFI
Nếu mục boot rEFInd bỗng dưng biến mất trong BIOS/Boot Menu nhưng các phân vùng (EFI, ext4/Root) vẫn còn nguyên vẹn.

**Cách 1: Chroot và cài lại bootloader**
1. Boot vào Arch ISO.
2. Xác định và Mount hệ thống cũ của bạn vào USB Live:
```bash
mount /dev/nvme0n1p3 /mnt       # Mount Root
mount /dev/nvme0n1p1 /mnt/boot  # Mount EFI
arch-chroot /mnt
```
3. Cài lại rEFInd (không cần kết nối mạng):
```bash
refind-install
```
> *Mẹo nhỏ: Bạn có thể tạo file Fallback boot để tự dự phòng nếu bị xoá lần nữa:*
> `sudo mkdir -p /boot/EFI/BOOT`
> `sudo cp /boot/EFI/refind/refind_x64.efi /boot/EFI/BOOT/BOOTX64.EFI`

**Cách 2: Sử dụng `efibootmgr` (Không cần cài lại)**
```bash
# Lệnh tạo lại liên kết cho rEFInd vào EFI
# (Lưu ý: -d là ổ đĩa, -p là số thứ tự phân vùng EFI (VD: 1), -l là đường dẫn chuẩn Windows)
efibootmgr -c -d /dev/nvme0n1 -p 1 -L "rEFInd" -l "\EFI\refind\refind_x64.efi"

# Kiểm tra thứ tự các lựa chọn boot
efibootmgr

# Để ưu tiên rEFInd khởi động mặc định (XXXX là ID boot của rEFInd tìm được ở lệnh trên)
efibootmgr -o XXXX,YYYY
```
Sau khi hoàn tất thì thoát chroot và khởi động lại:
```bash
exit
umount -R /mnt
reboot
```

# Arch Linux after install
## 13.5. Cài đặt mạng với nmtui
networkmanager đã cài trước đó

Mở nmtui để kết nối mạng và làm theo giao diện
```bash
nmtui
```
## 14. Cài viết tiếng Việt với fcitx5 và bamboo
Sau khi đã vào giao diện Hyprland thành công, Super+space để mở rofi, tìm và mở **fcitx5-configtool**.
Trong cửa sổ giao diện:
Nhìn sang cột bên phải (Available Input Method), bỏ tích ở ô Only Show Current Language.
Tại thanh tìm kiếm, nhập chữ bamboo.
Nhấp đúp chuột vào Bamboo (hoặc chọn nó và nhấn biểu tượng mũi tên hướng sang trái) để thêm bộ gõ này sang cột bên trái (Current Input Method).
Đảm bảo cột bên trái được sắp xếp theo đúng thứ tự:
    Keyboard - English (US)
    Bamboo
Để gõ VNI thay vì Telex thì chuột phải vào bamboo hoặc chuột trái vào đó và tìm các tùy chọn input method trên giao diện và chọn VNI.
Nhấn Apply rồi đóng cửa sổ.

Lưu ý trong nano ~/.config/hypr/hyprland.conf cần có (Sau khi cài UWSM có thể đã có cấu hình khác trong bộ dotfiles rồi, xem phần cài UWSM để biết thêm):
```bash
env = GTK_IM_MODULE,fcitx
env = QT_IM_MODULE,fcitx
env = XMODIFIERS,@im=fcitx
env = GLFW_IM_MODULE,ibus

exec-once = fcitx5 -d
```
Khởi động lại máy và nhấn Ctrl + Space để chuyển đổi ngôn ngữ.

## 15. Thiết lập lại giờ đồng bộ với window khi dualboot
Thiết lập múi giờ (Timezone) sang Việt Nam
```bash
sudo ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
```
Cấu hình Arch Linux dùng Local time (thay vì UTC) cho đồng hồ phần cứng
```bash
timedatectl set-local-rtc 1 --adjust-system-clock
```
Đồng bộ đồng hồ phần cứng (Hardware Clock)
```bash
sudo hwclock --systohc
```
Bật tính năng tự động đồng bộ giờ qua Internet (NTP)B
```bash
sudo timedatectl set-ntp true
```
Kiểm tra lại kết quả

```bash
timedatectl
```
Phải hiện như sau:
```bash
~ ❯ timedatectl
               Local time: Mon 2026-06-22 10:30:16 +07
           Universal time: Mon 2026-06-22 03:30:16 UTC
                 RTC time: Mon 2026-06-22 10:30:19
                Time zone: Asia/Ho_Chi_Minh (+07, +0700)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: yes
 
Warning: The system is configured to read the RTC time in the local time zone.
         This mode cannot be fully supported. It will create various problems
         with time zone changes and daylight saving time adjustments. The RTC
         time is never updated, it relies on external facilities to maintain it.
         If at all possible, use RTC in UTC by calling
         'timedatectl set-local-rtc 0'.
```

## 16. Cài VSCode
Phiên bản chính thức từ Microsoft (Code): Có đầy đủ bản quyền thương hiệu, đồng bộ tài khoản Microsoft/GitHub, đầy đủ Extension Marketplace của Microsoft.
```bash
yay -S visual-studio-code-bin
```

## Keyring
Khi mở ác ứng dụng như VS Code, Chrome, hay Brave, hệ thống sẽ yêu cầu bạn tạo một mật khẩu mới cho GNOME Keyring (Trình quản lý chìa khóa bảo mật). nên chọn mật khẩu của Keyring trùng hoàn toàn với mật khẩu đăng nhập tài khoản Linux.


## Copy và past và điều khiển con trỏ chuột trên kitty bằng bàn phím
Các tổ hợp phím như 'Ctrl + SHIFT + C, Ctrl + SHIFT + V, Ctrl + Delete hay Shift + Mũi tên' để điều khiển con trỏ trên kitty/zsh đã config trong:
```bash
nano ~/.config/kitty/kitty.conf

```
và 
```bash
nano ~/.zshrc
```
Khi copy sẽ tự vào clipboard đã cài bằng yay trước đó.
Ngoài ra thêm
```bash
bindkey -v
```
trong .zshrc để dùng như vim

## Cài sublimetext
yay -S sublime-text-4


## Bật tính năng show scrollback trên kitty với fix lỗi mã màu (dùng nvim)
Gán cho tổ hợp phím Ctrl + Shift + H cho show_scrollback trong ~/.config/kitty/kitty.conf và cấu hình mở nvim để tránh lỗi mã màu trong file config đó (xem file kitty.conf để biết thêm)


## Khiến sublimetext có thể mở 2 cửa sổ ở 2 workspace trên hyprland
```bash
mkdir -p ~/.local/share/applications/
cp /usr/share/applications/sublime-text.desktop ~/.local/share/applications/bash
nano ~/.local/share/applications/sublime-text.desktop

```
thay dòng Exec đầu tiên thấy bằng:
```bash
Exec=bash -c 'if pgrep -x "sublime_text" > /dev/null; then /usr/bin/subl -n "%F"; else /usr/bin/subl "%F"; fi'
```

## Fix lỗi khi tắt màn laptop trên GUI của Displays setting
Tái hiện lỗi: khi cắm màn ngoài và chỉ dùng màn ngoài (tắt màn laptop trên gui của Displays setting - nwg-display) sau đó tắt máy, rút màn ngoài và bật lại máy, lúc này tại màn hình load hyprland sẽ bị treo và không vào được hyprland, ngoài ra không thể CRT+ALT+F2 để sang TTY khác được luôn, phải đè phím nguồn để tắt máy và vào arch single user (nhấn tab ở hình arch os trên màn hình refind) để fix lỗi.
Fix lỗi:
    Nhấn tab ở hình arch os trên màn hình refind và chọn arch single user
    Nhập password của sudo user
    ```nano /home/neitng/.config/hypr/hyprland.conf```
    khóa dòng ```source = ...monitors.conf ```bằng dấu #
    mở dòng ```monitor=,preferred,auto,auto```, 
    lưu file và reboot
Sau đó sửa lại `nano /home/neitng/.config/hypr/hyprland.conf`:
    ```
    monitor = , preferred, auto, 1
    source = ~/.config/hypr/monitors.conf
    ```

## Kích hoạt tính năng Zoom màn hình với SUPER+SHIFT+MouseUp/Down
Đã cấu hình trong file hyprland.conf và scritp nano ~/.config/hypr/zoom.sh (đã cấp quyền thực thi cho nó)

## Sử dụng Camera laptop
Kiểm tra phần cứng camera (nhớ mở khóa vật lý cam nếu có):
```bash
ls /dev/video*
```
Kết quả bình thường: Bạn sẽ thấy xuất hiện các dòng như /dev/video0, /dev/video1. Thường /dev/video0 chính là webcam tích hợp của laptop.
Phân quyền cho tài khoản sử dụng Camera:
```bash
sudo usermod -aG video $USER
```
Kiểm tra cam trên các web online

## Độ sáng màn hình và âm lượng
Đã cài Brightnessctl và pipewired và pavucontral - Vlome Control , easy effect

Có thể hoặc không cần: ```sudo usermod -aG video $USER```

Dùng lệnh:
```bash
brightnessctl set +10%
brightnessctl set 10%-
brightnessctl set 60%
```
Ngoài ra còn gán phím tắt trong file hyprland.conf: 
Super+Shift+u tăng volume
Super+Shift+d giảm volume
Super+Ctrl+u tăng brightness
Super+Ctrl+d giảm brightness

## Drag and search trong chrome:
```bash
nano ~/.config/chrome-flags.conf
```
thêm vào và lưu:
```bash
--enable-blink-features=MiddleClickAutoscroll
```

## Khử nhiễu micro bằng easy effect
Mở Easy Effect bằng rofi, theo giao diện, chọn input device, chọn thêm effect và chọn rnn noise remove. 
sau đó trong pavucontrol - Volume control, chọn easy effect làm mặc định cho input device.

## Tạo symlink cấu hình với Stow
Cài Stow :
```bash
sudo pacman -S stow
```
### Khi muốn thêm file cấu hình mới
Thư mục neitnd_dotfiles/ là thư mục cần tập trung quản lý các cấu hình.
Với .config:
```bash
mkdir -p ~/neitnd_dotfiles/.config && cd ~/neitnd_dotfiles && for item in hypr waybar cmus htop swaync rofi kitty wallpaper_custom fastfetch MangoHud easyeffects fcitx5 nwg-displays chrome-flags.conf mimeapps.list mpd rustdesk xdg-desktop-portal uwsm sublime-text; do [ -e ~/.config/"$item" ] && [ ! -L ~/.config/"$item" ] && [ ! -e .config/"$item" ] && mv ~/.config/"$item" .config/; done && stow .

```
Với .local:
```bash
mkdir -p ~/neitnd_dotfiles/.local/share && cd ~/neitnd_dotfiles && [ -e ~/.local/share/fonts ] && [ ! -L ~/.local/share/fonts ] && [ ! -e .local/share/fonts ] && mv ~/.local/share/fonts .local/share/ && stow .

mkdir -p ~/neitnd_dotfiles/.local/share/applications && cd ~/neitnd_dotfiles && [ -e ~/.local/share/applications/sublime_text.desktop ] && [ ! -L ~/.local/share/applications/sublime_text.desktop ] && [ ! -e .local/share/applications/sublime_text.desktop ] && mv ~/.local/share/applications/sublime_text.desktop .local/share/applications/ && stow .

```

Với các file cấu hình khác:
```bash
cd ~/neitnd_dotfiles && for item in .zshrc .p10k.zsh .zprofile .gitconfig .vimrc; do [ -e ~/"$item" ] && [ ! -L ~/"$item" ] && [ ! -e "$item" ] && mv ~/"$item" ./ && stow .; done

mkdir -p ~/neitnd_dotfiles/.config/easyeffects/output/
cp ~/dotfiles/easyeffects-presets/HighDelay\'s\ EZFx\ Preset.json ~/neitnd_dotfiles/.config/easyeffects/output/
cd ~/neitnd_dotfiles && stow .

```

Để ignore file khi dùng stow:
```bash
echo -e "\\.git\n\\.gitignore\n\\.stow-local-ignore\nREADME\\.md\narch_install\\.md" > ~/neitnd_dotfiles/.stow-local-ignore

cd ~/neitnd_dotfiles && stow -R .
```
stow -R . sẽ tạo lại toàn bộ symlinks và có thể không xóa symlinks cũ, cần xóa thủ công.

## Remote từ xa hoặc remote local
Local dùng wayvnc `sudo pacman -S wayvnc`, 
Giữ một terminal khi chạy lệnh: `wayvnc 0.0.0.0`
Xem ip nội bộ của máy hiện tại: `ip a`, và lấy ip của wifi hoặc mạng mà thiết bị muốn remote và thiết bị này ở cùng mạng
Trên điện thoại tải VNC viewer của RealVNC hoặc app VNC nào đó, nhập ip trên và connect

Remote từ xa:
Dùng RustDesk:
Đảm bảo các port cần thiết, không xung đột:
```bash
sudo pacman -Rns xdg-desktop-portal-gnome xdg-desktop-portal-kde xdg-desktop-portal-wlr
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
```
Cấu hình khởi động nó trong các config của hyprland rồi (phải thông qua UWSM)
```bash
nano ~/.config/rustdesk/RustDesk.toml 
```
Ghi vào:
```bash
allow-wayland-screencast = true
enable-experimental-wayland = true
```
```bash
mkdir -p ~/.config/xdg-desktop-portal
nano ~/.config/xdg-desktop-portal/portals.conf
```
Ghi vào: (đã backup file)
```bash
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Screencast=hyprland
org.freedesktop.impl.portal.RemoteDesktop=hyprland
```

Tự đọng ghi nhứ lựa chọn màn hình (tránh thao tác trên máy khi kết nối từ xa)
`nano ~/.config/hypr/xdph.conf`
Thêm:
```bash
screencopy {
    max_fps = 60
    allow_token_by_default = true
}
```
Mở file cấu hình phụ của RustDesk:
```bash 
nano ~/.config/rustdesk/RustDesk_local.toml
```
Đảm bảo cấu hình token được sinh ra có dạng (ví dụ):
```bash
wayland_restore_token = "hyprland_some_random_string_token"
```
(Nếu dòng này trống hoặc bị lỗi, bạn hãy xóa hẳn dòng đó đi, khởi động lại RustDesk và thực hiện lại Bước 2 để hệ thống tạo lại token sạch).Sau khi bạn bổ sung cấu hình xdph.conf và tích chọn Remember Selection

Bươc trên có thể bị lỗi chưa fix được (không tạo token đó), phải mở GUI rustdesk để token đó lưu trong ram thì mới không phải chọn màn hình. có thể thêm vào hyprlan.conf: `exec-once = uwsm app -- rustdesk --tray` nhưng có thể tốn thêm ram. 
Hoặc dùng cách tạo script chọn màn hình:
```bash
Bước 1: Tạo Script tự động chọn màn hình
Bạn copy và chạy toàn bộ cụm lệnh này trong terminal (nó sẽ tạo một thư mục scripts và lưu file auto_share.sh vào đó, đồng thời cấp quyền thực thi):
bash
mkdir -p ~/.config/hypr/scripts
cat << 'EOF' > ~/.config/hypr/scripts/auto_share.sh
#!/bin/bash
# Lấy tên màn hình đầu tiên đang bật (ví dụ: eDP-1)
MONITOR=$(hyprctl monitors | grep Monitor | head -n 1 | awk '{print $2}')
# Tự động gửi kết quả chọn màn hình đó cho hệ thống
echo "[SELECTION]/screen:$MONITOR"
EOF
chmod +x ~/.config/hypr/scripts/auto_share.sh
Bước 2: Báo cho Portal sử dụng Script trên
Bạn mở lại file xdph.conf:
bash
nano ~/.config/hypr/xdph.conf
Sửa lại phần screencopy như sau (chú ý đường dẫn file):
ini
screencopy {
    max_fps = 60
    custom_picker_binary = /home/neitnd/.config/hypr/scripts/auto_share.sh
}
Bước 3: Áp dụng
Khởi động lại máy hoặc chạy lệnh khởi động lại portal để nó nhận cấu hình mới:
bash
systemctl --user restart xdg-desktop-portal-hyprland
```

## Thiết lập tự động mở gnome-keyring cho các app cần: chrome, vscode,...

dùng chính mật khẩu user để mở khóa Keyring ngầm bên dưới (cơ chế PAM auto-unlock). Vì đang sử dụng hệ thống tùy biến ráp nối thủ công (SDDM + UWSM + Hyprland), cơ chế chuyển tiếp mật khẩu này chưa được cấu hình.

Để xem và sửa các khóa cũ (cần cùng password với pass user), dùng seahorse, có giao diện để xóa, sửa, thêm khóa.
```bash
sudo pacman -S seahorse
```
bash
Có thể cần có các package khác nữa, để kiểm tra:
```bash
pacman -Qs gnome-keyring seahorse libsecret
```
```bash
sudo nano /etc/pam.d/sddm
```
Kiểm tra đã có các dòng:
```bash
auth optional pam_gnome_keyring.so
session optional pam_gnome_keyring.so auto_start
```
Sau đó nếu vẫn có hộp thoại yêu cầu nhập key khi mở app, hãy tích chọn không hỏi lại.
Khi nào đổi pass user thì cần vào seahorse và đổi pass của các keystore tương ứng.

## Cài SDDM và UWSM
```bash
sudo pacman -S uwsm
sudo pacman -S sddm
sudo systemctl enable sddm.service


```
Trong hyprland.conf
```bash
XÓA 3 DÒNG NÀY:
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user start hyprland-session.target
```
và sửa các dòng thành chạy với uwsm, cả khi nhấn phím tắt super+space thì rofi cũng phải mở bằng uwsm (đã bkup file cấu hình):
```bash
 --- Startup (Chuẩn hóa UWSM) ---
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

Chuyển biến môi trường sang cho UWSM từ hyprland.conf: đã backup trong ~/.config/uwsm/env
```bash
XCURSOR_SIZE=24
QT_QPA_PLATFORMTHEME=qt5ct
GVIM_ENABLE_WAYLAND=1

XDG_CURRENT_DESKTOP=Hyprland
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=Hyprland

# NVIDIA
LIBVA_DRIVER_NAME=nvidia
__GLX_VENDOR_LIBRARY_NAME=nvidia
NVD_BACKEND=direct
```
reboot và khi vào màn hình SDDM thì chọn hyprland (uwsm managed)

Về SDDM:
Vô hiệu hóa tính năng tự động đăng nhập của Getty (TTY): chỉ cần xóa file cấu hình ghi đè của Getty mà bạn đã tạo trước đó bằng lệnh sau:
```bash
sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf
```
Cấu hình Tự động đăng nhập (Auto-login) chuẩn qua SDDM và hyprland (không thực hiện/khuyến khích vì mất tính năng pam để mở keyring cho chrome, vscode,...): Tạo file cấu hình cho SDDM:
```bash
sudo mkdir -p /etc/sddm.conf.d
sudo nano /etc/sddm.conf.d/autologin.conf
```
Dán đoạn mã sau vào file (Thay thế neitng bằng tên user chính xác của bạn nếu có thay đổi):
```bash
[Autologin]
User=neitng
Session=hyprland
```
reboot

## Cấu hình rofi mở app qua uwsm: 
mờ: ~/.config/rofi/config.rasi
thêm vào 2 ngoặc nhọn của configuration:
```bash
drun-launch: "uwsm app -- {cmd}";
```

