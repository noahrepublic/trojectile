-- TODO:
-- Detect projectile sizes, not just collision from the raycast ✔
-- Ping compensation from moving sender
-- Zap integration (waiting on Zap to be updated)
-- Bullet drop

--> Services

local RunService = game:GetService("RunService")

--> Includes

local Constants = require(script.Constants)

if RunService:IsServer() then
	local Communicator = Instance.new("UnreliableRemoteEvent")
	Communicator.Name = Constants.COMMUNICATOR_NAME
	Communicator.Parent = script
end

if RunService:IsServer() then
	return require(script.TrojectileServer)
else
	return require(script.TrojectileClient)
end
