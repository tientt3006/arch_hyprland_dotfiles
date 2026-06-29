#!/bin/bash
# Daemon lắng nghe sự kiện mở cửa sổ mới để ép nó nổi lên nếu đang ở chế độ Full Float

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == openwindow* ]]; then
        # Tối ưu luồng: Xử lý chuỗi bằng tính năng nội tại của Bash thay vì gọi awk (giảm tải CPU)
        # Format sự kiện: openwindow>>address,workspace_name,class,title
        DATA="${line#*>>}"
        ADDRESS="${DATA%%,*}"
        REMAINDER="${DATA#*,}"
        WORKSPACE_NAME="${REMAINDER%%,*}"
        
        # Bọc toàn bộ khối xử lý vào trong ( ... ) & để chạy nền (async)
        # Giúp vòng lặp socat không bao giờ bị chặn (non-blocking) ngay cả khi đang sleep
        (
            # Kiểm tra xem Workspace này có đang bật Float Mode không
            if [ -f "/tmp/hypr_float_mode_$WORKSPACE_NAME" ]; then
                sleep 0.1
                # Ép nổi cửa sổ
                hyprctl dispatch setfloating address:0x$ADDRESS
                
                # Resize 80% và đưa vào giữa
                hyprctl dispatch resizewindowpixel exact 80% 80%,address:0x$ADDRESS
                hyprctl dispatch centerwindow
            fi
        ) &
    fi
done
