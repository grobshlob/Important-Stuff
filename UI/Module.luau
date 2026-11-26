--!strict

--[[
how to make a class
local dog = {}
dog.__index = dog
--creating instance
function dog.new(name, age, position)
    local self = setmetatable({}, Dog)
    self.name = name
    self.age = age
    self.position = position
    return self
end
--make dog do something
function dog:walk()
	self.position = self.position * 5
end
]]
local ui = {}

local function draw_cat(center: Vector2, scale: number, color: Color3, opacity: number, thickness: number)
	local function line(x1: number, y1: number, x2: number, y2: number)
		local p1 = center + Vector2.new(x1 * scale, y1 * scale)
		local p2 = center + Vector2.new(x2 * scale, y2 * scale)
		DrawingImmediate.Line(p1, p2, color, opacity, thickness)
	end

	-- Ears & forehead
	line(-0.7, -0.2, -0.8, -0.9) -- left ear outer
	line(-0.8, -0.9, -0.3, -0.5) -- left ear inner
	line(-0.3, -0.5,  0.3, -0.5) -- forehead
	line( 0.3, -0.5,  0.8, -0.9) -- right ear inner
	line( 0.8, -0.9,  0.7, -0.2) -- right ear outer

	-- Cheeks & chin
	line( 0.7,  -0.2,  0.85, 0.3)
	line( 0.85,  0.3,  0.45, 0.75)
	line( 0.45,  0.75, -0.45, 0.75)
	line(-0.45,  0.75, -0.85, 0.3)
	line(-0.85,  0.3,  -0.7, -0.2)

	-- eyes (^ ^)
	line(-0.45, 0.05, -0.3, -0.1)
	line(-0.3, -0.1,  -0.15, 0.05)
	line( 0.15, 0.05,  0.3, -0.1)
	line( 0.3, -0.1,   0.45, 0.05)

	-- Mouth (w)
	line(-0.18, 0.28, -0.09, 0.4)
	line(-0.09, 0.4,   0,    0.3)
	line( 0,    0.3,   0.09, 0.4)
	line( 0.09, 0.4,   0.18, 0.28)

	-- Whiskers
	line(-0.62, 0.18, -1.05, 0.1)
	line(-0.62, 0.34, -1.05, 0.4)
	line( 0.62, 0.18,  1.05, 0.1)
	line( 0.62, 0.34,  1.05, 0.4)
end
local RunService = game:GetService("RunService")
local userinput = game:GetService("UserInputService")
local ws = game:GetService("Workspace")
local camera = ws.CurrentCamera
local viewport = camera.ViewportSize

local children = {}

--helpers
local dragging = false
local drag_start = nil
local window_pos = nil
local children_window = {}

function drag(main_window)
	if isleftpressed() then
		local mpos = userinput:GetMouseLocation()
		if not dragging then
			table.clear(children_window)
			for v, _ in pairs(children) do
				table.insert(children_window, {
					child = v,
					pos = v.position
				})
			end
			local pos = main_window.position
			local size = main_window.size
			local xdist = mpos.X - pos.X
			local ydist = mpos.Y - pos.Y
			if xdist > 0 and ydist > 0 then
				if xdist <= size.X and ydist <= size.Y then
					dragging = true
					drag_start = userinput:GetMouseLocation()
					window_pos = pos
				end
			end
		else
			local new_mouse = mpos - drag_start
			main_window.position = window_pos + new_mouse
			for _, v in pairs(children_window) do
				v.child.position = v.pos + new_mouse
			end
		end
	else
		dragging = false
	end
end

function table_size(table_)
	local count = 0
	for _, v in pairs(table_) do
		count += 1
	end
	return count
end
--animations
local animations = {}

function linear(start_position, end_position, instance, duration)
	table.insert(animations, {
		instance = instance,
		start = start_position,
		target = end_position,
		duration = duration,
		elapsed = 0,
		property = "position"
	})
end

function pop(end_size, instance, duration, start, on_complete: (() -> ())?)
	local start_size = start or instance.size
	table.insert(animations, {
		instance = instance,
		start = start_size,
		target = end_size,
		pos = instance.position + (end_size - start_size) / 2,
		end_pos = instance.position,
		duration = duration,
		elapsed = 0,
		property = "size",
		on_complete = on_complete,
	})
end

function bounce(instance, duration, strength)
	table.insert(animations, {
		instance = instance,
		duration = duration,
		elapsed = 0,
		property = "size",
		start = instance.size,
		target = instance.size * strength,
		pos = instance.position,
		pos_mid = instance.position - (instance.size * strength - instance.size) / 2,
		is_bounce = true,
	})
end

function slide_up(instance, duration, on_complete: (() -> ())?)
	table.insert(animations, {
		instance = instance,
		duration = duration,
		elapsed = 0,
		property = "size",
		start = Vector2.new(instance.size.X, 1),
		target = instance.size,
		on_complete = on_complete,
	})
