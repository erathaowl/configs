FROM node:24-bookworm-slim

# Install prerequisites
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep curl \
     # nmap iproute2 \
  && rm -rf /var/lib/apt/lists/*

# Install Astral uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Install pi coding agent globally
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

# Install pi modules from modules.pi file
COPY modules.pi /tmp/modules.pi
RUN set -eu; \
    while IFS= read -r module || [ -n "$module" ]; do \
      module="$(printf '%s' "$module" | tr -d '\r')"; \
      case "$module" in \
        ""|\#*) continue ;; \
      esac; \
      printf '\n========== Installing pi module: %s ==========\n' "$module"; \
      pi install "$module"; \
    done < /tmp/modules.pi; \
    rm -f /tmp/modules.pi

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
