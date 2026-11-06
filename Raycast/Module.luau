--!strict
local parts = {}
local characters = {}
local grouped = {}


local json_ = game:HttpGet("https://offsets.imtheo.lol/offsets.json")
local decoded = crypt.json.decode(json_)
local offsets = decoded.Offsets


local b_p = offsets.BasePart --bp omgggggg
local prim_part = b_p.Primitive
local prim_main = offsets.Primitive

local pos_offset = prim_main.Position
local size_offset = prim_main.Size



local world = offsets.Workspace.World
local prim_holder = offsets.World.Primitives

local function cache()
	local prim_addrs = {}
	local ws = workspace
	local world = memory.readu64(ws, world)
	local prim_holder = memory.readu64(world, prim_holder)
	for offset = 0x0, 0xFFFFFFFF, 0x8 do
		local prim_addr = memory.readu64(prim_holder, offset)
		if memory.rtti(prim_addr) == "RBX::Primitive" then
			table.insert(prim_addrs, prim_addr)
		else
			break
		end
	end
	return prim_addrs
end

local function find_model(part_instance)
	local p = part_instance
	if not p then return false end
	local success, parent = pcall(function() 
		return p.Parent
	end)
	if not success and not parent then return false end
	if not success then return end
	if not parent then return end
	if parent.ClassName == "Model" and parent:FindFirstChild("Humanoid") then
		return p.Parent
	elseif p ~= workspace then
		return find_model(p.Parent)
	else
		return false
	end
end
local offset = 0x218
local seen = {}
local function sort(prim_addrs: table)
	for _, prim_addr in pairs(prim_addrs) do

		if not offset then print("offset not found") continue end
		local part_address = memory.readu64(prim_addr, offset)
		local part_instance = pointer_to_userdata(part_address)
		local found_model = find_model(part_instance)
		if not found_model then
			table.insert(parts, part_instance)
			table.insert(grouped, part_instance)
		elseif found_model:FindFirstChild("HumanoidRootPart") and not seen[found_model] then
			seen[found_model] = true
			table.insert(characters, found_model:FindFirstChild("HumanoidRootPart"))
			table.insert(grouped, found_model:FindFirstChild("HumanoidRootPart"))
		end				
	end
	return parts, characters, grouped
end





