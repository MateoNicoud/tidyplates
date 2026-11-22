# Tidy Plates (WoW Forever fork)

A nameplate replacement addon for World of Warcraft, ported to the WoW Forever client.

## Language

**Plate**:
One nameplate frame attached to a unit in the game world.
_Avoid_: Nameplate frame, bar

**Theme**:
A table registered in `TidyPlatesThemeList` that defines how a Plate looks.
_Avoid_: Skin, style pack

**Hub**:
The shared configuration panel and behaviour layer that Themes plug into.
_Avoid_: Settings addon, options panel

**Profile**:
A saved set of Hub settings.
_Avoid_: Preset, config

**Widget**:
An optional extra element drawn on a Plate, such as auras, class icon or threat line.
_Avoid_: Plugin, module

**Forever**:
The target client, WoW Forever (Interface 16001).
_Avoid_: Camelot, Classic
