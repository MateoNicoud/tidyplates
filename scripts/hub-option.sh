#!/usr/bin/env bash
# Finds a Hub option by the words shown in the panel: prints the label, the saved variable key and the line.
#   scripts/hub-option.sh "status text"
set -u
cd "$(dirname "$0")/.."
[ $# -ge 1 ] || { echo "usage: scripts/hub-option.sh <words from the option's label>" >&2; exit 1; }
grep -n -i -E 'CreateQuick[A-Za-z]+\(objectName\.\.' TidyPlatesHub/Hub.lua | grep -i -- "$*" \
  | sed -E 's/^([0-9]+):.*objectName\.\."([A-Za-z0-9_]+)", *(c[A-Za-z]+\.\.)?"([^"]*)".*/TidyPlatesHub\/Hub.lua:\1  key=\2  label="\4"/'
