local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.Action = Class
local Instance = Class.prototype

function Class:New(button, type, id, name, slot)
	local obj = S:Clone(Class.prototype)
	obj.button = button
	obj.type = type
	obj.id = id
	obj.name = name
	obj.slot = slot
	obj.priority = 0
	return obj
end

function Class:NewForActionSlot(button, slot)
	if HasAction(slot) then
		local actionName
		local actionType, id = GetActionInfo(slot)

		if actionType == "macro" then
			local macroName = GetMacroInfo(id)
			local spellName, _, spellId = GetMacroSpell(id)
			if spellName then
				actionName, actionType, id = spellName, "spell", spellId
			else
				local itemName, itemLink = GetMacroItem(id)
				if itemName then
					actionName, actionType, id = itemName, "item", -1
				else
					actionName, actionType, id = macroName, "macro", -1
				end
			end
		end

		if actionType == "item" and id ~= -1 then
			actionName = GetItemInfo(id)
		elseif actionType == "flyout" and id then
			actionName = GetFlyoutInfo(id)
		elseif (actionType == "spell" and id ~= -1) or (actionType == "macro" and id and id ~= -1) then
			actionName = GetSpellInfo(id)
			actionType = "spell"
		end

		local spellLink = ((actionType == "spell" or actionType == "item") and id and id ~= -1) and GetSpellLink(id) or nil
		return Class:New(button, actionType, id, actionName, slot)
	end

	return Class:New(button, nil, nil, nil, slot)
end