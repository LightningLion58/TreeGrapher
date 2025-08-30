--@author LightningLion58
local TreeNodeClass = require("./TreeNode")

local TreeGrapher = {}
TreeGrapher.__index = TreeGrapher

export type GuiTreeData<T> = {
	_guiObject : GuiObject;
	_height : number;
	_width : number;
	_scaleRatio : number;
	_data : TreeNodeClass.TreeNode<T>?;
	_isEmpty : boolean;
}

--[[
Settings for the lines connecting the nodes:
Thickness - thickness of the lines (in pixels).
Color - Color3 of the lines.
ParallelToAxes - if false, the connecting lines will be diagonal.
Otherwise, the lines will be parallel to the X and Y axes.
]]
export type LineSettings = {
	Thickness : number;
	Color : Color3;
	ParallelToAxes : boolean;
}

type self<T> = {
	_tree : TreeNodeClass.TreeNode<T>;
	_guiTree : TreeNodeClass.TreeNode<GuiTreeData<T>>?;
	_canvas : GuiObject?;
	_linesFrame : CanvasGroup?;
	_displayFunction : (T) -> GuiObject;
	_lineSettings : LineSettings;
}

--[[
TreeGrapher is a Class that can display trees (data structure) using GUI.
]]
export type TreeGrapher<T> = typeof( setmetatable({} :: self<T>, TreeGrapher) )

--[[
Assigns width values to the GUITree nodes of <strong>node</strong>
]]
local function assignWidths<T>(node : TreeNodeClass.TreeNode<GuiTreeData<T>>)
	if node:IsLeaf() then
		node:GetData()._width = 1
		return 1
	end
	local sum = 0
	for _, child in (node:GetChildren()) do
		sum += assignWidths(child)
	end
	node:GetData()._width = sum
	return sum
end
--[[
Assigns scaleRatios (width compared to the rest of the nodes on this level)
values to the GUITree nodes of <strong>node</strong>
]]
local function assignScaleRatio<T>(node : TreeNodeClass.TreeNode<GuiTreeData<T>>, parentScale)
	local nodeData = node:GetData()
	if node:IsRoot() then
		nodeData._scaleRatio = 1
	else
		nodeData._scaleRatio = (nodeData._width / node:GetParent():GetData()._width) * parentScale
	end
	for _, child in (node:GetChildren()) do
		assignScaleRatio(child, nodeData._scaleRatio)
	end
end
--[[
Creates a new TreeGrapher instance given: <br>
<strong>tree</strong> - The tree to be graphed.<br>
<strong>displayFunction</strong> - Function that creates a widget for a TreeNode,<br>
 and returns the GUI Widget of the node. The parameters sent to the function are the data of the node and it's parent (if exists)<br>
<strong>lineSettings</strong> - Dictionary with settings for the lines connecting the nodes.<br>
]]
function TreeGrapher.new<T>(tree : TreeNodeClass.TreeNode<T>, 
	displayFunction : (T, T?) -> GuiObject , lineSettings : LineSettings) : TreeGrapher<T>
	local self = setmetatable(
		{
			_tree = tree;
			_displayFunction = displayFunction;
			_canvas = nil;
			_lineSettings = lineSettings;
			_linesFrame = nil;
		}, 
		TreeGrapher
	)
	return self
end
--[[
Prepares the TreeGrapher to display the tree on the <strong>parent</strong> GUI Object.
]]
function TreeGrapher.Mount<T>(self : TreeGrapher<T>, parent : GuiObject)
	if(self._guiTree) then
		error("Warning: The Graph is already rendered, did you mean to call .Mount again?")
	end
	if(self._linesFrame) then
		self._linesFrame:Destroy()
	end
	self._canvas = parent
	local linesFrame = Instance.new("CanvasGroup")
	linesFrame.BackgroundTransparency = 1
	linesFrame.Size = UDim2.fromScale(1,1)
	linesFrame.Name = "GraphEdges"
	linesFrame.Parent = parent

	self._linesFrame = linesFrame
