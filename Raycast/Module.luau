--!strict
local parts = {}

local json_ = game:HttpGet("https://offsets.imtheo.lol/offsets.json")
local decoded = crypt.json.decode(json_)
local offsets = decoded.Offsets


local b_p = offsets.BasePart --bp omgggggg
local prim_part = b_p.Primitive
local prim_main = offsets.Primitive

local pos_offset = prim_main.Position
local size_offset = prim_main.Size
local rotation_offset = prim_main.Rotation
local prim_part = 0x218

local world = offsets.Workspace.World
local prim_holder = world.Primitives

local function cache()
	local prim_addrs = {}
	local ended = false
	local ws = workspace
	local world = memory.readu64(ws, world)
	local prim_holder = memory.readu64(world, prim_holder)
	for offset = 0x0, 0xFFFFFFFF, 0x8 do
		local prim_addr = memory.readu64(prim_holder, offset)
		if memory.rtti(prim_addr) == "RBX::Primitive" then
			table.insert(prim_addrs, prim_addr)
		else
			ended = true
			break
		end
	end
	return prim_addrs
end

--function CFrame.new(x: number, y: number, z: number, R00: number, R01: number, R02: number, R10: number, R11: number, R12: number, R20: number, R21: number, R22: number): CFrame
local function sort(prim_addrs: table)
	for _, prim_addr in pairs(prim_addrs) do
		local pos = memory.readvector(prim_addr, pos_offset)
		local size = memory.readvector(prim_addr, size_offset)
		local rotation_b = memory.readbuffer(prim_addr, rotation_offset)
		local R = {}
		--HERE HERE GET THE INSTANCE INSTEAD OF READING BUFFER AND JUST RETURN THE INSTANCE MUCH EASIER
		for i = 0, 32, 4 do
			table.insert(R, buffer.readf32(rotation_b, i))
		end

		local cframe = CFrame.new(pos.X, pos.Y, pos.Z, table.unpack(R))
		table.insert(parts, {Position = pos, Size = size, CFrame = cframe})
	end
	return parts
end





send_notification("caching static parts, thisll take a while depending on the games size", "info")
sort(cache())
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
	local min_bounds = -half_size
	local max_bounds = half_size
	
	local tmin = 0
	local tmax = 1 
	local hit_normal = vector.create(0, 0, 0)
	
	local axes = {"x", "y", "z"}
	for _, axis in ipairs(axes) do
		local origin_c, direction_c, min_c, max_c
		
		if axis == "x" then
			origin_c, direction_c, min_c, max_c = local_origin.x, local_dir.x, min_bounds.x, max_bounds.x
		elseif axis == "y" then
			origin_c, direction_c, min_c, max_c = local_origin.y, local_dir.y, min_bounds.y, max_bounds.y
		else
			origin_c, direction_c, min_c, max_c = local_origin.z, local_dir.z, min_bounds.z, max_bounds.z
		end
		
		if math.abs(direction_c) < 1e-6 then
			if origin_c < min_c or origin_c > max_c then
				return nil, nil
			end
		else
			local ood = 1.0 / direction_c
			local t1 = (min_c - origin_c) * ood
			local t2 = (max_c - origin_c) * ood
			
			local normal_axis = vector.create(0, 0, 0)
			if direction_c < 0 then
				if axis == "x" then normal_axis = vector.create(1, 0, 0)
				elseif axis == "y" then normal_axis = vector.create(0, 1, 0)
				elseif axis == "z" then normal_axis = vector.create(0, 0, 1) end
			else
				if axis == "x" then normal_axis = vector.create(-1, 0, 0)
				elseif axis == "y" then normal_axis = vector.create(0, -1, 0)
				elseif axis == "z" then normal_axis = vector.create(0, 0, -1) end
			end
			
			if t1 > t2 then t1, t2 = t2, t1 end
			if t1 > tmin then tmin = t1 hit_normal = normal_axis end
			if t2 < tmax then tmax = t2 end
			if tmin > tmax then return nil, nil end
		end
	end
	
	if tmin < 0 or tmin > 1 then return nil, nil end
	return tmin, hit_normal
end

local WorkspaceRaycaster = {}

function WorkspaceRaycaster:Raycast(origin: vector, direction: vector, params: any?, instance_type: string)
	local closest_hit = nil
	local min_dist = math.huge
	
	local ray_length = vector.magnitude(direction)
	if ray_length == 0 then return nil end
	local table_ = workspace:GetDescendants()
	if instance_type == "cached" then
		table_ = parts
	end
	for _, part in ipairs(table_) do
		local pos = part.Position
		local size = part.Size
		local rv = part.CFrame.RightVector
		local uv = part.CFrame.UpVector
		local lv = part.CFrame.LookVector
		local filter_passed = true
		
		if filter_passed then
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
					
					local hit_pos = pos
						+ (rv * local_hit_pos.x) 
						+ (uv * local_hit_pos.y) 
						+ (-lv * local_hit_pos.z)
						
					local world_normal = (rv * local_normal.x) 
						+ (uv * local_normal.y) 
						+ (-lv * local_normal.z)
					
					closest_hit = {
						Position = hit_pos,
						Normal = world_normal,
						Distance = distance,
						
					}
				end
			end
		end
	end
	
	return closest_hit
end

return WorkspaceRaycaster
