#!/usr/bin/env bash
# Remove the symlinks install.sh created. Does NOT delete your stored secrets —
# they live in the Keychain. To purge those first: run `secret list`, then
# `secret rm <name>` for each, before uninstalling.
set -euo pipefail

bin="$HOME/.local/bin/secret"
if [[ -e "$bin" || -L "$bin" ]]; then
  rm -f "$bin"; echo "Removed $bin"
else
  echo "Not found: $bin"
fi

found=0
for d in $(zsh -c 'print -l $fpath' 2>/dev/null); do
  comp="$d/_secret"
  if [[ -e "$comp" || -L "$comp" ]]; then
    rm -f "$comp"; echo "Removed $comp"; found=1
  fi
done
[[ $found -eq 0 ]] && echo "No _secret completion found on \$fpath"

bashcomp="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/secret"
if [[ -e "$bashcomp" || -L "$bashcomp" ]]; then
  rm -f "$bashcomp"; echo "Removed $bashcomp"
fi

echo "Done. Stored secrets remain in the Keychain."
