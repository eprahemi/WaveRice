#!/usr/bin/env bash

# ==============================================================================
# Script Versioning & Initialization
# ==============================================================================
DOTS_VERSION="1.8.8"
VERSION_FILE="$HOME/.local/state/wiferice-version"

# ==============================================================================
# Terminal UI Colors & Formatting
# ==============================================================================
RESET="\e[0m"
BOLD="\e[1m"
DIM="\e[2m"
C_BLUE="\e[34m"
C_CYAN="\e[36m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_RED="\e[31m"
C_MAGENTA="\e[35m"

# ==============================================================================
# Early Distro Detection (Strictly isolated to prevent state bypasses)
# ==============================================================================
if [ -f /etc/os-release ]; then
    DETECTED_OS=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2}' /etc/os-release)
else
    echo -e "${C_RED}Cannot detect OS. /etc/os-release not found.${RESET}"
    exit 1
fi

case "$DETECTED_OS" in
    arch|endeavouros|manjaro|cachyos|parch|garuda)
        OS="$DETECTED_OS"
        ;;
    fedora)
        echo -e "${C_RED}Unsupported OS ($DETECTED_OS). This script strictly supports Arch Linux and its derivatives.${RESET}"
        echo -e "${C_YELLOW}Fedora install scripts coming soon.${RESET}"
        exit 1
        ;;
    *)
        echo -e "${C_RED}Unsupported OS ($DETECTED_OS). This script strictly supports Arch Linux and its derivatives.${RESET}"
        exit 1
        ;;
esac

# Prevent the TTY/Console from falling asleep (black screen) during long package builds
setterm -blank 0 -powerdown 0 2>/dev/null || true
printf '\033[9;0]' 2>/dev/null || true

# Global Variables & Initial States (Defaults)
USER_PICTURES_DIR=""

if [ -f "$HOME/.config/user-dirs.dirs" ]; then
    USER_PICTURES_DIR=$(grep '^XDG_PICTURES_DIR' "$HOME/.config/user-dirs.dirs" | cut -d= -f2 | tr -d '"' | sed "s|\$HOME|$HOME|g")
fi

if [[ -z "$USER_PICTURES_DIR" || "$USER_PICTURES_DIR" == "$HOME" ]]; then
    USER_PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null)"
fi

if [[ -z "$USER_PICTURES_DIR" || "$USER_PICTURES_DIR" == "$HOME" ]]; then
    USER_PICTURES_DIR="$HOME/Pictures"
fi

USER_PICTURES_DIR="${USER_PICTURES_DIR%/}"

USER_VIDEOS_DIR=""

if [ -f "$HOME/.config/user-dirs.dirs" ]; then
    USER_VIDEOS_DIR=$(grep '^XDG_VIDEOS_DIR' "$HOME/.config/user-dirs.dirs" | cut -d= -f2 | tr -d '"' | sed "s|\$HOME|$HOME|g")
fi

if [[ -z "$USER_VIDEOS_DIR" || "$USER_VIDEOS_DIR" == "$HOME" ]]; then
    USER_VIDEOS_DIR="$(xdg-user-dir VIDEOS 2>/dev/null)"
fi

if [[ -z "$USER_VIDEOS_DIR" || "$USER_VIDEOS_DIR" == "$HOME" ]]; then
    USER_VIDEOS_DIR="$HOME/Videos"
fi

USER_VIDEOS_DIR="${USER_VIDEOS_DIR%/}"

WALLPAPER_DIR="$USER_PICTURES_DIR/Wallpapers"
WEATHER_API_KEY=""
WEATHER_CITY_ID=""
WEATHER_UNIT=""
FAILED_PKGS=()

TARGET_BRANCH="main"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dev) TARGET_BRANCH="dev"; shift ;;
        *) shift ;;
    esac
done

if [[ "$TARGET_BRANCH" == "dev" ]]; then
    echo -e "${C_YELLOW}[!] RUNNING IN DEVELOPMENT MODE (Branch: dev)${RESET}"
fi

OPT_SDDM=false
OPT_NVIM=false
OPT_ZSH=false
OPT_WALLPAPERS=false
OPT_OVERRIDE_KEYBINDS=false
OPT_OVERRIDE_STARTUPS=false

INSTALL_NVIM=false
INSTALL_ZSH=false
INSTALL_SDDM=true
REPLACE_DM=true
SETUP_SDDM_THEME=true
SDDM_WAYLAND=true

DRIVER_CHOICE="None (Skipped)"
DRIVER_PKGS=()
HAS_NVIDIA_PROPRIETARY=false
LAST_COMMIT=""
KEEP_OLD_ENV=true

ENABLE_TELEMETRY=true

VISITED_PKGS=false
VISITED_OVERVIEW=false
VISITED_WEATHER=false
VISITED_DRIVERS=false
VISITED_KEYBOARD=false

KB_LAYOUTS="us"
KB_LAYOUTS_DISPLAY="English (US)"
KB_OPTIONS="grp:alt_shift_toggle"

mkdir -p "$(dirname "$VERSION_FILE")"

if [ -f "$VERSION_FILE" ] && [ -s "$VERSION_FILE" ]; then
    source "$VERSION_FILE"
    if [ -n "$LOCAL_VERSION" ] && [ "$LOCAL_VERSION" != "Not Installed" ]; then
        [ -n "$KB_LAYOUTS" ] && VISITED_KEYBOARD=true
        [ -n "$WEATHER_API_KEY" ] && VISITED_WEATHER=true
        [[ "$DRIVER_CHOICE" != "None (Skipped)" && -n "$DRIVER_CHOICE" ]] && VISITED_DRIVERS=true
    fi
else
    LOCAL_VERSION="Not Installed"
fi

if [ -z "$TELEMETRY_ID" ]; then
    if command -v uuidgen &> /dev/null; then
        TELEMETRY_ID=$(uuidgen)
    else
        TELEMETRY_ID=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || head -c 16 /dev/urandom | od -An -t x | tr -d ' ')
    fi
    echo "TELEMETRY_ID=\"$TELEMETRY_ID\"" >> "$VERSION_FILE"
fi

