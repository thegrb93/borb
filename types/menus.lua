addType("mainmenu", "basegui", function(basegui)
local mainmenu = types.mainmenu

local controls = [[Controls:
esc: quit
1: play
2: leveleditor
]]

function mainmenu:initialize()
	basegui.initialize(self, world.basegui, 0, 0, scrw, scrh)
	hook.add("keypressed", self)
end

function mainmenu:keypressed(key)
	if self.activeControl then
		self.activeControl:keypressed(key)
	elseif mainmenu.keypressedCmd[key] then
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

function mainmenu:onClose()
	hook.remove("keypressed", self)
end
end)


addType("levelEditor", "basegui", function(basegui)
local levelEditor = types.levelEditor

local controls = [[Controls:
esc: exit
s: save
l: load
i: import
`: console
]]

function levelEditor:initialize()
	basegui.initialize(self, world.basegui, 0, 0, scrw, scrh)

	self.editingtxt = types.label:new(self, 100, 0, "Editing: <new file>", {1,1,1})

	hook.add("keypressed", self)
end

function levelEditor:keypressed(key)
	if self.activeControl then
		self.activeControl:keypressed(key)
	elseif levelEditor.keypressedCmd[key] then
		levelEditor.keypressedCmd[key](self)
	end
end

levelEditor.keypressedCmd = {
	escape = function(self)
		world:clear()
		types.mainmenu:new()
	end,
	s = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Save file (mdl):", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		self.activeControl = panel
		if self.filename then
			panel.entry.entrytxt.text = self.filename
		end
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:save(txt)
			end
			panel:close()
			self.activeControl = nil
		end
	end,
	l = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Load file (mdl):", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		self.activeControl = panel
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:load(txt)
			end
			panel:close()
			self.activeControl = nil
		end
	end,
	i = function(self)
		local panel = types.inputpanel:new(self, scrw*0.5-150, 200, 300, 50, "Import into mdl (obj/mdl):", {0.2, 0.2, 0.2}, {0.4, 0.4, 0.4}, {1, 1, 1})
		self.activeControl = panel
		function panel.entry.onEnter(_, txt)
			if #txt>0 then
				self:import(txt)
			end
			panel:close()
			self.activeControl = nil
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

function levelEditor:import(name)
	
end

function levelEditor:onClose()
	hook.remove("keypressed", self)
end
end)

