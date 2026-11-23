
--!strict
_G.cache = true

local parts: any = nil
local total_cached = 0
local characters_parts = table.create(50)
local grouped = {}

local Players = game:GetService("Players")

local lp = Players.LocalPlayer
local ws = workspace

local json_ = game:HttpGet("https://offsets.imtheo.lol/offsets.json")
local decoded = crypt.json.decode(json_)
local offsets = decoded.Offsets

local prim_main = offsets.Primitive
local world_offset = offsets.Workspace.World
local prim_holder_offset = offsets.World.Primitives

local primitive_to_part_offset = 0x218

local function get_root()
	local character = lp.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

local function to_vector3(v: vector): Vector3
	return Vector3.new(v.x, v.y, v.z)
end

local function is_character(part)
	for _, player in Players:GetChildren() do
		local character = player.Character

		if character and part:IsDescendantOf(character) then
			return true
		end
	end

	return false
end

local function cache()
	local primitive_addresses = {}

	local world_address = memory.readu64(ws, world_offset)
	local holder_address = memory.readu64(world_address, prim_holder_offset)

	for offset = 0, 0xFFFFFFFF, 8 do
		local primitive_address = memory.readu64(holder_address, offset)

		local success, rtti = pcall(function()
			return memory.rtti(primitive_address)
		end)

		if not success or rtti ~= "RBX::Primitive" then
			break
		end

		primitive_addresses[#primitive_addresses + 1] = primitive_address
	end

	return primitive_addresses
end

local max_parts = 256
local max_depth = 8
local min_size = 16

local function overlaps(entry, min_x, min_z, max_x, max_z)
    local position = entry.position3

    return
        position.X + entry.bounds_x >= min_x
        and position.X - entry.bounds_x <= max_x
        and position.Z + entry.bounds_z >= min_z
        and position.Z - entry.bounds_z <= max_z
end

local function build_node(entries, min_x, min_z, max_x, max_z, depth)
    local center_x = (min_x + max_x) * 0.5
    local center_z = (min_z + max_z) * 0.5

    local node = {
        center = Vector3.new(center_x, 0, center_z),
        size = Vector3.new(max_x - min_x, 0, max_z - min_z),
        parts = entries,
    }

    if #entries <= max_parts
        or depth >= max_depth
        or (max_x - min_x <= min_size and max_z - min_z <= min_size) then
        return node
    end

    local bounds = {
        {min_x, min_z, center_x, center_z},
        {center_x, min_z, max_x, center_z},
        {min_x, center_z, center_x, max_z},
        {center_x, center_z, max_x, max_z},
    }

    local children = {{}, {}, {}, {}}

    for i = 1, #entries do
        local entry = entries[i]

        for j = 1, 4 do
            local b = bounds[j]

            if overlaps(entry, b[1], b[2], b[3], b[4]) then
                children[j][#children[j] + 1] = entry
            end
        end
    end

    local largest = 0

    for i = 1, 4 do
        largest = math.max(largest, #children[i])
    end

    if largest >= #entries then
        return node
    end

    node.parts = nil
    node.children = {}

    for i = 1, 4 do
        if #children[i] > 0 then
            local b = bounds[i]

            node.children[#node.children + 1] = build_node(
                children[i],
                b[1],
                b[2],
                b[3],
                b[4],
                depth + 1
            )
        end
    end

    return node
end

local function sort(primitive_addresses)
    local total = #primitive_addresses
    local cached_parts = table.create(total)

    for i = 1, total do
        local success, entry = pcall(function()
            local part_address = memory.readu64(
                primitive_addresses[i],
                primitive_to_part_offset
            )

            local instance = pointer_to_userdata(part_address)

            if not instance or not instance:IsA("BasePart") then
                return nil
            end
            
            if is_character(instance) then
                return nil
            end

            local cf = instance.CFrame
            local position = cf.Position
            local size = instance.Size

            local half_x = size.X * 0.5
            local half_y = size.Y * 0.5
            local half_z = size.Z * 0.5

            local bounds_x =
                math.abs(cf.RightVector.X) * half_x
                + math.abs(cf.UpVector.X) * half_y
                + math.abs(cf.LookVector.X) * half_z

            local bounds_z =
                math.abs(cf.RightVector.Z) * half_x
                + math.abs(cf.UpVector.Z) * half_y
                + math.abs(cf.LookVector.Z) * half_z

            return {
                instance = instance,

                position = vector.create(
                    position.X,
                    position.Y,
                    position.Z
                ),

                position3 = position,

                size = vector.create(
                    size.X,
                    size.Y,
                    size.Z
                ),

                right = vector.create(
                    cf.RightVector.X,
                    cf.RightVector.Y,
                    cf.RightVector.Z
                ),

                up = vector.create(
                    cf.UpVector.X,
                    cf.UpVector.Y,
                    cf.UpVector.Z
                ),

                look = vector.create(
                    cf.LookVector.X,
                    cf.LookVector.Y,
                    cf.LookVector.Z
                ),

                bounds_x = bounds_x,
                bounds_z = bounds_z,
            }
        end)

        if not success or not entry then
            continue
        end

        cached_parts[#cached_parts + 1] = entry
    end

    if #cached_parts == 0 then
        return nil, 0
    end

    local min_x = math.huge
    local min_z = math.huge
    local max_x = -math.huge
    local max_z = -math.huge

    for i = 1, #cached_parts do
        local entry = cached_parts[i]
        local position = entry.position3

        min_x = math.min(min_x, position.X - entry.bounds_x)
        min_z = math.min(min_z, position.Z - entry.bounds_z)
        max_x = math.max(max_x, position.X + entry.bounds_x)
        max_z = math.max(max_z, position.Z + entry.bounds_z)
    end

    if max_x - min_x < 1 then
        min_x -= 0.5
        max_x += 0.5
    end

    if max_z - min_z < 1 then
        min_z -= 0.5
        max_z += 0.5
    end

    return build_node(
        cached_parts,
        min_x,
        min_z,
        max_x,
        max_z,
        0
    ), #cached_parts
end

local function update_characters()
	table.clear(characters_parts)

	for _, player in Players:GetChildren() do
		local character = player.Character

		if not character then
			continue
		end

		for _, instance in character:GetDescendants() do
			if not instance:IsA("BasePart") then
				continue
			end

			local cf = instance.CFrame
			local position = cf.Position
			local size = instance.Size

			table.insert(characters_parts, {
				instance = instance,

				position = vector.create(position.X, position.Y, position.Z),
				size = vector.create(size.X, size.Y, size.Z),

				right = vector.create(cf.RightVector.X, cf.RightVector.Y, cf.RightVector.Z),
				up = vector.create(cf.UpVector.X, cf.UpVector.Y, cf.UpVector.Z),
				look = vector.create(cf.LookVector.X, cf.LookVector.Y, cf.LookVector.Z),
			})
		end
	end
end


send_notification("Caching static parts. This may take a while.", "info")

parts, total_cached = sort(cache())

print("Cached parts:", total_cached)
send_notification("Done", "info")

local function determine_hit(
	origin: vector,
	direction: vector,
	part_size: vector,
	part_position: vector,
	right_vec: vector,
	up_vec: vector,
	look_vec: vector
): (number?, vector?)

	local relative_position = origin - part_position

	local local_origin = vector.create(
		vector.dot(relative_position, right_vec),
		vector.dot(relative_position, up_vec),
		-vector.dot(relative_position, look_vec)
	)

	local local_direction = vector.create(
		vector.dot(direction, right_vec),
		vector.dot(direction, up_vec),
		-vector.dot(direction, look_vec)
	)

	local half_size = part_size * 0.5
	local min_bounds = -half_size
	local max_bounds = half_size

	local t_min = 0
	local t_max = 1

	local hit_normal = vector.create(0, 0, 0)

	local function check_axis(
		origin_component,
		direction_component,
		min_component,
		max_component,
		normal_axis
	)
		if math.abs(direction_component) < 1e-6 then
			if origin_component < min_component
				or origin_component > max_component then
				return false
			end

			return true
		end

		local inverse_direction = 1 / direction_component

		local t1 = (min_component - origin_component) * inverse_direction
		local t2 = (max_component - origin_component) * inverse_direction

		local normal = normal_axis

		if t1 > t2 then
			t1, t2 = t2, t1
			normal = -normal
		end

		if t1 > t_min then
			t_min = t1
			hit_normal = normal
		end

		t_max = math.min(t_max, t2)

		return t_min <= t_max
	end

	if not check_axis(
		local_origin.x,
		local_direction.x,
		min_bounds.x,
		max_bounds.x,
		vector.create(-1, 0, 0)
	) then
		return nil, nil
	end

	if not check_axis(
		local_origin.y,
		local_direction.y,
		min_bounds.y,
		max_bounds.y,
		vector.create(0, -1, 0)
	) then
		return nil, nil
	end

	if not check_axis(
		local_origin.z,
		local_direction.z,
		min_bounds.z,
		max_bounds.z,
		vector.create(0, 0, -1)
	) then
		return nil, nil
	end

	if t_min < 0 or t_min > 1 then
		return nil, nil
	end

	return t_min, hit_normal
end

local function cast(
	table_,
	origin,
	direction,
	params,
	ray_length,
	closest_hit,
	min_dist,
	seen
)
	local filter = params and params.FilterDescendantsInstances

	for i = 1, #table_ do
		local entry = table_[i]
		local part = entry.instance

		if not part or not part.Parent then
			continue
		end

		if seen and seen[part] then
			continue
		end

		if seen then
			seen[part] = true
		end

		if part.Transparency >= 1 then
			continue
		end

		if filter then
			local ignored_part = false

			for j = 1, #filter do
				local ignored = filter[j]

				if part == ignored or part:IsDescendantOf(ignored) then
					ignored_part = true
					break
				end
			end

			if ignored_part then
				continue
			end
		end

		local t, local_normal = determine_hit(
			origin,
			direction,
			entry.size,
			entry.position,
			entry.right,
			entry.up,
			entry.look
		)

		if not t then
			continue
		end

		local distance = t * ray_length

		if distance >= min_dist then
			continue
		end

		min_dist = distance

		local hit_position = origin + direction * t

		local world_normal =
			entry.right * local_normal.x
			+ entry.up * local_normal.y
			- entry.look * local_normal.z

		closest_hit = {
			Position = to_vector3(hit_position),
			Normal = to_vector3(world_normal),
			Distance = distance,
			Instance = part,
			Parent = part.Parent,
			I_Name = part.Name,
			I_Class = part.ClassName,
		}
	end

	return closest_hit, min_dist
end

local function intersects_sector(
    origin: vector,
    direction: vector,
    center: Vector3,
    size: Vector3,
    max_t: number
): number?

    local half = size * 0.5

    local min_x = center.X - half.X
    local max_x = center.X + half.X
    local min_z = center.Z - half.Z
    local max_z = center.Z + half.Z

    local t_min = 0
    local t_max = max_t

    local ox, oz = origin.x, origin.z
    local dx, dz = direction.x, direction.z

    if math.abs(dx) < 1e-8 then
        if ox < min_x or ox > max_x then
            return nil
        end
    else
        local t1 = (min_x - ox) / dx
        local t2 = (max_x - ox) / dx

        if t1 > t2 then
            t1, t2 = t2, t1
        end

        t_min = math.max(t_min, t1)
        t_max = math.min(t_max, t2)

        if t_min > t_max then
            return nil
        end
    end

    if math.abs(dz) < 1e-8 then
        if oz < min_z or oz > max_z then
            return nil
        end
    else
        local t1 = (min_z - oz) / dz
        local t2 = (max_z - oz) / dz

        if t1 > t2 then
            t1, t2 = t2, t1
        end

        t_min = math.max(t_min, t1)
        t_max = math.min(t_max, t2)

        if t_min > t_max then
            return nil
        end
    end

    return t_min
end

local function cast_quadtree(
    node,
    origin,
    direction,
    params,
    ray_length,
    closest_hit,
    min_dist,
    seen
)
    if not node then
        return closest_hit, min_dist
    end

    local max_t = math.min(1, min_dist / ray_length)

    local entry_t = intersects_sector(
        origin,
        direction,
        node.center,
        node.size,
        max_t
    )

    if not entry_t then
        return closest_hit, min_dist
    end

    if not node.children then
        return cast(
            node.parts,
            origin,
            direction,
            params,
            ray_length,
            closest_hit,
            min_dist,
            seen
        )
    end

    local intersected = {}

    for i = 1, #node.children do
        local child = node.children[i]

        local child_entry = intersects_sector(
            origin,
            direction,
            child.center,
            child.size,
            math.min(1, min_dist / ray_length)
        )

        if child_entry then
            intersected[#intersected + 1] = {
                node = child,
                entry = child_entry,
            }
        end
    end

    table.sort(intersected, function(a, b)
        return a.entry < b.entry
    end)

    for i = 1, #intersected do
        local child = intersected[i]

        if child.entry > math.min(1, min_dist / ray_length) then
            break
        end

        closest_hit, min_dist = cast_quadtree(
            child.node,
            origin,
            direction,
            params,
            ray_length,
            closest_hit,
            min_dist,
            seen
        )
    end

    return closest_hit, min_dist
end

local WorkspaceRaycaster = {}

function WorkspaceRaycaster:Raycast(
	origin: Vector3,
	direction: Vector3,
	params: any?,
	instance_type: string
)
	local closest_hit = nil
	local min_dist = math.huge

	local origin_vector = vector.create(
		origin.X,
		origin.Y,
		origin.Z
	)

	local direction_vector = vector.create(
		direction.X,
		direction.Y,
		direction.Z
	)

	local ray_length = vector.magnitude(direction_vector)

	if ray_length == 0 then
		return nil
	end

	if instance_type == "static_walls" then
		closest_hit, min_dist = cast_quadtree(
			parts,
			origin_vector,
			direction_vector,
			params,
			ray_length,
			closest_hit,
			min_dist,
			{}
		)
	elseif instance_type == "characters" then
        update_characters()
		closest_hit, min_dist = cast(
			characters_parts,
			origin_vector,
			direction_vector,
			params,
			ray_length,
			closest_hit,
			min_dist
		)
	elseif instance_type == "grouped" then
		closest_hit, min_dist = cast(
			grouped,
			origin_vector,
			direction_vector,
			params,
			ray_length,
			closest_hit,
			min_dist
		)
	else
		return nil
	end

	return closest_hit
end
--[[
local last_hit = nil

task.spawn(function()
	while task.wait(0.1) do
		local chara = lp.Character
		local hrp = chara and chara:FindFirstChild("HumanoidRootPart")

		if not hrp then
			last_hit = nil
			_G.last_hit = nil
			continue
		end

		local params = {
			FilterDescendantsInstances = {chara}
		}

		local origin = hrp.Position + hrp.CFrame.LookVector * 3
		local direction = hrp.CFrame.LookVector * 50
		local start = os.clock()
		last_hit = WorkspaceRaycaster:Raycast(
			origin,
			direction,
			params,
			"static_walls"
		)

		print(last_hit)
		print(os.clock() - start)
	end
end)
]]
return WorkspaceRaycaster
