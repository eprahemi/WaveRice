# ==============================================================================
# Oh My Zsh & Plugins Setup
# ==============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
ZSH_CUSTOM="$ZSH/custom"

# Install Oh-My-Zsh if it doesn't exist
if [ ! -d "$ZSH" ]; then
  echo "Installing Oh-My-Zsh..."
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH" >/dev/null 2>&1
fi

# Auto-fetch necessary plugins if they don't exist
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" >/dev/null 2>&1
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" >/dev/null 2>&1
fi

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# ==============================================================================
# History Configuration
# ==============================================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

# ==============================================================================
# Custom Functions
# ==============================================================================

# Automatically list directory contents upon changing directories
cd() {
  builtin cd "$@" && ls
}

# Dynamic Fastfetch with Matugen Colors
function fetch() {
    local color_file="$HOME/.config/hypr/scripts/quickshell/qs_colors.json"
    local config_path="/tmp/qs_fastfetch.jsonc"

    # Only rebuild the config if the Matugen colors changed or the config is missing
    if [ "$color_file" -nt "$config_path" ] || [ ! -f "$config_path" ]; then

        # Extract analogous cool tones
        local c_blue=$(grep -E '"blue"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_blue=${c_blue:-"#89b4fa"}

        local c_sapphire=$(grep -E '"sapphire"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_sapphire=${c_sapphire:-"#74c7ec"}

        local c_teal=$(grep -E '"teal"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_teal=${c_teal:-"#94e2d5"}

        local c_mauve=$(grep -E '"mauve"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_mauve=${c_mauve:-"#cba6f7"}

        local c_text=$(grep -E '"text"\s*:\s*"[^"]+"' "$color_file" 2>/dev/null | cut -d '"' -f 4)
        c_text=${c_text:-"#cdd6f4"}

        # Extract a full rainbow palette
        local palette_hexes=()
        for col in red peach yellow green sapphire mauve pink; do
            local val=$(grep -E "\"$col\"\s*:\s*\"[^\"]+\"" "$color_file" 2>/dev/null | cut -d '"' -f 4)
            case $col in
                red) val=${val:-"#f38ba8"} ;;
                peach) val=${val:-"#fab387"} ;;
                yellow) val=${val:-"#f9e2af"} ;;
                green) val=${val:-"#a6e3a1"} ;;
                sapphire) val=${val:-"#74c7ec"} ;;
                mauve) val=${val:-"#cba6f7"} ;;
                pink) val=${val:-"#f5c2e7"} ;;
            esac
            palette_hexes+=("$val")
        done

        # Convert the hex codes into a printable string of ANSI truecolor circles
        local palette_str=""
        for hex in "${palette_hexes[@]}"; do
            hex="${hex//\#/}" # Strip the hash
            local r=$((16#${hex:0:2}))
            local g=$((16#${hex:2:2}))
            local b=$((16#${hex:4:2}))
            palette_str+="\\\\e[38;2;${r};${g};${b}m● \\\\e[0m"
        done

        # Generate the dynamic Fastfetch configuration
        cat > "$config_path" <<EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
  "logo": {
    "source": "OS_LOGO_PLACEHOLDER",
    "color": {
      "1": "$c_blue",
      "2": "$c_sapphire"
    },
    "padding": {
      "top": 1,
      "left": 2,
      "right": 3
    }
  },
  "display": {
    "separator": "  ",
    "color": {
      "separator": "$c_text"
    }
  },
  "modules": [
    "break",
    {
      "type": "title",
      "format": "{1}",
      "color": {
        "user": "$c_blue"
      }
    },
    "break",
    {
      "type": "os",
      "key": "󱄅 os ",
      "keyColor": "$c_blue"
    },
    {
      "type": "cpu",
      "key": " cpu",
      "keyColor": "$c_sapphire"
    },
    {
      "type": "memory",
      "key": "󰘚 ram",
      "keyColor": "$c_teal"
    },
    {
      "type": "shell",
      "key": " sh ",
      "keyColor": "$c_mauve"
    },
    "break",
    {
      "type": "command",
      "key": " ",
      "text": "echo -e '$palette_str'"
    }
  ]
}
EOF
    fi

    # Run Fastfetch instantly using the cached config
    fastfetch -c "$config_path"
}

# ==============================================================================
# Utils
# ==============================================================================

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  🧹 REFRESH — Full System Cache Cleaner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
refresh() {
    echo "🧹 Cleaning pacman cache..."
    sudo pacman -Scc --noconfirm

    echo "🧹 Cleaning yay/AUR cache..."
    rm -rf ~/.cache/yay

    echo "🧹 Cleaning thumbnails & fontconfig..."
    rm -rf ~/.cache/thumbnails/* ~/.cache/fontconfig

    echo "🧹 Cleaning user cache (keeping browsers & apps)..."
    find ~/.cache -mindepth 1 -maxdepth 1 \
        ! -name 'chromium' ! -name 'google-chrome' ! -name 'microsoft-edge' \
        ! -name 'mozilla' ! -name 'firefox' \
        ! -name 'spotify' ! -name 'vesktop' ! -name 'discord' \
        -exec rm -rf {} +

    echo "🧹 Rebuilding font cache..."
    fc-cache -r

    echo "🧹 Vacuuming journal logs (keeping 7 days)..."
    sudo journalctl --vacuum-time=7d

    echo "🧹 Cleaning tmp files..."
    rm -rf /tmp/* 2>/dev/null

    echo "🧹 Cleaning go build cache..."
    go clean -cache 2>/dev/null

    echo "🧹 Cleaning pip cache..."
    pip cache purge 2>/dev/null

    echo "🧹 Cleaning npm cache..."
    npm cache clean --force 2>/dev/null

    echo "✅ System refreshed!"
    fetch
}

# ─── EPRAHEMI UPDATE CHECKER ──────────────────────────────────────────
update() {
    local current_version remote_version
    local RED='\e[31m' GREEN='\e[32m' CYAN='\e[36m' BLUE='\e[34m'
    local MAGENTA='\e[35m' YELLOW='\e[33m' BOLD='\e[1m' DIM='\e[2m' RESET='\e[0m'

    if [ -f ~/.local/state/wiferice-version ]; then
        source ~/.local/state/wiferice-version
        current_version="$LOCAL_VERSION"
    else
        current_version="Unknown"
    fi

    remote_version=$(curl -m 5 -s https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh | grep '^DOTS_VERSION=' | cut -d'"' -f2)

    if [ -z "$remote_version" ]; then
        echo -e "\n  ${RED}[ERROR]${RESET} Could not check for updates. Check your internet connection.\n"
        return 1
    fi

    echo ""
    echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD}${GREEN}  ● Eprahemi Dots — Update Checker${RESET}"
    echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}"
    echo -e "  ${BOLD} Current:${RESET}  v$current_version"
    echo -e "  ${BOLD} Latest:${RESET}   v$remote_version"

    if [ "$current_version" = "$remote_version" ]; then
        echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}"
        echo -e "  ${GREEN}✅ You're on the latest version!${RESET}"
        echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}\n"
        return 0
    fi

    echo -e "  ${YELLOW}  ⚠ Update available!${RESET}"
    echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}  GitHub: ${RESET}${BOLD}eprahemi/WifeRice${RESET}"
    echo -e "  ${DIM}  Reddit: ${RESET}${BOLD}u/eprahemi${RESET}"
    echo -e "  ${BLUE}──────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}Download & install?${RESET} [y/N]: "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "  ${CYAN}Downloading v$remote_version...${RESET}"
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/eprahemi/WifeRice/main/install.sh)"
    else
        echo -e "  ${DIM}Update skipped.${RESET}\n"
    fi
}
