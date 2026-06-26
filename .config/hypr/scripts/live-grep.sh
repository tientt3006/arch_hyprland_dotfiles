#!/bin/bash
# ============================================================
# live-grep.sh - Tìm kiếm nội dung siêu tốc bằng fzf + ripgrep
# Yêu cầu cài đặt: fzf, ripgrep, bat
# ============================================================

# Kiểm tra dependency
if ! command -v fzf &> /dev/null || ! command -v rg &> /dev/null || ! command -v bat &> /dev/null; then
    echo "LỖI: Thiếu công cụ bắt buộc!"
    echo "Vui lòng chạy lệnh sau trên Terminal để cài đặt:"
    echo "sudo pacman -S fzf ripgrep bat"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

# Tự resize cửa sổ về đúng kích thước mong muốn ngay sau khi khởi tạo
# (Kitty có default size riêng có thể ghi đè windowrule)
sleep 0.15 && hyprctl dispatch resizeactive exact 90% 90% &

# Lệnh ripgrep tiêu chuẩn (hiển thị màu, số dòng, không header)
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"

# Giao diện fzf phối màu Catppuccin Mocha
# Nạp lại lệnh rg (Live Grep) mỗi khi gõ phím
SELECTED=$(
    fzf --ansi --disabled --query "" \
        --bind "start:reload:$RG_PREFIX {q} 2>/dev/null" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} 2>/dev/null || true" \
        --delimiter : \
        --preview 'bat --style=numbers --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}' \
        --preview-window 'right,60%,border-left,+{2}+3/3,~3' \
        --prompt "Live Grep> " \
        --info inline \
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8" \
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc" \
        --color="marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
)

# Nếu người dùng nhấn Esc hoặc không chọn gì
[ -z "$SELECTED" ] && exit 0

# Parse output (file:line:col:content)
FILE=$(echo "$SELECTED" | cut -d: -f1)

# Mở file bằng ứng dụng mặc định
gio open "$FILE"
