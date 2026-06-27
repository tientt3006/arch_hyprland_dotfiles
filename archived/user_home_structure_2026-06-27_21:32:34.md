# Theo dõi Cấu trúc Thư mục Người dùng

Tài liệu này ghi lại toàn bộ cây thư mục và thông tin vai trò của các file/thư mục tại `/home/neitnd`.

**Thời gian tạo theo dõi:** `2026-06-27 21:32:34`

---

## 1. Cây Thư mục (Đến Cấp 2 phù hợp)

```text
🏠 `/home/neitnd` [Tổng dung lượng: 6.31 GB]
├── 📁 **.antigravity-ide/** [78.99 MB]
├── 📄 .bash_logout [21.00 B]
├── 📄 .bash_profile [57.00 B]
├── 📄 .bashrc [172.00 B]
├── 📁 **.cache/** [188.58 MB]
├── 📁 **.config/** [5.51 GB]
│   ├── 📁 Antigravity IDE/ [77.19 MB]
│   ├── 📁 Code/ [60.10 MB]
│   ├── 📁 Kvantum/ [38.00 B]
│   ├── 📄 MangoHud [35.00 B]
│   ├── 📄 QtProject.conf [535.00 B]
│   ├── 📁 Thunar/ [8.76 KB]
│   ├── 📁 btop/ [10.67 KB]
│   ├── 📄 chrome-flags.conf [44.00 B]
│   ├── 📄 cmus [31.00 B]
│   ├── 📁 dconf/ [3.97 KB]
│   ├── 📄 easyeffects [38.00 B]
│   ├── 📄 fastfetch [36.00 B]
│   ├── 📁 fcitx/ [74.00 B]
│   ├── 📄 fcitx5 [33.00 B]
│   └── 📁 go/ [80.00 KB]
│   └── 📄 ... (còn 29 mục khác)
├── 📁 **.copilot/** [0.00 B]
│   └── 📁 ide/ [0.00 B]
├── 📁 **.dart-tool/** [1.14 KB]
├── 📄 .flutter [44.00 B]
├── 📁 **.gemini/** [30.36 MB]
├── 📄 .gitconfig [88.00 B]
├── 📁 **.gnupg/** [65.20 KB]
├── 📄 .gtkrc-2.0 [611.00 B]
├── 📁 **.local/** [467.70 MB]
│   ├── 📁 bin/ [80.00 B]
│   ├── 📁 share/ [467.55 MB]
│   └── 📁 state/ [145.02 KB]
├── 📄 .nanorc [1.00 B]
├── 📁 **.nv/** [0.00 B]
│   └── 📁 ComputeCache/ [0.00 B]
├── 📁 **.oh-my-zsh/** [22.49 MB]
├── 📄 .p10k.zsh [87.40 KB]
├── 📁 **.pki/** [64.44 KB]
├── 📄 .python_history [0.00 B]
├── 📁 **.ssh/** [0.00 B]
├── 📄 .viminfo [19.80 KB]
├── 🔗 .vimrc ➔ neitnd_dotfiles/.vimrc [22.00 B]
├── 📁 **.vscode/** [828.00 B]
├── 📁 **.vscode-shared/** [24.00 KB]
├── 📄 .zcompdump [53.85 KB]
├── 📄 .zcompdump-arch-lig3-5.9 [51.47 KB]
├── 📄 .zcompdump-arch-lig3-5.9.1 [55.10 KB]
├── 📄 .zcompdump-arch-lig3-5.9.1.zwc [118.89 KB]
├── 📄 .zcompdump-arch-lig3-5.9.zwc [120.73 KB]
├── 🔗 .zprofile ➔ neitnd_dotfiles/.zprofile [25.00 B]
├── 📄 .zsh_history [40.12 KB]
├── 🔗 .zshrc ➔ neitnd_dotfiles/.zshrc [22.00 B]
├── 📁 **Downloads/** [0.00 B]
└── 📁 **neitnd_dotfiles/** [25.17 MB]
    ├── 📁 .config/ [1.97 MB]
    ├── 📁 .git/ [10.66 MB]
    ├── 📄 .gitignore [1.21 KB]
    ├── 📁 .local/ [12.21 MB]
    ├── 📄 .stow-local-ignore [156.00 B]
    ├── 📄 .vimrc [72.00 B]
    ├── 📄 .zprofile [164.00 B]
    ├── 📄 .zshrc [5.61 KB]
    ├── 📄 README.md [5.87 KB]
    ├── 📄 arch_experience.md [42.19 KB]
    ├── 📁 archived/ [91.85 KB]
    ├── 📁 my-sddm-theme/ [185.02 KB]
    ├── 📁 temp_docs/ [3.99 KB]
    └── 📄 user_home_structure.md [11.19 KB]
```

---

## 2. Danh sách Chi tiết & Vai trò (Cấp 1)

