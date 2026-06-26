
## Q1: Rofi có mở qua UWSM chưa? Các app mở qua Rofi thì sao?

### Hiện trạng: ✅ ĐÃ CHUẨN — Không cần thay đổi gì

**Bản thân Rofi:**
Trong file `~/.config/hypr/hyprland.conf`, dòng gọi Rofi đã được bọc bằng UWSM:
```bash
bind = $mainMod, SPACE, exec, uwsm app -- rofi -show drun -theme ...
```
→ Rofi được UWSM nhốt vào scope riêng. Tuy nhiên Rofi là tiến trình tồn tại rất ngắn (mở lên → bạn chọn app → nó tự tắt), nên việc bọc UWSM cho nó chủ yếu là để giữ tính nhất quán. Có cũng tốt, không có cũng không sao.

**Các app mở TỪ Rofi:**
Trong file `~/.config/rofi/config.rasi`, dòng cấu hình:
```rasi
run-command: "uwsm app -- {cmd}";
```
→ Mọi ứng dụng bạn chọn trong menu Rofi (Chrome, Thunar, Firefox...) đều tự động được bọc qua `uwsm app --` trước khi khởi chạy. Nghĩa là chúng sẽ được nhốt vào scope riêng biệt, không "dính chùm" vào Hyprland.

**Cách kiểm chứng:**
```bash
# Mở một app bất kỳ từ Rofi, rồi chạy:
systemd-cgls --user | grep app-
# Nếu thấy dòng app-com.google.Chrome-xxx.scope hoặc tương tự → đã qua UWSM
```

---

## Q2: Ứng dụng chạy Wayland Native nghĩa là gì?

### Khái niệm

Trên hệ thống Hyprland (Wayland), mỗi ứng dụng đồ họa chạy theo 1 trong 2 chế độ:

| | **Wayland Native** | **XWayland** |
|---|---|---|
| **Cơ chế** | App giao tiếp trực tiếp với Hyprland qua giao thức Wayland | App chạy qua lớp trung gian mô phỏng X11 cũ (XWayland) |
| **Hiệu năng** | Tốt nhất, ít lag, mượt mà | Hơi chậm hơn do phải "dịch" qua lớp trung gian |
| **Tính năng** | Hỗ trợ đầy đủ: HiDPI, Fractional Scaling, Touchpad gesture | Có thể bị mờ trên HiDPI, thiếu gesture, thiếu Clipboard |
| **Bảo mật** | App bị cô lập, không thể "nhìn trộm" app khác | App có thể đọc được input của tất cả app X11 khác |

### Hiện trạng hệ thống của bạn
```
google-chrome    | xwayland = False  → ✅ Wayland Native
antigravity-ide  | xwayland = False  → ✅ Wayland Native
```
→ Cả 2 app đang mở đều đã chạy Wayland Native. Rất tốt!

### Các app phổ biến và trạng thái Wayland

| App | Wayland Native? | Ghi chú |
|---|---|---|
| Google Chrome | ✅ Có (mặc định) | Nhờ file `chrome-flags.conf` có `--ozone-platform-hint=auto` |
| Firefox | ✅ Có (mặc định) | Biến `MOZ_ENABLE_WAYLAND=1` đã được hệ thống set |
| Kitty | ✅ Có | Terminal native Wayland |
| Thunar | ✅ Có | GTK4 app, tự động native |
| Sublime Text | ❌ Không | Chạy qua XWayland, hiện chưa hỗ trợ Wayland |
| VS Code / Antigravity | ✅ Có | Electron app, đã native thông qua Ozone |

### Lời khuyên
- **Không cần ép buộc** tất cả app phải Wayland Native. Nếu app nào đó chỉ hỗ trợ X11 (như Sublime Text), XWayland sẽ tự động xử lý. Bạn vẫn dùng bình thường.
- **Ưu tiên cài app GTK4 hoặc Qt6** khi có lựa chọn, vì chúng thường hỗ trợ Wayland Native tốt hơn.
- Kiểm tra app nào đang dùng XWayland:
  ```bash
  hyprctl clients -j | python3 -c "import json,sys; [print(f'{c[\"class\"]} | xwayland={c[\"xwayland\"]}') for c in json.load(sys.stdin)]"
  ```

---

## Q3: Quản lý giao diện (Theme, Icon) — Hướng dẫn cài Catppuccin Mocha

### Hiện trạng

| Thành phần | Trạng thái | Vấn đề |
|---|---|---|
| GTK Theme | ⚠️ Mặc định `Adwaita` | Chưa có công cụ quản lý (nwg-look) |
| Icon Theme | ⚠️ Mặc định `Adwaita` | Chưa cài bộ icon nào |
| Qt Theme | ❌ **LỖI** | Biến `QT_QPA_PLATFORMTHEME=qt5ct` trỏ đến package chưa cài! |
| Cursor Theme | Mặc định `default` | Đang dùng cursor mặc định |

