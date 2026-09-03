#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly REPO_DIR
test_root="$(mktemp -d "${TMPDIR:-/tmp}/terminal-setup-test.XXXXXX")"
trap 'rm -rf "$test_root"' EXIT

test_home="$test_root/home"
mkdir -p "$test_home"
cat >"$test_home/.zshrc" <<'EOF'
# existing user configuration
# terminal-ergonomics START
alias legacy-terminal-setup='true'
# terminal-ergonomics END
# trailing user configuration
EOF
cp "$test_home/.zshrc" "$test_root/original-zshrc"

bash -n "$REPO_DIR/install.sh"
zsh -n "$REPO_DIR/config/zshrc-terminal-ergonomics.sh"

HOME="$test_home" PATH=/usr/bin:/bin \
  "$REPO_DIR/install.sh" --skip-packages >/dev/null
first_checksum="$(cksum "$test_home/.zshrc")"

HOME="$test_home" PATH=/usr/bin:/bin \
  "$REPO_DIR/install.sh" --skip-packages >/dev/null
second_checksum="$(cksum "$test_home/.zshrc")"

[[ "$first_checksum" == "$second_checksum" ]]
[[ "$(grep -Fxc '# terminal-ergonomics START' "$test_home/.zshrc")" -eq 1 ]]
[[ "$(grep -Fxc '# terminal-ergonomics END' "$test_home/.zshrc")" -eq 1 ]]
grep -Fq '# existing user configuration' "$test_home/.zshrc"
grep -Fq '# trailing user configuration' "$test_home/.zshrc"
if grep -Fq 'legacy-terminal-setup' "$test_home/.zshrc"; then
  printf 'legacy terminal-setup block was not removed\n' >&2
  exit 1
fi
grep -Fq "$REPO_DIR" "$test_home/.zshrc"
cmp -s "$test_root/original-zshrc" "$test_home/.zshrc.terminal-setup.bak"

HOME="$test_home" PATH=/usr/bin:/bin /bin/zsh -f -c \
  'source "$HOME/.zshrc"'

printf 'terminal-setup tests passed\n'
