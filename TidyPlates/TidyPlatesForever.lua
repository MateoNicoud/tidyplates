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
		local parent = panel.parent and categories[panel.parent]
		if parent then
			categories[name] = Settings.RegisterCanvasLayoutSubcategory(parent, panel, name)
		else
			local category = Settings.RegisterCanvasLayoutCategory(panel, name)
			Settings.RegisterAddOnCategory(category)
			categories[name] = category
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

-- Aura reads: rebuild the old UnitAura tuple from C_UnitAuras. Returns nothing if the API is missing,
-- which ends the callers' aura loops cleanly.
if not UnitAura then
	function UnitAura(unit, index, filter)
		local getAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
		-- Aura data can be refused (secret) for tainted callers: treat that as "no aura"
		local ok, a = pcall(getAura or function() end, unit, index, filter)
		if not ok or not a then return nil end
		return a.name, a.icon, a.applications, a.dispelName, a.duration, a.expirationTime, a.sourceUnit,
			a.isStealable, a.nameplateShowPersonal, a.spellId, a.canApplyAura, a.isBossAura
	end
end
if not UnitBuff then
	function UnitBuff(unit, index) return UnitAura(unit, index, "HELPFUL") end
end

-- Blocked-action reporter: the client's "action blocked" popup does not name the function.
-- This prints it, with a short stack, whenever the client blames a Tidy Plates addon.
local blockedFrame = CreateFrame("Frame")
blockedFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
blockedFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
blockedFrame:SetScript("OnEvent", function(_, event, addon, func)
	if addon and tostring(addon):find("TidyPlates", 1, true) then
		local report = "Tidy Plates "..event..": "..tostring(addon).." -> "..tostring(func)
		print("|cffff5555"..report.."|r")
		-- Also go through the error handler so it shows in the error window / BugSack with a stack
		local handler = geterrorhandler and geterrorhandler()
		if handler then handler(report.."\n"..(debugstack and debugstack(3, 8, 0) or "")) end
	end
end)

-- /tidydebug toggles TidyPlatesDebug, which gates the core's debug prints.
-- Output goes to the chat window so it can be copied.
SLASH_TIDYDEBUG1 = '/tidydebug'
SlashCmdList['TIDYDEBUG'] = function()
	TidyPlatesDebug = not TidyPlatesDebug
	print("|cff89f559Tidy Plates|r debug: " .. (TidyPlatesDebug and "ON" or "OFF"))
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
