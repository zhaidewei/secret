#!/usr/bin/env bash
# Install `secret` CLI + zsh completion via symlinks (so they track this repo).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/bin"
ln -sf "$SCRIPT_DIR/secret" "$HOME/.local/bin/secret"
echo "Linked secret      -> $HOME/.local/bin/secret"

# First writable dir on zsh's $fpath, else the common Intel-homebrew location.
COMP_DIR="${ZSH_COMPLETION_DIR:-}"
if [[ -z "$COMP_DIR" ]]; then
  for d in $(zsh -c 'print -l $fpath' 2>/dev/null); do
    [[ -d "$d" && -w "$d" ]] && { COMP_DIR="$d"; break; }
  done
fi

if [[ -n "$COMP_DIR" && -w "$COMP_DIR" ]]; then
  ln -sf "$SCRIPT_DIR/_secret" "$COMP_DIR/_secret"
  echo "Linked zsh comp    -> $COMP_DIR/_secret"
  echo "Reload zsh:        rm -f ~/.zcompdump*; exec zsh"
else
  echo "No writable \$fpath dir found; copy _secret into one manually, e.g.:"
  echo "  mkdir -p ~/.zfunc && cp '$SCRIPT_DIR/_secret' ~/.zfunc/ && echo 'fpath=(~/.zfunc \$fpath)' >> ~/.zshrc"
fi

# bash: bash-completion v2 auto-loads $XDG_DATA_HOME/bash-completion/completions/<cmd>.
BASH_COMP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
mkdir -p "$BASH_COMP_DIR"
ln -sf "$SCRIPT_DIR/secret.bash" "$BASH_COMP_DIR/secret"
echo "Linked bash comp   -> $BASH_COMP_DIR/secret"
echo "Reload bash:       exec bash  (needs the bash-completion package)"
