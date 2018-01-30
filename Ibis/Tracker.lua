local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
}
Addon.Tracker = Class
local Instance = Class.prototype

local flyoutTextures = {
	[1] = "Interface/Icons/Spell_Arcane_TeleportDalaran",
	[8] = "Interface/Icons/Spell_Arcane_TeleportDalaran",
	[9] = "Interface/Icons/Ability_Hunter_BeastCall",
	[10] = 136082,
	[11] = "Interface/Icons/Spell_Arcane_PortalStormWind",
	[12] = "Interface/Icons/Spell_Arcane_PortalOrgrimmar",
}

function Class:New(actionName, actionType)
	local obj = S:Clone(Class.prototype)
	obj.customName = nil
	obj.actionName = actionName
	obj.actionType = actionType or nil
	obj.faction = nil
	obj.race = nil
	obj.class = nil
	obj.spec = nil
	obj.talent = nil
	obj.equipped = nil
	obj.combat = nil
	obj.indicatorConfigs = {}
	return obj
end

function Instance:GetFullActionName()
	return (self.actionType or "any")..": "..self.actionName
end

function Instance:GetName()
	if self.customName then
		return self.customName
	end

	local number = tonumber(self.actionName)
	if number then
		return "Action Button #"..number
	end

	return self.actionName
end

function Instance:GetConfigGroupInfo()
	if self.class and #self.class == 1 then
		local sortOrder = S:KeyOf(CLASS_SORT_ORDER, self.class[1])
		local className = LOCALIZED_CLASS_NAMES_MALE[self.class[1]]
		sortOrder = sortOrder * 10

		if self.spec then
			sortOrder = sortOrder + self.spec
			if select(2, UnitClass("player")) == self.class[1] then
				return select(2, GetSpecializationInfo(self.spec)).." "..className, sortOrder
			else
				return className.." (Spec #"..self.spec..")", sortOrder
			end
		else
			return className, sortOrder
		end
	end

	return "Generic", 0
end

function Class:GetIconForFlyoutName(flyoutName)
	for id, flyoutTexture in pairs(flyoutTextures) do
		if flyoutName == GetFlyoutInfo(id) then
			return flyoutTexture
		end
	end
	return nil
end

function Class:GetIconForFlyoutId(flyoutId)
	return flyoutTextures[flyoutId]
end

function Class:GetIcon(actionType, actionName, withPlaceholderTexture)
	local number = tonumber(actionName)
	if number then
		local action = Addon.Action:NewForActionSlot(nil, number)
		return self:GetIcon(action.type, action.name)
	else
		local texture = nil

		if actionType == nil then
			if not texture then
				texture = GetSpellTexture(actionName)
			end
			if not texture then
				texture = select(5, GetItemInfoInstant(actionName))
			end
			if not texture then
				texture = select(2, GetMacroInfo(actionName))
			end
			if not texture then
				texture = self:GetIconForFlyoutName(actionName)
			end
		elseif actionType == "spell" or actionType == "companion" then
			texture = GetSpellTexture(actionName)
		elseif actionType == "item" then
			texture = select(5, GetItemInfoInstant(actionName))
		elseif actionType == "macro" then
			texture = select(2, GetMacroInfo(actionName))
		elseif actionType == "flyout" then
			texture = self:GetIconForFlyoutName(actionName)
		end

		if texture then
			return texture
		else
			return withPlaceholderTexture and "Interface/Icons/INV_Misc_QuestionMark" or nil
		end
	end
end

function Instance:GetIcon(withPlaceholderTexture)
	return Class:GetIcon(self.actionType, self.actionName, withPlaceholderTexture)
end

function Instance:HasModifier(factory)
	if self.tracker then
		if self.factory == factory then
			return true
		else
			return self.tracker:HasModifier(factory)
		end
	else
		return false
	end
end

function Instance:ToggleModifier(factory)
	self[factory.type] = not self:HasModifier(factory)
	local clone = Addon.TrackerFactory:Instantiate(Addon.TrackerFactory:Serialize(self))
	S:Clear(self)
	S:CloneInto(clone, self)
end

function Instance:ShouldLoadAtAll()
	if self.faction and self.faction ~= UnitFactionGroup("player") then
		return false
	end

	if self.race then
		local found = false
		local myRace = select(2, UnitRace("player"))
		for _, race in pairs(self.race) do
			if not found then
				if myRace == race then
					found = true
				end
			end
		end
		if not found then
			return false
		end
	end

	if self.class then
		local found = false
		local myClass = select(2, UnitClass("player"))
		for _, class in pairs(self.class) do
			if not found then
				if myClass == class then
					found = true
				end
			end
		end
		if not found then
			return false
		end
	end

	return true
end

function Instance:ShouldLoad()
	if not self:ShouldLoadAtAll() then
		return false
	end

	if self.spec and GetSpecialization() ~= self.spec then
		return false
	end

	if self.talent then
		for _, talent in pairs(self.talent) do
			local wanted = (#talent == 2) or talent[3]
			if select(4, GetTalentInfo(talent[1], talent[2], 1)) ~= wanted then
				return false
			end
		end
	end

	if self.equipped then
		for _, equipped in pairs(self.equipped) do
			if equipped ~= "" and not IsEquippedItem(equipped) then
				return false
			end
		end
	end

	return true
end

function Instance:ShouldLoadRightNow()
	if self.combat ~= nil then
		if self.combat ~= InCombatLockdown() then
			return false
		end
	end

	return true
end

function Instance:Matches(action)
	if self.actionType and self.actionType ~= action.type then
		return false
	end

	if self.actionName then
		local number = tonumber(self.actionName)
		if number then
			if number ~= action.slot then
				return false
			end
		else
			if self.actionName ~= action.name then
				return false
			end
		end
	end

	return true
end

function Instance:Serialize()
end

function Instance:GetValue()
	return nil
end

function Instance:ProvidedExtraDataColors()
	return nil
end