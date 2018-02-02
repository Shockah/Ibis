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

function Class:New(actionName, actionType, trackerAction)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.trackerAction = trackerAction
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("cooldown", "Cooldown")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {
				trackerAction = "<action>",
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
			track.trackerAction
		)

		return tracker
	end

	function factory:CreateConfigMenu(configAddon, tracker, container)
		local AceGUI = LibStub("AceGUI-3.0")

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
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		trackerAction = self.trackerAction,
	}
end

function Instance:GetValue()
	if self.actionType == "spell" then
		return self:GetSpellCooldown()
	elseif self.actionType == "item" then
		return self:GetItemCooldown()
	elseif not self.actionType then
		local a, b
		if not a then
			a, b = self:GetSpellCooldown()
		end
		return a, b
	end
end

function Instance:GetSpellCooldown()
	local spell = self.trackerAction or self.actionName
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