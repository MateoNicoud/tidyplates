-- Aura Widget (Forever client)
-- The client hides aura data from addon code in combat (secret values), so this widget never reads auras.
-- Each widget owns one AuraContainer built from CustomAuraContainerTemplate: the client picks, sorts, lays out
-- and draws the aura buttons, and the widget only configures it (filter string, count, sort, growth, look).
-- Reference for the approach: Plater_Auras.lua (reimplemented, not copied). See docs/forever-client.md.

TidyPlatesWidgets.DebuffWidgetBuild = 3

local WideArt = "Interface\\AddOns\\TidyPlatesWidgets\\Aura\\AuraFrameWide"
local SquareArt = "Interface\\AddOns\\TidyPlatesWidgets\\Aura\\AuraFrameSquare"
local AuraFont = "FONTS\\ARIALN.TTF"

local GROUP = "main"
local DebuffColumns = 3
local DebuffLimit = 6
local useWideIcons = true
local ICON_SPACING = 5

-- Filter strings the container applies on the client side (no per-aura Lua decisions are possible).
-- Hostile units: only the player's own debuffs. Friendly units: every debuff, or only the ones the player can dispel.
local FilterOptions = { friendlyDispellable = false }
local FILTER_HOSTILE = "HARMFUL|PLAYER"
local FILTER_FRIENDLY = "HARMFUL"
local FILTER_FRIENDLY_DISPEL = "HARMFUL|RAID_PLAYER_DISPELLABLE"

local ContainerAvailable = C_XMLUtil and C_XMLUtil.GetTemplateInfo
	and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate") and true or false

local AllWidgets = {}

local function GetFilterString(unitid)
	if UnitIsFriend("player", unitid) then
		return FilterOptions.friendlyDispellable and FILTER_FRIENDLY_DISPEL or FILTER_FRIENDLY
	end
	return FILTER_HOSTILE
end

-------------------------------------------------------------
-- Aura button look (called by the client for each button it creates)
-------------------------------------------------------------
local function StyleButton(button)
	local w, h, art, texCoord
	if useWideIcons then
		w, h, art, texCoord = 26.5, 14.5, WideArt, { .07, 1-.07, .23, 1-.23 }
	else
		w, h, art, texCoord = 16.5, 14.5, SquareArt, { .10, 1-.07, .12, 1-.12 }
	end
	button:SetSize(w, h)
	button.Icon:SetAllPoints(button)
	button.Icon:SetTexCoord(unpack(texCoord))
	button.Cooldown:SetAllPoints(button)
	button.Border:SetSize(32, 32)
	button.Border:ClearAllPoints()
	button.Border:SetPoint("CENTER", useWideIcons and 1 or 0, -2)
	button.Border:SetTexture(art)
	button.Count:SetFont(AuraFont, 10, "OUTLINE")
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, -2)
end

