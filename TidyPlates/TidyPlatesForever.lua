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
