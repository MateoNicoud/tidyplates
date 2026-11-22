#!/usr/bin/env bash
# Checks every changed Lua file: luacheck, mixed line endings, and calls the Forever client rejects.
#   scripts/check.sh            files changed against origin/master (CI, manual runs)
#   scripts/check.sh --staged   staged files (pre-commit hook)
#   scripts/check.sh --all      every Lua file (many old warnings, see issue #14)
set -u
cd "$(dirname "$0")/.."
export PATH="$HOME/.luarocks/bin:$PATH"

case "${1:-}" in
  --staged) files=$(git diff --cached --name-only --diff-filter=ACM) ;;
  --all)    files=$(git ls-files '*.lua') ;;
  *)        files=$(git diff --name-only --diff-filter=ACM origin/master...HEAD 2>/dev/null; git diff --name-only --diff-filter=ACM HEAD) ;;
esac
files=$(printf '%s\n' $files | grep '\.lua$' | grep -v 'BackupCore\|_RangeWidget' | sort -u)
[ -z "$files" ] && { echo "check: no Lua files to check"; exit 0; }

status=0
fail() { echo "FAIL: $1"; status=1; }

# 1. luacheck (undefined globals catch calls to APIs the client does not have)
if command -v luacheck >/dev/null; then
  luacheck --no-color $files; rc=$?
  # Warnings are informational until issue #14 clears the old ones; set CHECK_STRICT=1 to make them fail
  if [ "$rc" -ge 2 ] || { [ "$rc" -eq 1 ] && [ "${CHECK_STRICT:-0}" = 1 ]; }; then status=1; fi
else
  fail "luacheck is not installed (luarocks --local install luacheck)"
fi

# 2. a file must not mix CRLF and LF line endings
for f in $files; do
  crlf=$(grep -c $'\r$' "$f"); total=$(wc -l < "$f")
  if [ "$crlf" -gt 0 ] && [ "$crlf" -lt "$total" ]; then fail "$f mixes CRLF and LF line endings"; fi
done

# 3. calls the Forever client rejects (see docs/forever-client.md).
# Comments are blanked first (line numbers kept), so commented-out code never matches.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
for f in $files; do
  mkdir -p "$tmp/$(dirname "$f")"
  awk 'BEGIN{c=0} { l=$0
    if (c) { if (l ~ /\]\]/) c=0; print ""; next }
    if (l ~ /--\[\[/ && l !~ /\]\]/) { c=1; print ""; next }
    sub(/--.*$/, "", l); print l }' "$f" > "$tmp/$f"
done
code=$(cd "$tmp" && ls -d $files)

bad() { # pattern, reason
  hits=$(cd "$tmp" && grep -nE "$1" $code); [ -n "$hits" ] && { echo "$hits"; fail "$2"; }
}
bad 'SetJustifyV\("CENTER"'                       'vertical justify takes TOP, MIDDLE or BOTTOM, not CENTER'
bad 'SetFont\([^)]*"NONE"'                        'SetFont flags reject "NONE"; use an empty string'
bad 'UnitFrame[A-Za-z]*:Hide\(\)|GetChildren\(\)\s*:Hide\(\)' 'hide the Blizzard UnitFrame with alpha, after an IsForbidden() check (it can be protected)'

# These two are allowed when the line before names the guard
guarded() { # pattern, guard, reason
  hits=$(cd "$tmp" && grep -nE "$1" $code | while IFS=: read -r f n _; do
    sed -n "$((n-1))p" "$f" | grep -q "$2" || echo "$f:$n"; done)
  [ -n "$hits" ] && { echo "$hits"; fail "$3"; }
}
guarded 'RegisterEvent\("COMBAT_LOG_EVENT_UNFILTERED"\)' 'TidyPlatesForever' 'the combat log cannot be registered by addons on Forever (guard it with TidyPlatesForever)'
guarded ':SetBackdrop\(' 'TidyPlatesEnableBackdrop' 'call TidyPlatesEnableBackdrop(frame) on the line before SetBackdrop'

[ $status -eq 0 ] && echo "check: OK"
exit $status
