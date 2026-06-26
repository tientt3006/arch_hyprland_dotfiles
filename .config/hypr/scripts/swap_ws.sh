#!/bin/bash
# Script to swap all windows between current workspace and target workspace

TARGET_WS=$1
if [ -z "$TARGET_WS" ]; then
    exit 1
fi

CURRENT_WS=$(hyprctl activeworkspace -j | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))")

if [ -z "$CURRENT_WS" ] || [ "$TARGET_WS" == "$CURRENT_WS" ]; then
    exit 0
fi

# Lấy địa chỉ cửa sổ của 2 workspace
CURRENT_ADDRESSES=$(hyprctl clients -j | python3 -c "import sys, json; [print(c['address']) for c in json.load(sys.stdin) if c.get('workspace',{}).get('id') == $CURRENT_WS]")
TARGET_ADDRESSES=$(hyprctl clients -j | python3 -c "import sys, json; [print(c['address']) for c in json.load(sys.stdin) if c.get('workspace',{}).get('id') == int($TARGET_WS)]")

# 1. Chuyển tạm thời các cửa sổ của Target WS sang workspace 99 (workspace tạm)
for addr in $TARGET_ADDRESSES; do
    hyprctl dispatch movetoworkspacesilent "99,address:$addr"
done

# 2. Chuyển các cửa sổ của Current WS sang Target WS
for addr in $CURRENT_ADDRESSES; do
    hyprctl dispatch movetoworkspacesilent "$TARGET_WS,address:$addr"
done

# 3. Chuyển các cửa sổ từ workspace 99 (tạm) về Current WS
for addr in $TARGET_ADDRESSES; do
    hyprctl dispatch movetoworkspacesilent "$CURRENT_WS,address:$addr"
done

# Focus vào workspace vừa hoán đổi
hyprctl dispatch workspace "$TARGET_WS"
