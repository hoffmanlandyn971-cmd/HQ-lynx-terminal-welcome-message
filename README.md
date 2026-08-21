# HQ-lynx-terminal-welcome-message
🖥️ Welcome.sh — Interactive Terminal Dashboard for Linux & macOS

Turn your Linux or macOS terminal into a clean, animated, interactive system dashboard that greets you every time you open your shell.
To install this open terminal and paste:
curl -s https://raw.githubusercontent.com/hoffmanlandyn971-cmd/HQ-lynx-terminal-welcome-message/refs/heads/main/install_welcome.sh | bash

To uninstall this paste:
rm -rf ~/.config/welcome.sh ~/.cache/welcome.sh

Welcome.sh displays useful system information at startup while also providing an interactive menu packed with system tools, utilities, and customization options.

✨ Features
👋 Custom welcome message with your username
🌦️ Live weather information with customizable location
📊 Fastfetch system overview
🌐 Public & private IP information
📡 Wi-Fi/network information
💾 Disk usage monitoring
🧠 Memory usage statistics
⚙️ CPU information & temperature
🔥 Top CPU-consuming processes
📦 Package update detection
🔄 Built-in system updater
🔋 Battery information
🖥️ Interactive system menu
🧮 Built-in calculator
⏱️ Terminal timer
🔐 Password generator
🌐 Ping & DNS testing tools
🔌 Network connection viewer
📁 Large-file finder
📜 System log viewer
⚡ Animated loading effects
🧹 Cache management
📤 Export system information
📍 Change weather location directly from the menu
🔧 Reload configuration without reinstalling
🍓 Raspberry Pi detection & throttling status
🐧 Multi-distro support
🍎 Linux & macOS support
🎨 Fully customizable configuration
🚀 Lightweight and optimized with caching
🖥️ Interactive Menu

At the bottom of the welcome screen, Welcome.sh provides an interactive menu with tools such as:

╔══════════════════════════════════════════════╗
║              WELCOME.SH MENU                 ║
╠══════════════════════════════════════════════╣
║  1   System Information                      ║
║  2   Weather                                 ║
║  3   Network Information                     ║
║  4   Disk Usage                              ║
║  5   Memory Usage                            ║
║  6   Check for Updates                       ║
║  7   Update System                           ║
║  8   Clear Cache                             ║
║  9   Refresh                                 ║
║  10  Process Manager                         ║
║  11  CPU Details                             ║
║  12  Battery                                 ║
║  13  System Logs                             ║
║  14  Ping Test                               ║
║  15  DNS Lookup                              ║
║  16  Network Connections                     ║
║  17  Find Large Files                        ║
║  18  Services                                ║
║  19  Environment                             ║
║  20  Export System Info                      ║
║  21  Calculator                              ║
║  22  Timer                                   ║
║  23  Password Generator                      ║
║  24  Change Weather Location                 ║
║  25  Reload Configuration                    ║
║  26  About Welcome.sh                        ║
║  0   Exit                                    ║
╚══════════════════════════════════════════════╝
🌦️ Smart Weather

Weather can be configured for any location and is cached to reduce unnecessary requests.

Example:

WEATHER_LOCATION="Killeen+Texas"
WEATHER_FORMAT="3"

You can also change the location directly from the interactive menu.

⚡ Performance

Welcome.sh is designed to stay lightweight while still providing a lot of information.

⚡ Smart caching
⏱️ Request timeouts
🧹 Automatic cache management
🛡️ Error handling
🚫 Doesn't repeatedly request external services unnecessarily
🔄 Refreshable configuration
🎨 Configuration

Welcome.sh automatically creates its configuration file:

~/.config/welcome.sh/config

Edit it with:

nano ~/.config/welcome.sh/config

You can customize things such as:

SHOW_FASTFETCH=true
SHOW_WEATHER=true
SHOW_PUBLIC_IP=true
SHOW_PRIVATE_IP=true
SHOW_WIFI=true
SHOW_MEMORY=true
SHOW_CPU_TEMP=true


WEATHER_LOCATION="Killeen+Texas"
WEATHER_FORMAT="3"


CACHE_TIMEOUT=3600
REQUEST_TIMEOUT=5
🚀 Getting Started

Download or install Welcome.sh, make it executable, and launch it:

chmod +x welcome.sh
./welcome.sh

To automatically run it when opening your terminal, add it to your shell configuration such as:

~/.bashrc

or:

~/.zshrc
🛠️ Built for Customization

Welcome.sh is designed to be more than just a login message. It's a terminal dashboard and utility hub that you can continue expanding with new commands, animations, system tools, and custom features.

Lightweight. Interactive. Customizable. Built for your terminal. 🖥️⚡
