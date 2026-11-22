-- Aura Widget (Forever client)
-- The client hides aura data from addon code in combat (secret values), so this widget never reads auras.
-- Each widget owns one AuraContainer built from CustomAuraContainerTemplate: the client picks, sorts, lays out
-- and draws the aura buttons, and the widget only configures it (filter string, count, sort, growth, look).
-- Reference for the approach: Plater_Auras.lua (reimplemented, not copied). See docs/forever-client.md.

TidyPlatesWidgets.DebuffWidgetBuild = 3

local WideArt = "Interface\\AddOns\\TidyPlatesWidgets\\Aura\\AuraFrameWide"
local SquareArt = "Interface\\AddOns\\TidyPlatesWidgets\\Aura\\AuraFrameSquare"
local AuraFont = "FONTS\\ARIALN.TTF"

local GROUP = "debuffs"
local BUFF_GROUP = "enemybuffs"
-- One entry per Hub "Icon Style": icon size, art, texture crop and column count (two rows of icons)
local STYLES = {
	wide = { width = 26.5, height = 14.5, art = WideArt, texCoord = { .07, 1-.07, .23, 1-.23 }, columns = 3, borderX = 1 },
	square = { width = 16.5, height = 14.5, art = SquareArt, texCoord = { .10, 1-.07, .12, 1-.12 }, columns = 5, borderX = 0 },
}
local Style = STYLES.wide
local DebuffRows = 2
local ICON_SPACING = 5

-- Filter strings the container applies on the client side (no per-aura Lua decisions are possible).
-- Hostile units: only the player's own debuffs. Friendly units: every debuff, or only the ones the player can dispel.
local FilterOptions = { friendlyDispellable = false, enemyDispellableBuffs = false, enemyBuffsCombatOnly = true }
local FILTER_ENEMY_BUFFS = "HELPFUL|RAID_PLAYER_DISPELLABLE"  -- buffs on enemies the player can dispel or steal
local FILTER_HOSTILE = "HARMFUL|PLAYER"
local FILTER_FRIENDLY = "HARMFUL"
local FILTER_FRIENDLY_DISPEL = "HARMFUL|RAID_PLAYER_DISPELLABLE"

local ContainerAvailable = C_XMLUtil and C_XMLUtil.GetTemplateInfo
	and C_XMLUtil.GetTemplateInfo("CustomAuraContainerTemplate")
	and AuraContainerSortMethod and AuraContainerSortDirection and AnchorUtil and AnchorUtil.FlowDirection and true or false

local AllWidgets = {}
local PlayerInCombat = false

local function GetFilterString(unitid)
	if UnitIsFriend("player", unitid) then
		return FilterOptions.friendlyDispellable and FILTER_FRIENDLY_DISPEL or FILTER_FRIENDLY
	end
	return FILTER_HOSTILE
end

-------------------------------------------------------------
-- Aura button look (called by the client for each button it creates)
-------------------------------------------------------------
-- Art that can change after the button exists. The button itself is a protected object once the client has
-- created it: addon code may only size and anchor it inside initializeFrame, so later size changes go through
-- the container layout (elementWidth/elementHeight), never through the button.
local function SkinButton(button)
	button.Icon:SetTexCoord(unpack(Style.texCoord))
	button.Border:SetTexture(Style.art)
end

