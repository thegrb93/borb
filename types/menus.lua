addType("mainmenu", "basegui", function(basegui)
local mainmenu = types.mainmenu

local controls = [[Controls:
esc: quit
1: play
2: leveleditor
]]

function mainmenu:initialize()
	basegui.initialize(self, worldgui, 0, 0, scrw, scrh)
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
		world:loadLevel("levels/level1.lua")
	end,
	["2"] = function(self)
		world:clear()
		types.levelEditor:new()
	end,
}

function mainmenu:paint()
	love.graphics.print(controls)
end
end)


addType("levelEditor", "basegui", function(basegui)
local levelEditor = types.levelEditor

local controls = [[Controls:
esc: exit
s: save
l: load
a: Add entity
arrows: pan camera
]]

function levelEditor:initialize()
	basegui.initialize(self, worldgui, 0, 0, scrw, scrh)
	self:setActive()
	self.editingtxt = types.label:new(self, 100, 0, "Editing: <new file>", {1,1,1})
end

function levelEditor:keypressed(key)
	if levelEditor.keypressedCmd[key] then
		levelEditor.keypressedCmd[key](self)
	end
end

levelEditor.keypressedCmd = {
	escape = function(self)
		world:clear()
		types.mainmenu:new()
	end,
	s = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Save level:", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		panel.entry:setActive()
		if self.filename then
			panel.entry.entrytxt.text = self.filename
		end
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:save(txt)
			end
			panel:close()
			self:setActive()
		end
	end,
	l = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Load level:", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		panel.entry:setActive()
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:load(txt)
			end
			panel:close()
			self:setActive()
		end
	end,
	a = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Add entity (obj/mdl):", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		panel.entry:setActive()
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:addEntity(txt)
			end
			panel:close()
			self:setActive()
		end
	end,
	["`"] = function(self)
		console:toggle()
	end
}

function levelEditor:paint()
	love.graphics.print(controls)
end

function levelEditor:save(name)
	self.filename = name
	self.editingtxt.text = "Editing: "..name
end

function levelEditor:load(name)
	self.filename = name
	self.editingtxt.text = "Editing: "..name
end

function levelEditor:addEntity(name)
	
end
end)