local function InitButton(widget, button)
	button.Icon = button:CreateTexture(nil, "BACKGROUND")
	button:SetIcon(button.Icon)

	button.Cooldown = CreateFrame("Cooldown", nil, button, "TidyPlatesAuraWidgetCooldown")
	button.Cooldown:EnableMouse(false)
	button.Cooldown:SetReverse(true)
	button.Cooldown:SetDrawEdge(true)
	button.Cooldown:SetHideCountdownNumbers(false)
	button:SetDurationCooldown(button.Cooldown)

	button.Border = button:CreateTexture(nil, "ARTWORK")

	button.Count = button.Cooldown:CreateFontString(nil, "OVERLAY")
	button:SetApplicationCount(button.Count)

	StyleButton(button)
	widget.buttons[#widget.buttons + 1] = button
end

-------------------------------------------------------------
-- Container configuration
-------------------------------------------------------------
local function GetLayout()
	return {
		elementWidth = useWideIcons and 26.5 or 16.5,
		elementHeight = 14.5,
		elementSpacing = ICON_SPACING,
		lineSpacing = 8,
		groupSpacing = ICON_SPACING,
		groupLineSpacing = 8,
		maximumLineSize = DebuffColumns * ((useWideIcons and 26.5 or 16.5) + ICON_SPACING) + 1,
	}
end

local function ConfigureContainer(widget)
	local container = widget.container
	container:SetAuraGroupMaxFrameCount(GROUP, DebuffLimit)
	container:SetAuraGroupLayout(GROUP, GetLayout())
	container:SetFlowLayoutMaximumLineSize(GetLayout().maximumLineSize)
	for _, button in ipairs(widget.buttons) do StyleButton(button) end
end

local function UpdateWidgetContext(widget, unit)
	local container = widget.container
	local unitid = unit and unit.unitid
	if not container then return end

	if not unitid then
		container:SetEnabled(false)
		return
	end

	container:SetAuraGroupFilterString(GROUP, GetFilterString(unitid))
	if container.unitToken == unitid and container.enabled then
		container:UpdateAllAuras()
	else
		container:SetEnabled(true)
		container:SetUnit(unitid)
	end
	container:Show()
end

local function UpdateWidgetConfig(widget)
	if widget.container then ConfigureContainer(widget) end
end

-- Create the Main Widget Body
local function CreateAuraWidget(parent)
	local widget = CreateFrame("Frame", nil, parent)
	widget:SetWidth(128); widget:SetHeight(32); widget:Show()
	widget.buttons = {}

	if ContainerAvailable then
		local container = CreateFrame("AuraContainer", nil, widget, "CustomAuraContainerTemplate")
		container:SetSize(1, 1)
		container:SetPoint("LEFT", widget)
		container:AddAuraGroup(GROUP, FILTER_HOSTILE, {
			maxFrameCount = DebuffLimit,
			sortMethod = AuraContainerSortMethod.Expiration,
			sortDirection = AuraContainerSortDirection.Normal,
			initializeFrame = function(button) InitButton(widget, button) end,
			layout = GetLayout(),
		})
		container:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)
		container:SetFlowLayoutMaximumLineSize(GetLayout().maximumLineSize)
		container:SetEnabled(false)
		widget.container = container
	end

	widget._Hide = widget.Hide
	widget.Hide = function(self)
		if self.container then self.container:SetEnabled(false) end
		self:_Hide()
	end

	widget.UpdateContext = UpdateWidgetContext
	widget.Update = UpdateWidgetContext
	widget.UpdateConfig = UpdateWidgetConfig
	AllWidgets[#AllWidgets + 1] = widget
	return widget
end

local function ReconfigureAll()
	for _, widget in ipairs(AllWidgets) do UpdateWidgetConfig(widget) end
	TidyPlates:ForceUpdate()
end

local function UseSquareDebuffIcon()
	useWideIcons = false
	DebuffColumns = 5
	DebuffLimit = DebuffColumns * 2
	ReconfigureAll()
end

local function UseWideDebuffIcon()
	useWideIcons = true
	DebuffColumns = 3
	DebuffLimit = DebuffColumns * 2
	ReconfigureAll()
end

-- Hub options that still make sense on secret auras: {friendlyDispellable = bool}
local function SetAuraFilterOptions(options)
	if type(options) == "table" then
		FilterOptions.friendlyDispellable = options.friendlyDispellable and true or false
	end
end

-- Auras are filtered by the client now; kept so older callers do not break.
local function EnableAuraWatcher() end
local function DisableAuraWatcher() end

-----------------------------------------------------
-- External
-----------------------------------------------------
TidyPlatesWidgets.IsAuraShown = function(widget) return widget and widget:IsShown() end
TidyPlatesWidgets.UseSquareDebuffIcon = UseSquareDebuffIcon
TidyPlatesWidgets.UseWideDebuffIcon = UseWideDebuffIcon
TidyPlatesWidgets.SetAuraFilterOptions = SetAuraFilterOptions
TidyPlatesWidgets.CreateAuraWidget = CreateAuraWidget
TidyPlatesWidgets.EnableAuraWatcher = EnableAuraWatcher
TidyPlatesWidgets.DisableAuraWatcher = DisableAuraWatcher

-----------------------------------------------------
-- Soon to be deprecated
-----------------------------------------------------

local PlayerDispelCapabilities = {
	["Curse"] = false,
	["Disease"] = false,
	["Magic"] = false,
	["Poison"] = false,
}

local function UpdatePlayerDispelTypes()
	PlayerDispelCapabilities["Curse"] = IsSpellKnown(51886) or IsSpellKnown(475) or IsSpellKnown(2782)
	PlayerDispelCapabilities["Poison"] = IsSpellKnown(2782) or IsSpellKnown(32375) or IsSpellKnown(4987) or (IsSpellKnown(527) and IsSpellKnown(33167))
	PlayerDispelCapabilities["Magic"] = (IsSpellKnown(4987) and IsSpellKnown(53551)) or (IsSpellKnown(2782) and IsSpellKnown(88423)) or (IsSpellKnown(527) and IsSpellKnown(33167)) or (IsSpellKnown(51886) and IsSpellKnown(77130)) or IsSpellKnown(32375)
	PlayerDispelCapabilities["Disease"] = IsSpellKnown(4987) or IsSpellKnown(528)
end

local function CanPlayerDispel(debuffType)
	return PlayerDispelCapabilities[debuffType or ""]
end

TidyPlatesWidgets.CanPlayerDispel = CanPlayerDispel


