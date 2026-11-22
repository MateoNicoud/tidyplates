# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Tidy Plates (v6.19.2) is a World of Warcraft nameplate replacement addon (Interface 80000), written in Lua + Blizzard XML. The repo root holds several sibling addon folders; each is installed separately into `Interface/AddOns/`. There is no build system, linter, or test suite — code runs only inside the WoW client.

## Commands

- Package a release (from the repo root, per `TidyPlates/TidyPlatesChanges.log`): `zip -vr TP_Release.zip TidyPlates* -x@exclude.lst` (`exclude.lst` is not in the repo; it excludes `.svn`, `.DS_Store`, images, `.txt`, `.zip`, etc.)
- Dev install: copy/symlink every `TidyPlates*` folder into the WoW `Interface/AddOns/` directory, then `/reload` in game.
- In-game: `/hub` opens the Hub config panel. Set the global `TidyPlatesDebug` to enable debug prints in the core.
- Record user-facing changes at the top of `TidyPlates/TidyPlatesChanges.log` and bump `## Version` in `TidyPlates.toc` for releases.

## Architecture

Addon dependency chain (declared in each `.toc`): `TidyPlates` (core) → `TidyPlatesWidgets` → `TidyPlatesHub` → theme addons (`TidyPlates_Neon`, `_Grey`, `_Graphite`, `_Quatre`).

- **`TidyPlates/`** — the engine. `TidyPlates.xml` is the load manifest (the `.toc` lists only the XML) and sets the Lua file order: Statusbar, Core, Utility, Template, Parser, Panel. `TidyPlatesCore.lua` hooks Blizzard nameplate frames, builds the per-plate visual elements, and runs the update loop (flags like `UpdateMe` / `UpdateAll` / `ResetPlates` are set by `TidyPlates:RequestUpdate/Update/ForceUpdate`, and processed on the next frame). `TidyPlatesParser.lua` activates themes by name; `TidyPlatesPanel.lua` is the theme-selection options panel; `TidyPlatesUtility.lua` has shared helpers and the `PanelHelpers` UI builders. `BackupCore.lua` is not referenced by the XML — it is an old copy of the core and is not loaded.
- **Theme contract**: a theme is a table registered via `TidyPlatesThemeList[ThemeName] = Theme` (see the end of `Neon.lua`, `Grey.lua`, etc.). It defines the frame-element specs (`hitbox`, `highlight`, `healthborder`, …; `TidyPlatesTemplate.lua` is the reference template/defaults) plus optional callbacks (`SetStyle`, `SetScale`, `SetAlpha`, `SetHealthbarColor`, …) that the core calls per plate on update, and an optional `OnActivateTheme` that the parser calls on switch. Hub-enabled themes get most callbacks injected by the Hub rather than defining them.
- **`TidyPlatesHub/`** — a shared config panel and behaviour layer for the themes. `Defaults.lua` and `Templates.lua` define the settings and the RapidPanel UI builder (widgets are stacked on "rails" that share one callback). `functions/*.lua` (Core, Filter, Style, Alpha, Scale, Color, Text, Widgets) implement the callbacks that a Hub-enabled theme plugs in; `functions/Core.lua` `ApplyHubFunctions(theme)` assigns them onto the theme table (`SetScale`, `SetAlpha`, `SetStyle`, `SetHealthbarColor`, `SetNameColor`, `SetThreatColor`, `SetCastbarColor`, `SetCustomText`, `OnUpdate`, `OnContextUpdate`, `ApplyProfileSettings`, `OnChangeProfile`, …). `Menus.lua` is empty and not loaded; `functions/EnableWatchers.lua` is not in the `.toc`. Load order matters: it is the `.toc` order. Saved variables: `TidyPlatesHubSettings` (per character), `TidyPlatesHubGlobal`, `TidyPlatesHubCache`.
- **`TidyPlatesWidgets/`** — a library of optional per-plate widgets (aura, class icon, combo/combat, threat line, totem, tank/healer tracking). `Widgets.xml` is the load manifest; the Hub's `functions/Widgets.lua` creates and positions them on plates. `_RangeWidget.lua` is unused (underscore-prefixed, not in the manifest).
- **Theme addons** — each is one Lua file plus `.tga` textures, loaded through its `.toc`. They reference textures by `Interface\Addons\<Folder>\...` paths, so renaming a folder breaks the art.

When adding a Lua file, add it to the matching `.toc` or `.xml` manifest, or it will not load. Lua here is the WoW 5.1-flavoured runtime, so there is no `require`; addons share state through globals (`TidyPlates`, `TidyPlatesUtility`, `TidyPlatesThemeList`, `TidyPlatesHubMenus`) and the `addonName, TidyPlatesInternal = ...` vararg.

## Project goal and language

This is a fork of Binbwen/tidyplates (`upstream`), being adapted to run on **WoW Forever**. Our fork is `origin` (`MateoNicoud/tidyplates`); open PRs and issues there, never against upstream.

### Reference addons for the WoW Forever port

Two addons already adapted to WoW Forever are the reference for how to update Tidy Plates. Base the changes on how they handle the client's nameplate API, events, CVars, auras and `.toc` metadata:

- ThreatPlates: https://github.com/Backupiseasy/ThreatPlates (default branch: `devel/event-handling-redone`)
- Plater Nameplates: https://github.com/Tercioo/Plater-Nameplates (default branch: `master`)

Read them with `gh api`/`gh repo clone` into the scratchpad, not into this repo. Tidy Plates is MIT-licensed, and GitHub reports no license for either reference repo. Check each one's license file before copying code verbatim; if in doubt, reimplement the approach rather than pasting. Record in the issue or PR which reference file informed a change.

**All code, comments, documentation, commit messages, issues and PRs are written in English**, regardless of the language the user speaks to you in.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on the fork `MateoNicoud/tidyplates` (via `gh`). See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
