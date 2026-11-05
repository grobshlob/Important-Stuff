--!strict
local parts = {}
local models = {}
local models_folder = {}

local json_ = game:HttpGet("https://offsets.imtheo.lol/offsets.json")
local decoded = crypt.json.decode(json_)
local offsets = decoded.Offsets
local b_p = offsets.BasePart --bp omgggggg
local prim = b_p.Primitive
local flags = offsets.Primitive.Flags
local prim_flags = offsets.PrimitiveFlags
local anchored = prim_flags.Anchored

local function anchor_check(instance: BasePart)
	local part_prim = memory.readu64(instance, prim)
	local flags = memory.readu64(part_prim, flags)
	local anchored = memory.readu8(flags, anchored)
	if anchored == 0 then
		return false
	elseif anchored == 1 then
		return true
	end
end


local function find_folder(instance)
	local p = instance.Parent
	if p.ClassName == "Folder" then
		return p
	elseif p.ClassName == "Workspace" then
		return workspace
	else
		return find_folder(p)
	end
end

local function cache()
	for _, instance in pairs(game.Workspace:GetDescendants()) do
		if instance:IsA("BasePart") and instance.ClassName ~= "Terrain" and instance.ClassName ~= "Seat" and not instance:FindFirstChild("Humanoid") then
			if anchor_check then
				local pos = instance.Position
				local size = instance.Size
				local right_vec = instance.RightVector
				local up_vec = instance.UpVector
				local look_vec = instance.LookVector
				table.insert(parts, {
					pos = pos,
					instance = instance,
					size = size,
					right_vec = right_vec,
					up_vec = up_vec,
					look_vec = look_vec
				})
			end
		elseif instance:IsA("Model") and instance:FindFirstChild("Humanoid") then
			local folder = find_folder(instance)
			local instance = instance.PrimaryPart
			if not instance then return end
			--finish this bla bla bla
		end
	end
end	
if _G.cache then
	send_notification("caching static parts, thisll take a while depending on the games size", "info")
	cache()
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
	if instance_type == "BaseParts" then
		table_ = parts
	elseif instance_type == "Models" then
		table_ = models
	elseif instance_type == "all" then
		table_ = grouped
	end
	for _, part in ipairs(table_) do
		local pos = part.pos
		local size = part.size
		local rv = part.right_vec
		local uv = part.up_vec
		local lv = part.look_vec
		local instance = part.instance
		local filter_passed = true
		if params and params.FilterDescendantsInstances then
			for _, ignoredInstance in ipairs(params.FilterDescendantsInstances) do
				if instance == ignoredInstance or instance:IsDescendantOf(ignoredInstance) then
					filter_passed = false
					break
				end
			end
		end
		
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
						Instance = instance,
						Parent = instance.Parent,
						Position = hit_pos,
						Normal = world_normal,
						Distance = distance,
						Instance_name = instance.Name,
						Parent_name = instance.Parent.Name,
						
					}
				end
			end
		end
	end
	
	return closest_hit
end

return WorkspaceRaycaster
