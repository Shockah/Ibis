local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.CooldownTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, trackerAction, trackerActionType)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.trackerAction = trackerAction
	obj.trackerActionType = trackerActionType
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("cooldown", "Cooldown")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track

		local tracker = Class:New(
			config.actionName,
			config.actionType,
			track.trackerAction,
			track.trackerActionType
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

		local actionTypes = {
			"",
			"<any>",
			"spell",
			"item",
		}

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

		local spellEditbox = AceGUI:Create("EditBox")
		spellEditbox:SetLabel("Action (optional)")
		spellEditbox:SetText(tracker.trackerAction)
		spellEditbox:SetFullWidth(true)
		spellEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			tracker.trackerAction = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		container:AddChild(spellEditbox)

		local actionTypeValue = 1
		if tracker.trackerActionType then
			if tracker.trackerActionType == true then
				actionTypeValue = 2
			else
				actionTypeValue = S:KeyOf(actionTypes, tracker.trackerActionType)
			end
		end
		local actionTypeDropdown = AceGUI:Create("Dropdown")
		actionTypeDropdown:SetLabel("Action type (optional)")
		actionTypeDropdown:SetList(actionTypes)
		actionTypeDropdown:SetValue(actionTypeValue)
		actionTypeDropdown:SetFullWidth(true)
		actionTypeDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = nil
			if key == 2 then
				value = true
			elseif key > 2 then
				value = actionTypes[key]
			end
			tracker.trackerActionType = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(actionTypeDropdown)

		local chargesCheckbox = AceGUI:Create("CheckBox")
		chargesCheckbox:SetLabel("Charges")
		chargesCheckbox:SetValue(tracker.charges)
		chargesCheckbox:SetFullWidth(true)
		chargesCheckbox:SetCallback("OnValueChanged", function(self, event, value)
			tracker.charges = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(chargesCheckbox)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		trackerAction = self.trackerAction,
		trackerActionType = self.trackerActionType,
		charges = self.charges,
	}
end

function Instance:GetValue()
	local type = self.trackerActionType
	if type == nil then
		type = self.actionType
	elseif type == true then
		type = nil
	end

	if type == "spell" then
		return self:GetSpellCooldown()
	elseif type == "item" then
		return self:GetItemCooldown()
	elseif not type then
		local a, b
		if not a then
			a, b = self:GetSpellCooldown()
		end
		return a, b
	end
end

function Instance:GetSpellCooldown()
	if self.charges then
		return self:GetSpellChargeCooldown()
	else
		return self:GetActualSpellCooldown()
	end
end

function Instance:GetSpellChargeCooldown()
	local spell = self.trackerAction or self.actionName
	local charges, maxCharges, start, duration = GetSpellCharges(spell)
	if charges then
		if charges >= maxCharges then
			return 1.0, 1.0
		else
			local f = (GetTime() - start) / duration
			f = min(max(f, 0.0), 1.0)
			return f, 1.0
		end
	else
		return nil, nil
	end
end

function Instance:GetActualSpellCooldown()
	local spell = self.trackerAction or self.actionName
	if not spell then
		return nil, nil
	end

	local start, duration = GetSpellCooldown(spell)
	if start then
		if start == 0 then
			return 1.0, 1.0
		else
			local f = (GetTime() - start) / duration
			f = min(max(f, 0.0), 1.0)
			return f, 1.0
		end
	else
		return nil, nil
	end
end

function Instance:GetItemCooldown()
	local item = self.trackerAction or self.actionName
	if not item then
		return nil, nil
	end

	-- getting the item ID
	item = GetItemInfoInstant(item)
	if not item then
		return nil, nil
	end

	local start, duration = GetItemCooldown(item)
	if start then
		if start == 0 then
			return 1.0, 1.0
		else
			local f = (GetTime() - start) / duration
			f = min(max(f, 0.0), 1.0)
			return f, 1.0
		end
	else
		return nil, nil
	end
end