end

function update_animations(dt)
	for i = #animations, 1, -1 do
		local animation = animations[i]

		animation.elapsed += dt

		local alpha = math.clamp(
			animation.elapsed / animation.duration,
			0,
			1
		)

		local t = if animation.is_bounce then math.sin(alpha * math.pi) else alpha

		animation.instance[animation.property] = vector.lerp(
			animation.start,
			animation.target,
			t
		)

		if animation.is_bounce then
			animation.instance.position = vector.lerp(
				animation.pos,
				animation.pos_mid,
				t
			)
		elseif animation.pos and animation.end_pos then
			animation.instance.position = vector.lerp(
				animation.pos,
				animation.end_pos,
				alpha
			)
		end

		if alpha >= 1 then
			if animation.on_complete then
				animation.on_complete()
			end
			table.remove(animations, i)
		end
	end
end

--themes

local Themes = {
	Catppuccin = {
		MainBG   = Color3.fromRGB(24, 24, 37),    -- #181825 Mantle Dark
		BoxFill  = Color3.fromRGB(49, 50, 68),    -- #313244 Surface0
		Outline  = Color3.fromRGB(137, 180, 250), -- #89B4FA Soft Sapphire
		Accent   = Color3.fromRGB(69, 71, 90),    -- #45475A Subtle Border
		Selected = Color3.fromRGB(203, 166, 247), -- #CBA6F7 Mauve Highlight
		Text     = Color3.fromRGB(205, 214, 244), -- #CDD6F4 Crisp Soft White
	},

	MonokaiPro = {
		MainBG   = Color3.fromRGB(34, 31, 34),    -- #221F22 Obsidian
		BoxFill  = Color3.fromRGB(45, 42, 46),    -- #2D2A2E Charcoal
		Outline  = Color3.fromRGB(120, 220, 232), -- #78DCE8 Electric Cyan
		Accent   = Color3.fromRGB(64, 62, 65),    -- #403E41 Dim Border
		Selected = Color3.fromRGB(255, 97, 136),  -- #FF6188 Neon Rose
		Text     = Color3.fromRGB(252, 252, 250), -- #FCFCFA Pure Off-White
	},

	SolarizedDark = {
		MainBG   = Color3.fromRGB(0, 43, 54),     -- #002B36 Base03
		BoxFill  = Color3.fromRGB(7, 54, 66),     -- #073642 Base02
		Outline  = Color3.fromRGB(38, 139, 210),  -- #268BD2 Solar Blue
		Accent   = Color3.fromRGB(88, 110, 117),  -- #586E75 Base01
		Selected = Color3.fromRGB(42, 161, 152),  -- #2AA198 Solar Cyan
		Text     = Color3.fromRGB(147, 161, 161), -- #93A1A1 Base1
	},

	Monochrome = {
		MainBG   = Color3.fromRGB(14, 14, 14),    -- #0E0E0E Matte Black
		BoxFill  = Color3.fromRGB(28, 28, 28),    -- #1C1C1C Dark Grey
		Outline  = Color3.fromRGB(212, 212, 212), -- #D4D4D4 Silver White
		Accent   = Color3.fromRGB(56, 56, 56),    -- #383838 Neutral Grey
		Selected = Color3.fromRGB(115, 115, 115), -- #737373 Slate Highlight
		Text     = Color3.fromRGB(245, 245, 245), -- #F5F5F5 Pure Off-White
	},

	JadeHorizon = {
		MainBG   = Color3.fromRGB(26, 81, 64),    -- #1A5140 Deep Forest[cite: 1]
		BoxFill  = Color3.fromRGB(40, 135, 96),   -- #288760 Emerald Surface[cite: 1]
		Outline  = Color3.fromRGB(183, 229, 186), -- #B7E5BA Mint Highlight[cite: 1]
		Accent   = Color3.fromRGB(92, 168, 124),  -- #5CA87C Sage Border[cite: 1]
		Selected = Color3.fromRGB(183, 229, 186), -- #B7E5BA Soft Mint[cite: 1]
		Text     = Color3.fromRGB(235, 248, 237), -- #EBF8ED Crisp Mint White[cite: 1]
	},

	AbyssalSlate = {
		MainBG   = Color3.fromRGB(6, 20, 27),     -- #06141B Obsidian Navy[cite: 2]
		BoxFill  = Color3.fromRGB(17, 33, 45),    -- #11212D Midnight Slate[cite: 2]
		Outline  = Color3.fromRGB(155, 168, 171), -- #9BA8AB Mist Grey[cite: 2]
		Accent   = Color3.fromRGB(37, 55, 69),    -- #253745 Deep Steel[cite: 2]
		Selected = Color3.fromRGB(74, 92, 106),   -- #4A5C6A Storm Blue[cite: 2]
		Text     = Color3.fromRGB(204, 208, 207), -- #CCD0CF Pale Silver[cite: 2]
	},

	VelvetPlum = {
		MainBG   = Color3.fromRGB(0, 3, 14),      -- #00030E Void Night[cite: 3]
		BoxFill  = Color3.fromRGB(11, 14, 26),    -- #0B0E1A Midnight Indigo[cite: 3]
		Outline  = Color3.fromRGB(180, 122, 154), -- #B47A9A Dusty Rose[cite: 3]
		Accent   = Color3.fromRGB(44, 27, 47),    -- #2C1B2F Dark Aubergine[cite: 3]
		Selected = Color3.fromRGB(94, 58, 92),    -- #5E3A5C Muted Plum[cite: 3]
		Text     = Color3.fromRGB(243, 233, 236), -- #F3E9EC Soft Blush White[cite: 3]
	},

	AutumnTimber = {
		MainBG   = Color3.fromRGB(19, 25, 31),    -- #13191F River Styx[cite: 4]
		BoxFill  = Color3.fromRGB(43, 47, 46),    -- #2B2F2E Carbon Fibre[cite: 4]
		Outline  = Color3.fromRGB(202, 156, 104), -- #CA9C68 Amber Autumn[cite: 4]
		Accent   = Color3.fromRGB(89, 76, 61),    -- #594C3D Afternoon Tea[cite: 4]
		Selected = Color3.fromRGB(144, 109, 75),  -- #906D4B Tanned Wood[cite: 4]
		Text     = Color3.fromRGB(238, 224, 206), -- #EEE0CE Warm Parchment[cite: 4]
	},

	EspressoCrema = {
		MainBG   = Color3.fromRGB(47, 41, 39),    -- #2F2927 Noir[cite: 5]
		BoxFill  = Color3.fromRGB(106, 83, 73),   -- #6A5349 Bargeboard Brown[cite: 5]
		Outline  = Color3.fromRGB(216, 186, 166), -- #D8BAA6 Maiko[cite: 5]
		Accent   = Color3.fromRGB(143, 119, 106), -- #8F776A Chocolate Heart[cite: 5]
		Selected = Color3.fromRGB(183, 158, 139), -- #B79E8B Midtown[cite: 5]
		Text     = Color3.fromRGB(245, 236, 229), -- #F5ECE5 Warm Cream[cite: 5]
	},
	
	WinterPine = {
		MainBG   = Color3.fromRGB(39, 54, 63),    -- #27363F Pine[cite: 6]
		BoxFill  = Color3.fromRGB(104, 86, 82),   -- #685652 Branch[cite: 6]
		Outline  = Color3.fromRGB(142, 161, 174), -- #8EA1AE Mist[cite: 6]
		Accent   = Color3.fromRGB(190, 179, 172), -- #BEB3AC Frosty Silver[cite: 6]
		Selected = Color3.fromRGB(107, 33, 44),   -- #6B212C Berry[cite: 6]
		Text     = Color3.fromRGB(220, 224, 232), -- #DCE0E8 Snowflake[cite: 6]
	},

	NavyCream = {
		MainBG   = Color3.fromRGB(17, 50, 77),    -- #11324D Deep Navy[cite: 7]
		BoxFill  = Color3.fromRGB(38, 76, 108), --   #264C6C  Elevated Navy
		Outline  = Color3.fromRGB(193, 207, 192), -- #C1CFC0 Sage Mist[cite: 7]
		Accent   = Color3.fromRGB(231, 224, 201), -- #E7E0C9 Warm Sand[cite: 7]
		Selected = Color3.fromRGB(107, 122, 161), -- #6B7AA1  Slate Periwinkle
		Text     = Color3.fromRGB(247, 244, 235), -- #F7F4EB Cream White[cite: 7]
	},

	RosewoodDawn = {
		MainBG   = Color3.fromRGB(82, 88, 113),   -- #525871 Concrete[cite: 8]
		BoxFill  = Color3.fromRGB(133, 124, 145), -- #857C91 Warm Steel[cite: 8]
		Outline  = Color3.fromRGB(248, 204, 170), -- #F8CCAA Dawn[cite: 8]
		Accent   = Color3.fromRGB(205, 159, 160), -- #CD9FA0 Rosewood[cite: 8]
		Selected = Color3.fromRGB(242, 193, 163), -- #F2C1A3 Peaches & Cream[cite: 8]
		Text     = Color3.fromRGB(248, 204, 170), -- #F8CCAA Soft Peach[cite: 8]
	},

	ChaosPeach = {
		MainBG   = Color3.fromRGB(17, 15, 14),    -- #110F0E Chaos Black[cite: 9]
		BoxFill  = Color3.fromRGB(41, 34, 34),    -- #292222 Gold Black[cite: 9]
		Outline  = Color3.fromRGB(253, 227, 172), -- #FDE3AC Pale Peach[cite: 9]
		Accent   = Color3.fromRGB(74, 61, 58),    -- #4A3D3A Dobunezumi Brown[cite: 9]
		Selected = Color3.fromRGB(156, 120, 106), -- #9C786A Woodhaven[cite: 9]
		Text     = Color3.fromRGB(253, 227, 172), -- #FDE3AC Warm Peach[cite: 9]
	},
}



