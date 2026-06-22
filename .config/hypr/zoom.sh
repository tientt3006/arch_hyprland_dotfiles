#!/bin/bash
CURRENT=$(hyprctl getoption cursor:zoom_factor | awk '/float/ {print $2}')
if [ "$1" = "in" ]; then
    NEW=$(echo "$CURRENT + 0.25" | bc)
else
#!/bin/bash

# Lấy giá trị zoom hiện tại của hệ thống
CURRENT=$(hyprctl getoption cursor:zoom_factor | awk '/float/ {print $2}')

# Kiểm tra tham số truyền vào từ phím tắt Hyprland
if [ "$1" = "in" ]; then
    NEW=$(echo "$CURRENT + 0.25" | bc)
else
    NEW=$(echo "$CURRENT - 0.25" | bc)
    
    # Không cho phép thu nhỏ hơn mức hiển thị bình thường (1.0)
    if (( $(echo "$NEW < 1.0" | bc -l) )); then 
        NEW=1.0
    fi
fi

# Gửi giá trị mới sau khi tính toán ngược lại cho Hyprland
hyprctl keyword cursor:zoom_factor $NEW    NEW=$(echo "$CURRENT - 0.25" | bc)
    # Không cho phép zoom nhỏ hơn 1.0 (mức bình thường)
    if (( $(echo "$NEW < 1.0" | bc -l) )); then NEW=1.0; fi
fi
hyprctl keyword cursor:zoom_factor $NEW
