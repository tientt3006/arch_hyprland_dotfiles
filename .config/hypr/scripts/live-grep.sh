#!/bin/bash
# ============================================================
# live-grep.sh - Tìm kiếm nội dung siêu tốc bằng fzf + ripgrep
# Đã nâng cấp thành Multi-stage Wizard (Optimized for Ricing & Dev)
# ============================================================

# Kiểm tra dependency
if ! command -v fzf &> /dev/null || ! command -v rg &> /dev/null || ! command -v bat &> /dev/null; then
    echo "LỖI: Thiếu công cụ bắt buộc!"
    echo "sudo pacman -S fzf ripgrep bat"
    read -p "Nhấn Enter để thoát..."
    exit 1
fi

# Tự resize cửa sổ về 90%
sleep 0.15 && hyprctl dispatch resizeactive exact 90% 90% &> /dev/null &

# Giao diện Catppuccin Mocha cho FZF
export FZF_DEFAULT_OPTS="--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# ==========================================
# BƯỚC 1: Chọn thư mục Root
# ==========================================
# Liệt kê cả thư mục ẩn (cần thiết cho ricing như .config), nhưng bỏ qua các "bãi rác" hệ thống
SEARCH_DIR=$(find "$HOME" -maxdepth 3 -type d 2>/dev/null | grep -vE "(/\.cache|/\.mozilla|/\.local/share|/\.wine|/\.cargo|/\.rustup|/node_modules|/vendor|/\.var|/\.gemini)" | \
    fzf --prompt="1/4. Select Search Directory> " \
        --header="Press ENTER to select a directory, or ESC to abort" \
        --info=inline \
        --height=100%)

[ -z "$SEARCH_DIR" ] && exit 0

# ==========================================
# BƯỚC 2: Chọn Loại File (File Type)
# ==========================================
TYPE_SELECTION=$(echo -e "All Types (Default)\nconf\njsonc\nlua\ntoml\nyaml\njson\nsh (bash)\npython (py)\njavascript (js)\ntypescript (ts)\nhtml\ncss\nmarkdown (md)\nc\ncpp\nrust\ngo\njava" | \
    fzf --multi \
        --prompt="2/4. File Types (TAB to multi-select)> " \
        --header="Press TAB to select specific types (e.g. conf, lua), then ENTER" \
        --info=inline \
        --height=100%)

[ -z "$TYPE_SELECTION" ] && exit 0

# Build tham số lọc file cho ripgrep
RG_TYPE_OPTS=""
if ! echo "$TYPE_SELECTION" | grep -qi "All Types"; then
    for t in $TYPE_SELECTION; do
        ext=$(echo "$t" | awk '{print $1}') # Lấy từ khóa đầu tiên (conf, lua, python...)
        
        # Ánh xạ ngôn ngữ chuẩn của ripgrep
        if [ "$ext" = "python" ]; then RG_TYPE_OPTS="$RG_TYPE_OPTS -t py"
        elif [ "$ext" = "javascript" ]; then RG_TYPE_OPTS="$RG_TYPE_OPTS -t js"
        elif [ "$ext" = "typescript" ]; then RG_TYPE_OPTS="$RG_TYPE_OPTS -t ts"
        elif [ "$ext" = "markdown" ]; then RG_TYPE_OPTS="$RG_TYPE_OPTS -t md"
        elif [ "$ext" = "sh" ]; then RG_TYPE_OPTS="$RG_TYPE_OPTS -t sh"
        # Các file dạng config (ripgrep không hỗ trợ -t mặc định thì dùng glob)
        else
            RG_TYPE_OPTS="$RG_TYPE_OPTS -g '*.$ext'"
        fi
    done
fi

# ==========================================
# BƯỚC 3: Chọn Ignore Rules
# ==========================================
IGNORE_SELECTION=$(echo -e "1. [Default] Smart Ignore (node_modules, build, vendor, caches)\n2. [Toggle] Search Hidden Files (--hidden)\n3. [Toggle] Search INSIDE node_modules\n4. [Toggle] Search INSIDE vendor\n5. [Toggle] Search INSIDE build/target\n6. [DANGER] Search EVERYTHING (--no-ignore --hidden)" | \
    fzf --multi \
        --prompt="3/4. Ignore Rules (TAB to multi-select)> " \
        --header="Press TAB to override default rules, then ENTER" \
        --info=inline \
        --height=100%)

[ -z "$IGNORE_SELECTION" ] && exit 0

RG_IGNORE_OPTS=""

# Bỏ qua các rác hệ thống vĩnh viễn (trừ khi chọn DANGER)
if ! echo "$IGNORE_SELECTION" | grep -q "DANGER"; then
    RG_IGNORE_OPTS="$RG_IGNORE_OPTS -g '!.cache/*' -g '!.mozilla/*' -g '!.local/share/*' -g '!.wine/*' -g '!.cargo/*' -g '!.config/google-chrome/*' -g '!.config/mozilla/*' -g '!.config/Code/*' -g '!.config/Antigravity IDE/*' -g '!.gemini/*'"
fi

# Nếu KHÔNG chọn "Search INSIDE node_modules", thì mặc định sẽ bỏ qua chúng
if ! echo "$IGNORE_SELECTION" | grep -q "INSIDE node_modules"; then
    RG_IGNORE_OPTS="$RG_IGNORE_OPTS -g '!node_modules/*'"
fi

# Nếu KHÔNG chọn "Search INSIDE vendor", thì mặc định sẽ bỏ qua chúng
if ! echo "$IGNORE_SELECTION" | grep -q "INSIDE vendor"; then
    RG_IGNORE_OPTS="$RG_IGNORE_OPTS -g '!vendor/*'"
fi

# Nếu KHÔNG chọn "Search INSIDE build/target", thì mặc định sẽ bỏ qua chúng
if ! echo "$IGNORE_SELECTION" | grep -q "INSIDE build/target"; then
    RG_IGNORE_OPTS="$RG_IGNORE_OPTS -g '!build/*' -g '!target/*'"
fi

# Bật tìm kiếm file ẩn (như .bashrc, .env, .config/...)
if echo "$IGNORE_SELECTION" | grep -q "Search Hidden Files"; then
    RG_IGNORE_OPTS="$RG_IGNORE_OPTS --hidden"
fi

# Nếu chọn DANGER, phá vỡ mọi quy tắc
if echo "$IGNORE_SELECTION" | grep -q "DANGER"; then
    RG_IGNORE_OPTS="--no-ignore --hidden"
fi

# ==========================================
# BƯỚC 4: Màn hình LIVE GREP
# ==========================================
# Tham số ripgrep tổng hợp
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case $RG_TYPE_OPTS $RG_IGNORE_OPTS"

SELECTED=$(
    fzf --ansi --disabled --query "" \
        --bind "start:reload:$RG_PREFIX {q} '$SEARCH_DIR' 2>/dev/null" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} '$SEARCH_DIR' 2>/dev/null || true" \
        --delimiter : \
        --preview 'bat --style=numbers --color=always {1} --highlight-line {2} 2>/dev/null || cat {1}' \
        --preview-window 'right,60%,border-left,+{2}+3/3,~3' \
        --prompt "4/4. Live Grep> " \
        --info inline
)

[ -z "$SELECTED" ] && exit 0

FILE=$(echo "$SELECTED" | cut -d: -f1)
gio open "$FILE"
