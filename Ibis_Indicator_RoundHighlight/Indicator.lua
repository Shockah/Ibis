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

	indicator.highlight = Addon.RoundHighlight:Get(indicator)
	indicator.highlight:SetAllPoints()

	return indicator
end

function Instance:Setup(parentFrame, action, config, tracker)
	self.config = config
	self.action = action
	self.tracker = tracker

	self:ClearAllPoints()
	self:SetPoint("CENTER", parentFrame, "CENTER")

	local texture = config.texture or tracker.frameType:GetDefaultTexture(parentFrame) or nil
	self.highlight:SetTexture(texture)
	self.highlight:SetBlendMode(config.blendMode or "ADD")
	self.highlight:SetFrameStrata(config.strata or "MEDIUM")
	self.highlight:SetDrawLayer(config.layer or "BORDER")

	local function OnUpdate(self)
		local scale = config.scale or 1.0
		scale = scale * parentFrame:GetScale()
		self:SetSize(parentFrame:GetWidth() * scale, parentFrame:GetHeight() * scale)

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
		local initialAngle = self.config.initialAngle or 0
		local fullAngle = self.config.fullAngle or 360
		local fillMode = self.config.fillMode or 0

		initialAngle = initialAngle + fullAngle * fillMode

		local f = current / maximum
		f = f * (fullAngle / 360)
		local angle = (1.0 - f) * 360

		if f <= 0 then
			self.highlight:ClearAngle()
		else
			self.highlight:SetAngle(initialAngle + angle / 2.0 + angle * fillMode, initialAngle + 360 - angle / 2.0 + angle * fillMode)
		end
	else
		self.highlight:ClearAngle()
	end
end

function Instance:UpdateColor(extraDataColors)
	local color = BaseAddon:ParseColorConfig(self.config, extraDataColors)
	self.highlight:SetVertexColor(color[1], color[2], color[3], color[4])
end