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
