-- Tidy Plates - Forever environment flag and debug switch.
-- Loaded first (see TidyPlates.xml) so every later file and addon can rely on it.

-- True only on the WoW Forever client (Camelot project).
TidyPlatesForever = (WOW_PROJECT_CAMELOT ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CAMELOT) and true or false

-- Polyfills for APIs that moved into C_ namespaces. Only defined when the global is missing.
if not GetAddOnMetadata and C_AddOns then GetAddOnMetadata = C_AddOns.GetAddOnMetadata end
if not GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
	-- Old signature: name, rank, icon, castTime, minRange, maxRange, spellID
	function GetSpellInfo(spell)
		local info = C_Spell.GetSpellInfo(spell)
		if not info then return nil end
		return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
	end
end

-- Options panels: map the old InterfaceOptions API onto the Settings API.
-- A panel whose .parent names an already-registered panel becomes its subcategory.
if not InterfaceOptions_AddCategory and Settings and Settings.RegisterCanvasLayoutCategory then
	local categories = {}
	function InterfaceOptions_AddCategory(panel)
		local name = panel.name

		-- The Settings window calls OnCommit/OnRefresh/OnCancel/OnDefault; panels still set okay/refresh/cancel/default,
		-- usually after registering, so look them up when called.
		panel.OnCommit = panel.OnCommit or function() if panel.okay then panel.okay(panel) end end
		panel.OnRefresh = panel.OnRefresh or function() if panel.refresh then panel.refresh(panel) end end
		panel.OnCancel = panel.OnCancel or function() if panel.cancel then panel.cancel(panel) end end
		panel.OnDefault = panel.OnDefault or function() if panel.default then panel.default(panel) end end

		local parent = panel.parent and categories[panel.parent]
		if parent then
			categories[name] = Settings.RegisterCanvasLayoutSubcategory(parent, panel, name)
		else
			local category = Settings.RegisterCanvasLayoutCategory(panel, name)
			Settings.RegisterAddOnCategory(category)
			categories[name] = category
		end
	end

	-- Opens a panel registered above; accepts the panel or its name. Unknown panels (e.g. Blizzard's own)
	-- just open the settings window.
	function InterfaceOptionsFrame_OpenToCategory(panelOrName)
		local name = type(panelOrName) == "table" and panelOrName.name or panelOrName
		local category = name and categories[name]
		if category and Settings.OpenToCategory then
			Settings.OpenToCategory(category:GetID())
		elseif SettingsPanel then
			ShowUIPanel(SettingsPanel)
		end
	end
end

-- Specialization/talent APIs live in C_SpecializationInfo on this client; the old globals are gone.
-- Use the namespaced function when it exists, otherwise report "none" so callers fall back to defaults.
local SpecInfo = C_SpecializationInfo or {}
if not GetSpecialization then GetSpecialization = SpecInfo.GetSpecialization or function() return nil end end
if not GetSpecializationInfo then GetSpecializationInfo = SpecInfo.GetSpecializationInfo or function() return nil end end
if not GetSpecializationRole then GetSpecializationRole = SpecInfo.GetSpecializationRole or function() return nil end end
if not GetActiveSpecGroup then GetActiveSpecGroup = SpecInfo.GetActiveSpecGroup or function() return 1 end end

-- Blocked-action reporter: the client's "action blocked" popup does not name the function.
-- While /tidydebug is on, it reports the function and a short stack through the error handler whenever the
-- client blames a Tidy Plates addon (so it lands in the error window or BugSack).
local blockedFrame = CreateFrame("Frame")
blockedFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blockedFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
blockedFrame:SetScript("OnEvent", function(_, event, addon, func)
	if TidyPlatesDebug and addon and tostring(addon):find("TidyPlates", 1, true) then
		local report = "Tidy Plates "..event..": "..tostring(addon).." -> "..tostring(func)
		local handler = geterrorhandler and geterrorhandler()
		if handler then handler(report.."\n"..(debugstack and debugstack(3, 8, 0) or ""))
		else print("|cffff5555"..report.."|r") end
	end
end)

-- Error log: keeps the last Tidy Plates errors in the TidyPlatesErrorLog saved variable, so they can be read from
-- WTF/Account/<account>/SavedVariables/TidyPlates.lua after a /reload, without copying them out of the game.
-- Saved variables only exist once ADDON_LOADED fires, so early errors wait in a local buffer.
local errorLog, earlyErrors = nil, {}

local function RecordError(message)
	local entry = date("%H:%M:%S ")..message
	local list = errorLog or earlyErrors
	list[#list + 1] = entry
	if #list > 50 then tremove(list, 1) end
end

if seterrorhandler and geterrorhandler then
	local previousHandler = geterrorhandler()
	seterrorhandler(function(message, ...)
		if type(message) == "string" and message:find("TidyPlates", 1, true) then
			RecordError(message.."\n"..(debugstack and debugstack(2, 6, 0) or ""))
		end
		if previousHandler then return previousHandler(message, ...) end
	end)
end

local logLoader = CreateFrame("Frame")
logLoader:RegisterEvent("ADDON_LOADED")
logLoader:SetScript("OnEvent", function(self, _, addon)
	if addon ~= "TidyPlates" then return end
	self:UnregisterEvent("ADDON_LOADED")
	TidyPlatesErrorLog = TidyPlatesErrorLog or {}
	errorLog = TidyPlatesErrorLog
	for _, entry in ipairs(earlyErrors) do errorLog[#errorLog + 1] = entry end
	while #errorLog > 50 do tremove(errorLog, 1) end
end)

-- /tidydebug toggles TidyPlatesDebug, which gates the core's debug prints.
-- Output goes to the chat window so it can be copied.
SLASH_TIDYDEBUG1 = '/tidydebug'
SlashCmdList['TIDYDEBUG'] = function()
	TidyPlatesDebug = not TidyPlatesDebug
	print("|cff89f559Tidy Plates|r debug: " .. (TidyPlatesDebug and "ON" or "OFF"))
end

-- /tidyhealth: prints what the client says about the target's health (for the secret-health work, issue #10).
SLASH_TIDYHEALTH1 = '/tidyhealth'
SlashCmdList['TIDYHEALTH'] = function()
	local unit = "target"
	local scale = CurveConstants and CurveConstants.ScaleTo100
	print("|cff89f559Tidy Plates|r UnitHealthPercent:", type(UnitHealthPercent), "CurveConstants.ScaleTo100:", type(scale),
		"C_CurveUtil:", type(C_CurveUtil), "secret health:", issecretvalue and issecretvalue(UnitHealth(unit)))
	if UnitHealthPercent then
		local ok, pct = pcall(UnitHealthPercent, unit, true, scale)
		print("  with curve:", ok, issecretvalue and issecretvalue(pct) and "secret" or pct)
		ok, pct = pcall(UnitHealthPercent, unit, true)
		print("  without curve:", ok, issecretvalue and issecretvalue(pct) and "secret" or pct)
		ok, pct = pcall(function() return string.format("%.0f%%", (UnitHealthPercent(unit, true, scale))) end)
		print("  string.format:", ok, pct)
	end
end

-- Frames need backdrop methods mixed in on clients that dropped them from plain frames.
-- Call on a frame before SetBackdrop; harmless if the frame already has them.
function TidyPlatesEnableBackdrop(frame)
	if frame.SetBackdrop then return frame end
	if BackdropTemplateMixin and Mixin then
		Mixin(frame, BackdropTemplateMixin)
		if frame.OnBackdropSizeChanged then frame:HookScript("OnSizeChanged", frame.OnBackdropSizeChanged) end
	else
		-- No backdrop support at all: make the calls no-ops instead of erroring
		local function noop() end
		frame.SetBackdrop, frame.SetBackdropColor, frame.SetBackdropBorderColor = noop, noop, noop
	end
	return frame
end