local theme_instances = setmetatable({}, { __mode = "k" })

local function register_theme_instance(instance)
	theme_instances[instance] = true
end

local function refresh_theme(instance)
	local theme = Themes[instance.theme]
	if not theme or instance._applied_theme == instance.theme then
		return
	end

	instance._applied_theme = instance.theme


	if instance.color ~= nil then instance.color = theme.BoxFill end
	if instance.outline_color ~= nil then instance.outline_color = theme.Outline end
	if instance.activated_color ~= nil then instance.activated_color = theme.Selected end
	if instance.selected_color ~= nil then instance.selected_color = theme.Selected end
	if instance.text_color ~= nil then instance.text_color = theme.Text end
	if instance.color_box ~= nil then instance.color_box = theme.BoxFill end
	if instance.color_text ~= nil then instance.color_text = theme.Text end
	if instance.og_col ~= nil then instance.og_col = theme.BoxFill end

	local function update_child(child)
		if type(child) == "table" and child.theme ~= nil then
			child.theme = instance.theme
			child._applied_theme = nil
		end
	end

	update_child(instance.rect)
	update_child(instance.textbox)
	if instance.rects then
		for _, child in ipairs(instance.rects) do
			update_child(child)
		end
	end
end


--extra
local pl = game.Players
local lp = pl.LocalPlayer
local lp_name = lp.Name

