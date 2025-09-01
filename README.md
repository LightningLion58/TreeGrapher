# TreeGrapher + TreeNode - Create Tree structures and display them on GUI easily.
<hr />

More information on the [DevForum page]()

# TreeGrapher API:
<hr />

```luau
local TreeGrapher = require(...)

local canvas = ... -- Path to the GuiObject you want to be the parent of the tree graph.
local tree = ... -- Reference to your TreeNode root.
local VERTICAL_MARGIN = 0.4 --This is the default vertical margin.
local ALIGNMENT = "Center" -- This is the default alignment type.
local EDGES_SETTINGS = {
    Thickness = 4; -- Thickness of the edges (in pixels).
    Transparency = 0; -- Transparency of the edges.
    Color = Color3.fromRGB(0,0,0) -- Color of the edges.
    ParallelToAxes = false; -- Whether the edges connecting the nodes will be parallel to X,Y axes or diagonal.
}

local grapher = TreeGrapher.new(tree, createWidget, EDGES_SETTINGS) -- Create a grapher object.

--[[
Prepares the TreeGrapher to display the tree on the parent GUI Object.
]]
grapher:Mount(canvas)

--[[
Draws this TreeGrapher's contained tree, given a verticalMargin. <br>
Throws an error and clears the canvas if failed.
]]
grapher:Draw(VERTICAL_MARGIN, ALIGNMENT)

--[[
Prepares the TreeGrapher to display the tree on the parent GUI Object.
Draws this TreeGrapher's contained tree, given a verticalMargin. <br>
Throws an error and clears the canvas if failed.
]]
grapher:MountAndDraw(canvas, VERTICAL_MARGIN, ALIGNMENT)

--[[
Clears the graph and lets go of the resources used in creating it.
]]
grapher:Clear()
--[[
Redraws the tree contained in the grapher. This is useful if you have a dynamically changing tree. 
This method draws the changed tree on the same canvas with the same settings.
]]
grapher:Redraw()

--[[
Makes the graph invisible, without clearing it.
]]
grapher:HideGraph()

--[[
Makes the graph visible if it was hidden.
]]
grapher:ShowGraph()

--[[
Makes the graph visible or invisible, depending on the paramter (boolean)
]]
local visible : boolean = true
grapher:SetVisiblity(visible)

--[[
Replaces the current edge settings with the new edge settings, and redraws the graph.
]]
local NEW_EDGE_SETTINGS = {
    Thickness = 2;
    Transparency = 0.2;
    Color = Color3.fromRGB(255,0,0);
    ParallelToAxes = true;
}
grapher:SetEdgeSettings(NEW_EDGE_SETTINGS)

--[[
Changes the alignment type of the graph and redraws it.
]]
grapher:SetAlignment("Right")

--[[
Changes the vertical margin of the graph to the new vertical margin given and redraws it.
]]
grapher:SetVerticalMargin(0.8)
--[[
Clears the current graph, and draws a new graph with the new tree given.
]]
local newTree = ... -- Some other tree.
grapher:ReplaceTree(newTree)
```

# TreeNode API:
<hr />

```lua
--[[
Create a new tree node with the given data. Data can be anything
]]
local rootData : any = ...
local root = TreeNode.new(rootData) -- There is a second, optional parameter for a parent if this is not the root node.

--[[
Returns the data stored in this node.
]]
root:GetData()

--[[
Adds the node as a child to parent if parent is not nil. If nil, it makes the node a root (no parent node).
]]
local parent  = ... 
root:SetParent(parent)

--[[
Returns the parent node of this node.
]]
root:GetParent()

--[[
Returns true if this node is a root (no parent), false otherwise.
]]
root:IsRoot()

--[[
Adds a node as a child to this node.
]]
local newChildNode = ...
root:AddChild(newChildNode)

--[[
Adds all the nodes in the array to the children of this node.
]]
local arrayOfChildren = {...}
root:AddChildren(newChildNode)


--[[
Removes a child node from the children of this node.
childNode can either be the node itself, or the index of the child.

newChildNode will become a root in the process.
]]
local childNode = ... -- child node or child index.
root:RemoveChild(newChildNode)

--[[
Returns a shallow copy of the array of the child nodes of this node.
]]
local children = root:GetChildren()

--[[
Gets the amount of children that this node has.
Use this instead of #node:GetChildren(), as this is more efficient.
]]
local childrenCount = root:GetChildrenCount()

--[[
Returns true if someNode is a child of thisNode, false otherwise.
"child" means a direct child of this node, and not a descendant.
]]
local someNode = ...
root:HasChild(someNode)

--[[
Returns true if this node is a leaf (has no children), false otherwise
]]
root:IsLeaf()

--[[
Calls doSomething on all the nodes in pre order (DFS) manner.
Passes the currentNode to the function.
]]
local doSomething = function(currentNode)
    --Do something with the currentNode
    ...
end
root:PreOrderTraverse(doSomething)

--[[
Calls doSomething on all the nodes in post order (DFS) manner.
Passes the currentNode to the function.
]]
local doSomething = function(currentNode)
    --Do something with the currentNode
    ...
end
root:PostOrderTraverse(doSomething)

--[[
Calls doSomething on all the nodes in level order (BFS) manner.
Passes the currentNode, and the node's level to the function.
]]
local doSomething = function(currentNode, level)
    --Do something with the currentNode and level
    ...
end
root:LevelOrderTraverse(doSomething)

--[[
Calls doSomething on all nodes in the inputted order (PreOrder, PostOrder, or LevelOrder).
Passes the currentNode to the function.
]]
local traversalType = "PreOrder"
local doSomething = function(currentNode)
    --Do something with the currentNode
    ...
end
root:Traverse(traversalType, doSomething)

```