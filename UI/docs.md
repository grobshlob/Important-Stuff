
# UI Library Documentation

An immediate-mode Luau UI library built on `DrawingImmediate`, featuring built-in theming, window dragging, pop/bounce/slide animations, tabs, and modular UI components.

## Quick Start

Load the module, instantiate your components, and render them inside `RunService.Render` (or `RenderUnrestricted`). Track `isleftpressed()` **once** per frame to derive a single-frame `pressed` flag, then pass `pressed` and `is_pressed` into `ui.Tabs:Draw`.

```luau
local ui = loadstring(game:HttpGet("https://raw.githubusercontent.com/grobshlob/Important-Stuff/refs/heads/main/UI/Module.luau"))()
local RunService = game:GetService("RunService")

local window = ui.Rectangle.new(Vector2.new(600, 400), Vector2.new(500, 500), 1, true, true, "Monochrome", 15, 3, true, "My Hub")
local label = ui.TextBox.new(30, Vector2.new(200, 35), Vector2.new(640, 555), 1, 1, true, true, false, 10, 2, "Monochrome", "Status: Ready")
local dropdown = ui.Dropdown.new({"Options", "Option 1", "Option 2"}, Vector2.new(150, 45), Vector2.new(640, 660), 1, true, true, "Monochrome", 12, 2)

local button = ui.Button.new(Vector2.new(150, 40), Vector2.new(640, 605), 1, true, true, "Monochrome", 10, 2, function()
	print("Button clicked!")
end, "Click Me")

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

* `"Catppuccin"`
* `"Emerald_Glass"`
* `"Royal_Gold"`
* `"Rose_Pine"`
* `"Gruvbox_Dark"`
* `"Crimson_Carbon"`
* `"Phantom_Violet"`
* `"Monochrome"`
* `"Toxic_Lime"`
* `"Frost_Light"`

Each theme table contains six `Color3` keys: `MainBG`, `BoxFill`, `Outline`, `Accent`, `Selected`, and `Text`.

## Components

### Rectangle

Base container used for main windows and background panels. When `main_window = true`, it automatically expands its width by `50px` for the sidebar, plays a `0.5s` centered `pop` animation on first draw, and renders a sidebar divider with a cat icon. Any `Rectangle` created with `main_window = false` is automatically registered as a child and moves with the main window when dragged.

```luau
ui.Rectangle.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, main_window: boolean, title: string?)

```

| Parameter | Type | Description |
| --- | --- | --- |
| `size` | `Vector2` | Width and height of the rectangle |
| `position` | `Vector2` | Top-left screen position |
| `opacity` | `number` | Opacity (`0`–`1`) |
| `filled` | `boolean` | Draws a filled background when `true` |
| `outlined` | `boolean` | Draws a border outline when `true` |
| `theme` | `string` | Theme name from `ui.Themes` |
| `roundness` | `number` | Corner rounding radius |
| `thickness` | `number` | Border and divider line thickness |
| `main_window` | `boolean` | Enables dragging, sidebar layout, `MainBG` color, and pop-in animation |
| `title` | `string?` | Optional header title with horizontal divider line |

**Methods & Properties:**

* `rect:Draw()` — Renders the rectangle, optional title header, and sidebar divider/icon.
* `rect.animated: boolean` — `true` once the main window's initial `pop` animation finishes.
* `rect.draggable: boolean` — `true` for main windows.

### TextBox

A styled rectangle with left-padded text rendered inside.

```luau
ui.TextBox.new(size_text: number, size_box: Vector2, position: Vector2, opacity_box: number, opacity_text: number, filled: boolean, outlined: boolean, outlined_text: boolean, roundness: number, thickness: number, theme: string, text: string)

```

| Parameter | Type | Description |
| --- | --- | --- |
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

Clickable button with automatic hover shading, click `bounce` animation, optional text label, and callback execution.

```luau
ui.Button.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, callback: (() -> ())?, text: string?)

```

| Parameter | Type | Description |
| --- | --- | --- |
| `size` | `Vector2` | Button dimensions |
| `position` | `Vector2` | Top-left screen position |
| `opacity` | `number` | Opacity (`0`–`1`) |
| `filled` | `boolean` | Draws a filled background |
| `outlined` | `boolean` | Draws a border outline |
| `theme` | `string` | Theme name from `ui.Themes` |
| `roundness` | `number` | Corner rounding radius |
| `thickness` | `number` | Border thickness |
| `callback` | `(() -> ())?` | Function executed on click |
| `text` | `string?` | Optional label (renders internally as a `TextBox` when provided) |

**Methods & Properties:**

* `button:Draw()` — Renders the button.
* `button:Clicked(pressed: boolean)` — Handles hover state, click detection, `bounce` animation, and fires `callback`.
* `button.hovering: boolean` — `true` while the cursor is over the button.

### Checkbox

Toggleable box that highlights with the theme's `Selected` color when active, plays a `bounce` animation on click, and passes its boolean state to `callback`.

```luau
ui.Checkbox.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, callback: ((state: boolean) -> ())?)

