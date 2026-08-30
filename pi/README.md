# Pi Sandbox

Two sandbox approaches for running `pi-coding-agent`: a Docker sandbox with rolling persistence through `docker commit`, and a persistent Incus sandbox. Both baselines include Ruff.

## Part I — Docker sandbox with rolling persistence

This approach keeps the simplicity and filesystem isolation of a disposable Docker sandbox while preserving tools installed inside the container between runs.

Instead of keeping one long-lived container, every session starts a new container from a rolling image. When Pi exits, the stopped container is committed back to the same image and then removed.

```text
pi-agent:rolling
      |
      | docker run
      v
temporary container
      |
      | Pi installs tools / modifies rootfs
      v
docker commit
      |
      v
pi-agent:rolling (updated)
```

The current project is still mounted from the host at `/workspace`, while Pi state is stored separately in the named volume `pi-home` mounted at `/root/.pi`.

### Dockerfile

```dockerfile
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        git \
        ripgrep \
        curl \
        nano \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 24 and update npm
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install --global npm@latest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Astral uv
RUN curl -LsSf https://astral.sh/uv/install.sh \
    | env UV_INSTALL_DIR="/usr/local/bin" UV_NO_MODIFY_PATH=1 sh

# Install Ruff globally through uv
RUN UV_TOOL_DIR=/opt/uv-tools \
    UV_TOOL_BIN_DIR=/usr/local/bin \
    uv tool install ruff@latest

# Install Pi coding agent
RUN npm install \
    --global \
    --ignore-scripts \
    @earendil-works/pi-coding-agent

WORKDIR /workspace
CMD ["pi"]
```

The Docker baseline now matches the Incus software stack: Ubuntu 24.04, Node.js 24, current npm, Astral `uv`, Ruff, Python, Git, ripgrep, and Pi coding agent. Ruff is installed globally with `uv tool install ruff@latest`.

### Initial image build

Build the initial rolling image from the Dockerfile:

```powershell
docker build -t pi-agent:rolling .
```

This is needed only for the initial setup or when you intentionally want to rebuild the baseline from the Dockerfile.

### Persistence model

Three kinds of state are handled separately:

```text
Host current directory  -> /workspace   bind mount
Pi state                -> /root/.pi    named volume: pi-home
Container filesystem    -> committed    image: pi-agent:rolling
```

Files under `/workspace` remain on the host. Pi configuration and other state under `/root/.pi` remain in the named volume. Tools installed elsewhere in the container, for example with `apt`, `npm -g`, `pip`, or similar commands, are captured by `docker commit` and become available in the next session.

Docker does not include bind mounts or volume contents in `docker commit`, which is intentional in this setup.

### PowerShell profile function

Add the following function to `profile.ps1`:

```powershell
function pi-sandbox {
    $name = "pi-sandbox-$PID"

    if ($args.Count -gt 0 -and $args[0] -eq "shell") {
        docker run --name $name -it --mount "type=bind,source=$($PWD.Path),target=/workspace" --mount "type=volume,source=pi-home,target=/root/.pi" -w /workspace pi-agent:rolling bash
    }
    else {
        docker run --name $name -it --mount "type=bind,source=$($PWD.Path),target=/workspace" --mount "type=volume,source=pi-home,target=/root/.pi" -w /workspace pi-agent:rolling pi @args
    }

    docker commit $name pi-agent:rolling | Out-Null
    docker rm $name | Out-Null
}
```

Reload the profile:

```powershell
. $PROFILE
```

Then run Pi from any project directory:

```powershell
cd C:\path\to\project
pi-sandbox
```

Arguments are forwarded directly to Pi:

```powershell
pi-sandbox --help
```

To open an interactive Bash shell instead of Pi:

```powershell
pi-sandbox shell
```

The foreground `docker run -it` blocks until Pi exits. The function then commits the container filesystem to `pi-agent:rolling` and removes the stopped container. The next invocation starts from the updated image while mounting the new current directory as `/workspace`.

A container left behind by an interrupted shell can be inspected with:

```powershell
docker ps -a --filter "name=pi-sandbox-"
```

---

## Part II — Persistent Incus sandbox

This setup keeps the sandbox filesystem persistent while exposing only the current host directory at `/workspace`. Pi configuration, extensions, skills, caches, and tools installed inside the container survive between runs. The image also installs Ruff.

> The YAML below targets ARM64 (`aarch64`). On an `x86_64` host, use `architecture: x86_64` and `http://archive.ubuntu.com/ubuntu` as `source.url`.

### 1. Prerequisites

```bash
sudo apt update
sudo apt install -y incus debootstrap snapd
sudo snap install distrobuilder --classic
```

Run Incus without `sudo`:

```bash
sudo adduser "$USER" incus-admin
newgrp incus-admin
```

`incus-admin` grants full control over the Incus daemon.

### 2. `pi-sandbox.yaml`

