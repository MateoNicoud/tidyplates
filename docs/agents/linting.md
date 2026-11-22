# Linting

Run `luacheck` from the repo root (config: `.luacheckrc`):

```bash
luacheck TidyPlates TidyPlatesWidgets TidyPlatesHub TidyPlates_Neon TidyPlates_Grey TidyPlates_Graphite TidyPlates_Quatre
```

Install with `luarocks install luacheck`. Add new WoW API globals to `read_globals` in `.luacheckrc` as they are used.
