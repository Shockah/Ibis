local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.PowerTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, unit, powerType)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.unit = unit
	obj.powerType = powerType or nil
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("power", "Power")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {
				unit = "player",
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track
		if not track.unit then
			return nil
		end

		local tracker = Class:New(
			config.actionName,
			config.actionType,
			track.unit,
			track.powerType or nil
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

		local powerTypes = {
			[-1] = "<any>",
			[SPELL_POWER_MANA] = "Mana",
			[SPELL_POWER_RAGE] = "Rage",
			[SPELL_POWER_FOCUS] = "Focus",
			[SPELL_POWER_ENERGY] = "Energy",
			[SPELL_POWER_COMBO_POINTS] = "Combo Points",
			[SPELL_POWER_RUNES] = "Runes",
			[SPELL_POWER_RUNIC_POWER] = "Runic Power",
			[SPELL_POWER_SOUL_SHARDS] = "Soul Shards",
			[SPELL_POWER_LUNAR_POWER] = "Lunar Power",
			[SPELL_POWER_HOLY_POWER] = "Holy Power",
			[SPELL_POWER_ALTERNATE_POWER] = "Alternate Power",
			[SPELL_POWER_MAELSTROM] = "Maelstrom",
			[SPELL_POWER_CHI] = "Chi",
			[SPELL_POWER_INSANITY] = "Insanity",
			[SPELL_POWER_ARCANE_CHARGES] = "Arcane Charges",
			[SPELL_POWER_FURY] = "Fury",
			[SPELL_POWER_PAIN] = "Pain",
		}

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

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

		local powerTypeDropdown = AceGUI:Create("Dropdown")
		powerTypeDropdown:SetLabel("Power type")
		powerTypeDropdown:SetList(powerTypes)
		powerTypeDropdown:SetValue(S:KeyOf(powerTypes, tracker.powerType or powerTypes[-1]))
		powerTypeDropdown:SetFullWidth(true)
		powerTypeDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = key
			if value == -1 then
				value = nil
			end
			tracker.powerType = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(powerTypeDropdown)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		unit = self.unit,
		powerType = self.powerType,
	}
end

function Instance:GetValue()
	if UnitExists(self.unit) then
		local current = UnitPower(self.unit, self.powerType)
		local maximum = UnitPowerMax(self.unit, self.powerType)
		return current, maximum
	else
		return nil, nil
	end
end