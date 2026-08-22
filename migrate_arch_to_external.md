# Hướng dẫn chi tiết: Chuyển Arch Linux sang Ổ cứng rời (Portable Arch)

Tài liệu này hướng dẫn cách chuyển nguyên hệ điều hành Arch Linux hiện tại (từ Disk 0) sang ổ cứng rời (Disk 2) mà không làm mất dữ liệu, đồng thời cấu hình để ổ cứng này có thể boot được trên **bất kỳ máy tính nào khác**. Chúng ta sẽ loại bỏ rEFInd và thay bằng `systemd-boot` (gọn nhẹ, tích hợp sẵn của hệ thống, vô cùng phù hợp cho ổ rời).

## Mục tiêu:
- Chuyển Arch sang Disk 2.
- Chỉ sử dụng 100GB đầu tiên của Disk 2 (chia làm phân vùng EFI và Root).
- Thay rEFInd bằng `systemd-boot`.
- Tối ưu Initramfs để có thể khởi động trên mọi phần cứng khác nhau (chuẩn Portable).
- Không gây ảnh hưởng tới Windows hiện tại.

---

## Phần 1: Phân vùng và Format ổ cứng rời (Disk 2)

**Lưu ý:** Bạn có thể thực hiện toàn bộ các bước này ngay trong môi trường Arch Linux hiện tại đang chạy.

1. Cắm ổ cứng rời (Disk 2) vào máy.
2. Mở terminal và kiểm tra tên ổ đĩa:
   ```bash
   lsblk
   ```
   *Giả sử ổ cứng rời (Disk 2) của bạn là `/dev/sdX` (Hãy thay `sdX` bằng tên thực tế trong máy bạn, ví dụ `sda`, `sdb`, `nvme1n1`... Hãy kiểm tra kỹ dung lượng để tránh nhầm ổ).*

3. Sử dụng `cgdisk` để phân vùng (chỉ lấy 100GB đầu tiên):
   ```bash
   sudo cgdisk /dev/sdX
   ```
   - Chọn **New** -> Nhấn Enter (First sector mặc định) -> Gõ `1G` -> Code `EF00` -> Name `EFI`.
   - Chọn vùng free space còn lại phía dưới -> **New** -> Nhấn Enter -> Gõ `99G` -> Code `8300` -> Name `ArchRoot`.
   - Mặc kệ phần dung lượng chưa dùng tới ở cuối -> Chọn **Write** -> Gõ `yes` -> Chọn **Quit**.

4. Format các phân vùng vừa tạo:
   *Giả sử phân vùng EFI là `/dev/sdX1` và Root là `/dev/sdX2`.*
   ```bash
   sudo mkfs.fat -F32 /dev/sdX1
   sudo mkfs.ext4 /dev/sdX2
   ```

---

## Phần 2: Copy toàn bộ hệ thống sang ổ cứng rời

1. Mount phân vùng Root mới và tạo thư mục boot:
   ```bash
   sudo mount /dev/sdX2 /mnt
   sudo mkdir -p /mnt/boot
   sudo mount /dev/sdX1 /mnt/boot
   ```

2. Sử dụng công cụ `rsync` để copy toàn bộ hệ điều hành (loại bỏ các thư mục hệ thống tạm thời và swapfile):
   ```bash
   sudo rsync -aAXv --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found","/swapfile"} / /mnt
   ```
   *Quá trình này sẽ mất một lúc tùy thuộc vào tốc độ đọc/ghi của ổ cứng và dung lượng dữ liệu hiện tại của bạn.*

---

## Phần 3: Cấu hình hệ thống mới (Chroot)

1. Tạo file `fstab` mới cho ổ cứng rời (sử dụng UUID để máy tự nhận diện chính xác kể cả khi đổi cổng cắm):
   ```bash
   sudo genfstab -U /mnt > /mnt/etc/fstab
   ```
   *Kiểm tra lại file fstab bằng lệnh:* `cat /mnt/etc/fstab`. Xóa bỏ các dòng mount phân vùng của Windows (ổ C, ổ D, ổ F) nếu nó bị copy sang, **chỉ giữ lại `/` và `/boot` của ổ cứng rời**.

2. Chroot vào hệ thống mới trên ổ cứng rời:
   ```bash
   sudo arch-chroot /mnt
   ```

---

## Phần 4: Tối ưu cho Portable (Boot trên mọi máy tính)

Vì mục tiêu là mang ổ cứng này cắm vào máy tính khác vẫn boot được, ta cần chỉnh sửa lại Initramfs để nó chứa đủ driver (module) cho mọi loại phần cứng thay vì lược bỏ chỉ để vừa với máy Lenovo hiện tại. Đồng thời ta cần xóa các cấu hình bị "cứng" (hardcoded).

1. **Cài đặt Microcode và Driver mã nguồn mở cơ bản:**
   Để đảm bảo máy nhận diện tốt CPU và Card màn hình của bất kỳ hãng nào, hãy cài các gói sau:
   ```bash
   sudo pacman -S intel-ucode amd-ucode xf86-video-amdgpu xf86-video-ati xf86-video-nouveau
   ```

