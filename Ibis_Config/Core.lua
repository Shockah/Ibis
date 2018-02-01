local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]
local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local LibDualSpec = LibStub("LibDualSpec-1.0", true)

local libS = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local libCE = libC:GetAddonEncodeTable()

_G["SLASH_"..addonName..1] = "/"..BaseAddon:GetName():lower()
SlashCmdList[addonName] = function(msg)
	Addon:CreateConfigurationFrame()
end

local optionSelected = nil

function Addon:OnInitialize()
	table.insert(UISpecialFrames, BaseAddon:GetName().."ConfigFrame")
	self.Niji = addonTable.Niji

	local profilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(BaseAddon.db)

	if LibDualSpec then
		LibDualSpec:EnhanceOptions(profilesOptions, BaseAddon.db)
	end
	
	AceConfig:RegisterOptionsTable(addonName, profilesOptions)
end

function Addon:Export(tracker)
	local serialized = BaseAddon.TrackerFactory:Serialize(tracker)

	local one = libS:Serialize(serialized)
	local two = libC:CompressHuffman(one)
	local final = libCE:Encode(two)
	local base64 = self.Base64:Encode(final)

	return base64
end

function Addon:Import(text)
	if not text or text == "" then
		return nil, nil
	end

	local unbase64 = self.Base64:Decode(text)
	if not unbase64 then
		return nil, "Invalid import string."
	end

	local one = libCE:Decode(unbase64)

	local two, message = libC:Decompress(one)
	if not two then
		return nil, "Invalid import string. "..message
	end

	local success, final = libS:Deserialize(two)
	if not success then
		return nil, "Invalid import string."
	end

	local deserialized = BaseAddon.TrackerFactory:Instantiate(final)
	if not deserialized then
		return nil, "Tracker configuration corrupted or you're missing some required addons."
	end

	return deserialized
end

function Addon:ShowImportDialog(onClick)
	local dialogName = addonName.."_Import"

	StaticPopupDialogs[dialogName] = StaticPopupDialogs[dialogName] or {
		text = "Paste an import string:",
		button1 = "OK",
		hasEditBox = true,
		editBoxWidth = 350,
		OnShow = function(self, data)
			self.editBox:SetText("")
			self.editBox:SetFocus()
		end,
		OnAccept = function(self, data)
			local onClick = StaticPopupDialogs[dialogName].externalOnClick
			if onClick then
				local text = self.editBox:GetText()
				onClick(text)
			end
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}

	StaticPopupDialogs[dialogName].externalOnClick = onClick
	StaticPopup_Show(dialogName)
end

function Addon:ShowExportDialog(text)
	local dialogName = addonName.."_Export"

	StaticPopupDialogs[dialogName] = StaticPopupDialogs[dialogName] or {
		text = "Copy an import string:",
		button1 = "OK",
		hasEditBox = true,
		editBoxWidth = 350,
		OnShow = function(self, data)
			self.editBox:SetText(StaticPopupDialogs[dialogName].externalText or "")
			self.editBox:SetFocus()
			self.editBox:HighlightText(0)
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		enterClicksFirstButton = true,
	}

	StaticPopupDialogs[dialogName].externalText = text
	StaticPopup_Show(dialogName)
end

