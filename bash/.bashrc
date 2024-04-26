# expand history size
HISTSIZE=5000
HISTFILESIZE=10000

#append instead overwrite history file
shopt -s histappend

# save, clear and reload history after every command
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

# disable ctrl+s = suspend terminal
stty -ixon