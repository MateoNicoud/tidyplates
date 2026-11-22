#!/usr/bin/env bash
# Copies every TidyPlates* addon into the WoW Forever client, then /reload in game.
# Where the client lives is machine-specific, so it is not in the repo: set FOREVER_DIR (the client's _forever_ folder)
# or put that path in a file named .forever-path at the repo root (git ignores it).
# Copies over the existing folders and never deletes anything: remove a stale file by hand if you delete one here.
set -eu
cd "$(dirname "$0")/.."
forever="${FOREVER_DIR:-}"
[ -z "$forever" ] && [ -f .forever-path ] && forever=$(head -n 1 .forever-path)
[ -n "$forever" ] || { echo "Set FOREVER_DIR or write the path of the client's _forever_ folder in .forever-path" >&2; exit 1; }
dest="$forever/Interface/AddOns"
[ -d "$dest" ] || { echo "Forever AddOns folder not found: $dest" >&2; exit 1; }
for addon in TidyPlates TidyPlatesHub TidyPlatesWidgets TidyPlates_Graphite TidyPlates_Grey TidyPlates_Neon TidyPlates_Quatre; do
  mkdir -p "$dest/$addon"
  cp -rf "$addon/." "$dest/$addon/"
done
echo "Copied to $dest"
