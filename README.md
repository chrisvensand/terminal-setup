# terminal-setup

My macOS and Linux zsh configuration, tuned for a workflow that runs
everything through the VS Code built-in terminal (so no tmux/zellij—VS Code's
own tabs, panes, and shell integration already cover that).

The setup is installed explicitly on each machine. It does not modify arbitrary
SSH hosts or copy configuration during SSH login.

## Supported systems

- macOS on Apple Silicon or Intel, using Homebrew.
- Linux distributions using `apt` (Debian/Ubuntu), `dnf` (Fedora/RHEL), or
  `pacman` (Arch).
- Other Linux distributions can use `./install.sh --skip-packages` after the
  dependencies have been installed manually.

The shell configuration itself is portable across macOS and Linux. Optional
features stay disabled instead of breaking shell startup when a tool is not
installed.

## What's included

| Tool | Purpose |
|---|---|
| [`starship`](https://starship.rs) | Prompt: short cwd, git branch/status, command duration, Python venv (only when active) |
| [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) | Ghost-text command suggestions from history |
| [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) | Colors valid/invalid commands as you type |
| [`fzf`](https://github.com/junegunn/fzf) | Fuzzy history search (`Ctrl-R`) and file search (`Ctrl-T`) |
| [`zoxide`](https://github.com/ajeetdsouza/zoxide) | Smarter `cd`—jumps to frequently used directories via `z` |
| [`ripgrep`](https://github.com/BurntSushi/ripgrep) | Fast `grep` replacement (`rg`) |
| [`fd`](https://github.com/sharkdp/fd) | Friendlier/faster `find` |
| [`bat`](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [`eza`](https://github.com/eza-community/eza) | `ls` with icons, git status, and tree view |
| [`git-delta`](https://github.com/dandavison/delta) | Improved `git diff` output |

## Install on a new machine

Clone the repository, then run its installer:

```bash
git clone https://github.com/chrisvensand/terminal-setup.git ~/.terminal-setup
~/.terminal-setup/install.sh
exec zsh
```

The HTTPS clone works without credentials once the repository is public. While
it remains private, use an authenticated GitHub SSH URL instead:

```bash
git clone git@github.com:chrisvensand/terminal-setup.git ~/.terminal-setup
```

The installer:

1. Installs available dependencies using Homebrew, apt, dnf, or pacman.
2. Installs Starship into `~/.local/bin` on Linux when the distro does not
   package it.
3. Adds a managed source block to `~/.zshrc`, preserving the rest of the file.
4. Points Starship at this repository's `config/starship.toml`.
5. Includes `config/gitconfig-delta.txt` from the global Git configuration when
   delta is available.

It is safe to run repeatedly. When it changes `~/.zshrc`, it retains the
previous version as `~/.zshrc.terminal-setup.bak`. It does not change the login
shell automatically; if desired, do that explicitly:

```bash
chsh -s "$(command -v zsh)"
```

To configure files without installing packages:

```bash
./install.sh --skip-packages
```

On older Debian/Ubuntu releases, `bat` and `fd` are installed as `batcat` and
`fdfind`; the zsh configuration supplies the expected aliases automatically.
Likewise, it uses `exa` when `eza` is unavailable.

## Update an existing machine

```bash
git -C ~/.terminal-setup pull --ff-only
~/.terminal-setup/install.sh
```

## Daily-use cheatsheet

| Key/command | Effect |
|---|---|
| `Ctrl-R` | Fuzzy-search shell history (fzf) |
| `Ctrl-T` | Fuzzy-search files in the current directory and insert the path (fzf) |
| `→` (right arrow) | Accept autosuggestion ghost text |
| `z <partial-dir-name>` | Jump to a frequently used directory (zoxide) |
| `ll` / `la` / `lt` | List files (long / all / tree, via eza or exa) |
| `cat <file>` | Syntax-highlighted view (via bat) |
| `git diff` / `git log -p` | Side-by-side, syntax-highlighted diffs (via delta) |

## Notes and rationale

- **No tmux/zellij.** These overlap with VS Code's terminal tabs/splits and can
  interfere with shell integration such as working-directory tracking and
  command-status decorations.
- **No atuin.** `fzf` and normal shell history are enough unless history needs
  to be synchronized across machines.
- **No direnv.** It is most useful when juggling multiple projects with
  different per-project environment variables.
- **Python prompt segment shows only when a venv/conda env is active.**
  `config/starship.toml` checks `VIRTUAL_ENV`, `CONDA_DEFAULT_ENV`, and
  `PYENV_VERSION` instead of triggering on every Python-related file.
