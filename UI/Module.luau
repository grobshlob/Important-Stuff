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


local userinput = game:GetService("UserInputService")

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
ui.drag = drag
ui.linear = linear
ui.pop = pop
ui.bounce = bounce
ui.slide_up = slide_up
ui.update_animations = update_animations


--themes

local Themes = {
	Catppuccin = {
		MainBG   = Color3.fromRGB(24, 24, 37),--    #181825 Mantle Dark
		BoxFill  = Color3.fromRGB(49, 50, 68),--    #313244 Surface0
		Outline  = Color3.fromRGB(137, 180, 250),-- #89B4FA Soft Sapphire
		Accent   = Color3.fromRGB(69, 71, 90),--    #45475A Subtle Border
		Selected = Color3.fromRGB(203, 166, 247),-- #CBA6F7 Mauve Highlight
		Text     = Color3.fromRGB(205, 214, 244),-- #CDD6F4 Crisp Soft White
	},

	Emerald_Glass = {
		MainBG   = Color3.fromRGB(14, 20, 18),--    #0E1412 Deep Forest Charcoal
		BoxFill  = Color3.fromRGB(24, 34, 30),--    #18221E Card Surface
		Outline  = Color3.fromRGB(16, 185, 129),--  #10B981 Modern Emerald
		Accent   = Color3.fromRGB(39, 54, 48),--    #273630 Muted Sage Border
		Selected = Color3.fromRGB(5, 150, 105),--   #059669 Active Emerald
		Text     = Color3.fromRGB(236, 253, 245),-- #ECFDF5 Mint White
	},

	Royal_Gold = {
		MainBG   = Color3.fromRGB(15, 14, 13),--    #0F0E0D Obsidian Black
		BoxFill  = Color3.fromRGB(28, 26, 23),--    #1C1A17 Warm Charcoal
		Outline  = Color3.fromRGB(234, 179, 8),--   #EAB308 Rich Gold
		Accent   = Color3.fromRGB(54, 49, 41),--    #363129 Muted Bronze
		Selected = Color3.fromRGB(202, 138, 4),--   #CA8A04 Deep Amber Gold
		Text     = Color3.fromRGB(250, 245, 235),-- #FAF5EB Ivory White
	},

	Rose_Pine = {
		MainBG   = Color3.fromRGB(25, 23, 36),--    #191724 Base
		BoxFill  = Color3.fromRGB(38, 35, 58),--    #26233A Overlay
		Outline  = Color3.fromRGB(235, 188, 186),-- #EBBCBA Rose
		Accent   = Color3.fromRGB(64, 61, 82),--    #403D52 Highlight Med
		Selected = Color3.fromRGB(235, 111, 146),-- #EB6F92 Love Pink
		Text     = Color3.fromRGB(224, 222, 244),-- #E0DEF4 Soft White
	},

	Gruvbox_Dark = {
		MainBG   = Color3.fromRGB(29, 32, 33),--    #1D2021 Hard Dark
		BoxFill  = Color3.fromRGB(50, 48, 47),--    #32302F Warm Stone
		Outline  = Color3.fromRGB(254, 128, 25),--  #FE8019 Warm Orange
		Accent   = Color3.fromRGB(80, 73, 69),--    #504945 Muted Brown-Grey
		Selected = Color3.fromRGB(142, 192, 124),-- #8EC07C Sage Aqua
		Text     = Color3.fromRGB(235, 219, 178),-- #EBDBB2 Cream Text
	},

	Crimson_Carbon = {
		MainBG   = Color3.fromRGB(16, 16, 18),--    #101012 Carbon Black
		BoxFill  = Color3.fromRGB(28, 28, 32),--    #1C1C20 Dark Gunmetal
		Outline  = Color3.fromRGB(239, 68, 68),--   #EF4444 Modern Crimson
		Accent   = Color3.fromRGB(52, 52, 60),--    #34343C Steel Border
		Selected = Color3.fromRGB(220, 38, 38),--   #DC2626 Active Red
		Text     = Color3.fromRGB(244, 244, 245),-- #F4F4F5 Clean Off-White
	},

	Phantom_Violet = {
		MainBG   = Color3.fromRGB(17, 13, 23),--    #110D17 Deep Plum Black
		BoxFill  = Color3.fromRGB(30, 23, 41),--    #1E1729 Dark Violet
		Outline  = Color3.fromRGB(168, 85, 247),--  #A855F7 Electric Purple
		Accent   = Color3.fromRGB(52, 40, 71),--    #342847 Muted Plum
		Selected = Color3.fromRGB(147, 51, 234),--  #9333EA Vivid Violet
		Text     = Color3.fromRGB(243, 232, 255),-- #F3E8FF Soft Lavender White
	},

	Monochrome = {
		MainBG   = Color3.fromRGB(14, 14, 14),--    #0E0E0E Matte Black
		BoxFill  = Color3.fromRGB(28, 28, 28),--    #1C1C1C Dark Grey
		Outline  = Color3.fromRGB(212, 212, 212),-- #D4D4D4 Silver White
		Accent   = Color3.fromRGB(56, 56, 56),--    #383838 Neutral Grey
		Selected = Color3.fromRGB(115, 115, 115),-- #737373 Slate Highlight
		Text     = Color3.fromRGB(245, 245, 245),-- #F5F5F5 Pure Off-White
	},

	Toxic_Lime = {
		MainBG   = Color3.fromRGB(13, 16, 13),--    #0D100D Pitch Moss
		BoxFill  = Color3.fromRGB(23, 29, 23),--    #171D17 Dark Olive Slate
		Outline  = Color3.fromRGB(132, 204, 22),--  #84CC16 Acid Lime
		Accent   = Color3.fromRGB(43, 54, 43),--    #2B362B Muted Forest
		Selected = Color3.fromRGB(101, 163, 13),--  #65A30D Active Lime
		Text     = Color3.fromRGB(247, 254, 231),-- #F7FEE7 Crisp Lime White
	},

	Frost_Light = {
		MainBG   = Color3.fromRGB(244, 245, 248),-- #F4F5F8 Soft Cool Grey
		BoxFill  = Color3.fromRGB(255, 255, 255),-- #FFFFFF Pure Card White
		Outline  = Color3.fromRGB(59, 130, 246),--  #3B82F6 Crisp Royal Blue
		Accent   = Color3.fromRGB(209, 213, 219),-- #D1D5DB Subtle Divider
		Selected = Color3.fromRGB(37, 99, 235),--   #2563EB Active Blue
		Text     = Color3.fromRGB(17, 24, 39),--    #111827 Deep Charcoal Text
	},
}
ui.Themes = Themes
--extra
local pl = game.Players
local lp = pl.LocalPlayer
local lp_name = lp.Name

