#!/usr/bin/env bash
# Prints each new Tidy Plates error as one line, whenever the game rewrites the error log.
# The game writes saved variables on /reload and on logout, so errors arrive after a /reload.
# Usage: scripts/watch-errors.sh [path to the TidyPlates.lua saved variables file]
# Without an argument it looks in the client folder named by FOREVER_DIR or by .forever-path (git ignores that file).
set -u
cd "$(dirname "$0")/.."
forever="${FOREVER_DIR:-}"
[ -z "$forever" ] && [ -f .forever-path ] && forever=$(head -n 1 .forever-path)
default=""
[ -n "$forever" ] && default=$(ls "$forever"/WTF/Account/*/SavedVariables/TidyPlates.lua 2>/dev/null | head -1)
file="${1:-$default}"
[ -n "$file" ] || { echo "no saved variables file yet: pass its path, or set FOREVER_DIR / .forever-path and /reload once in game" >&2; exit 1; }
seen=$(mktemp); trap 'rm -f "$seen"' EXIT
last=""
while true; do
  mtime=$(stat -c %Y "$file" 2>/dev/null || true)
  if [ -n "$mtime" ] && [ "$mtime" != "$last" ]; then
    last="$mtime"
    lua5.1 - "$file" "$seen" <<'LUA'
local path, seenPath = arg[1], arg[2]
local env = {}
local chunk = loadfile(path)
if not chunk then return end
setfenv(chunk, env); pcall(chunk)
local seen, f = {}, io.open(seenPath, "r")
if f then for line in f:lines() do seen[line] = true end f:close() end
local out = io.open(seenPath, "a")
for _, entry in ipairs(env.TidyPlatesErrorLog or {}) do
  local key = (entry:gsub("\n", " "))
  if not seen[key] then
    out:write(key, "\n")
    local lines = {}
    for l in entry:gmatch("[^\n]+") do lines[#lines + 1] = l; if #lines == 4 then break end end
    print(table.concat(lines, " | "))
  end
end
out:close()
LUA
  fi
  sleep 2
done
