local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local function actionButtonHandler()
	local results = {}
	for i = 1, 10 do
		local bar = _G["BT4Bar"..i]
		if bar and bar.buttons and bar.numbuttons then
			for j = 1, bar.numbuttons do
				local button = bar.buttons[j]
				if button then
					local action = BaseAddon.Action:NewForActionSlot(button, BaseAddon:GetButtonAction(button))
					if action then
						action.priority = 1
						table.insert(results, action)
					end
				end
			end
		end
	end
	return results
end

function Addon:OnInitialize()
	BaseAddon:RegisterActionButtonHandler(actionButtonHandler)

	--[[hooksecurefunc(Bartender4.ButtonBar.prototype, "UpdateButtonLayout", function()
		BaseAddon:SetupActionButtons(actionButtonHandler())
	end)]]
	hooksecurefunc(Bartender4.ButtonBar.prototype, "ApplyConfig", function()
		BaseAddon:SetupActionButtons(actionButtonHandler())
	end)
end