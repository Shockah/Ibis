local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.AuraTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionType, unit, name, buff, stacks)
	local obj = Addon.Tracker:New(actionType)
	S:CloneInto(Class.prototype, obj)
	obj.unit = unit
	obj.name = name
	obj.buff = buff
	obj.stacks = stacks or nil
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("aura", "Aura")

	function factory:CreateBlank()
		local tracker = self:Create({
			track = {
				unit = "player",
				buff = true,
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track
		if not track.unit or track.buff == nil then
			return nil
		end

		local tracker = Class:New(
			config.actionType,
			track.unit,
			track.name,
			track.buff,
			track.stacks or nil
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

		local unitTypes = {
			"player",
			"target",
			"targettarget",
			"pet",
			"focus",
			"focustarget",
			"friendly",
		}

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

		local auraEditbox = AceGUI:Create("EditBox")
		auraEditbox:SetLabel("Aura (optional)")
		auraEditbox:SetText(tracker.name)
		auraEditbox:SetFullWidth(true)
		auraEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			tracker.name = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		container:AddChild(auraEditbox)

		local unitDropdown = AceGUI:Create("Dropdown")
		unitDropdown:SetLabel("Unit")
		unitDropdown:SetList(unitTypes)
		unitDropdown:SetValue(S:KeyOf(unitTypes, tracker.unit))
		unitDropdown:SetFullWidth(true)
		unitDropdown:SetCallback("OnValueChanged", function(self, event, key)
			tracker.unit = unitTypes[key]
			configAddon:Refresh(tracker)
		end)
		container:AddChild(unitDropdown)

		local buffCheckbox = AceGUI:Create("CheckBox")
		buffCheckbox:SetLabel("Buff")
		buffCheckbox:SetValue(tracker.buff)
		buffCheckbox:SetFullWidth(true)
		buffCheckbox:SetCallback("OnValueChanged", function(self, event, value)
			tracker.buff = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(buffCheckbox)

		local stacksEditbox = AceGUI:Create("EditBox")
		stacksEditbox:SetLabel("Max stacks (optional)")
		stacksEditbox:SetText(tracker.stacks or "")
		stacksEditbox:SetFullWidth(true)
		stacksEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			text = S:StringOrNil(text)
			if text then
				local number = tonumber(text)
				if number then
					tracker.stacks = number
				end
			else
				tracker.stacks = nil
			end
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		container:AddChild(stacksEditbox)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		unit = self.unit,
		name = self.name,
		buff = self.buff,
		stacks = self.stacks,
	}
end

function Instance:GetValue()
	local auraName = self.name or self.frameType:GetActionName(self)
	if not auraName then
		return nil, self.stacks
	end

	local units = {}
	if self.unit == "friendly" then
		if IsInRaid() then
			for i = 1, 40 do
				table.insert(units, "raid"..i)
			end
			for i = 1, 40 do
				table.insert(units, "raidpet"..i)
			end
		elseif IsInGroup() then
			table.insert(units, "player")
			for i = 1, 4 do
				table.insert(units, "party"..i)
			end

			table.insert(units, "pet")
			for i = 1, 4 do
				table.insert(units, "partypet"..i)
			end
		else
			table.insert(units, "player")
			table.insert(units, "pet")
		end
	else
		table.insert(units, self.unit)
	end

	for _, unit in pairs(units) do
		if UnitExists(unit) then
			local name, _, _, count, _, duration, expires = UnitAura(unit, auraName, nil, "PLAYER|"..(self.buff and "HELPFUL" or "HARMFUL"))
			if name and (expires == 0 or GetTime() < expires) then
				local f = 0
				if self.stacks then
					f = count / self.stacks
				else
					if expires == 0 then
						f = 1
					else
						f = (expires - GetTime()) / duration
					end
				end

				f = min(max(f, 0.0), 1.0)
				if self.stacks then
					return count, self.stacks
				else
					return f, 1.0
				end
			end
		end
	end

	return nil, self.stacks
end