function Addon:CreateConfigurationFrame()
	if not self.ConfigFrame then
		optionSelected = nil
	else
		self.ConfigFrame.frame.obj:Hide()
	end

	local frame = AceGUI:Create("Frame")
	frame:SetCallback("OnClose", function(self)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		local anchor, _, _, x, y = self.frame:GetPoint(1)
		BaseAddon.db.global.configFrame = {
			point = {
				anchor = anchor,
				x = x,
				y = y,
			},
			size = {
				width = self.frame:GetWidth(),
				height = self.frame:GetHeight(),
			},
		}
		AceGUI:Release(self)
		Addon.ConfigFrame = nil
		_G[BaseAddon:GetName().."ConfigFrame"] = nil
	end)
	frame:SetTitle(BaseAddon:GetName())
	frame:SetLayout(nil)
	--frame:SetLayout("Fill")
	frame:SetWidth(680)
	frame:SetHeight(560)
	frame.frame:SetFrameStrata("DIALOG")
	if BaseAddon.db.global.configFrame then
		local frameConfig = BaseAddon.db.global.configFrame
		if frameConfig.point then
			local point = frameConfig.point
			frame:ClearAllPoints()
			frame:SetPoint(point.anchor, nil, point.anchor, point.x, point.y)
		end
		if frameConfig.size then
			local size = frameConfig.size
			frame:SetWidth(size.width)
			frame:SetHeight(size.height)
		end
	end
	Addon.ConfigFrame = frame
	_G[BaseAddon:GetName().."ConfigFrame"] = frame

	local listScrollContainer = AceGUI:Create("SimpleGroup")
	listScrollContainer:SetLayout("Fill")
	frame:AddChild(listScrollContainer)
	listScrollContainer:ClearAllPoints()
	listScrollContainer:SetPoint("TOPLEFT", frame.content, "TOPLEFT")
	listScrollContainer:SetPoint("BOTTOMLEFT", frame.content, "BOTTOMLEFT")
	listScrollContainer:SetWidth(200)

	local listScroll = AceGUI:Create("ScrollFrame")
	listScroll:SetLayout("List")
	listScroll:SetFullWidth(true)
	listScrollContainer:AddChild(listScroll)
	frame.listScroll = listScroll

	local editorContainer = AceGUI:Create("SimpleGroup")
	editorContainer:SetLayout("Flow")
	frame:AddChild(editorContainer)
	editorContainer:ClearAllPoints()
	editorContainer:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT")
	editorContainer:SetPoint("BOTTOMLEFT", listScrollContainer.frame, "BOTTOMRIGHT", 8, 0)
	frame.editorContainer = editorContainer

	self:SetupFrame()
end

function Addon:FrameRefresh()
	local tracker = type(optionSelected) == "table" and optionSelected or nil
	self:SetupList()
	self:UpdateTrackerFrame(self.ConfigFrame.editorTitleGroup, tracker)
	self:UpdateConfigurationFrame(self.ConfigFrame.editorScroll, tracker)
end

function Addon:Refresh(tracker)
	BaseAddon:ReloadSessionTrackers()
	self:SetupList()
	self:UpdateTrackerFrame(self.ConfigFrame.editorTitleGroup, tracker)
	self:UpdateConfigurationFrame(self.ConfigFrame.editorScroll, tracker)
end

function Addon:SetupFrame()
	local frame = Addon.ConfigFrame
	if not frame then
		return
	end

	self:SetupList()
	frame.editorContainer:ReleaseChildren()

	local editorTitleGroup = AceGUI:Create("InlineGroup")
	editorTitleGroup:SetLayout("List")
	editorTitleGroup:SetFullWidth(true)
	editorTitleGroup:SetAutoAdjustHeight(false)
	editorTitleGroup:SetTitle("Selected")
	frame.editorContainer:AddChild(editorTitleGroup)

	local editorScrollContainer = AceGUI:Create("InlineGroup")
	editorScrollContainer:SetLayout("Fill")
	editorScrollContainer:SetTitle("Configuration")
	editorScrollContainer:SetFullWidth(true)
	editorScrollContainer:SetFullHeight(true)
	frame.editorContainer:AddChild(editorScrollContainer)

	local editorScroll = AceGUI:Create("ScrollFrame")
	editorScroll:SetLayout("List")
	editorScroll:SetFullWidth(true)
	editorScrollContainer:AddChild(editorScroll)
	frame.editorScroll = editorScroll

	if optionSelected == "add" then
		frame.editorTitleGroup = self:CreateNewOptionFrame(editorTitleGroup)
		self:UpdateConfigurationFrameToAddOption(editorScroll)
	elseif optionSelected == "settings" then
		frame.editorTitleGroup = self:CreateSettingsOptionFrame(editorTitleGroup)
		self:UpdateConfigurationFrameToSettingsOption(editorScroll)
	elseif optionSelected == "profiles" then
		frame.editorTitleGroup = self:CreateProfilesOptionFrame(editorTitleGroup)
		self:UpdateConfigurationFrameToProfilesOption(editorScroll)
	else
		local tracker = optionSelected
		frame.editorTitleGroup = self:CreateTrackerFrame(editorTitleGroup, tracker)
		self:UpdateConfigurationFrame(editorScroll, tracker)
	end
