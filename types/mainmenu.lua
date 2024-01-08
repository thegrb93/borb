addType("mainmenu", "basegui", function(basegui)
local mainmenu = types.mainmenu

local controls = [[Controls:
esc: quit
1: play
2: leveleditor
]]

function mainmenu:initialize()
	basegui.initialize(self, worldgui, 0, 0, scrw, scrh)
	self.controls = types.dialoguelistV:new(self, 0, 3)
	self.controls.padding = 0
	for _, v in ipairs(string.split(controls, "\n")) do
		self.controls:add(types.label:new(self.controls, 0, 0, v))
	end
	self:setActive()
end

function mainmenu:keypressed(key)
	if mainmenu.keypressedCmd[key] then
		mainmenu.keypressedCmd[key](self)
	end
end

mainmenu.keypressedCmd = {
	["1"] = function(self)
		world:clear()
		world:loadLevel("1")
	end,
	["2"] = function(self)
		world:clear()
		types.levelEditor:new()
	end,
}

function mainmenu:paint()
end
end)

