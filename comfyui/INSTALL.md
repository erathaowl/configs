# ComfyUI — Installation Guide

## Prerequisites

- **OS**: Linux (tested on Ubuntu/Debian-based distros)
- **git**, **curl**, **wget** available in `$PATH`
- `uv` Python package manager ([astral.sh/uv](https://docs.astral.sh/uv/))

> **Note**: All commands assume you are starting from your chosen ComfyUI install directory (e.g. `/opt/ComfyUI`).
> Adjust paths accordingly if you install elsewhere.

---

## 1. Install `uv` (if not already installed)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Reload your shell or source the updated profile so `uv` is in `$PATH`:

```bash
source $HOME/.local/bin/env   # or restart the terminal
```

---

## 2. Clone ComfyUI

```bash
git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git .
```

---

## 3. Create the Python virtual environment

```bash
uv venv --python 3.12
```

---

## 4. Install Python dependencies

```bash
uv pip install -r requirements.txt
```

---

## 5. Install custom nodes

Move into the `custom_nodes` directory and download the node list and installer script from this repo:

```bash
cd custom_nodes
wget https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main/comfyui/custom_nodes.list
wget https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main/comfyui/install_custom_nodes.sh
chmod +x install_custom_nodes.sh
```

Run the installer (must be inside `custom_nodes/`, which is the default clone target):

```bash
bash ./install_custom_nodes.sh ./custom_nodes.list
```

> **Note**: The script clones each repo listed in `custom_nodes.list` into the current directory
> and installs their `requirements.txt` / `pyproject.toml` via `uv pip install`.
> If a node directory already exists it will be updated instead of re-cloned.

Go back to the ComfyUI root when done:

```bash
cd ..
```

---

## 6. (Optional) Create a desktop shortcut

Replace `/opt/ComfyUI` with your actual install path if different.

```bash
sudo tee /usr/share/applications/comfyui.desktop > /dev/null << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=ComfyUI
Comment=Stable Diffusion graphical interface
Exec=bash -c "cd /opt/ComfyUI && uv run main.py"
Icon=/opt/ComfyUI/.venv/lib/python3.12/site-packages/comfyui_frontend_package/static/assets/favicon.ico
Terminal=true
Categories=Graphics;2DGraphics;
Keywords=ai;stable diffusion;image generation;
EOF
```

---

## Running ComfyUI

From the ComfyUI install directory:

```bash
uv run main.py
```

Add `--listen` to expose the UI on the local network, or `--port 8188` to change the default port.

---

## Quick reference — full install sequence

```bash
# 1. Install uv (skip if already available)
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env

# 2. Clone & set up ComfyUI
git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git .
uv venv --python 3.12
uv pip install -r requirements.txt

# 3. Install custom nodes
cd custom_nodes
wget https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main/comfyui/custom_nodes.list
wget https://raw.githubusercontent.com/erathaowl/configs/refs/heads/main/comfyui/install_custom_nodes.sh
chmod +x install_custom_nodes.sh
bash ./install_custom_nodes.sh ./custom_nodes.list
cd ..
```