end

function Addon:SetupList()
	local frame = Addon.ConfigFrame
	if not frame then
		return
	end

	frame.listScroll:ReleaseChildren()
	self:CreateTrackerFrames(frame.listScroll)
end

function Addon:CreateTopOptionFrames(container)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("List")
	group:SetFullWidth(true)
	group:SetAutoAdjustHeight(false)
	group:SetTitle("Options")
	container:AddChild(group)

	self:CreateNewOptionFrame(group)
	self:CreateSettingsOptionFrame(group)
	self:CreateProfilesOptionFrame(group)
end

function Addon:CreateTrackerFrames(container)
	self:CreateTopOptionFrames(container)

	local trackerGroups = { {}, {}, {} }

	for _, tracker in pairs(BaseAddon.allTrackers) do
		local groupTable
		if tracker:ShouldLoadAtAll() then
			groupTable = tracker:ShouldLoad() and trackerGroups[1] or trackerGroups[2]
		else
			groupTable = trackerGroups[3]
		end

		table.insert(groupTable, tracker)
	end

	for trackerGroupIndex, trackerGroup in pairs(trackerGroups) do
		if not S:IsEmpty(trackerGroup) then
			table.sort(trackerGroup, function(a, b)
				local av = select(2, a:GetConfigGroupInfo())
				local bv = select(2, b:GetConfigGroupInfo())

				if av ~= bv then
					return av < bv
				end

				return a:GetName() < b:GetName()
			end)

			local activityTitle = "Active"
			if trackerGroupIndex >= 2 then
				activityTitle = trackerGroupIndex == 2 and "Inactive" or "Unloaded"
			end

			local activityGroup = AceGUI:Create("InlineGroup")
			activityGroup:SetLayout("List")
			activityGroup:SetFullWidth(true)
			activityGroup:SetTitle(activityTitle)
			container:AddChild(activityGroup)

			local currentGroupName = nil
			local currentGroup

			for _, tracker in pairs(trackerGroup) do
				local newGroupName = tracker:GetConfigGroupInfo()
				if newGroupName ~= currentGroupName then
					local group = AceGUI:Create("InlineGroup")
					group:SetLayout("List")
					group:SetFullWidth(true)
					--group:SetAutoAdjustHeight(false)
					group:SetTitle(newGroupName)
					activityGroup:AddChild(group)

					currentGroupName = newGroupName
					currentGroup = group
				end
				
				self:CreateTrackerFrame(currentGroup, tracker)
			end
		end
	end

	container:DoLayout()
end

