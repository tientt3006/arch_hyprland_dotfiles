#!/bin/bash
# Script to close all windows on the current or target workspace

TARGET_WS=$1

# Nếu không truyền tham số, sẽ đóng workspace hiện tại
if [ -z "$TARGET_WS" ]; then
    TARGET_WS=$(hyprctl activeworkspace -j | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))")
fi

if [ -z "$TARGET_WS" ]; then
    exit 0
fi

# Lấy địa chỉ tất cả cửa sổ của workspace đó
ADDRESSES=$(hyprctl clients -j | python3 -c "import sys, json; [print(c['address']) for c in json.load(sys.stdin) if c.get('workspace',{}).get('id') == int($TARGET_WS)]")

# Đóng từng cửa sổ
for addr in $ADDRESSES; do
    hyprctl dispatch closewindow "address:$addr"
done
