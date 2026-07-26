# OpenFortiVPN Setup & Usage Guide

## 1. Introduction
The official FortiClient app on Linux is notoriously heavy, buggy (often crashing or experiencing "invisible tray" issues on modern Wayland/Hyprland setups), and poorly maintained compared to its Windows counterpart. 

`openfortivpn` is an open-source, highly stable, and lightweight CLI alternative developed by the Linux community. It natively supports Fortinet's SSL VPN protocol and seamlessly connects to your corporate network without requiring any graphical overhead.

## 2. Installation
`openfortivpn` is available in the official Arch Linux repositories.

```bash
# Install via yay (or pacman)
yay -S openfortivpn
```

## 3. Basic Connection (Manual)
To connect manually, use the following syntax. You will be prompted for your password interactively.

```bash
sudo openfortivpn [vpn_host]:[port] -u [username]
# Example:
sudo openfortivpn vpn.company.com:443 -u my_username
```

### 3.1. Handling the "Untrusted Certificate" Error
Often, corporate VPN gateways use self-signed certificates. If you connect for the first time, `openfortivpn` will reject the connection to prevent Man-In-The-Middle (MITM) attacks and print an error similar to this:

```
ERROR:  Gateway certificate validation failed...
ERROR:      --trusted-cert a780d9cb984a37948e0ac2f52b158040be22089b6ee805c504c0f649058a20e6
```

Simply copy the provided certificate hash and append it to your connection command:
```bash
sudo openfortivpn vpn.company.com:443 -u my_username --trusted-cert a780d9cb984a37948e0ac2f52b158040be22089b6ee805c504c0f649058a20e6
```

## 4. Setting up a Config Profile (Recommended)
To avoid typing the host, username, and certificate hash every time, you can store your configuration in the default `openfortivpn` config file.

1. **Edit the configuration file:**
   ```bash
   sudo nano /etc/openfortivpn/config
   ```

2. **Add your connection details:**
   ```ini
   host = vpn.company.com
   port = 443
   username = my_username
   # password = my_secret_password (Optional: Remove this line to type it manually each time for security)
   trusted-cert = a780d9cb984a37948e0ac2f52b158040be22089b6ee805c504c0f649058a20e6
   ```

3. **Secure the file:**
   Since this file contains sensitive network details (and potentially your password), lock it down so only the root user can read it:
   ```bash
   sudo chmod 600 /etc/openfortivpn/config
   ```

## 5. Connecting with One Command
Once your `/etc/openfortivpn/config` file is set up, connecting is as simple as running:

```bash
sudo openfortivpn
```
*(Keep the terminal open while you work. To disconnect, simply press `Ctrl + C` in the terminal).*

### 5.1. Creating a Zsh Alias
For maximum convenience, you can create a shortcut command in your Zsh configuration.

1. Open your `~/.zshrc`:
   ```bash
   nano ~/.zshrc
   ```
2. Add this alias to the bottom:
   ```bash
   alias vpn="sudo openfortivpn"
   ```
3. Reload Zsh:
   ```bash
   source ~/.zshrc
   ```
Now, whenever you need to access the corporate network, simply open Kitty, type `vpn`, and you're in!
