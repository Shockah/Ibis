local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {
		isActionFrameType = true,
	},
}
Addon.ActionFrameType = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(type, name)
	local obj = Addon.FrameType:New(type, name)
	S:CloneInto(Class.prototype, obj)
	return obj
end

function Private:Register()
	Addon.FrameType:Register(Class:New(nil, "Action: Any"))
	Addon.FrameType:Register(Class:New("spell", "Action: Spell"))
	Addon.FrameType:Register(Class:New("item", "Action: Item"))
	Addon.FrameType:Register(Class:New("flyout", "Action: Flyout"))
	Addon.FrameType:Register(Class:New("companion", "Action: Companion"))
	Addon.FrameType:Register(Class:New("macro", "Action: Macro"))
end

function Instance:GetActionName(tracker)
	return tracker.actionName
end

function Instance:MatchesAction(tracker, action)
	if tracker.actionType and tracker.actionType ~= action.type then
		return false
	end

	if tracker.actionName then
		local number = tonumber(tracker.actionName)
		if number then
			if number ~= action.slot then
				return false
			end
		else
			if tracker.actionName ~= action.name then
				return false
			end
		end
	end

	return true
end

function Instance:CreateConfigMenu(configAddon, tracker, container)
	local AceGUI = LibStub("AceGUI-3.0")

	local actionNameEditbox = AceGUI:Create("EditBox")
	actionNameEditbox:SetLabel("Action name")
	actionNameEditbox:SetText(tracker.actionName)
	actionNameEditbox:SetFullWidth(true)
	actionNameEditbox:SetCallback("OnEnterPressed", function(self, event, text)
		tracker.actionName = S:StringOrNil(text)
		self:ClearFocus()
		configAddon:Refresh(tracker)
	end)
	container:AddChild(actionNameEditbox)
end

function Instance:GetIcon(tracker, withPlaceholderTexture)
	return Addon.Tracker:GetIcon(tracker.actionType, tracker.actionName, withPlaceholderTexture)
end

function Instance:GetNameWithoutType(tracker)
	local number = tonumber(tracker.actionName)
	if number then
		return "Action Button #"..number
	end

	return (tracker.actionName or "<empty>")
end

function Instance:GetName(tracker)
	return self:GetNameWithoutType(tracker)
end

function Instance:Serialize(tracker, output)
	output.actionName = tracker.actionName
end

function Instance:Deserialize(input, tracker)
	tracker.actionName = input.actionName
end