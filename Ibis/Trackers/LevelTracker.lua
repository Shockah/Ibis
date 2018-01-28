local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.LevelTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, value)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.value = value
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("level", "Level")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {
				value = "level",
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track
		if not track.value then
			return nil
		end

		local tracker = Class:New(
			config.actionName,
			config.actionType,
			track.value
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

		local values = {
			"level",
			"experience",
			"artifact",
		}
		local localized = {
			"Level",
			"Experience",
			"Artifact Power",
		}

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

		local valueDropdown = AceGUI:Create("Dropdown")
		valueDropdown:SetLabel("Value")
		valueDropdown:SetList(localized)
		valueDropdown:SetValue(S:KeyOf(values, tracker.value))
		valueDropdown:SetFullWidth(true)
		valueDropdown:SetCallback("OnValueChanged", function(self, event, key)
			tracker.value = values[key]
			configAddon:Refresh(tracker)
		end)
		container:AddChild(valueDropdown)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		value = self.value,
	}
end

function Instance:GetValue()
	if self.value == "level" then
		return UnitLevel("player"), GetMaxPlayerLevel()
	elseif self.value == "experience" then
		return UnitXP("player"), UnitXPMax("player")
	elseif self.value == "artifact" then
		if HasArtifactEquipped() then
			local _, _, name, _, totalPower, traitsLearned, _, _, _, _, _, _, artifactTier = C_ArtifactUI.GetEquippedArtifactInfo()
			local numTraitsLearnable, power, powerForNextTrait = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(traitsLearned, totalPower, artifactTier)
			return power, powerForNextTrait
		else
			return nil, nil
		end
	else
		return nil, nil
	end
end