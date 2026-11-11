# Shell aliases and optional modules

[.aliases.sh](.aliases.sh) is the core configuration for interactive Bash and
Zsh sessions. It provides everyday aliases and functions without requiring Pi,
Codex, Docker, or Incus. The optional [Pi](modules/pi.sh) and
[Codex](modules/codex.sh) modules add sandbox helpers independently.

The configuration primarily targets Linux and GNU command-line tools. Loading
it does not install the commands referenced by its aliases.

## Install the core

Download the core directly from GitHub:

```sh
wget -qO ~/.bash_aliases https://raw.githubusercontent.com/erathaowl/configs/main/bash/.aliases.sh
. ~/.bash_aliases
```

This overwrites `~/.bash_aliases`. Back up an existing custom file first. If
`~/.bash_aliases` is a symlink, the download writes to its target.

For automatic loading, ensure the following block is present in `~/.bashrc`
for Bash, or add it to `~/.zshrc` for Zsh:

```sh
if [ -f "$HOME/.bash_aliases" ]; then
    . "$HOME/.bash_aliases"
fi
```

Many Bash installations already have this block. Do not add it twice.
Start a new shell or source the file to apply changes to the current session.

### Existing installer layout

The repository's `install.sh` uses the same core with a different storage path:

```text
~/.config/.user_aliases       # Downloaded core
~/.bash_aliases              # Symlink to ~/.config/.user_aliases
~/.config/aliases.d/pi.sh    # Optional Pi module
~/.config/aliases.d/codex.sh # Optional Codex module
```

Both a standalone `~/.bash_aliases` and the symlink layout work. Module paths
are always relative to `$HOME`, not to the location of the core file.

## What the core contains

### Shell setup and history

| Name | Behavior |
| --- | --- |
| Bash completion | Enables case-insensitive completion through `bind`. |
| `fcp` in Bash | Starts an interactive child Bash with `HISTFILE=/dev/null`, avoiding normal history-file persistence for that child. Exit it to return to the parent shell. |
| `fcp` in Zsh | Calls `fc -p` to push the current history context and switch to a new one. This is not a child shell. |
| `gistory` | Legacy shortcut for filtering shell history with case-insensitive `grep`; see the limitations below. |
| `nohistory` | Bash-oriented shortcut to disable history, delete the latest entry, and optionally make the current tmux pane background dark red. |
| `delhist [index]` | Deletes a history entry, defaulting to `-1`. Requires `HISTFILE` and a nonzero integer index. Uses Bash history deletion/write operations or Zsh history filtering and context operations. Returns `2` for an invalid index and `1` if history is unavailable or the operation fails. |

History helpers affect shell history, not terminal scrollback, audit logs,
application logs, or other running shells. Do not treat them as a secrecy or
security boundary.

### Files, directories, and display

| Name | Behavior |
| --- | --- |
| `sudo` | Adds a trailing space to the alias so the following command word can also undergo alias expansion. |
| `untar` | Runs `tar -xvf`; provide an archive name and any additional arguments. |
| `cd..` | Changes to the parent directory. |
| `rcp`, `rcpv` | Copy with `rsync`, preserving many file attributes but not owner/group. Both show progress; `rcpv` adds verbose file-list output. |
| `df`, `du` | Request human-readable sizes with `-h`. |
| `mksdir` | Runs `mkdir -pv`, creating missing parents and reporting created directories. |
| `ls`, `ll` | Use `eza` with directories first when available. Otherwise use GNU `ls --color=auto` and `ls -alFh`. |
| `grep`, `egrep`, `fgrep` | Enable automatic color output. |
| `gless` | Runs `less -G`, disabling highlighting of search matches. |
| `gview` | Opens `view` at the end of the file. |
| `cat`, `bat` | Defined when `batcat` is installed. `cat` uses plain output without paging; `bat` disables paging but retains its normal presentation. |
| `sha1`, `md5`, `sha512`, `sha256` | Shortcuts to the corresponding `*sum` utilities. |
| `vu` | Defined when `veracrypt` is installed; runs `veracrypt -u`. |
| `nano` | Function that always enables cursor-position display with `-c`. With exactly one argument, passes its resolved absolute path as `NANO_CURRENT_FILE` to nano, supporting the repository's custom nanorc workflow. Multiple arguments are forwarded without setting that variable. |

Conditional aliases are chosen when the core is sourced. Source it again after
installing a tool such as `eza`, `batcat`, `veracrypt`, or `uv`.

### Networking and system maintenance

