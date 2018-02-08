local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.HealthTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionType, unit)
	local obj = Addon.Tracker:New(actionType)
	S:CloneInto(Class.prototype, obj)
	obj.unit = unit
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("health", "Health")

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
		if not track.unit then
			return nil
		end

		local tracker = Class:New(
			config.actionType,
			track.unit
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
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		unit = self.unit,
	}
end

function Instance:GetValue()
	if UnitExists(self.unit) then
		local current = UnitHealth(self.unit)
		local maximum = UnitHealthMax(self.unit)

		local f = current / maximum
		local color

		if f > 0.5 then
			f = (f - 0.5) * 2.0
			color = S:Lerp(f, { 1.0, 1.0, 0.0 }, { 0.0, 1.0, 0.0 })
		else
			f = f * 2.0
			color = S:Lerp(f, { 1.0, 0.0, 0.0 }, { 1.0, 1.0, 0.0 })
		end
		table.insert(color, 1.0)

		local extraData = {
			colors = {
				["Health"] = color,
			},
		}

		return current, maximum, extraData
	else
		return nil, nil, nil
	end
end

function Instance:ProvidedExtraDataColors()
	return { "Health" }
end