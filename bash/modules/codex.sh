# The Incus helper requires Zsh's local traps and dynamic scoping.
if [ -n "${ZSH_VERSION:-}" ]; then
codex-sandbox-shared() {
    emulate -L zsh
    setopt localtraps

    local instance="codex-sandbox"
    local source_dir
    local project_name
    local safe_name
    local hash
    local device
    local target
    local exit_code=0
    local mounted=0
    local cleaning=0
    local active_sessions=0

    source_dir="$(realpath -- "$PWD")" || return 1
    project_name="$(basename -- "$source_dir")"
    safe_name="$(printf '%s' "$project_name" | sed 's/[^[:alnum:]_.-]/-/g')"
    hash="$(printf '%s' "$source_dir" | sha256sum | cut -c1-5)"

    device="cdxw-${safe_name}-${hash}"
    target="/ws/${safe_name}-${hash}"

    _codex_sandbox_shared_cleanup() {
        (( cleaning )) && return
        cleaning=1

        if (( mounted )); then
            echo "Restoring ownership: $source_dir"

            incus exec "$instance" -- sh -c \
                'cd "$1" && find . -xdev -exec chown --no-dereference --reference=. {} +' \
                _ "$target"

            incus config device remove "$instance" "$device"
            mounted=0
        fi

        active_sessions="$(
            incus config device list "$instance" 2>/dev/null |
                grep -Ec '^cdxw-.*-[[:xdigit:]]{5}$' || true
        )"

        if (( active_sessions == 0 )); then
            if incus info "$instance" 2>/dev/null |
                grep -q '^Status: RUNNING$'; then
                incus stop "$instance"
            fi

            printf '%s \033[31mstopped\033[0m\n' "$instance"
        elif (( active_sessions == 1 )); then
            printf '1 active session, %s \033[33mstill running\033[0m\n' "$instance"
        else
            printf '%s active sessions, %s \033[33mstill running\033[0m\n' \
                "$active_sessions" "$instance"
        fi
    }

    trap '_codex_sandbox_shared_cleanup; return 130' INT
    trap '_codex_sandbox_shared_cleanup; return 143' TERM
    trap '_codex_sandbox_shared_cleanup; return 129' HUP

    # Remove a stale device left by an interrupted previous execution.
    if incus config device list "$instance" 2>/dev/null |
        grep -Fxq "$device"; then

        if incus info "$instance" 2>/dev/null |
            grep -q '^Status: RUNNING$'; then
            echo "Error: project is already mounted: $target"
            return 1
        fi

        incus config device remove "$instance" "$device" || return 1
    fi

    if ! incus info "$instance" 2>/dev/null |
        grep -q '^Status: RUNNING$'; then
        incus start "$instance" || return 1
    fi

    incus config device add "$instance" "$device" disk \
        source="$source_dir" \
        path="$target" \
        shift=true || return 1

    mounted=1

    if [[ "$1" == "shell" ]]; then
        shift
        incus exec "$instance" --cwd "$target" -- bash "$@"
    else
        incus exec "$instance" --cwd "$target" -- codex "$@"
    fi

    exit_code=$?

    _codex_sandbox_shared_cleanup

    trap - INT TERM HUP
    unfunction _codex_sandbox_shared_cleanup 2>/dev/null

    return "$exit_code"
}
alias codex='codex-sandbox-shared'
fi
