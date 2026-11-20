# UI Library Documentation

An immediate-mode Luau UI library built on `DrawingImmediate`, featuring built-in theming, window dragging, animations, and modular UI components.

## Quick Start

Load the module, instantiate your components, and render them inside `RunService.Render`. Call `isleftclicked()` **once** per frame and pass `pressed` into interactive components so clicks aren't consumed early.

```
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/grobshlob/Important-Stuff/refs/heads/main/UI/Module.luau"))()
local RunService = game:GetService("RunService")

local window = ui.Rectangle.new(Vector2.new(600, 400), Vector2.new(500, 500), 1, true, true, "Monochrome", 15, 3, true, "My Hub")
local label = ui.TextBox.new(30, Vector2.new(200, 35), Vector2.new(640, 555), 1, 1, true, true, false, 10, 2, "Monochrome", "Status: Ready")
local dropdown = ui.Dropdown.new({"Options", "Option 1", "Option 2"}, Vector2.new(150, 45), Vector2.new(640, 660), 1, true, true, "Monochrome", 12, 2)

local button = ui.Button.new(Vector2.new(150, 40), Vector2.new(640, 605), 1, true, true, "Monochrome", 10, 2, function()
	print("Button clicked!")
end)

local checkbox = ui.Checkbox.new(Vector2.new(30, 30), Vector2.new(850, 605), 1, true, true, "Monochrome", 6, 2, function(state)
	print("Checkbox state:", state)
end)

local slider = ui.Slider.new(
	Vector2.new(200, 12),
	Vector2.new(640, 730),
	1,
	true,
	true,
	"Monochrome",
	6,
	2,
	0,
	100,
	50
)

local tab1 = ui.Tab.new("Main", 1, Vector2.new(100, 32))
local tab2 = ui.Tab.new("Visuals", 2, Vector2.new(100, 32))

tab1:Register(window)
tab2:Register(window)

tab1:Add(label)
tab1:Add(button)
tab1:Add(slider)

tab2:Add(checkbox)
tab2:Add(dropdown)

local hidden = false
local key_down = false

task.spawn(function()
	while task.wait(0.05) do
		local is_pressed = ui.hide("Ctrl")
		if is_pressed and not key_down then
			hidden = not hidden
		end
		key_down = is_pressed
	end
end)

local was_pressed = false

RunService.RenderUnrestricted:Connect(function(dt)
	if not hidden then
		local is_pressed = isleftpressed()
		local pressed = is_pressed and not was_pressed
		was_pressed = is_pressed

		window:Draw()
		ui.update_animations(dt)

		if window.animated then
			ui.Tabs:Draw(pressed, is_pressed)

			if window.draggable and not slider.dragging and not checkbox.hovering and not button.hovering and not dropdown.hovering then
				ui.drag(window)
			end
		end
	end
end)
```

## Themes

Access color palettes via `ui.Themes` or pass any theme name as a string to a component's `theme` parameter. Defaults to `"Catppuccin"` if an invalid name is provided.

**Available Themes:**

* `"Monochrome"`

* `"Catppuccin"`

* `"Emerald_Glass"`

* `"Royal_Gold"`

* `"Rose_Pine"`

* `"Gruvbox_Dark"`

* `"Crimson_Carbon"`

* `"Phantom_Violet"`

Each theme table contains six `Color3` keys: `MainBG`, `BoxFill`, `Outline`, `Accent`, `Selected`, and `Text`.

## Components

### Rectangle

Base container used for main windows and background panels. Any `Rectangle` created with `main_window = false` is automatically registered as a child and moves with the main window when dragged.

```
ui.Rectangle.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, main_window: boolean, title: string?)

```

| Parameter | Type | Description | 
| ----- | ----- | ----- | 
| `size` | `Vector2` | Width and height of the rectangle | 
| `position` | `Vector2` | Top-left screen position | 
| `opacity` | `number` | Opacity (`0`–`1`) | 
| `filled` | `boolean` | Draws a filled background when `true` | 
| `outlined` | `boolean` | Draws a border outline when `true` | 
| `theme` | `string` | Theme name from `ui.Themes` | 
| `roundness` | `number` | Corner rounding radius | 
| `thickness` | `number` | Border and divider line thickness | 
| `main_window` | `boolean` | Enables dragging (`draggable = true`) and uses `MainBG` color | 
| `title` | `string?` | Optional header title with divider line | 

**Methods:**

* `rect:Draw()` — Renders the rectangle (and optional title header).

### TextBox

A styled rectangle with left-padded text rendered inside.

```
ui.TextBox.new(size_text: number, size_box: Vector2, position: Vector2, opacity_box: number, opacity_text: number, filled: boolean, outlined: boolean, outlined_text: boolean, roundness: number, thickness: number, theme: string, text: string)

```

