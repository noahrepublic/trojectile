-- This assigns objects to a number u8

local RunService = game:GetService("RunService")

--> Variables

local yieldingThreads = {}

local Identifiers = {}
Identifiers.__index = Identifiers

--> Functions

function Identifiers.new(storageName: string)
	local self = setmetatable({}, Identifiers)

	local identifierStorage

	self._toClean = {}

	if RunService:IsServer() then
		identifierStorage = Instance.new("Folder")
		identifierStorage.Name = storageName
		identifierStorage.Parent = script
	else
		identifierStorage = script:WaitForChild(storageName)
	end

	table.insert(self._toClean, identifierStorage)

	self._identifierStorage = identifierStorage
	self._identifierMap = {}
	self._compressedIdentifiers = {}

	self._identifierCount = 0
	self._freeIDs = {}

	for id, value in identifierStorage:GetAttributes() do
		self._identifierMap[id] = value
		self._compressedIdentifiers[value] = id
	end

	table.insert(
		self._toClean,
		identifierStorage.AttributeChanged:Connect(function(id)
			self:_onReferenceChange(id)
		end)
	)

	return self
end

function Identifiers:referenceIdentifier(rawString)
	local packed
	if not self._freeIDs[1] then
		packed = self._identifierCount -- only up to 255, for one byte

		self._identifierCount += 1
	else
		packed = self._freeIDs[1]
		table.remove(self._freeIDs, 1)
	end

	self._identifierStorage:SetAttribute(rawString, packed)

	self._identifierMap[rawString] = packed
	self._compressedIdentifiers[packed] = rawString

	return packed
end

function Identifiers:unreferenceIdentifier(rawString: string)
	self._identifierStorage:SetAttribute(rawString, nil)

	local id = self._identifierMap[rawString]
	self._identifierMap[rawString] = nil
	self._compressedIdentifiers[rawString] = nil

	table.insert(self._freeIDs, id)
end

function Identifiers:serialize(rawString: string)
	return self._identifierMap[rawString]
end

function Identifiers:deserialize(id: number)
	return self._compressedIdentifiers[id]
end

function Identifiers:_onReferenceChange(id: number)
	local packed: string = self._identifierStorage:GetAttribute(id)

	if packed then
		self._identifierMap[id] = packed
		self._compressedIdentifiers[packed] = id
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
		local oldValue = self._identifierMap[id]
		self._identifierMap[id] = nil
		self._compressedIdentifiers[oldValue] = nil
	end
end

function Identifiers:Destroy()
	for _, task in self._toClean do
		if task.Destroy then
			task:Destroy()
		elseif task.Disconnect then
			task:Disconnect()
		end
	end
end

return Identifiers
