local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local frames = {}

function Addon:OnInitialize()
	Addon.CustomFrameType.__Private:Register()

	hooksecurefunc("CreateFrame", function(type, name, ...)
		if name then
			Addon:SetupFrameIfNeeded(_G[name])
		end
	end)

	for key, value in pairs(_G) do
		if type(value) == "table" then
			if value.GetName and value.GetObjectType and value.IsObjectType then
				self:SetupFrameIfNeeded(frame)
			end
		end
	end
end

function Addon:SetupFrameIfNeeded(frame)
	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "frame" and tracker.frameName == frame:GetName() then
			self:SetupFrame(frame)
		end
	end
end

function Addon:SetupFrame(frame)
	if not frame[addonName.."hooked"] then
		frame:HookScript("OnShow", function(self)
			Addon:SetupFrameIndicators(self)
		end)
		frame:HookScript("OnHide", function(self)
			Addon:SetupFrameIndicators(self)
		end)
		frame[addonName.."hooked"] = true
	end
	if frame:IsVisible() then
		self:SetupFrameIndicators(frame)
	end
end

function Addon:SetupFrameIndicators(frame)
	self:ClearFrameIndicators(frame)
	if frame:IsVisible() then
		self:CreateFrameIndicators(frame)
	end
end

function Addon:ClearFrameIndicators(frame)
	if not frame[addonName.."_indicators"] then
		return
	end

	local indicators = frame[addonName.."_indicators"]
	for _, indicator in pairs(indicators) do
		indicator.factory:Free(indicator)
	end
	S:Clear(indicators)

	frames[frame:GetName()] = nil
end

local function AddFrameIndicator(frame, indicator)
	if not frame[addonName.."_indicators"] then
		frame[addonName.."_indicators"] = {}
	end

	local indicators = frame[addonName.."_indicators"]
	table.insert(indicators, indicator)
end

function Addon:CreateFrameIndicators(frame)
	frames[frame:GetName()] = frame

	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "frame" and tracker.frameName == frame:GetName() then
			for _, indicatorConfig in pairs(tracker.indicatorConfigs) do
				local indicator = Addon.IndicatorFactory:Instantiate(frame, nil, indicatorConfig, tracker)
				if indicator then
					AddFrameIndicator(frame, indicator)
				end
			end
		end
	end
end