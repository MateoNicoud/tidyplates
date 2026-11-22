---------------------------------------------------------------------------------------------------------------------
-- Tidy Plates Interface Panel
---------------------------------------------------------------------------------------------------------------------

local addonName, TidyPlatesInternal = ...
TidyPlatesPanel = {}

local SetTheme = TidyPlatesInternal.SetTheme	-- Use the protected version

local version = GetAddOnMetadata("TidyPlates", "version")
local versionString = "|cFF666666"..version

local TidyPlatesInterfacePanel = PanelHelpers:CreatePanelFrame( "TidyPlatesInterfacePanel", "Tidy Plates", nil )
InterfaceOptions_AddCategory(TidyPlatesInterfacePanel);

local CallIn = TidyPlatesUtility.CallIn
local copytable = TidyPlatesUtility.copyTable
local PanelHelpers = TidyPlatesUtility.PanelHelpers

local NO_AUTOMATION = "No Automation"
local DURING_COMBAT = "Show during Combat, Hide when Combat ends"
local OUT_OF_COMBAT = "Hide when Combat starts, Show when Combat ends"

local font = "Interface\\Addons\\TidyPlates\\Media\\DefaultFont.ttf"
local yellow, blue, red, orange = "|cffffff00", "|cFF3782D1", "|cFFFF1100", "|cFFFF6906"

local function SetCastBars(enable)
	if enable then TidyPlates:EnableCastBars()
		else TidyPlates:DisableCastBars()
	end
end


-------------------------------------------------------------------------------------
--  Default Options
-------------------------------------------------------------------------------------

local FirstTryTheme = "Neon"
local DefaultProfile = "Damage"

local ActiveProfile = "None"

-- Panel labels. Forever has two talent groups (dual spec), not class specializations.
local Labels = {
	enUS = { primary = "Primary Talents", secondary = "Secondary Talents", active = "Active", useRole = "Use group role for the profile", distance = "Nameplate Distance" },
	frFR = { primary = "Principale", secondary = "Secondaire", active = "active", useRole = "Utiliser le rôle de groupe", distance = "Distance des plaques" },
}
local L = Labels[GetLocale()] or Labels.enUS

TidyPlatesOptions = {

	ActiveTheme = FirstTryTheme,

	FirstSpecProfile = DefaultProfile,
	SecondSpecProfile = DefaultProfile,
	ThirdSpecProfile = DefaultProfile,
	FourthSpecProfile = DefaultProfile,
	UseGroupRole = true,
	NameplateDistance = false,		-- false: leave the client value alone

	FriendlyAutomation = NO_AUTOMATION,
	EnemyAutomation = NO_AUTOMATION,
	DisableCastBars = false,
	ForceBlizzardFont = false,
	WelcomeShown = false,
}

local TidyPlatesOptionsDefaults = copytable(TidyPlatesOptions)
local TidyPlatesThemeNames = {}

local AutomationDropdownItems = {
					{ text = NO_AUTOMATION, value = NO_AUTOMATION } ,
					{ text = DURING_COMBAT, value = DURING_COMBAT } ,
					{ text = OUT_OF_COMBAT, value = OUT_OF_COMBAT } ,
					}

local HubProfileList = {}


local function GetProfile()
	return ActiveProfile
end

TidyPlates.GetProfile = GetProfile