| Name | Behavior |
| --- | --- |
| `ip` | Runs `ip -c` for colored output. |
| `iplist`, `ipa` | Show brief interface addresses. |
| `maclist`, `ipm` | Intended to show interface MAC addresses; see the legacy quoting limitation below. |
| `routelist`, `ipr` | Show the routing table with color. |
| `ipp` | Runs `ss -tulpn` to list listening TCP/UDP sockets and process information. |
| `ipar` | Runs the address listing, prints a blank line, then shows routes. |
| `ipscan <IP-or-subnet>` | Runs an ICMP discovery scan through `nmap -sn -PE`, printing addresses reported as up. Only scan networks you are authorized to inspect. |
| `watchc` | Legacy colored-watch shortcut; see the limitations below. |
| `supdate` | Debian/Ubuntu-oriented privileged maintenance: updates apt metadata, lists upgrades, waits for Enter or ten seconds, then runs a noninteractive dist-upgrade, autoremove, and clean. Review before using: this changes installed packages. |
| `sspeedtest` | Downloads a third-party Python speed-test script with `curl` and executes it through `python3`. This performs network access when invoked and runs remote code without saving it for review. |

### Development helpers

| Name | Behavior |
| --- | --- |
| `uvr`, `uvp`, `uvm` | Defined when `uv` is installed; run `uv run`, `uv run python`, and `uv run python manage.py`. |
| `pycclean` | Recursively deletes Python `.pyc`/`.pyo` files and `__pycache__` directories below the current directory. There is no confirmation prompt. |
| `docker-ps` | Lists all Docker containers in an ID/name/status table, highlighting running and exited containers. It remains in the core and needs Docker only when invoked. |
| `lazygit "message" [-np]` | Interactive Git status/review/commit helper. Offers diff and per-file review prompts, then runs `git add .` and commits. By default it also pushes; `-np` skips the push. It can stage unrelated changes under the current directory, so inspect the working tree first. |
| `aliases-install <pi\|codex>` | Installs or updates one optional module, as described below. |

To inspect the active definition of a command, use `type name` or `alias name`.
Use `command nano`, `command ls`, `command pi`, or `command codex` to bypass
these shell functions/aliases and invoke the underlying executable, if installed.

### Compatibility and existing limitations

The core can be sourced in Bash and Zsh, but some individual shortcuts retain
Bash-specific or Linux-specific behavior:

- Bash's `bind` can warn that line editing is not enabled when the file is
  sourced non-interactively. This configuration is intended for interactive use.
- `nohistory` and `supdate` use Bash-oriented history/read options; loading them
  in Zsh does not make those operations portable.
- `gistory` expands `$1` when the alias is defined rather than when it is used.
  `maclist` also retains problematic quoting around its embedded awk program.
  Inspect these definitions before relying on their output.
- `watchc` currently contains the literal `SYSTEMD?COLORS=1` argument rather than
  a valid environment assignment. It may not run the intended command.

These notes describe existing code; the module split does not rewrite these
shortcuts.

## Optional module lifecycle

The modules are intended for machines with the corresponding sandbox already
configured. Basic machines can use only the core. Neither module installs an
agent, builds an image, creates an Incus instance, or configures credentials.

### Install and update

From a shell where the core is loaded:

```sh
aliases-install pi
aliases-install codex
```

Install either module or both. Running the same command again updates that
module by replacing its local file; local edits to that module are overwritten.

The installer:

1. Accepts exactly one name: `pi` or `codex`.
2. Creates `~/.config/aliases.d/` if needed.
3. Uses `wget` to download from
   `https://raw.githubusercontent.com/erathaowl/configs/main/bash/modules/<name>.sh`.
4. Downloads to a temporary file in that directory and replaces `<name>.sh`
   only after a successful download. A failed download leaves the existing
   module intact.
5. Sources the installed file immediately. Each module guards its Zsh-only
   definitions, so installation from Bash is safe.

The installer returns `2` for invalid usage and `1` for download/filesystem
failures; on successful installation it returns the result of sourcing the
module (normally `0`). Core updates and module updates are separate operations.

### Automatic loading

At the end of each core load, it checks and sources these files in order:

1. `~/.config/aliases.d/pi.sh`
2. `~/.config/aliases.d/codex.sh`

Missing files or directories are silently skipped. Other filenames in
`aliases.d` are not loaded. Sourcing the core or either supplied module does
not download anything or start a sandbox. Network access occurs only when a
command that needs it is invoked.

