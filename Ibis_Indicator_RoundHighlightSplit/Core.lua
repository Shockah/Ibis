local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

function Addon:OnInitialize()
	local factory = BaseAddon.IndicatorFactory:New("roundHighlightSplit", "Split Round Highlight")
	factory.baseFactory = BaseAddon.IndicatorFactory.factories["roundHighlight"]

	function factory:CreateBlankConfig(configAddon, tracker)
		local config = self.baseFactory:CreateBlankConfig(configAddon, tracker)

		config.type = self.type

		local color = BaseAddon:ParseColorConfig(config, nil, true)
		for i = 1, 3 do
			color[i] = color[i] * 0.25
		end
		color[4] = color[4] * 0.5
		config.inactive = {
			rgba = color,
		}

		return config
	end

	function factory:Get(action, config, tracker)
		local indicator = Addon.Indicator:Get(action, config, tracker)
		indicator.factory = self
		return indicator
	end

	function factory:Free(indicator)
		Addon.Indicator:Free(indicator)
	end

	function factory:CreateConfigMenu(configAddon, tracker, container, indicatorConfig)
		self:AddBaseConfig(configAddon, tracker, container, indicatorConfig)
		self:AddColorConfig(configAddon, tracker, container, indicatorConfig)
	end

	function factory:AddBaseConfig(configAddon, tracker, container, indicatorConfig)
		local AceGUI = LibStub("AceGUI-3.0")

		self.baseFactory:AddBaseConfig(configAddon, tracker, container, indicatorConfig)

		local stackDegreesSlider = AceGUI:Create("Slider")
		stackDegreesSlider:SetLabel("Stack degrees (0 = auto)")
		stackDegreesSlider:SetSliderValues(0, 180, 0.5)
		stackDegreesSlider:SetValue(indicatorConfig.stackAngle or 0)
		stackDegreesSlider:SetFullWidth(true)
		stackDegreesSlider:SetCallback("OnMouseUp", function(self, event, value)
			if value == 0 then
				value = nil
			end
			indicatorConfig.stackAngle = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(stackDegreesSlider)

		local emptySpaceDegreesSlider = AceGUI:Create("Slider")
		emptySpaceDegreesSlider:SetLabel("Empty space degrees")
		emptySpaceDegreesSlider:SetSliderValues(0, 180, 0.5)
		emptySpaceDegreesSlider:SetValue(indicatorConfig.spaceAngle or 20)
		emptySpaceDegreesSlider:SetFullWidth(true)
		emptySpaceDegreesSlider:SetCallback("OnMouseUp", function(self, event, value)
			if value == 0 then
				value = nil
			end
			indicatorConfig.spaceAngle = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(emptySpaceDegreesSlider)
	end

	function factory:AddColorConfig(configAddon, tracker, container, indicatorConfig)
		BaseAddon.IndicatorFactory:CreateColorConfigMenu(configAddon, tracker, container, indicatorConfig, "Active color")

		if not indicatorConfig.inactive then
			indicatorConfig.inactive = {}
		end
		BaseAddon.IndicatorFactory:CreateColorConfigMenu(configAddon, tracker, container, indicatorConfig.inactive, "Inactive color")
	end

	BaseAddon:RegisterIndicatorFactory(factory)
end