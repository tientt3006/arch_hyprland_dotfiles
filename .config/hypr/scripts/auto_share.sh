#!/bin/bash
# Lấy tên màn hình đầu tiên đang bật (ví dụ: eDP-1)
MONITOR=$(hyprctl monitors | grep Monitor | head -n 1 | awk '{print $2}')
# Thêm độ trễ để tránh lỗi nhận diện quá nhanh của RustDesk/Portal
sleep 5
# Tự động gửi kết quả chọn màn hình đó cho hệ thống
echo "[SELECTION]/screen:$MONITOR"
