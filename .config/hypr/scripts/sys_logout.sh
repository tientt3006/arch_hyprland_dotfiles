#!/bin/bash

# Các service quan trọng cần tắt an toàn để tránh lỗi database
CRITICAL_SERVICES="onedrive.service rclone-bisync.service rclone-bisync.timer"
# Các service bỏ qua không tắt (hệ thống/UI)
# EXCLUDE_LIST="dbus-broker|pipewire|wireplumber|swaync|rofi|hyprland|uwsm-"
# EXCLUDE_LIST=""

notify() {
    notify-send "$1" "$2" -i system-log-out -a "System Logout"
}

# 1. Giao diện xác nhận đăng xuất
# ACTION=$(echo -e "Safe Logout\nCancel" | rofi -dmenu -i -p "Action:" -theme-str 'window {width: 15em; font: "Sans 12";}')
# if [ "$ACTION" != "Safe Logout" ]; then
#     exit 0
# fi

notify "Logout Initiated" "Đang tắt an toàn các dịch vụ đồng bộ..."

# 2. Dừng timer và gửi lệnh tắt mềm

SERVICE="rclone-bisync.timer"
SERVICE_STATE=$(systemctl --user is-active $SERVICE)
if [[ "$SERVICE_STATE" == "active" || "$SERVICE_STATE" == "activating" || "$SERVICE_STATE" == "deactivating" ]]; then
    notify "Logging out" "$SERVICE status: $SERVICE_STATE..."
    notify "Logging out" "Đang tắt an toàn $SERVICE..."
    systemctl --user stop $SERVICE
fi

SERVICE="rclone-bisync.service"
SERVICE_STATE=$(systemctl --user is-active $SERVICE)
if [[ "$SERVICE_STATE" == "active" || "$SERVICE_STATE" == "activating" || "$SERVICE_STATE" == "deactivating" ]]; then
    notify "Logging out" "$SERVICE status: $SERVICE_STATE..."
    notify "Logging out" "Đang tắt an toàn $SERVICE..."
    systemctl --user stop $SERVICE
fi

SERVICE="onedrive.service"
SERVICE_STATE=$(systemctl --user is-active $SERVICE)
if [[ "$SERVICE_STATE" == "active" || "$SERVICE_STATE" == "activating" || "$SERVICE_STATE" == "deactivating" ]]; then
    notify "Logging out" "$SERVICE status: $SERVICE_STATE..."
    notify "Logging out" "Đang tắt an toàn $SERVICE..."
    systemctl --user stop $SERVICE
fi

# systemctl --user stop $CRITICAL_SERVICES --no-block

# 3. Vòng lặp vô hạn theo dõi các service quan trọng
while true; do
    # Lấy danh sách các service vẫn đang chạy
    ACTIVE=""
    for s in $CRITICAL_SERVICES; do
        SERVICE=$s
        SERVICE_STATE=$(systemctl --user is-active $SERVICE)
        if [[ "$SERVICE_STATE" == "active" || "$SERVICE_STATE" == "activating" || "$SERVICE_STATE" == "deactivating" ]]; then
            ACTIVE="$ACTIVE $s"
        fi
    done

    # Nếu không còn service nào chạy, thoát vòng lặp
    if [ -z "$ACTIVE" ]; then
        break
    fi

    # Đợi 2 giây cho service có thời gian lưu database
    sleep 2

    # Hỏi người dùng nếu service vẫn đang treo
    CHOICE=$(echo -e "Keep Waiting\nForce Kill & Logout\nCancel Logout" | rofi -dmenu -i -p "Đang bận:$ACTIVE" -theme-str 'window {width: 30em; font: "Sans 12";}')

    case "$CHOICE" in
        "Cancel Logout")
            notify "Cancelled" "Hủy đăng xuất, hệ thống trở lại bình thường."
            systemctl --user start rclone-bisync.timer
            systemctl --user start onedrive.service
            exit 0
            ;;
        "Force Kill & Logout")
            notify "Force Kill" "Buộc tắt các service (Có thể gây lỗi DB)..."
            for s in $ACTIVE; do
                # systemctl --user kill -s SIGKILL "$s"
                notify "Force kill" "$s..."
                # break
            done
            break
            ;;
        *)
            # "Keep Waiting" hoặc bấm Esc: Gửi lại lệnh tắt mềm và tiếp tục chờ
            systemctl --user stop $ACTIVE --no-block
            notify "Waiting" "$ACTIVE..."
            ;;
    esac
done

# 4. Tắt các user service còn lại để tránh delay 90s của systemd
# STILL_RUNNING=$(systemctl --user list-units --type=service --state=running --no-legend | awk '{print $1}' | grep -Ev "$EXCLUDE_LIST")
# if [ -n "$STILL_RUNNING" ]; then
#     notify "Cleanup" "Đang dọn dẹp các dịch vụ còn lại..."
#     # Dùng --no-block để tắt song song, không chờ đợi
#     echo "$STILL_RUNNING" | xargs -r -I {} systemctl --user stop {} --no-block
#     sleep 1
# fi

# 5. Thực hiện đăng xuất thực sự
notify "Success" "Hệ thống an toàn. Đang đăng xuất..."
sleep 1
uwsm stop
