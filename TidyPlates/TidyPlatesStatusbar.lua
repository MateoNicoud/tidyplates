-- Tidy Plates status bar.
-- A real StatusBar, so health values the client marks as "secret" can be passed straight to
-- SetMinMaxValues/SetValue (addon Lua cannot do arithmetic or comparisons on them).
-- The extra methods keep the API the core and themes were written against.

local function SetBackdropTexCoord(self, left, right, top, bottom)
	self.Backdrop:SetTexCoord(left or 0, right or 1, top or 0, bottom or 1)
end

local function SetBackdropTexture(self, texture)
	self.Backdrop:SetTexture(texture)
end

-- The native bar crops its own fill texture, so a custom crop is not applied.
local function SetTexCoord() end

local function SetAllColors(self, rBar, gBar, bBar, aBar, rBackdrop, gBackdrop, bBackdrop, aBackdrop)
	self:SetStatusBarColor(rBar or 1, gBar or 1, bBar or 1, aBar or 1)
	self.Backdrop:SetVertexColor(rBackdrop or 1, gBackdrop or 1, bBackdrop or 1, aBackdrop or 1)
end

local function SetStatusBarGradient(self, r1, g1, b1, a1, r2, g2, b2, a2)
	local fill = self:GetStatusBarTexture()
	if fill and fill.SetGradient and CreateColor then
		fill:SetGradient(self:GetOrientation(), CreateColor(r1, g1, b1, a1), CreateColor(r2, g2, b2, a2))
	end
end

function CreateTidyPlatesStatusbar(parent)
	local frame = CreateFrame("StatusBar", nil, parent)
	frame:SetSize(1, 1)
	frame:SetMinMaxValues(0, 1)
	frame:SetValue(1)
	frame.Backdrop = frame:CreateTexture(nil, "BACKGROUND")
	frame.Backdrop:SetAllPoints(frame)

	frame.SetAllColors = SetAllColors
	frame.SetStatusBarGradient = SetStatusBarGradient
	frame.SetTexCoord = SetTexCoord
	frame.SetBackdropTexCoord = SetBackdropTexCoord
	frame.SetBackdropTexture = SetBackdropTexture
	return frame
end
