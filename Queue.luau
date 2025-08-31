--@author LightningLion58

local Queue = {}
Queue.__index = Queue

type self = {
	_queue: { any },
}
--[[
Simple Queue implementation in Luau.
]]
export type Queue = typeof(setmetatable({} :: self, Queue))

--[[
Instantiates a new Queue.
]]
function Queue.new(): Queue
	local self: Queue = setmetatable({
		_queue = {},
	}, Queue)
	return self
end
--[[
Returns the amount of elements in the queue.
]]
function Queue.Size(self: Queue): number
	return #self._queue
end
--[[
Returns the head of the Queue
]]
function Queue.Peek(self: Queue): any
	return self._queue[1]
end
--[[
Alias for Queue.Peek.
]]
Queue.Head = Queue.Peek

--[[
Removes element at index <strong>index</strong> if it exists and returns it, otherwise, it throws an error.
If no index is specified, it removes the head of the queue (and returns it)
]]
function Queue.Remove(self: Queue, index: number?): any
	if #self._queue == 0 then
		error("Cannot Remove from Queue: Queue is empty!")
	end
	if not index then
		return table.remove(self._queue, 1)
	else
		return table.remove(self._queue, index)
	end
end
--[[
Alias for Queue.Remove.
]]
Queue.Dequeue = Queue.Remove

--[[
Inserts <strong>item</strong> to the end of the queue.
]]
function Queue.Insert(self: Queue, item)
	table.insert(self._queue, item)
end
--[[
Alias for Queue.Insert.
]]
Queue.Enqueue = Queue.Insert
function Queue.Get(self: Queue, elementIndex): any
	return self._queue[elementIndex]
end
--[[
Searches if <strong>searchCriteria</strong> is true for any element in the queue.
Returns true if it is, false otherwise.
]]
function Queue.Search(self: Queue, searchCriteria: (index: number, element: any) -> boolean): boolean
	for i = 1, self:Size(), 1 do
		if searchCriteria(i, self:Get(i)) then
			return true
		end
	end
	return false
end
--[[
Returns true if the queue is empty, false otherwise.
]]
function Queue.IsEmpty(self: Queue): boolean
	return #self._queue == 0
end
--[[
Destroys the queue, it becomes unusable after destruction.
]]
function Queue:Destroy()
	self._queue = nil
	setmetatable(self, nil)
end

return if table.isfrozen(Queue) then Queue else table.freeze(Queue)
