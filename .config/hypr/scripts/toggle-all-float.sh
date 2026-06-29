#!/bin/bash
# Lấy ID của màn hình ảo (workspace) hiện tại
WORKSPACE=$(hyprctl activeworkspace -j | jq -r '.name')

# ---- LƯU TRẠNG THÁI FLOAT CHO WORKSPACE NÀY ----
STATE_FILE="/tmp/hypr_float_mode_$WORKSPACE"
if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    notify-send "Hyprland" "Workspace $WORKSPACE: Tiling Mode"
else
    touch "$STATE_FILE"
    notify-send "Hyprland" "Workspace $WORKSPACE: Float Mode"
fi
# ------------------------------------------------

# ---- CẤU HÌNH VÙNG AN TOÀN (SAFE ZONE) ----
SAFE_MARGIN_TOP=110
SAFE_MARGIN_BOTTOM=60
SAFE_MARGIN_LEFT=10
SAFE_MARGIN_RIGHT=10
CASCADE_STEP=30
# ------------------------------------------

# Lấy thông số màn hình
MONITOR_INFO=$(hyprctl monitors -j | jq '.[] | select(.focused == true)')
M_WIDTH=$(echo "$MONITOR_INFO" | jq '.width')
M_HEIGHT=$(echo "$MONITOR_INFO" | jq '.height')
M_SCALE=$(echo "$MONITOR_INFO" | jq '.scale')
M_X=$(echo "$MONITOR_INFO" | jq '.x')
M_Y=$(echo "$MONITOR_INFO" | jq '.y')

# Tính độ phân giải thực tế sau khi scale
L_WIDTH=$(awk "BEGIN {print int($M_WIDTH / $M_SCALE)}")
L_HEIGHT=$(awk "BEGIN {print int($M_HEIGHT / $M_SCALE)}")

# Tính toán toạ độ tuyệt đối (Global Coordinates cho đa màn hình)
START_X=$(( M_X + SAFE_MARGIN_LEFT ))
START_Y=$(( M_Y + SAFE_MARGIN_TOP ))
SAFE_W=$(( L_WIDTH - SAFE_MARGIN_LEFT - SAFE_MARGIN_RIGHT ))
SAFE_H=$(( L_HEIGHT - SAFE_MARGIN_TOP - SAFE_MARGIN_BOTTOM ))

# Kích thước cửa sổ = 80% Vùng an toàn
TARGET_W=$(awk "BEGIN {print int($SAFE_W * 0.8)}")
TARGET_H=$(awk "BEGIN {print int($SAFE_H * 0.8)}")

# Phân loại cửa sổ trên workspace hiện tại
TILED_WINDOWS=$(hyprctl clients -j | jq -r ".[] | select(.workspace.name == \"$WORKSPACE\" and .floating == false) | .address")
ALL_WINDOWS=$(hyprctl clients -j | jq -r ".[] | select(.workspace.name == \"$WORKSPACE\") | .address")

# BƯỚC 1: Toggle toàn bộ cửa sổ (Đổi Tiling -> Float, và Float -> Tiling)
for address in $ALL_WINDOWS; do
    hyprctl dispatch togglefloating address:$address
done

# Đợi 0.1s để Hyprland cập nhật layout (Sửa triệt để lỗi văng về workspace 1)
sleep 0.1

# BƯỚC 2: Chỉ áp dụng Resize & Move cho những cửa sổ VỪA MỚI biến thành Float (trước đó là Tiling)
index=0
for address in $TILED_WINDOWS; do
    POS_X=$(( START_X + (index * CASCADE_STEP) ))
    POS_Y=$(( START_Y + (index * CASCADE_STEP) ))
    
    # Dùng --batch để gộp lệnh chạy siêu tốc
    hyprctl --batch "dispatch resizewindowpixel exact $TARGET_W $TARGET_H,address:$address ; dispatch movewindowpixel exact $POS_X $POS_Y,address:$address"
    
    index=$((index + 1))
done
