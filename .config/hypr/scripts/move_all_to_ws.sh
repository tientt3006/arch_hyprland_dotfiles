#!/bin/bash
# Script to move all windows on the current workspace to a target workspace

TARGET_WS=$1
if [ -z "$TARGET_WS" ]; then
    exit 1
fi

# Lấy ID của workspace hiện tại bằng python3 (thay vì jq để khỏi phải cài thêm gói)
CURRENT_WS=$(hyprctl activeworkspace -j | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))")

if [ -z "$CURRENT_WS" ] || [ "$TARGET_WS" == "$CURRENT_WS" ]; then
    exit 0
fi

# Lấy địa chỉ của tất cả cửa sổ đang nằm ở workspace hiện tại
ADDRESSES=$(hyprctl clients -j | python3 -c "import sys, json; [print(c['address']) for c in json.load(sys.stdin) if c.get('workspace',{}).get('id') == $CURRENT_WS]")

# Chuyển từng cửa sổ sang workspace đích (dùng silent để tránh giật lag màn hình)
for addr in $ADDRESSES; do
    hyprctl dispatch movetoworkspacesilent "$TARGET_WS,address:$addr"
done

# Sau khi chuyển hết, tự động nhảy sang workspace đích đó
hyprctl dispatch workspace "$TARGET_WS"
