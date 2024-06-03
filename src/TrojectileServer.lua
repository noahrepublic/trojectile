--[[
TrojectileServer.lua
on client request to fire, the clients receive a timestamp on when the projectile started according to the server, and has access to each projectile type speeds and whatever.

then to know how far progressed the projectile is for visuals it is just, game.Workspace:GetServerTimeNow() - timestamp
a rollback system would also be easily achievable with this approach for any ping compensation
]]

--> Services

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--> Includes

local Constants = require(script.Parent.Constants)
local Identifiers = require(script.Parent.Identifiers)
local Set = require(script.Parent.Set)
local tConstants = require(script.Parent.tConstants)

local serverNetwork = require(script.Parent.network.server)

--> Variables

local TrojectileServer = {
	_cooldown = 0,
	_cooldowns = {},

	_projectileConfigs = {},
}

local projectiles = Set.new()

local PlayerSerDes = Identifiers.new(Constants.PLAYER_ID_STORAGE_NAME)
local ProjectileTypeSerDes = Identifiers.new(Constants.PROJECTILE_ID_STORAGE_NAME)

--> Functions

local function onRequest(
	player,
	projectileData: {
		origin: Vector3,
		direction: Vector3,
		projectileType: number,
	}
)
	projectileData.projectileType = ProjectileTypeSerDes:deserialize(projectileData.projectileType)
	assert(tConstants.projectileData(projectileData))

	local timestamp = game.Workspace:GetServerTimeNow()

	if
		TrojectileServer._cooldowns[player] == nil
		or timestamp - TrojectileServer._cooldowns[player] >= TrojectileServer._cooldown
	then
		TrojectileServer._cooldowns[player] = timestamp
	else
		return
	end

	local playerPing = player:GetNetworkPing()

	warn(playerPing, playerPing * 1000)

	timestamp -= playerPing

	local projectile = {
		player = player,
		origin = projectileData.origin,
		direction = projectileData.direction,
		projectileType = projectileData.projectileType,

		timestamp = timestamp,
	}

	projectiles:add(projectile)

	local playerSerID = PlayerSerDes:serialize(player.Name)

	serverNetwork.Trojectile_SERVER.FireExcept(player, {
		t = timestamp,
		origin = projectileData.origin,
		direction = projectileData.direction,
		projectileType = ProjectileTypeSerDes:serialize(projectileData.projectileType),
		sender = playerSerID,
	})
end

--> Public Methods

function TrojectileServer:setRatelimit(time)
	TrojectileServer._cooldown = time
end

function TrojectileServer:addProjectileType(
	name,
	config: {
		speed: number,
		dropRate: number, -- how much gravity affects the projectile (0 = no gravity, 1 = full gravity)

		maxTravelTime: number?,
		callback: (hit: Instance, hitPoint: Vector3) -> nil,

		type: {
			method: "Raycast" | "Spherecast" | "Blockcast", -- defaults to raycast
			size: Vector3 | number, -- depends on method
		}?,
	}
)
	assert(tConstants.projectileType(config))
	assert(TrojectileServer._projectileConfigs[name] == nil, "Projectile type already exists" .. debug.traceback())

	config.maxTravelTime = config.maxTravelTime or 10
	config.callback = config.callback or function() end

	TrojectileServer._projectileConfigs[name] = config

	ProjectileTypeSerDes:referenceIdentifier(name)

	return function() -- as far as we need for cleanup, you shouldn't need to have to remove projectile types as you control when to add them
		TrojectileServer._projectileConfigs[name] = nil
		ProjectileTypeSerDes:unreferenceIdentifier(name)
	end
end

--> Connections

--Communicator.OnServerEvent:Connect(onRequest)

serverNetwork.Trojectile_CLIENT.SetCallback(onRequest)

local totalDt = 0

RunService.Heartbeat:Connect(function(dt)
	totalDt += dt

	if totalDt < Constants.jobSteps then
		return
	end

	for projectile in projectiles:iterate() do
		local projectileConfig = TrojectileServer._projectileConfigs[projectile.projectileType]

		if
			projectileConfig == nil
			or (game.Workspace:GetServerTimeNow() - projectile.timestamp >= projectileConfig.maxTravelTime)
		then
			projectiles:remove(projectile)
			continue
		end

		local origin = projectile.origin
			- (Vector3.yAxis * 10 * (game.Workspace:GetServerTimeNow() - projectile.timestamp))
		local newOrigin = projectile.origin + (projectile.direction * projectileConfig.speed * totalDt)

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

			raycastResult =
				workspace:Raycast(origin, projectile.direction * projectileConfig.speed * totalDt, raycastParams)
		end

		projectile.origin = newOrigin

		if raycastResult ~= nil then
			print("hit", raycastResult.Instance, raycastResult.Position)
			--newOrigin = raycastResult.Position

			local instance = Instance.new("Part")
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanQuery = false
			instance.Size = Vector3.new(0.2, 0.2, 0.2)
			instance.Position = raycastResult.Position
			instance.Color = Color3.new(1, 0, 0)
			instance.Parent = workspace

			print(raycastResult.Instance, raycastResult.Position)
			if raycastResult.Instance then
				projectileConfig.callback(raycastResult.Instance, raycastResult.Position)

				projectiles:remove(projectile)
			end -- otherwise, keep going until either hit, or done.
		end
	end

	totalDt = 0
end)

Players.PlayerAdded:Connect(function(player: Player)
	PlayerSerDes:referenceIdentifier(player.Name)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	PlayerSerDes:unreferenceIdentifier(player.Name)
end)

return TrojectileServer
