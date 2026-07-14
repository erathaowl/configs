#!/bin/sh
set -e

mkdir -p /root/.pi/agent

if [ ! -f /root/.pi/agent/lmstudio.json ]; then
    cat >/root/.pi/agent/lmstudio.json <<EOF
{"url":"${LMSTUDIO_URL:-http://host.docker.internal:1234}","token":"${LMSTUDIO_TOKEN:-token}"}
EOF
fi

exec pi "$@"
