#!/bin/bash
# Lấy danh sách ảnh trong thư mục và chọn ngẫu nhiên 1 tấm
WALLPAPER_DIR="$HOME/GDrive_bisync/picture/Saved pics/arch_wallpapers"
RANDOM_IMG=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.gif" \) | shuf -n 1)

if [[ -n "$RANDOM_IMG" ]]; then
    # Thay đổi hình nền với hiệu ứng chuyển cảnh ngẫu nhiên
    uwsm app -- awww img "$RANDOM_IMG" --transition-type random --transition-step 90 --transition-fps 60
fi
