[UI_Library_Documentation(1).md](https://github.com/user-attachments/files/35196856/UI_Library_Documentation.1.md)
# UI Library Documentation

An immediate-mode Luau UI library built on `DrawingImmediate`. The module provides themed rectangles, text boxes, buttons, checkboxes, multi-select dropdowns, sliders, keybinds, tabs, dragging, and simple size/position animations.

This documentation is based on the uploaded module and its accompanying test script. The test script is an example harness; the reusable library ends before the test section.

> **Module setup note:** the uploaded module assigns its exports to `ui` and returns `ui`, but does not declare `ui` in the uploaded source. In a standalone ModuleScript, add `local ui = {}` near the top of the module (before the exports near the bottom), otherwise the returned export table is not initialized.

## Quick start

The test script uses a `Rectangle` as the main window, creates widgets, registers tabs, and updates the UI from a render callback.

```luau
local ui = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/grobshlob/Important-Stuff/refs/heads/main/UI/Module.luau"
))()

local RunService = game:GetService("RunService")

local theme = "NavyCream"
local active_theme = theme

local window = ui.Rectangle.new(
    Vector2.new(600, 400),
    Vector2.new(500, 500),
    1, true, true, theme, 15, 3, true, "My UI"
)

local button = ui.Button.new(
    Vector2.new(150, 40),
    Vector2.new(630, 605),
    1, true, true, theme, 10, 2,
    function()
        print("Button clicked")
    end,
    "Click me"
)

local checkbox = ui.Checkbox.new(
    Vector2.new(50, 50),
    Vector2.new(860, 660),
    1, true, true, theme, 10, 2,
    function(state)
        print("Checkbox state:", state)
    end
)
local data = {"Themes"}
for theme, color in pairs(ui.Themes) do
	table.insert(data, theme)
end
local dropdown = ui.Dropdown.new(
    data,
    Vector2.new(200, 40),
    Vector2.new(630, 660),
    1, true, true, theme, 15, 3, 1
)

local slider = ui.Slider.new(
    Vector2.new(200, 12),
    Vector2.new(630, 730),
    1, true, true, theme, 6, 2,
    0, 100, 50
)

local keybind = ui.Keybind.new(
    15,
    Vector2.new(40, 40),
    Vector2.new(750, 760),
    1, true, true, theme, 15, 3, "F"
)

-- Tabs
local main_tab = ui.Tab.new("Main", 1, Vector2.new(100, 32))
local settings_tab = ui.Tab.new("Settings", 2, Vector2.new(100, 32))

main_tab:Register(window)
settings_tab:Register(window)

main_tab:Add(button)
main_tab:Add(slider)

settings_tab:Add(checkbox)
settings_tab:Add(dropdown)
settings_tab:Add(keybind)

-- Input tracking
local was_pressed = false

-- Render loop
RunService.Render:Connect(function(dt)
    local is_pressed = isleftpressed()
    local pressed = is_pressed and not was_pressed

    was_pressed = is_pressed

    -- Draw window
    window:Draw()

    -- Update animations
    ui.update_animations(dt)

    if not window.animated then
        return
    end

    -- Draw tabs and their contents
    ui.Tabs:Draw(pressed, is_pressed)

    -- Theme selection
    if ui.Tabs.active == 2 then
        local selected_theme = dropdown.chosen[1]

        if selected_theme
            and ui.Themes[selected_theme]
            and selected_theme ~= active_theme
        then
            if ui.SetTheme(selected_theme) then
                active_theme = selected_theme
                print("Theme changed to:", active_theme)
            end
        end

        -- Keybind detection
        if keybind.activated then
            print("Pressed:", keybind.current_key)
        end
    end

    -- Window dragging
    if window.draggable
        and not slider.dragging
        and not checkbox.hovering
        and not button.hovering
        and not dropdown.hovering
        and not keybind.hovering
    then
        ui.drag(window)
    end
end)
```

### Input timing

`isleftpressed()` should be read once per frame. Derive `pressed` as the transition from released to held:

```luau
local is_pressed = isleftpressed()
local pressed = is_pressed and not was_pressed
was_pressed = is_pressed
```

Pass both values to `ui.Tabs:Draw(pressed, is_pressed)`. `pressed` is for click events; `is_pressed` is for held interactions such as dragging a slider.

The library also expects the environment to provide `getpressedkeys()`, `isleftpressed()`, `DrawingImmediate`, and the input APIs used in the module.

## Exports

The module exports these members:

| Export | Purpose |
| --- | --- |
| `ui.Rectangle` | Rectangle and main-window component |
| `ui.TextBox` | Text inside a styled rectangle |
| `ui.Button` | Clickable button |
| `ui.Checkbox` | Boolean toggle |
| `ui.Dropdown` | Animated multi-select list |
| `ui.Slider` | Draggable numeric slider |
| `ui.Keybind` | Key capture and key-press detection |
| `ui.Tab` | Creates a tab |
| `ui.Tabs` | Shared tab manager |
| `ui.Themes` | Theme palette table |
| `ui.drag` | Drags a main window and registered children |
| `ui.hide` | Checks whether a key is currently pressed |
| `ui.linear` | Position interpolation animation |
| `ui.pop` | Centered size animation |
| `ui.bounce` | Sine-based size bounce |
| `ui.slide_up` | Vertical size expansion |
| `ui.update_animations` | Advances active animations |

## Themes

Pass a theme name as the `theme` argument. The module defines these names:

- `Catppuccin`
- `MonokaiPro`
- `SolarizedDark`
- `Monochrome`
- `JadeHorizon`
- `AbyssalSlate`
- `VelvetPlum`
- `AutumnTimber`
- `EspressoCrema`
- `WinterPine`
- `NavyCream`
- `RosewoodDawn`
- `ChaosPeach`

Each theme contains six `Color3` values:

| Key | Used for |
| --- | --- |
| `MainBG` | Main window background |
| `BoxFill` | Component background |
| `Outline` | Borders, accents, and slider knob |
| `Accent` | Additional details and separators |
| `Selected` | Selected checkbox/dropdown state |
| `Text` | Text color |

Access the palette directly with `ui.Themes.NavyCream`, for example.

## Components

### Rectangle

Creates a rectangle. Set `main_window` to `true` for the primary window. The main window expands its width by 50 pixels on its first draw, plays a centered pop animation, and draws the sidebar divider and cat graphic. A main window is marked draggable.

```luau
ui.Rectangle.new(
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    main_window: boolean,
    title: string?
)
```

| Argument | Meaning |
| --- | --- |
| `size` | Rectangle dimensions |
| `position` | Top-left screen position |
| `opacity` | Opacity value |
| `filled` | Whether to draw a filled rectangle |
| `outlined` | Whether to draw an outline |
| `theme` | Theme name |
| `roundness` | Corner radius |
| `thickness` | Outline/divider thickness |
| `main_window` | Enables main-window behavior when true |
| `title` | Optional title displayed in the header |

**Methods and properties**

- `rectangle:Draw()` — draws the rectangle.
- `rectangle.animated` — becomes true after the main window's initial animation completes.
- `rectangle.draggable` — true for a main window.
- `rectangle.position`, `rectangle.size`, `rectangle.theme` — mutable component properties.

### TextBox

Draws text over a styled rectangle. `centered` is an optional final argument in the uploaded module.

```luau
ui.TextBox.new(
    size_text: number,
    size_box: Vector2,
    position: Vector2,
    opacity_box: number,
    opacity_text: number,
    filled: boolean,
    outlined: boolean,
    outlined_text: boolean,
    roundness: number,
    thickness: number,
    theme: string,
    text: string,
    centered: boolean?
)
```

| Argument | Meaning |
| --- | --- |
| `size_text` | Font size |
| `size_box` | Background dimensions |
| `position` | Top-left screen position |
| `opacity_box` | Background opacity |
| `opacity_text` | Text opacity |
| `filled` | Whether the background is filled |
| `outlined` | Whether the background has an outline |
| `outlined_text` | Uses `DrawingImmediate.OutlinedText` when true |
| `roundness` | Background corner radius |
| `thickness` | Outline thickness |
| `theme` | Theme name |
| `text` | Text to display |
| `centered` | Passes centered alignment to the regular text drawing call |

**Methods and properties**

- `textbox:Draw()` — draws the background and text.
- `textbox.text` — displayed string.
- `textbox.centered` — whether regular text drawing uses centered alignment.

### Button

A clickable rectangle with optional text. Hovering changes its fill shade. Clicking plays a bounce animation and calls the callback.

```luau
ui.Button.new(
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    callback: (() -> ())?,
    text: string?
)
```

| Argument | Meaning |
| --- | --- |
| `size` | Button dimensions |
| `position` | Top-left screen position |
| `opacity` | Opacity |
| `filled` | Whether the button is filled |
| `outlined` | Whether the button has an outline |
| `theme` | Theme name |
| `roundness` | Corner radius |
| `thickness` | Outline thickness |
| `callback` | Function called when clicked |
| `text` | Optional button label |

**Methods and properties**

- `button:Draw()` — creates the backing rectangle/textbox if needed, then draws it.
- `button:Clicked(pressed: boolean)` — updates hover state and handles click edges.
- `button.hovering` — true while the mouse is over the button.
- `button.activated` — toggled on each click.

### Checkbox

A clickable toggle that changes its state and selected fill color. The callback receives the new boolean state.

```luau
ui.Checkbox.new(
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    callback: ((state: boolean) -> ())?
)
```

| Argument | Meaning |
| --- | --- |
| `size` | Checkbox dimensions |
| `position` | Top-left screen position |
| `opacity` | Opacity |
| `filled` | Whether the checkbox is filled |
| `outlined` | Whether the checkbox has an outline |
| `theme` | Theme name |
| `roundness` | Corner radius |
| `thickness` | Outline thickness |
| `callback` | Called with `true` or `false` after a toggle |

**Methods and properties**

- `checkbox:Draw()` — draws the checkbox.
- `checkbox:Clicked(pressed: boolean)` — handles hover and click behavior.
- `checkbox.state` — current boolean state.
- `checkbox.activated` — current active state.
- `checkbox.hovering` — true while hovered.

**Implementation note:** although the constructor type marks `callback` optional, the current `Clicked` implementation calls it without checking for `nil`. Supply a callback when creating a checkbox unless the module is updated with a nil check.

### Dropdown

An animated multi-select dropdown. The first string in `data` is the header; the remaining strings are selectable options. The menu animates option rows open and closed.

```luau
ui.Dropdown.new(
    data: {string},
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    max: number?
)
```

| Argument | Meaning |
| --- | --- |
| `data` | String array; `data[1]` is the header |
| `size` | Dimensions of each row |
| `position` | Top-left position of the header |
| `opacity` | Row opacity |
| `filled` | Whether rows are filled |
| `outlined` | Whether rows have outlines |
| `theme` | Theme name |
| `roundness` | Row corner radius |
| `thickness` | Outline thickness |
| `max` | Maximum number of selected values; if omitted, the implementation sets it to `#data` |

**Methods and properties**

- `dropdown:Draw()` — draws the header, options, and chevron.
- `dropdown:Dropped(pressed: boolean): {string}` — handles opening, closing, hover, and selection; returns the selected array.
- `dropdown.chosen` — array of selected option strings.
- `dropdown.dropped` — true while expanded.
- `dropdown.hovering` — true while the header is hovered.
- `dropdown.max` — maximum selection count.

Example:

```luau
local dropdown = ui.Dropdown.new(
    {"Choose theme", "NavyCream", "Monochrome"},
    Vector2.new(180, 36),
    Vector2.new(600, 600),
    1, true, true, "NavyCream", 8, 2, 1
)

-- After ui.Tabs:Draw has updated the dropdown:
local chosen_theme = dropdown.chosen[1]
```

### Slider

A horizontal slider with a circular knob. The value is clamped to the configured minimum and maximum. The slider is dragged by clicking near its knob and holding the mouse button.

```luau
ui.Slider.new(
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    min: number,
    max: number,
    value: number?
)
```

| Argument | Meaning |
| --- | --- |
| `size` | Track dimensions |
| `position` | Top-left track position |
| `opacity` | Track/knob opacity |
| `filled` | Whether the track is filled |
| `outlined` | Whether the track has an outline |
| `theme` | Theme name |
| `roundness` | Track corner radius |
| `thickness` | Track outline thickness |
| `min` | Minimum value |
| `max` | Maximum value |
| `value` | Initial value; defaults to `min` |

**Methods and properties**

- `slider:Draw()` — draws the track, segment rectangles, and knob.
- `slider:Update(pressed: boolean, is_held: boolean, on_change: ((number) -> ())?)` — starts/continues/stops dragging and optionally calls `on_change(value)` when the value changes.
- `slider:SetValue(new_value: number)` — clamps and assigns the value.
- `slider:GetKnobInfo(): (Vector2, number)` — returns the knob center and its radius.
- `slider.value` — current numeric value.
- `slider.dragging` — true while the knob is being dragged.

**Tab-manager note:** `ui.Tabs:Draw` calls `slider:Update(pressed, is_pressed)` with only the two input arguments. To use `on_change`, call `slider:Update` yourself with the callback, or modify the tab manager to forward one.

### Keybind

A clickable keybind box. Click the box to enter capture mode, then press a key. `Keybind:Set()` ignores the left mouse button used to activate the control. `Keybind:Check()` sets `activated` for the first frame of a key press, rather than remaining true for every frame the key is held.

```luau
ui.Keybind.new(
    text_size: number,
    size: Vector2,
    position: Vector2,
    opacity: number,
    filled: boolean,
    outlined: boolean,
    theme: string,
    roundness: number,
    thickness: number,
    start_key: string?
)
```

| Argument | Meaning |
| --- | --- |
| `text_size` | Font size for the displayed key |
| `size` | Keybind box dimensions |
| `position` | Top-left position |
| `opacity` | Box and text opacity |
| `filled` | Whether the box is filled |
| `outlined` | Whether the box has an outline |
| `theme` | Theme name |
| `roundness` | Corner radius |
| `thickness` | Outline thickness |
| `start_key` | Optional initial key string |

**Methods and properties**

- `keybind:Draw()` — draws the box and current key label.
- `keybind:Clicked(pressed: boolean)` — toggles key capture when clicked.
- `keybind:Set()` — captures a key while capture mode is active.
- `keybind:Check()` — checks the current key and updates `activated`.
- `keybind.current_key` — currently assigned key string, or `"Not Set"`.
- `keybind.clicked` — true while waiting for a key.
- `keybind.activated` — true for the frame in which the assigned key transitions to pressed.
- `keybind.hovering` — true while the mouse is over the keybind box.

Example:

```luau
if keybind.activated then
    print("Pressed:", keybind.current_key)
end
```

The test script registers the keybind with a tab, so `ui.Tabs:Draw` calls `Draw`, `Clicked`, `Set`, and `Check` automatically.

## Tabs

Tabs group components. The manager draws all tab buttons and updates the components belonging to the active tab.

### Create a tab

```luau
ui.Tab.new(name: string, index: number, size: Vector2)
```

| Argument | Meaning |
| --- | --- |
| `name` | Text shown on the sidebar button |
| `index` | 1-based tab index |
| `size` | Sidebar button dimensions |

**Tab methods**

- `tab:Register(main_window)` — creates the sidebar button using the main window's theme and layout.
- `tab:Add(instance)` — adds a component to the tab's `instances` array.

**Tabs manager**

- `ui.Tabs:Draw(pressed: boolean, is_pressed: boolean)` — draws tab buttons, then draws and updates widgets in the active tab. It dispatches `Clicked`, `Dropped`, `Update`, `Set`, and `Check` methods when present.
- `ui.Tabs.active` — active tab index; defaults to `1`.
- `ui.Tabs.list` — array of created tabs.

Example:

```luau
local first = ui.Tab.new("Main", 1, Vector2.new(100, 32))
local second = ui.Tab.new("Other", 2, Vector2.new(100, 32))

first:Register(window)
second:Register(window)

first:Add(button)
second:Add(checkbox)
```

## Helpers and animations

### Dragging

```luau
ui.drag(main_window)
```

Call while the left mouse button is held. The helper records the positions of registered children when dragging begins, then moves the main window and those children by the mouse delta. The main window's drag area is its rectangle.

### Hide-key check

```luau
ui.hide(hide_key: string): boolean
```

Returns true when the supplied key string appears in `getpressedkeys()`. The test harness polls this helper and toggles a `hidden` state on a key-down edge.

```luau
local was_down = false

task.spawn(function()
    while task.wait(0.05) do
        local is_down = ui.hide("Ctrl")
        if is_down and not was_down then
            hidden = not hidden
        end
        was_down = is_down
    end
end)
```

### Animations

The animation helpers add entries to the module's animation list. Call `ui.update_animations(dt)` every frame to advance them.

```luau
ui.linear(start_position: Vector2, end_position: Vector2, instance, duration: number)
ui.pop(end_size: Vector2, instance, duration: number, start_size: Vector2?, on_complete: (() -> ())?)
ui.bounce(instance, duration: number, strength: number)
ui.slide_up(instance, duration: number, on_complete: (() -> ())?)
ui.update_animations(dt: number)
```

| Helper | Behavior |
| --- | --- |
| `linear` | Interpolates `instance.position` from start to end |
| `pop` | Interpolates `instance.size` from a start size to an end size while adjusting position to keep it centered |
| `bounce` | Scales the instance out and back using a sine curve |
| `slide_up` | Expands the instance's height from 1 pixel to its current height |
| `update_animations` | Advances active animations and invokes completion callbacks |

## Test script notes

The uploaded test script exercises:

- A main window using the `NavyCream` theme.
- A button and slider on the first tab.
- A checkbox, theme dropdown, and keybind on the second tab.
- Changing the window theme from the first selected dropdown option.
- Printing the key name when the keybind activates.
- Hiding/toggling the UI using the `"Ctrl"` key.
- Drawing and updating animations from a render callback.

The test script includes both the module implementation and a test section. If you split the files, keep the reusable class/helper definitions and `ui` exports in `Module.luau`; keep sample widget creation and the render loop in a separate test script.

## Current implementation caveats

These are behavior notes from the uploaded source, not additional API promises:

1. The module references an export table named `ui` but does not initialize it in the uploaded file. Add `local ui = {}` before assigning exports.
2. `Checkbox:Clicked` calls `self.callback(self.state)` without a nil check, so pass a callback.
3. `ui.Tabs:Draw` does not forward an `on_change` callback to `Slider:Update`.
4. The module uses environment-provided helpers/APIs such as `getpressedkeys`, `isleftpressed`, and `DrawingImmediate`; they must exist in the runtime where the module is used.
5. The test harness uses `RunService.Render`. Use the render event provided by your execution environment; the event name may differ between environments.
