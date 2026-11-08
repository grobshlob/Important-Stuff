_G.cache = false --recommended for big games
local Workspace_raycast = loadstring(game:HttpGet("https://raw.githubusercontent.com/grobshlob/Important-Stuff/refs/heads/main/Raycast/Module.luau"))()


local pl = game:GetService("Players")
local lp = pl.LocalPlayer
local chara = lp.Character
local hrp = chara:FindFirstChild("HumanoidRootPart")


local origin = hrp.Position + (hrp.CFrame.LookVector * 3)
local direction = hrp.CFrame.LookVector * 50

local params = {
    FilterDescendantsInstances = {chara}
}
--[[
Workspace_raycast:Raycast(origin: Vector3, direction:Vector3, params: table, instance_type: string)
instance_type is only if u cached the game

options
{
    "static_walls" --static walls
    "characters" -- characters
    "grouped" --both static_walls and characters
}
]]
local raycast = Workspace_raycast:Raycast(origin, direction, params)
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