function Addon:CreateEntryFrame(container)
	local group = AceGUI:Create("SimpleGroup")
	group:SetLayout(nil)
	group:SetFullWidth(true)
	group:SetAutoAdjustHeight(false)
	group:SetHeight(28)
	container:AddChild(group)

	local icon = AceGUI:Create("Icon")
	icon:SetImageSize(24, 24)
	icon:SetWidth(24)
	icon:SetHeight(24)
	group:AddChild(icon)
	icon:ClearAllPoints()
	icon:SetPoint("LEFT", group.frame, "LEFT", 4, 4)
	group.icon = icon

	local label = AceGUI:Create("Label")
	group:AddChild(label)
	label:ClearAllPoints()
	label:SetPoint("LEFT", icon.frame, "RIGHT", 8, -4)
	label:SetPoint("RIGHT", group.frame, "RIGHT")
	group.label = label

	container:SetHeight(40 + #container.children * 28)
	return group
end

function Addon:CreateNewOptionFrame(container)
	local group = self:CreateEntryFrame(container)
	self:UpdateTrackerFrameToNewOption(group)
end

function Addon:CreateSettingsOptionFrame(container)
	local group = self:CreateEntryFrame(container)
	self:UpdateTrackerFrameToSettingsOption(group)
end

function Addon:CreateProfilesOptionFrame(container)
	local group = self:CreateEntryFrame(container)
	self:UpdateTrackerFrameToProfilesOption(group)
end

function Addon:CreateTrackerFrame(container, tracker)
	local group = self:CreateEntryFrame(container)
	self:UpdateTrackerFrame(group, tracker)
	return group
end

function Addon:UpdateTrackerFrameToNewOption(container)
	container.icon:SetImage("Interface/Icons/Spell_ChargePositive")
	container.label:SetText("Add...")

	container.icon:SetCallback("OnClick", function(self, event)
		optionSelected = "add"
		Addon:SetupFrame()
	end)
end

function Addon:UpdateTrackerFrameToSettingsOption(container)
	container.icon:SetImage("Interface/Icons/INV_Misc_Gear_05")
	container.label:SetText("Settings")

	container.icon:SetCallback("OnClick", function(self, event)
		optionSelected = "settings"
		Addon:SetupFrame()
	end)
end

function Addon:UpdateTrackerFrameToProfilesOption(container)
	container.icon:SetImage("Interface/Icons/Achievement_Character_Human_Male")
	container.label:SetText("Profiles")

	container.icon:SetCallback("OnClick", function(self, event)
		optionSelected = "profiles"
		Addon:SetupFrame()
	end)
end

function Addon:UpdateTrackerFrame(container, tracker)
	if not tracker then
		return
	end

	container.icon:SetImage(tracker:GetIcon(true))

	container.icon:SetCallback("OnClick", function(self, event)
		optionSelected = tracker
		Addon:SetupFrame()
	end)

	container.label:SetText(tracker:GetName())
end

function Addon:UpdateConfigurationFrameToAddOption(container)
	container:ReleaseChildren()

	BaseAddon.TrackerFactory:CreateConfigMenu(self, container, function(tracker)
		table.insert(BaseAddon.allTrackers, tracker)
		optionSelected = tracker
		Addon:SetupFrame()
	end)

	local separator = AceGUI:Create("SimpleGroup")
	separator:SetLayout("List")
	separator:SetFullWidth(true)
	separator:SetAutoAdjustHeight(false)
	separator:SetHeight(16)
	container:AddChild(separator)

	local importButton = AceGUI:Create("Button")
	importButton:SetText("Import")
	importButton:SetFullWidth(true)
	importButton:SetCallback("OnClick", function(self, event)
		Addon:ShowImportDialog(function(text)
			local newTracker, message = Addon:Import(text)
			if message then
				UIErrorsFrame:AddMessage(message, 1.0, 0.0, 0.0)
			end

			if newTracker then
				table.insert(BaseAddon.allTrackers, newTracker)
				optionSelected = newTracker
				Addon:SetupFrame()
			end
		end)
	end)
	container:AddChild(importButton)
end

function Addon:UpdateConfigurationFrameToSettingsOption(container)
	container:ReleaseChildren()

	local generalHeading = AceGUI:Create("Heading")
	generalHeading:SetText("General")
	generalHeading:SetFullWidth(true)
	container:AddChild(generalHeading)

	local hideGlowCheckbox = AceGUI:Create("CheckBox")
	hideGlowCheckbox:SetLabel("Hide action button glow")
	hideGlowCheckbox:SetDescription("Currently only working with action buttons using LibButtonGlow (for example Bartender).")
	hideGlowCheckbox:SetValue(BaseAddon.db.profile.hideGlow)
	hideGlowCheckbox:SetFullWidth(true)
	hideGlowCheckbox:SetCallback("OnValueChanged", function(self, event, value)
		if not value then
			value = nil
		end
		BaseAddon.db.profile.hideGlow = value
		BaseAddon:UpdateSettings()
	end)
	container:AddChild(hideGlowCheckbox)
end

function Addon:UpdateConfigurationFrameToProfilesOption(container)
	container:ReleaseChildren()

	local group = AceGUI:Create("SimpleGroup")
	group:SetLayout("Fill")
	group:SetFullWidth(true)
	container:AddChild(group)

	AceConfigDialog:Open(addonName, group)
	container:DoLayout()
end

function Addon:UpdateConfigurationFrame(container, tracker)
	container:ReleaseChildren()
	if not tracker then
		return
	end

	local actionTypes = {
		"<any>",
		"spell",
		"item",
		"flyout",
		"companion",
		"macro",
	}

	local specs = {
		"<any>",
	}

	if tracker.class and #tracker.class == 1 and tracker.class[1] == select(2, UnitClass("player")) then
		for i = 1, 4 do
			local name = select(2, GetSpecializationInfo(i))
			if name then
				table.insert(specs, name)
			end
		end
	else
		for i = 1, 4 do
			table.insert(specs, "Spec #"..i)
		end
	end

	local factions = {
		"<any>",
		"Alliance",
		"Horde",
		"Neutral",
	}

	local actionsGroup = AceGUI:Create("SimpleGroup")
	actionsGroup:SetLayout("Flow")
	actionsGroup:SetFullWidth(true)
	container:AddChild(actionsGroup)

	local exportButton = AceGUI:Create("Button")
	exportButton:SetText("Export")
	exportButton:SetRelativeWidth(0.333)
	exportButton:SetCallback("OnClick", function(self, event)
		local importString = Addon:Export(tracker)
		Addon:ShowExportDialog(importString)
	end)
	actionsGroup:AddChild(exportButton)

	local duplicateButton = AceGUI:Create("Button")
	duplicateButton:SetText("Duplicate")
	duplicateButton:SetRelativeWidth(0.333)
	duplicateButton:SetCallback("OnClick", function(self, event)
		local newTracker = BaseAddon.TrackerFactory:Instantiate(BaseAddon.TrackerFactory:Serialize(tracker))
		table.insert(BaseAddon.allTrackers, newTracker)
		optionSelected = newTracker
		Addon:SetupFrame()
	end)
	actionsGroup:AddChild(duplicateButton)

	local removeButton = AceGUI:Create("Button")
	removeButton:SetText("Remove")
	removeButton:SetRelativeWidth(0.333)
	removeButton:SetCallback("OnClick", function(self, event)
		S:RemoveValue(BaseAddon.allTrackers, tracker)
		optionSelected = nil
		Addon:SetupFrame()
	end)
	actionsGroup:AddChild(removeButton)

	local customNameEditbox = AceGUI:Create("EditBox")
	customNameEditbox:SetLabel("Custom name (optional)")
	customNameEditbox:SetText(tracker.customName or "")
	customNameEditbox:SetFullWidth(true)
	customNameEditbox:SetCallback("OnEnterPressed", function(self, event, text)
		tracker.customName = S:StringOrNil(text)
		self:ClearFocus()
		Addon:Refresh(tracker)
	end)
	container:AddChild(customNameEditbox)

	local actionHeading = AceGUI:Create("Heading")
	actionHeading:SetText("Action")
	actionHeading:SetFullWidth(true)
	container:AddChild(actionHeading)

	local actionTypeDropdown = AceGUI:Create("Dropdown")
	actionTypeDropdown:SetLabel("Action type")
	actionTypeDropdown:SetList(actionTypes)
	actionTypeDropdown:SetValue(S:KeyOf(actionTypes, tracker.actionType or actionTypes[1]))
	actionTypeDropdown:SetFullWidth(true)
	actionTypeDropdown:SetCallback("OnValueChanged", function(self, event, key)
		local value = actionTypes[key]
		if key == 1 then
			value = nil
		end
		tracker.actionType = value
		Addon:Refresh(tracker)
	end)
	container:AddChild(actionTypeDropdown)

	local spellEditbox = AceGUI:Create("EditBox")
	spellEditbox:SetLabel("Action")
	spellEditbox:SetText(tracker.actionName)
	spellEditbox:SetFullWidth(true)
	spellEditbox:SetCallback("OnEnterPressed", function(self, event, text)
		local value = S:StringOrNil(text)
		if value then
			tracker.actionName = value
			self:ClearFocus()
			Addon:Refresh(tracker)
		else
			self:SetText(tracker.actionName)
			self:ClearFocus()
		end
	end)
	container:AddChild(spellEditbox)

	tracker.factory:CreateConfigMenu(self, tracker, container)
	BaseAddon.TrackerFactory:CreateConfigMenuForModifiers(self, tracker, container)
	BaseAddon.IndicatorFactory:CreateConfigMenu(self, tracker, container)

	local conditionsHeading = AceGUI:Create("Heading")
	conditionsHeading:SetText("Conditions")
	conditionsHeading:SetFullWidth(true)
	container:AddChild(conditionsHeading)

	local factionDropdown = AceGUI:Create("Dropdown")
	factionDropdown:SetLabel("Faction")
	factionDropdown:SetList(factions)
	factionDropdown:SetValue(S:KeyOf(factions, tracker.faction or factions[1]))
	factionDropdown:SetFullWidth(true)
	factionDropdown:SetCallback("OnValueChanged", function(self, event, key)
		local value = factions[key]
		if key == 1 then
			value = nil
		end
		tracker.faction = value
		Addon:Refresh(tracker)
	end)
	container:AddChild(factionDropdown)

	self:CreateRaceConfigurationFrame(container, tracker)
	self:CreateClassConfigurationFrame(container, tracker)

	if tracker.class and #tracker.class == 1 then
		local specsDropdown = AceGUI:Create("Dropdown")
		specsDropdown:SetLabel("Specialization")
		specsDropdown:SetList(specs)
		specsDropdown:SetValue((tracker.spec or 0) + 1)
		specsDropdown:SetFullWidth(true)
		specsDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = key - 1
			if value == 0 then
				value = nil
			end
			tracker.spec = value
			tracker.talents = nil
			Addon:Refresh(tracker)
		end)
		container:AddChild(specsDropdown)
	end

	self:CreateTalentConfigurationFrame(container, tracker)
	self:CreateEquippedConfigurationFrame(container, tracker)

	local combatCheckbox = AceGUI:Create("CheckBox")
	combatCheckbox:SetLabel("Combat")
	combatCheckbox:SetTriState(true)
	combatCheckbox:SetValue(tracker.combat)
	combatCheckbox:SetFullWidth(true)
	combatCheckbox:SetCallback("OnValueChanged", function(self, event, value)
		tracker.combat = value
		Addon:Refresh(tracker)
	end)
	container:AddChild(combatCheckbox)