--Classes

local Rectangle = {}
Rectangle.__index = Rectangle

function Rectangle.new(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, main_window, title: string?, slider: boolean?)
	local self = setmetatable({}, Rectangle)
	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.roundness = roundness
	self.thickness = thickness
	self.main_window = main_window
	self.expand = size / 5
	self.title = title
	self.draggable = false
	self.animated = false
	self.anim_started = false
	self.resized = false
	self.slider = slider or false
	if self.main_window then
		self.draggable = true
	else
		self.draggable = false
		children[self] = true
	end

	return self
end

function Rectangle:Draw()
	refresh_theme(self)
	if self.main_window and not self.resized then 
		self.size += Vector2.new(50, 0) 
		self.resized = true
	end
	if self.main_window and not self.anim_started then
		self.anim_started = true
		local og_size = self.size
		local start_size = Vector2.new(50, 50)
		pop(og_size, self, 0.5, start_size, function()
			self.animated = true
		end)
		self.size = start_size
		self.position = self.position + (og_size - start_size) / 2
	end

	--variables
	local size = self.size
	local position = self.position

	local fill_col = self.color or self.main_window and Themes[self.theme].MainBG or Themes[self.theme].BoxFill
	if self.slider then
		fill_col = Themes[self.theme].Selected
	end
	local outline_col = self.outline_color or Themes[self.theme].Outline
	local text_col = self.text_color or Themes[self.theme].Text
	local accent_col = Themes[self.theme].Accent

	--filled rectangle
	if self.filled then
		DrawingImmediate.FilledRectangle(position, size, fill_col, self.opacity, self.roundness)
		if self.outlined then
			DrawingImmediate.Rectangle(position, size, outline_col, self.opacity, self.roundness, self.thickness)
		end
	else
		DrawingImmediate.Rectangle(position, size, outline_col, self.opacity, self.roundness, self.thickness)
	end
	local expand = self.expand.X
	if self.title then
		DrawingImmediate.FilledRectangle(position + Vector2.new(10, 35), Vector2.new(size.X - 20, self.thickness), accent_col, self.opacity)
		DrawingImmediate.Text(position + Vector2.new(15 + expand, 10), 25, text_col, 1, self.title, false, "Nunito")
	end
	if self.main_window and self.resized then
		--divider
		local from = position + Vector2.new(expand, 10)
		local to = position + Vector2.new(expand, self.size.Y - 10)

		DrawingImmediate.Line(from, to, accent_col, self.opacity, self.thickness, 1)
		local cat_center = position + Vector2.new(expand / 2, 18)
		draw_cat(cat_center, 14, outline_col, self.opacity, 2)
	end
end


local TextBox = {}
TextBox.__index = TextBox