> [!WARNING]
> **Lỗi nghiêm trọng:** Trong file `~/.config/uwsm/env`, dòng `QT_QPA_PLATFORMTHEME=qt5ct` đang trỏ đến package `qt5ct` **chưa được cài**. Điều này có thể khiến một số app Qt bị crash hoặc không hiển thị theme. Cần sửa thành `qt6ct` sau khi cài package.

### Các công cụ quản lý giao diện là gì?

| Công cụ | Chức năng | Dùng cho |
|---|---|---|
| **nwg-look** | Giao diện đồ họa để chọn GTK Theme, Icon, Font, Cursor cho tất cả app GTK (Chrome, Firefox, Thunar...) | GTK apps |
| **qt6ct** | Giao diện đồ họa để chọn Theme, Font, Icon cho tất cả app Qt6 | Qt6 apps |
| **kvantum** | Engine theme đặc biệt cho Qt, cho phép dùng các theme cực kỳ đẹp với hiệu ứng blur, gradient | Qt apps (nâng cao) |

### Phân tích xung đột với dotfiles hiện có

Bạn đang dùng bộ dotfiles từ tác giả **HighDelay** với bảng màu tùy chỉnh riêng:
- **Màu nền chính:** `#112436` (xanh đậm navy)
- **Màu chữ:** `#EAF2F9` (trắng xanh nhạt)
- **Màu nhấn:** `#71BBD4` (xanh cyan)
- **Terminal (Kitty):** Đã dùng bảng màu **Catppuccin Mocha** cho 16 terminal colors (F38BA8, A6E3A1, 89B4FA...)

→ **Kết luận:** Kitty đã dùng Catppuccin Mocha rồi! Nhưng Waybar, Swaync, Rofi, Hyprland, Hyprlock vẫn đang dùng bảng màu tùy chỉnh của HighDelay (navy blue). Việc đổi GTK/Qt theme sang Catppuccin Mocha **KHÔNG gây xung đột** với các file config này vì GTK Theme chỉ ảnh hưởng đến giao diện của các ứng dụng (Chrome, Thunar, Firefox...), không ảnh hưởng Waybar/Rofi/Swaync (chúng dùng CSS riêng).

### Hướng dẫn cài đặt từng bước

#### Bước 1: Cài công cụ quản lý
```bash
sudo pacman -S nwg-look qt6ct
```

#### Bước 2: Sửa biến môi trường
Mở file `~/.config/uwsm/env`:
```bash
nano ~/.config/uwsm/env
```
Tìm dòng:
```
QT_QPA_PLATFORMTHEME=qt5ct
```
Sửa thành:
```
QT_QPA_PLATFORMTHEME=qt6ct
```

#### Bước 3: Cài Catppuccin Mocha GTK Theme
```bash
yay -S catppuccin-gtk-theme-mocha
```
Sau khi cài xong, mở `nwg-look` từ Rofi:
1. Mục **Widget Theme** → chọn `catppuccin-mocha-blue-standard+default` (hoặc biến thể bạn thích)
2. Mục **Icon Theme** → giữ `Adwaita` hoặc cài thêm bộ icon đẹp hơn:
   ```bash
   sudo pacman -S papirus-icon-theme
   ```
   Sau đó chọn `Papirus-Dark` trong nwg-look.
3. Mục **Cursor Theme** → giữ nguyên hoặc cài thêm:
   ```bash
   yay -S catppuccin-cursors-mocha
   ```
4. Nhấn **Apply** để áp dụng.

#### Bước 4: Cấu hình Qt6
Mở `qt6ct` từ Rofi:
1. Tab **Appearance** → Style: chọn `Fusion`
2. Tab **Fonts** → Chọn font bạn thích (gợi ý: `Noto Sans`, size 10)
3. Nhấn **Apply** → **OK**

*(Tùy chọn nâng cao)* Nếu muốn Qt apps cũng có theme Catppuccin:
```bash
sudo pacman -S kvantum
yay -S kvantum-theme-catppuccin-git
```
Mở `kvantummanager` từ Rofi:
1. Bạn bỏ qua phần "Select a Kvantum theme folder" (đó là chỗ để cài theme thủ công).
2. Hãy bấm vào nút xổ xuống ở mục **Change/Delete Theme** (Thay đổi/Xóa Theme) ở ngay bên dưới.
3. Tìm và chọn `catppuccin-mocha-blue`.
4. Nhấn **Use this theme** (Sử dụng theme này).

