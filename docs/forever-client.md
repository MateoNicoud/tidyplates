# The Forever client: what breaks and how the code handles it

Read this before porting or touching code that reads units, auras, casts, frames or options. Everything here was
verified in the game while rendering Plates (issue #3); the reference addons are Plater and ThreatPlates (reimplement, never paste: ADR 0002).

## Shim file

`TidyPlates/TidyPlatesForever.lua` loads first. It holds the `TidyPlatesForever` flag, the polyfills below,
`TidyPlatesEnableBackdrop(frame)`, the `/tidydebug` switch, the blocked-action reporter (active while `/tidydebug` is on),
and the error log (`TidyPlatesErrorLog` saved variable: read `WTF/Account/<account>/SavedVariables/TidyPlates.lua` after a `/reload`).
Add a new polyfill there, once, and list it in `.luacheckrc` `globals`.

## Secret values

The client hides enemy health, cast times and the non-interruptible flag behind secret values: Lua cannot compare, calculate
with or branch on them. Pass them only to widget APIs (`StatusBar:SetValue`, `SetTimerDuration`, `SetAlphaFromBoolean`,
`FontString:SetText`). Test with `issecretvalue`.

- The core stores raw health on `extended` (`healthRaw`, `healthmaxRaw`) for the bar only. `unit.health` and `unit.healthmax` hold plain
  numbers (1 and 1 when secret), because the core compares `unit` against its cache and the Hub compares health.
- Cast timing comes from `UnitCastingDuration` / `UnitChannelDuration` driving the bar with `SetTimerDuration`.
- Addon code and slash commands cannot read secret auras (`GetAuraDataByIndex`, `GetUnitAuras` are refused). The client has
  `CustomAuraContainerTemplate` (an `AuraContainer` it fills and draws); that is the route for auras (issue #5).

## Forbidden and protected things

- `COMBAT_LOG_EVENT_UNFILTERED` cannot be registered: it raises a blocked-action popup, and a `pcall` does not prevent it.
- The Blizzard nameplate `UnitFrame` can be protected or forbidden: hide it with alpha, after `IsForbidden()`; never `Hide()` it.
- `nameplateMaxDistance` (accepts up to 60) and other nameplate CVars are combat-protected: write them out of combat only.
- Unit events fire for every unit token; `C_NamePlate.GetNamePlateForUnit` raises on anything but `nameplateN` (the core filters).
- The event handler calls `fn(event, ...)`: a plain function gets the event name first.

## Missing or changed APIs

Specialization globals, `InterfaceOptions_*`, `UnitAura`, `GetSpellInfo`, `GetAddOnMetadata` are gone or moved (polyfilled).
Frames need `BackdropTemplate` for `SetBackdrop`. `SetFont` flags reject `"NONE"`; `SetJustifyV` takes `MIDDLE`, not `CENTER`.
There are no class specializations: a Talent group (two of them) and the Group role replace them (`GLOSSARY.md`).

## Testing

Tell the scripts where your client is, once: set `FOREVER_DIR` to its `_forever_` folder, or write that path in `.forever-path` at the repo root (git ignores it). Then copy the addons with `scripts/deploy-forever.sh` and `/reload`. `scripts/check.sh` flags the calls above before the game does.
