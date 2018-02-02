local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

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

	indicator.highlight = Addon.RoundHighlight:Get(indicator)
	indicator.highlight:SetAllPoints()

	return indicator
end

function Instance:Setup(action, config, tracker)
	self.config = config
	self.action = action
	self.tracker = tracker

	self:ClearAllPoints()
	self:SetPoint("CENTER", action.button, "CENTER")
	
	self.highlight:SetTexture(config.texture or action.button.Border:GetTexture())
	self.highlight:SetBlendMode(config.blendMode or "ADD")
	self.highlight:SetFrameStrata(config.strata or "MEDIUM")
	self.highlight:SetDrawLayer(config.layer or "BORDER")

	local function OnUpdate(self)
		local scale = config.scale or 1.0
		scale = scale * action.button:GetScale()
		self:SetSize(action.button:GetWidth() * scale, action.button:GetHeight() * scale)

		self:UpdateIndicator()
	end
	self:SetScript("OnUpdate", OnUpdate)
	OnUpdate(self)

	self:Show()
end

function Instance:UpdateIndicator()
	local current, maximum, extraData = self.tracker:GetValue()
	local extraDataColors = extraData and extraData.colors

	self:UpdateAngle(current, maximum)
	self:UpdateColor(extraDataColors)
end

function Instance:UpdateAngle(current, maximum)
	if not self.tracker:ShouldLoadRightNow() then
		self.highlight:ClearAngle()
		return
	end

	local current, maximum = self.tracker:GetValue()
	if current then
		local f = current / maximum
		local angle = (1.0 - f) * 360

		local initialAngle = self.config.initialAngle or 0
		if f <= 0 then
			self.highlight:ClearAngle()
		else
			self.highlight:SetAngle(initialAngle + angle / 2.0, initialAngle + 360 - angle / 2.0)
		end
	else
		self.highlight:ClearAngle()
	end
end

function Instance:UpdateColor(extraDataColors)
	local color = BaseAddon:ParseColorConfig(self.config, extraDataColors)
	self.highlight:SetVertexColor(color[1], color[2], color[3], color[4])
end