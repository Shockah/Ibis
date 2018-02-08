local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")

local Class = {
	prototype = {},
	factories = {},
}
Addon.IndicatorFactory = Class
local Instance = Class.prototype

local factories = Class.factories

function Class:New(type, name)
	local obj = S:Clone(Class.prototype)
	obj.type = type
	obj.name = name
	return obj
end

function Class:Register(factory)
	factories[factory.type] = factory
end

function Class:Instantiate(parentFrame, action, config, tracker)
	if not config or not config.type then
		return nil
	end

	local factory = factories[config.type]
	if not factory then
		return nil
	end

	local indicator = factory:Get(parentFrame, action, config, tracker)
	if indicator then
		indicator.action = action
		indicator.tracker = tracker
		indicator.factory = factory
	end

	return indicator
end

function Class:CreateConfigMenu(configAddon, tracker, container)
	if S:IsEmpty(factories) and S:IsEmpty(tracker.indicatorConfigs) then
		return
	end

	local AceGUI = LibStub("AceGUI-3.0")

	local indicatorsHeading = AceGUI:Create("Heading")
	indicatorsHeading:SetText("Indicators")
	indicatorsHeading:SetFullWidth(true)
	container:AddChild(indicatorsHeading)

	for _, indicatorConfig in pairs(tracker.indicatorConfigs) do
		local group = AceGUI:Create("InlineGroup")
		group:SetTitle(factories[indicatorConfig.type].name)
		group:SetFullWidth(true)
		container:AddChild(group)

		factories[indicatorConfig.type]:CreateConfigMenu(configAddon, tracker, group, indicatorConfig)

		local removeButton = AceGUI:Create("Button")
		removeButton:SetText("Remove")
		removeButton:SetFullWidth(true)
		removeButton:SetCallback("OnClick", function(self, event)
			S:RemoveValue(tracker.indicatorConfigs, indicatorConfig)
			configAddon:Refresh(tracker)
		end)
		group:AddChild(removeButton)
	end

	local sortedFactories = S:Clone(factories)
	table.sort(sortedFactories, function(a, b)
		return a.name < b.name
	end)

	for _, factory in pairs(sortedFactories) do
		local addIndicatorButton = AceGUI:Create("Button")
		addIndicatorButton:SetText("Add "..factory.name)
		addIndicatorButton:SetFullWidth(true)
		addIndicatorButton:SetCallback("OnClick", function(self, event)
			table.insert(tracker.indicatorConfigs, factory:CreateBlankConfig(configAddon, tracker))
			configAddon:Refresh(tracker)
		end)
		container:AddChild(addIndicatorButton)
	end
end

function Class:CreateColorConfigMenu(configAddon, tracker, container, tbl, label)
	local AceGUI = LibStub("AceGUI-3.0")

	local providedExtraDataColors = tracker:ProvidedExtraDataColors()
	local hasExtra = providedExtraDataColors and not S:IsEmpty(providedExtraDataColors)

	local group
	if hasExtra then
		group = AceGUI:Create("InlineGroup")
		group:SetLayout("Flow")
		group:SetTitle(label)
		group:SetFullWidth(true)
		container:AddChild(group)
	else
		group = container
	end

	local color = Addon:ParseColorConfig(tbl, nil, true)
	local colorPicker = AceGUI:Create("ColorPicker")
	colorPicker:SetLabel(hasExtra and "Color" or label)
	colorPicker:SetHasAlpha(true)
	colorPicker:SetColor(color[1], color[2], color[3], color[4])
	colorPicker:SetDisabled(tbl.extraDataColor ~= nil)
	colorPicker:SetFullWidth(true)
	colorPicker:SetCallback("OnValueConfirmed", function(self, event, r, g, b, a)
		tbl.rgbi = nil
		tbl.rgbai = nil
		tbl.rgb = nil
		tbl.rgba = { r, g, b, a }
		tbl.extraDataColor = nil
		configAddon:Refresh(tracker)
	end)
	group:AddChild(colorPicker)

	if hasExtra then
		for _, extraColorName in pairs(providedExtraDataColors) do
			local extraColorCheckbox = AceGUI:Create("CheckBox")
			extraColorCheckbox:SetLabel(extraColorName)
			extraColorCheckbox:SetValue(tbl.extraDataColor == extraColorName)
			extraColorCheckbox:SetWidth(120)
			extraColorCheckbox:SetCallback("OnValueChanged", function(self, event, value)
				tbl.rgbi = nil
				tbl.rgbai = nil
				tbl.rgb = nil
				tbl.rgba = nil
				tbl.extraDataColor = value and extraColorName or nil
				configAddon:Refresh(tracker)
			end)
			group:AddChild(extraColorCheckbox)
		end
	end

	local pulsing = tbl.alphaPulsing or {}
	pulsing.frequency = pulsing.frequency or 2.0
	pulsing.factor = pulsing.factor or 0.0

	local function setupPulsing()
		if pulsing.frequency == 2.0 and pulsing.factor == 0.0 then
			tbl.alphaPulsing = nil
		else
			tbl.alphaPulsing = pulsing
		end
	end

	local pulseGroup = AceGUI:Create("InlineGroup")
	pulseGroup:SetLayout("Flow")
	pulseGroup:SetTitle("Pulsing")
	pulseGroup:SetFullWidth(true)
	group:AddChild(pulseGroup)

	local pulseFrequencySlider = AceGUI:Create("Slider")
	pulseFrequencySlider:SetLabel("Frequency")
	pulseFrequencySlider:SetSliderValues(0.0, 10.0, 0.05)
	pulseFrequencySlider:SetValue(pulsing.frequency)
	pulseFrequencySlider:SetRelativeWidth(0.5)
	pulseFrequencySlider:SetCallback("OnMouseUp", function(self, event, value)
		pulsing.frequency = value
		setupPulsing()
		configAddon:Refresh(tracker)
	end)
	pulseGroup:AddChild(pulseFrequencySlider)

	local pulseFactorSlider = AceGUI:Create("Slider")
	pulseFactorSlider:SetLabel("Factor")
	pulseFactorSlider:SetSliderValues(0.0, 1.0, 0.01)
	pulseFactorSlider:SetValue(pulsing.factor)
	pulseFactorSlider:SetRelativeWidth(0.5)
	pulseFactorSlider:SetCallback("OnMouseUp", function(self, event, value)
		pulsing.factor = value
		setupPulsing()
		configAddon:Refresh(tracker)
	end)
	pulseGroup:AddChild(pulseFactorSlider)
end

function Instance:CreateBlankConfig(configAddon, tracker)
	return nil
end

function Instance:Get(action, config, tracker)
	return nil
end

function Instance:Free(indicator)
end

function Instance:CreateConfigMenu(configAddon, tracker, container, indicatorConfig)
end