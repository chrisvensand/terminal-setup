# terminal-ergonomics START
# fd/ripgrep/bat/eza just work once installed, no config needed beyond aliases below

# eza: nicer ls
alias ls="eza"
alias ll="eza -lh --git"
alias la="eza -lha --git"
alias lt="eza --tree --level=2"

# bat: nicer cat
alias cat="bat --paging=never"

# git-delta: nicer git diff (also see gitconfig-delta.txt)

# zoxide: smarter cd (use `z` instead of `cd`)
eval "$(zoxide init zsh)"

# fzf: fuzzy history (Ctrl-R) and file search (Ctrl-T)
source <(fzf --zsh)

# zsh-autosuggestions: ghost-text suggestions from history
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting: MUST be sourced last
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# starship: cleaner prompt with git branch/status, short cwd, etc.
eval "$(starship init zsh)"
# terminal-ergonomics END
