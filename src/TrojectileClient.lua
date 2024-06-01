--[[
    on client request to fire, the clients receive a timestamp on when the projectile started according to the server, and has access to each projectile type speeds and whatever.

    then to know how far progressed the projectile is for visuals it is just, game.Workspace:GetServerTimeNow() - timestamp
    a rollback system would also be easily achievable with this approach for any ping compensation
]]

--> Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--> Includes

local Constants = require(script.Parent.Constants)
local Set = require(script.Parent.Set)
local tConstants = require(script.Parent.tConstants)

local clientNetwork = require(script.Parent.network.client)

--> Wally Dependencies

local ecr = require(script.Parent.Parent.ecr)

--> Variables

local player = Players.LocalPlayer

local Trojectile = {
	_projectileConfigs = {},

	_projectiles = Set.new(),
}


local Position = ecr.component() :: Vector3
local Direction = ecr.component() :: Vector3
local projectiles = ecr.registry()

--> Functions

local function onRequest(projectileData)
	local projectileConfig = Trojectile._projectileConfigs[projectileData.projectileType] -- string indexes are ok here. zap does not serialize struct keys

	if projectileConfig == nil then
		return
	end
	
	--[[
        timestamp,
		compensatedPosition,
		projectileData.direction,
		projectileData.projectileType,
    ]]

	local id = projectiles:create()

	local projectile = {
		t = projectileData.t - player:GetNetworkPing(),
		origin = projectileData.origin,
		direction = projectileData.direction,
		projectileType = projectileData.projectileType,
		player = projectileData.sender,

		id = id,
	}

	projectiles:set(id, Position, projectileData.origin)
	projectiles:set(id, Direction, projectileData.direction)
	Trojectile._projectiles:add(projectile)
end

--> Public Methods

function Trojectile:Fire(projectileData: {
	origin: Vector3,
	direction: Vector3,
	projectileType: string,
})
	assert(tConstants.projectileData(projectileData))

	onRequest({
		t = game.Workspace:GetServerTimeNow() + player:GetNetworkPing(),
		origin = projectileData.origin,
		direction = projectileData.direction,
		projectileType = projectileData.projectileType,
		sender = player,
	})

	-- Communicator:FireServer(projectileData) -- serDes

	clientNetwork.Trojectile_CLIENT.Fire(projectileData)
end

function Trojectile:addProjectileType(
	name,
	config: {
		speed: number,
		dropRate: number,

		maxTravelTime: number?,
		callback: (hit: Instance, hitPoint: Vector3) -> nil,

		type: {
			method: "Raycast" | "Spherecast" | "Blockcast", -- defaults to raycast
			size: Vector3 | number, -- depends on method
		}?,
	}
)
	assert(tConstants.projectileType(config))
	assert(Trojectile._projectileConfigs[name] == nil, "Projectile type already exists" .. debug.traceback())

	config.maxTravelTime = config.maxTravelTime or 10
	config.callback = config.callback or function() end

	Trojectile._projectileConfigs[name] = config

	return function()
		Trojectile._projectileConfigs[name] = nil
	end
end

function Trojectile:track(callback)
	local observer = projectiles:track(Position)

	return function()
		for projectile, position in observer do
			callback(projectile, position, projectiles:get(projectile, Direction))
		end
	end
end

function Trojectile:cleanup(callback)
	projectiles:on_remove(Position):connect(callback)
end

--> Connections

-- Communicator.OnClientEvent:Connect(function(projectileData)
-- 	if projectileData[5] == player then
-- 		return
-- 	end

-- 	onRequest(projectileData)
-- end)

clientNetwork.Trojectile_SERVER.SetCallback(onRequest)

local totalDt = 0

RunService.RenderStepped:Connect(function(dt)
	totalDt += dt

	if totalDt < Constants.jobSteps then
		return
	end

	for projectile in Trojectile._projectiles:iterate() do
		local projectileConfig = Trojectile._projectileConfigs[projectile.projectileType]

		if projectileConfig == nil then
			continue
		end

		local projectileTravelTime = game.Workspace:GetServerTimeNow() - projectile.t

		if projectileTravelTime > projectileConfig.maxTravelTime then
			Trojectile._projectiles:remove(projectile)
			projectiles:remove(projectile.id, Position)
			projectiles:destroy(projectile.id)
			continue
		end

		local origin = projectile.origin - (Vector3.yAxis * 1 * projectileTravelTime)
		local projectilePosition = origin + (projectile.direction * projectileConfig.speed * totalDt)

		local projectileType = projectileConfig.type

		local method = if projectileType ~= nil
				and (projectileType.method == "Spherecast" or projectileType.method == "Blockcast")
			then projectileType.method
			else "Raycast"

		local raycastParams = RaycastParams.new()

		raycastParams.FilterDescendantsInstances = { projectile.player.Character }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude

		local raycastResult

		if
			projectileType ~= nil
			and (projectileType.method == "Spherecast" or projectileType.method == "Blockcast")
			and projectileType.size
		then
			raycastResult = workspace[method](
				workspace,
				if projectileType.method == "Blockcast" then CFrame.new(origin) else origin,
				projectileType.size,
				projectile.direction * projectileConfig.speed * totalDt,
				raycastParams
			)
		else
			if projectileConfig.method then
				warn(
					"Projectile type has a method that is not supported by the server, defaulting to use Raycast. Valid methods: Spherecast, or Blockcast"
				)
			end

			raycastResult = workspace:Raycast(
				origin,
				projectile.direction * projectileConfig.speed * totalDt,
				raycastParams
			)
		end

		projectile.origin = projectilePosition
		projectiles:set(projectile.id, Position, projectilePosition - (Vector3.yAxis * projectileConfig
		.dropRate * projectileTravelTime))

		if raycastResult and raycastResult.Instance ~= nil then
			projectileConfig.callback(raycastResult.Instance, raycastResult.Position)

			Trojectile._projectiles:remove(projectile)

			projectiles:remove(projectile.id, Position)
			projectiles:destroy(projectile.id)
		end
		-- projectiles:remove(projectile.id)
	end

	totalDt = 0
end)

return Trojectile
