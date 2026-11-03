# Set case insensitive shell completion
if [ -n "$BASH_VERSION" ]; then
  bind "set completion-ignore-case on";
  alias fcp='HISTFILE=/dev/null bash -i'
fi

# New no-history shell in ZSH
if [ -n "$ZSH_VERSION" ]; then
    alias fcp="fc -p"
fi

# Space added in order to allow alias expansion
alias sudo='sudo '

# mixed usefull things
#alias nano='nano -c'
#alias nano='SUDO_EDITOR="nano -c" sudoedit'

alias gistory="history | grep -i $1"
alias untar="tar -xvf"
alias cd..="cd .."

# Copy file(s) showing progress info
alias rcp='rsync -ahWIU --no-owner --no-group --no-inc-recursive --info=progress2'
alias rcpv='rsync -ahvWIU --no-owner --no-group --no-inc-recursive --info=flist,progress1,progress2'

# Human readable filesizes
alias df="df -h"
alias du="du -h"

# Some usefull network related aliases
alias ip="ip -c"
alias iplist="ip -br -c addr show"
alias maclist="ip -o link | awk '$2 != "lo:" {print $2, $17}'"
alias routelist="ip -c r"
# ---
alias ipa=iplist
alias ipm=maclist
alias ipr=routelist
alias ipp="ss -tulpn"
alias ipar="ipa && echo && ipr"

# Create parent directory on demand if needed
alias mksdir='mkdir -pv'

# Watch with color for commands like "service"
alias watchc="watch -c SYSTEMD?COLORS=1"

# Disable history and clear itself from history; if inside tmux change to red the background color of the pane
alias nohistory="set +o history && history -d -1 && if [ $TMUX ]; then tmux select-pane -P 'bg=#440000'; fi"

# Check and use eza in place of standard ls
if command -v eza 2>&1 >/dev/null
then
    #alias eza="eza --icons"
    alias ls="eza --group-directories-first"
    #alias ll="eza --group-directories-first --long --all --octal-permissions --no-permissions --group --header --time-style=long-iso"
    alias ll="eza --group-directories-first --long --all -a --group --header --time-style=long-iso"
else
    alias ls="ls --color=auto"
    alias ll="ls -alFh"
fi

# Grep custom shortcuts
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Less custom shortcut
alias gless='less -G'
alias gview='view "+normal G$"'

# Check and replace standard cat with bat
if command -v batcat 2>&1 >/dev/null
then
    # require batcat installed: `sudo apt install bat`
    alias cat="batcat --paging=never --style=plain"
    alias bat="batcat --paging=never"
fi

# Hashing shortcuts
alias sha1="sha1sum"
alias md5="md5sum"
alias sha512="sha512sum"
alias sha256="sha256sum"

# Check if veracrypt is installed and add shortcuts
if command -v veracrypt 2>&1 >/dev/null
then
    alias vu="veracrypt -u"
fi

# Check if uv is installed and add shortcuts
if command -v uv 2>&1 >/dev/null
then
    alias uvr="uv run"
    alias uvp="uv run python"
    alias uvm="uv run python manage.py"
fi

# Recursive clean current folder fronl python cache and compiled files 
pycclean() {
  find . -type f -name '*.py[co]' -delete -o -type d -name __pycache__ -delete -delete
}

# Ipscan via nmap icmp test
ipscan() {
    # Check if an argument (IP or subnet) was provided
    if [ -z "$1" ]; then
        echo "Error: you must specify a subnet or an IP."
        echo "Usage: ipscan <192.168.x.x/24>"
        return 1
    fi
    # Execute the command using the provided argument
    nmap -sn -PE "$1" -oG - | awk '/Up$/{print $2}'
}

# Perform apt update as sudo, 
#   then list upgradable packages 
#   and ask to proceed with upgrade
alias supdate='sudo apt update && apt list --upgradable && read -t 10 -p "Press [ENTER] or wait 10 seconds..."; sudo NEEDRESTART_MODE=a apt dist-upgrade -y && sudo apt autoremove -y && sudo apt clean -y'

# minimal docker ps colored tab
docker-ps() {
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}" \
    | awk '
        NR == 1 { print; next }
        /Up /     { printf "\033[32m%s\033[0m\n", $0; next }
        /Exited / { printf "\033[31m%s\033[0m\n", $0; next }
        { print }
    '
}

