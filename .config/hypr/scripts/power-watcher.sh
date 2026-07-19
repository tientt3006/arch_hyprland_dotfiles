#!/bin/bash
# ~/.config/hypr/scripts/power-watcher.sh
# Theo dõi sự kiện cắm/rút sạc và restart hypridle để reset bộ đếm thời gian
# Khi nguồn điện thay đổi (AC <-> Battery), hypridle cần khởi động lại
# để các mốc idle (dim, dpms, lock, suspend) được đếm lại từ đầu.

PREV_STATE=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1)

while read -r line; do
    # Mỗi khi upower phát sự kiện, kiểm tra trạng thái nguồn có thay đổi không
    CURR_STATE=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1)
    if [ "$CURR_STATE" != "$PREV_STATE" ]; then
        PREV_STATE=$CURR_STATE
        # Debounce: chờ 1 giây để trạng thái ổn định
        sleep 1
        systemctl --user restart hypridle
    fi
done < <(upower --monitor)
