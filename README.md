# terminal-setup

My macOS + zsh terminal configuration, tuned for a workflow that runs
everything through the VSCode built-in terminal (so no tmux/zellij — VSCode's
own tabs/panes and shell integration already cover that).

## What's included

| Tool | Purpose |
|---|---|
| [`starship`](https://starship.rs) | Prompt: short cwd, git branch/status, command duration, python venv (only when active) |
| [`zsh-autosuggestions`](https://github.com/zsh-users/zsh-autosuggestions) | Ghost-text command suggestions from history |
| [`zsh-syntax-highlighting`](https://github.com/zsh-users/zsh-syntax-highlighting) | Colors valid/invalid commands as you type |
| [`fzf`](https://github.com/junegunn/fzf) | Fuzzy history search (`Ctrl-R`) and file search (`Ctrl-T`) |
| [`zoxide`](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` — jumps to frequently-used dirs via `z` |
| [`ripgrep`](https://github.com/BurntSushi/ripgrep) | Fast `grep` replacement (`rg`) |
| [`fd`](https://github.com/sharkdp/fd) | Friendlier/faster `find` |
| [`bat`](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [`eza`](https://github.com/eza-community/eza) | `ls` with icons/git status/tree view |
| [`git-delta`](https://github.com/dandavison/delta) | Much nicer `git diff` output |

## Install

```bash
brew install starship zsh-autosuggestions zsh-syntax-highlighting fzf zoxide ripgrep fd bat eza git-delta
```

## Configure

1. Append `config/zshrc-terminal-ergonomics.sh` to the end of your `~/.zshrc`.
   Order matters — `zsh-syntax-highlighting` must be sourced after the other
   plugins, and `starship init` must come last of all.
2. Copy `config/starship.toml` to `~/.config/starship.toml`.
3. Append the contents of `config/gitconfig-delta.txt` to `~/.gitconfig` (or
   run the `git config --global` commands listed at the bottom of that file).
4. Restart your terminal (or run `exec zsh`) to pick up the changes.

## Daily-use cheatsheet

| Key/command | Effect |
|---|---|
| `Ctrl-R` | fuzzy-search shell history (fzf) |
| `Ctrl-T` | fuzzy-search files in cwd, inserts path (fzf) |
| `→` (right arrow) | accept autosuggestion ghost text |
| `z <partial-dir-name>` | jump to a frequently-used directory (zoxide) |
| `ll` / `la` / `lt` | list files (long / all / tree, via eza) |
| `cat <file>` | syntax-highlighted view (via bat) |
| `git diff` / `git log -p` | side-by-side, syntax-highlighted diffs (via delta) |

## Notes / rationale

- **No tmux/zellij.** Redundant with VSCode's own terminal tabs/splits, and
  can interfere with VSCode's shell integration (CWD tracking, command status
  decorations).
- **No atuin.** `fzf` + normal shell history is enough unless you specifically
  want history synced across machines.
- **No direnv.** Only worth adding if juggling multiple projects with
  different per-project env vars.
- **Python prompt segment shows only when a venv/conda env is active**
  (`config/starship.toml` restricts detection to the `VIRTUAL_ENV`,
  `CONDA_DEFAULT_ENV`, and `PYENV_VERSION` env vars, instead of the starship
  default of triggering on any `.py` file, `pyproject.toml`, etc. in the
  directory). This avoids showing a misleading "system Python 3.9.6" version
  in every Python-ish directory when no environment is actually activated,
  while still surfacing the venv name when one is.
