# terminal-ergonomics START
# Shared macOS/Linux zsh configuration. Optional tools are enabled only when
# installed, so this file is safe to source on a minimally provisioned host.

# User-local binaries are where the Linux installer puts tools that are not
# available from the system package manager (currently Starship).
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH

if [[ -n "${TERMINAL_SETUP_DIR:-}" && -r "$TERMINAL_SETUP_DIR/config/starship.toml" ]]; then
  export STARSHIP_CONFIG="$TERMINAL_SETUP_DIR/config/starship.toml"
fi

# eza: nicer ls
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -lh --git'
  alias la='eza -lha --git'
  alias lt='eza --tree --level=2'
elif command -v exa >/dev/null 2>&1; then
  # Ubuntu 22.04 ships eza's predecessor under this name.
  alias ls='exa'
  alias ll='exa -lh --git'
  alias la='exa -lha --git'
  alias lt='exa --tree --level=2'
fi

# Debian/Ubuntu package fd and bat as fdfind and batcat.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
elif command -v batcat >/dev/null 2>&1; then
  alias bat='batcat'
  alias cat='batcat --paging=never'
fi

# git-delta: nicer git diff (also see gitconfig-delta.txt)

# zoxide: smarter cd (use `z` instead of `cd`)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf: fuzzy history (Ctrl-R) and file search (Ctrl-T)
if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    source <(fzf --zsh)
  elif [[ -r "$HOME/.fzf.zsh" ]]; then
    source "$HOME/.fzf.zsh"
  else
    # Older fzf releases, including the one in Ubuntu 22.04, install separate
    # completion and key-binding scripts.
    for _terminal_setup_fzf_completion in \
      /opt/homebrew/opt/fzf/shell/completion.zsh \
      /usr/local/opt/fzf/shell/completion.zsh \
      /home/linuxbrew/.linuxbrew/opt/fzf/shell/completion.zsh \
      /usr/share/doc/fzf/examples/completion.zsh \
      /usr/share/fzf/completion.zsh; do
      if [[ -r "$_terminal_setup_fzf_completion" ]]; then
        source "$_terminal_setup_fzf_completion"
        break
      fi
    done

    for _terminal_setup_fzf_bindings in \
      /opt/homebrew/opt/fzf/shell/key-bindings.zsh \
      /usr/local/opt/fzf/shell/key-bindings.zsh \
      /home/linuxbrew/.linuxbrew/opt/fzf/shell/key-bindings.zsh \
      /usr/share/doc/fzf/examples/key-bindings.zsh \
      /usr/share/fzf/key-bindings.zsh; do
      if [[ -r "$_terminal_setup_fzf_bindings" ]]; then
        source "$_terminal_setup_fzf_bindings"
        break
      fi
    done
    unset _terminal_setup_fzf_completion _terminal_setup_fzf_bindings
  fi
fi

_terminal_setup_source_first() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}

# zsh-autosuggestions: ghost-text suggestions from history. These cover
# Apple Silicon/Intel Homebrew, Linuxbrew, Debian/Ubuntu, Fedora, and Arch.
_terminal_setup_source_first \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  >/dev/null 2>&1 || true

# zsh-syntax-highlighting must be sourced after the other shell plugins.
_terminal_setup_source_first \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /home/linuxbrew/.linuxbrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "${XDG_DATA_HOME:-$HOME/.local/share}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  >/dev/null 2>&1 || true

unfunction _terminal_setup_source_first

# starship: cleaner prompt with git branch/status, short cwd, etc.
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
# terminal-ergonomics END
