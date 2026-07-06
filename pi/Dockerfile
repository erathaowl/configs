FROM node:24-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      git \
      ripgrep \
    #   nmap \
    #   curl \
    #   wget \
    #   iproute2 \
    #   nano \
  && rm -rf /var/lib/apt/lists/*

### install pi-coding-agent and lmstudio
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent
RUN pi install npm:pi-lmstudio

### some useful scripts for debugging network issues
# RUN printf '#!/bin/sh\nip -br address\n' \
#     > /usr/local/bin/ipa \
#  && chmod +x /usr/local/bin/ipa

# RUN printf '#!/bin/sh\nip -br route\n' \
#     > /usr/local/bin/ipr \
#  && chmod +x /usr/local/bin/ipr

# RUN printf '#!/bin/sh\nip -br address\necho\nip -br route\n' \
#     > /usr/local/bin/ipar \
#  && chmod +x /usr/local/bin/ipar

# RUN printf '#!/bin/sh\nss -tulpn\n' \
#     > /usr/local/bin/ipp \
#  && chmod +x /usr/local/bin/ipp

### copy entrypoint script and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["entrypoint.sh"]
CMD ["pi"]