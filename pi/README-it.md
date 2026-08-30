# Pi Sandbox

Due modalità per eseguire `pi-coding-agent` in sandbox: una sandbox Docker con persistenza rolling tramite `docker commit` e una sandbox Incus persistente. Entrambe le baseline includono Ruff.

## Parte I — Sandbox Docker con persistenza rolling

Questo approccio mantiene la semplicità e l'isolamento filesystem della sandbox Docker usa-e-getta, conservando però tra le esecuzioni i tool installati dentro il container.

Ogni sessione crea un nuovo container a partire da un'immagine rolling. Quando Pi termina, il container fermo viene salvato nuovamente nella stessa immagine tramite `docker commit` e poi eliminato.

```text
pi-agent:rolling
      |
      | docker run
      v
container temporaneo
      |
      | Pi installa tool / modifica il rootfs
      v
docker commit
      |
      v
pi-agent:rolling aggiornata
```

Il progetto corrente continua a essere montato dall'host in `/workspace`, mentre lo stato di Pi è conservato separatamente nel named volume `pi-home`, montato in `/root/.pi`.

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

La baseline Docker replica ora lo stack software Incus: Ubuntu 24.04, Node.js 24, npm aggiornato, Astral `uv`, Ruff, Python, Git, ripgrep e Pi coding agent. Ruff viene installato globalmente tramite `uv tool install ruff@latest`.

### Build iniziale dell'immagine

Costruire l'immagine rolling iniziale dal Dockerfile:

```powershell
docker build -t pi-agent:rolling .
```

Serve per il setup iniziale o quando si vuole ricreare intenzionalmente la baseline dal Dockerfile.

### Modello di persistenza

I tre tipi di stato vengono gestiti separatamente:

```text
Directory corrente host -> /workspace   bind mount
Stato di Pi             -> /root/.pi    named volume: pi-home
Filesystem container    -> commit       image: pi-agent:rolling
```

I file sotto `/workspace` restano sull'host. Configurazione e altro stato di Pi sotto `/root/.pi` rimangono nel named volume. I tool installati nel resto del filesystem del container, per esempio tramite `apt`, `npm -g`, `pip` o comandi analoghi, vengono acquisiti da `docker commit` e saranno disponibili nella sessione successiva.

Docker non include nel `docker commit` il contenuto dei bind mount e dei volume, comportamento voluto in questa configurazione.

### Funzione da aggiungere a `profile.ps1`

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

Ricaricare il profilo:

```powershell
. $PROFILE
```

Poi eseguire Pi da qualsiasi progetto:

```powershell
cd C:\path\to\project
pi-sandbox
```

Gli argomenti vengono inoltrati direttamente a Pi:

```powershell
pi-sandbox --help
```

Per aprire una shell Bash interattiva al posto di Pi:

```powershell
pi-sandbox shell
```

Il `docker run -it` rimane in foreground fino all'uscita da Pi. La funzione esegue quindi il commit del filesystem del container in `pi-agent:rolling` ed elimina il container fermo. L'esecuzione successiva parte dall'immagine aggiornata e monta la nuova directory corrente in `/workspace`.

Un eventuale container rimasto dopo un'interruzione della shell può essere individuato con:

```powershell
docker ps -a --filter "name=pi-sandbox-"
```

---

## Parte II — Sandbox Incus persistente

Questa configurazione mantiene persistente il filesystem del sandbox esponendo dall'host solamente la directory corrente in `/workspace`. Configurazione, extension, skill, cache e tool installati nel container rimangono disponibili tra le esecuzioni. L'immagine installa inoltre Ruff.

> Lo YAML seguente è configurato per ARM64 (`aarch64`). Su host `x86_64`, usare `architecture: x86_64` e `http://archive.ubuntu.com/ubuntu` come `source.url`.

### 1. Prerequisiti

```bash
sudo apt update
sudo apt install -y incus debootstrap snapd
sudo snap install distrobuilder --classic
```

Per usare Incus senza `sudo`:

```bash
sudo adduser "$USER" incus-admin
newgrp incus-admin
```

`incus-admin` concede pieno controllo sul daemon Incus.

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

### 3. Build idempotente

Salvare come `build.sh`:

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

Poi:

```bash
chmod +x build.sh
./build.sh
```

### 4. Storage

```bash
incus storage show pi-storage >/dev/null 2>&1 || \
    incus storage create pi-storage dir
```

### 5. Rete privata NAT

```bash
incus network show pi-sandbox-net >/dev/null 2>&1 || \
    incus network create pi-sandbox-net \
        ipv4.address=10.240.0.1/24 \
        ipv4.nat=true \
        ipv6.address=none
```

### 6. UFW

Se UFW è attivo:

```bash
sudo ufw allow in on pi-sandbox-net to any port 67 proto udp
sudo ufw allow in on pi-sandbox-net to any port 53
sudo ufw route allow in on pi-sandbox-net from 10.240.0.0/24
```

Le tre regole consentono rispettivamente DHCP, DNS e traffico inoltrato/NAT verso Internet.

### 7. Istanza persistente

```bash
incus info pi-sandbox >/dev/null 2>&1 || \
    incus launch pi-sandbox pi-sandbox \
        --storage pi-storage \
        --network pi-sandbox-net
```

### 8. File host

```bash
sudo install -d -m 700 /etc/pi
sudo chmod 600 /etc/pi/auth.json
sudo chmod 600 /etc/pi/APPEND_SYSTEM.md
```

File usati:

```text
/etc/pi/auth.json
/etc/pi/APPEND_SYSTEM.md
```

### 9. Mount

```bash
incus stop pi-sandbox 2>/dev/null || true
```

Workspace dinamico:

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

### 10. Funzione Bash

Aggiungere a `~/.bashrc`:

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

Poi:

```bash
source ~/.bashrc
```

### 11. Utilizzo

```bash
cd ~/projects/example
pi-sandbox
```

Gli argomenti vengono inoltrati a Pi:

```bash
pi-sandbox --help
```

Per aprire una shell interattiva nello stesso sandbox:

```bash
pi-sandbox shell
```

### 12. Verifica rete

```bash
incus start pi-sandbox
incus exec pi-sandbox -- ip -4 addr show eth0
incus exec pi-sandbox -- ping -c 1 google.com
incus exec pi-sandbox -- curl -I https://github.com
```

Il container deve ricevere un IPv4 nella subnet `10.240.0.0/24`.

### Persistenza e sicurezza

Persistono nel root filesystem Incus:

```text
/root/.pi/agent
/root/.local
/usr/local
/opt
```

Il progetto corrente viene montato dinamicamente:

```text
Host $PWD
    |
    | disk + shift=true
    v
/workspace
```

Mantenere il container unprivileged, montare solo il progetto corrente e non esporre socket Docker/Incus o la LAN fisica.

### Rebuild

```bash
incus delete pi-sandbox --force
./build.sh

incus launch pi-sandbox pi-sandbox \
    --storage pi-storage \
    --network pi-sandbox-net
```

Dopo la ricreazione riapplicare i tre device `workspace`, `pi-auth` e `pi-append-system-prompt`.


### Riferimenti implementativi

- Installazione Ruff: https://docs.astral.sh/ruff/installation/
- Installazione tool con uv: https://docs.astral.sh/uv/guides/tools/
