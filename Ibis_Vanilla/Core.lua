local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local function HandleButton(results, button)
	if button and button.action then
		local action = BaseAddon.Action:NewForActionSlot(button, button.action)
		if action then
			action.slot = button.action
			table.insert(results, action)
		end
	end
end

function Addon:OnInitialize()
	BaseAddon:RegisterActionButtonHandler(function()
		local results = {}

		for i = 1, 12 do
			HandleButton(results, _G["ActionButton"..i])
		end
		for i = 1, 12 do
			HandleButton(results, _G["MultiBarBottomLeftButton"..i])
		end
		for i = 1, 12 do
			HandleButton(results, _G["MultiBarBottomRightButton"..i])
		end
		for i = 1, 12 do
			HandleButton(results, _G["MultiBarLeftButton"..i])
		end
		for i = 1, 12 do
			HandleButton(results, _G["MultiBarRightButton"..i])
		end

		return results
	end)
end