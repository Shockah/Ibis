local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local LibDualSpec = LibStub("LibDualSpec-1.0", true)
local LibButtonGlow = LibStub("LibButtonGlow-1.0", true)

Addon.defaultTrackerConfigs = {}
Addon.allTrackers = {}
Addon.sessionTrackers = {}
Addon.trackers = {}

local actionButtonHandlers = {}
local indicatorFactories = {}

local original_Vanilla_ShowOverlayGlow = nil
local original_LibButtonGlow_ShowOverlayGlow = nil

function Addon:OnInitialize()
	self:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
	self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")

	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

	Addon.AuraTracker.__Private:Register()
	Addon.CooldownTracker.__Private:Register()
	Addon.HealthTracker.__Private:Register()
	Addon.LevelTracker.__Private:Register()
	Addon.PostCastTimerTracker.__Private:Register()
	Addon.PowerTracker.__Private:Register()
	Addon.ReputationTracker.__Private:Register()
	Addon.TotemTracker.__Private:Register()

	Addon.ExistsTracker.__Private:Register()
	Addon.ReverseTracker.__Private:Register()

	self.defaultTrackerConfigs = {}

	self.db = LibStub("AceDB-3.0"):New(addonName.."DB", {
		profile = {
			trackers = self.defaultTrackerConfigs,
		},
	}, true)
	self.db.RegisterCallback(self, "OnProfileChanged", "DeserializeConfig")
	self.db.RegisterCallback(self, "OnProfileCopied", "DeserializeConfig")
	self.db.RegisterCallback(self, "OnProfileReset", "DeserializeConfig")
	self.db.RegisterCallback(self, "OnProfileShutdown", "SerializeConfig")
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "SerializeConfig")

	if LibDualSpec then
		LibDualSpec:EnhanceDatabase(self.db, addonName)
	end
end

function Addon:OnEnable()
	if not self.db.profile.trackers then
		self.db.profile.trackers = self.defaultTrackerConfigs
	end

	C_Timer.After(0.0, function()
		self:DeserializeConfig()
		self:UpdateSettings()
	end)
end

function Addon:DeserializeConfig()
	S:Clear(self.allTrackers)
	if not self.db.profile.trackers then
		self.db.profile.trackers = {}
	end
	for _, trackerConfig in pairs(self.db.profile.trackers) do
		local tracker = self.TrackerFactory:Instantiate(trackerConfig)
		if tracker then
			table.insert(self.allTrackers, tracker)
		end
	end
	self:ReloadSessionTrackers()

	local ConfigAddon = _G[addonName.."_Config"]
	if ConfigAddon then
		if ConfigAddon.ConfigFrame then
			ConfigAddon:CreateConfigurationFrame()
		end
	end
end

function Addon:SerializeConfig()
	local trackerConfigs = {}
	self.db.profile.trackers = trackerConfigs

	for _, tracker in pairs(self.allTrackers) do
		table.insert(trackerConfigs, self.TrackerFactory:Serialize(tracker))
	end
end

function Addon:UpdateSettings()
	if not original_Vanilla_ShowOverlayGlow then
		original_Vanilla_ShowOverlayGlow = ActionButton_ShowOverlayGlow
		if LibButtonGlow then
			original_LibButtonGlow_ShowOverlayGlow = LibButtonGlow.ShowOverlayGlow
		end
	end

	if self.db.profile.hideGlow then
		local blankFunction = function() end
		--ActionButton_ShowOverlayGlow = blankFunction
		if LibButtonGlow then
			LibButtonGlow.ShowOverlayGlow = blankFunction
		end
	else
		--ActionButton_ShowOverlayGlow = original_Vanilla_ShowOverlayGlow
		if LibButtonGlow then
			LibButtonGlow.ShowOverlayGlow = original_LibButtonGlow_ShowOverlayGlow
		end
	end
end

function Addon:ReloadSessionTrackers()
	self.sessionTrackers = S:Filter(self.allTrackers, function(tracker)
		return tracker:ShouldLoadAtAll()
	end)
	self:ReloadTrackers()
end

function Addon:ReloadTrackers()
	self.trackers = S:Filter(self.sessionTrackers, function(tracker)
		return tracker:ShouldLoad()
	end)
	self:SetupAllActionButtons()
end

function Addon:ACTIONBAR_SLOT_CHANGED(event, slot)
	self:SetupFirstActionButton(slot)
end

function Addon:ACTIVE_TALENT_GROUP_CHANGED(event)
	self:ReloadTrackers()
	self:SetupAllActionButtons()
end

function Addon:PLAYER_TALENT_UPDATE(event)
	self:ReloadTrackers()
	self:SetupAllActionButtons()
end

function Addon:UPDATE_SHAPESHIFT_FORM(event)
	self:SetupAllActionButtons()
