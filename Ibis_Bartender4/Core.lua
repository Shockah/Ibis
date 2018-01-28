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
				if button and button.action then
					local actionIndex = button.action
					if not actionIndex or actionIndex == 0 then
						actionIndex = button._state_action
					end
					if not actionIndex or actionIndex == 0 then
						actionIndex = ActionButton_GetPagedID(button)
					end
					if not actionIndex or actionIndex == 0 then
						actionIndex = ActionButton_CalculateAction(button)
					end
					if not actionIndex or actionIndex == 0 then
						actionIndex = button:GetAttribute('action')
					end

					local action = BaseAddon.Action:NewForActionSlot(button, actionIndex)
					if action then
						action.slot = actionIndex
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
		print("kek")
		BaseAddon:SetupActionButtons(actionButtonHandler())
	end)]]
	hooksecurefunc(Bartender4.ButtonBar.prototype, "ApplyConfig", function()
		BaseAddon:SetupActionButtons(actionButtonHandler())
	end)
end