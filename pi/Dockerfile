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

# Preserve the real Git binary and install a wrapper that blocks remote writes
RUN dpkg-divert \
        --local \
        --rename \
        --add \
        --divert /usr/bin/git-real \
        /usr/bin/git \
    && cat > /usr/bin/git <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

args=("$@")
command=""
command_index=-1
i=0

while (( i < ${#args[@]} )); do
    arg="${args[$i]}"

    case "$arg" in
        -C|-c|--git-dir|--work-tree|--namespace|--super-prefix|--config-env)
            ((i += 2))
            ;;
        -*)
            ((i += 1))
            ;;
        *)
            command="$arg"
            command_index="$i"
            break
            ;;
    esac
done

if [[ "$command" == "push" || "$command" == "send-pack" ]]; then
    echo "ERROR: Remote Git writes are disabled in this sandbox." >&2
    exit 1
fi

if [[ "$command" == "lfs" && "${args[$((command_index + 1))]:-}" == "push" ]]; then
    echo "ERROR: Remote Git writes are disabled in this sandbox." >&2
    exit 1
fi

exec /usr/bin/git-real "$@"
WRAPPER
RUN chmod 755 /usr/bin/git

WORKDIR /workspace
CMD ["pi"]