function TextBox.new(size_text, size_box, position: Vector2, opacity_box, opacity_text, filled, outlined, outlined_text, roundness, thickness, theme: string, text, centered: boolean?)
	local self = setmetatable({}, TextBox)

	self.size_text = size_text
	self.size_box = DrawingImmediate.GetTextBounds("Nunito", self.size_text, text)
	self.size = size_box
	self.position = position
	self.opacity_box = opacity_box
	self.opacity_text = opacity_text
	self.filled = filled
	self.outlined = outlined
	self.roundness = roundness
	self.thickness = thickness
	self.outlined_text = outlined_text
	self.theme = theme
	register_theme_instance(self)
	self.color_box = Themes[self.theme].BoxFill
	self.outline_color = Themes[self.theme].Outline
	self.color_text = Themes[self.theme].Text
	self.text = text
	self.rect = Rectangle.new(
		self.size_box,
		self.position,
		self.opacity_box,
		self.filled,
		self.outlined,
		self.theme,
		self.roundness,
		self.thickness,
		false
	)
	self.centered = centered or false
	children[self.rect] = nil
	children[self] = true
	return self
end

function TextBox:Draw()
	refresh_theme(self)
	self.rect.position = self.position
	self.rect.size = self.size
	self.rect.opacity = self.opacity_box
	self.rect.color = self.color_box
	self.rect.outline_color = self.outline_color
	self.rect:Draw(1)
	local text_pos = self.position + Vector2.new(10, 4)
	if self.centered then 
		text_pos = self.position + Vector2.new(self.size.X / 2, self.size.Y / 2 - self.size_text / 2)
	end
	if self.outlined_text then
		DrawingImmediate.OutlinedText(text_pos, self.size_text, self.color_text, self.opacity_text, self.text, false, "Nunito")
	else
		DrawingImmediate.Text(text_pos, self.size_text, self.color_text, self.opacity_text, self.text, self.centered, "Nunito")
	end
end


local Button = {}
Button.__index = Button

function Button.new(size, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, callback: (() -> ())?, text: string?, centered: boolean?)
	local self = setmetatable({}, Button)


	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.color = Themes[self.theme].BoxFill
	self.outline_color = Themes[self.theme].Outline
	self.callback = callback
	self.roundness = roundness
	self.thickness = thickness
	self.rect = nil
	self.textbox = nil
	self.activated_color = Themes[self.theme].Selected
	self.hovering = false
	self.activated = false
	self.text = text
	self.centered = centered or false
	children[self] = true
	return self
end

function Button:Draw()
	refresh_theme(self)
	if not self.rect then
		self.rect = Rectangle.new(
			self.size,
			self.position,
			self.opacity,
			self.filled,
			self.outlined,
			self.theme,
			self.roundness,
			self.thickness,
			false
		)
	end
	if not self.textbox then
		self.textbox = TextBox.new(
			self.size.Y - 5,
			self.size, 
			self.position,
			0,
			self.opacity,
			self.filled,
			self.outlined,
			false,
			self.roundness,
			self.thickness,
			self.theme,
			self.text,
			self.centered
		)
	end
	self.rect:Draw(1)
	self.textbox:Draw()
end
function Button:Clicked(pressed)
	local mpos = userinput:GetMouseLocation()

	local pos = self.position
	local size = self.size
	local col = self.color

	local x_dist = mpos.X - pos.X
	local y_dist = mpos.Y - pos.Y

	self.hovering =
		x_dist >= 0 and y_dist >= 0
		and x_dist <= size.X and y_dist <= size.Y

	if pressed and self.hovering then
		if not self.activated then
			self.activated = true
		else
			self.activated = false
		end

		if self.callback then
			self.callback()
		end

		bounce(self.rect, 0.15, 1.15)
	end

	if self.hovering then
		local h, s, v = col:ToHSV()
		local offset = v > 0.5 and -0.15 or 0.15

		self.rect.color = Color3.fromHSV(
			h, s, math.clamp(v + offset, 0, 1)
		)
	else
		self.rect.color = col
	end
end
local Tabs = {}
Tabs.__index = Tabs
Tabs.list = {}
Tabs.active = 1

local Tab = {}
Tab.__index = Tab

function Tab.new(name: string, index: number, size: Vector2)
	local self = setmetatable({}, Tab)
	self.name = name
	self.index = index
	self.size = size
	self.button = nil
	self.instances = {}

	table.insert(Tabs.list, self)
	return self
end

function Tab:Register(main_window)
	local position = main_window.position
	local sidebar_start = position + Vector2.new(10, 45)
	local padding = 6
	local section = sidebar_start + Vector2.new(0, (self.size.Y + padding) * (self.index - 1))

	if not self.button then
		self.button = Button.new(
			self.size,
			section,
			main_window.opacity,
			false,
			true,
			main_window.theme,
			main_window.roundness,
			main_window.thickness,
			function()
				Tabs.active = self.index
			end,
			self.name,
			true
		)
	end
end

function Tab:Add(instance)
	table.insert(self.instances, instance)
end

function Tabs:Proccess()
	for _, tab in ipairs(Tabs.list) do
		if tab.index == Tabs.active then
			for _, child in ipairs(tab.instances) do
				if child.Check then
					child:Check()
				end
			end
		end
	end
