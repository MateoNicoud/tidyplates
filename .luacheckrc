-- luacheck config for the Tidy Plates addons (WoW Forever, Lua 5.1 runtime).
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "TidyPlates/BackupCore.lua", "TidyPlatesWidgets/_RangeWidget.lua" }

-- Globals the addons define and share.
globals = {
	"TidyPlates", "TidyPlatesDebug", "TidyPlatesForever", "InterfaceOptions_AddCategory", "GetAddOnMetadata", "GetSpellInfo", "GetSpecialization", "GetSpecializationInfo", "GetSpecializationRole", "UnitAura", "UnitBuff", "TidyPlatesEnableBackdrop", "TidyPlatesOptions",
	"TidyPlatesUtility", "TidyPlatesThemeList", "TidyPlatesHubMenus",
	"TidyPlatesHubSettings", "TidyPlatesHubGlobal", "TidyPlatesHubCache",
	"TidyPlatesSlashCommands", "SlashCmdList",
	"CreateTidyPlatesStatusbar", "TidyPlatesInterfacePanel",
	"TidyPlatesHubFunctions", "TidyPlatesWidgets", "TidyPlatesHubDefaults",
	"TidyPlatesHubRapidPanel", "TidyPlatesHubHelpers", "TidyPlatesHubPrefixList",
	"TidyPlatesHubDamageVariables", "TidyPlatesHubLocalizedFont", "TidyPlatesPanel",
	"TidyPlatesDefaultThemeName", "TidyPlatesHub_GetLocalizedString", "PanelHelpers",
	"TankWatcher", "AlphaFunctionsTank", "AlphaFunctionsDamage",
	"ShowTidyPlatesHubPanel", "ShowTidyPlatesHubDamagePanel", "ShowTidyPlatesHubTankPanel",
	"ShowTidyPlatesHubHealerPanel", "ShowTidyPlatesHubGladiatorPanel",
	"SLASH_TIDYPLATES1", "SLASH_TIDYPLATES2", "SLASH_HUB1", "SLASH_EVAL1", "SLASH_TIDYDEBUG1",
}

-- WoW API surface is huge; treat unknown globals as read-only fields rather than errors.
read_globals = {
	"WOW_PROJECT_ID", "WOW_PROJECT_CAMELOT", "C_NamePlate", "C_UnitAuras", "C_Timer",
	"CreateFrame", "Mixin", "BackdropTemplateMixin", "Settings", "WorldFrame", "UIParent", "GameTooltip",
	"UnitName", "UnitGUID", "UnitExists", "UnitIsUnit", "UnitClass", "UnitReaction",
	"UnitHealth", "UnitHealthMax", "UnitAffectingCombat", "UnitCanAttack", "UnitIsPlayer",
	"UnitThreatSituation", "UnitDetailedThreatSituation", "UnitCastingInfo", "UnitChannelInfo",
	"GetTime", "GetCVar", "SetCVar", "InCombatLockdown", "IsInInstance", "GetSpellInfo",
	"GetNumGroupMembers", "IsInGroup", "IsInRaid", "GetRaidTargetIndex", "GetLocale",
	"RAID_CLASS_COLORS", "STANDARD_TEXT_FONT", "DEFAULT_CHAT_FRAME", "CUSTOM_CLASS_COLORS",
	"hooksecurefunc", "wipe", "tinsert", "tremove", "strsplit", "format", "date", "time",
	"ceil", "floor", "max", "min", "sort", "gsub", "strfind", "bit", "getglobal",
	"IsSpellKnown", "UNSPECIFIED_TOTEM", "ColorPickerFrame", "OpacitySliderFrame", "UnitInRaid", "UnitInParty",
	"PlaySound", "UnitClassBase",
	"UnitPowerMax", "UnitPower", "UnitPowerType", "UnitGroupRolesAssigned", "InterfaceOptionsFrame_OpenToCategory",
	"InterfaceOptionsFrame", "InterfaceOptionsListButton_ToggleSubCategories", "INTERFACEOPTIONS_ADDONCATEGORIES",
	"HasPetUI", "ReloadUI", "PowerBarColor", "SPELL_POWER_CHI", "SPEC_MONK_BREWMASTER",
	"IsShiftKeyDown", "GetShapeshiftFormID", "GetPartyAssignment", "GetGuildInfo", "UnitSelectionColor",
	"UnitPlayerOrPetInParty", "UnitPlayerControlled", "UnitPVPName", "UnitLevel", "UnitIsTapDenied", "UnitIsFriend",
	"UnitFactionGroup", "UnitEffectiveLevel", "UnitClassification", "UNIT_LEVEL_TEMPLATE", "UIDropDownMenu_AddButton",
	"NAMEPLATE_FONT", "IsActiveBattlefieldArena", "HideUIPanel", "GetNumBattlefieldScores", "GetCreatureDifficultyColor",
	"GetComboPoints", "GetBuildInfo", "GetBattlefieldScore", "GetActiveSpecGroup",
	"RequestBattlefieldScoreData", "CombatLogGetCurrentEventInfo", "COMBATLOG_OBJECT_REACTION_FRIENDLY",
	"COMBATLOG_OBJECT_CONTROL_PLAYER", "SHOW_CLASS_COLOR_IN_V_KEY", "OPTION_TOOLTIP_SHOW_CLASS_COLOR_IN_V_KEY",
	"UNIT_NAMEPLATES_SHOW_FRIENDS", "UNIT_NAMEPLATES_SHOW_FRIENDLY_TOTEMS", "UNIT_NAMEPLATES_SHOW_FRIENDLY_PETS",
	"UNIT_NAMEPLATES_SHOW_FRIENDLY_GUARDIANS", "UNIT_NAMEPLATES_SHOW_ENEMY_TOTEMS", "UNIT_NAMEPLATES_SHOW_ENEMY_PETS",
	"UNIT_NAMEPLATES_SHOW_ENEMY_MINUS", "UNIT_NAMEPLATES_SHOW_ENEMY_GUARDIANS", "UNIT_NAMEPLATES_SHOW_ENEMIES",
	"OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDS", "OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDLY_TOTEMS",
	"OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDLY_PETS", "OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_FRIENDLY_GUARDIANS",
	"OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMY_TOTEMS", "OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMY_PETS",
	"OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMY_MINUS", "OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMY_GUARDIANS",
	"OPTION_TOOLTIP_UNIT_NAMEPLATES_SHOW_ENEMIES",
}
