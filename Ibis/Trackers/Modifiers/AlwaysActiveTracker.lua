local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.AlwaysActiveTracker = Class
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
	Private.factory = Addon.TrackerFactory:New("alwaysactive", "Always Active")
	Private.factory.priority = 2

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
	if current then
		return current, maximum
	else
		return 0.0, maximum or 1.0
	end
end

function Instance:Serialize()
	return self.tracker:Serialize()
end