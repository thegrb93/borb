addType("mainmenu", "baseentity", function(baseentity)
local mainmenu = types.mainmenu

local controls = [[Controls:
1: play
2: leveleditor
3: modeleditor
]]

function mainmenu:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.gui
	hook.add("keypressed", self)
end

function mainmenu:keypressed(key)
	if key=="1" then
		world:clear()
		world:loadLevel("levels/level1.lua")
	elseif key=="2" then
		world:clear()
		types.levelEditor:new():spawn()
	elseif key=="3" then
		world:clear()
		types.modelEditor:new():spawn()
	end
end

function mainmenu:draw()
	love.graphics.print(controls)
end

function mainmenu:onRemove()
	hook.remove("keypressed", self)
end

end)

addType("modelEditor", "baseentity", function(baseentity)
local modelEditor = types.modelEditor

local controls = [[Controls:
mouse1: draw
mouse2: erase
space: play
backspace: clear
s: save
l: load
[: Increase brush
]: Decrease brush
h: Show/Hide controls
]]

function modelEditor:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.gui
	hook.add("keypressed", self)
end

function modelEditor:keypressed(key)
end

function modelEditor:draw()
	love.graphics.print(controls)
end

function modelEditor:onRemove()
	hook.remove("keypressed", self)
end

end)

addType("levelEditor", "baseentity", function(baseentity)
local levelEditor = types.levelEditor

local controls = [[Controls:
mouse1: draw
mouse2: erase
space: play
backspace: clear
s: save
l: load
[: Increase brush
]: Decrease brush
h: Show/Hide controls
]]

function levelEditor:initialize()
	baseentity.initialize(self)
	self.drawCategory = world.drawCategories.gui
	hook.add("keypressed", self)
end

function levelEditor:keypressed(key)
end

function levelEditor:draw()
	love.graphics.print(controls)
end

function levelEditor:onRemove()
	hook.remove("keypressed", self)
end

end)