| Parameter | Type | Description | 
| ----- | ----- | ----- | 
| `size_text` | `number` | Font size | 
| `size_box` | `Vector2` | Box width and height | 
| `position` | `Vector2` | Top-left screen position | 
| `opacity_box` | `number` | Background opacity (`0`–`1`) | 
| `opacity_text` | `number` | Text opacity (`0`–`1`) | 
| `filled` | `boolean` | Draws a filled background | 
| `outlined` | `boolean` | Draws a box border | 
| `outlined_text` | `boolean` | Uses `DrawingImmediate.OutlinedText` when `true` | 
| `roundness` | `number` | Corner rounding radius | 
| `thickness` | `number` | Border thickness | 
| `theme` | `string` | Theme name from `ui.Themes` | 
| `text` | `string` | Displayed text | 

**Methods:**

* `textbox:Draw()` — Renders the box and text.

### Button

Clickable rectangle with automatic hover shading and callback execution.

```
ui.Button.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, callback: (() -> ())?)

```

| Parameter | Type | Description | 
| ----- | ----- | ----- | 
| `size` | `Vector2` | Button dimensions | 
| `position` | `Vector2` | Top-left screen position | 
| `opacity` | `number` | Opacity (`0`–`1`) | 
| `filled` | `boolean` | Draws a filled background | 
| `outlined` | `boolean` | Draws a border outline | 
| `theme` | `string` | Theme name from `ui.Themes` | 
| `roundness` | `number` | Corner rounding radius | 
| `thickness` | `number` | Border thickness | 
| `callback` | `(() -> ())?` | Function executed on click | 

**Methods & Properties:**

* `button:Draw()` — Renders the button.

* `button:Clicked(pressed: boolean)` — Handles hover state, click detection, and fires `callback`.

* `button.hovering: boolean` — `true` while the cursor is over the button.

### Checkbox

Toggleable box that highlights with the theme's `Selected` color when active and passes its boolean state to `callback`.

```
ui.Checkbox.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, callback: ((state: boolean) -> ())?)

```

| Parameter | Type | Description | 
| ----- | ----- | ----- | 
| `size` | `Vector2` | Checkbox dimensions | 
| `position` | `Vector2` | Top-left screen position | 
| `opacity` | `number` | Opacity (`0`–`1`) | 
| `filled` | `boolean` | Draws a filled background | 
| `outlined` | `boolean` | Draws a border outline | 
| `theme` | `string` | Theme name from `ui.Themes` | 
| `roundness` | `number` | Corner rounding radius | 
| `thickness` | `number` | Border thickness | 
| `callback` | `((state: boolean) -> ())?` | Fires with `true` or `false` when toggled | 

**Methods & Properties:**

* `checkbox:Draw()` — Renders the checkbox.

* `checkbox:Clicked(pressed: boolean)` — Updates hover/active state and fires `callback(state)`.

* `checkbox.state: boolean` — Current toggle state (`true` / `false`).

* `checkbox.hovering: boolean` — `true` while the cursor is over the checkbox.

### Dropdown

Animated multi-select dropdown menu. The first element in `data` acts as the header; remaining elements slide open as selectable rows.

```
ui.Dropdown.new(data: {string}, size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number)

```

| Parameter | Type | Description | 
| ----- | ----- | ----- | 
| `data` | `{string}` | List of strings (`data[1]` is the header, `data[2..N]` are options) | 
| `size` | `Vector2` | Size of each row | 
| `position` | `Vector2` | Top-left screen position of the header | 
| `opacity` | `number` | Opacity (`0`–`1`) | 
| `filled` | `boolean` | Draws filled rows | 
| `outlined` | `boolean` | Draws row borders | 
| `theme` | `string` | Theme name from `ui.Themes` | 
| `roundness` | `number` | Corner rounding radius | 
| `thickness` | `number` | Border thickness | 

**Methods & Properties:**

* `dropdown:Draw()` — Renders the header and visible option rows.

* `dropdown:Dropped(pressed: boolean): {string}` — Handles opening/closing animations, option selection, and returns `dropdown.chosen`.

* `dropdown.chosen: {string}` — Array of currently selected option strings.

* `dropdown.dropped: boolean` — `true` while the menu is expanded.

* `dropdown.hovering: boolean` — `true` while hovering over the dropdown header.

## Helpers & Animations

| Function | Description | 
| ----- | ----- | 
| `ui.drag(main_window)` | Drags `main_window` and all child components while left mouse is held. Call inside `RunService.Render`. | 
| `ui.hide(hide_key: string): boolean` | Returns `true` if `hide_key` (e.g., `"Ctrl"`) is currently pressed. | 
| `ui.linear(start_pos, end_pos, instance, duration)` | Smoothly interpolates `instance.position` from `start_pos` to `end_pos` over `duration` seconds. | 
| `ui.pop(end_size, instance, duration)` | Smoothly interpolates `instance.size` to `end_size` over `duration` seconds. | 
| `ui.update_animations(dt)` | Advances all active `linear` and `pop` animations. Must be called every frame in `RunService.Render`. | 
