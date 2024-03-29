--!native
--!optimize 2
--!nolint FunctionUnused
--!nolint LocalUnused
--!nolint LocalShadow
--#selene: allow(unused_variable)
--#selene: allow(shadowing)
-- Client generated by Zap v0.3.3 (https://github.com/red-blox/zap)
local outgoing_buff: buffer
local outgoing_used: number
local outgoing_size: number
local outgoing_inst: { Instance }
local outgoing_apos: number

local incoming_buff: buffer
local incoming_read: number
local incoming_inst: { Instance }
local incoming_ipos: number

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
if game:GetService("RunService"):IsServer() then
	error("Cannot use the client module on the server!")
end

local reliable = game:GetService("ReplicatedStorage"):WaitForChild("ZAP_RELIABLE")
local unreliable = game:GetService("ReplicatedStorage"):WaitForChild("ZAP_UNRELIABLE")

local time = 0

game:GetService("RunService").Heartbeat:Connect(function(dt)
	time += dt

	if time >= (1 / 61) then
		time -= (1 / 61)

		if outgoing_used ~= 0 then
			local buff = buffer.create(outgoing_used)
			buffer.copy(buff, 0, outgoing_buff, 0, outgoing_used)

			reliable:FireServer(buff, outgoing_inst)

			outgoing_buff = buffer.create(64)
			outgoing_used = 0
			outgoing_size = 64
			table.clear(outgoing_inst)
		end
	end
end)
export type clientProjectileData = ({
	origin: (Vector3),
	direction: (Vector3),
	projectileType: (string),
	p: (boolean),
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
	local len = #value.projectileType
	alloc(2)
	buffer.writeu16(outgoing_buff, outgoing_apos, len)
	alloc(len)
	buffer.writestring(outgoing_buff, outgoing_apos, value.projectileType, len)
	alloc(1)
	buffer.writeu8(outgoing_buff, outgoing_apos, value.p and 1 or 0)
end
function types.read_clientProjectileData()
	local value;
	value = {}
	local x = buffer.readf32(incoming_buff, read(4))
	local y = buffer.readf32(incoming_buff, read(4))
	local z = buffer.readf32(incoming_buff, read(4))
	value.origin = Vector3.new(x, y, z)
	local x = buffer.readf32(incoming_buff, read(4))
	local y = buffer.readf32(incoming_buff, read(4))
	local z = buffer.readf32(incoming_buff, read(4))
	value.direction = Vector3.new(x, y, z)
	local len = buffer.readu16(incoming_buff, read(2))
	value.projectileType = buffer.readstring(incoming_buff, read(len), len)
	value.p = buffer.readu8(incoming_buff, read(1)) == 1
	return value
end
export type serverProjectileData = ({
	t: (number),
	origin: (Vector3),
	direction: (Vector3),
	projectileType: (string),
	player: (Player),
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
	local len = #value.projectileType
	alloc(2)
	buffer.writeu16(outgoing_buff, outgoing_apos, len)
	alloc(len)
	buffer.writestring(outgoing_buff, outgoing_apos, value.projectileType, len)
	table.insert(outgoing_inst, value.player)
end
function types.read_serverProjectileData()
	local value;
	value = {}
	value.t = buffer.readu32(incoming_buff, read(4))
	local x = buffer.readf32(incoming_buff, read(4))
	local y = buffer.readf32(incoming_buff, read(4))
	local z = buffer.readf32(incoming_buff, read(4))
	value.origin = Vector3.new(x, y, z)
	local x = buffer.readf32(incoming_buff, read(4))
	local y = buffer.readf32(incoming_buff, read(4))
	local z = buffer.readf32(incoming_buff, read(4))
	value.direction = Vector3.new(x, y, z)
	local len = buffer.readu16(incoming_buff, read(2))
	value.projectileType = buffer.readstring(incoming_buff, read(len), len)
	incoming_ipos = incoming_ipos + 1
	value.player = incoming_inst[incoming_ipos]
	assert(value.player ~= nil)
	return value
end
local events = table.create(2)
reliable.OnClientEvent:Connect(function(buff, inst)
	incoming_buff = buff
	incoming_inst = inst
	incoming_read = 0
	incoming_ipos = 0
	local len = buffer.len(buff)
	while incoming_read < len do
		local id = buffer.readu8(buff, read(1))
		if id == 2 then
			local value
			value = types.read_serverProjectileData()
			if events[2] then
				task.spawn(events[2], value)
			end
		else
			error("Unknown event id")
		end
	end
end)
return {
	Trojectile_CLIENT = {
		Fire = function(Value: (clientProjectileData))
			local pos = alloc(1)
			buffer.writeu8(outgoing_buff, pos, 1)
			types.write_clientProjectileData(Value)
		end,
	},
	Trojectile_SERVER = {
		SetCallback = function(Callback: ((serverProjectileData)) -> ())
			events[2] = Callback
		end,
	},
}
