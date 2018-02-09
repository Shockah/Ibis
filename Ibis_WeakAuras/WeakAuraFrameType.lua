local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local Class = {
	prototype = {},
}
Addon.WeakAurasFrameType = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

function Class:New(type, name)
	local obj = BaseAddon.FrameType:New(type, name)
	S:CloneInto(Class.prototype, obj)
	return obj
end

function Private:Register()
	BaseAddon.FrameType:Register(Class:New("weakaura", "WeakAura"))
end

local function setupWeakAuraIfNeeded(weakAuraName)
	if weakAuraName then
		local weakAura = WeakAuras.regions[weakAuraName]
		if weakAura then
			Addon:SetupWeakAura(weakAura)
		end
	end
end

function Instance:CreateConfigMenu(configAddon, tracker, container)
	local AceGUI = LibStub("AceGUI-3.0")

	local weakAuraNameEditbox = AceGUI:Create("EditBox")
	weakAuraNameEditbox:SetLabel("WeakAura name")
	weakAuraNameEditbox:SetText(tracker.weakAuraName)
	weakAuraNameEditbox:SetFullWidth(true)
	weakAuraNameEditbox:SetCallback("OnEnterPressed", function(self, event, text)
		local oldName = tracker.weakAuraName
		tracker.weakAuraName = S:StringOrNil(text)
		setupWeakAuraIfNeeded(oldName)
		setupWeakAuraIfNeeded(tracker.weakAuraName)
		self:ClearFocus()
		configAddon:Refresh(tracker)
	end)
	container:AddChild(weakAuraNameEditbox)
end

function Instance:GetIcon(tracker, withPlaceholderTexture)
	if not tracker.weakAuraName then
		return withPlaceholderTexture and "Interface/Icons/INV_Misc_QuestionMark" or nil
	end

	local weakAura = Addon.weakAuras[tracker.weakAuraName]
	if not weakAura then
		return withPlaceholderTexture and "Interface/Icons/INV_Misc_QuestionMark" or nil
	end

	if weakAura.region.icon and weakAura.region.icon.GetTexture then
		local texture = weakAura.region.icon:GetTexture()
		if texture then
			return texture
		end
	end

	return withPlaceholderTexture and "Interface/Icons/INV_Misc_QuestionMark" or nil
end

function Instance:GetName(tracker)
	return tracker.weakAuraName or "<empty>"
end

function Instance:Serialize(tracker, output)
	output.weakAuraName = tracker.weakAuraName
end

function Instance:Deserialize(input, tracker)
	tracker.weakAuraName = input.weakAuraName
end