send_notification("caching static parts, thisll take a while depending on the games size", "info")
sort(cache())
print(#parts, #characters, #grouped)
send_notification("done", "info")

local function determine_hit(
    origin: vector,
    direction: vector,
    part_size: vector,
    part_pos: vector,
    right_vec: vector,
    up_vec: vector,
    look_vec: vector
): (number?, vector?)

    local rel_pos = origin - part_pos

    local local_origin = vector.create(
        vector.dot(rel_pos, right_vec),
        vector.dot(rel_pos, up_vec),
        -vector.dot(rel_pos, look_vec)
    )

    local local_dir = vector.create(
        vector.dot(direction, right_vec),
        vector.dot(direction, up_vec),
        -vector.dot(direction, look_vec)
    )

    local half_size = part_size * 0.5

    local inside =
        math.abs(local_origin.x) <= half_size.x and
        math.abs(local_origin.y) <= half_size.y and
        math.abs(local_origin.z) <= half_size.z

    local tmin = -math.huge
    local tmax = math.huge

    local entry_normal = vector.create(0, 0, 0)
    local exit_normal = vector.create(0, 0, 0)

    local axes = {
        {
            origin = local_origin.x,
            direction = local_dir.x,
            min = -half_size.x,
            max = half_size.x,
            axis = vector.create(1, 0, 0)
        },
        {
            origin = local_origin.y,
            direction = local_dir.y,
            min = -half_size.y,
            max = half_size.y,
            axis = vector.create(0, 1, 0)
        },
        {
            origin = local_origin.z,
            direction = local_dir.z,
            min = -half_size.z,
            max = half_size.z,
            axis = vector.create(0, 0, 1)
        }
    }

    for _, slab in ipairs(axes) do
        local o = slab.origin
        local d = slab.direction

        if math.abs(d) < 1e-6 then
            if o < slab.min or o > slab.max then
                return nil, nil
            end
        else
            local t1 = (slab.min - o) / d
            local t2 = (slab.max - o) / d

            local near_normal = -slab.axis
            local far_normal = slab.axis

            if t1 > t2 then
                t1, t2 = t2, t1
                near_normal, far_normal = far_normal, near_normal
            end

            if t1 > tmin then
                tmin = t1
                entry_normal = near_normal
            end

            if t2 < tmax then
                tmax = t2
                exit_normal = far_normal
            end

            if tmin > tmax then
                return nil, nil
            end
        end
    end

    local t
    local local_normal

    if inside then
        t = tmax
        local_normal = exit_normal
    else
        t = tmin
        local_normal = entry_normal
    end

    if t < 0 or t > 1 then
        return nil, nil
    end

    return t, local_normal
end

local WorkspaceRaycaster = {}

function WorkspaceRaycaster:Raycast(origin: vector, direction: vector, params: any?, instance_type: string)
	local closest_hit = nil
	local min_dist = math.huge
	print("Raycast called:", instance_type, #table_)
	local ray_length = vector.magnitude(direction)
	if ray_length == 0 then return nil end
	local table_ = workspace:GetDescendants()
	if instance_type == "static_walls" then
		table_ = parts
	elseif instance_type == "characters" then
		table_ = characters
	elseif instance_type == "grouped" then
		table_ = grouped
	end
	for _, part in ipairs(table_) do
		local filter_passed = nil
		if not part then continue end
		if part:IsA("BasePart") and part.ClassName ~= "Terrain" and part.ClassName ~= "Seat" then
			filter_passed = true
			if params and params.FilterDescendantsInstances then
				for _, ignoredInstance in ipairs(params.FilterDescendantsInstances) do
					if part == ignoredInstance or part:IsDescendantOf(ignoredInstance) then
						filter_passed = false
						break
					end
				end
			end
			if filter_passed then
				local cf = part.CFrame
				
				local pos = cf.Position
				local size = part.Size
			
				local rv = cf.RightVector
				local uv = cf.UpVector
				local lv = cf.LookVector
				local t, local_normal = determine_hit(
					origin, 
					direction, 
					size, 
					pos, 
					rv, 
					uv, 
					lv
				)
				
				if t then
					print("Intersection:", part.Name, t)
					local distance = t * ray_length
					if distance < min_dist then
						min_dist = distance
						
						local local_origin_rel = origin - pos
						local local_orig = vector.create(
							vector.dot(local_origin_rel, rv), 
							vector.dot(local_origin_rel, uv), 
							-vector.dot(local_origin_rel, lv)
						)
						local local_dir_rel = vector.create(
							vector.dot(direction, rv), 
							vector.dot(direction, uv), 
							-vector.dot(direction, lv)
						)
						local local_hit_pos = local_orig + (local_dir_rel * t)
						
						local hit_pos = origin + (direction * t)
							
						local world_normal = (rv * local_normal.x) 
							+ (uv * local_normal.y) 
							+ (-lv * local_normal.z)
						
						closest_hit = {
							Position = hit_pos,
							Normal = world_normal,
							Distance = distance,
							Instance = part,
							Parent = part.Parent,
							I_Name = part.Name,
							I_Class = part.ClassName,
							
						}
					end
				end
			end
		end
	end
	return closest_hit
end
local pl = game:GetService("Players")
local lp = pl.LocalPlayer
local chara = lp.Character
local hrp = chara:FindFirstChild("HumanoidRootPart")




local params = {
    FilterDescendantsInstances = {chara}
}
while task.wait(1) do
	local origin = hrp.Position + (hrp.CFrame.LookVector)
	local direction = hrp.CFrame.LookVector * 50
	local raycast = WorkspaceRaycaster:Raycast(origin, direction, params, "static_walls")
	if raycast then
	  print(raycast)
--[[
	    {
	        Normal   = 1, 0, 0
	        Position = 2.1476593017578125, 3.000002384185791, -44.869056701660156
	        Instance = Part
	        Distance = 33.47706544960554
	        Parent   = rare7
	    }
	  ]]
	else
	  print("didnt hit")
	end
end

return WorkspaceRaycaster
