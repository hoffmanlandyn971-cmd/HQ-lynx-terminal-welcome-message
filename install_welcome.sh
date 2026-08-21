#!/bin/bash

# ============================================================
# WELCOME.SH
# System Dashboard + Interactive Tools
# ============================================================

CONFIG_DIR="$HOME/.config/welcome.sh"
CONFIG_FILE="$CONFIG_DIR/config"
CACHE_DIR="$HOME/.cache/welcome.sh"

# ============================================================
# DISPLAY SETTINGS
# ============================================================

SHOW_FASTFETCH=true
SHOW_WEATHER=true
SHOW_PUBLIC_IP=true
SHOW_PRIVATE_IP=true
SHOW_WIFI=true
SHOW_UPTIME=true
SHOW_DISK_USAGE=true
SHOW_MEMORY=true
SHOW_CPU_TEMP=true
SHOW_TOP_CPU=true
SHOW_ASCII_ART=false
QUIET_MODE=false

# ============================================================
# WEATHER
# ============================================================

WEATHER_LOCATION="Killeen+Texas"
WEATHER_FORMAT="3"

GREETING=""

CACHE_TIMEOUT=3600
REQUEST_TIMEOUT=5

# ============================================================
# CREATE CONFIG
# ============================================================

if [[ ! -f "$CONFIG_FILE" ]]; then

    mkdir -p "$CONFIG_DIR"

    cat > "$CONFIG_FILE" << 'CONF'
# Welcome.sh Configuration

SHOW_FASTFETCH=true
SHOW_WEATHER=true
SHOW_PUBLIC_IP=true
SHOW_PRIVATE_IP=true
SHOW_WIFI=true
SHOW_UPTIME=true
SHOW_DISK_USAGE=true
SHOW_MEMORY=true
SHOW_CPU_TEMP=true
SHOW_TOP_CPU=true
SHOW_ASCII_ART=false
QUIET_MODE=false

WEATHER_LOCATION="Killeen+Texas"
WEATHER_FORMAT="3"

GREETING=""

CACHE_TIMEOUT=3600
REQUEST_TIMEOUT=5
CONF

fi

source "$CONFIG_FILE"

mkdir -p "$CACHE_DIR"

# ============================================================
# COLORS
# ============================================================

CYAN="\033[1;36m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
WHITE="\033[1;37m"
NC="\033[0m"

# ============================================================
# ANIMATION
# ============================================================

SPINNER_FRAMES=(
    "⠋"
    "⠙"
    "⠹"
    "⠸"
    "⠼"
    "⠴"
    "⠦"
    "⠧"
    "⠇"
    "⠏"
)

