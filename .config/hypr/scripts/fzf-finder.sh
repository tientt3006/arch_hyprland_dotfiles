#!/bin/bash
# ============================================================
# fzf-finder.sh - Tìm kiếm file & thư mục siêu tốc (Streaming)
# Hỗ trợ tùy chọn bộ lọc và tắt terminal ngay khi mở app
# ============================================================

# Kiểm tra dependency
if ! command -v fzf &> /dev/null || ! command -v fd &> /dev/null; then
    echo "LỖI: Thiếu công cụ bắt buộc!"
    echo "sudo pacman -S fzf fd"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

# Tự resize cửa sổ về 90% để hiện ở giữa màn hình
sleep 0.15 && hyprctl dispatch resizeactive exact 90% 90% &> /dev/null &

# Giao diện Catppuccin Mocha cho FZF
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ==========================================
# BƯỚC 1: Chọn Chế Độ Tìm Kiếm
# ==========================================
MODE_SELECTION=$(echo -e "1. Tiêu chuẩn (Nhanh - Bỏ qua các file/folder ẩn ở màn hình Home)\n2. Chuyên sâu (Tìm toàn bộ kể cả file ẩn)" | \
    fzf --prompt="🔍 Chọn Chế Độ Tìm Kiếm> " \
        --header="Nhấn Enter để chọn chế độ" \
        --info=inline \
        --height=100%)

[ -z "$MODE_SELECTION" ] && exit 0

# ==========================================
# BƯỚC 2: Cấu Hình Bộ Lọc
# ==========================================
# Danh sách exclude rác và cloud drives (luôn luôn áp dụng)
EXCLUDES=(
    --exclude ".git"
    --exclude ".cache"
    --exclude ".cargo"
    --exclude ".oh-my-zsh"
    --exclude ".pub-cache"
    --exclude ".vscode"
    --exclude ".vscode-shared"
    --exclude ".antigravity-ide"
    --exclude ".gemini"
    --exclude ".nv"
    --exclude ".pki"
    --exclude ".copilot"
    --exclude ".gnupg"
    --exclude ".ssh"
    --exclude ".dart-tool"
    --exclude "node_modules"
    --exclude ".local/share/Trash"
    --exclude ".local/share/logs"
    --exclude ".local/share/nvim"
    # --exclude "GDrive"
    # --exclude "OneDrive"
    --exclude "vendor"
)

# Nếu người dùng chọn "Tiêu chuẩn", thêm luật: bỏ qua tất cả file/folder bắt đầu bằng dấu chấm (.) ở ngay cấp 1 của thư mục Home.
if [[ "$MODE_SELECTION" == 1* ]]; then
    EXCLUDES+=("--exclude" "/.*")
fi

# ==========================================
# BƯỚC 3: Streaming Tìm Kiếm
# ==========================================
SELECTION=$(fd . "$HOME" --hidden "${EXCLUDES[@]}" 2>/dev/null | \
    fzf --prompt="🔍 Tìm File/Thư mục> " \
        --header="Enter: Mở | Cuộn bằng chuột | Esc: Thoát" \
        --info=inline \
        --height=100% \
        --preview="$HOME/.config/hypr/scripts/fzf-preview.sh {}" \
        --preview-window=right:60%:wrap)

[ -z "$SELECTION" ] && exit 0

# ==========================================
# BƯỚC 4: Mở File/Thư Mục & Tắt Terminal
# ==========================================
# Sử dụng hyprctl dispatch exec để uỷ quyền cho Hyprland mở app, 
# nhờ đó script không bị "giam" lại chờ app tắt, và Terminal Kitty sẽ lập tức đóng lại.

if [ -d "$SELECTION" ]; then
    # Nếu là thư mục, mở bằng Thunar
    hyprctl dispatch exec "uwsm app -- thunar \"$SELECTION\""
else
    # Nếu là file, mở bằng ứng dụng mặc định
    hyprctl dispatch exec "uwsm app -- gio open \"$SELECTION\""
fi

exit 0