end
--[[
Instantiates a new empty, transparent frame of size <strong>size</strong>,
 at <strong>position</strong> under <strong>parentContainer</strong>
]]
local function createContainer(size : UDim2, position : UDim2, parentContainer : GuiObject)
	local frame = Instance.new("Frame")
	frame.Size = size
	frame.Position = position
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = false

	frame.Parent = parentContainer
	return frame	
end
--[[
Creates a <em>Path2D</em> connecting <strong>pos1</strong> and <strong>pos2</strong>,
 according to <strong>lineSettings</strong>, 
 and sets the name to <strong>name</strong> under the parent CanvasGroup <strong>parentContainer</strong><br>
 <br/>
Returns the Path2D.
]]
local function connectWithPath(
	pos1 : Path2DControlPoint, pos2  : Path2DControlPoint, lineSettings : LineSettings, name : string,
	parentContainer : CanvasGroup?)

	local line = Instance.new("Path2D")
	line.Name = name

	if(lineSettings.ParallelToAxes) then
		local midPos = UDim2.fromScale(
			(pos1.Position.X.Scale + pos2.Position.X.Scale)/2,
			(pos1.Position.Y.Scale + pos2.Position.Y.Scale)/2
		)
		local left = Path2DControlPoint.new(UDim2.fromScale(pos1.Position.X.Scale, midPos.Y.Scale))
		local mid = Path2DControlPoint.new(midPos)
		local right = Path2DControlPoint.new(UDim2.fromScale(pos2.Position.X.Scale, midPos.Y.Scale))
		line:SetControlPoints({pos1, left, mid, right, pos2})
	else
		line:SetControlPoints({pos1,pos2})
	end

	line.Thickness = lineSettings.Thickness
	line.Color3 = lineSettings.Color
	line.Visible = true

	line.Parent = parentContainer
	return line
end

--[[
Creates a new GUI widget for <strong>treeNode</strong> using <strong>displayFunction</strong>. <br>
<strong>nodeHeight</strong> - the <em>treeNode</em>'s height from the root node.<br>
<strong>treeHeight</strong> - the height (in nodes) from the tree's root to the highest/deepest leaf.<br>
<strong>treeHeightWithMargin</strong> - the height from the root to the tallest node with consideration to the verticalMargin.<br>
<strong>parentContainer</strong> - The canvas where the tree is supposed to be drawn.
]]
local function createTreeNodeGui<T>(
	treeNode : TreeNodeClass.TreeNode<GuiTreeData<T>>, displayFunction : (T, T?) -> GuiObject, 
	nodeHeight : number, treeHeight : number, treeHeightWithMargin : number, parentContainer : GuiObject)

	local posX = 0
	local posY = 0
	local parentNode = treeNode:GetParent()
	if(parentNode) then
		local parentPos = parentNode:GetData()._guiObject.Position
		posX = parentPos.X.Scale

		for _, otherNode in (parentNode:GetChildren()) do
			if(otherNode ~= treeNode) then
				posX += otherNode:GetData()._scaleRatio
			else
				break
			end
		end
	end

	posY = nodeHeight/treeHeight

	local nodeSize = treeNode:GetData()._scaleRatio

	local container = createContainer(
		UDim2.fromScale(nodeSize,  1 / treeHeightWithMargin),
		UDim2.fromScale(posX, posY), 
		parentContainer
	)

	local success, name = pcall(function()
		local data = treeNode:GetData()._data:GetData()
		if(typeof(data) == "string") then
			return data
		end
		return tostring(data.Name)
	end)
	local isEmpty = treeNode:GetData()._isEmpty
	container.Name = success and name or tostring(isEmpty and "EmptySpace" or treeNode:GetData()._data:GetData())
	if(not isEmpty) then
		local widget = displayFunction(treeNode:GetData()._data:GetData(), treeNode:IsRoot() and treeNode:GetData()._data:GetData() or nil)
		widget.AnchorPoint = Vector2.new(0.5,0.5)
		widget.Position = UDim2.fromScale(0.5,0.5)

		widget.Name = "TreeNodeWidget"
		widget.Parent = container
	end
	treeNode:GetData()._guiObject = container
