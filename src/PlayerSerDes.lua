-- This should save about 4 bytes per request

local RunService = game:GetService("RunService")

--> Variables

local Constants = require(script.Parent.Constants)

local identifierStorage

if RunService:IsServer() then
    identifierStorage = Instance.new("Folder")
    identifierStorage.Name = Constants.PLAYER_ID_STORAGE_NAME
    identifierStorage.Parent = script
else
    identifierStorage = script:WaitForChild(Constants.PLAYER_ID_STORAGE_NAME)
end

local identifierMap = {}
local compressedIdentifers = {}

local identifierCount = 0
local freeIDs = {}

local yieldingThreads = {}

local PlayerSerDes = {}

--> Functions

function PlayerSerDes.referencePlayer(player: Player)
    local packed
    if not freeIDs[1] then
        packed = identifierCount -- only up to 255, for one byte

	    identifierCount += 1
    else
        packed = freeIDs[1]
        table.remove(freeIDs, 1)
    end
	identifierStorage:SetAttribute(player.Name, packed)

	identifierMap[player.Name] = packed
	compressedIdentifers[packed] = player.Name

	return packed
end

function PlayerSerDes.unreferencePlayer(player: Player)
    identifierStorage:SetAttribute(player.Name, nil)

    local id = identifierMap[player.Name]
    identifierMap[player.Name] = nil
	compressedIdentifers[player.Name] = nil

    table.insert(freeIDs, id)
end

function PlayerSerDes.serialize(player: Player)
	return identifierMap[player.Name]
end

function PlayerSerDes.deserialize(id: number)
	return compressedIdentifers[id]
end

for id, value in identifierStorage:GetAttributes() do
	identifierMap[id] = value
	compressedIdentifers[value] = id
end

identifierStorage.AttributeChanged:Connect(function(id: string)
	local packed: string = identifierStorage:GetAttribute(id)

	if packed then
		identifierMap[id] = packed
		compressedIdentifers[packed] = id
		if not yieldingThreads[id] then
			return
		end

		local indexes = {}

		for index, thread in yieldingThreads[id] do
			task.spawn(thread, packed)

			table.insert(indexes, index)
		end

		for _, index in indexes do
			table.remove(yieldingThreads[id], index)
		end
	else
		local oldValue = identifierMap[id]
		identifierMap[id] = nil
		compressedIdentifers[oldValue] = nil
	end
end)

return PlayerSerDes