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
    local source_dir project_name safe_name hash device target lock_dir
    local project_fd instance_fd devices
    local exit_code=0
    local project_open=0 project_locked=0 instance_open=0 instance_locked=0
    local mounted=0 started_here=0 active_sessions=0

    source_dir="$(realpath -- "$PWD")" || return 1
    project_name="$(basename -- "$source_dir")"
    safe_name="$(printf '%s' "$project_name" | sed 's/[^[:alnum:]_.-]/-/g')"
    hash="$(printf '%s' "$source_dir" | sha256sum | cut -c1-5)"
    device="piw-$safe_name-$hash"
    target="/ws/$safe_name-$hash"
    lock_dir="$HOME/.cache/pi-sandbox-incus"

    # Existing sessions from older launcher versions have no lock.
    _pi_sandbox_shared_mount_busy() {
        local status
        status="$(
            incus exec "$instance" -- sh -c '
                target="$1"
                for pid_dir in /proc/[0-9]*; do
                    cwd="$(readlink "$pid_dir/cwd" 2>/dev/null)" || continue
                    case "$cwd" in
                        "$target"|"$target"/*) printf "BUSY"; exit 0 ;;
                    esac
                done
                printf "FREE"
            ' _ "$target" 2>/dev/null
        )" || return 0
        [[ "$status" != "FREE" ]]
    }

    trap 'return 130' INT
    trap 'return 143' TERM
    trap 'return 129' HUP

    {
        mkdir -p -m 700 "$lock_dir" || return 1
        exec {project_fd}>"$lock_dir/$device.lock" || return 1
        project_open=1

        if ! flock -n "$project_fd"; then
            echo "Error: project already has an active session: $target" >&2
            return 1
        fi
        project_locked=1

        exec {instance_fd}>"$lock_dir/$instance.lock" || return 1
        instance_open=1
        flock "$instance_fd" || return 1
        instance_locked=1

        devices="$(incus config device list "$instance")" || return 1
        if printf '%s\n' "$devices" | grep -Fxq "$device"; then
            if incus info "$instance" 2>/dev/null |
                grep -q '^Status: RUNNING$'; then
                if _pi_sandbox_shared_mount_busy; then
                    echo "Error: project mount is still in use: $target" >&2
                    return 1
                fi

                echo "Restoring ownership of stale mount: $source_dir"
                incus exec "$instance" -- sh -c \
                    'cd "$1" && find . -xdev -exec chown --no-dereference --reference=. {} +' \
                    _ "$target" || return 1
            fi

            echo "Removing stale workspace device: $device"
            incus config device remove "$instance" "$device" || return 1
        fi

        if ! incus info "$instance" 2>/dev/null |
            grep -q '^Status: RUNNING$'; then
            incus start "$instance" || return 1
            started_here=1
        fi

        incus config device add "$instance" "$device" disk \
            source="$source_dir" path="$target" shift=true || return 1
        mounted=1

        flock -u "$instance_fd" || return 1
        instance_locked=0

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
    } always {
        # Hold the instance lock while removing devices and deciding to stop it.
        if (( project_locked && instance_open )); then
            if (( ! instance_locked )); then
                if flock "$instance_fd"; then
                    instance_locked=1
                else
                    echo "Warning: could not lock Incus cleanup" >&2
                fi
            fi

            if (( instance_locked )); then
                if (( mounted )); then
                    if incus info "$instance" 2>/dev/null |
                        grep -q '^Status: RUNNING$'; then
                        if _pi_sandbox_shared_mount_busy; then
                            echo "Warning: workspace is still in use; keeping mount: $target" >&2
                        else
                            echo "Restoring ownership: $source_dir"
                            if incus exec "$instance" -- sh -c \
                                'cd "$1" && find . -xdev -exec chown --no-dereference --reference=. {} +' \
                                _ "$target"; then
                                incus config device remove "$instance" "$device" ||
                                    echo "Warning: failed to remove workspace device: $device" >&2
                            else
                                echo "Warning: failed to restore ownership; keeping mount: $target" >&2
                            fi
                        fi
                    else
                        incus config device remove "$instance" "$device" ||
                            echo "Warning: failed to remove workspace device: $device" >&2
                    fi
                fi

                if (( mounted || started_here )); then
                    if devices="$(incus config device list "$instance")"; then
                        active_sessions="$(printf '%s\n' "$devices" |
                            grep -Ec '^piw-.*-[[:xdigit:]]{5}$' || true)"

                        if (( active_sessions == 0 )); then
                            if incus info "$instance" 2>/dev/null |
                                grep -q '^Status: RUNNING$'; then
                                incus stop "$instance" --timeout 2 ||
                                    echo "Warning: failed to stop $instance" >&2
                            fi
                        else
                            printf '%s workspace mount(s) remaining, %s still running\n' \
                                "$active_sessions" "$instance"
                        fi
                    else
                        echo "Warning: could not list Incus devices; keeping the instance running" >&2
                    fi
                fi

                flock -u "$instance_fd"
            fi
        fi

        (( instance_open )) && exec {instance_fd}>&-
        (( project_open )) && exec {project_fd}>&-
        unfunction _pi_sandbox_shared_mount_busy 2>/dev/null
    }

    return "$exit_code"
}
alias pi='pi-sandbox-incus-shared'
fi
