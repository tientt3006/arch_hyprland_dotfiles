# LazyVim Basic Usage Guide

LazyVim is a Neovim setup that turns your terminal text editor into a full-fledged IDE.

## 1. Core Concepts
- **Leader Key:** The Leader key in LazyVim is the **Spacebar** (`<Space>`).
- **Which-Key:** Whenever you press the Leader key or any other shortcut prefix, a popup will appear at the bottom showing you the available next keys and their functions. If you forget a shortcut, just press `<Space>` and wait!

## 2. File Navigation
- `<Space> e`: Toggle **Neo-tree** (the file explorer on the left).
  - Press `?` inside Neo-tree to see all its shortcuts.
- `<Space> f f`: **Find Files** (opens Telescope to search for files by name).
- `<Space> s g`: **Live Grep** (search for text inside all files in the current project).
- `<Space> ,`: Switch between open buffers (tabs).

## 3. Window & Buffer Management
- `Ctrl + h/j/k/l`: Move cursor between split windows.
- `<Space> b d`: Delete the current buffer (close the file without messing up the window layout).
- `<Space> |`: Split window vertically.
- `<Space> -`: Split window horizontally.

## 4. Code & LSP (Language Server Protocol)
- `K`: Hover over a variable/function to see its documentation.
- `g d`: Go to definition of a variable/function.
- `g r`: Find references to the symbol under the cursor.
- `<Space> c r`: Rename the symbol across the entire project.
- `<Space> c a`: Show Code Actions (quick fixes).

## 5. Plugin Management
- `<Space> l`: Open the **Lazy.nvim** UI to update, clean, or profile your plugins.
- `<Space> c m`: Open **Mason** UI to install new LSPs, formatters, and linters (e.g., Python `black`, JS `prettier`, C++ `clangd`).

## 6. Exiting
- `<Space> q q`: Quit Neovim quickly.
