local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local weakAuras = {}
Addon.weakAuras = weakAuras

function Addon:OnInitialize()
	Addon.WeakAuraFrameType.__Private:Register()

	BaseAddon:RegisterDeserializeDelegate(function()
		Addon:ResetupAllWeakAuraIndicators()

		for _, tracker in pairs(BaseAddon.trackers) do
			if tracker.frameType.type == "weakaura" and tracker.weakAuraName then
				local weakAura = WeakAuras.regions[tracker.weakAuraName]
				if weakAura then
					Addon:SetupWeakAuraIfNeeded(weakAura)
				end
			end
		end
	end)
	BaseAddon:RegisterTrackerUpdateDelegate(function(tracker)
		Addon:ResetupAllWeakAuraIndicators()
	end)

	C_Timer.After(0.0, function()
		hooksecurefunc(WeakAuras, "pAdd", function(data)
			if data.id then
				local weakAura = WeakAuras.regions[data.id]
				if weakAura then
					Addon:SetupWeakAuraIfNeeded(weakAura)
				end
			end
		end)
	end)
end

function Addon:SetupWeakAuraIfNeeded(weakAura)
	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "weakaura" and tracker.weakAuraName == weakAura.id then
			self:SetupWeakAura(weakAura)
			return
		end
	end
end

function Addon:SetupWeakAura(weakAura)
	if not weakAura.region[addonName.."hooked"] then
		weakAura.region:HookScript("OnShow", function(self)
			Addon:SetupWeakAuraIndicators(weakAura)
		end)
		weakAura.region:HookScript("OnHide", function(self)
			Addon:SetupWeakAuraIndicators(weakAura)
		end)
		weakAura.region[addonName.."hooked"] = true
	end
	if weakAura.region:IsVisible() then
		self:SetupWeakAuraIndicators(weakAura)
	end
end

function Addon:ResetupAllWeakAuraIndicators()
	local clonedWeakAuras = S:Clone(weakAuras)
	for _, weakAura in pairs(clonedWeakAuras) do
		self:SetupWeakAuraIndicators(weakAura)
	end
end

function Addon:SetupWeakAuraIndicators(weakAura)
	self:ClearWeakAuraIndicators(weakAura)
	if weakAura.region:IsVisible() then
		self:CreateWeakAuraIndicators(weakAura)
	end
end

function Addon:ClearWeakAuraIndicators(weakAura)
	if not weakAura.region[addonName.."_indicators"] then
		return
	end

	local indicators = weakAura.region[addonName.."_indicators"]
	for _, indicator in pairs(indicators) do
		indicator.factory:Free(indicator)
	end
	S:Clear(indicators)

	weakAuras[weakAura.id] = nil
end

local function AddWeakAuraIndicator(weakAura, indicator)
	if not weakAura.region[addonName.."_indicators"] then
		weakAura.region[addonName.."_indicators"] = {}
	end

	local indicators = weakAura.region[addonName.."_indicators"]
	table.insert(indicators, indicator)
end

function Addon:CreateWeakAuraIndicators(weakAura)
	weakAuras[weakAura.id] = weakAura

	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "weakaura" and tracker.weakAuraName == weakAura.id then
			for _, indicatorConfig in pairs(tracker.indicatorConfigs) do
				local indicator = BaseAddon.IndicatorFactory:Instantiate(weakAura.region, nil, indicatorConfig, tracker)
				if indicator then
					AddWeakAuraIndicator(weakAura, indicator)
				end
			end
		end
	end
end