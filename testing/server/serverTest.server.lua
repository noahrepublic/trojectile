--> Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Packages

local Packages = ReplicatedStorage.Packages

--> Includes

local Trojectile = require(Packages.trojectile)

local ProjectileTypes = require(ReplicatedStorage.Projectiles)

for name, data in ProjectileTypes do
	Trojectile:addProjectileType(name, data)
end
