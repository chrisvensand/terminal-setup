#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly REPO_DIR
readonly BLOCK_START="# terminal-ergonomics START"
readonly BLOCK_END="# terminal-ergonomics END"

skip_packages=false

log() {
  printf '[terminal-setup] %s\n' "$*"
}

warn() {
  printf '[terminal-setup] warning: %s\n' "$*" >&2
}

die() {
  printf '[terminal-setup] error: %s\n' "$*" >&2
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

usage() {
  cat <<'EOF'
Usage: ./install.sh [--skip-packages]

Installs terminal dependencies and configures the current user's zsh and Git.

Options:
  --skip-packages  Configure dotfiles without invoking a package manager.
  -h, --help       Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --skip-packages)
      skip_packages=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "unknown option: $1"
      ;;
  esac
  shift
done

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif have sudo; then
    sudo "$@"
  else
    die "installing system packages requires root or sudo"
  fi
}

install_macos_packages() {
  have brew || die "Homebrew is required on macOS: https://brew.sh"

  log "installing macOS packages with Homebrew"
  brew install \
    starship \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    fzf \
    zoxide \
    ripgrep \
    fd \
    bat \
    eza \
    git-delta
}

package_available() {
  local manager="$1"
  local package="$2"

  case "$manager" in
    apt)
      apt-cache show "$package" >/dev/null 2>&1
      ;;
    dnf)
      dnf --quiet info "$package" >/dev/null 2>&1
      ;;
    pacman)
      pacman -Si "$package" >/dev/null 2>&1
      ;;
  esac
}

append_available_package() {
  local manager="$1"
  shift

  local package
  for package in "$@"; do
    if package_available "$manager" "$package"; then
      linux_packages+=("$package")
      return 0
    fi
  done

  warn "none of these packages are available: $*"
  return 0
}

install_linux_packages() {
  local manager
  local -a desired_packages
  linux_packages=()

  if have apt-get; then
    manager=apt
    log "refreshing apt package metadata"
    run_as_root apt-get update
    desired_packages=(
      zsh git curl fzf zoxide ripgrep fd-find bat
      zsh-autosuggestions zsh-syntax-highlighting git-delta starship
    )
  elif have dnf; then
    manager=dnf
    desired_packages=(
      zsh git curl fzf zoxide ripgrep fd-find bat
      zsh-autosuggestions zsh-syntax-highlighting git-delta starship
    )
  elif have pacman; then
    manager=pacman
    desired_packages=(
      zsh git curl fzf zoxide ripgrep fd bat
      zsh-autosuggestions zsh-syntax-highlighting git-delta starship
    )
  else
    warn "no supported package manager found (apt, dnf, or pacman)"
    warn "install the tools listed in README.md, then rerun with --skip-packages"
    return
  fi

  local package
  for package in "${desired_packages[@]}"; do
    append_available_package "$manager" "$package"
  done
  append_available_package "$manager" eza exa

  if ((${#linux_packages[@]} == 0)); then
    warn "no terminal packages were available through $manager"
    return
  fi

  log "installing Linux packages with $manager"
  case "$manager" in
    apt)
      run_as_root apt-get install -y "${linux_packages[@]}"
      ;;
    dnf)
      run_as_root dnf install -y "${linux_packages[@]}"
      ;;
    pacman)
      run_as_root pacman -S --needed "${linux_packages[@]}"
      ;;
  esac
}

install_starship_fallback() {
  have starship && return
  have curl || {
    warn "Starship is not installed and curl is unavailable"
    return
  }

  log "installing Starship into $HOME/.local/bin"
  mkdir -p "$HOME/.local/bin"
  curl --proto '=https' --tlsv1.2 -sSf https://starship.rs/install.sh \
    | sh -s -- --yes --bin-dir "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
}

