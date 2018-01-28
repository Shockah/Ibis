local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

function Addon:OnInitialize()
	BaseAddon:RegisterActionButtonHandler(function()
		local results = {}
		for i = 1, 120 do
			local button = _G["ActionButton"..i]
			if button and button.action then
				local action = BaseAddon.Action:NewForActionSlot(button, button.action)
				if action then
					action.slot = button.action
					table.insert(results, action)
				end
			end
		end
		return results
	end)
end