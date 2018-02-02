local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.ReverseTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, tracker)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.tracker = tracker
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("reverse", "Reverse")

	function factory:Create(tracker)
		return Class:New(
			tracker.actionName,
			tracker.actionType,
			tracker
		)
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		tracker.tracker.factory:CreateConfigMenu(configAddon, tracker.tracker, container)
	end

	Addon:RegisterTrackerModifierFactory(factory)
end

function Instance:GetValue()
	local current, maximum = self.tracker:GetValue()
	if self:HasModifier(Addon.ExistsTracker.__Private.factory) then
		if not current then
			return 1, 1
		else
			return nil, maximum or 1.0
		end
	else
		if not current then
			return nil, maximum or 1.0
		else
			return maximum - current, maximum
		end
	end
end

function Instance:Serialize()
	return self.tracker:Serialize()
end