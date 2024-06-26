--!native
--!optimize 2
--!nocheck
--!nolint
--#selene: allow(unused_variable, shadowing, incorrect_standard_library_use)
-- Server generated by Zap v0.6.3 (https://github.com/red-blox/zap)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local outgoing_buff: buffer
local outgoing_used: number
local outgoing_size: number
local outgoing_inst: { Instance }
local outgoing_apos: number

local incoming_buff: buffer
local incoming_read: number
local incoming_inst: { Instance }
local incoming_ipos: number

-- thanks to https://dom.rojo.space/binary.html#cframe
local CFrameSpecialCases = {
	CFrame.Angles(0, 0, 0),
	CFrame.Angles(math.rad(90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(180)),
	CFrame.Angles(math.rad(-90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(90)),
	CFrame.Angles(0, math.rad(90), math.rad(90)),
	CFrame.Angles(0, 0, math.rad(90)),
	CFrame.Angles(0, math.rad(-90), math.rad(90)),
	CFrame.Angles(math.rad(-90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(-90), 0),
	CFrame.Angles(math.rad(90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(90), math.rad(180)),
	CFrame.Angles(0, math.rad(-90), math.rad(180)),
	CFrame.Angles(0, math.rad(180), math.rad(0)),
	CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(180)),
	CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(-90)),
	CFrame.Angles(0, math.rad(-90), math.rad(-90)),
	CFrame.Angles(0, math.rad(-180), math.rad(-90)),
	CFrame.Angles(0, math.rad(90), math.rad(-90)),
	CFrame.Angles(math.rad(90), math.rad(90), 0),
	CFrame.Angles(0, math.rad(90), 0),
	CFrame.Angles(math.rad(-90), math.rad(90), 0),
}

local function alloc(len: number)
	if outgoing_used + len > outgoing_size then
		while outgoing_used + len > outgoing_size do
			outgoing_size = outgoing_size * 2
		end

		local new_buff = buffer.create(outgoing_size)
		buffer.copy(new_buff, 0, outgoing_buff, 0, outgoing_used)

		outgoing_buff = new_buff
	end

	outgoing_apos = outgoing_used
	outgoing_used = outgoing_used + len

	return outgoing_apos
end

local function read(len: number)
	local pos = incoming_read
	incoming_read = incoming_read + len

	return pos
end

local function save()
	return {
		buff = outgoing_buff,
		used = outgoing_used,
		size = outgoing_size,
		inst = outgoing_inst,
	}
end

local function load(data: {
	buff: buffer,
	used: number,
	size: number,
	inst: { Instance },
})
	outgoing_buff = data.buff
	outgoing_used = data.used
	outgoing_size = data.size
	outgoing_inst = data.inst
end

local function load_empty()
	outgoing_buff = buffer.create(64)
	outgoing_used = 0
	outgoing_size = 64
	outgoing_inst = {}
end

load_empty()

local types = {}
local Players = game:GetService("Players")

if RunService:IsClient() then
	error("Cannot use the server module on the client!")
end

local reliable = ReplicatedStorage:FindFirstChild("ZAP_RELIABLE")
if reliable == nil then
	reliable = Instance.new("RemoteEvent")
	reliable.Name = "ZAP_RELIABLE"
	reliable.Parent = ReplicatedStorage
end

local unreliable = ReplicatedStorage:FindFirstChild("ZAP_UNRELIABLE")
if unreliable == nil then
	unreliable = Instance.new("UnreliableRemoteEvent")
	unreliable.Name = "ZAP_UNRELIABLE"
	unreliable.Parent = ReplicatedStorage
end

local player_map = {}

local function load_player(player: Player)
	if player_map[player] then
		load(player_map[player])
	else
		load_empty()
	end
end

Players.PlayerRemoving:Connect(function(player)
	player_map[player] = nil
end)
export type clientProjectileData = ({
	origin: (Vector3),
	direction: (Vector3),
	projectileType: (number),
})
function types.write_clientProjectileData(value: clientProjectileData)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.X)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.Y)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.Z)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.X)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.Y)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.Z)
	alloc(1)
	buffer.writeu8(outgoing_buff, outgoing_apos, value.projectileType)
