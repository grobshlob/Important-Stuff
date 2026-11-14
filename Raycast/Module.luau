
--!strict
_G.cache = true

local parts = {}
local characters = table.create(50)
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

local sector_layouts = {
	[1] = {1, 1},
	[2] = {1, 2},
	[3] = {2, 2},
	[4] = {2, 4},
}

local function create_subsectors(
	center: Vector3,
	quadrant_size: number,
	subdivisions_x: number,
	subdivisions_z: number
)
	local subsectors = {}

	local sub_size_x = quadrant_size / subdivisions_x
	local sub_size_z = quadrant_size / subdivisions_z

	local start_x = quadrant_size / 2 - sub_size_x / 2
	local start_z = quadrant_size / 2 - sub_size_z / 2

	local index = 1

	for x = 0, subdivisions_x - 1 do
		for z = 0, subdivisions_z - 1 do
			local offset_x = -start_x + x * sub_size_x
			local offset_z = -start_z + z * sub_size_z

			subsectors["sector" .. index] = {
				center = center + Vector3.new(offset_x, 0, offset_z),
				size = Vector3.new(sub_size_x, 0, sub_size_z),
				parts = {},
			}

			index += 1
		end
	end

	return subsectors
end

local function sort(primitive_addresses, optimization_level)
	local total = #primitive_addresses

	local opt_level = total > 20000 and 4 or optimization_level
	opt_level = math.clamp(opt_level or 1, 1, 4)

	local layout = sector_layouts[opt_level]
	local subdivisions_x = layout[1]
	local subdivisions_z = layout[2]

	local root = get_root()

	if not root then
		return {}
	end

	local root_position = root.Position
	local root_x = root_position.X
	local root_z = root_position.Z

	local root_vector = vector.create(
		root_x,
		root_position.Y,
		root_z
	)

	local max_dist = 0
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

			local cf = instance.CFrame
			local position = cf.Position

			local native_position = vector.create(
				position.X,
				position.Y,
				position.Z
			)

			local size = instance.Size

			return {
				instance = instance,

				position = native_position,
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
			}
		end)

		if not success or not entry then
			continue
		end

		cached_parts[#cached_parts + 1] = entry

		local distance = vector.magnitude(root_vector - entry.position)

		if distance > max_dist then
			max_dist = distance
		end
	end

	max_dist = math.max(max_dist, 1)

	local quadrant_size = max_dist
	local half_quad = quadrant_size / 2

	local quadrant_offsets = {
		Sector_1 = Vector3.new(half_quad, 0, half_quad),
		Sector_2 = Vector3.new(-half_quad, 0, half_quad),
		Sector_3 = Vector3.new(half_quad, 0, -half_quad),
		Sector_4 = Vector3.new(-half_quad, 0, -half_quad),
	}

	local sectors = {}

	for name, quadrant_offset in pairs(quadrant_offsets) do
		local quadrant_center = root_position + quadrant_offset

		sectors[name] = {
			center = quadrant_center,
			children_amt = subdivisions_x * subdivisions_z,
			size = Vector3.new(quadrant_size, 0, quadrant_size),

			children = create_subsectors(
				quadrant_center,
				quadrant_size,
				subdivisions_x,
				subdivisions_z
			),
		}
	end

	local sub_size_x = quadrant_size / subdivisions_x
	local sub_size_z = quadrant_size / subdivisions_z

	for i = 1, #cached_parts do
		local entry = cached_parts[i]
		local position = entry.position3

		local dx = position.X - root_x
		local dz = position.Z - root_z

		local quadrant

		if dx >= 0 then
			quadrant = dz >= 0 and sectors.Sector_1 or sectors.Sector_3
		else
			quadrant = dz >= 0 and sectors.Sector_2 or sectors.Sector_4
		end

		local x_index = math.floor(math.abs(dx) / sub_size_x)
		local z_index = math.floor(math.abs(dz) / sub_size_z)

		if dx < 0 then
			x_index = subdivisions_x - 1 - x_index
		end

		if dz < 0 then
			z_index = subdivisions_z - 1 - z_index
		end

		x_index = math.clamp(x_index, 0, subdivisions_x - 1)
		z_index = math.clamp(z_index, 0, subdivisions_z - 1)

		local sector_index = x_index * subdivisions_z + z_index + 1
		local sector = quadrant.children["sector" .. sector_index]

		if sector then
			sector.parts[#sector.parts + 1] = entry
		end
	end

	return sectors
end

send_notification("Caching static parts. This may take a while.", "info")

parts = sort(cache(), 3)

local total_cached = 0

for _, quadrant in pairs(parts) do
	for _, sector in pairs(quadrant.children) do
		total_cached += #sector.parts
	end
end

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
	min_dist
)
	local filter = params and params.FilterDescendantsInstances

	for i = 1, #table_ do
		local entry = table_[i]
		local part = entry.instance

		if not part or not part.Parent then
			continue
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
): boolean

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
			return false
		end
	else
		local t1 = (min_x - ox) / dx
		local t2 = (max_x - ox) / dx

		if t1 > t2 then
			t1, t2 = t2, t1
		end

		t_min = math.max(t_min, t1)
		t_max = math.min(t_max, t2)
	end

	if math.abs(dz) < 1e-8 then
		if oz < min_z or oz > max_z then
			return false
		end
	else
		local t1 = (min_z - oz) / dz
		local t2 = (max_z - oz) / dz

		if t1 > t2 then
			t1, t2 = t2, t1
		end

		t_min = math.max(t_min, t1)
		t_max = math.min(t_max, t2)
	end

	return t_min <= t_max
end

local function cast_sectors(
	sectors,
	origin,
	direction,
	params,
	ray_length,
	closest_hit,
	min_dist
)
	for _, quadrant in pairs(sectors) do
		local max_t = math.min(1, min_dist / ray_length)

		if not intersects_sector(
			origin,
			direction,
			quadrant.center,
			quadrant.size,
			max_t
		) then
			continue
		end

		for _, sector in pairs(quadrant.children) do
			max_t = math.min(1, min_dist / ray_length)

			if not intersects_sector(
				origin,
				direction,
				sector.center,
				sector.size,
				max_t
			) then
				continue
			end

			closest_hit, min_dist = cast(
				sector.parts,
				origin,
				direction,
				params,
				ray_length,
				closest_hit,
				min_dist
			)
		end
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
		closest_hit, min_dist = cast_sectors(
			parts,
			origin_vector,
			direction_vector,
			params,
			ray_length,
			closest_hit,
			min_dist
		)
	elseif instance_type == "characters" then
		closest_hit, min_dist = cast(
			characters,
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