loading() {

    local message="$1"
    local duration="${2:-1}"

    local i=0
    local end_time

    end_time=$(awk "BEGIN {print systime() + $duration}")

    while [[ "$(awk "BEGIN {print systime() < $end_time}")" == "1" ]]; do

        printf "\r${CYAN}${SPINNER_FRAMES[$i]}${NC} %s..." "$message"

        i=$(( (i + 1) % ${#SPINNER_FRAMES[@]} ))

        sleep 0.08

    done

    printf "\r\033[K"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error_msg() {
    echo -e "${RED}✗ $1${NC}"
}

# ============================================================
# CACHE
# ============================================================

get_cached() {

    local cache_file="$1"
    local max_age="$2"

    if [[ -f "$cache_file" ]]; then

        local timestamp

        timestamp=$(
            stat -c%Y "$cache_file" 2>/dev/null ||
            stat -f%m "$cache_file" 2>/dev/null ||
            echo 0
        )

        local age=$(( $(date +%s) - timestamp ))

        if [[ "$age" -lt "$max_age" ]]; then
            cat "$cache_file"
            return 0
        fi

    fi

    return 1
}

set_cached() {

    local cache_file="$1"
    local data="$2"

    printf "%s\n" "$data" > "$cache_file"
}

# ============================================================
# OS
# ============================================================

OS_TYPE="$(uname -s)"
IS_MACOS=false

[[ "$OS_TYPE" == "Darwin" ]] && IS_MACOS=true

# ============================================================
# UPTIME
# ============================================================

get_uptime() {

    if [[ "$IS_MACOS" == "true" ]]; then

        uptime |
            sed 's/.*up \(.*\), [0-9]* users.*/\1/' |
            sed 's/ *$//' ||
            echo "N/A"

    else

        uptime -p 2>/dev/null || echo "N/A"

    fi
}

# ============================================================
# LOAD
# ============================================================

get_load_average() {

    if [[ "$IS_MACOS" == "true" ]]; then

        uptime |
            awk -F'load averages?:' '{print $2}' |
            sed 's/^ *//' ||
            echo "N/A"

    else

        cut -d' ' -f1-3 /proc/loadavg 2>/dev/null ||
            echo "N/A"

    fi
}

# ============================================================
# CPU TEMPERATURE
# ============================================================

get_temp() {

    if [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then

        local temp

        temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)

        if [[ -n "$temp" && "$temp" != "0" ]]; then

            echo "$((temp / 1000))°C"
            return

        fi

    fi

    if command -v sensors >/dev/null 2>&1; then

        sensors 2>/dev/null |
            grep -i "Package id 0\|Core 0\|temp1" |
            head -n 1 |
            awk '{print $2}' |
            sed 's/+//'

        return

    fi

    echo "N/A"
}

# ============================================================
# TOP CPU
# ============================================================

get_top_cpu() {

    if [[ "$IS_MACOS" == "true" ]]; then

        ps -A -o %cpu=,comm= 2>/dev/null |
            sort -rn |
            head -n1 |
            awk '{printf "%s (%.1f%%)", $2, $1}'

    else

        ps aux --sort=-%cpu 2>/dev/null |
            awk 'NR==2 {
                printf "%s (%.1f%%)", $11, $3
            }'

    fi
}

# ============================================================
# WIFI
# ============================================================

get_wifi_info() {

    local ssid="N/A"
    local signal=""

    if [[ "$IS_MACOS" == "true" ]]; then

        local wifi_data

        wifi_data=$(system_profiler SPAirPortDataType 2>/dev/null)

        ssid=$(
            echo "$wifi_data" |
            awk -F': ' '/Current Network Information:/ {
                getline
                print $1
            }' |
            xargs
        )

    else

        if command -v nmcli >/dev/null 2>&1; then

            ssid=$(
                nmcli -t -f active,ssid dev wifi 2>/dev/null |
                grep '^yes' |
                cut -d: -f2
            )

            local signal_percent

            signal_percent=$(
                nmcli -t -f active,signal dev wifi 2>/dev/null |
                grep '^yes' |
                cut -d: -f2
            )

            [[ -n "$signal_percent" ]] &&
                signal=" (${signal_percent}% signal)"

        elif command -v iwconfig >/dev/null 2>&1; then

            ssid=$(
                iwconfig 2>/dev/null |
                grep 'ESSID:' |
                cut -d'"' -f2
            )

        fi

    fi

    if [[ -n "$ssid" && "$ssid" != "N/A" ]]; then
        echo "${ssid}${signal}"
    else
        echo "Disconnected / Wired"
    fi
}

# ============================================================
# WEATHER
# ============================================================

get_weather() {

    local location="${WEATHER_LOCATION:-Killeen+Texas}"

    # NEVER use New York
    if [[ -z "$location" ||
          "$location" == "New+York" ||
          "$location" == "New York" ]]; then

        location="Killeen+Texas"

    fi

    local format="${WEATHER_FORMAT:-3}"

    local cache_name

    cache_name=$(
        echo "$location" |
        tr '[:upper:]' '[:lower:]' |
        tr -cd '[:alnum:]_-'
    )

    local cache_file="$CACHE_DIR/weather_${cache_name}"

    local weather

    weather=$(get_cached "$cache_file" "$CACHE_TIMEOUT")

    if [[ $? -ne 0 ]]; then

        weather=$(
            curl -fsS \
                --max-time "$REQUEST_TIMEOUT" \
                "https://wttr.in/${location}?format=${format}" \
                2>/dev/null
        )

        if [[ -n "$weather" ]]; then
            set_cached "$cache_file" "$weather"
        else
            weather="Weather unavailable"
        fi

    fi

    echo "$weather"
}

# ============================================================
# ASCII
# ============================================================

if [[ "$SHOW_ASCII_ART" == "true" ]]; then

    echo -e "${CYAN}"

    cat << "EOF"
 ██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗
 ██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝
 ██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗
 ██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝
 ╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗
  ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝╚═╝     ╚═╝╚══════╝
EOF

    echo -e "${NC}"

fi

# ============================================================
# STARTUP
# ============================================================

loading "Starting Welcome.sh" 1

clear

# ============================================================
# FASTFETCH
# ============================================================

if [[ "$SHOW_FASTFETCH" == "true" ]]; then

    if command -v fastfetch >/dev/null 2>&1; then
        fastfetch
    fi

fi

# ============================================================
# MAIN INFORMATION
# ============================================================

echo -e "${CYAN}Hello, $USER!${NC}"

if [[ "$SHOW_UPTIME" == "true" ]]; then

    echo -e "${YELLOW}Uptime: $(get_uptime) | Load Average: $(get_load_average)${NC}"

fi

# ============================================================
# PUBLIC IP
# ============================================================

if [[ "$SHOW_PUBLIC_IP" == "true" ]]; then

    PUBIP_CACHE="$CACHE_DIR/public_ip"

    PUBIP=$(get_cached "$PUBIP_CACHE" "$CACHE_TIMEOUT")

    if [[ $? -ne 0 ]]; then

        PUBIP=$(
            curl -fsS \
                --max-time "$REQUEST_TIMEOUT" \
                ifconfig.me 2>/dev/null ||
                echo "N/A"
        )

        [[ "$PUBIP" != "N/A" ]] &&
            set_cached "$PUBIP_CACHE" "$PUBIP"

    fi

    echo -e "${GREEN}Public IP: $PUBIP${NC}"

fi

# ============================================================
# PRIVATE IP
# ============================================================

if [[ "$SHOW_PRIVATE_IP" == "true" ]]; then

    if [[ "$IS_MACOS" == "true" ]]; then

        IFACE=$(
            route -n get default 2>/dev/null |
            awk '/interface:/{print $2}'
        )

        PRIVIP=$(
            ipconfig getifaddr "$IFACE" 2>/dev/null ||
            echo "N/A"
        )

    else

        PRIVIP=$(
            hostname -I 2>/dev/null |
            awk '{print $1}' ||
            echo "N/A"
        )

    fi

    echo -e "${GREEN}Private IP: $PRIVIP${NC}"

fi

# ============================================================
# WIFI
# ============================================================

if [[ "$SHOW_WIFI" == "true" ]]; then

    WIFI_INFO=$(get_wifi_info)

    echo -e "${GREEN}Wi-Fi Network: $WIFI_INFO${NC}"

fi

# ============================================================
# DISK
# ============================================================

if [[ "$SHOW_DISK_USAGE" == "true" ]]; then

    if [[ "$IS_MACOS" == "true" ]]; then

        df -h 2>/dev/null |
            awk 'NR>1 {
                printf "%s %s %s %s\n",
                $NF,$3,$2,$5
            }' |
            while read -r mount used size percent; do

                echo -e "${CYAN}Disk Usage on ${mount}: ${used} used of ${size} (${percent})${NC}"

            done

    else

        df -h \
            --output=target,used,size,pcent \
            -x tmpfs \
            -x devtmpfs \
            -x squashfs 2>/dev/null |
            awk 'NR>1 {
                printf "Disk Usage on %s: %s used of %s (%s)\n",
                $1,$2,$3,$4
            }' |
            while read -r line; do

                echo -e "${CYAN}${line}${NC}"

            done

    fi

