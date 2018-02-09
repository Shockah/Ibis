local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local frames = {}

local function IsWidget(value)
	if not value then
		return false
	end
	if type(value) == "table" then
		if value.GetName and value.GetObjectType and value.IsObjectType then
			return true
		end
	end
	return false
end

function Addon:OnInitialize()
	Addon.CustomFrameType.__Private:Register()

	BaseAddon:RegisterDeserializeDelegate(function()
		Addon:ResetupAllFrameIndicators()

		for _, tracker in pairs(BaseAddon.trackers) do
			if tracker.frameType.type == "frame" and tracker.frameName then
				local frame = _G[tracker.frameName]
				if IsWidget(frame) then
					Addon:SetupFrameIfNeeded(frame)
				end
			end
		end
	end)
	BaseAddon:RegisterTrackerUpdateDelegate(function(tracker)
		Addon:ResetupAllFrameIndicators()
	end)

	hooksecurefunc("CreateFrame", function(type, name, ...)
		if name then
			local frame = _G[name]
			if IsWidget(frame) then
				Addon:SetupFrameIfNeeded(frame)
			end
		end
	end)
end

function Addon:SetupFrameIfNeeded(frame)
	if frame.IsForbidden then
		local err, result = pcall(function()
			return frame:IsForbidden()
		end)
		if not err and result then
			return
		end
	end

	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "frame" and tracker.frameName == frame:GetName() then
			self:SetupFrame(frame)
			return
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

function Addon:ResetupAllFrameIndicators()
	local clonedFrames = S:Clone(frames)
	for _, frame in pairs(clonedFrames) do
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
				local indicator = BaseAddon.IndicatorFactory:Instantiate(frame, nil, indicatorConfig, tracker)
				if indicator then
					AddFrameIndicator(frame, indicator)
				end
			end
		end
	end
end