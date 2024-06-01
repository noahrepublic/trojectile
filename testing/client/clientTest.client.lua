--> Services

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--> Packages

local Packages = ReplicatedStorage.Packages

--> Includes

local Trojectile = require(Packages.trojectile)

local ProjectileTypes = require(ReplicatedStorage.Projectiles)

for name, data in ProjectileTypes do
	Trojectile:addProjectileType(name, data)
end

--> Variables

local player = Players.LocalPlayer


local playerMouse = player:GetMouse()

local projectileModels = {}

local observe = Trojectile:track(function(projectile, position, direction)
	local model

	if not projectileModels[projectile] then
		model = Instance.new("Part")

		projectileModels[projectile] = model
		model.Anchored = true
		model.CanCollide = false

		model.Parent = game.Workspace
	else
		model = projectileModels[projectile]
	end

	for i = 0, 1, 0.05 do
		model.CFrame = model.CFrame:Lerp(CFrame.new(position, direction * Vector3.new(1, 1, 0)) , i)
	end

end)

Trojectile:cleanup(function(projectile)
	if projectileModels[projectile] then
		projectileModels[projectile]:Destroy()
		projectileModels[projectile] = nil
	end
end)

ContextActionService:BindAction("Fire", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		local origin = player.Character.Head.Position
		local direction = (playerMouse.Hit.Position - origin).Unit

		local projectileType = "testProjectile"

		Trojectile:Fire({ origin = origin, direction = direction, projectileType = projectileType })
	end
end, false, Enum.KeyCode.F)

RunService.RenderStepped:Connect(function()
	observe()
end)