fi

# ============================================================
# MEMORY
# ============================================================

if [[ "$SHOW_MEMORY" == "true" ]]; then

    if command -v free >/dev/null 2>&1; then

        MEM_INFO=$(
            free -b |
            awk 'NR==2 {
                used=$3
                total=$2
                printf "Used: %.2f GiB / %.2f GiB (%.0f%%)",
                used/1073741824,
                total/1073741824,
                (used/total)*100
            }'
        )

        echo -e "${BLUE}Memory: $MEM_INFO${NC}"

    fi

fi

# ============================================================
# TOP CPU
# ============================================================

if [[ "$SHOW_TOP_CPU" == "true" &&
      "$QUIET_MODE" != "true" ]]; then

    TOP_CPU=$(get_top_cpu)

    [[ -n "$TOP_CPU" ]] &&
        echo -e "${MAGENTA}Top CPU: $TOP_CPU${NC}"

fi

# ============================================================
# UPDATES
# ============================================================

if command -v apt >/dev/null 2>&1; then

    UPDATES=$(
        apt list --upgradeable 2>/dev/null |
        grep -v "Listing..." |
        wc -l
    )

    if [[ "$UPDATES" -gt 0 ]]; then
        echo -e "${RED}Updates available: $UPDATES package(s)${NC}"
    else
        echo -e "${GREEN}Your system is up to date.${NC}"
    fi

