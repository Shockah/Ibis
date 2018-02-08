local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local Class = {
	prototype = {},
}
Addon.CustomFrameType = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(type, name)
	local obj = BaseAddon.FrameType:New(type, name)
	S:CloneInto(Class.prototype, obj)
	return obj
end

function Private:Register()
	BaseAddon.FrameType:Register(Class:New("frame", "Frame"))
end

local function setupFrameIfNeeded(frameName)
	if frameName then
		local frame = _G[frameName]
		if frame then
			Addon:SetupFrame(frame)
		end
	end
end

function Instance:CreateConfigMenu(configAddon, tracker, container)
	local AceGUI = LibStub("AceGUI-3.0")

	local frameNameEditbox = AceGUI:Create("EditBox")
	frameNameEditbox:SetLabel("Frame name")
	frameNameEditbox:SetText(tracker.frameName)
	frameNameEditbox:SetFullWidth(true)
	frameNameEditbox:SetCallback("OnEnterPressed", function(self, event, text)
		local oldName = tracker.frameName
		tracker.frameName = S:StringOrNil(text)
		setupFrameIfNeeded(oldName)
		setupFrameIfNeeded(tracker.frameName)
		self:ClearFocus()
		configAddon:Refresh(tracker)
	end)
	container:AddChild(frameNameEditbox)
end

function Instance:GetName(tracker)
	return tracker.frameName or "<empty>"
end

function Instance:Serialize(tracker, output)
	output.frameName = tracker.frameName
end

function Instance:Deserialize(input, tracker)
	tracker.frameName = input.frameName
end