end
function Tabs:Draw(pressed: boolean, is_pressed: boolean)
	for _, tab in ipairs(Tabs.list) do
		if tab.button then
			tab.button:Draw()
			tab.button:Clicked(pressed)
		end

		if tab.index == Tabs.active then
			for _, child in ipairs(tab.instances) do
				child:Draw()

				if child.Clicked then
					child:Clicked(pressed)
				end

				if child.Dropped then
					child:Dropped(pressed)
				end

				if child.Update then
					child:Update(pressed, is_pressed)
				end

				if child.Set then
					child:Set()
				end
			end
		end
	end
end



local Checkbox = {}
Checkbox.__index = Checkbox
function Checkbox.new(size, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, callback: (() -> ())?)
	local self = setmetatable({}, Checkbox)

	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.color = Themes[self.theme].BoxFill
	self.outline_color = Themes[self.theme].Outline
	self.callback = callback
	self.roundness = roundness
	self.thickness = thickness
	self.rect = nil
	self.activated_color = Themes[self.theme].Selected
	self.hovering = false
	self.activated = false
	self.state = false
	children[self] = true
	return self
end
function Checkbox:Draw()
	refresh_theme(self)
	if not self.rect then
		self.rect = Rectangle.new(
			self.size,
			self.position,
			self.opacity,
			self.filled,
			self.outlined,
			self.theme,
			self.roundness,
			self.thickness,
			false
		)
	end
	self.rect:Draw(1)
end

function Checkbox:Clicked(pressed)
	local mpos = userinput:GetMouseLocation()

	local pos = self.position
	local size = self.size
	local col = self.color

	local x_dist = mpos.X - pos.X
	local y_dist = mpos.Y - pos.Y

	self.hovering =
		x_dist >= 0 and y_dist >= 0
		and x_dist <= size.X and y_dist <= size.Y

	if pressed and self.hovering then
		if not self.activated then
			self.activated = true
			self.state = true
			self.callback(self.state)
		else
			self.activated = false
			self.state = false
			self.callback(self.state)
		end
		bounce(self.rect, 0.1, 1.1)


	end
	if self.activated then
		self.rect.color = self.activated_color
	elseif self.hovering then
		local h, s, v = col:ToHSV()
		local offset = v > 0.5 and -0.15 or 0.15

		self.rect.color = Color3.fromHSV(
			h, s, math.clamp(v + offset, 0, 1)
		)
	else
		self.rect.color = col
	end
end
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(data: {string}, size, position, opacity, filled, outlined, theme: string, roundness, thickness, max)
	local self = setmetatable({}, Dropdown)

	self.data = data
	self.size = size
	self.position = position
	self.last_header_pos = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.color = Themes[self.theme].BoxFill
	self.outline_color = Themes[self.theme].Outline
	self.roundness = roundness
	self.thickness = thickness
	self.selected_color = Themes[self.theme].Selected
	self.text_color = Themes[self.theme].Text
	self.hovering = false
	self.dropped = false
	if not max then
		self.max = #data
	else
		self.max = max
	end
	self.rects = {}
	self.in_position = {}
	self.chosen = {}
	self.og_col = Themes[self.theme].BoxFill
	children[self] = true
	return self
end

function Dropdown:Draw()
	refresh_theme(self)
	local amount_of_options = #self.data
	if #self.rects ~= amount_of_options then
		for i = 1, amount_of_options do
			local item_opacity = (i == 1) and self.opacity or 0
			self.rects[i] = TextBox.new(
				self.size.Y - 10,
				self.size,
				self.position,
				item_opacity,
				item_opacity,
				true,
				self.outlined,
				false,
				self.roundness,
				self.thickness,
				self.theme,
				tostring(self.data[i])
			)
			if i > 1 then
				children[self.rects[i]] = nil
			end
		end
		self.last_header_pos = self.position
	end
	local current_header_pos = self.rects[1].position
	if self.last_header_pos and current_header_pos ~= self.last_header_pos then
		local delta = current_header_pos - self.last_header_pos
		for i = 2, amount_of_options do
			self.rects[i].position += delta
			for _, anim in ipairs(animations) do
				if anim.instance == self.rects[i] and anim.property == "position" then
					anim.start += delta
					anim.target += delta
				end
			end
		end
	end
	self.last_header_pos = current_header_pos
	for i = amount_of_options, 1, -1 do
		local box = self.rects[i]
		
		if i > 1 and not self.dropped and vector.magnitude(box.position - self.rects[1].position) < 1 then
			box.opacity_box = 0
			box.opacity_text = 0
		end

		if box.opacity_box > 0 or box.opacity_text > 0 then
			box:Draw()
		end
	end

	local from_1 = Vector2.new(self.last_header_pos.X + self.size.X - 20, self.last_header_pos.Y + self.size.Y / 2 - 5)
	local to_1 = Vector2.new(self.last_header_pos.X + self.size.X - 15, self.last_header_pos.Y + self.size.Y / 2)
	local to_2 = Vector2.new(self.last_header_pos.X + self.size.X - 10, self.last_header_pos.Y + self.size.Y / 2 - 5)
	DrawingImmediate.Line(from_1, to_1, self.outline_color, self.opacity, 3, 3)
	DrawingImmediate.Line(to_1, to_2, self.outline_color, self.opacity, 3, 3)