elif command -v dnf >/dev/null 2>&1; then

    UPDATES=$(
        dnf check-update -q 2>/dev/null |
        grep -v "^$" |
        wc -l
    )

    [[ "$UPDATES" -gt 0 ]] &&
        echo -e "${RED}Updates available: $UPDATES package(s)${NC}" ||
        echo -e "${GREEN}Your system is up to date.${NC}"

elif command -v pacman >/dev/null 2>&1; then

    UPDATES=$(pacman -Qu 2>/dev/null | wc -l)

    [[ "$UPDATES" -gt 0 ]] &&
        echo -e "${RED}Updates available: $UPDATES package(s)${NC}" ||
        echo -e "${GREEN}Your system is up to date.${NC}"

fi

# ============================================================
# REBOOT
# ============================================================

if [[ -f /var/run/reboot-required ]]; then
    echo -e "${RED}⚠️ Reboot required!${NC}"
fi

# ============================================================
# CPU TEMP
# ============================================================

if [[ "$SHOW_CPU_TEMP" == "true" &&
      "$IS_MACOS" != "true" ]]; then

    TEMP=$(get_temp)

    echo -e "${CYAN}CPU Temp: $TEMP${NC}"

fi

# ============================================================
# RASPBERRY PI
# ============================================================

IS_RPI=false

if [[ -f /proc/device-tree/model ]] &&
   grep -qi "raspberry pi" /proc/device-tree/model 2>/dev/null; then

    IS_RPI=true

fi

if [[ "$IS_RPI" == "true" ]] &&
   command -v vcgencmd >/dev/null 2>&1; then

    RAW_OUTPUT=$(vcgencmd get_throttled 2>/dev/null || true)

    if [[ "$RAW_OUTPUT" == throttled=* ]]; then

        THROTTLED_RAW=$(echo "$RAW_OUTPUT" | cut -d= -f2)

        if [[ "$THROTTLED_RAW" != "0x0" ]]; then
            echo -e "${RED}Throttled: Yes ($THROTTLED_RAW)${NC}"
        else
            echo -e "${GREEN}Throttled: No${NC}"
        fi

    fi

fi

# ============================================================
# WEATHER
# ============================================================

if [[ "$SHOW_WEATHER" == "true" ]]; then

    WEATHER=$(get_weather)

    echo -e "${YELLOW}Weather: $WEATHER${NC}"

fi

echo -e "${YELLOW}${GREETING}${NC}"

# ============================================================
# INTERACTIVE MENU
# ============================================================

