local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.ReputationTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, faction)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.faction = faction
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("reputation", "Reputation")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {
				reputation = nil,
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track

		local tracker = Class:New(
			config.actionName,
			config.actionType,
			track.faction
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

		local values = {
			-1,
		}
		local localized = {
			"<watched>",
		}

		for i = 1, GetNumFactions() do
			local name, _, _, _, barMax, _, _, _, isHeader, _, hasRep, _, _, factionID = GetFactionInfo(i)
			if not isHeader or (hasRep and barMax and barMax > 0) then
				table.insert(values, factionID)
				table.insert(localized, name)
			end
		end

		local heading = AceGUI:Create("Heading")
		heading:SetText(self.name)
		heading:SetFullWidth(true)
		container:AddChild(heading)

		local valueDropdown = AceGUI:Create("Dropdown")
		valueDropdown:SetLabel("Faction")
		valueDropdown:SetList(localized)
		valueDropdown:SetValue(S:KeyOf(values, tracker.faction or -1))
		valueDropdown:SetFullWidth(true)
		valueDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = values[key]
			if value == -1 then
				value = nil
			end
			tracker.faction = values[key]
			configAddon:Refresh(tracker)
		end)
		container:AddChild(valueDropdown)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		faction = self.faction,
	}
end

function Instance:GetValue()
	local faction = self.faction
	if not faction then
		for i = 1, GetNumFactions() do
			local _, _, _, _, _, _, _, _, _, _, _, isWatched, _, factionID = GetFactionInfo(i)
			if isWatched then
				faction = factionID
			end
		end
	end

	if faction then
		local _, _, standingID, barMin, barMax, barValue = GetFactionInfoByID(faction)

		local color = FACTION_BAR_COLORS[standingID]
		local extraData = {
			colors = {
				["Standing"] = { color.r, color.g, color.b, 1.0 },
			},
		}

		return barValue - barMin, barMax - barMin, extraData
	else
		return nil, nil, nil
	end
end

function Instance:ProvidedExtraDataColors()
	return { "Standing" }
end