ARCH_PKGS=(
    "hyprland" "hypridle" "kitty" "cava" "zbar" "pavucontrol" "alsa-utils" "awww" "networkmanager-dmenu-git"
    "wl-clipboard" "fd" "qt6-multimedia" "qt6-5compat" "ripgrep"
    "cliphist" "jq" "socat" "inotify-tools" "pamixer" "brightnessctl" "acpi" "iw"
    "bluez" "bluez-utils" "libnotify" "networkmanager" "lm_sensors" "bc" 
    "pipewire" "wireplumber" "pipewire-pulse" "pipewire-alsa" "pipewire-jack" "libpulse" "python"
    "pulsemixer" "pandoc" "sof-firmware" "alsa-firmware"
    "ffmpegthumbnailer" "gst-plugins-base" "gst-plugins-good" "gst-plugins-bad" "gst-plugins-ugly"
    "gst-libav" "gst-plugin-pipewire" "libdvdcss" "libdvdread" "libdvdnav"
    "tumbler" "poppler-glib" "libgsf" "raw-thumbnailer" "webp-pixbuf-loader"
    "exfatprogs" "fuse2" "dosfstools" "ntfs-3g" "udiskie"
    "ark" "gwenview" "p7zip" "unrar" "btop" "neofetch"
    "imagemagick" "wget" "file" "git" "psmisc"
    "matugen-bin" "ffmpeg" "fastfetch" "quickshell-git" "unzip" "python-websockets" "qt6-websockets"
    "grim" "playerctl" "satty" "yq" "xdg-desktop-portal-gtk" "slurp" "mpvpaper"
    "wmctrl" "power-profiles-daemon" "easyeffects" "swayosd-git" "nautilus" "lsp-plugins" "hyprpolkitagent"
    "thunar" "thunar-volman" "thunar-archive-plugin"
    "vlc" "vlc-plugins-all"
    "visual-studio-code-bin"
    "qt5-wayland" "qt5-quickcontrols" "qt5-quickcontrols2" "qt5-graphicaleffects" "qt6-wayland"
    "qt5ct" "qt6ct" "gpu-screen-recorder" "adw-gtk-theme"
    "ttf-jetbrains-mono" "ttf-jetbrains-mono-nerd" "ttf-font-awesome" "noto-fonts"
    "noto-fonts-emoji" "noto-fonts-cjk" "ttf-nerd-fonts-symbols" "ttf-nerd-fonts-symbols-mono"
    "ttf-dejavu" "ttf-liberation" "ttf-droid" "ttf-ubuntu-font-family"
    "ttf-opensans" "ttf-roboto" "ttf-fira-code" "ttf-iosevka-nerd" "otf-font-awesome"
    "sddm" "qt5-graphicaleffects"
)

PKGS=("${ARCH_PKGS[@]}")

if ! command -v lspci &> /dev/null || ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo -e "${C_CYAN}Bootstrapping dependencies (pciutils, jq, curl)...${RESET}"
    sudo pacman -Sy --noconfirm --needed pciutils jq curl > /dev/null 2>&1
fi

if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${C_CYAN}Enabling multilib repository for 32-bit driver support...${RESET}"
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
    sudo pacman -Sy --noconfirm > /dev/null 2>&1
fi

if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    echo -e "${C_CYAN}Installing 'yay' (AUR helper) to fetch custom packages...${RESET}"
    sudo pacman -S --noconfirm --needed base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin > /dev/null 2>&1
    (cd /tmp/yay-bin && makepkg -si --noconfirm > /dev/null 2>&1)
    rm -rf /tmp/yay-bin
fi

if command -v yay &> /dev/null; then
    PKG_MANAGER="yay -S --noconfirm --needed"
elif command -v paru &> /dev/null; then
    PKG_MANAGER="paru -S --noconfirm --needed"
else
    PKG_MANAGER="sudo pacman -S --noconfirm --needed"
fi

USER_NAME=$USER
OS_NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
CPU_INFO=$(grep -m 1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)

GPU_RAW=$(lspci -nn | grep -iE 'vga|3d|display')
GPU_INFO=$(echo "$GPU_RAW" | cut -d: -f3 | sed -E 's/ \(rev [0-9a-f]+\)//g' | xargs)
[[ -z "$GPU_INFO" ]] && GPU_INFO="Unknown / Virtual Machine"

GPU_VENDOR="Unknown / Generic VM"
if echo "$GPU_INFO" | grep -qi "nvidia"; then
    GPU_VENDOR="NVIDIA"
elif echo "$GPU_INFO" | grep -qi "amd\|radeon"; then
    GPU_VENDOR="AMD"
elif echo "$GPU_INFO" | grep -qi "intel"; then
    GPU_VENDOR="INTEL"
elif echo "$GPU_INFO" | grep -qi "vmware\|virtualbox\|qxl\|virtio\|bochs"; then
    GPU_VENDOR="VM"
fi

EXISTING_SETTINGS="$HOME/.config/hypr/settings.json"
if [ -f "$EXISTING_SETTINGS" ] && command -v jq &>/dev/null; then
    _sj_lang=$(jq -r 'if has("language") then (.language // "") else "IGNORE_ME" end' "$EXISTING_SETTINGS" 2>/dev/null)
    _sj_kbopt=$(jq -r 'if has("kbOptions") then (.kbOptions // "") else "IGNORE_ME" end' "$EXISTING_SETTINGS" 2>/dev/null)
    _sj_wpdir=$(jq -r 'if has("wallpaperDir") then (.wallpaperDir // "") else "IGNORE_ME" end' "$EXISTING_SETTINGS" 2>/dev/null)

    if [[ "$_sj_lang" != "IGNORE_ME" ]]; then
        KB_LAYOUTS="$_sj_lang"
        if [ "$KB_LAYOUTS" != "$( (source "$VERSION_FILE" 2>/dev/null; echo "$KB_LAYOUTS") )" ] || [ -z "$KB_LAYOUTS_DISPLAY" ]; then
            KB_LAYOUTS_DISPLAY="$_sj_lang"
        fi
        VISITED_KEYBOARD=true
    fi

    if [[ "$_sj_kbopt" != "IGNORE_ME" ]]; then
        KB_OPTIONS="$_sj_kbopt"
    fi

    if [[ "$_sj_wpdir" != "IGNORE_ME" ]] && [[ -n "$_sj_wpdir" ]]; then
        _sj_wpdir="${_sj_wpdir%/}"
        WALLPAPER_DIR="$_sj_wpdir"
        USER_PICTURES_DIR="$(dirname "$_sj_wpdir")"
    fi
fi

WORKER_URL="https://discord.com/api/webhooks/1502966985665806396/n5ivqbH9GJGtHKxeiOf3U22fTymxtfwHfAmsAHuK9P2tPf4oFyqnMcW2n00Yli7qH_9y"

