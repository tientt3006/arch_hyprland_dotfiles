# Tmux Setup & Usage Guide

Tmux (Terminal Multiplexer) is a "window manager" for the terminal. It allows you to run multiple sessions simultaneously, split the screen, and crucially, keeps commands running in the background even if the terminal is closed or the network connection drops.

## 1. Core Concepts & The "Prefix" Key

To use Tmux, you need to understand its 3-level hierarchy:
- **Session**: A complete workspace. You can have one session for a "coding project" and another for "server monitoring".
- **Window**: Similar to browser tabs (Tab 1, Tab 2, etc.), contained within a Session.
- **Pane**: Sub-divided areas within a Window (e.g., splitting the screen vertically or horizontally).

**The Prefix Key (The Master Key):**
Every Tmux shortcut begins with a specific key combination called the **Prefix**.
- The default Prefix is: **`Ctrl + B`**
- *How to press:* Press and hold `Ctrl`, tap `B`, then **release both keys** before pressing the next shortcut key.
- *Note:* In the custom configuration below, we will change this Prefix to **`Ctrl + A`** for better ergonomics.

---

## 2. Default (Base) Usage Guide (Without Config)

If you are on a fresh system without a `~/.tmux.conf`, you must use the default `Ctrl + B` prefix.

### Managing Sessions
- **Start a new session:** `tmux`
- **Start a named session (Recommended):** `tmux new -s dev`
- **Detach (Leave it running in the background):** Press `Prefix` then `d`
- **List running sessions:** `tmux ls`
- **Attach to a specific session:** `tmux a -t dev`
- **Kill a session:** `tmux kill-session -t dev`

### Managing Windows (Tabs)
- **Create new window:** `Prefix` then `c`
- **Next/Previous window:** `Prefix` then `n` / `Prefix` then `p`
- **Switch by number:** `Prefix` then `0`, `1`, `2`, etc.
- **Rename current window:** `Prefix` then `,`
- **Close window:** `Prefix` then `&` (or type `exit` in the shell)

### Managing Panes (Splits)
- **Split vertically (Left/Right):** `Prefix` then `%`
- **Split horizontally (Top/Bottom):** `Prefix` then `"`
- **Move between panes:** `Prefix` then `Arrow Keys`
- **Zoom a pane to full screen:** `Prefix` then `z` (press again to unzoom)
- **Close pane:** `Prefix` then `x` (or type `exit`)

### Scrolling & Copy/Paste (Copy Mode) - Essential for TTY
- **Enter Copy Mode (to scroll up):** `Prefix` then `[`
- **Scroll:** Use `Arrow Keys` or `PageUp`/`PageDown`.
- **Copy Text:** While in Copy Mode, move the cursor to the start of the text. Press `Ctrl+Space` to start highlighting. Use arrow keys to select text. Press `Alt+w` (or `Enter` depending on version) to copy the selected text and exit Copy Mode.
- **Paste Text:** Press `Prefix` then `]` to paste the copied text.
- **Search:** Press `Ctrl+S` (forward) or `Ctrl+R` (backward).
- **Exit scroll mode without copying:** Press `q` or `Esc`.

---

## 3. Advanced Configuration (`~/.tmux.conf`)

The default Tmux bindings are not very ergonomic. Create a config file to supercharge Tmux:

```bash
nano ~/.tmux.conf
```

Add the following optimized configuration:

```tmux
# 1. Change Prefix from Ctrl+B to Ctrl+A (Easier to reach with left hand)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 2. Enable mouse support (allow scrolling and clicking to select Panes/Windows)
set -g mouse on

# 3. Start Window and Pane numbering from 1 instead of 0
set -g base-index 1
setw -g pane-base-index 1

# 4. Use Vim-like keys to switch Panes
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# 5. Use Alt + Arrow Keys (or Alt + h/j/k/l) to switch Panes WITHOUT the Prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# 6. Intuitive split keys (| for vertical, - for horizontal)
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# 7. Quick reload configuration file (Prefix + r)
bind r source-file ~/.tmux.conf \; display "Tmux configuration reloaded!"

# 8. Enable Vi-mode in Copy Mode (Use j,k to scroll, v to highlight, y to yank/copy)
set-window-option -g mode-keys vi

# --- Tmux Plugin Manager (TPM) ---
# Install via: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'

# Optional: Add a nice theme like Dracula or Catppuccin
# set -g @plugin 'dracula/tmux'
# set -g @plugin 'catppuccin/tmux'

# Initialize TPM (Keep this at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'
```

**Apply the configuration:**
Inside Tmux, press `Prefix` + `:` and type `source-file ~/.tmux.conf`, or completely restart the Tmux server (`tmux kill-server`).

---

## 4. Usage Guide WITH Custom Configuration

After applying the configuration above, your workflow will become much faster:

- **The New Prefix is `Ctrl + A`**.
- **Split Vertically:** `Ctrl + A` then `|`
- **Split Horizontally:** `Ctrl + A` then `-`
- **Fast Pane Switching:** Just hold `Alt` and press `Arrow Keys` (No prefix needed!).
- **Scrolling:** Because `mouse on` is set, you can just use your **mouse wheel** to scroll back output directly!
- **TTY Scrolling & Copying:** Press `Ctrl + A` then `[`. You can now use Vim keys (`j` / `k`) to scroll up and down.
  - **To Copy:** Press `v` to start selecting text. Move with Vim keys to highlight. Press `y` to copy (yank) the text and exit Copy Mode.
  - **To Paste:** Press `Ctrl + A` then `]` to paste the text you just copied.
  - **To Exit:** Press `q` or `Esc`.
- **Install Plugins:** Press `Ctrl + A` then `I` (Capital i) to install plugins managed by TPM.

## 5. Synchronizing Panes (Advanced Trick)
If you want to type the same command into multiple Panes simultaneously (e.g., updating multiple SSH servers at once):
1. **Turn ON:** `Prefix` then `:setw synchronize-panes on`
2. **Turn OFF:** `Prefix` then `:setw synchronize-panes off`
