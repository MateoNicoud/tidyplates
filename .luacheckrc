-- luacheck config for the Tidy Plates addons (WoW Forever, Lua 5.1 runtime).
std = "lua51"
max_line_length = false
codes = true
exclude_files = { "TidyPlates/BackupCore.lua", "TidyPlatesWidgets/_RangeWidget.lua" }

-- Globals the addons define and share.
globals = {
	"TidyPlates", "TidyPlatesDebug", "TidyPlatesForever", "TidyPlatesOptions",
	"TidyPlatesUtility", "TidyPlatesThemeList", "TidyPlatesHubMenus",
	"TidyPlatesHubSettings", "TidyPlatesHubGlobal", "TidyPlatesHubCache",
	"TidyPlatesSlashCommands", "SlashCmdList",
	"CreateTidyPlatesStatusbar", "TidyPlatesInterfacePanel",
}

-- WoW API surface is huge; treat unknown globals as read-only fields rather than errors.
read_globals = {
	"WOW_PROJECT_ID", "WOW_PROJECT_CAMELOT", "C_NamePlate", "C_UnitAuras", "C_Timer",
	"CreateFrame", "WorldFrame", "UIParent", "GameTooltip", "InterfaceOptions_AddCategory",
	"UnitName", "UnitGUID", "UnitExists", "UnitIsUnit", "UnitClass", "UnitReaction",
	"UnitHealth", "UnitHealthMax", "UnitAffectingCombat", "UnitCanAttack", "UnitIsPlayer",
	"UnitThreatSituation", "UnitDetailedThreatSituation", "UnitCastingInfo", "UnitChannelInfo",
	"GetTime", "GetCVar", "SetCVar", "InCombatLockdown", "IsInInstance", "GetSpellInfo",
	"GetNumGroupMembers", "IsInGroup", "IsInRaid", "GetRaidTargetIndex", "GetLocale",
	"RAID_CLASS_COLORS", "STANDARD_TEXT_FONT", "DEFAULT_CHAT_FRAME", "CUSTOM_CLASS_COLORS",
	"hooksecurefunc", "wipe", "tinsert", "tremove", "strsplit", "format", "date", "time",
}
