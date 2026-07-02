#!/usr/bin/env bash
#
# install.sh — ComfyUI full installer
#
# Usage:
#   bash install.sh [INSTALL_DIR]
#
# If INSTALL_DIR is omitted the current directory is used.
# The script must be run as a regular user (sudo is used internally only
# for the optional .desktop file step).

set -euo pipefail

# ---------- Colors ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ---------- Helpers ----------
info()    { echo -e "${CYAN}${BOLD}[INFO]${NC}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}${BOLD}[ERR ]${NC}  $*" >&2; }
die()     { error "$*"; exit 1; }
section() { echo -e "\n${BOLD}${CYAN}━━━  $*  ━━━${NC}"; }

run() {
    # run CMD [ARGS…]  — execute silently, print friendly error on failure
    local label="$1"; shift
    info "$label"
    if ! "$@" > /tmp/_install_out 2>&1; then
        error "$label — FAILED"
        cat /tmp/_install_out >&2
        exit 1
    fi
    ok "$label"
}

# ---------- Resolve install directory ----------
INSTALL_DIR="${1:-$(pwd)}"
INSTALL_DIR="$(realpath "$INSTALL_DIR")"

CONFIGS_BASE="https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main/comfyui"

# ---------- Banner ----------
echo -e "
${BOLD}${CYAN}╔══════════════════════════════════════════╗
║          ComfyUI  Installer              ║
╚══════════════════════════════════════════╝${NC}
  Install path : ${BOLD}${INSTALL_DIR}${NC}
"

# ─────────────────────────────────────────────
section "Step 1 — Check prerequisites"
# ─────────────────────────────────────────────

check_cmd() {
    if command -v "$1" > /dev/null 2>&1; then
        ok "$1 found  ($(command -v "$1"))"
    else
        echo "$1 missing"
        return 1
    fi
}

MISSING=()
for cmd in git wget curl; do
    check_cmd "$cmd" || MISSING+=("$cmd")
done

[[ ${#MISSING[@]} -gt 0 ]] && die "Missing required tools: ${MISSING[*]}.  Install them and re-run."

# ─────────────────────────────────────────────
section "Step 2 — Install / verify uv"
# ─────────────────────────────────────────────

if command -v uv > /dev/null 2>&1; then
    ok "uv already installed  ($(uv --version))"
else
    info "uv not found — installing via official installer..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        ok "uv installed"
        # Make uv available in this session
        export PATH="$HOME/.local/bin:$PATH"
        source "$HOME/.local/bin/env" 2>/dev/null || true
    else
        die "uv installation failed. Install manually: https://docs.astral.sh/uv/"
    fi
fi

command -v uv > /dev/null 2>&1 || die "uv still not in PATH after install. Open a new terminal and re-run."

# ─────────────────────────────────────────────
section "Step 3 — Clone ComfyUI"
# ─────────────────────────────────────────────

mkdir -p "$INSTALL_DIR"

if [[ -f "$INSTALL_DIR/main.py" ]]; then
    warn "ComfyUI appears to be already cloned in $INSTALL_DIR — skipping clone."
else
    info "Cloning ComfyUI into $INSTALL_DIR ..."
    if git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git "$INSTALL_DIR" 2>&1 | \
            grep -E "^(Cloning|remote:|Receiving|Resolving|Updating)" || true; then
        :
    fi
    [[ -f "$INSTALL_DIR/main.py" ]] || die "Clone succeeded but main.py not found — unexpected repository layout."
    ok "ComfyUI cloned"
fi

cd "$INSTALL_DIR"

# ─────────────────────────────────────────────
section "Step 4 — Create Python 3.12 virtual environment"
# ─────────────────────────────────────────────

if [[ -d "$INSTALL_DIR/.venv" ]]; then
    warn ".venv already exists — skipping venv creation."
else
    run "Creating venv with Python 3.12" uv venv --python 3.12
fi

# ─────────────────────────────────────────────
section "Step 5 — Install ComfyUI dependencies"
# ─────────────────────────────────────────────

run "Installing requirements.txt" uv pip install -r requirements.txt

# ─────────────────────────────────────────────
section "Step 6 — Install custom nodes"
# ─────────────────────────────────────────────

NODES_DIR="$INSTALL_DIR/custom_nodes"
mkdir -p "$NODES_DIR"
cd "$NODES_DIR"

info "Downloading custom_nodes.list ..."
wget -q -O custom_nodes.list "$CONFIGS_BASE/custom_nodes.list" \
    || die "Failed to download custom_nodes.list"
ok "custom_nodes.list downloaded"

info "Downloading install_custom_nodes.sh ..."
wget -q -O install_custom_nodes.sh "$CONFIGS_BASE/install_custom_nodes.sh" \
    || die "Failed to download install_custom_nodes.sh"
chmod +x install_custom_nodes.sh
ok "install_custom_nodes.sh downloaded"

echo ""
info "Running custom node installer..."
echo ""
bash ./install_custom_nodes.sh ./custom_nodes.list
echo ""
ok "Custom nodes installed"

cd "$INSTALL_DIR"

# ─────────────────────────────────────────────
section "Step 7 — Desktop shortcut (optional)"
# ─────────────────────────────────────────────

DESKTOP_FILE="/usr/share/applications/comfyui.desktop"

if [[ ! -d /usr/share/applications ]]; then
    warn "/usr/share/applications not found — skipping desktop shortcut (not a desktop Linux system?)."
elif [[ -f "$DESKTOP_FILE" ]]; then
    warn "Desktop shortcut already exists at $DESKTOP_FILE — skipping."
else
    # Detect the favicon path dynamically
    FAVICON="$(find "$INSTALL_DIR/.venv" -path "*/comfyui_frontend_package/static/assets/favicon.ico" 2>/dev/null | head -n1)"
    [[ -z "$FAVICON" ]] && FAVICON="$INSTALL_DIR/.venv/lib/python3.12/site-packages/comfyui_frontend_package/static/assets/favicon.ico"

    info "Creating desktop shortcut at $DESKTOP_FILE ..."
    if sudo tee "$DESKTOP_FILE" > /dev/null << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Stable Diffusion graphical interface
Exec=bash -c "cd ${INSTALL_DIR} && uv run main.py"
Icon=${FAVICON}
Terminal=true
Categories=Graphics;2DGraphics;
Keywords=ai;stable diffusion;image generation;
EOF
    then
        ok "Desktop shortcut created"
    else
        warn "Could not create desktop shortcut (sudo failed?). You can create it manually — see install.md."
    fi
fi

# ─────────────────────────────────────────────
section "Done!"
# ─────────────────────────────────────────────

echo -e "
${GREEN}${BOLD}ComfyUI is ready.${NC}

  To launch:
    ${BOLD}cd ${INSTALL_DIR} && uv run main.py${NC}

  Options:
    --listen          expose UI on the local network
    --port 8188       change the default port
"
