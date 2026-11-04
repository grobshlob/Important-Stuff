--!strict

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

function WorkspaceRaycaster:Raycast(origin: vector, direction: vector, params: any?)
	local closest_hit = nil
	local min_dist = math.huge
	
	local ray_length = vector.magnitude(direction)
	if ray_length == 0 then return nil end
	
	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.ClassName ~= "Terrain" then
			local filter_passed = true
			if params and params.FilterDescendantsInstances then
				for _, ignoredInstance in ipairs(params.FilterDescendantsInstances) do
					if part == ignoredInstance or part:IsDescendantOf(ignoredInstance) then
						filter_passed = false
						break
					end
				end
			end
			
			if filter_passed then
				local t, local_normal = determine_hit(
					origin, 
					direction, 
					part.Size, 
					part.Position, 
					part.RightVector, 
					part.UpVector, 
					part.LookVector
				)
				
				if t then
					local distance = t * ray_length
					if distance < min_dist then
						min_dist = distance
						
						local local_origin_rel = origin - part.Position
						local local_orig = vector.create(
							vector.dot(local_origin_rel, part.RightVector), 
							vector.dot(local_origin_rel, part.UpVector), 
							-vector.dot(local_origin_rel, part.LookVector)
						)
						local local_dir_rel = vector.create(
							vector.dot(direction, part.RightVector), 
							vector.dot(direction, part.UpVector), 
							-vector.dot(direction, part.LookVector)
						)
						local local_hit_pos = local_orig + (local_dir_rel * t)
						
						local hit_pos = part.Position 
							+ (part.RightVector * local_hit_pos.x) 
							+ (part.UpVector * local_hit_pos.y) 
							+ (-part.LookVector * local_hit_pos.z)
							
						local world_normal = (part.RightVector * local_normal.x) 
							+ (part.UpVector * local_normal.y) 
							+ (-part.LookVector * local_normal.z)
						
						closest_hit = {
							Instance = part.Name,
							Position = hit_pos,
							Normal = world_normal,
							Distance = distance,
							Parent = part.Parent.Name,
						}
					end
				end
			end
		end
	end
	
	return closest_hit
end

return WorkspaceRaycaster