remove_managed_block() {
  local input="$1"
  local output="$2"

  awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
    $0 == start { skipping = 1; next }
    $0 == end && skipping { skipping = 0; next }
    !skipping {
      lines[++count] = $0
      if ($0 !~ /^[[:space:]]*$/) {
        last_content = count
      }
    }
    END {
      for (line = 1; line <= last_content; line++) {
        print lines[line]
      }
    }
  ' "$input" >"$output"
}

configure_zsh() {
  local zshrc="$HOME/.zshrc"
  local start_count=0
  local end_count=0
  local temp_file
  local add_separator=false

  mkdir -p "$HOME"
  touch "$zshrc"

  start_count="$(grep -Fxc "$BLOCK_START" "$zshrc" || true)"
  end_count="$(grep -Fxc "$BLOCK_END" "$zshrc" || true)"
  if [[ "$start_count" != "$end_count" || "$start_count" -gt 1 ]]; then
    die "$zshrc has an invalid terminal-setup block; fix it before rerunning"
  fi

  temp_file="$(mktemp "${TMPDIR:-/tmp}/terminal-setup-zshrc.XXXXXX")"
  remove_managed_block "$zshrc" "$temp_file"
  if [[ -s "$temp_file" ]]; then
    add_separator=true
  fi

  {
    if [[ "$add_separator" == true ]]; then
      printf '\n'
    fi
    printf '%s\n' "$BLOCK_START"
    printf 'TERMINAL_SETUP_DIR=%q\n' "$REPO_DIR"
    printf "source \"\$TERMINAL_SETUP_DIR/config/zshrc-terminal-ergonomics.sh\"\n"
    printf '%s\n' "$BLOCK_END"
  } >>"$temp_file"

  if cmp -s "$temp_file" "$zshrc"; then
    log "$zshrc is already configured"
  else
    cp -p "$zshrc" "$zshrc.terminal-setup.bak"
    cat "$temp_file" >"$zshrc"
    log "configured $zshrc (backup: $zshrc.terminal-setup.bak)"
  fi

  rm -f "$temp_file"
}

configure_git_delta() {
  local include_path="$REPO_DIR/config/gitconfig-delta.txt"

  if ! have git; then
    warn "Git is unavailable; skipping the delta configuration"
    return
  fi
  if ! have delta; then
    warn "delta is unavailable; skipping the Git delta configuration"
    return
  fi

  if git config --global --get-all include.path 2>/dev/null | grep -Fxq "$include_path"; then
    log "Git delta configuration is already included"
  else
    git config --global --add include.path "$include_path"
    log "included Git delta configuration from $include_path"
  fi
}

report_tools() {
  local label
  local found
  local -a alternatives

  printf '\nInstalled tools:\n'
  while (($#)); do
    label="$1"
    shift
    IFS=',' read -r -a alternatives <<<"$1"
    shift
    found=''
    local candidate
    for candidate in "${alternatives[@]}"; do
      if have "$candidate"; then
        found="$(command -v "$candidate")"
        break
      fi
    done
    if [[ -n "$found" ]]; then
      printf '  %-12s %s\n' "$label" "$found"
    else
      printf '  %-12s missing (feature will remain disabled)\n' "$label"
    fi
  done
}

if [[ "$skip_packages" == false ]]; then
  case "$(uname -s)" in
    Darwin)
      install_macos_packages
      ;;
    Linux)
      install_linux_packages
      install_starship_fallback
      ;;
    *)
      die "unsupported operating system: $(uname -s)"
      ;;
  esac
fi

configure_zsh
configure_git_delta

report_tools \
  zsh zsh \
  starship starship \
  fzf fzf \
  zoxide zoxide \
  ripgrep rg \
  fd fd,fdfind \
  bat bat,batcat \
  eza eza,exa \
  delta delta

printf '\n'
log "setup complete"
if have zsh; then
  log "start it now with: exec zsh"
  if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
    log "make it your default with: chsh -s $(command -v zsh)"
  fi
else
  warn "zsh is not installed; install it before using this configuration"
fi