Quay lại `qt6ct`:
1. Tab **Appearance** → Style: đổi thành `kvantum`
2. Nhấn **Apply**

#### Bước 5: Khởi động lại (Logout/Login) để mọi thay đổi có hiệu lực

---

## Q4: Tính năng thú vị cho người dùng Windows mới chuyển sang

### 1. Dán văn bản nhanh bằng chuột giữa (Primary Selection)
- **Cách dùng:** Bôi đen (quét chọn) bất kỳ đoạn text nào → Nhấn **chuột giữa** (hoặc nhấn đồng thời chuột trái + phải trên touchpad) ở vị trí muốn dán → Text được dán ngay lập tức!
- **Khác biệt:** Đây là clipboard thứ 2, độc lập với Ctrl+C/Ctrl+V. Bạn có thể dùng song song cả hai.
- **Cuộn trang bằng chuột giữa (Autoscroll):**
  - **Chrome/Brave:** Thêm dòng `--enable-blink-features=MiddleClickAutoscroll` vào file `~/.config/chrome-flags.conf`.
  - **Firefox:** Vào *Settings → General → Browsing* → Tích chọn *Use autoscrolling*.

### 2. Workspace (Vùng làm việc ảo)
- Hyprland có **10 workspace** (Super+1 đến Super+0). Mỗi workspace như một màn hình ảo riêng biệt.
- **Di chuyển 1 cửa sổ:** `Super + Shift + [số]` để ném cửa sổ đang chọn sang workspace khác.
- **Tính năng mở rộng (Đã cấu hình thêm bằng script):**
  - `Super + Alt + [số]`: Ném toàn bộ cửa sổ ở Workspace hiện tại sang Workspace đích.
  - `Super + Shift + Alt + [số]`: Hoán đổi vị trí toàn bộ cửa sổ giữa Workspace hiện tại và Workspace đích.
  - `Super + Shift + W`: Đóng ngay lập tức toàn bộ cửa sổ trên Workspace hiện tại.

### 3. Tiling Window Manager
- Khác với Windows (cửa sổ chồng chéo), Hyprland tự động **sắp xếp cửa sổ lấp đầy màn hình**.
- **Super+S:** Chuyển cửa sổ sang chế độ nổi (floating) như Windows truyền thống.
- **Super+F:** Toàn màn hình (fullscreen).
- **Super+O:** Xoay hướng chia cửa sổ (ngang ↔ dọc).

### 4. Terminal là trung tâm
- **Ctrl+Shift+C / Ctrl+Shift+V:** Copy/Paste trong terminal (KHÔNG phải Ctrl+C/V vì Ctrl+C là lệnh hủy tiến trình).
- **Tab:** Tự động hoàn thành lệnh, tên file.
- **Ctrl+R:** Tìm kiếm lịch sử lệnh.
- **!!:** Chạy lại lệnh trước đó. `sudo !!` = chạy lại lệnh trước với quyền root.

### 5. Quản lý gói Pacman/Yay
```bash
sudo pacman -Syu          # Cập nhật hệ thống
pacman -Ss <tên>           # Tìm gói
pacman -Q | grep <tên>     # Xem gói đã cài
sudo pacman -Rns <tên>     # Gỡ gói sạch sẽ
paccache -r                # Dọn cache cũ
```

### 6. Phím tắt hữu ích trên hệ thống hiện tại

| Phím tắt | Chức năng |
|---|---|
| `Super + Enter` | Mở terminal (Kitty) |
| `Super + Space` | Mở launcher (Rofi) |
| `Super + E` | Mở File Manager (Thunar) |
| `Super + W` | Đóng cửa sổ hiện tại |
| `Super + V` | Mở lịch sử Clipboard |
| `Super + Shift + F` | Tìm kiếm File (Rofi Finder) |
| `Super + Shift + G` | Tìm kiếm Nội dung File (Live Grep) |
| `Super + N` | Mở/đóng bảng thông báo |
| `Super + Tab` | Chuyển đổi cửa sổ |
| `Alt + F4` | Mở menu Power (Shutdown/Reboot/Logout) |
| `Print` | Chụp toàn màn hình |
| `Super + Shift + S` | Chụp vùng chọn |
| `Super + Shift + Cuộn chuột` | Zoom màn hình |
| `Ctrl + Space` | Chuyển đổi ngôn ngữ |

### 7. Alias (Bí danh lệnh)
Mở `~/.zshrc` và thêm:
```bash
alias update="sudo pacman -Syu"
alias cls="clear"
alias ll="ls -la"
```
Chạy `source ~/.zshrc` để kích hoạt.

---

## Q5: Kiểm tra tổng thể hệ thống — Các vấn đề cần khắc phục

