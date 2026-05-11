#!/usr/bin/env bash

# ===========================================================================
#  Eprahemi Updated Dots — Restore Script
#  Restores all dotfiles, wallpapers, and themes to system locations
# ===========================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/backup_$(date +%Y%m%d_%H%M%S)"
CURRENT_USER=$(whoami)

echo ""
echo "  ███████╗██╗    ██╗     ██╗      ██████╗"
echo "  ██╔════╝██║    ██║     ██║     ██╔════╝"
echo "  █████╗  ██║    ██║     ██║     ██║"
echo "  ██╔══╝  ██║    ██║     ██║     ██║"
echo "  ██║     ██║    ███████╗███████╗╚██████╗"
echo "  ╚═╝     ╚═╝    ╚══════╝╚══════╝ ╚═════╝"
echo ""
echo "  Eprahemi Updated Dots — System Restore"
echo "  User: $CURRENT_USER"
echo "  https://github.com/eprahemi"
echo ""
echo "  ──────────────────────────────────────────────"
echo ""

# ─── INSTALL DEPENDENCIES ─────────────────────────────────────────────

echo "  [1/9] Installing required packages..."
echo ""

if command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm --needed xdg-user-dirs xdg-desktop-portal-hyprland 2>/dev/null || true
    xdg-user-dirs-update 2>/dev/null || true
    echo "    [OK] xdg-user-dirs, xdg-desktop-portal-hyprland"
fi

echo ""

# ─── BACKUP EXISTING CONFIGS ──────────────────────────────────────────────

echo "  [2/9] Backing up current configs to: $BACKUP_DIR"
echo ""

mkdir -p "$BACKUP_DIR"
for dir in hypr kitty nvim rofi swaync matugen; do
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" 2>/dev/null
        echo "    [BACKUP] ~/.config/$dir"
    fi
done

echo ""

# ─── RESTORE CONFIG FILES (Force overwrite) ───────────────────────────────

echo "  [3/9] Restoring configuration files..."
echo ""