while true; do

    echo ""

    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              WELCOME.HQ MENU                 ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}1${NC}   System Information                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}2${NC}   Weather                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}3${NC}   Network Information                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}4${NC}   Disk Usage                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}5${NC}   Memory Usage                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}6${NC}   Check for Updates                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}7${NC}   Update System                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}8${NC}   Clear Cache                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}9${NC}   Refresh                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}10${NC}  Process Manager                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}11${NC}  CPU Details                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}12${NC}  Battery                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}13${NC}  System Logs                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}14${NC}  Ping Test                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}15${NC}  DNS Lookup                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}16${NC}  Network Connections                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}17${NC}  Find Large Files                       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}18${NC}  Services                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}19${NC}  Environment                            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}20${NC}  Export System Info                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}21${NC}  Calculator                             ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}22${NC}  Timer                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}23${NC}  Password Generator                     ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}24${NC}  Change Weather Location                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}25${NC}  Reload Configuration                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}26${NC}  About Welcome.sh                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${RED}0${NC}   Exit                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"

    echo ""

    read -rp "Select an option: " choice

    loading "Opening" 0.4

    case "$choice" in

        # ====================================================
        # SYSTEM INFORMATION
        # ====================================================

        1)

            clear

            echo -e "${CYAN}=== SYSTEM INFORMATION ===${NC}"
            echo ""

            if command -v fastfetch >/dev/null 2>&1; then
                fastfetch
            else
                echo "OS: $(uname -s)"
                echo "Kernel: $(uname -r)"
                echo "Architecture: $(uname -m)"
                echo "Hostname: $(hostname)"
            fi

            ;;

        # ====================================================
        # WEATHER
        # ====================================================

        2)

            clear

            echo -e "${CYAN}=== WEATHER ===${NC}"
            echo ""

            loading "Fetching weather" 1

            echo -e "${YELLOW}$(get_weather)${NC}"

            ;;

        # ====================================================
        # NETWORK
        # ====================================================

        3)

            clear

            echo -e "${CYAN}=== NETWORK INFORMATION ===${NC}"
            echo ""

            echo "Hostname: $(hostname)"
            echo ""

            if command -v ip >/dev/null 2>&1; then
                ip -brief addr 2>/dev/null
            fi

            echo ""

            echo "Public IP:"

            curl -fsS \
                --max-time "$REQUEST_TIMEOUT" \
                ifconfig.me 2>/dev/null ||
                echo "N/A"

            ;;

        # ====================================================
        # DISK
        # ====================================================

        4)

            clear

            echo -e "${CYAN}=== DISK USAGE ===${NC}"
            echo ""

            df -h

            ;;

        # ====================================================
        # MEMORY
        # ====================================================

        5)

            clear

            echo -e "${CYAN}=== MEMORY USAGE ===${NC}"
            echo ""

            if command -v free >/dev/null 2>&1; then
                free -h
            else
                echo "Memory information unavailable."
            fi

            ;;

        # ====================================================
        # CHECK UPDATES
        # ====================================================

        6)

            clear

            echo -e "${CYAN}=== CHECK FOR UPDATES ===${NC}"
            echo ""

            if command -v apt >/dev/null 2>&1; then

                sudo apt update

                echo ""

                UPDATES=$(
                    apt list --upgradeable 2>/dev/null |
                    grep -v "Listing..." |
                    wc -l
                )

                if [[ "$UPDATES" -gt 0 ]]; then
                    echo -e "${RED}Updates available: $UPDATES package(s)${NC}"
                else
                    success "Your system is up to date."
                fi

            elif command -v dnf >/dev/null 2>&1; then

                sudo dnf check-update || true

            elif command -v pacman >/dev/null 2>&1; then

                pacman -Qu

            else

                error_msg "No supported package manager found."

            fi

            ;;

        # ====================================================
        # UPDATE SYSTEM
        # ====================================================

        7)

            clear

            echo -e "${CYAN}=== UPDATE SYSTEM ===${NC}"
            echo ""

            if command -v apt >/dev/null 2>&1; then

                echo -e "${YELLOW}Updating package lists...${NC}"

                sudo apt update

                echo ""

                echo -e "${YELLOW}Installing updates...${NC}"

                sudo apt upgrade -y

                echo ""

                success "System update complete."

            elif command -v dnf >/dev/null 2>&1; then

                sudo dnf upgrade -y

                success "System update complete."

            elif command -v yum >/dev/null 2>&1; then

                sudo yum update -y

                success "System update complete."

            elif command -v pacman >/dev/null 2>&1; then

                sudo pacman -Syu --noconfirm

                success "System update complete."

            else

                error_msg "No supported package manager found."

            fi

            ;;

        # ====================================================
        # CLEAR CACHE
        # ====================================================

        8)

            clear

            echo -e "${CYAN}=== CLEAR CACHE ===${NC}"
            echo ""

            loading "Clearing cache" 1

            rm -rf "$CACHE_DIR"

            mkdir -p "$CACHE_DIR"

            success "Cache cleared."

            ;;

        # ====================================================
        # REFRESH
        # ====================================================

        9)

            clear

            loading "Refreshing Welcome.sh" 1

            exec "$0"

            ;;

        # ====================================================
        # PROCESS MANAGER
        # ====================================================

        10)

            clear

            echo -e "${CYAN}=== PROCESS MANAGER ===${NC}"
            echo ""

            ps aux --sort=-%cpu 2>/dev/null |
                head -n 20

            ;;

        # ====================================================
        # CPU DETAILS
        # ====================================================

        11)

            clear

            echo -e "${CYAN}=== CPU DETAILS ===${NC}"
            echo ""

            echo "Architecture: $(uname -m)"
            echo "Load Average: $(get_load_average)"
            echo "Temperature: $(get_temp)"

            if command -v nproc >/dev/null 2>&1; then
                echo "CPU Cores: $(nproc)"
            fi

            if [[ -f /proc/cpuinfo ]]; then

                grep -m1 "model name" /proc/cpuinfo |
                    cut -d: -f2 |
                    sed 's/^ //'

            elif [[ "$IS_MACOS" == "true" ]]; then

                echo "CPU: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
                echo "Cores: $(sysctl -n hw.ncpu 2>/dev/null)"

            fi

            ;;

        # ====================================================
        # BATTERY
        # ====================================================

        12)

            clear

            echo -e "${CYAN}=== BATTERY ===${NC}"
            echo ""

            BATTERY_FOUND=false

            # ------------------------------------------------
            # UPOWER
            # ------------------------------------------------

            if command -v upower >/dev/null 2>&1; then

                BATTERY_DEVICES=$(
                    upower -e 2>/dev/null |
                    grep -Ei 'battery|DisplayDevice'
                )

                if [[ -n "$BATTERY_DEVICES" ]]; then

                    while IFS= read -r DEVICE; do

                        [[ -z "$DEVICE" ]] && continue

                        BATTERY_INFO=$(
                            upower -i "$DEVICE" 2>/dev/null
                        )

                        if echo "$BATTERY_INFO" |
                           grep -qi "percentage:"; then

                            BATTERY_FOUND=true

                            echo "$BATTERY_INFO" |
                                grep -E \
                                "state:|percentage:|energy:|energy-full:|energy-rate:|time to empty:|time to full:"

                            echo ""

                        fi

                    done <<< "$BATTERY_DEVICES"

                fi

            fi

            # ------------------------------------------------
            # LINUX BATTERY
            # ------------------------------------------------

            if [[ "$BATTERY_FOUND" == "false" &&
                  -d /sys/class/power_supply ]]; then

                for battery in /sys/class/power_supply/BAT*; do

                    if [[ -d "$battery" ]]; then

                        BATTERY_FOUND=true

                        echo "Battery: $(basename "$battery")"

                        if [[ -f "$battery/status" ]]; then
                            echo "Status: $(cat "$battery/status")"
                        fi

                        if [[ -f "$battery/capacity" ]]; then
                            echo "Charge: $(cat "$battery/capacity")%"
                        fi

                        if [[ -f "$battery/capacity_level" ]]; then
                            echo "Level: $(cat "$battery/capacity_level")"
                        fi

                        echo ""

                    fi

                done

            fi

            # ------------------------------------------------
            # CHROMEOS / DBUS
            # ------------------------------------------------

            if [[ "$BATTERY_FOUND" == "false" ]] &&
               command -v dbus-send >/dev/null 2>&1; then

                CHROME_BATTERY=$(
                    dbus-send \
                        --system \
                        --print-reply \
                        --dest=org.freedesktop.UPower \
                        /org/freedesktop/UPower/devices/DisplayDevice \
                        org.freedesktop.DBus.Properties.Get \
                        string:org.freedesktop.UPower.Device \
                        string:Percentage \
                        2>/dev/null
                )

                PERCENT=$(
                    echo "$CHROME_BATTERY" |
                    grep -oE '[0-9]+(\.[0-9]+)?' |
                    tail -n1
                )

                if [[ -n "$PERCENT" ]]; then

                    BATTERY_FOUND=true

                    echo -e "${GREEN}Battery: ${PERCENT}%${NC}"

                fi

            fi

            # ------------------------------------------------
            # FINAL RESULT
            # ------------------------------------------------

            if [[ "$BATTERY_FOUND" == "false" ]]; then

                echo -e "${YELLOW}Battery information is not exposed to the Linux container.${NC}"
                echo ""
                echo "ChromeOS is keeping the battery information"
                echo "outside of the Linux environment."

            fi

            ;;

        # ====================================================
        # SYSTEM LOGS
        # ====================================================

        13)

            clear

            echo -e "${CYAN}=== SYSTEM LOGS ===${NC}"
            echo ""

            if command -v journalctl >/dev/null 2>&1; then

                journalctl \
                    -p warning \
                    -n 25 \
                    --no-pager

            else

                echo "journalctl is not available."

            fi

            ;;

        # ====================================================
        # PING
        # ====================================================

        14)

            clear

            echo -e "${CYAN}=== PING TEST ===${NC}"
            echo ""

            read -rp "Host [google.com]: " PING_HOST

            [[ -z "$PING_HOST" ]] &&
                PING_HOST="google.com"

            echo ""

            ping -c 4 "$PING_HOST"

            ;;

        # ====================================================
        # DNS
        # ====================================================

        15)

            clear

            echo -e "${CYAN}=== DNS LOOKUP ===${NC}"
            echo ""

            read -rp "Domain: " DNS_DOMAIN

            if command -v nslookup >/dev/null 2>&1; then

                nslookup "$DNS_DOMAIN"

            elif command -v dig >/dev/null 2>&1; then

                dig "$DNS_DOMAIN"

            elif command -v host >/dev/null 2>&1; then

                host "$DNS_DOMAIN"

            else

                error_msg "No DNS utility installed."

            fi

            ;;

        # ====================================================
        # CONNECTIONS
        # ====================================================

        16)

            clear

            echo -e "${CYAN}=== NETWORK CONNECTIONS ===${NC}"
            echo ""

            if command -v ss >/dev/null 2>&1; then
                ss -tunap 2>/dev/null
            elif command -v netstat >/dev/null 2>&1; then
                netstat -tunap 2>/dev/null
            else
                error_msg "No network utility available."
            fi

            ;;

        # ====================================================
        # LARGE FILES
        # ====================================================

        17)

            clear

            echo -e "${CYAN}=== LARGE FILES ===${NC}"
            echo ""

            echo "Files larger than 50 MB:"
            echo ""

            find "$HOME" \
                -type f \
                -size +50M \
                -exec du -h {} + 2>/dev/null |
                sort -hr |
                head -n 20

            ;;

        # ====================================================
        # SERVICES
        # ====================================================

        18)

            clear

            echo -e "${CYAN}=== RUNNING SERVICES ===${NC}"
            echo ""

            if command -v systemctl >/dev/null 2>&1; then

                systemctl list-units \
                    --type=service \
                    --state=running \
                    --no-pager

            else

                echo "systemctl is not available."

            fi

            ;;

        # ====================================================
        # ENVIRONMENT
        # ====================================================

        19)

            clear

            echo -e "${CYAN}=== ENVIRONMENT ===${NC}"
            echo ""

            echo "User: $USER"
            echo "Home: $HOME"
            echo "Shell: $SHELL"
            echo "Terminal: ${TERM:-N/A}"

            echo ""

            echo "PATH:"
            echo "$PATH" | tr ':' '\n'

            ;;

        # ====================================================
        # EXPORT
        # ====================================================

        20)

            clear

            echo -e "${CYAN}=== EXPORT SYSTEM INFORMATION ===${NC}"
            echo ""

            EXPORT_FILE="$HOME/welcome-system-info-$(date +%Y%m%d-%H%M%S).txt"

            loading "Collecting information" 1

            {
                echo "Welcome.sh System Information"
                echo "================================"
                echo ""
                echo "Date: $(date)"
                echo "User: $USER"
                echo "Hostname: $(hostname)"
                echo "OS: $(uname -s)"
                echo "Kernel: $(uname -r)"
                echo "Architecture: $(uname -m)"
                echo ""
                echo "Uptime:"
                get_uptime
                echo ""
                echo "Load:"
                get_load_average
                echo ""
                echo "CPU:"
                get_top_cpu
                echo ""
                echo "Weather:"
                get_weather
                echo ""
                echo "Disk:"
                df -h
            } > "$EXPORT_FILE"

            success "Information exported."

            echo ""
            echo "Saved to:"
            echo "$EXPORT_FILE"

            ;;

        # ====================================================
        # CALCULATOR
        # ====================================================

        21)

            clear

            echo -e "${CYAN}=== CALCULATOR ===${NC}"
            echo ""
            echo "Type 'exit' to return."
            echo ""

            while true; do

                read -rp "Calculator > " CALC

                [[ "$CALC" == "exit" ]] &&
                    break

                [[ -z "$CALC" ]] &&
                    continue

                if command -v bc >/dev/null 2>&1; then
                    echo "$CALC" | bc -l
                else
                    error_msg "bc is not installed."
                    break
                fi

            done

            ;;

        # ====================================================
        # TIMER
        # ====================================================

        22)

            clear

            echo -e "${CYAN}=== TIMER ===${NC}"
            echo ""

            read -rp "Seconds: " TIMER_SECONDS

            if [[ "$TIMER_SECONDS" =~ ^[0-9]+$ ]]; then

                for ((i=TIMER_SECONDS; i>0; i--)); do

                    printf "\r${YELLOW}⏱ Time remaining: %02d seconds${NC}" "$i"

                    sleep 1

                done

                printf "\r\033[K"

                echo -e "${GREEN}🔔 Timer finished!${NC}"

            else

                error_msg "Invalid number."

            fi

            ;;

        # ====================================================
        # PASSWORD GENERATOR
        # ====================================================

        23)

            clear

            echo -e "${CYAN}=== PASSWORD GENERATOR ===${NC}"
            echo ""

            read -rp "Password length [20]: " PASSWORD_LENGTH

            [[ -z "$PASSWORD_LENGTH" ]] &&
                PASSWORD_LENGTH=20

            if [[ "$PASSWORD_LENGTH" =~ ^[0-9]+$ ]]; then

                if command -v openssl >/dev/null 2>&1; then

                    PASSWORD=$(
                        openssl rand -base64 256 |
                        tr -dc 'A-Za-z0-9!@#$%^&*()_+=' |
                        head -c "$PASSWORD_LENGTH"
                    )

                    echo ""
                    echo -e "${GREEN}Generated password:${NC}"
                    echo "$PASSWORD"

                else

                    error_msg "OpenSSL is not installed."

                fi

            else

                error_msg "Invalid length."

            fi

            ;;

        # ====================================================
        # CHANGE WEATHER
        # ====================================================

        24)

            clear

            echo -e "${CYAN}=== CHANGE WEATHER LOCATION ===${NC}"
            echo ""

            echo "Current location:"
            echo "${WEATHER_LOCATION//+/ }"

            echo ""

            read -rp "New location: " NEW_LOCATION

            if [[ -n "$NEW_LOCATION" ]]; then

                NEW_LOCATION=$(echo "$NEW_LOCATION" | sed 's/ /+/g')

                WEATHER_LOCATION="$NEW_LOCATION"

                if grep -q "^WEATHER_LOCATION=" "$CONFIG_FILE"; then

                    sed -i \
                        "s|^WEATHER_LOCATION=.*|WEATHER_LOCATION=\"$WEATHER_LOCATION\"|" \
                        "$CONFIG_FILE"

                else

                    echo "WEATHER_LOCATION=\"$WEATHER_LOCATION\"" \
                        >> "$CONFIG_FILE"

                fi

                rm -f "$CACHE_DIR"/weather_*

                success "Weather location changed."

                echo ""

                loading "Getting weather" 1

                echo -e "${YELLOW}$(get_weather)${NC}"

            fi

            ;;

        # ====================================================
        # RELOAD
        # ====================================================

        25)

            clear

            loading "Reloading configuration" 1

            if [[ -f "$CONFIG_FILE" ]]; then

                source "$CONFIG_FILE"

                success "Configuration reloaded."

            else

                error_msg "Configuration file not found."

            fi

            ;;

        # ====================================================
        # ABOUT
        # ====================================================

        26)

            clear

            echo -e "${CYAN}"
            echo "╔══════════════════════════════════════════════╗"
            echo "║              WELCOME.SH                     ║"
            echo "╠══════════════════════════════════════════════╣"
            echo "║                                              ║"
            echo "║       Terminal System Dashboard              ║"
            echo "║       Weather + Network + Tools              ║"
            echo "║       Interactive System Menu                ║"
            echo "║                                              ║"
            echo "║       Config:                                ║"
            echo "║       ~/.config/welcome.sh                   ║"
            echo "║                                              ║"
            echo "╚══════════════════════════════════════════════╝"
            echo -e "${NC}"

            ;;

        # ====================================================
        # EXIT
        # ====================================================

        0|q|Q)

            clear

            loading "Closing Welcome.sh" 1

            echo -e "${GREEN}✓ Goodbye, $USER!${NC}"

            exit 0

            ;;

        # ====================================================
        # INVALID
        # ====================================================

        *)

            clear

            error_msg "Invalid option."

            ;;

    esac

    echo ""

    read -rp "Press Enter to return to the menu..."

    clear

done
