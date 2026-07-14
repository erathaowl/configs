FROM node:24-bookworm-slim

#Install prerequisites
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git ripgrep curl \
     # nmap iproute2 \
  && rm -rf /var/lib/apt/lists/*

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
      printf '========== Installed: %s ==========\n\n' "$module"; \
    done < /tmp/modules.pi; \
    rm -f /tmp/modules.pi

# Add some usefull network scripts
# RUN printf '#!/bin/sh\nip -br address\n' \
#     > /usr/local/bin/ipa \
#  && chmod +x /usr/local/bin/ipa

# RUN printf '#!/bin/sh\nip -br route\n' \
#    > /usr/local/bin/ipr \
# && chmod +x /usr/local/bin/ipr

# RUN printf '#!/bin/sh\nip -br address\necho\nip -br route\n' \
#     > /usr/local/bin/ipar \
#  && chmod +x /usr/local/bin/ipar

WORKDIR /workspace
ENTRYPOINT ["pi"]