end

function Dropdown:Dropped(pressed)
	local mpos = userinput:GetMouseLocation()
	local base_pos = self.rects[1].position

	for i = 1, #self.rects do
		local box = self.rects[i]
		local pos = box.position
		local size = self.size

		local hovering =
			mpos.X >= pos.X and mpos.Y >= pos.Y
			and mpos.X <= (pos.X + size.X) and mpos.Y <= (pos.Y + size.Y)

		local target_pos = base_pos + Vector2.new(0, self.size.Y * (i - 1))

		if i == 1 then
			self.hovering = hovering
			if pressed and hovering then
				self.dropped = not self.dropped

				for j = 2, #self.rects do
					local row = self.rects[j]
					local row_target = base_pos + Vector2.new(0, self.size.Y * (j - 1))
					if self.dropped then
						row.opacity_box = self.opacity
						row.opacity_text = self.opacity
						linear(row.position, row_target, row, 0.15)
					else
						linear(row.position, base_pos, row, 0.15)
					end
				end
			end
		elseif self.dropped and vector.magnitude(pos - target_pos) < 1 then
			if hovering and pressed then
				local found_index = table.find(self.chosen, self.data[i])
				local tablesize = table_size(self.chosen)
				if found_index then
					table.remove(self.chosen, found_index)
					box.selected = false
					box.color_box = self.og_col

				elseif tablesize < self.max then
					table.insert(self.chosen, self.data[i])
					box.selected = true
				end
			end
		end

		if box.selected then
			box.color_box = self.selected_color
		elseif hovering and (i == 1 or self.dropped) then
			local h, s, v = self.og_col:ToHSV()
			local offset = v > 0.5 and -0.15 or 0.15
			box.color_box = Color3.fromHSV(h, s, math.clamp(v + offset, 0, 1))
		else
			box.color_box = self.og_col
		end
	end

	return self.chosen
end

local Slider = {}
Slider.__index = Slider
--(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, main_window, title: string?)
function Slider.new(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, min, max, value)
	local self = setmetatable({}, Slider)
	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.roundness = roundness
	self.thickness = thickness
	self.min = min
	self.max = max
	self.delta = max - min
	self.value = math.clamp(value or min, min, max)

	self.rect = Rectangle.new(
		size,
		position,
		opacity,
		filled,
		outlined,
		theme,
		roundness,
		thickness,
		false
	)
	self.fill_rect = Rectangle.new(
		size,
		position,
		opacity,
		filled,
		outlined,
		theme,
		roundness,
		thickness,
		false,
		_,
		Themes[theme].Accent
	)
	children[self.rect] = nil
	children[self.fill_rect] = nil
	children[self] = true

	self.rects = {}
	if self.delta > 0 then
		local width = self.size.X / self.delta
		for i = 0, math.floor(self.delta) - 1 do
			local seg_pos = Vector2.new(self.position.X + (width * i), self.position.Y)
			local seg_size = Vector2.new(width, self.size.Y)
			self.rects[i + 1] = Rectangle.new(
				seg_size,
				seg_pos,
				0,
				false,
				false,
				"Monochrome",
				self.roundness,
				self.thickness,
				false
			)
			children[self.rects[i + 1]] = nil
		end
	end

	return self
end

function Slider:SetValue(new_value: number)
	self.value = math.clamp(new_value, self.min, self.max)
end

function Slider:GetKnobInfo(): (Vector2, number)
	local ratio = if self.delta > 0
		then math.clamp((self.value - self.min) / self.delta, 0, 1)
		else 0

	local knob_position = Vector2.new(
		self.position.X + (self.size.X * ratio),
		self.position.Y + (self.size.Y / 2)
	)
	local knob_radius = self.size.Y + 3

	return knob_position, knob_radius
end

function Slider:Update(pressed: boolean, is_held: boolean, on_change: ((number) -> ())?)
	local mpos = userinput:GetMouseLocation()
	local knob_position, knob_radius = self:GetKnobInfo()
	if pressed then
		local dist = vector.magnitude(mpos - knob_position)
		if dist <= knob_radius + 2 then
			self.dragging = true
		end
	end

	if not is_held then
		self.dragging = false
	end

	if self.dragging and is_held and self.size.X > 0 then
		DrawingImmediate.FilledCircle(knob_position, knob_radius + 9, Themes[self.theme].Outline, 0.3, 99)
		local ratio = math.clamp((mpos.X - self.position.X) / self.size.X, 0, 1)
		local new_value = self.min + (ratio * self.delta)
		local prev_value = self.value
		self:SetValue(new_value)

		if on_change and self.value ~= prev_value then
			on_change(self.value)
		end
	end