function TidyPlatesPanel.AddProfile(self, profileName )
	if  profileName then
		HubProfileList[#HubProfileList+1] = { text = profileName, value = profileName, }
	end
end

local function SetNameplateVisibility(cvar, mode, combat)
	if mode == DURING_COMBAT then
		if combat then
			SetCVar(cvar, 1)
		else
			SetCVar(cvar, 0)
		end
	elseif mode == OUT_OF_COMBAT then
		if combat then
			SetCVar(cvar, 0)
		else
			SetCVar(cvar, 1)
		end
	end
end

--[[
function TidyPlates:ReloadTheme()
	SetTheme(TidyPlatesInternal.activeThemeName)
	TidyPlatesOptions.ActiveTheme = TidyPlatesInternal.activeThemeName
	TidyPlates:ForceUpdate()
end
--]]


-------------------------------------------------------------------------------------
-- Panel
-------------------------------------------------------------------------------------
local ThemeDropdownMenuItems = {}

-- Nameplate view distance. The CVar cannot be changed in combat, so a request made then waits for it to end.
local DISTANCE_CVAR = "nameplateMaxDistance"
local DISTANCE_MIN, DISTANCE_MAX = 20, 60
local distancePending = false

local function ApplyNameplateDistance()
	local distance = TidyPlatesOptions.NameplateDistance
	if not distance then return end
	if InCombatLockdown() then distancePending = true; return end
	distancePending = false
	SetCVar(DISTANCE_CVAR, distance)
end

local function ApplyAutomationSettings()
	SetCastBars(not TidyPlatesOptions.DisableCastBars)
	TidyPlates.OverrideFonts( TidyPlatesOptions.ForceBlizzardFont)

	if TidyPlatesOptions._EnableMiniButton then
		TidyPlatesUtility:CreateMinimapButton()
		TidyPlatesUtility:ShowMinimapButton()
	end

	TidyPlates:ForceUpdate()
end

-- Hub profiles are only known once the Hub has registered them; until then accept any name
local function IsKnownProfile(name)
	if #HubProfileList == 0 then return true end
	for _, item in ipairs(HubProfileList) do
		if item.value == name then return true end
	end
	return false
end

-- GetProfileForPlayer: the group role decides when there is one (a Shaman tank has no stance or aura
-- that gives it away). Without a role, the profile chosen for the active talent group applies.
local function GetProfileForPlayer()
	if TidyPlatesOptions.UseGroupRole ~= false and UnitGroupRolesAssigned then
		local role = UnitGroupRolesAssigned("player")
		local profile = (role == "TANK" and "Tank") or (role == "HEALER" and "Healer") or (role == "DAMAGER" and "Damage") or nil
		if profile and IsKnownProfile(profile) then return profile end
	end

	local talentGroup = GetActiveSpecGroup and GetActiveSpecGroup() or 1
	if talentGroup == 2 then return TidyPlatesOptions.SecondSpecProfile or DefaultProfile end
	return TidyPlatesOptions.FirstSpecProfile or DefaultProfile
end

-- ApplyProfile: switches the Hub profile if the wanted one changed
local function ApplyProfile()
	local profile = GetProfileForPlayer()
	if profile == ActiveProfile then return end
	ActiveProfile = profile

	local theme = TidyPlates:GetTheme()
	if theme and theme.OnChangeProfile then theme:OnChangeProfile(ActiveProfile) end

	TidyPlates:ResetWidgets()
	TidyPlates:ForceUpdate()
end

local function ApplyPanelSettings()

	-- Theme
	SetTheme(TidyPlatesOptions.ActiveTheme or FirstTryTheme)

	-- This is here in case the theme couldn't be loaded, and the core falls back to defaults
	--TidyPlatesOptions.ActiveTheme = TidyPlatesInternal.activeThemeName
	--local theme = TidyPlatesThemeList[TidyPlatesInternal.activeThemeName]

	-- Load Hub Profile (the theme may just have been reloaded, so force it to be applied again)
	ActiveProfile = nil
	ApplyProfile()
end





local function GetPanelValues(panel)
	TidyPlatesOptions.ActiveTheme = panel.ActiveThemeDropdown:GetValue()

	TidyPlatesOptions.FriendlyAutomation = panel.AutoShowFriendly:GetValue()
	TidyPlatesOptions.EnemyAutomation = panel.AutoShowEnemy:GetValue()
	TidyPlatesOptions.DisableCastBars = panel.DisableCastBars:GetChecked()
	TidyPlatesOptions.ForceBlizzardFont = panel.ForceBlizzardFont:GetChecked()
	TidyPlatesOptions.UseGroupRole = panel.UseGroupRole:GetChecked() and true or false
	TidyPlatesOptions.PrimaryProfile = panel.FirstSpecDropdown:GetValue()

	TidyPlatesOptions.FirstSpecProfile = panel.FirstSpecDropdown:GetValue()
	TidyPlatesOptions.SecondSpecProfile = panel.SecondSpecDropdown:GetValue()
	TidyPlatesOptions.ThirdSpecProfile = panel.ThirdSpecDropdown:GetValue()
	TidyPlatesOptions.FourthSpecProfile = panel.FourthSpecDropdown:GetValue()
end


local function SetPanelValues(panel)
	panel.ActiveThemeDropdown:SetValue(TidyPlatesOptions.ActiveTheme or FirstTryTheme)	-- same fallback the core uses

	panel.UseGroupRole:SetChecked(TidyPlatesOptions.UseGroupRole ~= false)
	panel.NameplateDistance:SetValue(TidyPlatesOptions.NameplateDistance or tonumber(GetCVar(DISTANCE_CVAR)) or 41)
	panel.FirstSpecDropdown:SetValue(TidyPlatesOptions.FirstSpecProfile)
	panel.SecondSpecDropdown:SetValue(TidyPlatesOptions.SecondSpecProfile)
	panel.ThirdSpecDropdown:SetValue(TidyPlatesOptions.ThirdSpecProfile)
	panel.FourthSpecDropdown:SetValue(TidyPlatesOptions.FourthSpecProfile)

	panel.DisableCastBars:SetChecked(TidyPlatesOptions.DisableCastBars)
	panel.ForceBlizzardFont:SetChecked(TidyPlatesOptions.ForceBlizzardFont)
	panel.AutoShowFriendly:SetValue(TidyPlatesOptions.FriendlyAutomation)
	panel.AutoShowEnemy:SetValue(TidyPlatesOptions.EnemyAutomation)
end



local function OnValueChange(self)
	local panel = self:GetParent()
	GetPanelValues(panel)
	ApplyPanelSettings()
end


local function OnOkay(panel)
	GetPanelValues(panel)
	ApplyPanelSettings()
	ApplyAutomationSettings()
end


-- Loads values from the saved vars, and preps for display of the panel
local function OnRefresh(panel)

	if not panel then return end

	SetPanelValues(panel)

	------------------------
	-- Talent group labels
	------------------------
	local activeGroup = GetActiveSpecGroup and GetActiveSpecGroup() or 1
	local activeSuffix = " ("..L.active..")"
	panel.FirstSpecLabel:SetText(L.primary..(activeGroup == 1 and activeSuffix or ""))
	panel.SecondSpecLabel:SetText(L.secondary..(activeGroup == 2 and activeSuffix or ""))

end





local function CreateMenuTables()
	-- Convert the Theme List into a Menu List
	local themecount = 1

	ThemeDropdownMenuItems = {{text = "           ",},}

	if type(TidyPlatesThemeList) == "table" then
		for themename, themepointer in pairs(TidyPlatesThemeList) do
			TidyPlatesThemeNames[themecount] = themename
			--TidyPlatesThemeIndexes[themename] = themecount
			themecount = themecount + 1
		end
		-- Theme Choices
		for index, name in pairs(TidyPlatesThemeNames) do ThemeDropdownMenuItems[index] = {text = name, value = name } end
	end
	sort(ThemeDropdownMenuItems, function (a,b)
	  return (a.text < b.text)
    end)

end

local function BuildInterfacePanel(panel)
	TidyPlatesEnableBackdrop(panel)
	panel:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", insets = { left = 2, right = 2, top = 2, bottom = 2 },})
	panel:SetBackdropColor(0.06, 0.06, 0.06, .7)

	panel.Label:SetFont("Interface\\Addons\\TidyPlates\\Media\\DefaultFont.ttf", 26)
	panel.Label:SetPoint("TOPLEFT", panel, "TOPLEFT", 16+6, -16-4)
	panel.Label:SetTextColor(255/255, 105/255, 6/255)

	panel.Version = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
	panel.Version:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -16-4)
	panel.Version:SetHeight(15)
	panel.Version:SetWidth(350)
	panel.Version:SetJustifyH("RIGHT")
	panel.Version:SetJustifyV("TOP")
	panel.Version:SetText(versionString)
	panel.Version:SetFont("Interface\\Addons\\TidyPlates\\Media\\DefaultFont.ttf", 18)

	panel.DividerLine = panel:CreateTexture(nil, 'ARTWORK')
	panel.DividerLine:SetTexture("Interface\\Addons\\TidyPlatesHub\\shared\\ThinBlackLine")
	panel.DividerLine:SetSize( 500, 12)
	panel.DividerLine:SetPoint("TOPLEFT", panel.Label, "BOTTOMLEFT", -6, -12)

	----------------------------------------------
	-- Theme
	----------------------------------------------
	panel.ThemeCategoryTitle = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.ThemeCategoryTitle:SetFont(font, 22)
	panel.ThemeCategoryTitle:SetText("Theme")
	panel.ThemeCategoryTitle:SetPoint("TOPLEFT", 20, -70)
	panel.ThemeCategoryTitle:SetTextColor(255/255, 105/255, 6/255)

	-- Dropdown
	panel.ActiveThemeDropdown = PanelHelpers:CreateDropdownFrame("TidyPlatesChooserDropdown", panel, ThemeDropdownMenuItems, TidyPlatesDefaultThemeName, nil, true)
	panel.ActiveThemeDropdown:SetPoint("TOPLEFT", panel.ThemeCategoryTitle, "BOTTOMLEFT", -20, -4)

	----------------------------------------------
	-- Profiles
	----------------------------------------------
	panel.ProfileLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.ProfileLabel:SetFont(font, 22)
	panel.ProfileLabel:SetText("Profile")
	panel.ProfileLabel:SetPoint("TOPLEFT", panel.ActiveThemeDropdown, "BOTTOMLEFT", 20, -20)
	panel.ProfileLabel:SetTextColor(255/255, 105/255, 6/255)

	---------------
	-- Column 1
	---------------
	-- Spec 1
	panel.FirstSpecLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.FirstSpecLabel:SetPoint("TOPLEFT", panel.ProfileLabel,"BOTTOMLEFT", 0, -4)
	panel.FirstSpecLabel:SetWidth(170)
	panel.FirstSpecLabel:SetJustifyH("LEFT")
	panel.FirstSpecLabel:SetText(L.primary)

	panel.FirstSpecDropdown = PanelHelpers:CreateDropdownFrame("TidyPlatesFirstSpecDropdown", panel, HubProfileList, DefaultProfile, nil, true)
	panel.FirstSpecDropdown:SetPoint("TOPLEFT", panel.FirstSpecLabel, "BOTTOMLEFT", -20, -2)

	-- Spec 3
	panel.ThirdSpecLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.ThirdSpecLabel:SetPoint("TOPLEFT", panel.FirstSpecDropdown,"BOTTOMLEFT", 20, -8)
	panel.ThirdSpecLabel:SetWidth(170)
	panel.ThirdSpecLabel:SetJustifyH("LEFT")
	panel.ThirdSpecLabel:SetText("Third Spec")
	panel.ThirdSpecLabel:Hide()

	panel.ThirdSpecDropdown = PanelHelpers:CreateDropdownFrame("TidyPlatesThirdSpecDropdown", panel, HubProfileList, DefaultProfile, nil, true)
	panel.ThirdSpecDropdown:SetPoint("TOPLEFT", panel.ThirdSpecLabel, "BOTTOMLEFT", -20, -2)
	-- Forever has two talent groups only: the third and fourth slots stay hidden
	panel.ThirdSpecLabel:Hide()
	panel.ThirdSpecDropdown:Hide()

	---------------
	-- Column 2
	---------------
	-- Spec 2
	panel.SecondSpecLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.SecondSpecLabel:SetPoint("TOPLEFT", panel.FirstSpecLabel,"TOPLEFT", 180, 0)
	panel.SecondSpecLabel:SetWidth(170)
	panel.SecondSpecLabel:SetJustifyH("LEFT")
	panel.SecondSpecLabel:SetText(L.secondary)

	panel.SecondSpecDropdown = PanelHelpers:CreateDropdownFrame("TidyPlatesSecondSpecDropdown", panel, HubProfileList, DefaultProfile, nil, true)
	panel.SecondSpecDropdown:SetPoint("TOPLEFT",panel.SecondSpecLabel, "BOTTOMLEFT", -20, -2)

	-- Spec 4
	panel.FourthSpecLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.FourthSpecLabel:SetPoint("TOPLEFT", panel.SecondSpecDropdown,"BOTTOMLEFT", 20, -8)
	panel.FourthSpecLabel:SetWidth(170)
	panel.FourthSpecLabel:SetJustifyH("LEFT")
	panel.FourthSpecLabel:SetText("Fourth Spec")
	panel.FourthSpecLabel:Hide()

	panel.FourthSpecDropdown = PanelHelpers:CreateDropdownFrame("TidyPlatesFourthSpecDropdown", panel, HubProfileList, DefaultProfile, nil, true)
	panel.FourthSpecDropdown:SetPoint("TOPLEFT",panel.FourthSpecLabel, "BOTTOMLEFT", -20, -2)
	panel.FourthSpecDropdown:Hide()


	----------------------------------------------
	-- Automation
	----------------------------------------------
	panel.AutomationLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.AutomationLabel:SetFont(font, 22)
	panel.AutomationLabel:SetText("Automation")
	panel.AutomationLabel:SetPoint("TOPLEFT", panel.FirstSpecDropdown, "BOTTOMLEFT", 20, -20)
	panel.AutomationLabel:SetTextColor(255/255, 105/255, 6/255)


	---------------
	-- Column 1
	---------------
	-- Enemy Visibility
	panel.AutoShowEnemyLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.AutoShowEnemyLabel:SetPoint("TOPLEFT", panel.AutomationLabel,"BOTTOMLEFT", 0, -4)
	panel.AutoShowEnemyLabel:SetWidth(170)
	panel.AutoShowEnemyLabel:SetJustifyH("LEFT")
	panel.AutoShowEnemyLabel:SetText("Enemy Nameplates:")

	panel.AutoShowEnemy = PanelHelpers:CreateDropdownFrame("TidyPlatesAutoShowEnemy", panel, AutomationDropdownItems, NO_AUTOMATION, nil, true)
	panel.AutoShowEnemy:SetPoint("TOPLEFT",panel.AutoShowEnemyLabel, "BOTTOMLEFT", -20, -2)


	---------------
	-- Column 2
	---------------
	-- Friendly Visibility
	panel.AutoShowFriendlyLabel = panel:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	panel.AutoShowFriendlyLabel:SetPoint("TOPLEFT", panel.AutoShowEnemyLabel,"TOPLEFT", 180, 0)
	panel.AutoShowFriendlyLabel:SetWidth(170)
	panel.AutoShowFriendlyLabel:SetJustifyH("LEFT")
	panel.AutoShowFriendlyLabel:SetText("Friendly Nameplates:")

	panel.AutoShowFriendly = PanelHelpers:CreateDropdownFrame("TidyPlatesAutoShowFriendly", panel, AutomationDropdownItems, NO_AUTOMATION, nil, true)
	panel.AutoShowFriendly:SetPoint("TOPLEFT", panel.AutoShowFriendlyLabel,"BOTTOMLEFT", -20, -2)



	----------------------------------------------
	-- Other Options
	----------------------------------------------
	-- Blizz Button
	local BlizzOptionsButton = CreateFrame("Button", "TidyPlatesOptions_BlizzOptionsButton", panel, "TidyPlatesPanelButtonTemplate")
	--BlizzOptionsButton:SetPoint("TOPRIGHT", ResetButton, "TOPLEFT", -8, 0)
	BlizzOptionsButton:SetPoint("TOPLEFT", panel.AutoShowEnemy, "TOPLEFT", 16, -55)
	BlizzOptionsButton:SetWidth(260)
	BlizzOptionsButton:SetText("Nameplate Motion & Visibility")

	-- Cast Bars
	panel.DisableCastBars = PanelHelpers:CreateCheckButton("TidyPlatesOptions_DisableCastBars", panel, "Disable Cast Bars")
	panel.DisableCastBars:SetPoint("TOPLEFT", BlizzOptionsButton, "TOPLEFT", 0, -35)
	panel.DisableCastBars:SetScript("OnClick", function(self) SetCastBars(not self:GetChecked()) end)

	-- ForceBlizzardFont
	panel.ForceBlizzardFont = PanelHelpers:CreateCheckButton("TidyPlatesOptions_ForceBlizzardFont", panel, "Force Multi-Lingual Font (Requires /reload)")
	panel.ForceBlizzardFont:SetPoint("TOPLEFT", panel.DisableCastBars, "TOPLEFT", 0, -35)
	panel.ForceBlizzardFont:SetScript("OnClick", function(self) TidyPlates.OverrideFonts( self:GetChecked()); end)

	-- Group role decides the profile when there is one
	panel.UseGroupRole = PanelHelpers:CreateCheckButton("TidyPlatesOptions_UseGroupRole", panel, L.useRole)
	panel.UseGroupRole:SetPoint("TOPLEFT", panel.ForceBlizzardFont, "TOPLEFT", 0, -35)
	panel.UseGroupRole:SetScript("OnClick", function(self)
		TidyPlatesOptions.UseGroupRole = self:GetChecked() and true or false
		ApplyProfile()
	end)

	-- Nameplate distance (only written once the player moves the slider)
	panel.NameplateDistance = PanelHelpers:CreateSliderFrame("TidyPlatesOptions_NameplateDistance", panel, L.distance,
		tonumber(GetCVar(DISTANCE_CVAR)) or 41, DISTANCE_MIN, DISTANCE_MAX, 1, "ACTUAL")
	panel.NameplateDistance:SetPoint("TOPLEFT", panel.UseGroupRole, "TOPLEFT", 6, -62)
	panel.NameplateDistance:SetWidth(200)
	panel.NameplateDistance:SetScript("OnValueChanged", function(self, value, userInput)
		value = floor(value + 0.5)
		self.Value:SetText(tostring(value))
		if userInput then
			TidyPlatesOptions.NameplateDistance = value
			ApplyNameplateDistance()
		end
	end)

	-- Reset
	ResetButton = CreateFrame("Button", "TidyPlatesOptions_ResetButton", panel, "TidyPlatesPanelButtonTemplate")
	ResetButton:SetPoint("BOTTOMRIGHT", -16, 8)
	ResetButton:SetWidth(155)
	ResetButton:SetText("Reset Configuration")

	-- Update Functions
	panel.okay = OnOkay
	panel.refresh = OnRefresh
	panel.ActiveThemeDropdown.OnValueChanged = OnValueChange

	panel.FirstSpecDropdown.OnValueChanged = OnValueChange
	panel.SecondSpecDropdown.OnValueChanged = OnValueChange
	panel.ThirdSpecDropdown.OnValueChanged = OnValueChange
	panel.FourthSpecDropdown.OnValueChanged = OnValueChange



	-- Blizzard Nameplate Options Button
	BlizzOptionsButton:SetScript("OnClick", function()
		InterfaceOptionsFrame_OpenToCategory(_G["InterfaceOptionsNamesPanel"])
	end)

	-- Reset Button
	ResetButton:SetScript("OnClick", function()
		SetCVar("nameplateShowEnemies", 1)
		SetCVar("threatWarning", 3)		-- Required for threat/aggro detection


		if IsShiftKeyDown() then
			TidyPlatesOptions = wipe(TidyPlatesOptions)
			for i, v in pairs(TidyPlatesOptionsDefaults) do TidyPlatesOptions[i] = v end
			SetCVar("nameplateShowFriends", 0)
			ReloadUI()
		else
			TidyPlatesOptions = wipe(TidyPlatesOptions)
			for i, v in pairs(TidyPlatesOptionsDefaults) do TidyPlatesOptions[i] = v end
			OnRefresh(panel)
			ApplyPanelSettings()
			print(yellow.."Resetting "..orange.."Tidy Plates"..yellow.." Theme Selection to Default")
			print(yellow.."Holding down "..blue.."Shift"..yellow.." while clicking "..red.."Reset Configuration"..yellow.." will clear your saved settings, AND reload the user interface.")
		end

	end)