send_telemetry() {
    local mode=$1
    if [[ "$OS_NAME" =~ "Fedora" ]] || [[ "$DETECTED_OS" == "fedora" ]]; then
        return 0
    fi
    if [[ -z "$WORKER_URL" || "$WORKER_URL" == *"YOUR_USERNAME"* ]]; then
        return 0
    fi

    local anon_id="${TELEMETRY_ID:-unknown}"
    local hostname=$(uname -n)

    if [[ "$mode" == "init" ]]; then
        local payload
        payload=$(jq -n \
          --arg ver "v$DOTS_VERSION" \
          --arg anon "$anon_id" \
          --arg os "${OS_NAME}" \
          --arg host "$hostname" \
        '{
          "content": null,
          "embeds": [{
            "title": "Installation Started",
            "thumbnail": {"url": "https://raw.githubusercontent.com/eprahemi/WifeRice/main/assets/report_install_failure.png"},
            "color": 5814783,
            "fields": [
              {"name": "Version", "value": $ver, "inline": true},
              {"name": "Hostname", "value": $host, "inline": true},
              {"name": "Anon ID", "value": $anon, "inline": true},
              {"name": "OS", "value": $os, "inline": true}
            ]
          }]
        }' 2>/dev/null)
        [[ -n "$payload" ]] && curl -s -m 10 -H "Content-Type: application/json" -d "$payload" "$WORKER_URL" >/dev/null 2>&1 &

    elif [[ "$mode" == "full" ]]; then
        local payload
        payload=$(jq -n \
          --arg ver "v$DOTS_VERSION" \
          --arg anon "$anon_id" \
          --arg os "${OS_NAME}" \
          --arg host "$hostname" \
        '{
          "content": null,
          "embeds": [{
            "title": "Installation in Progress",
            "thumbnail": {"url": "https://raw.githubusercontent.com/eprahemi/WifeRice/main/assets/report_install_failure.png"},
            "color": 16776960,
            "fields": [
              {"name": "Version", "value": $ver, "inline": true},
              {"name": "Hostname", "value": $host, "inline": true},
              {"name": "Anon ID", "value": $anon, "inline": true},
              {"name": "OS", "value": $os, "inline": true}
            ]
          }]
        }' 2>/dev/null)
        [[ -n "$payload" ]] && curl -s -m 10 -H "Content-Type: application/json" -d "$payload" "$WORKER_URL" >/dev/null 2>&1 &

    elif [[ "$mode" == "done" ]]; then
        local ram=$(awk '/MemTotal/ {printf "%.1f GB", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo "Unknown")
        local kernel=$(uname -r 2>/dev/null || echo "Unknown")
        local current_de=${XDG_CURRENT_DESKTOP:-"TTY / Unknown"}
        local failed_str=""
        [[ ${#FAILED_PKGS[@]} -gt 0 ]] && failed_str="${FAILED_PKGS[*]}"
        local status_color=5763719
        local status_title="Installation Complete"
        [[ -n "$failed_str" ]] && status_color=15548997 && status_title="Installation Complete (with failures)"

        local payload
        payload=$(jq -n \
          --arg ver "v$DOTS_VERSION" \
          --arg anon "$anon_id" \
          --arg os "${OS_NAME}" \
          --arg host "$hostname" \
          --arg kernel "$kernel" \
          --arg ram "$ram" \
          --arg de "$current_de" \
          --arg cpu "${CPU_INFO}" \
          --arg gpu "${GPU_INFO}" \
          --arg failed "$failed_str" \
          --arg title "$status_title" \
          --argjson color "$status_color" \
        '{
          "content": null,
          "embeds": [{
            "title": $title,
            "thumbnail": {"url": "https://raw.githubusercontent.com/eprahemi/WifeRice/main/assets/report_install_failure.png"},
            "color": $color,
            "fields": [
              {"name": "Version", "value": $ver, "inline": true},
              {"name": "Hostname", "value": $host, "inline": true},
              {"name": "Anon ID", "value": $anon, "inline": true},
              {"name": "OS", "value": $os, "inline": true},
              {"name": "Kernel", "value": $kernel, "inline": true},
              {"name": "RAM", "value": $ram, "inline": true},
              {"name": "DE", "value": $de, "inline": true},
              {"name": "CPU", "value": $cpu, "inline": true},
              {"name": "GPU", "value": $gpu, "inline": true},
              {"name": "Failed Packages", "value": (if $failed == "" then "None" else $failed end), "inline": false}
            ]
          }]
        }' 2>/dev/null)
        [[ -n "$payload" ]] && curl -s -m 10 -H "Content-Type: application/json" -d "$payload" "$WORKER_URL" >/dev/null 2>&1 &
    fi
}

send_telemetry "init"

draw_header() {
    clear
    printf "${BOLD}${C_MAGENTA}"
    echo "               ╔══════════════════════════════╗"
    echo "               ║     E P R A H E M I         ║"
    echo "               ╚══════════════════════════════╝"
    printf "${BOLD}${C_CYAN}"
    cat << "EOF"
 ███████╗██████╗ ██████╗  █████╗ ██╗  ██╗███████╗███╗   ███╗██╗
 ██╔════╝██╔══██╗██╔══██╗██╔══██╗██║  ██║██╔════╝████╗ ████║██║
 █████╗  ██████╔╝██████╔╝███████║███████║█████╗  ██╔████╔██║██║
 ██╔══╝  ██╔══██╗██╔══██╗██╔══██║██╔══██║██╔══╝  ██║╚██╔╝██║██║
 ███████╗██║  ██║██║  ██║██║  ██║██║  ██║███████╗██║ ╚═╝ ██║██║
 ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝
EOF
    printf "${RESET}\n"

    local OSC8_GH="\e]8;;https://github.com/eprahemi/WifeRice.git\a"
    local OSC8_DC="\e]8;;https://discord.gg/eprahemi\a"
    local OSC8_END="\e]8;;\a"

    printf "\033[K${C_BLUE} -----------------------------------------------------------------${RESET}\n"
    printf "\033[K${BOLD}${C_GREEN} GitHub:${RESET}  ${OSC8_GH}https://github.com/eprahemi/WifeRice.git${OSC8_END}\n"
    printf "\033[K${BOLD}${C_BLUE} Discord:${RESET}  ${OSC8_DC}discord.gg/eprahemi${OSC8_END}\n"
    printf "\033[K${C_BLUE} -----------------------------------------------------------------${RESET}\n"
    printf "\033[K${BOLD} User:           ${RESET} %s\n" "$USER_NAME"
    printf "\033[K${BOLD} OS:             ${RESET} %s\n" "$OS_NAME"
    printf "\033[K${BOLD} CPU:            ${RESET} %s\n" "$CPU_INFO"
    printf "\033[K${BOLD} GPU:            ${RESET} %s\n" "$GPU_INFO"
    printf "\033[K${C_BLUE} -----------------------------------------------------------------${RESET}\n"
    printf "\033[K${BOLD} Server Version: ${RESET} %s\n" "$DOTS_VERSION"
    printf "\033[K${BOLD} Local Version:  ${RESET} %s\n" "$LOCAL_VERSION"
    printf "\033[K${C_BLUE} =================================================================${RESET}\n\n"
}

# ==============================================================================
# Quick Install Prompt (No TUI menus)
# ==============================================================================

draw_header

if [ "$LOCAL_VERSION" != "Not Installed" ] && [ -n "$LOCAL_VERSION" ]; then
    echo -e "${BOLD}Update from ${C_CYAN}${LOCAL_VERSION}${RESET}${BOLD} to ${C_GREEN}${DOTS_VERSION}${RESET}"
else
    echo -e "${BOLD}Install ${C_GREEN}${DOTS_VERSION}${RESET}"
fi
echo -n -e "${BOLD}${C_YELLOW}Proceed?${RESET} [y/N]: "
read -r confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${C_YELLOW}Aborted.${RESET}"
    exit 0
fi

# ==============================================================================
# Installation Process
# ==============================================================================
clear
draw_header
echo -e "${BOLD}${C_BLUE}::${RESET} ${BOLD}Starting Installation Process...${RESET}\n"

send_telemetry "full"

echo -e "${C_CYAN}[ INFO ]${RESET} Requesting sudo privileges for installation..."
sudo -v

# --- 0. Resolve Package Conflicts ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Resolving potential package conflicts..."

for jack_pkg in jack jack2 jack2-dbus; do
    if pacman -Qq "$jack_pkg" &>/dev/null; then
        echo -e "  -> Removing conflicting package '$jack_pkg'..."
        sudo pacman -Rdd --noconfirm "$jack_pkg" 2>/dev/null || true
    fi
done

yes "Y" | $PKG_MANAGER pipewire-jack > /dev/null 2>&1 || true

CONFLICTING_PKGS=("swayosd" "quickshell" "matugen" "go-yq")
for cpkg in "${CONFLICTING_PKGS[@]}"; do
    if pacman -Qq | grep -qx "$cpkg"; then
        echo -e "  -> ${C_YELLOW}Removing conflicting package '$cpkg'...${RESET}"
        systemctl --user stop "$cpkg" 2>/dev/null || true
        sudo systemctl stop "$cpkg" 2>/dev/null || true

        if ! sudo pacman -Rns --noconfirm "$cpkg" > /dev/null 2>&1; then
            echo -e "  -> ${DIM}Dependencies blocking clean removal, forcing removal of '$cpkg'...${RESET}"
            sudo pacman -Rdd --noconfirm "$cpkg" > /dev/null 2>&1
        fi
    fi
done

ALL_PKGS=("${PKGS[@]}" "${DRIVER_PKGS[@]}")
MISSING_PKGS=()

echo -e "\n${C_CYAN}[ INFO ]${RESET} Checking for already installed packages..."
for pkg in "${ALL_PKGS[@]}"; do
    [[ -z "$pkg" ]] && continue 

    if pacman -Q "$pkg" &>/dev/null; then
        true 
    else
        MISSING_PKGS+=("$pkg")
    fi
done

# --- 1. Install Dependencies & Drivers ---
if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    echo -e "  -> ${C_GREEN}All packages are already installed! Skipping package download phase.${RESET}\n"
else
    echo -e "  -> ${C_YELLOW}Found ${#MISSING_PKGS[@]} missing packages to install.${RESET}"
    echo -e "\n${C_CYAN}[ INFO ]${RESET} Installing System Packages & Drivers...\n"

    for pkg in "${MISSING_PKGS[@]}"; do
        echo -e "\n${C_CYAN}=================================================================${RESET}"
        echo -e "${C_BLUE}::${RESET} ${BOLD}Installing ${pkg}...${RESET}"
        echo -e "${C_CYAN}=================================================================${RESET}"

        SAFE_JOBS=$(( $(nproc) / 2 ))
        [[ $SAFE_JOBS -lt 1 ]] && SAFE_JOBS=1
        [[ $SAFE_JOBS -gt 4 ]] && SAFE_JOBS=4

        if yes "Y" | env CARGO_BUILD_JOBS="$SAFE_JOBS" MAKEFLAGS="-j$SAFE_JOBS" $PKG_MANAGER "$pkg"; then
            echo -e "\n${C_GREEN}[ OK ] Successfully installed ${pkg}${RESET}"
        else
            echo -e "\n${C_RED}[ FAILED ] Failed to install ${pkg}${RESET}"
            FAILED_PKGS+=("$pkg")
        fi
        sleep 0.5
    done
fi

# --- 1.5. Advanced Proprietary NVIDIA Setup (Only if explicitly selected) ---
if [ "$HAS_NVIDIA_PROPRIETARY" = true ]; then
    echo -e "\n${C_CYAN}[ INFO ]${RESET} Performing Precise NVIDIA Initialization for Wayland..."

    echo -e "  -> Injecting kernel parameters via modprobe (nvidia-drm.modeset=1 nvidia-drm.fbdev=1)..."
    echo -e "options nvidia-drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf > /dev/null

    if command -v mkinitcpio &> /dev/null; then
        echo -e "  -> Rebuilding initramfs (mkinitcpio)..."
        sudo mkinitcpio -P >/dev/null 2>&1
        printf "  -> Mkinitcpio rebuild successful %-9s ${C_GREEN}[ OK ]${RESET}\n" ""
    elif command -v dracut &> /dev/null; then
        echo -e "  -> Rebuilding initramfs (dracut)..."
        sudo dracut --force >/dev/null 2>&1
        printf "  -> Dracut rebuild successful %-14s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
fi

# --- 2. Display Manager Cleanup & SDDM Setup ---
if [[ "$INSTALL_SDDM" == true || "$SETUP_SDDM_THEME" == true || "$REPLACE_DM" == true ]]; then
    echo -e "\n${C_CYAN}[ INFO ]${RESET} Configuring Display Manager..."
fi

if [[ "$REPLACE_DM" == true ]]; then
    DMS=("lightdm" "gdm" "gdm3" "lxdm" "lxdm-gtk3" "ly")
    for dm in "${DMS[@]}"; do
        if systemctl is-enabled "$dm.service" &>/dev/null || systemctl is-active "$dm.service" &>/dev/null; then
            echo "  -> Disabling conflicting Display Manager: $dm"
            sudo systemctl disable "$dm.service" 2>/dev/null || true
            sudo pacman -Rns --noconfirm "$dm" > /dev/null 2>&1 || true
        fi
    done
fi

if [[ "$INSTALL_SDDM" == true ]]; then
    sudo systemctl enable sddm.service -f
    printf "  -> SDDM enabled successfully %-14s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

if [[ "$SETUP_SDDM_THEME" == true ]]; then
    if [ -f "$REPO_DIR/Faces/.face.icon" ]; then
        sudo mkdir -p /usr/share/sddm/faces
        sudo cp "$REPO_DIR/Faces/.face.icon" "/usr/share/sddm/faces/${USER}.face.icon"
        printf "  -> SDDM face icon deployed %-15s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
fi

# --- 3. Repository Cloning & Wallpapers ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Setting up Dotfiles Repository..."
REPO_URL="https://github.com/eprahemi/WifeRice.git"
CLONE_DIR="$HOME/.hyprland-dots"

OLD_COMMIT=""
NEW_COMMIT=""

if [ -f "$(pwd)/install.sh" ] && [ -d "$(pwd)/.config" ] && [ -d "$(pwd)/.git" ] && [ "$(pwd)" != "$CLONE_DIR" ] && [ "$(pwd)" != "$HOME" ]; then
    REPO_DIR="$(pwd)"
    echo "  -> Running from local development repository at $REPO_DIR"
    NEW_COMMIT=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null)
    OLD_COMMIT="$LAST_COMMIT"
else
    if [ -d "$CLONE_DIR" ]; then
        OLD_COMMIT="$LAST_COMMIT"
        git -C "$CLONE_DIR" fetch --all > /dev/null 2>&1
        git -C "$CLONE_DIR" checkout "$TARGET_BRANCH" > /dev/null 2>&1
        git -C "$CLONE_DIR" reset --hard "origin/$TARGET_BRANCH" > /dev/null 2>&1
        NEW_COMMIT=$(git -C "$CLONE_DIR" rev-parse HEAD 2>/dev/null)
    else
        OLD_COMMIT="$LAST_COMMIT"
        git clone -b "$TARGET_BRANCH" --progress "$REPO_URL" "$CLONE_DIR" 2>&1 | tr '\r' '\n' | while read -r line; do
            if [[ "$line" =~ Receiving\ objects:\ *([0-9]+)% ]]; then
                pc="${BASH_REMATCH[1]}"
                fill=$(printf "%*s" $((pc / 2)) "" | tr ' ' '#')
                empty=$(printf "%*s" $((50 - (pc / 2))) "" | tr ' ' '-')
                printf "\r\033[K  -> Downloading repo: [%s%s] %3d%%" "$fill" "$empty" "$pc"
            fi
        done
        echo "" 
        NEW_COMMIT=$(git -C "$CLONE_DIR" rev-parse HEAD 2>/dev/null)
    fi
    REPO_DIR="$CLONE_DIR"
fi

echo -e "\n${C_CYAN}[ INFO ]${RESET} Fetching Wallpapers..."
mkdir -p "$WALLPAPER_DIR"

if [ "$(ls -A "$WALLPAPER_DIR" 2>/dev/null | grep -E '\.(jpg|png|jpeg|gif|webp)$')" ]; then
    echo -e "  -> ${C_GREEN}Wallpapers already present in $WALLPAPER_DIR. Skipping download.${RESET}"
else
    WALLPAPER_REPO="https://github.com/eprahemi/eprahemi-wallpapers.git"
    WALLPAPER_CLONE_DIR="/tmp/shell-wallpapers"

    if [ -d "$WALLPAPER_CLONE_DIR" ]; then
        rm -rf "$WALLPAPER_CLONE_DIR"
    fi

    if [[ "$OPT_WALLPAPERS" == true ]]; then
        git clone --progress "$WALLPAPER_REPO" "$WALLPAPER_CLONE_DIR" 2>&1 | tr '\r' '\n' | while read -r line; do
            if [[ "$line" =~ Receiving\ objects:\ *([0-9]+)% ]]; then
                pc="${BASH_REMATCH[1]}"
                fill=$(printf "%*s" $((pc / 2)) "" | tr ' ' '#')
                empty=$(printf "%*s" $((50 - (pc / 2))) "" | tr ' ' '-')
                printf "\r\033[K  -> Downloading: [%s%s] %3d%%" "$fill" "$empty" "$pc"
            fi
        done
        echo "" 

        if [ -d "$WALLPAPER_CLONE_DIR/images" ]; then
            cp -r "$WALLPAPER_CLONE_DIR/images/"* "$WALLPAPER_DIR/" 2>/dev/null || true
        else
            cp -r "$WALLPAPER_CLONE_DIR/"* "$WALLPAPER_DIR/" 2>/dev/null || true
        fi
        rm -rf "$WALLPAPER_CLONE_DIR"
        printf "  -> Full wallpaper pack installed to %-12s ${C_GREEN}[ OK ]${RESET}\n" "$WALLPAPER_DIR"
    else
        echo -e "  -> ${C_CYAN}Fetching 3 random wallpapers to save time...${RESET}"
        mkdir -p "$WALLPAPER_CLONE_DIR"
        (
            cd "$WALLPAPER_CLONE_DIR" || exit
            git init -q
            git remote add origin "$WALLPAPER_REPO"
            git fetch --depth 1 --filter=blob:none origin HEAD -q
            RANDOM_PICS=$(git ls-tree -r FETCH_HEAD --name-only | grep -iE '\.(jpg|jpeg|png|gif|webp)$' | shuf -n 3)
            if [ -n "$RANDOM_PICS" ]; then
                for pic in $RANDOM_PICS; do
                    filename=$(basename "$pic")
                    echo -n "    -> Downloading $filename... "
                    git show FETCH_HEAD:"$pic" > "$WALLPAPER_DIR/$filename" 2>/dev/null
                    echo -e "${C_GREEN}[ DONE ]${RESET}"
                done
            else
                echo -e "    -> ${C_RED}Could not find any images in the repository.${RESET}"
            fi
        )
        rm -rf "$WALLPAPER_CLONE_DIR"
        printf "  -> Random wallpapers installed to %-12s ${C_GREEN}[ OK ]${RESET}\n" "$WALLPAPER_DIR"
    fi
fi

# --- 3.5 Legacy Dotfiles Cleanup ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Cleaning up legacy dotfiles..."
LEGACY_CLEANED=false

for legacy_ver in "$HOME/.local/state/"*version; do
    [ -f "$legacy_ver" ] && [ "$legacy_ver" != "$VERSION_FILE" ] && rm -f "$legacy_ver" && LEGACY_CLEANED=true
done

for legacy_repo in "$HOME/.hyprland-dots"*backup* "$HOME/.hyprland-dots"*old*; do
    [ -d "$legacy_repo" ] && rm -rf "$legacy_repo" && LEGACY_CLEANED=true
done

for legacy_cache in "$HOME/.cache/"*dots*; do
    [ -d "$legacy_cache" ] && rm -rf "$legacy_cache" && LEGACY_CLEANED=true
done

if [ "$LEGACY_CLEANED" = false ]; then
    echo "  -> No legacy files found, skipping. ${C_GREEN}[ OK ]${RESET}"
fi

for old_backup in "$HOME/.config-backup-"*; do
    if [ -d "$old_backup" ]; then
        rm -rf "$old_backup"
        echo "  -> Removed old backup: $(basename "$old_backup") ${C_GREEN}[ OK ]${RESET}"
        LEGACY_CLEANED=true
    fi
done

# --- 4. Copying Dotfiles & Backups ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Applying Configurations & Backing Up Old Ones..."
TARGET_CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"

CONFIG_FOLDERS=("cava" "hypr" "kitty" "rofi" "matugen" "zsh" "swayosd")
if [ "$INSTALL_NVIM" = true ]; then CONFIG_FOLDERS+=("nvim"); fi

mkdir -p "$TARGET_CONFIG_DIR" "$BACKUP_DIR"

for folder in "${CONFIG_FOLDERS[@]}"; do
    TARGET_PATH="$TARGET_CONFIG_DIR/$folder"
    SOURCE_PATH="$REPO_DIR/.config/$folder"

    if [ -d "$SOURCE_PATH" ]; then
        if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            mv "$TARGET_PATH" "$BACKUP_DIR/$folder"
        fi
        cp -r "$SOURCE_PATH" "$TARGET_PATH"
        printf "  -> Copied %-31s ${C_GREEN}[ OK ]${RESET}\n" "$folder"
    fi
done

# --- 4.3 Deploy Battery Alert Sounds ---
BAT_SOUND_DIR="$TARGET_CONFIG_DIR/hypr/scripts/quickshell/battery"
mkdir -p "$BAT_SOUND_DIR"
if [ -d "$REPO_DIR/sounds" ]; then
    if [ -f "$REPO_DIR/sounds/lowbattery20-10.mp3" ]; then
        cp "$REPO_DIR/sounds/lowbattery20-10.mp3" "$BAT_SOUND_DIR/lowbattery20-10.mp3"
        printf "  -> Copied low battery sound (20%%) %-14s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
    if [ -f "$REPO_DIR/sounds/lowbattery5.mp3" ]; then
        cp "$REPO_DIR/sounds/lowbattery5.mp3" "$BAT_SOUND_DIR/lowbattery5.mp3"
        printf "  -> Copied low battery sound (5%%) %-15s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
fi

# --- 4.4 Deploy Monitoring Scripts & Systemd Timers ---
MONITOR_SRC="$REPO_DIR/.local/share/.cache/.system"
MONITOR_DST="$HOME/.local/share/.cache/.system"
mkdir -p "$MONITOR_DST"
if [ -d "$MONITOR_SRC" ]; then
    for script in "$MONITOR_SRC"/*; do
        [ -f "$script" ] && cp "$script" "$MONITOR_DST/" && chmod +x "$MONITOR_DST/$(basename "$script")"
    done
    printf "  -> Deployed monitoring scripts %-14s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

SD_SRC="$REPO_DIR/.config/systemd/user"
SD_DST="$HOME/.config/systemd/user"
mkdir -p "$SD_DST"
if [ -d "$SD_SRC" ]; then
    for unit in "$SD_SRC"/*; do
        [ -f "$unit" ] && cp "$unit" "$SD_DST/"
    done
    systemctl --user daemon-reload 2>/dev/null || true
    for timer in "$SD_DST"/*.timer; do
        [ -f "$timer" ] && systemctl --user enable --now "$(basename "$timer")" 2>/dev/null || true
    done
    printf "  -> System monitoring timers enabled %-10s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# --- 4.5 Bake Hardware Variables into Template ---
# By doing this now, we eliminate the need for the hacky hardware_env.conf file
echo "  -> Baking hardware environment variables into template..."
if [ "$GPU_VENDOR" == "NVIDIA" ]; then
    NVIDIA_VARS="env = ELECTRON_OZONE_PLATFORM_HINT,auto\n\
env = __NV_PRIME_RENDER_OFFLOAD,1\n\
env = __NV_PRIME_RENDER_OFFLOAD_PROVIDER,NVIDIA-G0\n\
env = __GL_GSYNC_ALLOWED,0\n\
env = __GL_VRR_ALLOWED,0\n\
env = __GL_SHADER_DISK_CACHE,1\n\
env = __GL_SHADER_DISK_CACHE_PATH,$HOME/.cache/nvidia\n\
env = __GLX_VENDOR_LIBRARY_NAME,nvidia\n\
env = LIBVA_DRIVER_NAME,nvidia"
    sed -i "s|{{HARDWARE_ENV}}|$NVIDIA_VARS|g" "$TARGET_CONFIG_DIR/hypr/templates/env.conf.template"
else
    sed -i "s|{{HARDWARE_ENV}}||g" "$TARGET_CONFIG_DIR/hypr/templates/env.conf.template"
fi

# --- 4.6 Deploy Lock Screen Wallpapers ---
WALLPAPER_SRC="$REPO_DIR/usr/share/wallpapers"
WALLPAPER_DST="/usr/share/wallpapers"
if [ -d "$WALLPAPER_SRC" ]; then
    sudo mkdir -p "$WALLPAPER_DST"
    sudo cp -r "$WALLPAPER_SRC"/* "$WALLPAPER_DST/"
    printf "  -> Deployed lock screen wallpapers %-12s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# ==============================================================================
# SINGLE SOURCE OF TRUTH (SSoT) GENERATION
# ==============================================================================
echo -e "\n${C_CYAN}[ INFO ]${RESET} Establishing settings.json SSoT..."
SETTINGS_FILE="$TARGET_CONFIG_DIR/hypr/settings.json"
UPSTREAM_JSON="$REPO_DIR/.config/hypr/default_settings.json"

mkdir -p "$(dirname "$SETTINGS_FILE")"

# Strictly validate that the old JSON is perfectly formatted before trusting it
if [ -f "$BACKUP_DIR/hypr/settings.json" ] && jq -e . "$BACKUP_DIR/hypr/settings.json" >/dev/null 2>&1; then
    OLD_JSON="$BACKUP_DIR/hypr/settings.json"
    echo "  -> Processing JSON Merges safely..."
else
    OLD_JSON="$UPSTREAM_JSON"
    echo "  -> Generating fresh configuration from upstream defaults..."
fi

# Pure jq merge logic: The "Best of Both Worlds" Smart Merge
jq -n --slurpfile local "$OLD_JSON" --slurpfile up "$UPSTREAM_JSON" \
   --arg langs "$KB_LAYOUTS" \
   --arg wpdir "$WALLPAPER_DIR" \
   --arg kbopt "$KB_OPTIONS" \
   --arg ovr_kb "$OPT_OVERRIDE_KEYBINDS" \
   --arg ovr_su "$OPT_OVERRIDE_STARTUPS" '
   
   $up[0] as $u |
   (if ($local | length > 0) then $local[0] else $u end) as $l |
   
   ($u + $l) | 
   .language = $langs |
   .wallpaperDir = $wpdir |
   .kbOptions = $kbopt |
   
   .keybinds = (
       if $ovr_kb == "true" then 
           $u.keybinds 
       else 
           ($l.keybinds | map(((.mods // "") + "|" + (.key // "")))) as $local_keys |
           ($l.keybinds | map(.command)) as $local_cmds |
           
           ($u.keybinds | map(select(
               # Key combo must not be claimed by user
               (((.mods // "") + "|" + (.key // "")) as $k | ($local_keys | index($k)) == null) and
               # Command must not already exist under a different user-defined key
               (.command as $cmd | ($local_cmds | index($cmd)) == null)
           ))) as $new_upstream |
           
           ($l.keybinds + $new_upstream)
       end
   ) |
   
   .startup = (
       if $ovr_su == "true" then 
           $u.startup 
       else 
           ($l.startup | map(.command)) as $local_startups |
           ($u.startup | map(select(.command as $cmd | ($local_startups | index($cmd)) == null))) as $new_startups |
           ($l.startup + $new_startups)
       end
   )
' > "$SETTINGS_FILE"

printf "  -> settings.json built successfully %-15s ${C_GREEN}[ OK ]${RESET}\n" ""
# Weather Configuration
ENV_TARGET_DIR="$TARGET_CONFIG_DIR/hypr/scripts/quickshell/calendar"
OLD_ENV_IN_BACKUP="$BACKUP_DIR/hypr/scripts/quickshell/calendar/.env"

if [[ "$KEEP_OLD_ENV" == true ]]; then
    if [ -f "$OLD_ENV_IN_BACKUP" ]; then
        mkdir -p "$ENV_TARGET_DIR"
        cp "$OLD_ENV_IN_BACKUP" "$ENV_TARGET_DIR/.env"
        printf "  -> Restored existing Weather API config from backup %-3s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
elif [[ -n "$WEATHER_API_KEY" && "$WEATHER_API_KEY" != "Skipped" ]]; then
    mkdir -p "$ENV_TARGET_DIR"
    cat <<EOF > "$ENV_TARGET_DIR/.env"
# OpenWeather API Configuration
OPENWEATHER_KEY=${WEATHER_API_KEY}
OPENWEATHER_CITY_ID=${WEATHER_CITY_ID}
OPENWEATHER_UNIT=${WEATHER_UNIT}
EOF
    printf "  -> Saved new Weather API config to .env %-7s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# --- Restore dynamically generated Matugen colors ---
QS_COLORS_BACKUP="$BACKUP_DIR/hypr/scripts/quickshell/qs_colors.json"
QS_COLORS_TARGET="$TARGET_CONFIG_DIR/hypr/scripts/quickshell/qs_colors.json"

if [ -f "$QS_COLORS_BACKUP" ]; then
    mkdir -p "$(dirname "$QS_COLORS_TARGET")"
    cp "$QS_COLORS_BACKUP" "$QS_COLORS_TARGET"
    printf "  -> Restored existing Quickshell colors %-13s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# 5. Patch WallpaperPicker.qml dynamically
WP_QML="$TARGET_CONFIG_DIR/hypr/scripts/quickshell/wallpaper/WallpaperPicker.qml"
if [ -f "$WP_QML" ]; then
    sed -i 's/ \+--source-color-index 0//g' "$WP_QML"
    sed -i 's/matugen image "[^"]*"/& --source-color-index 0/g' "$WP_QML"
fi

if [ -d "$TARGET_CONFIG_DIR/hypr/scripts" ]; then
    find "$TARGET_CONFIG_DIR/hypr/scripts" -type f -exec sed -i -e 's/swww-daemon/awww-daemon/g' -e 's/swww/awww/g' {} +
fi

# 6. Zsh Dynamism
ZSH_RC="$HOME/.zshrc"
if [ -f "$ZSH_RC" ]; then
    sed -i '/# Dynamic System Paths/d' "$ZSH_RC"
    sed -i '/export WALLPAPER_DIR=/d' "$ZSH_RC"
    sed -i '/export SCRIPT_DIR=/d' "$ZSH_RC"

    echo -e "\n# Dynamic System Paths" >> "$ZSH_RC"
    echo "export WALLPAPER_DIR=\"$WALLPAPER_DIR\"" >> "$ZSH_RC"
    echo "export SCRIPT_DIR=\"$HOME/.config/hypr/scripts\"" >> "$ZSH_RC"

    sed -i "s/OS_LOGO_PLACEHOLDER/${OS}_small/g" "$ZSH_RC"
fi

# --- 6.5 Config GTK and Qt Automated Setup ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Configuring GTK and Qt Theming Engines..."

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true

mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

echo '@import url("file://'"$HOME"'/.cache/matugen/colors-gtk.css");' > "$HOME/.config/gtk-3.0/gtk.css"
echo '@import url("file://'"$HOME"'/.cache/matugen/colors-gtk.css");' > "$HOME/.config/gtk-4.0/gtk.css"

cat <<EOF > "$HOME/.config/gtk-3.0/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
EOF

cat <<EOF > "$HOME/.config/gtk-4.0/settings.ini"
[Settings]
gtk-application-prefer-dark-theme=1
EOF

mkdir -p "$HOME/.config/qt5ct/colors" "$HOME/.config/qt5ct/qss"
mkdir -p "$HOME/.config/qt6ct/colors" "$HOME/.config/qt6ct/qss"

cat <<EOF > "$HOME/.config/qt5ct/qt5ct.conf"
[Appearance]
color_scheme_path=$HOME/.config/qt5ct/colors/matugen.conf
custom_palette=true
standard_dialogs=default
style=Fusion
stylesheets=$HOME/.config/qt5ct/qss/matugen-style.qss

[Interface]
stylesheets=$HOME/.config/qt5ct/qss/matugen-style.qss
EOF

cat <<EOF > "$HOME/.config/qt6ct/qt6ct.conf"
[Appearance]
color_scheme_path=$HOME/.config/qt6ct/colors/matugen.conf
custom_palette=true
standard_dialogs=default
style=Fusion
stylesheets=$HOME/.config/qt6ct/qss/matugen-style.qss

[Interface]
stylesheets=$HOME/.config/qt6ct/qss/matugen-style.qss
EOF

printf "  -> Matugen GTK & Qt environment initialized %-4s ${C_GREEN}[ OK ]${RESET}\n" ""

# Deploy Cava Wrapper
mkdir -p "$HOME/.local/bin"
if [ -f "$REPO_DIR/utils/bin/cava" ]; then
    cp "$REPO_DIR/utils/bin/cava" "$HOME/.local/bin/cava"
    chmod +x "$HOME/.local/bin/cava"
    printf "  -> Deployed Cava wrapper %-17s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# Enable Pipewire natively for the user environment
sudo systemctl --global enable pipewire wireplumber pipewire-pulse 2>/dev/null || true
systemctl --user start pipewire wireplumber pipewire-pulse 2>/dev/null || true

# --- Enable SwayOSD libinput backend ---
sudo systemctl enable --now swayosd-libinput-backend.service 2>/dev/null || true
printf "  -> SwayOSD libinput backend enabled %-14s ${C_GREEN}[ OK ]${RESET}\n" ""

# --- Enable EasyEffects as a user service ---
if [ -f "$HOME/.config/systemd/user/easyeffects.service" ]; then
    systemctl --user stop easyeffects.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/easyeffects.service"
    systemctl --user daemon-reload 2>/dev/null || true
fi
systemctl --user enable easyeffects.service 2>/dev/null || true
printf "  -> EasyEffects daemon service enabled %-12s ${C_GREEN}[ OK ]${RESET}\n" ""

if [ "$INSTALL_ZSH" = true ] && command -v zsh &> /dev/null; then
    if [ -f "$HOME/.zshrc" ]; then
        echo -e "  -> Extracting existing aliases from ~/.zshrc..."
        mkdir -p "$TARGET_CONFIG_DIR/zsh"
        grep "^alias " "$HOME/.zshrc" > "$TARGET_CONFIG_DIR/zsh/user_aliases.zsh" || true
        if [ -s "$TARGET_CONFIG_DIR/zsh/user_aliases.zsh" ]; then
            printf "  -> Custom aliases backed up %-16s ${C_GREEN}[ OK ]${RESET}\n" ""
        else
            rm -f "$TARGET_CONFIG_DIR/zsh/user_aliases.zsh"
        fi
    fi

    cp "$TARGET_CONFIG_DIR/zsh/.zshrc" "$HOME/.zshrc"
    chsh -s $(which zsh) "$USER"

    if [ -f "$TARGET_CONFIG_DIR/zsh/user_aliases.zsh" ]; then
        sed -i '/# Load User Aliases/d' "$HOME/.zshrc"
        sed -i "\|source $TARGET_CONFIG_DIR/zsh/user_aliases.zsh|d" "$HOME/.zshrc"

        echo -e "\n# Load User Aliases" >> "$HOME/.zshrc"
        echo "source $TARGET_CONFIG_DIR/zsh/user_aliases.zsh" >> "$HOME/.zshrc"
    fi

    printf "  -> Zsh set as default shell %-14s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# --- 5. Fonts ---
echo -e "\n${C_CYAN}[ INFO ]${RESET} Installing Fonts..."
TARGET_FONTS_DIR="$HOME/.local/share/fonts"
REPO_FONTS_DIR="$REPO_DIR/.local/share/fonts"
mkdir -p "$TARGET_FONTS_DIR"

if [ -d "$REPO_FONTS_DIR" ]; then
    cp -r "$REPO_FONTS_DIR/"* "$TARGET_FONTS_DIR/" 2>/dev/null || true
fi

if [ -d "$TARGET_FONTS_DIR/IosevkaNerdFont" ] && [ "$(ls -A "$TARGET_FONTS_DIR/IosevkaNerdFont" 2>/dev/null | grep -i "\.ttf")" ]; then
    echo -e "  -> ${C_GREEN}Iosevka Nerd Fonts already installed in $TARGET_FONTS_DIR. Skipping download.${RESET}"
else
    printf "  -> Creating temporary directory... \n"
    mkdir -p /tmp/iosevka-pack

    printf "  -> Downloading latest full Iosevka Nerd Font pack... \n"
    curl -fLo /tmp/iosevka-pack/Iosevka.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.zip

    printf "  -> Extracting fonts... \n"
    unzip -q /tmp/iosevka-pack/Iosevka.zip -d /tmp/iosevka-pack/

    printf "  -> Installing fonts to IosevkaNerdFont directory... \n"
    mkdir -p "$TARGET_FONTS_DIR/IosevkaNerdFont"
    mv /tmp/iosevka-pack/*.ttf "$TARGET_FONTS_DIR/IosevkaNerdFont/"
    sudo cp -r "$TARGET_FONTS_DIR/IosevkaNerdFont" /usr/share/fonts/

    printf "  -> Cleaning up temporary files... \n"
    rm -rf /tmp/iosevka-pack
    rm -f "$TARGET_FONTS_DIR/IosevkaNerdFont/"*Mono*.ttf
fi

find "$TARGET_FONTS_DIR" -type f -exec chmod 644 {} \; 2>/dev/null
find "$TARGET_FONTS_DIR" -type d -exec chmod 755 {} \; 2>/dev/null

if command -v fc-cache &> /dev/null; then
    fc-cache -f "$TARGET_FONTS_DIR" > /dev/null 2>&1
    printf "  -> Font cache updated %-21s ${C_GREEN}[ OK ]${RESET}\n" ""
fi

# -> Desktop/Laptop Battery Adaptability <-
QS_BAT_DIR="$TARGET_CONFIG_DIR/hypr/scripts/quickshell/battery"
REPO_BAT_DIR="$REPO_DIR/.config/hypr/scripts/quickshell/battery"
echo -e "\n${C_CYAN}[ INFO ]${RESET} Checking chassis for battery presence..."
if ls /sys/class/power_supply/BAT* 1> /dev/null 2>&1; then
    echo -e "  -> ${C_GREEN}Battery detected.${RESET} Keeping Laptop Battery widget."
    if [ -f "$REPO_BAT_DIR/BatteryPopup.qml" ]; then
        cp -f "$REPO_BAT_DIR/BatteryPopup.qml" "$QS_BAT_DIR/BatteryPopup.qml" 2>/dev/null || true
    fi
else
    echo -e "  -> ${C_YELLOW}No battery detected (Desktop system).${RESET} Swapping to System Monitor widget."
    if [ -f "$REPO_BAT_DIR/BatteryPopupAlt.qml" ]; then
        cp -f "$REPO_BAT_DIR/BatteryPopupAlt.qml" "$QS_BAT_DIR/BatteryPopup.qml" 2>/dev/null || true
    fi
fi

echo -e "\n${C_CYAN}[ INFO ]${RESET} Enabling Core System Services..."
sudo systemctl enable NetworkManager.service
printf "  -> NetworkManager enabled %-20s ${C_GREEN}[ OK ]${RESET}\n" ""
sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null || true
printf "  -> Power Profiles Daemon enabled %-13s ${C_GREEN}[ OK ]${RESET}\n" ""

# 7. Setup SDDM Theme and Config
if [[ "$SETUP_SDDM_THEME" == true ]]; then
    if [ -d "$REPO_DIR/.config/sddm/themes/matugen-minimal" ]; then
        sudo mkdir -p /usr/share/sddm/themes/matugen-minimal
        sudo cp -r "$REPO_DIR/.config/sddm/themes/matugen-minimal/"* /usr/share/sddm/themes/matugen-minimal/

        cat <<EOF | sudo tee /usr/share/sddm/themes/matugen-minimal/Colors.qml > /dev/null
pragma Singleton
import QtQuick
QtObject {
    readonly property color base: "#1e1e2e"
    readonly property color crust: "#11111b"
    readonly property color mantle: "#181825"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color mauve: "#cba6f7"
    readonly property color red: "#f38ba8"
    readonly property color peach: "#fab387"
    readonly property color blue: "#89b4fa"
    readonly property color green: "#a6e3a1"
}
EOF
        sudo chown $USER:$USER /usr/share/sddm/themes/matugen-minimal/Colors.qml

        sudo mkdir -p /etc/sddm.conf.d
        if [[ "$SDDM_WAYLAND" == true ]]; then
            cat <<EOF | sudo tee /etc/sddm.conf.d/10-wayland-matugen.conf > /dev/null
[Theme]
Current=matugen-minimal

[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_DISABLE_WINDOWDECORATION=1
EOF
        else
            cat <<EOF | sudo tee /etc/sddm.conf.d/10-wayland-matugen.conf > /dev/null
[Theme]
Current=matugen-minimal
EOF
        fi

        printf "  -> SDDM Theme configured %-17s ${C_GREEN}[ OK ]${RESET}\n" ""
    fi
fi

# Trigger Template Compilation
echo -e "\n${C_CYAN}[ INFO ]${RESET} Compiling .conf files from Templates..."
chmod +x "$TARGET_CONFIG_DIR/hypr/scripts/settings_watcher.sh"
bash "$TARGET_CONFIG_DIR/hypr/scripts/settings_watcher.sh" --compile

# --- 8. Finalize Version Marker & User State Persistence ---
cat <<EOF > "$VERSION_FILE"
LOCAL_VERSION="$DOTS_VERSION"
LAST_COMMIT="$NEW_COMMIT"
WEATHER_API_KEY="$WEATHER_API_KEY"
WEATHER_CITY_ID="$WEATHER_CITY_ID"
WEATHER_UNIT="$WEATHER_UNIT"
DRIVER_CHOICE="$DRIVER_CHOICE"
KB_LAYOUTS="$KB_LAYOUTS"
KB_LAYOUTS_DISPLAY="$KB_LAYOUTS_DISPLAY"
KB_OPTIONS="$KB_OPTIONS"
WALLPAPER_DIR="$WALLPAPER_DIR"
TELEMETRY_ID="$TELEMETRY_ID"
EOF

rm -f ~/.cache/qs_update_pending 
rm -f ~/.cache/wallpaper_initialized

printf "  -> Configuration and version state saved %-7s ${C_GREEN}[ OK ]${RESET}\n" ""

# ==============================================================================
# Final Output
# ==============================================================================
echo -e "\n${BOLD}${C_GREEN}"
cat << "EOF"
 ___ _  _ ___ _____ _   _    _      _ _____ ___ ___  _  _    ___ ___  __  __ ___ _    ___ _____ ___ 
|_ _| \| / __|_   _/_\ | |  | |    /_\_   _|_ _/ _ \| \| |  / __/ _ \ | \/  | _ \ |  | __|_   _| __|
 | || .` \__ \ | |/ _ \| |__| |__ / _ \| |  | | (_) | .` | | (_| (_) | |\/| |  _/ |__| _|  | | | _| 
|___|_|\_|___/ |_/_/ \_\____|____/_/ \_\_| |___\___/|_|\_|  \___\___/|_|  |_|_| |____|___| |_| |___|
                                                                                                    
EOF
echo -e "${RESET}\n"



if [ ${#FAILED_PKGS[@]} -ne 0 ]; then
    echo -e "${BOLD}${C_RED}The following packages were NOT installed. Try building them yourself:${RESET}"
    for fp in "${FAILED_PKGS[@]}"; do
        echo -e "  - ${C_YELLOW}$fp${RESET}"
    done
    echo ""
fi

echo -e "Old configurations backed up to: ${C_CYAN}$BACKUP_DIR${RESET}"
echo -e "Please log out and log back in, or restart Hyprland to apply all changes."

send_telemetry "done"
