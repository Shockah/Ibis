local addonName, addonTable = ...

local Addon = _G[addonName]
local S = LibStub:GetLibrary("ShockahUtils")
local BaseAddon = _G[S:Split(addonName, "_")[1]]

local Class = {
	prototype = {},
}
Addon.Indicator = Class
local Instance = Class.prototype

local Private = {}
Class["__Private"] = Private

local free = {}

local defaultTexCoord = {
	ULx = 0, ULy = 0,
	LLx = 0, LLy = 1,
	URx = 1, URy = 0,
	LRx = 1, LRy = 1,
}

function Class:Get(action, config, tracker)
	local obj
	if S:IsEmpty(free) then
		obj = Private:Create(action, config, tracker)
	else
		obj = free[1]
		table.remove(free, 1)
	end
	obj:Setup(action, config, tracker)
	return obj
end

function Class:Free(indicator)
	indicator:Free()
end

function Instance:Free()
	self:SetScript("OnUpdate", nil)
	self:ClearAllPoints()
	self:Hide()

	table.insert(free, self)
end

function Private:Create(action, config, tracker)
	local indicator = CreateFrame("frame", nil, action.button or UIParent)
	S:CloneInto(Instance, indicator)

	indicator.textures = {}
	indicator.coords = {}
	for i = 1, 3 do
		local texture = indicator:CreateTexture()
		texture:SetAllPoints(indicator)
		table.insert(indicator.textures, texture)

		local coord = Private:CreateTexCoord(texture)
		table.insert(indicator.coords, coord)
	end

	return indicator
end

function Private:CreateTexCoord(texture)
	local coord = {
		ULx = 0, ULy = 0,
		LLx = 0, LLy = 1,
		URx = 1, URy = 0,
		LRx = 1, LRy = 1,

		ULvx = 0, ULvy = 0,
		LLvx = 0, LLvy = 0,
		URvx = 0, URvy = 0,
		LRvx = 0, LRvy = 0,

		texture = texture
	}

	local function ApplyTransform(x, y, scalex, scaley, rotation, mirror_h, mirror_v)
		x = ((x - 0.5) * 1.4142) / scalex
		y = ((y - 0.5) * 1.4142) / scaley

		if mirror_h then
			x = -x
		end
		if mirror_v then
			y = -y
		end

		local cos_rotation = cos(rotation)
		local sin_rotation = sin(rotation)

		x, y = cos_rotation * x - sin_rotation * y, sin_rotation * x + cos_rotation * y
		return x + 0.5, y + 0.5
	end

	function coord:MoveCorner(corner, x, y)
		local width, height = self.texture:GetSize()
		local rx = defaultTexCoord[corner.."x"] - x
		local ry = defaultTexCoord[corner.."y"] - y
		coord[corner.."vx"] = -rx * width
		coord[corner.."vy"] = ry * height

		coord[corner.."x"] = x
		coord[corner.."y"] = y
	end

	function coord:Hide()
		coord.texture:Hide()
	end

	function coord:Show()
		coord:Apply()
		coord.texture:Show()
	end

	function coord:SetFull()
		coord.ULx, coord.ULy = 0, 0
		coord.LLx, coord.LLy = 0, 1
		coord.URx, coord.URy = 1, 0
		coord.LRx, coord.LRy = 1, 1

		coord.ULvx, coord.ULvy = 0, 0
		coord.LLvx, coord.LLvy = 0, 0
		coord.URvx, coord.URvy = 0, 0
		coord.LRvx, coord.LRvy = 0, 0
	end

	function coord:Apply()
		coord.texture:SetVertexOffset(UPPER_RIGHT_VERTEX, coord.URvx, coord.URvy)
		coord.texture:SetVertexOffset(UPPER_LEFT_VERTEX, coord.ULvx, coord.ULvy)
		coord.texture:SetVertexOffset(LOWER_RIGHT_VERTEX, coord.LRvx, coord.LRvy)
		coord.texture:SetVertexOffset(LOWER_LEFT_VERTEX, coord.LLvx, coord.LLvy)
		coord.texture:SetTexCoord(coord.ULx, coord.ULy, coord.LLx, coord.LLy, coord.URx, coord.URy, coord.LRx, coord.LRy)
	end

	local exactAngles = {
		{ 0.5, 0 },	-- 0°
		{ 1, 0 },	-- 45°
		{ 1, 0.5 },	-- 90°
		{ 1, 1 },	-- 135°
		{ 0.5, 1 },	-- 180°
		{ 0, 1 },	-- 225°
		{ 0, 0.5 },	-- 270°
		{ 0, 0 },	-- 315°
	}

	local function angleToCoord(angle)
		angle = angle % 360

		if angle % 45 == 0 then
			local index = floor (angle / 45) + 1
			return exactAngles[index][1], exactAngles[index][2]
		end

		if angle < 45 then
			return 0.5 + tan(angle) / 2, 0
		elseif angle < 135 then
			return 1, 0.5 + tan(angle - 90) / 2
		elseif angle < 225 then
			return 0.5 - tan(angle) / 2, 1
		elseif angle < 315 then
			return 0, 0.5 - tan(angle - 90) / 2
		elseif angle < 360 then
			return 0.5 + tan(angle) / 2, 0
		end
	end

	local pointOrder = { "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR", "LL", "UL", "UR", "LR" }

	function coord:SetAngle(angle1, angle2)
		local index = floor((angle1 + 45) / 90)

		local middleCorner = pointOrder[index + 1]
		local startCorner = pointOrder[index + 2]
		local endCorner1 = pointOrder[index + 3]
		local endCorner2 = pointOrder[index + 4]

		-- LL => 32, 32
		-- UL => 32, -32
		self:MoveCorner(middleCorner, 0.5, 0.5)
		self:MoveCorner(startCorner, angleToCoord(angle1))

		local edge1 = floor((angle1 - 45) / 90)
		local edge2 = floor((angle2 -45) / 90)

		if edge1 == edge2 then
			self:MoveCorner(endCorner1, angleToCoord(angle2))
		else
			self:MoveCorner(endCorner1, defaultTexCoord[endCorner1.."x"], defaultTexCoord[endCorner1.."y"])
		end

		self:MoveCorner(endCorner2, angleToCoord(angle2))
	end

	function coord:Transform(scalex, scaley, rotation, mirror_h, mirror_v)
		coord.ULx, coord.ULy = ApplyTransform(coord.ULx, coord.ULy, scalex, scaley, rotation, mirror_h, mirror_v)
		coord.LLx, coord.LLy = ApplyTransform(coord.LLx, coord.LLy, scalex, scaley, rotation, mirror_h, mirror_v)
		coord.URx, coord.URy = ApplyTransform(coord.URx, coord.URy, scalex, scaley, rotation, mirror_h, mirror_v)
		coord.LRx, coord.LRy = ApplyTransform(coord.LRx, coord.LRy, scalex, scaley, rotation, mirror_h, mirror_v)
	end

	return coord
