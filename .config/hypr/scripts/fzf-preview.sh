#!/bin/bash
# ============================================================
# fzf-preview.sh - Trình xem trước thông minh cho fzf
# ============================================================

FILE="$1"

# 1. Nếu là thư mục
if [ -d "$FILE" ]; then
    ls -la --color=always "$FILE"
    exit 0
fi

# 2. Nếu là file, kiểm tra xem có phải file ảnh không
if [ -f "$FILE" ]; then
    MIME=$(file -b --mime-type "$FILE")
    
    if [[ "$MIME" == image/* ]]; then
        # Nếu có chafa (phần mềm chuyên render ảnh ASCII siêu đẹp trên terminal)
        if command -v chafa &> /dev/null; then
            chafa -f symbols --size="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}" "$FILE"
        else
            # Chạy thử kitty icat (Lưu ý: icat đôi khi bị đè hình do cơ chế xoá màn hình của fzf)
            kitty +kitten icat --clear --transfer-mode=memory --stdin=no --place="${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0" "$FILE"
        fi
    else
        # Nếu là file văn bản/code
        if command -v bat &> /dev/null; then
            bat --color=always --style=numbers --line-range=:500 "$FILE" 2>/dev/null
        else
            head -n 100 "$FILE"
        fi
    fi
fi
