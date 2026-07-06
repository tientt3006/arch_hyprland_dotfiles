#!/bin/bash
# Lấy kích thước monitor để tính 90% 80% thay cho cú pháp exact % cũ (không dùng được trong Lua mode)
MON_W=$(hyprctl monitors -j | jq '.[] | select(.focused) | .width / .scale' | awk '{print int($1)}')
MON_H=$(hyprctl monitors -j | jq '.[] | select(.focused) | .height / .scale' | awk '{print int($1)}')
RW=$(awk "BEGIN {print int($MON_W * 0.9)}")
RH=$(awk "BEGIN {print int($MON_H * 0.8)}")
sleep 0.15 && hyprctl dispatch "hl.dsp.window.resize({x=$RW, y=$RH})" &> /dev/null &

WALLPAPER_DIR="$HOME/GDrive_bisync/picture/Saved pics/arch_wallpapers"

cd "$WALLPAPER_DIR" || exit 1

# Dọn dẹp terminal trước khi mở
clear

# Mở FZF với preview ảnh qua kitten icat
SELECTED=$(fd -t f -e jpg -e png -e jpeg -e gif . | fzf \
    --prompt="🖼️ Chon Hinh Nen: " \
    --preview="kitten icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {}" \
    --preview-window=right:50% \
    --border="rounded" \
    --margin=2%,2%)

# Xoá màn hình sau khi tắt FZF
clear

if [[ -n "$SELECTED" ]]; then
    IMG_PATH="$WALLPAPER_DIR/$SELECTED"
    # Thay đổi hình nền, hiệu ứng phóng to từ giữa màn hình
    uwsm app -- awww img "$IMG_PATH" --transition-type random --transition-step 90 --transition-fps 60
    # wallust run -q "$IMG_PATH"
    # hyprctl reload
    # killall -SIGUSR2 waybar
    # swaync-client -rs
    # killall -SIGUSR1 kitty
fi