end

function Instance:SetTexture(texture)
	for i = 1, #self.textures do
		self.textures[i]:SetTexture(texture)
	end
end

function Instance:SetVertexColor(r, g, b, a)
	for i = 1, #self.textures do
		self.textures[i]:SetVertexColor(r, g, b, a or 1.0)
	end
end

function Instance:SetBlendMode(blendMode)
	for i = 1, #self.textures do
		self.textures[i]:SetBlendMode(blendMode)
	end
end

function Instance:SetDrawLayer(layer, sublayer)
	for i = 1, #self.textures do
		self.textures[i]:SetDrawLayer(layer, sublayer)
	end
end

function Instance:ClearAngle()
	self.coords[1]:Hide()
	self.coords[2]:Hide()
	self.coords[3]:Hide()
end

function Instance:SetAngle(angle1, angle2)
	local scalex = 1.4142
	local scaley = 1.4142
	local rotate = 0
	local mirror_h = true
	local mirror_v = false
	if angle2 - angle1 >= 360 or angle1 == angle2 then
		self.coords[1]:SetFull()
		self.coords[1]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[1]:Show()

		self.coords[2]:Hide()
		self.coords[3]:Hide()
		return
	end

	local index1 = floor((angle1 + 45) / 90)
	local index2 = floor((angle2 + 45) / 90)

	if index1 + 1 >= index2 then
		self.coords[1]:SetAngle(angle1, angle2)
		self.coords[1]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[1]:Show()
		self.coords[2]:Hide()
		self.coords[3]:Hide()
	elseif index1 + 3 >= index2 then
		local firstEndAngle = (index1 + 1) * 90 + 45
		self.coords[1]:SetAngle(angle1, firstEndAngle)
		self.coords[1]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[1]:Show()

		self.coords[2]:SetAngle(firstEndAngle, angle2)
		self.coords[2]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[2]:Show()

		self.coords[3]:Hide()
	else
		local firstEndAngle = (index1 + 1) * 90 + 45
		local secondEndAngle = firstEndAngle + 180

		self.coords[1]:SetAngle(angle1, firstEndAngle)
		self.coords[1]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[1]:Show()

		self.coords[2]:SetAngle(firstEndAngle, secondEndAngle)
		self.coords[2]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[2]:Show()

		self.coords[3]:SetAngle(secondEndAngle, angle2)
		self.coords[3]:Transform(scalex, scaley, rotate, mirror_h, mirror_v)
		self.coords[3]:Show()
	end
end

function Instance:Setup(action, config, tracker)
	self.config = config

	local scale = config.scale or 1.1

	self:ClearAllPoints()
	self:SetPoint("CENTER", action.button, "CENTER")
	self:SetSize(action.button.Border:GetWidth() * scale, action.button.Border:GetHeight() * scale)
	self:SetTexture(config.texture or action.button.Border:GetTexture())
	self:SetBlendMode(config.blendMode or "ADD")
	self:SetFrameStrata(config.strata or "MEDIUM")
	self:SetDrawLayer(config.layer or "BORDER")
	self:SetScript("OnUpdate", function(self)
		self:Update()
	end)

	self:Show()
end

function Instance:Update()
	local current, maximum, extraData = self.tracker:GetValue()
	local extraDataColors = extraData and extraData.colors

	self:UpdateAngle(current, maximum)
	self:UpdateColor(extraDataColors)
end

function Instance:UpdateAngle(current, maximum)
	if not self.tracker:ShouldLoadRightNow() then
		self:ClearAngle()
		return
	end

	local current, maximum = self.tracker:GetValue()
	if current then
		local f = current / maximum
		local angle = (1.0 - f) * 360

		local initialAngle = self.config.initialAngle or 0
		self:SetAngle(initialAngle + angle / 2.0, initialAngle + 360 - angle / 2.0)
	else
		self:ClearAngle()
	end
end

function Instance:UpdateColor(extraDataColors)
	local color = BaseAddon:ParseColorConfig(self.config, extraDataColors)
	self:SetVertexColor(color[1], color[2], color[3], color[4])
end