end

function Slider:Draw()
	refresh_theme(self)
	local knob_position, _ = self:GetKnobInfo()
	self.rect.position = self.position
	local dist = vector.magnitude(knob_position - self.rect.position)
	self.fill_rect.position = self.position
	self.rect:Draw()
	self.fill_rect.size = Vector2.new(dist, self.size.Y)
	self.fill_rect:Draw()

	for _, segment in ipairs(self.rects) do
		segment:Draw()
	end

	local knob_position, knob_radius = self:GetKnobInfo()

	DrawingImmediate.FilledCircle(
		knob_position,
		knob_radius,
		Themes[self.theme].Outline,
		self.opacity,
		99
	)
end

local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(text_size, size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, start_key: string?)
	local self = setmetatable({}, Keybind)
	self.size = size
	self.text_size = text_size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	register_theme_instance(self)
	self.roundness = roundness
	self.thickness = thickness
	self.start_key = start_key
	self.current_key = start_key or "Not Set"
	self.clicked = false
	self.hovering = false
	self.activated = false
	self.rect = Rectangle.new(
		self.size,
		self.position,
		self.opacity,
		self.filled,
		self.outlined,
		self.theme,
		self.roundness,
		self.thickness,
		false
	)
	--(size_text, size_box, position: Vector2, opacity_box, opacity_text, filled, outlined, outlined_text, roundness, thickness, theme: string, text)
	self.textbox = TextBox.new(
		self.text_size,
		self.size,
		self.position,
		self.opacity,
		self.opacity,
		self.filled,
		self.outlined,
		false,
		self.roundness,
		self.thickness,
		self.theme,
		self.current_key,
		true
	)
	self.was_pressed = false
	children[self.rect] = true
	children[self.textbox] = true
	return self
end

function Keybind:Draw()
	refresh_theme(self)
	if self.clicked then
		self.current_key = ""
		DrawingImmediate.Line(self.rect.position + Vector2.new(8, self.size.Y - 5), self.rect.position + Vector2.new(self.size.X - 8, self.size.Y - 5), Themes[self.theme].Accent, self.opacity, self.thickness, self.thickness)
	end
	self.textbox.text = self.current_key
	self.rect:Draw()
	self.textbox:Draw()
end

function Keybind:Clicked(pressed)
    local mpos = userinput:GetMouseLocation()

    local pos = self.rect.position
    local size = self.size

    local x_dist = mpos.X - pos.X
    local y_dist = mpos.Y - pos.Y

    self.hovering =
        x_dist >= 0 and y_dist >= 0
        and x_dist <= size.X and y_dist <= size.Y

    if pressed and self.hovering then
        self.clicked = not self.clicked
        bounce(self.rect, 0.1, 1.1)
		bounce(self.textbox, 0.1, 1.1)
    end
end

function Keybind:Set()
    if not self.clicked then return end

    if isleftpressed() then return end

    local keys = getpressedkeys()

    for _, key in ipairs(keys) do
        if key then
            local key_name = tostring(key)

            if key_name ~= "M1" and key_name ~= "MouseButton1" then
                self.current_key = key_name
                self.start_key = key_name
                self.clicked = false
                break
            end
        end
    end
end

function Keybind:Check()
    local key = self.current_key
    local pressed = table.find(getpressedkeys(), key) ~= nil

    self.activated = pressed and not self.was_activated
    self.was_activated = pressed
end
--main

function hide(hide_key: string)
	local keys = getpressedkeys()
	for _, key in pairs(keys) do
		if key == hide_key then
			return true
		else
		end
	end
	return false
end


ui.Keybind = Keybind
ui.Slider = Slider
ui.Dropdown = Dropdown
ui.Tabs = Tabs
ui.Tab = Tab
ui.Rectangle = Rectangle
ui.Button = Button
ui.Checkbox = Checkbox
ui.drag = drag
ui.hide = hide
ui.TextBox = TextBox
ui.linear = linear
ui.slide_up = slide_up
ui.update_animations = update_animations
ui.bounce = bounce
ui.pop = pop
ui.Themes = Themes

function ui.SetTheme(theme: string): boolean
	if not Themes[theme] then
		return false
	end

	for instance in pairs(theme_instances) do
		instance.theme = theme
		instance._applied_theme = nil
	end

	return true
end
local version = game.GetClientVersion()
local theo = game:HttpGet("https://offsets.imtheo.lol/" .. version .. "/offsets.json")
local decoded = crypt.json.decode(theo).Offsets
local uis = decoded.UserInputService
local input_state = uis.WindowInputState
local current_textbox = decoded.WindowInputState.CurrentTextBox


function ui.Typing()
	local windowinput = memory.readu64(userinput, input_state)
	local current_text = memory.readu64(windowinput, current_textbox)
	if current_text ~= 0 then 
		return true
	end
	return false
end
return ui