# Hyprland (force overwrite all configs including config/ subdirectory)
if [ -d "$SCRIPT_DIR/Hyprland" ]; then
    rm -rf ~/.config/hypr 2>/dev/null
    mkdir -p ~/.config/hypr
    cp -rf "$SCRIPT_DIR/Hyprland"/* ~/.config/hypr/
    echo "    [RESTORED] Hyprland (force overwrite)"
fi

if [ -d "$SCRIPT_DIR/Kitty" ]; then
    rm -rf ~/.config/kitty 2>/dev/null
    mkdir -p ~/.config/kitty
    cp -f "$SCRIPT_DIR/Kitty"/* ~/.config/kitty/
    echo "    [RESTORED] Kitty"
fi

if [ -d "$SCRIPT_DIR/Neovim" ]; then
    rm -rf ~/.config/nvim 2>/dev/null
    mkdir -p ~/.config/nvim
    cp -f "$SCRIPT_DIR/Neovim"/* ~/.config/nvim/
    echo "    [RESTORED] Neovim"
fi

if [ -d "$SCRIPT_DIR/Rofi" ]; then
    rm -rf ~/.config/rofi 2>/dev/null
    mkdir -p ~/.config/rofi
    cp -f "$SCRIPT_DIR/Rofi"/* ~/.config/rofi/
    echo "    [RESTORED] Rofi"
fi

if [ -d "$SCRIPT_DIR/SwayNC" ]; then
    rm -rf ~/.config/swaync 2>/dev/null
    mkdir -p ~/.config/swaync
    cp -f "$SCRIPT_DIR/SwayNC"/* ~/.config/swaync/
    echo "    [RESTORED] SwayNC"
fi

if [ -d "$SCRIPT_DIR/Matugen" ]; then
    rm -rf ~/.config/matugen 2>/dev/null
    mkdir -p ~/.config/matugen/templates
    cp -f "$SCRIPT_DIR/Matugen/config.toml" ~/.config/matugen/
    cp -f "$SCRIPT_DIR/Matugen/templates"/* ~/.config/matugen/templates/
    echo "    [RESTORED] Matugen"
fi

echo ""

# ─── REGENERATE CONFIGS FOR CURRENT USER ───────────────────────────

echo "  [4/10] Regenerating configs for current user..."
echo ""

if [ -f "$HOME/.config/hypr/scripts/settings_watcher.sh" ]; then
    bash "$HOME/.config/hypr/scripts/settings_watcher.sh" --compile 2>/dev/null || true
    echo "    [OK] Configs regenerated for user $CURRENT_USER"
fi

echo ""

# ─── INSTALL .zshrc ─────────────────────────────────────────────────

echo "  [5/10] Installing .zshrc..."
echo ""

if [ -f "$SCRIPT_DIR/.zshrc" ] && [ ! -f "$HOME/.zshrc" ]; then
    cp -f "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
    echo "    [INSTALLED] ~/.zshrc (first install)"
fi

echo ""

# ─── INSTALL FACE ICON ─────────────────────────────────────────────────

echo "  [6/10] Installing user face icon..."
echo ""

if [ -f "$SCRIPT_DIR/Faces/.face.icon" ] && [ ! -f "$HOME/.face.icon" ] && [ ! -f "/usr/share/sddm/faces/${CURRENT_USER}.face.icon" ]; then
    cp -f "$SCRIPT_DIR/Faces/.face.icon" "$HOME/.face.icon"
    echo "    [INSTALLED] ~/.face.icon (Lockscreen)"
    
    if command -v sudo &>/dev/null; then
        sudo mkdir -p /usr/share/sddm/faces
        sudo cp -f "$SCRIPT_DIR/Faces/.face.icon" "/usr/share/sddm/faces/${CURRENT_USER}.face.icon"
        echo "    [INSTALLED] /usr/share/sddm/faces/${CURRENT_USER}.face.icon (SDDM Login)"
    fi
fi

echo ""

# ─── COPY WALLPAPERS TO PICTURES FOLDER ───────────────────────────────

echo "  [7/10] Setting up wallpapers for picker (Super+W)..."
echo ""

mkdir -p "$HOME/Pictures/Wallpapers"

if [ -d "$SCRIPT_DIR/Wallpapers" ]; then
    find "$SCRIPT_DIR/Wallpapers" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -exec cp -f {} "$HOME/Pictures/Wallpapers/" \;
    echo "    [COPIED] Wallpapers → ~/Pictures/Wallpapers/"
fi

echo "    [INFO] Add more wallpapers to ~/Pictures/Wallpapers/"

# Clear wallpaper picker thumbnail cache for a fresh start
rm -rf "$HOME/.cache/wallpaper_picker" 2>/dev/null || true
echo "    [OK] Wallpaper thumbnail cache cleared"

echo ""

# ─── SDDM WALLPAPER ──────────────────────────────────────────

echo "  [8/10] Restoring SDDM wallpaper..."
echo ""

if [ -d "$SCRIPT_DIR/SDDM-Wallpaper" ]; then
    # Lock screen wallpaper — only set once, never overwrite user's custom file
    if [ ! -f /usr/share/wallpapers/lock.png ] && command -v sudo &>/dev/null; then
        sudo mkdir -p /usr/share/wallpapers
        sudo cp -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" /usr/share/wallpapers/lock.png
        echo "    [RESTORED] /usr/share/wallpapers/lock.png (Lockscreen)"
    fi
    # SDDM login wallpaper — only set on first install
    if [ ! -d /usr/share/sddm/themes/matugen-minimal ] && command -v sudo &>/dev/null; then
        sudo mkdir -p /usr/share/sddm/themes/matugen-minimal
        sudo cp -f "$SCRIPT_DIR/SDDM-Wallpaper/wallpaper.png" /usr/share/sddm/themes/matugen-minimal/wallpaper.png
        echo "    [RESTORED] /usr/share/sddm/themes/matugen-minimal/wallpaper.png (Login Screen)"
    fi
fi

echo ""

# ─── FIX KEYBINDINGS PERMISSIONS ─────────────────────────────────────

echo "  [9/10] Setting up keybinding permissions..."
echo ""

chmod +x ~/.config/hypr/scripts/*.sh 2>/dev/null || true
echo "    [OK] Scripts made executable"

echo ""

# ─── CLEANUP STALE REFERENCES ───────────────────────────────────────────

echo "  [10/10] Cleaning up stale references..."
echo ""

rm -f "$HOME/.local/state/imperative-dots-version" 2>/dev/null

echo "  [10/10] Writing version file..."
echo ""

mkdir -p "$HOME/.local/state"
echo "LOCAL_VERSION=\"1.7.12\"" > "$HOME/.local/state/wiferice-version"
echo "    [VERSION] v1.7.14"

echo ""

# ─── RELOAD HYPRLAND ────────────────────────────────────────────────────

echo "  Reloading Hyprland..."
hyprctl reload 2>/dev/null && echo "    [OK] Hyprland reloaded" || echo "    [WARN] Hyprland not running (reload manually)"

# ─── DONE ───────────────────────────────────────────────────────────────

echo ""
echo "  ──────────────────────────────────────────────"
echo ""
echo "  ✅ All configs restored successfully! (v1.7.14)"
echo ""
echo "  👤 User: $CURRENT_USER"
echo "  📂 Old configs backed up to: $BACKUP_DIR"
echo ""
echo "  ⌨️  Keybindings:"
echo "     • Super+T = Open terminal (Kitty)"
echo "     • Super+W = Wallpaper picker"
echo "     • Super+Q = Close window"
echo "     • Super+D = App launcher"
echo "     • Super+H = Help/Guide"
echo ""
echo "  🖼  Face Icon:"
echo "     • Lockscreen → ~/.face.icon"
echo "     • SDDM Login → /usr/share/sddm/faces/${CURRENT_USER}.face.icon"
echo ""
echo "  🖼  Wallpapers:"
echo "     • Folder → ~/Pictures/Wallpapers/ (for picker - Super+W)"
echo "     • Lockscreen → /usr/share/wallpapers/lock.png"
echo "     • Login (SDDM) → /usr/share/sddm/themes/matugen-minimal/wallpaper.png"
echo ""
echo "  📝 Terminal:"
echo "     • ~/.zshrc installed (oh-my-zsh auto-installs)"
echo ""
echo "  ⚠️  Add your OpenWeather API key:"
echo "     Create: ~/.config/hypr/scripts/quickshell/calendar/.env"
echo ""
echo "  ──────────────────────────────────────────────"
echo ""
