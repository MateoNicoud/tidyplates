# Linting and checks

`scripts/check.sh` checks the changed Lua files (`--staged` in the pre-commit hook, `--all` for everything):

- `luacheck` with `.luacheckrc` (WoW globals; style noise is switched off). Undefined globals (W113) catch calls to APIs the client does not have. Warnings are informational until issue #14 clears the old ones; `CHECK_STRICT=1` makes them fail.
- mixed CRLF/LF line endings inside one file, and a file whose style differs from its base version (the repo mixes both across files; never convert a file)
- calls the Forever client rejects (see `docs/forever-client.md`)

Install luacheck with `luarocks --local install luacheck` (then `export PATH="$HOME/.luarocks/bin:$PATH"`). Add new WoW API globals to `read_globals`, and globals the addons define to `globals`, in `.luacheckrc`. CI runs the same script (`.github/workflows/check.yml`).
