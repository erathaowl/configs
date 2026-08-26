FROM node:24-bookworm-slim

# Install prerequisites
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash ca-certificates git ripgrep curl nano jq \
    python3 python3-pip python3-venv\
    # nmap iproute2 \
  && rm -rf /var/lib/apt/lists/*

# Install Astral uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install pi coding agent globally
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Copy files
COPY modules.pi /modules.pi
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