```yaml
image:
  name: pi-sandbox
  distribution: ubuntu
  release: noble
  description: Pi coding agent sandbox
  architecture: aarch64

source:
  downloader: debootstrap
  url: http://ports.ubuntu.com/ubuntu-ports
  components:
    - main
    - universe

packages:
  manager: apt
  update: true
  cleanup: true

  sets:
    - packages:
        - bash
        - ca-certificates
        - git
        - ripgrep
        - curl
        - nano
        - python3
        - python3-pip
        - python3-venv
        - systemd-resolved
      action: install
      flags:
        - --no-install-recommends

files:
  - path: /etc/systemd/network/10-eth0.network
    generator: dump
    content: |-
      [Match]
      Name=eth0

      [Network]
      DHCP=ipv4
      IPv6AcceptRA=no

actions:
  - trigger: post-packages
    action: |-
      #!/bin/bash
      set -euxo pipefail

      # Configure networking
      systemctl enable systemd-networkd
      systemctl enable systemd-resolved

      rm -f /etc/resolv.conf
      ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

      # Install Node.js 24 and npm
      curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
      apt-get install -y --no-install-recommends nodejs

      # Update npm
      npm install --global npm@latest

      # Install Astral uv
      curl -LsSf https://astral.sh/uv/install.sh \
        | env UV_INSTALL_DIR="/usr/local/bin" UV_NO_MODIFY_PATH=1 sh

      # Install Ruff globally through uv
      UV_TOOL_DIR=/opt/uv-tools \
      UV_TOOL_BIN_DIR=/usr/local/bin \
        uv tool install ruff@latest

      # Install Pi coding agent
      npm install \
        --global \
        --ignore-scripts \
        @earendil-works/pi-coding-agent

      mkdir -p /workspace

      apt-get clean
      rm -rf /var/lib/apt/lists/*

mappings:
  architecture_map: debian
```

### 3. Idempotent build

Save as `build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE_ALIAS="pi-sandbox"

incus image alias delete "$IMAGE_ALIAS" 2>/dev/null || true

sudo distrobuilder build-incus \
    --type=unified \
    --import-into-incus="$IMAGE_ALIAS" \
    pi-sandbox.yaml
```

Then:

```bash
chmod +x build.sh
./build.sh
```

### 4. Storage

```bash
incus storage show pi-storage >/dev/null 2>&1 || \
    incus storage create pi-storage dir
```

### 5. Private NAT network

```bash
incus network show pi-sandbox-net >/dev/null 2>&1 || \
    incus network create pi-sandbox-net \
        ipv4.address=10.240.0.1/24 \
        ipv4.nat=true \
        ipv6.address=none
```

### 6. UFW

If UFW is enabled:

```bash
sudo ufw allow in on pi-sandbox-net to any port 67 proto udp
sudo ufw allow in on pi-sandbox-net to any port 53
sudo ufw route allow in on pi-sandbox-net from 10.240.0.0/24
```

These rules allow DHCP, DNS, and forwarded/NAT traffic to the Internet.

### 7. Persistent instance

```bash
incus info pi-sandbox >/dev/null 2>&1 || \
    incus launch pi-sandbox pi-sandbox \
        --storage pi-storage \
        --network pi-sandbox-net
```

### 8. Host files

```bash
sudo install -d -m 700 /etc/pi
sudo chmod 600 /etc/pi/auth.json
sudo chmod 600 /etc/pi/APPEND_SYSTEM.md
```

Files:

```text
/etc/pi/auth.json
/etc/pi/APPEND_SYSTEM.md
```

### 9. Mounts

```bash
incus stop pi-sandbox 2>/dev/null || true
```

Dynamic workspace:

```bash
incus config device remove pi-sandbox workspace 2>/dev/null || true
incus config device add \
    pi-sandbox workspace disk \
    source=/tmp \
    path=/workspace \
    shift=true
```

`auth.json`:

```bash
incus config device remove pi-sandbox pi-auth 2>/dev/null || true
incus config device add \
    pi-sandbox pi-auth disk \
    source=/etc/pi/auth.json \
    path=/root/.pi/agent/auth.json \
    shift=true
```

`APPEND_SYSTEM.md`:

```bash
incus config device remove pi-sandbox pi-append-system-prompt 2>/dev/null || true
incus config device add \
    pi-sandbox pi-append-system-prompt disk \
    source=/etc/pi/APPEND_SYSTEM.md \
    path=/root/.pi/agent/APPEND_SYSTEM.md \
    shift=true
```

### 10. Bash helper

Add to `~/.bashrc`:

```bash
pi-sandbox () {
    local instance="pi-sandbox"
    local workspace
    local exit_code

    workspace="$(realpath -- "$PWD")"

    if incus info "$instance" | grep --color=auto -q '^Status: RUNNING'; then
        incus stop "$instance" || return 1
    fi

    incus config device set "$instance" workspace source="$workspace" || return 1
    incus start "$instance" || return 1

    if [[ "$1" == "shell" ]]; then
        incus exec "$instance" --cwd /workspace -- bash
    else
        incus exec "$instance" --cwd /workspace -- pi "$@"
    fi

    exit_code=$?
    incus stop "$instance"
    return "$exit_code"
}
```

Then:

```bash
source ~/.bashrc
```

### 11. Usage

```bash
cd ~/projects/example
pi-sandbox
```

Arguments are forwarded to Pi:

```bash
pi-sandbox --help
```

To open an interactive shell inside the same sandbox:

```bash
pi-sandbox shell
```

### 12. Network verification

```bash
incus start pi-sandbox
incus exec pi-sandbox -- ip -4 addr show eth0
incus exec pi-sandbox -- ping -c 1 google.com
incus exec pi-sandbox -- curl -I https://github.com
```

The container should receive an IPv4 address in `10.240.0.0/24`.

### Persistence and security

The Incus root filesystem remains persistent:

```text
/root/.pi/agent
/root/.local
/usr/local
/opt
```

The current project is mounted dynamically:

```text
Host $PWD
    |
    | disk + shift=true
    v
/workspace
```

Keep the container unprivileged, mount only the current project, and do not expose Docker/Incus sockets or attach the container directly to the physical LAN.

### Rebuild

```bash
incus delete pi-sandbox --force
./build.sh

incus launch pi-sandbox pi-sandbox \
    --storage pi-storage \
    --network pi-sandbox-net
```

After recreating the instance, reapply the `workspace`, `pi-auth`, and `pi-append-system-prompt` devices.


### Implementation references

- Ruff installation: https://docs.astral.sh/ruff/installation/
- uv tool installation: https://docs.astral.sh/uv/guides/tools/
