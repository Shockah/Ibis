local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]
local RoundHighlightAddon = _G[BaseAddon:GetName().."_Indicator_RoundHighlight"]

local Class = {
	prototype = {},
}
Addon.Indicator = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

local free = {}

function Class:Get(parentFrame, action, config, tracker)
	local obj
	if S:IsEmpty(free) then
		obj = Private:Create(parentFrame, action, config, tracker)
	else
		obj = free[1]
		table.remove(free, 1)
		obj:SetParent(parentFrame)
	end
	obj:Setup(parentFrame, action, config, tracker)
	return obj
end

function Class:Free(indicator)
	indicator:Free()
end

function Instance:Free()
	self:SetScript("OnUpdate", nil)
	self:ClearAllPoints()
	self:Hide()

	table.insert(free, self)
end

function Private:Create(parentFrame, action, config, tracker)
	local indicator = CreateFrame("frame", nil, parentFrame or UIParent)
	S:CloneInto(Instance, indicator)

	indicator.highlights = {}

	return indicator
end

function Instance:Setup(parentFrame, action, config, tracker)
	self.parentFrame = parentFrame
	self.config = config
	self.action = action
	self.tracker = tracker

	self:ClearAllPoints()
	self:SetPoint("CENTER", parentFrame, "CENTER")

	for _, highlight in pairs(self.highlights) do
		self:SetupHighlight(highlight)
	end

	local function OnUpdate(self)
		local scale = self.config.scale or 1.0
		scale = scale * parentFrame:GetScale()
		self:SetSize(parentFrame:GetWidth() * scale, parentFrame:GetHeight() * scale)

		self:UpdateIndicator()
	end
	self:SetScript("OnUpdate", OnUpdate)
	OnUpdate(self)

	self:Show()
end

function Instance:SetupHighlight(highlight)
	highlight:ClearAllPoints()
	highlight:SetPoint("TOPLEFT", self, "TOPLEFT")
	highlight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")

	local texture = self.config.texture or ((self.parentFrame.Border and self.parentFrame.Border.GetTexture) and self.parentFrame.Border:GetTexture()) or nil
	highlight:SetTexture(texture)
	highlight:SetBlendMode(self.config.blendMode or "ADD")
	highlight:SetFrameStrata(self.config.strata or "MEDIUM")
	highlight:SetDrawLayer(self.config.layer or "BORDER")
end

function Instance:UpdateIndicator()
	local current, maximum, extraData = self.tracker:GetValue()
	local extraDataColors = extraData and extraData.colors

	if current then
		while maximum > #self.highlights do
			local highlight = RoundHighlightAddon.RoundHighlight:Get(self)
			self:SetupHighlight(highlight)
			table.insert(self.highlights, highlight)
		end
		while maximum < #self.highlights do
			local highlight = self.highlights[#self.highlights]
			highlight:Free()
			table.remove(self.highlights, #self.highlights)
		end
	else
		for _, highlight in pairs(self.highlights) do
			highlight:ClearAngle()
		end
	end

	local color = BaseAddon:ParseColorConfig(self.config, extraDataColors)
	local inactiveColor = BaseAddon:ParseColorConfig(self.config.inactive or {}, extraDataColors)
	self:Update(current, maximum, color, inactiveColor)
end

function Instance:UpdateHighlight(highlight, baseAngle, angle, color)
	if not color or color[4] <= 0.0 then
		highlight:ClearAngle()
	else
		highlight:SetAngle(360 + baseAngle - angle / 2.0, 360 + baseAngle + angle / 2.0)
		highlight:SetVertexColor(color[1], color[2], color[3], color[4])
	end
end

function Instance:Update(current, maximum, activeColor, inactiveColor)
	if not self.tracker:ShouldLoadRightNow() then
		for _, highlight in pairs(self.highlights) do
			highlight:ClearAngle()
		end
		return
	end

	if current and maximum then
		local initialAngle = self.config.initialAngle or 0
		local fullAngle = self.config.fullAngle or 360
		local spaceAngle = self.config.spaceAngle or 20
		local singleAngle = self.config.stackAngle
		local endSpace = self.config.endSpace ~= false
		local reverseStacks = self.config.reverseStacks

		if not singleAngle or singleAngle <= 0 then
			singleAngle = (fullAngle - spaceAngle * (maximum - (endSpace and 0 or 1))) / maximum
		end

		local totalWidth = singleAngle * maximum + spaceAngle * (maximum - (endSpace and 0 or 1))
		local offset = -totalWidth / 2 + singleAngle / 2

		for index, highlight in pairs(self.highlights) do
			local actualIndex = (reverseStacks and (maximum - index + 1) or index)
			local active = current >= index
			local color = active and activeColor or inactiveColor
			self:UpdateHighlight(highlight, initialAngle + offset + (spaceAngle + singleAngle) * (actualIndex - 1), singleAngle, color)
		end
	else
		for _, highlight in pairs(self.highlights) do
			highlight:ClearAngle()
		end
	end
end