```

| Parameter | Type | Description |
| --- | --- | --- |
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
* `checkbox:Clicked(pressed: boolean)` — Updates hover/active state, plays `bounce`, and fires `callback(state)`.
* `checkbox.state: boolean` — Current toggle state (`true` / `false`).
* `checkbox.hovering: boolean` — `true` while the cursor is over the checkbox.

### Dropdown

Animated multi-select dropdown menu with a chevron indicator. The first element in `data` acts as the header; remaining elements slide open as selectable rows.

```luau
ui.Dropdown.new(data: {string}, size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number)

```

| Parameter | Type | Description |
| --- | --- | --- |
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

* `dropdown:Draw()` — Renders the header, chevron, and visible option rows.
* `dropdown:Dropped(pressed: boolean): {string}` — Handles opening/closing animations, option selection, and returns `dropdown.chosen`.
* `dropdown.chosen: {string}` — Array of currently selected option strings.
* `dropdown.dropped: boolean` — `true` while the menu is expanded.
* `dropdown.hovering: boolean` — `true` while hovering over the dropdown header.

### Slider

Draggable horizontal slider with a circular knob and active drag halo.

```luau
ui.Slider.new(size: Vector2, position: Vector2, opacity: number, filled: boolean, outlined: boolean, theme: string, roundness: number, thickness: number, min: number, max: number, value: number?)

```

| Parameter | Type | Description |
| --- | --- | --- |
| `size` | `Vector2` | Track width and height |
| `position` | `Vector2` | Top-left screen position |
| `opacity` | `number` | Opacity (`0`–`1`) |
| `filled` | `boolean` | Draws a filled track |
| `outlined` | `boolean` | Draws a track border |
| `theme` | `string` | Theme name from `ui.Themes` |
| `roundness` | `number` | Corner rounding radius |
| `thickness` | `number` | Border thickness |
| `min` | `number` | Minimum slider value |
| `max` | `number` | Maximum slider value |
| `value` | `number?` | Initial value (defaults to `min`) |

**Methods & Properties:**

* `slider:Draw()` — Renders the slider track and knob.
* `slider:Update(pressed: boolean, is_held: boolean, on_change: ((number) -> ())?)` — Handles knob dragging, renders the drag halo, updates `slider.value`, and fires `on_change(value)` when changed.
* `slider:SetValue(new_value: number)` — Clamps and sets `slider.value`.
* `slider:GetKnobInfo(): (Vector2, number)` — Returns the knob's center position and radius.
* `slider.value: number` — Current slider value.
* `slider.dragging: boolean` — `true` while the knob is being dragged.

### Tab & Tabs

Sidebar category system for organizing widgets into switchable pages.

```luau
ui.Tab.new(name: string, index: number, size: Vector2)

```

| Parameter | Type | Description |
| --- | --- | --- |
| `name` | `string` | Label displayed on the sidebar tab button |
| `index` | `number` | 1-based vertical slot order and tab ID |
| `size` | `Vector2` | Dimensions of the tab button |

**`Tab` Methods:**

* `tab:Register(main_window)` — Creates and positions the tab's sidebar `Button` relative to `main_window`.
* `tab:Add(instance)` — Assigns a widget (`TextBox`, `Button`, `Checkbox`, `Dropdown`, `Slider`) to this tab.

**`Tabs` Manager Methods & Properties:**

* `ui.Tabs:Draw(pressed: boolean, is_pressed: boolean)` — Renders all tab buttons and draws/updates all widgets belonging to `ui.Tabs.active`.
* `ui.Tabs.active: number` — Index of the currently active tab (defaults to `1`).
* `ui.Tabs.list: {Tab}` — Array of all created `Tab` instances.

## Helpers & Animations

| Function | Description |
| --- | --- |
| `ui.drag(main_window)` | Drags `main_window` and all child components while left mouse is held. Call inside `RunService.Render`. |
| `ui.hide(hide_key: string): boolean` | Returns `true` if `hide_key` (e.g., `"Ctrl"`) is currently pressed. |
| `ui.linear(start_position, end_position, instance, duration)` | Smoothly interpolates `instance.position` from `start_position` to `end_position` over `duration` seconds. |
| `ui.pop(end_size, instance, duration, start?, on_complete?)` | Animates `instance.size` from `start` (or current size) to `end_size` while keeping it centered, then runs `on_complete`. |
| `ui.bounce(instance, duration, strength)` | Smoothly scales `instance.size` out by `strength` and back using a sine curve while staying centered. |
| `ui.slide_up(instance, duration, on_complete?)` | Expands `instance.size.Y` from `1` to its target height over `duration` seconds, then runs `on_complete`. |
| `ui.update_animations(dt)` | Advances all active animations and triggers `on_complete` callbacks. Must be called every frame in `RunService.Render`. |

```

```
