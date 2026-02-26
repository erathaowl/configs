# Set case insensitive shell completion
if [ -n "$BASH_VERSION" ]; then
  bind "set completion-ignore-case on";
  alias fcp='HISTFILE=/dev/null bash -i'
fi

# New no-history shell in ZSH
if [ -n "$ZSH_VERSION" ]; then
    alias fcp="fc -p"
fi

alias nano='nano -c'
alias gistory="history | grep -i $1"
alias untar="tar -xvf"
alias cd..="cd .."
alias ip="ip -c"

# Copy file(s) showing progress info
alias rcp="rsync -ah --info=progress2"

# Human readable filesizes
alias df="df -h"
alias du="du -h"

# Some usefull network related aliases
alias iplist="ip -br -c addr show"
alias maclist="ip -o link | awk '$2 != "lo:" {print $2, $17}'"
alias routelist="ip -c r"
# ---
alias ipa=iplist
alias ipm=maclist
alias ipr=routelist

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
    alias ll="eza --group-directories-first --long --all --octal-permissions --no-permissions --group --header --time-style=long-iso"
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

# Copy file(s) showing progress info
alias rcp="rsync -ah --info=progress2"

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