end
--[[
Constructs a guiTree for <strong>tree</strong>, given a <strong>verticalMargin</strong>.
]]
local function buildGuiTree<T>(tree : TreeNodeClass.TreeNode<T>, verticalMargin : number)
	local treeToGuiTreeMap = {}
	local treeHeight = 0
	tree:LevelOrderTraverse(function(node, level)
		local guiTreeNode = TreeNodeClass.new({
			_data = node;
			_width = 0;
			_height = level + 1;
		})
		treeHeight = math.max(treeHeight, level + 1)
		treeToGuiTreeMap[node] = guiTreeNode

		local parent = node:GetParent()
		if parent then
			local parentGuiNode = treeToGuiTreeMap[parent]
			parentGuiNode:AddChild(guiTreeNode)
		end
	end)


	if(treeToGuiTreeMap[tree] == nil) then
		error("guiTree is nil - This is not supposed to happen.")
	end
	local guiTree = treeToGuiTreeMap[tree]
	guiTree:LevelOrderTraverse(function(currentNode, level)
		local height = currentNode:GetData()._height
		if(#currentNode:GetChildren() == 0 and height < treeHeight) then
			local emptySlot : TreeNodeClass.TreeNode<GuiTreeData<T>> = TreeNodeClass.new({
				_data = nil;
				_guiObject = nil;
				_width = 1;
				_scaleRatio = -1;
				_height = height + 1;
				_isEmpty = true;
			})
			currentNode:AddChild(emptySlot)
		end
	end)

	assignWidths(guiTree)
	assignScaleRatio(guiTree)

	local totalHeight = treeHeight + (treeHeight - 1) * verticalMargin

	return guiTree, treeHeight, totalHeight
end

--[[
Graphs the guiTree of <em>this</em> TreeGrapher's tree, given the <strong>treeHeight</strong> 
and <strong>treeHeightWithMargin</strong> (which is the height with consideration to the vertical margin).
]]
local function graphTree<T>(self : TreeGrapher<T>, treeHeight : number, treeHeightWithMargin : number)

	if(not self._canvas) then
		error("TreeGrapher: parent given is nil.")
	end
	if(not self._guiTree) then
		error("TreeGrapher: _guiTree has not been constructed. Did you forget to call buildGuiTree(...)?")
	end
	self._guiTree:LevelOrderTraverse(function(currentNode, currentLevel)
		createTreeNodeGui(currentNode, self._displayFunction, currentLevel, treeHeight, treeHeightWithMargin, self._canvas)
	end)
	self._guiTree:PostOrderTraverse(function(node)
		if(node:GetData()._isEmpty) then
			return
		end

		local parentNode = node:GetParent()
		if(parentNode) then
			local widget = node:GetData()._guiObject
			local parentContainer = parentNode:GetData()._guiObject
			local pos1 = Path2DControlPoint.new(UDim2.new(
				widget.Position.X.Scale + widget.Size.X.Scale / 2,
				0,
				widget.Position.Y.Scale,
				0
				)
			)
			local pos2 = Path2DControlPoint.new(UDim2.new(
				parentContainer.Position.X.Scale + parentContainer.Size.X.Scale / 2,
				0,
				parentContainer.Position.Y.Scale + parentContainer.Size.Y.Scale,
				0
				)
			)
			connectWithPath(pos1, pos2, self._lineSettings, parentContainer.Name .. "_To_" .. widget.Name, self._linesFrame)
		end
	end)

end
--[[
Attempts to draw <em>this</em> TreeGrapher's tree given a <strong>verticalMargin</strong>. </br >
This is unsafe because this isn't wrapped in a protected call (pcall)
]]
local function drawUnsafe<T>(self : TreeGrapher<T>, verticalMargin)
	local guiTree, treeHeight, treeHeightWithMargin  = buildGuiTree(self._tree, verticalMargin)
	self._guiTree = guiTree
	graphTree(self, treeHeight, treeHeightWithMargin)
end
--[[
Draws <em>this</em> TreeGrapher's contained tree, given a <strong>verticalMargin</strong>. <br>
Throws an error and clears the canvas if failed.
]]
function TreeGrapher.Draw<T>(self : TreeGrapher<T>, verticalMargin : number)
	if not self._canvas then
		error("TreeGrapher.Draw called before Mounting to a Frame.")
	end
	if(self._guiTree ~= nil) then
		error("Tree could not be graphed: Tree graph already exists. Did you call TreeGrapher.Clear()?")
	end

	local success, err = pcall(function()
		drawUnsafe(self, verticalMargin or 0.4)
	end)
	if(not success) then
		self:Clear()
		error(err)
	end
end
--[[
Clears the canvas of <em>this</em> TreeGrapher and frees the resources used for displaying the tree.
]]
function TreeGrapher.Clear<T>(self : TreeGrapher<T>)
	if(not self._guiTree) then
		return
	end
	self._guiTree:PostOrderTraverse(function(node)
		local nodeData = node:GetData()
		if nodeData._guiObject then
			--Destroy the parent frame (which wraps the widget):
			nodeData._guiObject:Destroy()
			nodeData._guiObject = nil
		end
	end)

	--Clear the reference to the GUI tree:
	self._guiTree = nil
	if(self._linesFrame) then
		self._linesFrame:Destroy()
		self._linesFrame = nil
	end
end
--[[
Redraws <em>this</em>'s tree on the canvas. (Clears the canvas and draws again). <br>
This is useful if you have a tree that is modified during runtime. <br>
]]
function TreeGrapher.Redraw<T>(self : TreeGrapher<T>)
	self:Clear()
	self:Draw()
end
--[[
Mounts <em>this</em> TreeGrapher on <strong>parentContainer</strong>, 
and then draws <em>this</em> TreeGrapher's tree given <strong>verticalMargin</strong> <br>
]]
function TreeGrapher.MountAndDraw<T>(self : TreeGrapher<T>, parentContainer : GuiObject?, verticalMargin : number)
	self:Clear()
	self:Mount(parentContainer)
	self:Draw(verticalMargin)
end
--[[
Replaces the tree to be displayed by <em>this</em> TreeGrapher with <strong>newTree</strong>, and then redraws.
]]
function TreeGrapher.ReplaceTree<T>(self : TreeGrapher<T>, newTree : TreeNodeClass.TreeNode<T>)
	self:Clear()
	self._tree = newTree
	self:Redraw()
end
--[[
Makes the entire tree graph visible if <strong>active</strong> is true, invisible otherwise.
]]
function TreeGrapher.SetVisiblity<T>(self : TreeGrapher<T>, active : boolean)
	if(not self._guiTree or not self._linesFrame) then
		error("TreeGrapher: Attempt to hide guiTree that doesn't exist. Did you call .Draw(...)?")
	end
	self._linesFrame.Visible = active
	self._guiTree:PreOrderTraverse(function(node)
		node:GetData()._guiObject.Visible = active
	end)
end
--[[
Hides the graph of <em>this</em> TreeGrapher, without clearing it.
]]
function TreeGrapher.Hide<T>(self : TreeGrapher<T>)
	self:SetVisiblity(false)
end
--[[
Shows the graph of <em>this</em> TreeGrapher, without clearing it. <br>
(Make sure that .Draw(...) was called before using this)
]]
function TreeGrapher.Show<T>(self : TreeGrapher<T>)
	self:SetVisiblity(true)
end

return if(table.isfrozen(TreeGrapher)) then TreeGrapher else table.freeze(TreeGrapher)