--Classes

local Rectangle = {}
Rectangle.__index = Rectangle
ui.Rectangle = Rectangle
function Rectangle.new(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, main_window, title: string?)
	local self = setmetatable({}, Rectangle)
	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	self.roundness = roundness
	self.thickness = thickness
	self.main_window = main_window
	self.expand = size / 5
	self.title = title
	self.draggable = false
	self.animated = false
	self.anim_started = false
	self.resized = false
	if self.main_window then
		self.draggable = true
	else
		self.draggable = false
		children[self] = true
	end

	return self
end

function Rectangle:Draw()
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
	local t = Themes[self.theme] or Themes.Catppuccin

	local fill_col = self.color or (self.main_window and t.MainBG or t.BoxFill)
	local outline_col = self.outline_color or t.Outline
	local text_col = self.text_color or t.Text
	local accent_col = t.Accent

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
		local middle = position + Vector2.new(expand / 2, 7.5)
		DrawingImmediate.Line(from, to, accent_col, self.opacity, self.thickness, 1)
		DrawingImmediate.Text(middle, 25, text_col, 1, lp_name, true, "Nunito")
	end
end


local TextBox = {}
TextBox.__index = TextBox
ui.TextBox = TextBox
function TextBox.new(size_text, size_box, position: Vector2, opacity_box, opacity_text, filled, outlined, outlined_text, roundness, thickness, theme: string, text)
	local self = setmetatable({}, TextBox)
	local t = Themes[theme]

	self.size_text = size_text
	self.size_box = size_box
	self.position = position
	self.opacity_box = opacity_box
	self.opacity_text = opacity_text
	self.filled = filled
	self.outlined = outlined
	self.roundness = roundness
	self.thickness = thickness
	self.outlined_text = outlined_text
	self.theme = theme
	self.color_box = t.BoxFill
	self.outline_color = t.Outline
	self.color_text = t.Text
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
	children[self.rect] = nil
	children[self] = true
	return self
end

