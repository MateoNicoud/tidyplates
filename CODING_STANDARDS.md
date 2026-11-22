# Coding standards (read by the reviewer; judgement calls only)

Mechanical rules live in `scripts/check.sh`, not here. Background: `docs/forever-client.md`.

- **Secret first.** Any value read from an enemy unit (health, cast data, auras) may be secret. Never store it in `unit`
  (the core compares `unit` with its cache) and never branch on it; hand it to a widget API.
- **Blizzard frames by alpha.** Touch a Blizzard nameplate frame only after `IsForbidden()`, and only through alpha.
- **One shim.** A missing client API is polyfilled once in `TidyPlates/TidyPlatesForever.lua`, never per call site.
- **Local by default.** A variable that is not an addon-wide global is `local`; `luacheck` W111/W113 findings on touched code are fixed, not ignored.
