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

	function factory:Get(action, config, tracker)
		local indicator = Addon.Indicator:Get(action, config, tracker)
		indicator.factory = self
		return indicator
	end

	function factory:Free(indicator)
		Addon.Indicator:Free(indicator)
	end

	function factory:CreateConfigMenu(configAddon, tracker, container, indicatorConfig)
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

		local textureEditbox = AceGUI:Create("EditBox")
		textureEditbox:SetText(indicatorConfig.texture or "<use the button border texture>")
		textureEditbox:SetFullWidth(true)
		textureEditbox:SetCallback("OnEnterPressed", function(self, event, text)
			indicatorConfig.texture = S:StringOrNil(text)
			self:ClearFocus()
			configAddon:Refresh(tracker)
		end)
		textureGroup:AddChild(textureEditbox)

		local borderTextureButton = AceGUI:Create("Button")
		borderTextureButton:SetText("Button border")
		borderTextureButton:SetRelativeWidth(0.5)
		borderTextureButton:SetCallback("OnClick", function(self, event)
			indicatorConfig.texture = nil
			configAddon:Refresh(tracker)
		end)
		textureGroup:AddChild(borderTextureButton)

		local vanillaTextureButton = AceGUI:Create("Button")
		vanillaTextureButton:SetText("Vanilla")
		vanillaTextureButton:SetRelativeWidth(0.5)
		vanillaTextureButton:SetCallback("OnClick", function(self, event)
			indicatorConfig.texture = "Interface/BUTTONS/UI-ActionButton-Border"
			configAddon:Refresh(tracker)
		end)
		textureGroup:AddChild(vanillaTextureButton)

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

		BaseAddon.IndicatorFactory:CreateColorConfigMenu(configAddon, tracker, container, indicatorConfig, "Color")

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
	end

	BaseAddon:RegisterIndicatorFactory(factory)
end