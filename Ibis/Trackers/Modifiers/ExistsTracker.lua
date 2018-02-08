local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.ExistsTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionType, tracker)
	local obj = Addon.Tracker:New(actionType)
	S:CloneInto(Class.prototype, obj)
	obj.tracker = tracker
	return obj
end

function Private:Register()
	Private.factory = Addon.TrackerFactory:New("exists", "Exists")
	Private.factory.priority = 1

	function Private.factory:Create(tracker)
		return Class:New(
			tracker.actionType,
			tracker
		)
	end

	function Private.factory:CreateConfigMenu(configAddon, tracker, container)
		tracker.tracker.factory:CreateConfigMenu(configAddon, tracker.tracker, container)
	end

	Addon:RegisterTrackerModifierFactory(Private.factory)
end

function Instance:GetValue()
	local current, maximum = self.tracker:GetValue()
	if not current then
		return nil, maximum or 1.0
	else
		return maximum, maximum
	end
end

function Instance:Serialize()
	return self.tracker:Serialize()
end