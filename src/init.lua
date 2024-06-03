-- TODO:
-- Detect projectile sizes, not just collision from the raycast ✔
-- Ping compensation from moving sender
-- Zap integration (waiting on Zap to be updated)
-- Bullet drop

--> Services

local RunService = game:GetService("RunService")

--> Includes

if RunService:IsServer() then
	return require(script.TrojectileServer)
else
	return require(script.TrojectileClient)
end