Modules are executable shell code sourced into your current shell. Only install
files you trust. When active in Zsh, their `pi` and `codex` aliases override bare
commands with the same names.

### Remove

Delete only the module you no longer want:

```sh
rm ~/.config/aliases.d/pi.sh
# Or:
rm ~/.config/aliases.d/codex.sh
```

Then open a new shell. Deleting a file, or reloading the core after deletion,
does not undefine functions and aliases already loaded in the current session.

## Pi module

### Docker helper: Bash and Zsh

```sh
pi-sandbox-docker
pi-sandbox-docker --help
```

`pi-sandbox-docker` runs an interactive, automatically removed container from
the existing `pi-sandbox` image. It mounts:

- The current host directory at `/workspace`, writable.
- The named Docker volume `pi-agent-home` at `/root/.pi/agent` for persistent
  agent state.

Arguments are passed to the image's configured entrypoint. Docker must be
installed and usable by the current user, and the image must be available.
This helper does not define the `pi` alias in Bash.

### Shared Incus helper: Zsh only

```sh
pi                         # Run Pi in the current project
pi --help                  # Forward arguments to Pi
pi shell                   # Open Bash inside the mounted project
pi shell -lc 'pwd'         # Pass arguments to that Bash
pi list                    # Formatted package listing
```

`pi` aliases `pi-sandbox-incus-shared`. It uses the existing Incus instance
`pi-sandbox`, starting it if necessary. The current directory is resolved to an
absolute path and mounted read-write at `/ws/<safe-project-name>-<hash>` using
a shifted disk device named `piw-<safe-project-name>-<hash>`. The hash is the
first five characters of the path's SHA-256 checksum.

Normal arguments go to the container's `pi` command with the mounted project as
its working directory. The special first arguments are:

- `shell`: runs Bash in the project and forwards the remaining arguments.
- `list`: runs `pi list` from `/workspace` and formats package names, paths, and
  available versions read from `package.json` with Node.js.

The Incus CLI, suitable device permissions/ID-mapping support, and the configured
instance with Pi installed must already exist. The helpers also use host tools
such as `realpath`, `sha256sum`, `sed`, `cut`, and `grep`.

## Codex module

### Shared Incus helper: Zsh only

```sh
codex                      # Run Codex in the current project
codex --help               # Forward arguments to Codex
codex shell                # Open Bash inside the mounted project
codex shell -lc 'pwd'      # Pass arguments to that Bash
```

`codex` aliases `codex-sandbox-shared`. It follows the same project-mounting
approach as the Pi Incus helper, but uses instance `codex-sandbox` and device
prefix `cdxw-`. Normal arguments are passed to the container's `codex` command;
`shell` is the only special first argument. There is no Codex Docker helper or
special package-list formatting in this module.

The existing instance must contain Codex and its required configuration and
credentials. Installing this module in Bash saves it for future Zsh sessions,
but defines no Codex function or alias in Bash.

## Shared Incus lifecycle and safety

Both Incus helpers use Zsh's local traps and cleanup functions. They are omitted
entirely in Bash rather than attempting a partial Bash implementation.

On the normal cleanup path, and through handlers for `INT`, `TERM`, and `HUP`,
the helper attempts to:

1. Restore ownership within the mounted project using the project's root
   directory ownership as the reference, without crossing filesystem boundaries.
2. Remove its project disk device.
3. Count remaining workspace devices for that agent and stop the instance if
   none remain; otherwise report that it is still running.

The agent or shell exit status is returned on the normal completion path. A
project already mounted in a running instance is rejected; a matching stale
device on a stopped instance is removed before retrying. Different project
mounts can share the same agent instance.

These are shared-instance convenience helpers, not a guarantee of cleanup or
isolation between sessions. Abrupt termination, command failures, or concurrent
operations can leave resources requiring manual inspection. The mounted host
project is writable by the agent, and cleanup changes ownership recursively;
do not use projects requiring preservation of mixed file ownership without
reviewing that behavior. Avoid concurrent operations on the same project.

## Other files in this directory

- [.bash_addons](.bash_addons) is a separate **Bash-only** customization file.
  It sets history sizes, enables `histappend`, configures `PROMPT_COMMAND` to
  save/clear/reload history after commands, and disables terminal Ctrl+S flow
  control with `stty -ixon`. It is not loaded by `.aliases.sh`; `install.sh`
  installs it separately and adds a source line to the user's `.bashrc`.
- [.bash_starship](.bash_starship) is a separate Starship initialization snippet,
  conditional on `starship` being installed. It is not an aliases module and is
  not loaded by the core.