end

function Addon:CreateRaceConfigurationFrame(container, tracker)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("List")
	group:SetTitle("Races")
	group:SetFullWidth(true)
	container:AddChild(group)

	local innerGroup1 = AceGUI:Create("SimpleGroup")
	innerGroup1:SetLayout("Flow")
	innerGroup1:SetFullWidth(true)
	group:AddChild(innerGroup1)

	local separator = AceGUI:Create("SimpleGroup")
	separator:SetLayout("List")
	separator:SetFullWidth(true)
	separator:SetAutoAdjustHeight(false)
	separator:SetHeight(8)
	group:AddChild(separator)

	local innerGroup2 = AceGUI:Create("SimpleGroup")
	innerGroup2:SetLayout("Flow")
	innerGroup2:SetFullWidth(true)
	group:AddChild(innerGroup2)

	local separator2 = AceGUI:Create("SimpleGroup")
	separator2:SetLayout("List")
	separator2:SetFullWidth(true)
	separator2:SetAutoAdjustHeight(false)
	separator2:SetHeight(8)
	group:AddChild(separator2)

	local innerGroup3 = AceGUI:Create("SimpleGroup")
	innerGroup3:SetLayout("Flow")
	innerGroup3:SetFullWidth(true)
	group:AddChild(innerGroup3)

	local races = {
		{
			id = "Pandaren",
			localized = "Pandaren",
		},
		{
			id = "Human",
			localized = "Human",
		},
		{
			id = "Orc",
			localized = "Orc",
		},
		{
			id = "Dwarf",
			localized = "Dwarf",
		},
		{
			id = "Scourge",
			localized = "Undead",
		},
		{
			id = "NightElf",
			localized = "Night Elf",
		},
		{
			id = "Tauren",
			localized = "Tauren",
		},
		{
			id = "Gnome",
			localized = "Gnome",
		},
		{
			id = "Troll",
			localized = "Troll",
		},
		{
			id = "Draenei",
			localized = "Draenei",
		},
		{
			id = "BloodElf",
			localized = "Blood Elf",
		},
		{
			id = "Worgen",
			localized = "Worgen",
		},
		{
			id = "Goblin",
			localized = "Goblin",
		},
	}

	local alliedRaces = {
		{
			id = "LightforgedDraenei",
			localized = "Lightforged Draenei",
		},
		{
			id = "HighmountainTauren",
			localized = "Highmountain Tauren",
		},
		{
			id = "VoidElf",
			localized = "Void Elf",
		},
		{
			id = "Nightborne",
			localized = "Nightborne",
		},
	}

	local function setupRace(race, specificGroup)
		local raceCheckbox = AceGUI:Create("CheckBox")
		raceCheckbox:SetRelativeWidth(0.5)
		specificGroup:AddChild(raceCheckbox)

		if race then
			raceCheckbox:SetLabel(race.localized)
			raceCheckbox:SetValue(tracker.race and S:Contains(tracker.race, race.id))
			raceCheckbox:SetCallback("OnValueChanged", function(self, event, value)
				if value then
					if tracker.race == nil then
						tracker.race = {}
					end
					table.insert(tracker.race, race.id)
				else
					S:RemoveValue(tracker.race, race.id)
					if S:IsEmpty(tracker.race) then
						tracker.race = nil
					end
				end
				Addon:Refresh(tracker)
			end)
		else
			raceCheckbox:SetLabel("Any")
			raceCheckbox:SetValue(tracker.race == nil)
			raceCheckbox:SetCallback("OnValueChanged", function(self, event, value)
				tracker.race = nil
				Addon:Refresh(tracker)
			end)
		end
	end

	setupRace(nil, innerGroup1)
	setupRace(races[1], innerGroup1)

	for i = 2, #races do
		setupRace(races[i], innerGroup2)
	end
	for i = 1, #alliedRaces do
		setupRace(alliedRaces[i], innerGroup3)
	end
