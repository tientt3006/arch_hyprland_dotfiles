#!/bin/bash
# ~/.config/hypr/scripts/smart-idle.sh
# Lấy trạng thái nguồn (1: đang sạc, 0: dùng pin)
AC_ONLINE=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1)

MODE=$1    # Lời gọi: "ac", "bat", hoặc "resume"
ACTION=$2  # Lời gọi: "dim", "dpms_off", "dpms_on", "lock", "suspend"

# Kiểm tra hoàn cảnh: Đang dùng pin mà mốc thời gian là của cắm sạc -> Bỏ qua!
if [ "$MODE" = "ac" ] && [ "$AC_ONLINE" != "1" ]; then exit 0; fi
if [ "$MODE" = "bat" ] && [ "$AC_ONLINE" == "1" ]; then exit 0; fi

# Nếu đúng hoàn cảnh, thực thi lệnh:
case $ACTION in
    dim)
        if [ "$MODE" = "resume" ]; then
            brightnessctl -r
        else
            brightnessctl -s # Lưu lại độ sáng cũ
            CURRENT=$(brightnessctl g)
            MAX=$(brightnessctl m)
            TARGET=$((MAX * 5 / 100))
            
            if [ "$CURRENT" -gt "$TARGET" ]; then
                STEP=$(( (CURRENT - TARGET) / 30 ))
                if [ "$STEP" -gt 0 ]; then
                    for i in {1..30}; do
                        brightnessctl s ${STEP}- -q
                        sleep 0.02
                    done
                fi
            fi
            # Đảm bảo điểm dừng chính xác là 5%
            brightnessctl s 5% -q
        fi
        ;;
    dpms_off)
        hyprctl dispatch "hl.dsp.dpms('off')"
        ;;
    dpms_on)
        hyprctl dispatch "hl.dsp.dpms('on')"
        ;;
    lock)
        loginctl lock-session
        ;;
    suspend)
        systemctl suspend
        ;;
esac