end
function types.read_clientProjectileData()
	local value;
	value = {}
	value.origin = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
	value.direction = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
	value.projectileType = buffer.readu8(incoming_buff, read(1))
	return value
end
export type serverProjectileData = ({
	t: (number),
	origin: (Vector3),
	direction: (Vector3),
	projectileType: (number),
	sender: (number),
})
function types.write_serverProjectileData(value: serverProjectileData)
	alloc(4)
	buffer.writeu32(outgoing_buff, outgoing_apos, value.t)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.X)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.Y)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.origin.Z)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.X)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.Y)
	alloc(4)
	buffer.writef32(outgoing_buff, outgoing_apos, value.direction.Z)
	alloc(1)
	buffer.writeu8(outgoing_buff, outgoing_apos, value.projectileType)
	alloc(1)
	buffer.writeu8(outgoing_buff, outgoing_apos, value.sender)
end
function types.read_serverProjectileData()
	local value;
	value = {}
	value.t = buffer.readu32(incoming_buff, read(4))
	value.origin = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
	value.direction = Vector3.new(buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)), buffer.readf32(incoming_buff, read(4)))
	value.projectileType = buffer.readu8(incoming_buff, read(1))
	value.sender = buffer.readu8(incoming_buff, read(1))
	return value
end

RunService.Heartbeat:Connect(function()
	for player, outgoing in player_map do
		if outgoing.used > 0 then
			local buff = buffer.create(outgoing.used)
			buffer.copy(buff, 0, outgoing.buff, 0, outgoing.used)

			reliable:FireClient(player, buff, outgoing.inst)

			outgoing.buff = buffer.create(64)
			outgoing.used = 0
			outgoing.size = 64
			table.clear(outgoing.inst)
		end
	end
end)

local events = table.create(2)
reliable.OnServerEvent:Connect(function(player, buff, inst)
	incoming_buff = buff
	incoming_inst = inst
	incoming_read = 0
	incoming_ipos = 0
	local len = buffer.len(buff)
	while incoming_read < len do
		local id = buffer.readu8(buff, read(1))
		if id == 1 then
			local value
			value = types.read_clientProjectileData()
			if events[1] then
				task.spawn(events[1], player, value)
			end
		else
			error("Unknown event id")
		end
	end
end)
return {
	Trojectile_SERVER = {
		Fire = function(Player: Player, Value: (serverProjectileData))
			load_player(Player)
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 2)
			types.write_serverProjectileData(Value)
			player_map[Player] = save()
		end,
		FireAll = function(Value: (serverProjectileData))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 2)
			types.write_serverProjectileData(Value)
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for _, player in Players:GetPlayers() do
				load_player(player)
				alloc(used)
				buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
				table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
				player_map[player] = save()
			end
		end,
		FireExcept = function(Except: Player, Value: (serverProjectileData))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 2)
			types.write_serverProjectileData(Value)
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for _, player in Players:GetPlayers() do
				if player ~= Except then
					load_player(player)
					alloc(used)
					buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
					table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
					player_map[player] = save()
				end
			end
		end,
		FireList = function(List: { Player }, Value: (serverProjectileData))
			load_empty()
			alloc(1)
			buffer.writeu8(outgoing_buff, outgoing_apos, 2)
			types.write_serverProjectileData(Value)
			local buff, used, inst = outgoing_buff, outgoing_used, outgoing_inst
			for _, player in List do
				load_player(player)
				alloc(used)
				buffer.copy(outgoing_buff, outgoing_apos, buff, 0, used)
				table.move(inst, 1, #inst, #outgoing_inst + 1, outgoing_inst)
				player_map[player] = save()
			end
		end,
	},
	Trojectile_CLIENT = {
		SetCallback = function(Callback: (Player, (clientProjectileData)) -> ()): () -> ()
			events[1] = Callback
			return function()
				events[1] = nil
			end
		end,
	},
}