| # | Vấn đề | Mức độ | Hiện trạng |
|---|---|---|---|
| 1 | ❌ Không có Swap | **Nghiêm trọng** | 32GB RAM, 0 Swap |
| 2 | ❌ fstrim.timer tắt | **Quan trọng** | SSD NVMe không được dọn rác |
| 3 | ❌ systemd-oomd tắt | **Quan trọng** | Không có bảo vệ tràn RAM |
| 4 | ⚠️ Thiếu Image Viewer | Nhỏ | Không thể mở ảnh trong Thunar |
| 5 | ⚠️ Thiếu Archive Manager | Nhỏ | Không thể giải nén từ Thunar |
| 6 | ⚠️ qt5ct chưa cài | Nhỏ | Biến môi trường trỏ sai (đã nêu ở Q3) |

---

### Vấn đề 1: Tạo Swap File (8GB)

> [!CAUTION]
> Hiện tại máy bạn có 32GB RAM nhưng **KHÔNG CÓ SWAP**. Khi RAM đầy, hệ thống sẽ **freeze cứng** thay vì xử lý nhẹ nhàng. Ngoài ra, bạn cũng không thể sử dụng tính năng Hibernate (ngủ đông).

**Bước 1: Tạo file Swap 8GB**
```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress

or dùng `sudo fallocate -l 8G /swapfile` nếu là ext4 cho nhanh (yes)

sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

**Bước 2: Đăng ký tự động khi khởi động**
```bash
sudo nano /etc/fstab
```
Thêm dòng này vào **cuối file**:
```
/swapfile none swap defaults 0 0
```

**Bước 3: Kiểm tra**
```bash
swapon --show
free -h
```

**Bước 4 (Tùy chọn): Giảm swappiness**
```bash
cat /proc/sys/vm/swappiness              # Xem giá trị hiện tại (mặc định 60)
sudo sysctl vm.swappiness=10             # Đặt tạm thời
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf  # Đặt vĩnh viễn
```

---

### Vấn đề 2: Bật fstrim.timer

> [!WARNING]
> SSD NVMe cần được TRIM định kỳ để duy trì tốc độ và tuổi thọ.

```bash
sudo systemctl enable --now fstrim.timer
systemctl status fstrim.timer
sudo fstrim -av    # Chạy TRIM ngay lập tức lần đầu
```

---

### Vấn đề 3: Bật systemd-oomd

```bash
sudo systemctl enable --now systemd-oomd
systemctl status systemd-oomd
```

---

### Vấn đề 4 & 5: Cài Image Viewer và Archive Manager

```bash
sudo pacman -S imv xarchiver unzip unrar p7zip
```
Sau đó mở Thunar → chuột phải vào ảnh → Open With Other Application → chọn `imv` → tick "Use as default".

---

## Q6: Control Center — Có nên dùng không?

### ✅ Không cần cài thêm

| Chức năng | Công cụ hiện có | Cách mở |
|---|---|---|
| Thông báo | swaync | Super+N |
| Âm thanh | pavucontrol + EasyEffects | Mở từ Rofi |
| Bluetooth | blueman-manager | Rofi hoặc icon Waybar |
| Wi-Fi | network-manager-applet / nmtui | Icon Waybar hoặc terminal |
| Màn hình | nwg-displays | Mở từ Rofi |
| Độ sáng | Phím tắt (Super+Ctrl+U/D) | Bàn phím |
| Clipboard | cliphist | Super+V |

Triết lý Hyprland là **"mỗi công cụ làm một việc"**. Cài Control Center tập trung sẽ thêm nặng mà không cần thiết.

---

## Q7: Bảo mật, Tường lửa, Quyền riêng tư

| Hạng mục | Trạng thái |
|---|---|
| Secure Boot | ✅ Có (sbctl) |
| GNOME Keyring | ✅ Hoạt động |
| Polkit | ✅ Có (hyprpolkitagent) |
| Tường lửa | ❌ **CHƯA CÓ** |
| DNS mã hóa | ⚠️ Chưa cấu hình |

### Cài Tường lửa (UFW)

> [!IMPORTANT]
> Máy bạn **không có tường lửa**. Khi ở mạng công cộng, các dịch vụ đang lắng nghe (RustDesk, wayvnc) có thể bị truy cập từ bên ngoài.

```bash
sudo pacman -S ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
# sudo ufw allow ssh            # Nếu cần SSH
# sudo ufw allow 21115:21119/tcp  # Nếu cần RustDesk từ xa
# sudo ufw allow 21116/udp
sudo ufw enable
sudo ufw status verbose
sudo systemctl enable ufw
```

### DNS mã hóa (Tùy chọn nâng cao)
```bash
sudo nano /etc/NetworkManager/conf.d/dns.conf
```
Thêm:
```ini
[main]
dns=systemd-resolved
```
```bash
sudo systemctl enable --now systemd-resolved
sudo nano /etc/systemd/resolved.conf
```
Sửa/thêm:
```ini
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google
FallbackDNS=9.9.9.9#dns.quad9.net
DNSOverTLS=yes
```
```bash
sudo systemctl restart systemd-resolved NetworkManager
resolvectl status    # Kiểm tra
```

### Lời khuyên bảo mật khác
1. Không đăng nhập bằng root. Luôn dùng user + `sudo`.
2. Cập nhật hệ thống thường xuyên (xem Q8).
3. Đọc PKGBUILD trước khi cài AUR (xem Q9).
4. **Về định vị:** Linux desktop mặc định **không có dịch vụ định vị** chạy ngầm (khác Windows/macOS).

---

## Q8: Lời khuyên sử dụng hàng ngày

### Lịch cập nhật

| Hành động | Tần suất | Lệnh |
|---|---|---|
| Cập nhật official repos | 1-2 tuần/lần | `sudo pacman -Syu` |
| Cập nhật AUR | Sau official | `yay -Sua` |
| Dọn cache gói cũ | 1 tháng/lần | `paccache -r` |
| TRIM SSD | Tự động hàng tuần | `fstrim.timer` |
systemctl list-timers


### Quy trình update an toàn

**Trước khi update:**
1. Vào [archlinux.org/news](https://archlinux.org/news/) đọc thông báo.
2. Đảm bảo pin đủ hoặc đang cắm sạc.

**Thực hiện:**
```bash
sudo pacman -Syu         # Update chính
pacman -Qdt              # Kiểm tra gói mồ côi
# sudo pacman -Rns $(pacman -Qdtq)  # Gỡ gói mồ côi (nếu có)
yay -Sua                 # Update AUR
```

**Sau khi update:**
- Update kernel hoặc Nvidia driver → **Khởi động lại máy**.
- Các update khác → Thường không cần restart.

### Mẹo bảo trì & Kiểm tra định kỳ
```bash
# ----- Dọn dẹp -----
du -sh /var/cache/pacman/pkg/   # Xem dung lượng cache pacman
# Nếu báo lỗi "command not found: paccache", hãy cài gói pacman-contrib: sudo pacman -S pacman-contrib
sudo paccache -rk1              # Dọn cache gói cài đặt (giữ 1 phiên bản gần nhất)
sudo pacman -Rns $(pacman -Qtdq) # Gỡ bỏ hoàn toàn các gói mồ côi (cài thừa)
rm -rf ~/.cache/*               # Dọn sạch cache ứng dụng của người dùng (giải phóng nhiều GB)

# ----- Kiểm tra hệ thống định kỳ -----
df -h                           # Xem dung lượng ổ đĩa
systemd-analyze blame | head    # Xem các tiến trình làm chậm quá trình khởi động máy
systemctl --failed              # Kiểm tra xem có dịch vụ nào bị crash ngầm không
systemctl list-timers           # Xem danh sách các tác vụ tự động (như fstrim) và lịch chạy tiếp theo
journalctl -p err -b            # Xem log lỗi của hệ thống trong phiên làm việc hiện tại
```

### Khởi động lại giao diện an toàn
Nếu bạn đang chỉnh sửa cấu hình (như Waybar, Hyprland) và muốn áp dụng thay đổi hoặc bật lại app lỡ tay tắt, hãy dùng các lệnh sau trong Terminal:
```bash
# ----- Waybar (Thanh trạng thái) -----
killall -SIGUSR2 waybar                       # Tải lại cấu hình Waybar (Mượt nhất, khuyên dùng)
hyprctl dispatch exec "uwsm app -- waybar"    # Bật lại Waybar an toàn nếu nhỡ tay tắt hẳn

# ----- Hyprland (Môi trường chung) -----
# Lưu ý: Hyprland tự động cập nhật khi bạn Save file, nên hiếm khi cần lệnh này.
hyprctl reload                                # Ép tải lại toàn bộ cấu hình lõi
```

### Tối ưu hóa hệ thống (Đã áp dụng)
- **Tăng tốc biên dịch (Cài AUR siêu tốc):** Sửa `/etc/makepkg.conf`, kích hoạt `MAKEFLAGS="-j$(nproc)"` để bắt hệ thống dùng toàn bộ luồng CPU thay vì chỉ 1 luồng khi biên dịch các gói từ AUR.
- **Khôi phục phím tìm kiếm lệnh cũ (Ctrl+R):** Khi bật chế độ Vi Mode trong Zsh (`bindkey -v`), `Ctrl+R` sẽ mất tác dụng. Đã thêm lệnh `bindkey '^R' history-incremental-search-backward` vào `~/.zshrc` để khôi phục tính năng này.
- **Thanh trạng thái Waybar:** Đã thêm cấu hình CSS để tàng hình hoàn toàn các Workspace trống (fix lỗi hiển thị của Waybar).

---

## Q9: Paru, PKGBUILD, và An toàn khi dùng AUR

### Giải thích các khái niệm

#### PKGBUILD là gì?
File script (Bash) mô tả **toàn bộ quy trình xây dựng** một gói phần mềm: tên gói, phiên bản, URL tải mã nguồn, lệnh biên dịch, lệnh cài đặt, danh sách phụ thuộc.

#### Post-install script là gì?
File script chạy **SAU khi gói cài xong**, với **quyền root**. Nó có thể tạo user, sửa file hệ thống, hoặc xóa dữ liệu. Đây là lý do cần kiểm tra cẩn thận.

#### Paru là gì?
AUR Helper hiện đại hơn Yay. Paru mặc định **hiển thị PKGBUILD** cho bạn đọc trước khi cài. Yay mặc định bỏ qua bước này.

### Nguyên tắc an toàn khi cài AUR

1. **Đọc PKGBUILD trước:**
   ```bash
   yay -S <tên_gói> --editmenu
   ```

2. **Kiểm tra dấu hiệu đáng ngờ:**
   - URL tải từ nguồn lạ?
   - Có `curl | bash` hoặc lệnh xóa file bất thường?

3. **Đọc bình luận AUR:**
   Truy cập `https://aur.archlinux.org/packages/<tên_gói>` → đọc Comments.

4. **Kiểm tra post-install:**
   ```bash
   pacman -Qi <tên_gói> | grep "Install Script"
   ```

5. **Ưu tiên gói chính thức** (`pacman -S`) hơn AUR (`yay -S`).

### Chuyển sang Paru? Không bắt buộc.
```bash
yay -S paru   # Nếu muốn thử
paru -S <tên_gói>
```

---

## Q10: Quản lý phần cứng Lenovo IdeaPad Gaming 3 15IAH7

### Hiện trạng

| Tính năng | Tương đương Lenovo Vantage | Trạng thái | Giá trị |
|---|---|---|---|
| Conservation Mode | Bảo trì pin (sạc đến ~60% rồi dừng) | ✅ **ĐÃ BẬT** | `1` |
| Platform Profile | Chế độ hiệu năng | ✅ Có | `balanced` |
| Fan Mode | Tốc độ quạt | ✅ Có | Điều chỉnh được |
| Fn Lock | Khóa phím Fn | ✅ Có | Điều chỉnh được |
| Đèn LED bàn phím | — | ❌ Không có | IdeaPad Gaming 3 không có LED phần mềm |

### Conservation Mode (Bảo trì pin)
```bash
# Xem trạng thái (1 = bật, 0 = tắt)
cat /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Tắt (sạc đầy 100%)
echo 0 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode

# Bật lại (sạc đến ~60% rồi dừng)
echo 1 | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
```

### Platform Profile (Tốc độ quạt & Hiệu năng - Tương đương Fn + Q)
Trên các dòng IdeaPad đời mới, Tốc độ quạt (Fan Mode) được gộp chung vào **Platform Profile**. Bạn không chỉnh quạt riêng lẻ mà chỉnh qua Profile.
Có 3 chế độ chính:
- `low-power`: Tiết kiệm pin, quạt quay rất êm (Quiet Mode).
- `balanced`: Cân bằng (mặc định).
- `performance`: Hiệu năng tối đa, quạt quay mạnh nhất để tản nhiệt.

```bash
# Xem chế độ hiện tại
cat /sys/firmware/acpi/platform_profile

# Xem các chế độ máy hỗ trợ
cat /sys/firmware/acpi/platform_profile_choices

# Chuyển chế độ (Cần nhập mật khẩu)
echo "low-power" | sudo tee /sys/firmware/acpi/platform_profile   # Quạt êm / Tiết kiệm pin
echo "balanced" | sudo tee /sys/firmware/acpi/platform_profile    # Bình thường
echo "performance" | sudo tee /sys/firmware/acpi/platform_profile # Quạt mạnh / Chơi game
```

### Tạo phím tắt (Tùy chọn)
Thêm vào `~/.config/hypr/hyprland.conf`:
```bash
bind = $mainMod, F1, exec, echo low-power | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Low Power"
bind = $mainMod, F2, exec, echo balanced | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Balanced"
bind = $mainMod, F3, exec, echo performance | sudo tee /sys/firmware/acpi/platform_profile && notify-send "Power" "Performance"
```

> [!NOTE]
> Để phím tắt `sudo tee` hoạt động mà không hỏi mật khẩu:
> ```bash
> sudo nano /etc/sudoers.d/power-profile
> ```
> Thêm:
> ```
> neitnd ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/firmware/acpi/platform_profile
> neitnd ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
> ```

### Xem thông tin pin
```bash
cat /sys/class/power_supply/BAT1/capacity           # % pin
cat /sys/class/power_supply/BAT1/status              # Trạng thái
cat /sys/class/power_supply/BAT1/energy_full         # Dung lượng thực tế
cat /sys/class/power_supply/BAT1/energy_full_design  # Dung lượng thiết kế
# Nếu energy_full < 80% energy_full_design → pin đã chai đáng kể
```

---

## Q11: Rofi File Finder (Tìm kiếm file siêu tốc)

### Tổng quan
Hệ thống của bạn đã được cấu hình một script Rofi tùy chỉnh tại `~/.config/hypr/scripts/rofi-finder.sh` để tìm kiếm file nhanh. Bấm **Super + Shift + F** để gọi chức năng này.

### Cơ chế hoạt động thông minh
1. **Ưu tiên File vừa mở:**
   - Script tự động đọc file `~/.local/share/recently-used.xbel` của Linux (nơi hệ điều hành lưu lại mọi file bạn đã tương tác từ bất kỳ phần mềm nào).
   - 25 file/thư mục vừa mở gần nhất sẽ luôn được ghim lên **đầu danh sách**. Khi bạn gõ từ khóa, Rofi sẽ vẫn ưu tiên kết quả nằm trong nhóm file vừa mở lên trước. Trải nghiệm y hệt Mac Spotlight.
2. **Tìm kiếm file siêu tốc với `fd`:**
   - Không đọc database định kỳ như Windows Search, script dùng lệnh `fd` quét trực tiếp toàn bộ thư mục `$HOME` theo thời gian thực (loại bỏ thư mục rác hệ thống như `.git, .vscode, node_modules...`).
   - Tối ưu hóa: Thay vì phải fork hàng nghìn tiến trình con để phân biệt file/folder, script chia hai luồng `--type d` và `--type f` chạy song song siêu nhẹ, xử lý 10.000 file trong tích tắc.

### Các Phím tắt trong bảng tìm kiếm

Khi chọn một mục trên Rofi, bạn có thể thực hiện 4 thao tác sau:

| Phím bấm | Hành động | Giải thích |
|---|---|---|
| `Enter` | **Mở mặc định** | Dùng cơ chế `gio open` (giống Thunar). File `.conf` mở bằng Sublime, ảnh mở bằng Image Viewer, thư mục mở Thunar. |
| `Alt + D` | **Mở thư mục chứa** | Bật Thunar trỏ thẳng đến nơi đang cất giữ file đó. |
| `Alt + T` | **Mở Terminal tại đây** | Bật Kitty thẳng vào thư mục chứa file. |
| `Alt + E` | **Mở bằng Editor** | Bật Neovim để chỉnh sửa nhanh file/thư mục đó. |

---

## Q12: Live Grep (Tìm kiếm nội dung siêu tốc)

### Tổng quan
Tìm kiếm theo tên file là chưa đủ khi bạn làm việc với hàng ngàn file code hoặc tài liệu dài. Tính năng **Live Grep** giúp bạn lục tung từng dòng chữ bên trong tất cả các file của bạn theo thời gian thực (real-time). 
Bấm **Super + Shift + G** để kích hoạt.

### Cơ chế hoạt động
Hệ thống sử dụng bộ 3 công cụ kinh điển nhất của dân chơi Linux:
1. **Kitty Floating Window:** Một cửa sổ terminal cực xịn xò (bao phủ 90% màn hình) được Hyprland bật lên giữa màn hình chỉ dành riêng cho tác vụ này.
2. **ripgrep (rg):** Công cụ tìm kiếm nội dung nhanh nhất thế giới (viết bằng Rust). Nó thông minh đến mức tự động bỏ qua các file ảnh, video, file nén, hay các thư mục `.git`, `node_modules` để tập trung 100% công lực quét text.
3. **fzf + bat:** Trình tìm kiếm mờ (Fuzzy Finder). Thay vì bắt `ripgrep` chạy 1 lần, `fzf` ra lệnh cho `ripgrep` chạy lại liên tục sau **mỗi một ký tự** bạn gõ vào. Đồng thời, `bat` hỗ trợ preview ngay bên cạnh màn hình với đầy đủ màu sắc (syntax highlight).

### Hướng dẫn sử dụng
1. Bấm `Super + Shift + G`.
2. Gõ từ khóa bạn muốn tìm (vd: `export function` hoặc `hyprland`).
3. Khung bên trái sẽ hiển thị danh sách các file + số dòng chứa từ khóa.
4. Khung bên phải hiển thị nội dung file đó (có tô màu) để bạn xem trước.
5. Dùng `Up/Down` để cuộn qua các kết quả.
6. Bấm `Enter` để mở file đó bằng ứng dụng mặc định (Sublime Text/Neovim). Mọi thứ diễn ra trong chưa tới 1 giây!

---

## Q13: Tinh chỉnh Giao diện & Terminal (Mới cập nhật)

### 1. Kitty Terminal
- **Giao diện Catppuccin Mocha:** Toàn bộ bảng màu của Kitty (từ màu chữ, màu nền đến 16 màu ANSI) đã được đồng bộ chuẩn Catppuccin Mocha, trùng khớp hoàn toàn với màu hệ thống.
- **Hiệu ứng Kính (Glassmorphism):** Độ mờ (`opacity`) được tăng lên `0.88`, kết hợp với hiệu ứng làm mờ nền (`background_blur 10`), tạo cảm giác sang trọng.
- **Độ phản hồi siêu tốc:** Thêm cấu hình `repaint_delay 10` và `input_delay 3` giúp thao tác gõ chữ gần như không có độ trễ.
- **Tiêu đề Tab gọn gàng:** Lược bỏ phần tên máy cũ dài dòng, chỉ giữ lại thư mục/tiến trình đang chạy.

### 2. ZSH & Môi trường dòng lệnh
- **Quản lý lịch sử thông minh (history-substring-search):** 
  - Gõ một phần lệnh bất kỳ (ví dụ: `pacman`) rồi bấm mũi tên **Lên/Xuống**. Zsh sẽ lọc ra tất cả các lệnh cũ có chứa từ "pacman".
- **Phím tắt điều hướng Text (Word-by-word):**
  - Bấm `Ctrl + Mũi tên Trái/Phải` để nhảy con trỏ qua từng chữ một, tiện lợi y hệt VSCode/Sublime Text.
- **Bí danh (Alias) hiện đại:**
  - `ls`, `ll`, `la` tự động dùng lệnh `eza` để hiển thị kèm icon màu sắc và phân nhóm thư mục cực kỳ dễ nhìn.
  - `cat` tự động gọi lệnh `bat`, hỗ trợ tô màu code (syntax highlighting) ngay trong terminal.

### 3. SwayNC (Trung tâm thông báo)
- Đã được làm lại CSS 100% sang chuẩn Catppuccin Mocha:
  - Nền tối `#1e1e2e`, chữ `#cdd6f4`, viền xanh `#89b4fa`.
  - Thông báo quan trọng (Critical) có viền và nền hồng nhạt cảnh báo.
  - Các nút bấm, thanh trượt Do Not Disturb được bo tròn, đẹp mắt.

### 4. Power Menu (Alt + F4)
- **Giao diện dạng danh sách:** Trả về layout dọc 5 dòng quen thuộc, giúp chữ không bao giờ bị cắt ngắn (`...`). Font Nerd lớn và sắc nét.
- **Thao tác nhanh bằng bàn phím (Hotkeys):**
  - Mở menu (`Alt + F4`), sau đó **KHÔNG CẦN CHỌN VÀ BẤM ENTER**, bạn chỉ cần gõ ngay 1 phím:
    - **`s`** = Shutdown (Tắt máy)
    - **`r`** = Reboot (Khởi động lại)
    - **`l`** = Lock (Khóa màn hình)
    - **`u`** = Suspend (Sleep/Ngủ)
    - **`e`** = Logout (Đăng xuất)
  - Ở màn hình xác nhận, bấm **`y`** (Yes) hoặc **`n`** (No) để chốt hành động cực kỳ mượt mà.

### 5. Màn hình khóa (Hyprlock)
- Đã được đồng bộ thiết kế sang Catppuccin Mocha.
- Khu vực nhập mật khẩu (`input-field`) giờ đây có nền xám đen `Base`, chữ màu `Text`, và viền màu xanh `Blue`.
- Báo hiệu trực quan:
  - Khi đang nhập: Viền xanh.
  - Khi kiểm tra thành công: Viền nháy Xanh lá (`Green`).
  - Khi nhập sai: Viền nháy Đỏ hồng (`Red`).

### 6. Màn hình đăng nhập (SDDM)
- Hệ thống đã được cài đặt bộ Theme `catppuccin-sddm-theme-mocha` (tải từ AUR).
- Giao diện được cấu hình sử dụng biến thể **Mocha Blue** (tại file `/etc/sddm.conf.d/catppuccin.conf`).
- Khi Logout hoặc khởi động lại máy, bạn sẽ thấy màn hình đăng nhập hoàn toàn ăn khớp với giao diện tổng thể của Hyprland.