function TextBox:Draw()
	self.rect.position = self.position
	self.rect.opacity = self.opacity_box
	self.rect.color = self.color_box
	self.rect.outline_color = self.outline_color
	self.rect:Draw(1)

	local text_pos = self.position + Vector2.new(8, 2)
	if self.outlined_text then
		DrawingImmediate.OutlinedText(text_pos, self.size_text, self.color_text, self.opacity_text, self.text, false, "Nunito")
	else
		DrawingImmediate.Text(text_pos, self.size_text, self.color_text, self.opacity_text, self.text, false, "Nunito")
	end
end


local Button = {}
Button.__index = Button
ui.Button = Button
function Button.new(size, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, callback: (() -> ())?)
	local self = setmetatable({}, Button)
	local t = Themes[theme] or Themes.Catppuccin

	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	self.color = t.BoxFill
	self.outline_color = t.Outline
	self.callback = callback
	self.roundness = roundness
	self.thickness = thickness
	self.rect = nil
	self.activated_color = t.Selected
	self.hovering = false
	self.activated = false
	return self
end

function Button:Draw()
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
	children[self] = true
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

local Checkbox = {}
Checkbox.__index = Checkbox
ui.Checkbox = Checkbox
function Checkbox.new(size, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, callback: (() -> ())?)
	local self = setmetatable({}, Checkbox)
	local t = Themes[theme] or Themes.Catppuccin

	self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	self.color = t.BoxFill
	self.outline_color = t.Outline
	self.callback = callback
	self.roundness = roundness
	self.thickness = thickness
	self.rect = nil
	self.activated_color = t.Selected
	self.hovering = false
	self.activated = false
	self.state = false
	return self
end
function Checkbox:Draw()
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
	children[self] = true
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
ui.Dropdown = Dropdown
function Dropdown.new(data: {string}, size, position, opacity, filled, outlined, theme: string, roundness, thickness)
	local self = setmetatable({}, Dropdown)
	local t = Themes[theme] or Themes.Catppuccin

	self.data = data
	self.size = size
	self.position = position
	self.last_header_pos = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
	self.color = t.BoxFill
	self.outline_color = t.Outline
	self.roundness = roundness
	self.thickness = thickness
	self.selected_color = t.Selected
	self.text_color = t.Text
	self.hovering = false
	self.dropped = false
	self.rects = {}
	self.in_position = {}
	self.chosen = {}
	self.og_col = t.BoxFill
	return self
end

function Dropdown:Draw()
	local amount_of_options = #self.data
	if #self.rects ~= amount_of_options then
		for i = 1, amount_of_options do
			local item_opacity = (i == 1) and 1 or 0
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
		local size = box.size_box

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
						row.opacity_box = 1
						row.opacity_text = 1
						linear(row.position, row_target, row, 0.15)
					else
						linear(row.position, base_pos, row, 0.15)
					end
				end
			end
		elseif self.dropped and vector.magnitude(pos - target_pos) < 1 then
			if hovering and pressed then
				local found_index = table.find(self.chosen, self.data[i])
				if not found_index then
					table.insert(self.chosen, self.data[i])
					box.selected = true
				else
					table.remove(self.chosen, found_index)
					box.selected = false
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
ui.Slider = Slider
--(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, main_window, title: string?)
function Slider.new(size: Vector2, position: Vector2, opacity, filled, outlined, theme: string, roundness, thickness, min, max, value)
	local self = setmetatable({}, Slider)
self.size = size
	self.position = position
	self.opacity = opacity
	self.filled = filled
	self.outlined = outlined
	self.theme = theme
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
	children[self.rect] = nil
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
	local t = Themes[self.theme]
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
		DrawingImmediate.FilledCircle(knob_position, knob_radius + 9, t.Outline, 0.3, 99)
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
	self.rect.position = self.position
	self.rect:Draw()

	local t = Themes[self.theme] or Themes.Catppuccin
	for _, segment in ipairs(self.rects) do
		segment:Draw()
	end

	local knob_position, knob_radius = self:GetKnobInfo()

	DrawingImmediate.FilledCircle(
		knob_position,
		knob_radius,
		t.Outline,
		self.opacity,
		99
	)
end

--main

function ui.hide(hide_key: string)
	local keys = getpressedkeys()
	for _, key in pairs(keys) do
		if key == hide_key then
			return true
		else
		end
	end
	return false
end



return ui