end

function Addon:CreateClassConfigurationFrame(container, tracker)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("List")
	group:SetTitle("Classes")
	group:SetFullWidth(true)
	container:AddChild(group)

	local anyClassCheckbox = AceGUI:Create("CheckBox")
	anyClassCheckbox:SetLabel("Any")
	anyClassCheckbox:SetValue(tracker.class == nil)
	anyClassCheckbox:SetFullWidth(true)
	anyClassCheckbox:SetCallback("OnValueChanged", function(self, event, value)
		tracker.class = nil
		Addon:Refresh(tracker)
	end)
	group:AddChild(anyClassCheckbox)

	local innerGroup = AceGUI:Create("SimpleGroup")
	innerGroup:SetLayout("Flow")
	innerGroup:SetFullWidth(true)
	group:AddChild(innerGroup)

	for class, localized in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		local classCheckbox = AceGUI:Create("CheckBox")
		classCheckbox:SetLabel("|c"..RAID_CLASS_COLORS[class].colorStr..localized.."|r")
		classCheckbox:SetValue(tracker.class and S:Contains(tracker.class, class))
		classCheckbox:SetRelativeWidth(0.5)
		classCheckbox:SetCallback("OnValueChanged", function(self, event, value)
			if value then
				if tracker.class == nil then
					tracker.class = {}
				end
				table.insert(tracker.class, class)
			else
				S:RemoveValue(tracker.class, class)
				if S:IsEmpty(tracker.class) then
					tracker.class = nil
				end
			end
			tracker.spec = nil
			tracker.talents = nil
			Addon:Refresh(tracker)
		end)
		innerGroup:AddChild(classCheckbox)
	end