2. **Sửa file `mkinitcpio.conf` để nạp toàn bộ Driver:**
   ```bash
   nano /etc/mkinitcpio.conf
   ```
   Tìm dòng `HOOKS=(...)`. Mặc định nó chứa hook `autodetect`. Hook này sẽ tự động loại bỏ các module không có trên máy hiện tại. **Hãy xóa chữ `autodetect` khỏi dòng HOOKS.**
   - Dòng cũ có thể là: `HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)`
   - Dòng mới sẽ là: `HOOKS=(base udev modconf kms keyboard keymap consolefont block filesystems fsck)`
   
   Lưu file và thoát. Sau đó build lại initramfs:
   ```bash
   mkinitcpio -P
   ```

3. **Xóa cấu hình Xorg ép dùng card Intel (Quan trọng):**
   Trong `arch_experience.md`, bạn có hardcode BusID của card Intel cho SDDM (`PCI:0:2:0`). Nếu sang máy khác không có đúng địa chỉ này, SDDM sẽ lỗi đen màn hình.
   ```bash
   rm -f /etc/X11/xorg.conf.d/10-intel-sddm.conf
   ```

4. **Chỉnh sửa các biến môi trường ép dùng NVIDIA (Tùy chọn nhưng khuyến nghị):**
   Nếu bạn cắm ổ vào máy dùng card AMD/Intel, các biến ép dùng NVIDIA sẽ gây lỗi giao diện.
   ```bash
   nano /home/neitnd/.config/uwsm/env
   ```
   *Hãy comment (thêm dấu `#` vào đầu) các dòng liên quan đến NVIDIA:*
   ```bash
   # LIBVA_DRIVER_NAME=nvidia
   # __GLX_VENDOR_LIBRARY_NAME=nvidia
   # NVD_BACKEND=direct
   ```

---

## Phần 5: Cài đặt Bootloader (systemd-boot)

1. Cài đặt `systemd-boot` vào phân vùng EFI của ổ rời:
   ```bash
   bootctl --path=/boot install
   ```

2. Tạo file cấu hình Loader chính:
   ```bash
   nano /boot/loader/loader.conf
   ```
   Thêm nội dung sau:
   ```ini
   default arch.conf
   timeout 3
   console-mode max
   editor no
   ```

3. Lấy UUID của phân vùng Root (ổ rời `/dev/sdX2`):
   ```bash
   blkid /dev/sdX2
   ```
   *Copy đoạn mã UUID (chuỗi ký tự dài, không lấy dấu ngoặc kép).*

4. Tạo file cấu hình Boot Entry tiêu chuẩn:
   ```bash
   nano /boot/loader/entries/arch.conf
   ```
   Thêm nội dung sau (Thay `<UUID_CUA_ROOT>` bằng UUID vừa copy):
   ```ini
   title   Arch Linux (Portable Standard)
   linux   /vmlinuz-linux
   initrd  /amd-ucode.img
   initrd  /intel-ucode.img
   initrd  /initramfs-linux.img
   options root=UUID=<UUID_CUA_ROOT> rw quiet
   ```

5. (Tùy chọn) Tạo thêm một mục Boot riêng chỉ dành cho máy có card NVIDIA:
   Nếu cắm vào máy có NVIDIA (như chiếc Lenovo của bạn), bạn có thể chọn dòng này khi boot để kích hoạt DRM Modeset.
   ```bash
   nano /boot/loader/entries/arch-nvidia.conf
   ```
   ```ini
   title   Arch Linux (NVIDIA Mode)
   linux   /vmlinuz-linux
   initrd  /amd-ucode.img
   initrd  /intel-ucode.img
   initrd  /initramfs-linux.img
   options root=UUID=<UUID_CUA_ROOT> rw quiet nvidia_drm.modeset=1 nvidia_drm.fbdev=1
   ```

6. Thoát khỏi chroot và unmount ổ đĩa:
   ```bash
   exit
   sudo umount -R /mnt
   ```

---

## Phần 6: Khởi động thử và Dọn dẹp máy cũ

1. Khởi động lại máy. Nhấn phím `F12` (hoặc phím chọn Boot Menu của máy bạn) và chọn ổ cứng rời (Disk 2) hoặc mục có tên `Linux Boot Manager`.
2. Kiểm tra xem Arch Linux có khởi động thành công và nhận đủ mạng, giao diện hay không.
3. Nếu mọi thứ hoạt động hoàn hảo, bạn đã hoàn tất việc chuyển đổi sang ổ cứng rời!

### Dọn dẹp Disk 0 (Xóa Arch cũ và rEFInd)

Lúc này, toàn bộ Arch và Bootloader đều nằm trên ổ cứng rời của bạn, hoàn toàn độc lập với máy tính. Bạn có thể tiến hành dọn dẹp Disk 0 để trả lại dung lượng cho Windows:

1. Mở hệ điều hành Windows trên máy chính.
2. Mở công cụ **Disk Management**.
3. Tại **Disk 0**, bạn sẽ thấy:
   - Phân vùng EFI 700MB (Của Arch cũ, chứa rEFInd).
   - Phân vùng 240.16GB (Root của Arch cũ).
4. Chuột phải vào từng phân vùng này và chọn **Delete Volume**.
5. Phần dung lượng 240.16GB + 700MB sẽ chuyển thành *Unallocated*. Bạn có thể Extend (gộp) nó vào ổ D hoặc tạo một ổ mới trên Windows.

*(Với việc xóa phân vùng 700MB EFI này, rEFInd cũng sẽ bị xóa vĩnh viễn khỏi Disk 0. Trả lại máy tính chuẩn Windows EFI gốc trên Disk 1 cho bạn).* 
