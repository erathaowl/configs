#!/bin/sh
set -e

agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
mkdir -p "$agent_dir"

while IFS= read -r extension || [ -n "$extension" ]; do
    extension=$(printf '%s\n' "$extension" | sed 's/\r$//; s/^[[:space:]]*//; s/[[:space:]]*$//')
    case "$extension" in
        ''|'#'*) continue ;;
    esac

    # A configured package without an installed path must be reinstalled.
    if ! pi list --no-approve | awk -v extension="$extension" '
        $0 == "  " extension || $0 == "  " extension " (filtered)" {
            if (getline > 0 && $0 ~ /^    \/.*/) installed = 1
        }
        END { exit installed ? 0 : 1 }
    '; then
        pi install "$extension"
    fi
done </modules.pi

lmstudio_config="$agent_dir/lmstudio.json"
if [ ! -f "$lmstudio_config" ] || ! jq -e '
    type == "object" and
    (.url | type) == "string" and (.url | length) > 0 and
    (.token | type) == "string"
' "$lmstudio_config" >/dev/null 2>&1; then
    config_tmp=$(mktemp "$agent_dir/lmstudio.json.XXXXXX")
    trap 'rm -f "$config_tmp"' EXIT HUP INT TERM
    jq -n \
        --arg url "${LMSTUDIO_URL:-http://host.docker.internal:1234}" \
        --arg token "${LMSTUDIO_TOKEN:-token}" \
        '{url: $url, token: $token}' >"$config_tmp"
    mv "$config_tmp" "$lmstudio_config"
    trap - EXIT HUP INT TERM
fi

exec pi "$@"