local function StyleButton(button)
	button:SetSize(Style.width, Style.height)
	button.Icon:SetAllPoints(button)
	button.Cooldown:SetAllPoints(button)
	button.Border:SetSize(32, 32)
	button.Border:ClearAllPoints()
	button.Border:SetPoint("CENTER", Style.borderX, -2)
	button.Count:ClearAllPoints()
	button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, -2)
	SkinButton(button)
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

	-- The client sets text on this string as soon as it is bound, so it needs a font first
	button.Count = button.Cooldown:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	button.Count:SetFont(AuraFont, 10, "OUTLINE")
	button:SetApplicationCount(button.Count)

	StyleButton(button)
	widget.buttons[#widget.buttons + 1] = button
end

-------------------------------------------------------------
-- Container configuration
-------------------------------------------------------------
local function GetLayout()
	return {
		elementWidth = Style.width,
		elementHeight = Style.height,
		elementSpacing = ICON_SPACING,
		lineSpacing = 8,
		groupSpacing = ICON_SPACING,
		groupLineSpacing = 8,
		maximumLineSize = Style.columns * (Style.width + ICON_SPACING) + 1,
	}
end

local function ConfigureContainer(widget)
	local container = widget.container
	local layout = GetLayout()
	container:SetAuraGroupMaxFrameCount(GROUP, Style.columns * DebuffRows)
	container:SetAuraGroupLayout(GROUP, layout)
	container:SetAuraGroupMaxFrameCount(BUFF_GROUP, Style.columns)
	container:SetAuraGroupLayout(BUFF_GROUP, layout)
	container:SetFlowLayoutMaximumLineSize(layout.maximumLineSize)
	for _, button in ipairs(widget.buttons) do pcall(SkinButton, button) end
end

-- Dispellable/stealable enemy buffs: always, or only while the player is in combat (option)
local function SetBuffGroup(container, unitid)
	local show = (PlayerInCombat or not FilterOptions.enemyBuffsCombatOnly) and FilterOptions.enemyDispellableBuffs and not UnitIsFriend("player", unitid)
	container:SetAuraGroupEnabled(BUFF_GROUP, show and true or false)
end

local function UpdateWidgetContext(widget, unit)
	local container = widget.container
	local unitid = unit and unit.unitid
	if not container then return end

	if not unitid then
		container:SetEnabled(false)
		widget.auraUnit = nil
		return
	end

	local filter = GetFilterString(unitid)
	container:SetAuraGroupFilterString(GROUP, filter)
	SetBuffGroup(container, unitid)
	if widget.auraUnit == unitid and widget.auraFilter == filter then
		container:UpdateAllAuras()
	else
		container:SetEnabled(true)
		container:SetUnit(unitid)
		widget.auraUnit, widget.auraFilter = unitid, filter
	end
	widget:Show()
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
			maxFrameCount = Style.columns * DebuffRows,
			sortMethod = AuraContainerSortMethod.Expiration,
			sortDirection = AuraContainerSortDirection.Normal,
			initializeFrame = function(button) InitButton(widget, button) end,
			layout = GetLayout(),
		})
		container:AddAuraGroup(BUFF_GROUP, FILTER_ENEMY_BUFFS, {
			maxFrameCount = Style.columns,
			sortMethod = AuraContainerSortMethod.Expiration,
			sortDirection = AuraContainerSortDirection.Normal,
			initializeFrame = function(button) InitButton(widget, button) end,
			layout = GetLayout(),
		})
		container:SetAuraGroupEnabled(BUFF_GROUP, false)
		container:SetFlowLayoutAnchorPoint("BOTTOMLEFT")
		container:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection.Right, AnchorUtil.FlowDirection.Up)
		container:SetFlowLayoutMaximumLineSize(GetLayout().maximumLineSize)
		container:SetEnabled(false)
		widget.container = container
	end

	widget._Hide = widget.Hide
	widget.Hide = function(self)
		if self.container then self.container:SetEnabled(false) end
		self.auraUnit = nil
		self:_Hide()
	end

	widget.UpdateContext = UpdateWidgetContext
	widget.Update = UpdateWidgetContext
	widget.UpdateConfig = UpdateWidgetConfig
	AllWidgets[#AllWidgets + 1] = widget
	return widget
end

local CombatWatcher = CreateFrame("Frame")
CombatWatcher:RegisterEvent("PLAYER_REGEN_DISABLED")
CombatWatcher:RegisterEvent("PLAYER_REGEN_ENABLED")
CombatWatcher:SetScript("OnEvent", function(_, event)
	PlayerInCombat = (event == "PLAYER_REGEN_DISABLED")
	for _, widget in ipairs(AllWidgets) do
		if widget.container and widget.auraUnit then SetBuffGroup(widget.container, widget.auraUnit) end
	end
end)

local function ReconfigureAll()
	for _, widget in ipairs(AllWidgets) do UpdateWidgetConfig(widget) end
	TidyPlates:ForceUpdate()
end

local function UseDebuffStyle(name)
	Style = STYLES[name]
	ReconfigureAll()
end

local function UseSquareDebuffIcon() UseDebuffStyle("square") end
local function UseWideDebuffIcon() UseDebuffStyle("wide") end

-- Hub options that still make sense on secret auras: {friendlyDispellable = bool, enemyDispellableBuffs = bool, enemyBuffsCombatOnly = bool}
local function SetAuraFilterOptions(options)
	if type(options) == "table" then
		FilterOptions.friendlyDispellable = options.friendlyDispellable and true or false
		FilterOptions.enemyDispellableBuffs = options.enemyDispellableBuffs and true or false
		FilterOptions.enemyBuffsCombatOnly = options.enemyBuffsCombatOnly ~= false
		TidyPlates:ForceUpdate()
	end
end

-----------------------------------------------------
-- External
-----------------------------------------------------
TidyPlatesWidgets.IsAuraShown = function(widget) return widget and widget:IsShown() end
TidyPlatesWidgets.UseSquareDebuffIcon = UseSquareDebuffIcon
TidyPlatesWidgets.UseWideDebuffIcon = UseWideDebuffIcon
TidyPlatesWidgets.SetAuraFilterOptions = SetAuraFilterOptions
TidyPlatesWidgets.CreateAuraWidget = CreateAuraWidget

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