end

function Addon:UPDATE_VEHICLE_ACTIONBAR(event)
	self:SetupAllActionButtons()
end

function Addon:UNIT_ENTERED_VEHICLE(event)
	self:SetupAllActionButtons()
end

function Addon:UNIT_EXITED_VEHICLE(event)
	self:SetupAllActionButtons()
end

function Addon:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, rank, lineID, spellID)
	for _, tracker in pairs(self.allTrackers) do
		if S:Contains(tracker.factory.registeredEvents, event) then
			tracker[event](tracker, event, unitID, spell, rank, lineID, spellID)
		end
	end
end

function Addon:RegisterActionButtonHandler(func)
	table.insert(actionButtonHandlers, 1, func)
	self:SetupActionButtons(func())
end

function Addon:RegisterIndicatorFactory(indicatorFactory)
	self.IndicatorFactory:Register(indicatorFactory)
end

function Addon:RegisterTrackerFactory(trackerFactory)
	self.TrackerFactory:Register(trackerFactory)
end

function Addon:RegisterTrackerModifierFactory(trackerFactory)
	self.TrackerFactory:RegisterModifier(trackerFactory)
end

function Addon:ParseColorConfig(config, extraDataColors, inConfig)
	local color = { 1.0, 1.0, 1.0, 1.0 }

	--[[if config.pulsing then
		color[4] = sin(GetTime() * 720) * 0.25 + 0.75
	end]]

	if config.rgbi then
		for i = 1, 3 do
			color[i] = config.rgbi[i] / 255
		end
	end
	if config.rgb then
		for i = 1, 3 do
			color[i] = config.rgb[i]
		end
	end

	if config.rgbai then
		for i = 1, 4 do
			color[i] = config.rgbai[i] / 255
		end
	end
	if config.rgba then
		for i = 1, 4 do
			color[i] = config.rgba[i]
		end
	end

	if not inConfig then
		if extraDataColors and config.extraDataColor then
			local extraDataColor = extraDataColors[config.extraDataColor]
			if extraDataColor then
				for i = 1, 4 do
					color[i] = extraDataColor[i]
				end
			end
		end
	end

	if config.rgbAdd then
		for i = 1, 3 do
			color[i] = color[i] + config.rgbAdd[i]
		end
	end

	if config.rgbMult then
		for i = 1, 3 do
			color[i] = color[i] * config.rgbMult[i]
		end
	end

	if not inConfig then
		if config.alphaPulsing then
			local frequency = config.alphaPulsing.frequency or 2.0
			local factor = config.alphaPulsing.factor or 0.0
			local f = sin(GetTime() * 360 * frequency) * factor * 0.5 + (1.0 - factor * 0.5)
			color[4] = color[4] * f
		end
	end

	return color
end

function Addon:SetupAllActionButtons()
	for _, actionButtonHandler in pairs(actionButtonHandlers) do
		self:SetupActionButtons(actionButtonHandler())
	end
end

function Addon:SetupActionButtons(actions)
	for _, action in pairs(actions) do
		self:SetupActionButton(action)
	end
end

function Addon:ClearButtonIndicators(button)
	if not button[addonName.."_indicators"] then
		return
	end

	local indicators = button[addonName.."_indicators"]
	for _, indicator in pairs(indicators) do
		indicator.factory:Free(indicator)
	end
	S:Clear(indicators)
end

local function AddButtonIndicator(button, indicator)
	if not button[addonName.."_indicators"] then
		button[addonName.."_indicators"] = {}
	end

	local indicators = button[addonName.."_indicators"]
	table.insert(indicators, indicator)
end

function Addon:SetupFirstActionButton(slot)
	local actions = S:FlatMap(actionButtonHandlers, function(actionButtonHandler)
		return actionButtonHandler()
	end)
	table.sort(actions, function(a, b)
		return a.priority > b.priority
	end)

	for _, action in pairs(actions) do
		if action.slot == slot then
			self:SetupActionButton(action)
			return
		end
	end
end

function Addon:SetupActionButton(action)
	self:ClearButtonIndicators(action.button)
	if not action.button:IsVisible() or not action.type then
		return
	end

	if not action.name then
		return
	end

	for _, tracker in pairs(self.trackers) do
		if tracker:Matches(action) then
			for _, indicatorConfig in pairs(tracker.indicatorConfigs) do
				local indicator = Addon.IndicatorFactory:Instantiate(action, indicatorConfig, tracker)
				if indicator then
					AddButtonIndicator(action.button, indicator)
				end
			end
			--TODO: handle optional `return`
			--return
		end
	end
end

function Addon:GetButtonAction(button)
	return button._state_action or ActionButton_GetPagedID(button) or ActionButton_CalculateAction(button) or button:GetAttribute('action') or 0
end