end

-------------------------------------------------------------------------------------
-- Auto-Loader
-------------------------------------------------------------------------------------
local panelevents = {}

function panelevents:ACTIVE_TALENT_GROUP_CHANGED(self)
	ApplyProfile()
end

-- The group role can change when roles are assigned or the group changes
function panelevents:PLAYER_ROLES_ASSIGNED() ApplyProfile() end
function panelevents:GROUP_ROSTER_UPDATE() ApplyProfile() end

function panelevents:PLAYER_ENTERING_WORLD()
	--print("Panel:Player Entering World")
	-- Tihs may happen every time a loading screen is shown
	local fallBackTheme

	-- Locate a fallback theme
	if TidyPlatesThemeList[FirstTryTheme] then
		fallBackTheme = FirstTryTheme
	else
		for i,v in pairs(TidyPlatesThemeList) do fallBackTheme = i break; end
	end

	-- Check to make sure the selected themes exist; if not, replace with fallback
	if not TidyPlatesThemeList[TidyPlatesOptions.ActiveTheme] then
		TidyPlatesOptions.ActiveTheme = fallBackTheme end

	ApplyPanelSettings()
	ApplyAutomationSettings()
	ApplyNameplateDistance()
end

function panelevents:PLAYER_REGEN_ENABLED()
	if distancePending then ApplyNameplateDistance() end
	SetNameplateVisibility("nameplateShowEnemies", TidyPlatesOptions.EnemyAutomation, false)
	SetNameplateVisibility("nameplateShowFriends", TidyPlatesOptions.FriendlyAutomation, false)
