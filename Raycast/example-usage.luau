_G.cache = true --recommended
local Workspace_raycast = loadstring(game:HttpGet("https://raw.githubusercontent.com/grobshlob/Important-Stuff/refs/heads/main/Raycast/Module.luau"))()

local pl = game:GetService("Players")
local lp = pl.LocalPlayer
local chara = lp.Character
local hrp = chara:FindFirstChild("HumanoidRootPart")


--[[
Workspace_raycast:Raycast(origin: Vector3, direction:Vector3, params: table, instance_type: string)
instance_type is only if u cached the game

options
{
    "static_walls" --static walls
    "characters" -- characters (temp down)
    "grouped" --both static_walls and characters
}
]]

local params = {
    FilterDescendantsInstances = {chara}
}
while task.wait(0.1) do
	local start = os.clock()
	local origin = hrp.Position + (hrp.CFrame.LookVector * 3) 
	local direction = hrp.CFrame.LookVector * 50
	local raycast = Workspace_raycast:Raycast(origin, direction, params, "static_walls")
	if raycast then
	  print(raycast, os.clock() - start)
	else
	  print("didnt hit")
	end
end
