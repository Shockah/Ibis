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

function Class:Get(action, config, tracker)
	local obj
	if S:IsEmpty(free) then
		obj = Private:Create(action, config, tracker)
	else
		obj = free[1]
		table.remove(free, 1)
		obj:SetParent(action.button)
	end
	obj:Setup(action, config, tracker)
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

function Private:Create(action, config, tracker)
	local indicator = CreateFrame("frame", nil, action.button or UIParent)
	S:CloneInto(Instance, indicator)

	indicator.highlights = {}

	return indicator
end

function Instance:Setup(action, config, tracker)
	self.config = config
	self.action = action
	self.tracker = tracker

	self:ClearAllPoints()
	self:SetPoint("CENTER", action.button, "CENTER")

	for _, highlight in pairs(self.highlights) do
		self:SetupHighlight(highlight)
	end

	local function OnUpdate(self)
		local scale = self.config.scale or 1.0
		scale = scale * self.action.button:GetScale()
		self:SetSize(self.action.button:GetWidth() * scale, self.action.button:GetHeight() * scale)

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

	highlight:SetTexture(self.config.texture or self.action.button.Border:GetTexture())
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

	if current then
		local initialAngle = self.config.initialAngle or 0
		local spaceAngle = self.config.spaceAngle or 20
		local singleAngle = self.config.stackAngle

		if not singleAngle then
			singleAngle = (360 - spaceAngle * maximum) / maximum
		end

		for index, highlight in pairs(self.highlights) do
			local active = current >= index
			local color = active and activeColor or inactiveColor
			self:UpdateHighlight(highlight, initialAngle + (spaceAngle + singleAngle) * (index - 1), singleAngle, color)
		end
	else
		for _, highlight in pairs(self.highlights) do
			highlight:ClearAngle()
		end
	end
end