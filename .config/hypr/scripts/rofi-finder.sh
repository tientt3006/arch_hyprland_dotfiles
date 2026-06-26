#!/bin/bash
# ============================================================
# rofi-finder.sh - Tìm kiếm file & thư mục bằng Rofi + fd
# Tối ưu: fd --type tách luồng song song, không dùng awk/test
# Phím tắt:
#   Enter    → Mở file/thư mục bằng ứng dụng mặc định
#   Alt+D    → Mở thư mục chứa file bằng Thunar
#   Alt+T    → Mở terminal (Kitty) tại thư mục chứa
#   Alt+E    → Mở file bằng editor (nvim)
# ============================================================

if ! command -v fd &>/dev/null; then
    notify-send "rofi-finder" "Thiếu gói 'fd'. Cài bằng: sudo pacman -S fd" --urgency=critical
    exit 1
fi

# Danh sách exclude chung
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
)

# Lấy danh sách 20 file/thư mục mở gần đây nhất từ GTK (mọi app)
RECENT_LIST=$(python3 -c '
import xml.etree.ElementTree as ET, urllib.parse, os
try:
    root = ET.parse(os.path.expanduser("~/.local/share/recently-used.xbel")).getroot()
    paths = [urllib.parse.unquote(b.attrib["href"][7:]) for b in root.findall("bookmark") if b.attrib["href"].startswith("file://")]
    seen = set()
    for p in reversed(paths):
        if p not in seen and os.path.exists(p):
            seen.add(p)
            print((" " if os.path.isdir(p) else "󰈔 ") + p)
            if len(seen) >= 25: break
except Exception:
    pass
')

# Tách 2 luồng SONG SONG: fd thư mục và fd file, prefix icon ngay trong fd
FILE_LIST=$(
    {
        [ -n "$RECENT_LIST" ] && echo "$RECENT_LIST"
        fd . "$HOME" --type d --hidden "${EXCLUDES[@]}" 2>/dev/null | sed 's/^/ /'
        fd . "$HOME" --type f --hidden "${EXCLUDES[@]}" 2>/dev/null | sed 's/^/󰈔 /'
    } | awk "!seen[\$0]++"
)

SELECTION=$(echo "$FILE_LIST" | rofi -dmenu \
        -p "  Tìm kiếm" \
        -i \
        -mesg "Enter: Mở  |  Alt+D: Thư mục chứa  |  Alt+T: Terminal tại đây  |  Alt+E: Editor" \
        -kb-custom-1 "alt+d" \
        -kb-custom-2 "alt+t" \
        -kb-custom-3 "alt+e" \
        -theme "$HOME/.config/rofi/config.rasi")

EXIT_CODE=$?

[ -z "$SELECTION" ] && exit 0

# Cắt icon prefix (ký tự đầu tiên + dấu cách) để lấy đường dẫn thật
REAL_PATH="${SELECTION#* }"

if [ -d "$REAL_PATH" ]; then
    PARENT_DIR="$REAL_PATH"
else
    PARENT_DIR=$(dirname "$REAL_PATH")
fi

case $EXIT_CODE in
    0)
        if [ -d "$REAL_PATH" ]; then
            uwsm app -- thunar "$REAL_PATH"
        else
            uwsm app -- gio open "$REAL_PATH"
        fi
        ;;
    10)
        uwsm app -- thunar "$PARENT_DIR"
        ;;
    11)
        uwsm app -- kitty --directory "$PARENT_DIR"
        ;;
    12)
        if [ -d "$REAL_PATH" ]; then
            uwsm app -- kitty --directory "$REAL_PATH" sh -c "nvim ."
        else
            uwsm app -- kitty --directory "$PARENT_DIR" sh -c "nvim '$(basename "$REAL_PATH")'"
        fi
        ;;
esac
