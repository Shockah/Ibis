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
	end)
	BaseAddon:RegisterReloadTrackersDelegate(function(tracker)
		Addon:ResetupAllWeakAuraIndicators()
	end)
	BaseAddon:RegisterTrackerUpdateDelegate(function(tracker)
		Addon:ResetupAllWeakAuraIndicators()
	end)

	C_Timer.After(0.0, function()
		hooksecurefunc(WeakAuras, "pAdd", function(data)
			--TODO: find a better way to handle just one WeakAura
			C_Timer.After(0.0, function()
				Addon:ResetupAllWeakAuraIndicators()
			end)
		end)
		hooksecurefunc(WeakAuras, "Rename", function(data, newid)
			--TODO: find a better way to handle just one WeakAura (need the old id)
			C_Timer.After(0.0, function()
				Addon:ResetupAllWeakAuraIndicators()
			end)
		end)
	end)
end

function Addon:SetupWeakAuraIfNeeded(weakAura)
	if not weakAura.region then
		return
	end
	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "weakaura" and tracker.weakAuraName == weakAura.region.id then
			self:SetupWeakAura(weakAura)
			return
		end
	end
end

function Addon:SetupWeakAura(weakAura)
	if not weakAura.region then
		return
	end
	if not weakAura.region[addonName.."_hooked"] then
		weakAura.region:HookScript("OnShow", function(self)
			Addon:SetupWeakAuraIndicators(weakAura)
		end)
		weakAura.region:HookScript("OnHide", function(self)
			Addon:SetupWeakAuraIndicators(weakAura)
		end)
		weakAura.region[addonName.."_hooked"] = true
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

	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "weakaura" and tracker.weakAuraName then
			local weakAura = WeakAuras.regions[tracker.weakAuraName]
			if weakAura then
				self:SetupWeakAuraIfNeeded(weakAura)
			end
		end
	end
end

function Addon:SetupWeakAuraIndicators(weakAura)
	if not weakAura.region then
		return
	end
	self:ClearWeakAuraIndicators(weakAura)
	if weakAura.region:IsVisible() then
		self:CreateWeakAuraIndicators(weakAura)
	end
end

function Addon:ClearWeakAuraIndicators(weakAura)
	if not weakAura.region then
		return
	end
	if not weakAura.region[addonName.."_indicators"] then
		return
	end

	local indicators = weakAura.region[addonName.."_indicators"]
	for _, indicator in pairs(indicators) do
		indicator.factory:Free(indicator)
	end
	S:Clear(indicators)

	weakAuras[weakAura.region.id] = nil
end

local function AddWeakAuraIndicator(weakAura, indicator)
	if not weakAura.region[addonName.."_indicators"] then
		weakAura.region[addonName.."_indicators"] = {}
	end

	local indicators = weakAura.region[addonName.."_indicators"]
	table.insert(indicators, indicator)
end

function Addon:CreateWeakAuraIndicators(weakAura)
	weakAuras[weakAura.region.id] = weakAura

	for _, tracker in pairs(BaseAddon.trackers) do
		if tracker.frameType.type == "weakaura" and tracker.weakAuraName == weakAura.region.id then
			for _, indicatorConfig in pairs(tracker.indicatorConfigs) do
				local indicator = BaseAddon.IndicatorFactory:Instantiate(weakAura.region, nil, indicatorConfig, tracker)
				if indicator then
					AddWeakAuraIndicator(weakAura, indicator)
				end
			end
		end
	end
end