end

function Addon:CreateTalentConfigurationFrame(container, tracker)
	if not tracker.class or #tracker.class ~= 1 then
		return
	end

	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("List")
	group:SetTitle("Talents")
	group:SetFullWidth(true)
	container:AddChild(group)

	local levels = { 15, 30, 45, 60, 75, 90, 100 }
	if tracker.class[1] == "DEATHKNIGHT" then
		levels = { 56, 57, 58, 60, 75, 90, 100 }
	elseif tracker.class[1] == "DEMONHUNTER" then
		levels = { 99, 100, 102, 104, 106, 108, 110 }
	end

	for i = 1, 7 do
		local innerGroup = AceGUI:Create("SimpleGroup")
		innerGroup:SetLayout("Flow")
		innerGroup:SetFullWidth(true)
		group:AddChild(innerGroup)

		local talentLabel = AceGUI:Create("Label")
		talentLabel:SetText(levels[i])
		talentLabel:SetWidth(50)
		innerGroup:AddChild(talentLabel)

		for j = 1, 3 do
			local value = nil
			if tracker.talent then
				for index, talent in pairs(tracker.talent) do
					if talent[1] == i and talent[2] == j then
						value = #talent == 2 or talent[3]
					end
				end
			end

			local talentCheckbox = AceGUI:Create("CheckBox")
			talentCheckbox:SetLabel("")
			talentCheckbox:SetTriState(true)
			talentCheckbox:SetValue(value)
			talentCheckbox:SetWidth(32)
			talentCheckbox:SetCallback("OnValueChanged", function(self, event, value)
				if tracker.talent then
					for index, talent in pairs(tracker.talent) do
						if talent[1] == i and talent[2] == j then
							table.remove(tracker.talent, index)
						end
					end
					if S:IsEmpty(tracker.talent) then
						tracker.talent = nil
					end
				end
				if value ~= nil then
					if not tracker.talent then
						tracker.talent = {}
					end
					table.insert(tracker.talent, { i, j, value })
				end
				Addon:Refresh(tracker)
			end)
			innerGroup:AddChild(talentCheckbox)
		end
	end
