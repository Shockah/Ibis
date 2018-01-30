local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.TrackerFactory = Class
local Instance = Class.prototype

local factories = {}
local modifierFactories = {}

function Class:New(type, name)
	local obj = S:Clone(Class.prototype)
	obj.type = type
	obj.name = name
	return obj
end

function Class:Register(factory)
	factories[factory.type] = factory
end

function Class:RegisterModifier(factory)
	modifierFactories[factory.type] = factory
end

function Class:Instantiate(config)
	if not config or not config.actionName or not config.track or not config.track.type then
		return nil
	end

	local factory = factories[config.track.type]
	if not factory then
		return nil
	end

	local tracker = factory:Create(config)
	if tracker then
		tracker.factory = factory

		for _, modifierFactory in pairs(modifierFactories) do
			if config.track[modifierFactory.type] then
				tracker = modifierFactory:Create(tracker)
				tracker.factory = modifierFactory
			end
		end

		tracker.customName = config.customName
		tracker.faction = config.faction
		tracker.race = S:DeepClone(config.race)
		tracker.class = S:DeepClone(config.class)
		tracker.spec = config.spec
		tracker.talent = S:DeepClone(config.talent)
		tracker.equipped = S:DeepClone(config.equipped)
		tracker.combat = config.combat

		if config.indicators then
			for _, v in pairs(config.indicators) do
				table.insert(tracker.indicatorConfigs, S:DeepClone(v))
			end
		end
	end

	return tracker
end

function Class:Serialize(tracker)
	local serialized = {
		actionName = tracker.actionName,
		actionType = tracker.actionType,
		track = {},
		indicators = {},
	}
	S:CloneInto(tracker:Serialize(), serialized.track)
	S:CloneInto(tracker.indicatorConfigs, serialized.indicators)

	local innerTracker = tracker
	while innerTracker.tracker do
		serialized.track[innerTracker.factory.type] = true
		innerTracker = innerTracker.tracker
	end
	serialized.track.type = innerTracker.factory.type

	for _, modifierFactory in pairs(modifierFactories) do
		if tracker[modifierFactory.type] ~= nil then
			serialized.track[modifierFactory.type] = tracker[modifierFactory.type]
		end
	end

	serialized.customName = tracker.customName
	serialized.faction = tracker.faction
	serialized.race = S:DeepClone(tracker.race)
	serialized.class = S:DeepClone(tracker.class)
	serialized.spec = tracker.spec
	serialized.talent = S:DeepClone(tracker.talent)
	serialized.equipped = S:DeepClone(tracker.equipped)
	serialized.combat = tracker.combat

	return serialized
end

function Class:CreateConfigMenu(configAddon, container, func)
	if S:IsEmpty(factories) then
		return
	end

	local AceGUI = LibStub("AceGUI-3.0")

	local sortedFactories = S:Values(factories)
	table.sort(sortedFactories, function(a, b)
		return a.name < b.name
	end)

	for _, factory in pairs(sortedFactories) do
		local addTrackerButton = AceGUI:Create("Button")
		addTrackerButton:SetText("Add "..factory.name.." Tracker")
		addTrackerButton:SetFullWidth(true)
		addTrackerButton:SetCallback("OnClick", function(self, event)
			local tracker = factory:CreateBlank(tracker)
			func(tracker)
		end)
		container:AddChild(addTrackerButton)
	end
end

function Class:CreateConfigMenuForModifiers(configAddon, tracker, container)
	if S:IsEmpty(modifierFactories) then
		return
	end

	local AceGUI = LibStub("AceGUI-3.0")

	local modifiersHeading = AceGUI:Create("Heading")
	modifiersHeading:SetText("Modifiers")
	modifiersHeading:SetFullWidth(true)
	container:AddChild(modifiersHeading)

	local group = AceGUI:Create("SimpleGroup")
	group:SetLayout("Flow")
	group:SetFullWidth(true)
	container:AddChild(group)

	for _, modifierFactory in pairs(modifierFactories) do
		local modifierCheckbox = AceGUI:Create("CheckBox")
		modifierCheckbox:SetLabel(modifierFactory.name)
		modifierCheckbox:SetValue(tracker:HasModifier(modifierFactory))
		modifierCheckbox:SetRelativeWidth(0.5)
		modifierCheckbox:SetCallback("OnValueChanged", function(self, event, value)
			tracker:ToggleModifier(modifierFactory)
			configAddon:Refresh(tracker)
		end)
		group:AddChild(modifierCheckbox)
	end
end

function Instance:CreateBlank()
	return nil
end

function Instance:Create(config)
	return nil
end

function Instance:CreateConfigMenu(configAddon, tracker, container)
end