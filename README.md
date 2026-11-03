# configs

Personal repository to keep various config files like bash, nano etc...
If you find something usefull feel free to grab and use, but most likely you can skip it without worries

Italian keyboard:
- backtick: `Alt + 96`
- tilde: `Alt + 126`
- È: `Alt + 0200`
- É: `Alt + 0201`

 
## Shell aliases (Bash and Zsh)

Install the core aliases:

```sh
wget -qO ~/.bash_aliases https://raw.githubusercontent.com/erathaowl/configs/main/bash/.aliases.sh
. ~/.bash_aliases
```

Bash normally loads `~/.bash_aliases` from `~/.bashrc`; ensure that source line
exists. For Zsh, add `. ~/.bash_aliases` to `~/.zshrc`.
The installer instead saves the same core to `~/.config/.user_aliases` and
symlinks `~/.bash_aliases` to it; both layouts work.

Install optional modules independently from a shell with the core loaded:

```sh
aliases-install pi
aliases-install codex
```

Run the same command again to update a module. Downloads require `wget`;
failed downloads leave the existing file intact. Installed modules are sourced
immediately and automatically from `~/.config/aliases.d/pi.sh` and
`~/.config/aliases.d/codex.sh` whenever the core is loaded. Missing modules are
silently skipped, and shell startup never downloads anything.

The Pi Docker helper works in Bash and Zsh. The Pi and Codex Incus helpers
(and their `pi`/`codex` aliases) require Zsh and are skipped in Bash.
These helpers use the existing sandbox environments; installation only downloads
shell helpers, not Docker images or Incus instances.

To remove a module, delete its file and start a new shell (already loaded
functions and aliases remain in the current shell):

```sh
rm ~/.config/aliases.d/pi.sh
rm ~/.config/aliases.d/codex.sh
```

## starship prompt

`sudo apt install starship`\
`wget https://raw.githubusercontent.com/erathaowl/configs/main/.config/starship.toml`

*https://starship.rs/*
*https://github.com/starship/starship*


## tmux customization

`sudo apt install tmux`\
`wget https://raw.githubusercontent.com/erathaowl/configs/main/tmux/lite/.tmux.conf`

*https://github.com/gpakosz/.tmux*

## gsudo (windows)

https://github.com/gerardog/gsudo


## Nerd Fonts

https://www.nerdfonts.com/

https://github.com/ryanoasis/nerd-fonts