end

function Addon:CreateEquippedConfigurationFrame(container, tracker)
	local group = AceGUI:Create("InlineGroup")
	group:SetLayout("List")
	group:SetTitle("Equipped")
	group:SetFullWidth(true)
	container:AddChild(group)

	if tracker.equipped then
		for equippedIndex, equipped in pairs(tracker.equipped) do
			local innerGroup = AceGUI:Create("SimpleGroup")
			innerGroup:SetLayout("Flow")
			innerGroup:SetFullWidth(true)
			group:AddChild(innerGroup)

			local editbox = AceGUI:Create("EditBox")
			editbox:SetText(equipped)
			editbox:SetRelativeWidth(0.65)
			editbox:SetCallback("OnEnterPressed", function(self, event, text)
				tracker.equipped[equippedIndex] = text
				self:ClearFocus()
				Addon:Refresh(tracker)
			end)
			innerGroup:AddChild(editbox)

			local removeButton = AceGUI:Create("Button")
			removeButton:SetText("Remove")
			removeButton:SetRelativeWidth(0.35)
			removeButton:SetCallback("OnClick", function(self, event)
				table.remove(tracker.equipped, equippedIndex)
				Addon:Refresh(tracker)
			end)
			innerGroup:AddChild(removeButton)
		end
	end

	local addButton = AceGUI:Create("Button")
	addButton:SetText("Add equipped item")
	addButton:SetFullWidth(true)
	addButton:SetCallback("OnClick", function(self, event)
		if not tracker.equipped then
			tracker.equipped = {}
		end
		table.insert(tracker.equipped, "")
		Addon:Refresh(tracker)
	end)
	group:AddChild(addButton)
end