| Tên File/Thư mục | Loại | Kích thước | Vai trò / Mô tả |
| :--- | :--- | :--- | :--- |
| `.antigravity-ide` | Thư mục (Directory) | 78.99 MB | Môi trường làm việc và cấu hình của AI Agent Antigravity. |
| `.bash_logout` | File | 21.00 B | Script chạy khi đăng xuất khỏi shell Bash. |
| `.bash_profile` | File | 57.00 B | Cấu hình môi trường khi đăng nhập bằng shell Bash. |
| `.bashrc` | File | 172.00 B | File cấu hình mặc định cho trình shell Bash (không sử dụng do dùng Zsh). |
| `.cache` | Thư mục (Directory) | 188.58 MB | Bộ nhớ đệm (cache) của các ứng dụng, có thể xóa đi mà không mất dữ liệu cấu hình. |
| `.config` | Thư mục (Directory) | 5.51 GB | Thư mục lưu trữ cấu hình của các ứng dụng người dùng (XDG Config Home). Hầu hết được liên kết đến dotfiles. |
| `.copilot` | Thư mục (Directory) | 0.00 B | Mục phát sinh từ ứng dụng hoặc cấu hình riêng lẻ. |
| `.dart-tool` | Thư mục (Directory) | 1.14 KB | Các file cấu hình và cache của Dart SDK. |
| `.flutter` | File | 44.00 B | File cấu hình/cache của Flutter SDK. |
| `.gemini` | Thư mục (Directory) | 30.36 MB | Thư mục ứng dụng của Gemini Agent IDE. |
| `.gitconfig` | File | 88.00 B | Cấu hình Git toàn cục (user name, email, alias). |
| `.gnupg` | Thư mục (Directory) | 65.20 KB | Lưu trữ các khóa mã hóa GnuPG. |
| `.gtkrc-2.0` | File | 611.00 B | Cấu hình theme cho các ứng dụng viết bằng thư viện GTK2. |
| `.local` | Thư mục (Directory) | 467.70 MB | Thư mục chứa các dữ liệu cục bộ của người dùng (binaries tự cài, dữ liệu ứng dụng, share, state). |
| `.nanorc` | File | 1.00 B | File cấu hình của trình soạn thảo văn bản Nano. |
| `.nv` | Thư mục (Directory) | 0.00 B | Thư mục cache và cấu hình của driver NVIDIA. |
| `.oh-my-zsh` | Thư mục (Directory) | 22.49 MB | Bộ khung (framework) quản lý cấu hình Zsh shell và các plugin đi kèm. |
| `.p10k.zsh` | File | 87.40 KB | File cấu hình giao diện thanh nhập lệnh Powerlevel10k cho Zsh. |
| `.pki` | Thư mục (Directory) | 64.44 KB | Kho chứng chỉ số bảo mật cá nhân (Public Key Infrastructure). |
| `.python_history` | File | 0.00 B | Lịch sử các lệnh đã gõ trong terminal Python. |
| `.ssh` | Thư mục (Directory) | 0.00 B | Lưu trữ các khóa SSH (private/public keys) để kết nối bảo mật. |
| `.viminfo` | File | 19.80 KB | Lưu lịch sử phiên làm việc, con trỏ, register của Vim. |
| `.vimrc` | Symlink (trỏ tới `neitnd_dotfiles/.vimrc`) | 22.00 B | File cấu hình chính của trình soạn thảo Vim. |
| `.vscode` | Thư mục (Directory) | 828.00 B | Lưu trữ cấu hình của VS Code. |
| `.vscode-shared` | Thư mục (Directory) | 24.00 KB | Thư mục dữ liệu chia sẻ của VS Code. |
| `.zcompdump` | File | 53.85 KB | Bộ nhớ đệm (cache) chứa định nghĩa autocompletion của Zsh. |
| `.zcompdump-arch-lig3-5.9` | File | 51.47 KB | Bộ nhớ đệm autocompletion của Zsh bản 5.9. |
| `.zcompdump-arch-lig3-5.9.1` | File | 55.10 KB | Bộ nhớ đệm autocompletion của Zsh bản 5.9.1. |
| `.zcompdump-arch-lig3-5.9.1.zwc` | File | 118.89 KB | File cache đã biên dịch (compiled) cho zcompdump 5.9.1. |
| `.zcompdump-arch-lig3-5.9.zwc` | File | 120.73 KB | File cache đã biên dịch (compiled) cho zcompdump 5.9. |
| `.zprofile` | Symlink (trỏ tới `neitnd_dotfiles/.zprofile`) | 25.00 B | Cấu hình môi trường khi đăng nhập shell. |
| `.zsh_history` | File | 40.12 KB | Lịch sử các lệnh shell zsh đã chạy của người dùng. |
| `.zshrc` | Symlink (trỏ tới `neitnd_dotfiles/.zshrc`) | 22.00 B | File cấu hình chính của Zsh (được Stow trỏ sang dotfiles). |
| `Downloads` | Thư mục (Directory) | 0.00 B | Thư mục tải về mặc định của người dùng. |
| `neitnd_dotfiles` | Thư mục (Directory) | 25.17 MB | Repo Git chứa toàn bộ dotfiles cá nhân được quản lý bằng GNU Stow. |

---
*Ghi chú: Dung lượng thư mục được tính toán động dựa trên tất cả các tệp tin chứa bên trong.*
