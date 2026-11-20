local box3d = {}

box3d.thickness = 2
box3d.color_filled = Color3.fromRGB(118, 0, 118)
box3d.color_outline = Color3.fromRGB(50, 0, 150)
box3d.text_color = Color3.fromRGB(255, 255, 255)

local ws = workspace
local cam = ws.CurrentCamera

function box3d.rotate(cf, offset)
    return cf.Position + 
        (cf.RightVector * offset.X) + 
        (cf.UpVector * offset.Y) + 
        (-cf.LookVector * offset.Z)
end

function box3d.outline(part)
    local cf = part.CFrame
    local size = part.Size
    
    local nx = -size.X / 2
    local ny = -size.Y / 2
    local nz = -size.Z / 2
    
    local x = size.X / 2
    local y = size.Y / 2
    local z = size.Z / 2
    
    local corners = {
        box3d.rotate(cf, Vector3.new(x, y, nz)),
        box3d.rotate(cf, Vector3.new(nx, y, nz)),
        box3d.rotate(cf, Vector3.new(nx, ny, nz)),
        box3d.rotate(cf, Vector3.new(x, ny, nz)),
        box3d.rotate(cf, Vector3.new(x, y, z)),
        box3d.rotate(cf, Vector3.new(nx, y, z)),
        box3d.rotate(cf, Vector3.new(nx, ny, z)),
        box3d.rotate(cf, Vector3.new(x, ny, z))
    }
    
    return corners
end

function box3d.screen_positions(corners)
    local screen_positions = {}
    for i, v in ipairs(corners) do
        screen_positions[i] = cam:WorldToScreenPoint(v)
    end
    return screen_positions
end

function box3d.draw_faces(screen_positions)
    local s = screen_positions
    --face 1
    DrawingImmediate.FilledQuad(s[1], s[2], s[3], s[4], box3d.color_filled, 0.5)
    --face2
    DrawingImmediate.FilledQuad(s[2], s[3], s[7], s[6], box3d.color_filled, 0.5)
    --face3
    DrawingImmediate.FilledQuad(s[5], s[6], s[7], s[8], box3d.color_filled, 0.5)
    --face4
    DrawingImmediate.FilledQuad(s[1], s[5], s[8], s[4], box3d.color_filled, 0.5)
    --face5
    DrawingImmediate.FilledQuad(s[1], s[2], s[6], s[5], box3d.color_filled, 0.5)
    --face6
    DrawingImmediate.FilledQuad(s[3], s[7], s[8], s[4], box3d.color_filled, 0.5)
end

function box3d.draw_outline(corners)
    local c = corners
    --face 1
    DrawingImmediate.Quad(c[1], c[2], c[3], c[4], box3d.color_outline, box3d.thickness)
    --face2
    DrawingImmediate.Quad(c[2], c[3], c[7], c[6], box3d.color_outline, box3d.thickness)
    --face3
    DrawingImmediate.Quad(c[5], c[6], c[7], c[8], box3d.color_outline, box3d.thickness)
    --face4
    DrawingImmediate.Quad(c[1], c[5], c[8], c[4], box3d.color_outline, box3d.thickness)
    --face5
    DrawingImmediate.Quad(c[1], c[2], c[6], c[5], box3d.color_outline, box3d.thickness)
    --face6
    DrawingImmediate.Quad(c[3], c[7], c[8], c[4], box3d.color_outline, box3d.thickness)
end
function box3d.text(part, text, character)
    local text = text or part.Name
    local pos = part.Position
    local size = part.Size
    local text_pos = pos + Vector3.new(0, size.Y + 5, 0)
    local spos, vis = cam:WorldToScreenPoint(text_pos)
    if vis then
        local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        local dist = vector.magnitude(hrp.Position - pos)
        local text_size = math.clamp(150 / math.max(dist, 1), 12, 24)
        DrawingImmediate.Text(spos, text_size, box3d.text_color, true, text)
    end
end
return box3d
