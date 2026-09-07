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

# pi-agend sandbox via docker
pi-sandbox-docker() { 
    docker run --rm -it \
        -v "${PWD}:/workspace" \
        -v "pi-agent-home:/root/.pi/agent" \
        pi-sandbox "$@"
}

# start pi coding agent in lxc container
pi-sandbox () {
    local instance="pi-sandbox"
    local workspace
    local exit_code

    workspace="$(realpath -- "$PWD")"

    if incus info "$instance" | grep --color=auto -q '^Status: RUNNING'; then
        incus stop "$instance" || return 1
    fi

    incus config device set "$instance" workspace source="$workspace" || return 1
    incus start "$instance" || return 1

    if [[ "$1" == "shell" ]]; then
        incus exec "$instance" --cwd /workspace -- bash
    else
        incus exec "$instance" --cwd /workspace -- pi "$@"
    fi

    exit_code=$?
    incus stop "$instance"
    return "$exit_code"
}
alias pi='pi-sandbox'

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
    local push=true
    local message=""

    for arg in "$@"; do
        if [[ "$arg" == "-np" ]]; then
            push=false
        else
            message="$arg"
        fi
    done

    if [[ -z "$message" ]]; then
        echo "Usage: lazygit \"commit message\" [-np]"
        return 1
    fi

    git status &&
    git add . &&
    git commit -m "$message" || return 1

    printf '\033[7;32m     Committed       \033[0m\n'

    if $push; then
        git push || return 1
        printf '\033[7;32m     Pushed          \033[0m\n'
    else
        printf '\033[7;33m     Push skipped    \033[0m\n'
    fi

    echo
    git show --stat --oneline --color=always HEAD
}
