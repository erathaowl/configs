# Pi sandbox via Docker (Bash and Zsh).
pi-sandbox-docker() {
    docker run --rm -it \
        -v "${PWD}:/workspace" \
        -v "pi-agent-home:/root/.pi/agent" \
        pi-sandbox "$@"
}

# The Incus helper requires Zsh's local traps and dynamic scoping.
if [ -n "${ZSH_VERSION:-}" ]; then
# start pi coding agent in lxc container
pi-sandbox-incus-shared() {
    emulate -L zsh
    setopt localtraps

    local instance="pi-sandbox"
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

    if [[ "$1" == "force-remove" ]]; then
        if [[ $# -ne 2 || -z "$2" ]]; then
            echo "Usage: pi force-remove <project-id>" >&2
            return 2
        fi
        incus config device remove "$instance" "piw-$2"
        return $?
    fi

    source_dir="$(realpath -- "$PWD")" || return 1
    project_name="$(basename -- "$source_dir")"
    safe_name="$(printf '%s' "$project_name" | sed 's/[^[:alnum:]_.-]/-/g')"
    hash="$(printf '%s' "$source_dir" | sha256sum | cut -c1-5)"

    device="piw-${safe_name}-${hash}"
    target="/ws/${safe_name}-${hash}"

    _pi_sandbox_shared_cleanup() {
        (( cleaning )) && return
        cleaning=1

        if (( mounted )); then
            echo "Restoring ownership: $source_dir"

            incus exec "$instance" -- sh -c \
                'cd "$1" && find . -xdev -exec chown --no-dereference --reference=. {} +' \
                _ "$target"

            #echo "Removing workspace device: $device"
            incus config device remove "$instance" "$device"
            mounted=0
        fi

        active_sessions="$(
            incus config device list "$instance" 2>/dev/null |
                grep -Ec '^piw-.*-[[:xdigit:]]{5}$' || true
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

    trap '_pi_sandbox_shared_cleanup; return 130' INT
    trap '_pi_sandbox_shared_cleanup; return 143' TERM
    trap '_pi_sandbox_shared_cleanup; return 129' HUP

    # Remove a stale device left by an interrupted previous execution.
    if incus config device list "$instance" 2>/dev/null |
        grep -Fxq "$device"; then

        if incus info "$instance" 2>/dev/null |
            grep -q '^Status: RUNNING$'; then
            echo "Error: project is already mounted: $target"
            echo "For orphan session use: pi force-remove ${device#piw-}"
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

    elif [[ "$1" == "list" ]]; then
        shift

        incus exec "$instance" --cwd /workspace -- bash -c '
            package=""

            while IFS= read -r line; do
                trimmed="${line#"${line%%[![:space:]]*}"}"

                [[ -z "$trimmed" ]] && continue

                if [[ "$trimmed" == "User packages:" ]]; then
                    printf "%s\n" "$trimmed"
                    continue
                fi

                if [[ "$trimmed" == /* ]]; then
                    path="$trimmed"
                    version=""

                    if [[ -f "$path/package.json" ]]; then
                        version="$(node -p "require(process.argv[1]).version || \"\"" "$path/package.json" 2>/dev/null)"
                    fi

                    if [[ -n "$package" ]]; then
                        if [[ -n "$version" ]]; then
                            printf "  %s - %s\n" "$package" "$version"
                        else
                            printf "  %s\n" "$package"
                        fi
                    fi

                    printf "\033[90m    %s\033[0m\n" "$path"
                    package=""
                else
                    package="$trimmed"
                fi
            done < <(pi list "$@")

            if [[ -n "$package" ]]; then
                printf "  %s\n" "$package"
            fi
        ' _ "$@"

    else
        incus exec "$instance" --cwd "$target" -- pi "$@"
    fi

    exit_code=$?

    _pi_sandbox_shared_cleanup

    trap - INT TERM HUP
    unfunction _pi_sandbox_shared_cleanup 2>/dev/null

    return "$exit_code"
}
alias pi='pi-sandbox-incus-shared'
fi
