local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.FrameType = Class
local Instance = Class.prototype

local factories = {}

function Class:New(type, name)
	local obj = S:DeepClone(Class.prototype)
	obj.type = type
	obj.name = name
	return obj
end

function Class:Register(factory)
	factories[factory.type or ""] = factory
end

function Class:Get(type)
	return factories[type or ""]
end

function Class:CreateConfigMenu(configAddon, tracker, container)
	if S:IsEmpty(factories) then
		return
	end

	local AceGUI = LibStub("AceGUI-3.0")
	tracker = tracker:GetBase()

	local sortedFactories = S:Values(factories)
	table.sort(sortedFactories, function(a, b)
		if a.type == nil then
			return true
		end
		if b.type == nil then
			return false
		end
		return a.name < b.name
	end)

	local actionHeading = AceGUI:Create("Heading")
	actionHeading:SetText("Action")
	actionHeading:SetFullWidth(true)
	container:AddChild(actionHeading)

	local actionTypes = S:Map(sortedFactories, function(factory)
		return factory.type or ""
	end)
	local actionNames = S:Map(sortedFactories, function(factory)
		return factory.name
	end)

	local actionTypeDropdown = AceGUI:Create("Dropdown")
	actionTypeDropdown:SetLabel("Type")
	actionTypeDropdown:SetList(actionNames)
	actionTypeDropdown:SetValue(S:KeyOf(actionTypes, tracker.actionType or actionTypes[1]))
	actionTypeDropdown:SetFullWidth(true)
	actionTypeDropdown:SetCallback("OnValueChanged", function(self, event, key)
		local value = actionTypes[key]
		if value == "" then
			value = nil
		end
		tracker.actionType = value
		tracker.frameType = Addon.FrameType:Get(value)
		configAddon:Refresh(tracker)
	end)
	container:AddChild(actionTypeDropdown)

	tracker.frameType:CreateConfigMenu(configAddon, tracker, container)
end

function Instance:GetIcon(tracker, withPlaceholderTexture)
	return withPlaceholderTexture and "Interface/Icons/INV_Misc_QuestionMark" or nil
end

function Instance:GetName(tracker)
	return self.name
end

function Instance:Serialize(tracker, output)
end

function Instance:Deserialize(input, tracker)
end

function Instance:CreateConfigMenu(configAddon, tracker, container)
end

function Instance:GetActionName(tracker)
	return nil
end

function Instance:GetDefaultTexture(parentFrame)
	return nil, nil
end