--!strict
local parts = table.create(100000)
local characters = table.create(50)
local grouped = table.create(#parts + #characters)


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
		local ok, rtti_ = pcall(function() return memory.rtti(prim_addr) end)
		if not ok then continue end
		if rtti_ == "RBX::Primitive" then
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




if _G.cache then
	send_notification("caching static parts, thisll take a while depending on the games size", "info")
	sort(cache())
	print(#parts, #characters, #grouped)
	send_notification("done", "info")
end

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
	if instance_type == "static_walls" then
		table_ = parts
	elseif instance_type == "characters" then
		table_ = characters
	elseif instance_type == "grouped" then
		table_ = grouped
	end
	for i = 1, #table_ do
		local part = table_[i]
		--print(part.Name, part.Parent)
		local filter_passed = nil
		ok, part = pcall(function() return part end)
		local ok1, class = pcall(function() return part.ClassName end)
		if not ok or not ok1 then continue end
		if part.Transparency == 1 then continue end
		if part:IsA("BasePart") and class ~= "Terrain" and class ~= "Seat" then
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
					--print("Intersection:", part.Name, t)
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
--[[ test
local pl = game:GetService("Players")
local lp = pl.LocalPlayer
local chara = lp.Character
local hrp = chara:FindFirstChild("HumanoidRootPart")




local params = {
    FilterDescendantsInstances = {chara}
}
while task.wait(1) do
	local origin = hrp.Position + (hrp.CFrame.LookVector * 3) 
	local direction = hrp.CFrame.LookVector * 50
	local raycast = WorkspaceRaycaster:Raycast(origin, direction, params, "static_walls")
	if raycast then
	  print(raycast)

	    {
	        Normal   = 1, 0, 0
	        Position = 2.1476593017578125, 3.000002384185791, -44.869056701660156
	        Instance = Part
	        Distance = 33.47706544960554
	        Parent   = rare7
	    }

	else
	  print("didnt hit")
	end
end
]]
return WorkspaceRaycaster
