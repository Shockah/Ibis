local addonName, addonTable = ...

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceEvent-3.0")
local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

function Addon:OnInitialize()
	local factory = BaseAddon.IndicatorFactory:New("roundHighlight", "Round Highlight")

	function factory:CreateBlankConfig(configAddon, tracker)
		local r, g, b = 1.0, 1.0, 1.0
		local icon = tracker:GetIcon(false)
		if icon then
			r, g, b = configAddon.Niji.GetIconColor(icon, r, g, b)
		end
		
		return {
			type = self.type,
			rgb = { r, g, b },
			scale = 1.8,
		}
	end

	function factory:Get(parentFrame, action, config, tracker)
		local indicator = Addon.Indicator:Get(parentFrame, action, config, tracker)
		indicator.factory = self
		return indicator
	end

	function factory:Free(indicator)
		Addon.Indicator:Free(indicator)
	end

	function factory:CreateConfigMenu(configAddon, tracker, container, indicatorConfig)
		self:AddBaseConfig(configAddon, tracker, container, indicatorConfig)
		self:AddSpecificConfig(configAddon, tracker, container, indicatorConfig)
		self:AddColorConfig(configAddon, tracker, container, indicatorConfig)
	end

	function factory:AddBaseConfig(configAddon, tracker, container, indicatorConfig)
		local AceGUI = LibStub("AceGUI-3.0")

		local stratas = {
			"<default>",
			"BACKGROUND",
			"LOW",
			"MEDIUM",
			"HIGH",
			"DIALOG",
			"FULLSCREEN",
			"FULLSCREEN_DIALOG",
			"TOOLTIP",
		}

		local layers = {
			"<default>",
			"ARTWORK",
			"BACKGROUND",
			"BORDER",
			"HIGHLIGHT",
			"OVERLAY",
		}

		local blendModes = {
			"<default>",
			"BLEND",
			"ADD",
			"ALPHAKEY",
			"MOD",
			"DISABLE",
		}

		local textureGroup = AceGUI:Create("InlineGroup")
		textureGroup:SetLayout("Flow")
		textureGroup:SetTitle("Texture")
		textureGroup:SetFullWidth(true)
		container:AddChild(textureGroup)

		local defaultTexture, defaultTextureName = tracker.frameType:GetDefaultTexture(nil)

		local textureEditbox = AceGUI:Create("EditBox")
		textureEditbox:SetText(indicatorConfig.texture or defaultTextureName or "")
		textureEditbox:SetFullWidth(true)
		textureEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			if text == defaultTextureName then
				text = nil
			end
			indicatorConfig.texture = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		textureGroup:AddChild(textureEditbox)

		if defaultTextureName then
			local borderTextureButton = AceGUI:Create("Button")
			borderTextureButton:SetText(defaultTextureName)
			borderTextureButton:SetRelativeWidth(0.5)
			borderTextureButton:SetCallback("OnClick", function(self, event)
				indicatorConfig.texture = nil
				configAddon:Refresh(tracker)
			end)
			textureGroup:AddChild(borderTextureButton)
		end

		local vanillaTextureButton = AceGUI:Create("Button")
		vanillaTextureButton:SetText("Vanilla")
		if defaultTextureName then
			vanillaTextureButton:SetRelativeWidth(0.5)
		else
			vanillaTextureButton:SetFullWidth(true)
		end
		vanillaTextureButton:SetCallback("OnClick", function(self, event)
			indicatorConfig.texture = "Interface/BUTTONS/UI-ActionButton-Border"
			configAddon:Refresh(tracker)
		end)
		textureGroup:AddChild(vanillaTextureButton)

		self:AddOffsetConfig(configAddon, tracker, container, indicatorConfig, false, true)

		local scaleSlider = AceGUI:Create("Slider")
		scaleSlider:SetLabel("Scale")
		scaleSlider:SetSliderValues(0.0, 5.0, 0.01)
		scaleSlider:SetValue(indicatorConfig.scale or 1.0)
		scaleSlider:SetFullWidth(true)
		scaleSlider:SetCallback("OnMouseUp", function(self, event, value)
			indicatorConfig.scale = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(scaleSlider)

		local strataDropdown = AceGUI:Create("Dropdown")
		strataDropdown:SetLabel("Frame Strata")
		strataDropdown:SetList(stratas)
		strataDropdown:SetValue(S:KeyOf(stratas, indicatorConfig.strata or stratas[1]))
		strataDropdown:SetFullWidth(true)
		strataDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = stratas[key]
			if value == stratas[1] then
				value = nil
			end
			indicatorConfig.strata = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(strataDropdown)

		local layerDropdown = AceGUI:Create("Dropdown")
		layerDropdown:SetLabel("Layer")
		layerDropdown:SetList(layers)
		layerDropdown:SetValue(S:KeyOf(layers, indicatorConfig.layer or layers[1]))
		layerDropdown:SetFullWidth(true)
		layerDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = layers[key]
			if value == layers[1] then
				value = nil
			end
			indicatorConfig.layer = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(layerDropdown)

		local blendModeDropdown = AceGUI:Create("Dropdown")
		blendModeDropdown:SetLabel("Blend mode")
		blendModeDropdown:SetList(blendModes)
		blendModeDropdown:SetValue(S:KeyOf(blendModes, indicatorConfig.blendMode or blendModes[1]))
		blendModeDropdown:SetFullWidth(true)
		blendModeDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = blendModes[key]
			if value == blendModes[1] then
				value = nil
			end
			indicatorConfig.blendMode = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(blendModeDropdown)

		local initialAngleSlider = AceGUI:Create("Slider")
		initialAngleSlider:SetLabel("Angle")
		initialAngleSlider:SetSliderValues(0, 360, 1)
		initialAngleSlider:SetValue(indicatorConfig.initialAngle or 0)
		initialAngleSlider:SetFullWidth(true)
		initialAngleSlider:SetCallback("OnMouseUp", function(self, event, value)
			if value == 0 then
				value = nil
			end
			indicatorConfig.initialAngle = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(initialAngleSlider)

		local fullDegreesSlider = AceGUI:Create("Slider")
		fullDegreesSlider:SetLabel("Degrees while full")
		fullDegreesSlider:SetSliderValues(0, 360, 1)
		fullDegreesSlider:SetValue(indicatorConfig.fullAngle or 360)
		fullDegreesSlider:SetFullWidth(true)
		fullDegreesSlider:SetCallback("OnMouseUp", function(self, event, value)
			if value == 360 then
				value = nil
			end
			indicatorConfig.fullAngle = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(fullDegreesSlider)
	end

	function factory:AddOffsetConfig(configAddon, tracker, container, indicatorConfig, percentage, pixel)
		local AceGUI = LibStub("AceGUI-3.0")
		local both = percentage and pixel

		local group = container

		if both then
			local offsetGroup = AceGUI:Create("InlineGroup")
			offsetGroup:SetLayout("List")
			offsetGroup:SetTitle("Offset")
			offsetGroup:SetFullWidth(true)
			group:AddChild(offsetGroup)
			group = offsetGroup
		end

		if percentage then
			local percentageOffsetGroup = AceGUI:Create("InlineGroup")
			percentageOffsetGroup:SetLayout("Flow")
			percentageOffsetGroup:SetTitle(both and "Percentage" or "Percentage Offset")
			percentageOffsetGroup:SetFullWidth(true)
			group:AddChild(percentageOffsetGroup)

			local percentageXSlider = AceGUI:Create("Slider")
			percentageXSlider:SetLabel("X")
			percentageXSlider:SetSliderValues(-1.5, 1.5, 0.01)
			percentageXSlider:SetValue(indicatorConfig.percentOffX or 0.0)
			percentageXSlider:SetRelativeWidth(0.5)
			percentageXSlider:SetCallback("OnMouseUp", function(self, event, value)
				if value == 0.0 then
					value = nil
				end
				indicatorConfig.percentOffX = value
				configAddon:Refresh(tracker)
			end)
			percentageOffsetGroup:AddChild(percentageXSlider)

			local percentageYSlider = AceGUI:Create("Slider")
			percentageYSlider:SetLabel("Y")
			percentageYSlider:SetSliderValues(-1.5, 1.5, 0.01)
			percentageYSlider:SetValue(indicatorConfig.percentOffY or 0.0)
			percentageYSlider:SetRelativeWidth(0.5)
			percentageYSlider:SetCallback("OnMouseUp", function(self, event, value)
				if value == 0.0 then
					value = nil
				end
				indicatorConfig.percentOffY = value
				configAddon:Refresh(tracker)
			end)
			percentageOffsetGroup:AddChild(percentageYSlider)
		end

		if pixel then
			local pixelOffsetGroup = AceGUI:Create("InlineGroup")
			pixelOffsetGroup:SetLayout("Flow")
			pixelOffsetGroup:SetTitle(both and "Pixel" or "Pixel Offset")
			pixelOffsetGroup:SetFullWidth(true)
			group:AddChild(pixelOffsetGroup)

			local pixelXSlider = AceGUI:Create("Slider")
			pixelXSlider:SetLabel("X")
			pixelXSlider:SetSliderValues(-100, 100, 1)
			pixelXSlider:SetValue(indicatorConfig.offX or 0)
			pixelXSlider:SetRelativeWidth(0.5)
			pixelXSlider:SetCallback("OnMouseUp", function(self, event, value)
				if value == 0 then
					value = nil
				end
				indicatorConfig.offX = value
				configAddon:Refresh(tracker)
			end)
			pixelOffsetGroup:AddChild(pixelXSlider)

			local pixelYSlider = AceGUI:Create("Slider")
			pixelYSlider:SetLabel("Y")
			pixelYSlider:SetSliderValues(-100, 100, 1)
			pixelYSlider:SetValue(indicatorConfig.offY or 0)
			pixelYSlider:SetRelativeWidth(0.5)
			pixelYSlider:SetCallback("OnMouseUp", function(self, event, value)
				if value == 0 then
					value = nil
				end
				indicatorConfig.offY = value
				configAddon:Refresh(tracker)
			end)
			pixelOffsetGroup:AddChild(pixelYSlider)
		end
	end

	function factory:AddSpecificConfig(configAddon, tracker, container, indicatorConfig)
		local AceGUI = LibStub("AceGUI-3.0")

		local fillMode = {
			"centered",
			"clockwise",
			"counter-clockwise",
		}
		local fillModeValues = {
			0,
			0.5,
			-0.5,
		}

		local fillModeDropdown = AceGUI:Create("Dropdown")
		fillModeDropdown:SetLabel("Fill mode")
		fillModeDropdown:SetList(fillMode)
		fillModeDropdown:SetValue(S:KeyOf(fillModeValues, indicatorConfig.fillMode or fillModeValues[1]))
		fillModeDropdown:SetFullWidth(true)
		fillModeDropdown:SetCallback("OnValueChanged", function(self, event, key)
			local value = fillModeValues[key]
			if value == fillModeValues[1] then
				value = nil
			end
			indicatorConfig.fillMode = value
			configAddon:Refresh(tracker)
		end)
		container:AddChild(fillModeDropdown)
	end

	function factory:AddColorConfig(configAddon, tracker, container, indicatorConfig)
		BaseAddon.IndicatorFactory:CreateColorConfigMenu(configAddon, tracker, container, indicatorConfig, "Color")
	end

	BaseAddon:RegisterIndicatorFactory(factory)
end