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
  echo "Linked _secret     -> $COMP_DIR/_secret"
  echo "Reload completion: rm -f ~/.zcompdump*; exec zsh"
else
  echo "No writable \$fpath dir found; copy _secret into one manually, e.g.:"
  echo "  mkdir -p ~/.zfunc && cp '$SCRIPT_DIR/_secret' ~/.zfunc/ && echo 'fpath=(~/.zfunc \$fpath)' >> ~/.zshrc"
fi