end

function panelevents:PLAYER_REGEN_DISABLED()
	SetNameplateVisibility("nameplateShowEnemies", TidyPlatesOptions.EnemyAutomation, true)
	SetNameplateVisibility("nameplateShowFriends", TidyPlatesOptions.FriendlyAutomation, true)
end

function panelevents:PLAYER_LOGIN()
	-- This happens only once a session

	-- Setup the interface panels
	CreateMenuTables()				-- Look at the theme table and get names
	BuildInterfacePanel(TidyPlatesInterfacePanel)

	-- First time setup
	if not TidyPlatesOptions.WelcomeShown then
		SetCVar("nameplateShowSelf", 0)		--
		SetCVar("nameplateShowAll", 1)		--


		SetCVar("nameplateShowEnemies", 1)
		SetCVar("nameplateShowFriends", 0)
		SetCVar("threatWarning", 3)		-- Required for threat/aggro detection
		TidyPlatesOptions.WelcomeShown = true
	end

end

TidyPlatesInterfacePanel:SetScript("OnEvent", function(self, event, ...) panelevents[event](self, ...) end)
for eventname in pairs(panelevents) do
	-- pcall: an event this client does not know must not stop the panel from loading
	pcall(TidyPlatesInterfacePanel.RegisterEvent, TidyPlatesInterfacePanel, eventname)
end

-------------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------------

TidyPlatesSlashCommands = {}

function TidyPlatesSlashCommands.debug_on()
	TidyPlatesDebug = true
end


function TidyPlatesSlashCommands.debug_off()
	TidyPlatesDebug = false
end


function slash_TidyPlates(arg)
	if type(TidyPlatesSlashCommands[arg]) == 'function' then
		TidyPlatesSlashCommands[arg]()
		TidyPlates:ForceUpdate()
	else
		TidyPlatesUtility.OpenInterfacePanel(TidyPlatesInterfacePanel)
	end
end

SLASH_TIDYPLATES1 = '/tidyplates'
SLASH_TIDYPLATES2 = '/tp'
SlashCmdList['TIDYPLATES'] = slash_TidyPlates;



