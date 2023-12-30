local Set = {}
Set.__index = Set

--> Constructor

function Set.new(...)
	local self
	self = setmetatable({
		__len = function()
			return self._size
		end,
	}, Set)
	self._set = {}
	self._size = 0
	self._values = {}

	for _, value in { ... } do
		self:add(value)
	end

	return self
end

--> Public Methods

function Set:add(value)
	if not self:has(value) then
		self._set[value] = true
		self._size += 1
		self._values[self._size] = value
	end
end

function Set:remove(value)
	if self:has(value) then
		self._set[value] = nil
		self._size -= 1
		self._values[self._size] = nil
	end
end

function Set:has(value)
	return self._set[value] ~= nil
end

function Set:clear()
	self._set = {}
	self._size = 0
	self._values = {}
end

function Set:size()
	return self._size
end

function Set:values()
	return self._values
end

function Set:iterate()
	return self._set
end

function Set:toList()
	local list = {}

	for _, value in pairs(self._values) do
		table.insert(list, value)
	end

	return list
end

return Set