# Wrap nano to track the absolute path of a single edited (ALT+S to save readonly in nanorc) file and always enable cursor position display.
unalias nano 2>/dev/null
nano() {
    if [[ $# -eq 1 ]]; then
        NANO_CURRENT_FILE="$(realpath -m -- "$1")" command nano -c "$1"
    else
        command nano -c "$@"
    fi
}

# Lazy command to perform git status-add-commit and skippable push
lazygit() {
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        emulate -L zsh
        setopt ksh_arrays
    fi

    local message="" arg choice
    local skip_push=0 file_index=0 tracked_count=0
    local -a changed_files=()

    for arg in "$@"; do
        if [[ "$arg" == "-np" ]]; then
            skip_push=1
        elif [[ -z "$message" ]]; then
            message="$arg"
        else
            printf 'Usage: lazygit "commit message" [-np]\n'
            return 1
        fi
    done

    if [[ -z "$message" ]]; then
        printf 'Usage: lazygit "commit message" [-np]\n'
        return 1
    fi

    git status || return 1

    while true; do
        printf 'Proceed, differences, or abort/quit? [P/d/a/q] '
        IFS= read -r choice || return 1
        case "$choice" in
            ''|[pP]*) break ;;
            [dD]*)
                git diff --stat --color=always || return 1
                while true; do
                    printf 'Proceed, review, or abort/quit? [P/r/a/q] '
                    IFS= read -r choice || return 1
                    case "$choice" in
                        ''|[pP]*) break 2 ;;
                        [rR]*)
                            while IFS= read -r -d '' arg; do
                                changed_files+=("$arg")
                            done < <(git diff HEAD --name-only -z)
                            tracked_count=${#changed_files[@]}
                            while IFS= read -r -d '' arg; do
                                changed_files+=("$arg")
                            done < <(git ls-files --others --exclude-standard -z)

                            if (( ${#changed_files[@]} == 0 )); then
                                printf 'No changed files to review.\n'
                                continue
                            fi

                            file_index=0
                            while true; do
                                if (( file_index < tracked_count )); then
                                    git diff --color=always HEAD -- "${changed_files[$file_index]}" || return 1
                                else
                                    git diff --color=always --no-index -- /dev/null "${changed_files[$file_index]}"
                                    (( $? <= 1 )) || return 1
                                fi
                                while true; do
                                    if (( file_index == ${#changed_files[@]} - 1 )); then
                                        printf 'Continue, previous, next, or abort/quit? [C/p/n/a/q] '
                                    else
                                        printf 'Continue, previous, next, or abort/quit? [c/p/N/a/q] '
                                    fi
                                    IFS= read -r choice || return 1
                                    if [[ -z "$choice" ]]; then
                                        if (( file_index == ${#changed_files[@]} - 1 )); then
                                            choice=c
                                        else
                                            choice=n
                                        fi
                                    fi
                                    case "$choice" in
                                        [cC]*) break 4 ;;
                                        [pP]*)
                                            if (( file_index > 0 )); then
                                                ((file_index -= 1))
                                                break
                                            fi
                                            printf 'Already at the first file.\n'
                                            ;;
                                        [nN]*)
                                            if (( file_index < ${#changed_files[@]} - 1 )); then
                                                ((file_index += 1))
                                                break
                                            fi
                                            printf 'Already at the last file.\n'
                                            ;;
                                        [aA]*|[qQ]*) return 1 ;;
                                        *) printf 'Please choose continue, previous, next, or abort/quit.\n' ;;
                                    esac
                                done
                            done
                            ;;
                        [aA]*|[qQ]*) return 1 ;;
                        *) printf 'Please choose proceed, review, or abort/quit.\n' ;;
                    esac
                done
                ;;
            [aA]*|[qQ]*) return 1 ;;
            *) printf 'Please choose proceed, differences, or abort/quit.\n' ;;
        esac
    done

    git add . && git commit -m "$message" || return 1
    printf '\033[7;32m     Committed       \033[0m\n'

    if (( ! skip_push )); then
        git push || return 1
        printf '\033[7;32m     Pushed          \033[0m\n'
    else
        printf '\033[7;33m     Push skipped    \033[0m\n'
    fi

    printf '\n'
    git show --stat --oneline --color=always HEAD
}

delhist() {
    local index="${1:--1}"

    [[ "$index" =~ ^-?[1-9][0-9]*$ ]] || return 2
    [[ -n "${HISTFILE:-}" ]] || return 1

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        local entry
        entry=$(fc -ln "$index" "$index") || return 1
        [[ -n "$entry" ]] || return 1

        local previous_ignore="${HISTORY_IGNORE:-}"
        local HISTORY_IGNORE="${(b)entry}"
        [[ -n "$previous_ignore" ]] && HISTORY_IGNORE="($previous_ignore|$HISTORY_IGNORE)"

        fc -W && fc -p "$HISTFILE" "$HISTSIZE" "$SAVEHIST"

    elif [[ -n "${BASH_VERSION:-}" ]]; then
        (( index < 0 )) && index=$((index - 1))
        history -d "$index" && history -w
    fi
}


# simple speedtest via github python script
sspeedtest() {
    curl -s https://raw.githubusercontent.com/PeterLinuxOSS/speedtest-cli/master/speedtest.py | python3 -
}

# Install or update an optional module. Return 2 for usage errors, 1 on failure.
aliases-install() {
    if [ "$#" -ne 1 ]; then
        printf 'Usage: aliases-install <pi|codex>\n' >&2
        return 2
    fi
    case "$1" in
        pi|codex) ;;
        *) printf 'aliases-install: unsupported module: %s\n' "$1" >&2; return 2 ;;
    esac

    local directory="$HOME/.config/aliases.d"
    local temporary
    mkdir -p -- "$directory" || return 1
    temporary=$(mktemp "$directory/.$1.XXXXXX") || return 1

    if ! wget -qO "$temporary" "https://raw.githubusercontent.com/erathaowl/configs/main/bash/modules/$1.sh"; then
        rm -f -- "$temporary"
        printf 'aliases-install: download failed: %s\n' "$1" >&2
        return 1
    fi
    if ! mv -f -- "$temporary" "$directory/$1.sh"; then
        rm -f -- "$temporary"
        printf 'aliases-install: could not install: %s\n' "$1" >&2
        return 1
    fi

    # Modules guard their own shell-specific helpers.
    . "$directory/$1.sh"
}

# Optional modules are installed separately; shell startup never downloads them.
if [ -f "$HOME/.config/aliases.d/pi.sh" ]; then
    . "$HOME/.config/aliases.d/pi.sh"
fi
if [ -f "$HOME/.config/aliases.d/codex.sh" ]; then
    . "$HOME/.config/aliases.d/codex.sh"
fi
