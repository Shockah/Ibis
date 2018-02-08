local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.TotemTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionType, name)
	local obj = Addon.Tracker:New(actionType)
	S:CloneInto(Class.prototype, obj)
	obj.name = name
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("totem", "Totem")

	function factory:CreateBlank()
		local tracker = self:Create({
			track = {
				unit = "player",
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track

		local tracker = Class:New(
			config.actionType,
			track.name
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

		local totemEditbox = AceGUI:Create("EditBox")
		totemEditbox:SetLabel("Totem (optional)")
		totemEditbox:SetText(tracker.name)
		totemEditbox:SetFullWidth(true)
		totemEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			tracker.name = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		container:AddChild(totemEditbox)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		name = self.name,
	}
end

function Instance:GetValue()
	local myTotem = self.name or self.frameType:GetActionName(self)
	if not myTotem then
		return nil, nil
	end

	for i = 1, 5 do
		local haveTotem, name, startTime, duration, icon = GetTotemInfo(i)
		if haveTotem and name == myTotem then
			local f = (GetTime() - startTime) / duration
			f = min(max(1 - f, 0.0), 1.0)
			return f, 1.0
		end
	end
	return nil, nil
end