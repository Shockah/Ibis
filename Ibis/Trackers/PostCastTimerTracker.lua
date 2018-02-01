local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.PostCastTimerTracker = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(actionName, actionType, spell, time)
	local obj = Addon.Tracker:New(actionName, actionType)
	S:CloneInto(Class.prototype, obj)
	obj.spell = spell
	obj.time = time
	return obj
end

function Private:Register()
	local factory = Addon.TrackerFactory:New("postcasttimer", "Post-Cast Timer")
	table.insert(factory.registeredEvents, "UNIT_SPELLCAST_SUCCEEDED")

	function factory:CreateBlank()
		local tracker = self:Create({
			actionName = "<action>",
			track = {
				time = 15,
			},
		})
		tracker.factory = factory
		return tracker
	end

	function factory:Create(config)
		track = config.track
		if not track.time then
			return nil
		end

		local tracker = Class:New(
			config.actionName,
			config.actionType,
			track.spell,
			track.time
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
		spellEditbox:SetLabel("Spell (optional)")
		spellEditbox:SetText(tracker.spell)
		spellEditbox:SetFullWidth(true)
		spellEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			tracker.spell = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		container:AddChild(spellEditbox)

		local timeSlider = AceGUI:Create("Slider")
		timeSlider:SetLabel("Time (seconds)")
		timeSlider:SetSliderValues(0.0, 60.0, 1.0)
		timeSlider:SetValue(tracker.time)
		timeSlider:SetFullWidth(true)
		timeSlider:SetCallback("OnMouseUp", function(self, event, value)
			tracker.time = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(timeSlider)
	end

	Addon:RegisterTrackerFactory(factory)
end

function Instance:Serialize()
	return {
		spell = self.spell,
		time = self.time,
	}
end

function Instance:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, rank, lineID, spellID)
	if unitID ~= "player" then
		return
	end

	if spell == (self.spell or self.actionName) then
		self.expires = GetTime() + self.time
	end
end

function Instance:GetValue()
	if self.expires then
		local f = (self.expires - GetTime()) / self.time
		if f < 0.0 then
			return nil, nil
		end
		return min(max(f, 0.0), 1.0), 1.0
	else
		return nil, nil
	end
end