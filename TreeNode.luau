--@author LightningLion58

local TreeNode = {}

TreeNode.__index = TreeNode

type self<T> = {
	_data: T,
	_parent: TreeNode<T>?,
	_children: { TreeNode<T> },
	_childrenCount: number,
}

export type TreeNode<T> = typeof(setmetatable({} :: self<T>, TreeNode))

local Queue = require("@self/Queue")

--[[
Types of tree traversals
]]
TreeNode.TraversalTypes = table.freeze({
	PreOrder = 1,
	PostOrder = 2,
	LevelOrder = 3,
})

--[[
Creates a new TreeNode given <strong>data</strong> (can be anything), and a <strong>parent<strong> node.
]]
function TreeNode.new<T>(data: T, parent: TreeNode<T>?): TreeNode<T>
	local self = setmetatable({}, TreeNode)

	self.className = "TreeNode"

	self._data = data
	self._parent = parent

	self._children = {}
	self._childrenCount = 0

	self._childrenIndexes = {}

	if self._parent then
		self._parent:AddChild(self)
	end

	return self
end
--[[
Returns the data stored in this node.
]]
function TreeNode.GetData<T>(self: TreeNode<T>): T
	return self._data
end
--[[
Returns the parent node of this node.
If this node is the root, this will return nil.
]]
function TreeNode.GetParent<T>(self: TreeNode<T>): TreeNode<T>?
	return self._parent
end
--[[
Returns true if this node is the root of the tree, false otherwise.
]]
function TreeNode.IsRoot<T>(self: TreeNode<T>): boolean
	return self._parent == nil
end

--[[
Returns true if this node is a lead of the tree, false otherwise.
]]
function TreeNode.IsLeaf<T>(self: TreeNode<T>): boolean
	return self._childrenCount == 0
end
--[[
Sets the <strong>parent</strong> of this node.
]]
function TreeNode.SetParent<T>(self: TreeNode<T>, parent: TreeNode<T>)
	local oldParent = self._parent

	if oldParent then
		oldParent:RemoveChild(self)
	end
	if parent then
		parent:AddChild(self)
	else
		self._parent = nil
	end
end
--[[
Adds the <strong>child</strong> TreeNode to this node.
]]
function TreeNode.AddChild<T>(self: TreeNode<T>, child: TreeNode<T>)
	table.insert(self._children, child)
	self._childrenCount += 1
	self._childrenIndexes[child] = self._childrenCount
	child._parent = self
end

--[[
Returns the number of children of the tree node.
]]
function TreeNode.GetChildrenCount<T>(self: TreeNode<T>): number
	return self._childrenCount
end

--[[
Adds a list of TreeNode  <strong>children</strong> to this node.
]]
function TreeNode.AddChildren<T>(self: TreeNode<T>, children: { TreeNode<T> })
	for _, child in children do
		self:AddChild(child)
	end
end

--[[
Returns a table of the children of this node.
]]
function TreeNode.GetChildren<T>(self: TreeNode<T>): { TreeNode<T> }
	return table.clone(self._children)
end
--[[
Returns whether <strong>someNode</strong> is a child of this node
]]
function TreeNode.HasChild<T>(self: TreeNode<T>, someNode: TreeNode<T>)
	return self._childrenIndexes[someNode] ~= nil
end

--[[
Removes <strong>someNode</strong> from this TreeNode's children (if exists) and returns it

<strong>someNode</strong> can either be a TreeNode, or a number.
If <strong>someNode</strong> is a number, it is treated as an index of the children table,
and the child at that index will be removed

If <strong>someNode</strong> is a TreeNode, it is treated as a node to be removed from this node's children.
]]
function TreeNode.RemoveChild<T>(self: TreeNode<T>, someNode: TreeNode<T> | number): TreeNode<T>?
	local deletedValue = nil
	local deletedValueIndex = nil

	if typeof(someNode) == "number" then
		deletedValueIndex = someNode
		deletedValue = table.remove(self._children, someNode)
	elseif getmetatable(someNode) == TreeNode then
		if self:HasChild(someNode) then
			deletedValueIndex = self._childrenIndexes[someNode]
			deletedValue = table.remove(self._children, deletedValueIndex)
		else
			warn("Attempt to remove a node that is not a child of this node")
		end
	end
	if deletedValue then
		self._childrenCount -= 1
		table.clear(self._childrenIndexes)
		for i, child in self._children do
			self._childrenIndexes[child] = i
		end

		deletedValue._parent = nil
		return deletedValue
	end

	return nil
end

function preOrder<T>(treeNode: TreeNode<T>, action: (TreeNode<T>) -> any)
	if treeNode == nil then
		return
	end
	action(treeNode)
	local children = treeNode._children
	for _, child in children do
		preOrder(child, action)
	end
end

--[[
Traverses the tree in pre-order, starting from this node, and performs <strong>action</strong> on each node.
]]
function TreeNode.PreOrderTraverse<T>(self: TreeNode<T>, action: (TreeNode<T>) -> any)
	preOrder(self, action)
end

function postOrder<T>(treeNode: TreeNode<T>, action: (TreeNode<T>) -> any)
	if treeNode == nil then
		return
	end

	local children = treeNode._children
	for _, child in children do
		postOrder(child, action)
	end

	action(treeNode)
end
--[[
Traverses the tree in post-order, starting from this node, and performs <strong>action</strong> on each node.
]]
function TreeNode.PostOrderTraverse<T>(self: TreeNode<T>, action: (TreeNode<T>) -> any)
	postOrder(self, action)
end
--[[
Traverses the tree in level-order, starting from this node, and performs <strong>action</strong> on each node.
]]
function TreeNode.LevelOrderTraverse<T>(self: TreeNode<T>, action: (TreeNode<T>, number) -> any)
	local queue = Queue.new()
	queue:Insert({ node = self, level = 0 })

	while not queue:IsEmpty() do
		local queueItem = queue:Remove()
		local node = queueItem.node
		local currentLevel = queueItem.level
		action(node, currentLevel)

		for _, childNode in node._children do
			queue:Insert({ node = childNode, level = currentLevel + 1 })
		end
	end
	queue:Destroy()
end

--[[
Traverses the tree in the specified <strong>mode</strong>, starting from this node, and performs <strong>action</strong> on each node.
]]
function TreeNode.Traverse<T>(
	self: TreeNode<T>,
	mode: "PreOrder" | "PostOrder" | "LevelOrder",
	action: (TreeNode<T>, number?) -> any
)
	local mode = if typeof(mode) == "string" then TreeNode.TraversalTypes[mode] else mode
	if mode == TreeNode.TraversalTypes.PreOrder then
		self:PreOrderTraverse(action)
	elseif mode == TreeNode.TraversalTypes.PostOrder then
		self:PostOrderTraverse(action)
	elseif mode == TreeNode.TraversalTypes.LevelOrder then
		self:LevelOrderTraverse(action)
	end
end
return if table.isfrozen(TreeNode) then TreeNode else table.freeze(TreeNode)
