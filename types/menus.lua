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
		world:loadLevel("levels/level1.lua")
	end,
	["2"] = function(self)
		world:clear()
		types.levelEditor:new()
	end,
}

function mainmenu:paint()
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
	self.controls = types.dialoguelistV:new(self, 0, 3)
	self.controls.padding = 0
	for _, v in ipairs(string.split(controls, "\n")) do
		self.controls:add(types.label:new(self.controls, 0, 0, v))
	end
	self.editingtxt = types.label:new(self, 100, 3, "Editing: <new file>")
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
		local panel = types.inputpanel:new(self, 0, 0, "Save level:")
		panel:center()
		panel.entry:setActive()
		if self.filename then
			panel.entry:setText(self.filename)
		end
		function panel.entry.onEnter(_, txt)
			panel:close()
			self:setActive()
			if #txt>0 then
				self:save(txt)
			end
		end
	end,
	l = function(self)
		local panel = types.inputpanel:new(self, 0, 0, "Load level:")
		panel:center()
		panel.entry:setActive()
		function panel.entry.onEnter(_, txt)
			panel:close()
			self:setActive()
			if #txt>0 then
				self:load(txt)
			end
		end
	end,
	a = function(self)
		local panel = types.inputpanel:new(self, 0, 0, "Add entity:")
		panel:center()
		panel.entry:setActive()
		if self.lastAddEntity then panel.entry:setText(self.lastAddEntity) end
		function panel.entry.onEnter(_, name)
			panel:close()
			self:setActive()
			if #name>0 then
				self.lastAddEntity = name
				self:addEntity(name)
			end
		end
	end,
	["`"] = function(self)
		console:toggle()
	end
}

function levelEditor:paint()
end

function levelEditor:save(name)
	self.filename = name
	self.editingtxt:setText("Editing: "..name)
end

function levelEditor:load(name)
	self.filename = name
	self.editingtxt:setText("Editing: "..name)
end

function levelEditor:addEntity(name)
	local t = types[name]
	if t and t:isSubclassOf(types.baseentity) then
		local x, y = love.mouse.getPosition()
		local wx, wy = world:getCursorPosition()
		if t.properties then
			local props = types.propertiespanel:new(self, x, y, "Creating: "..name, t.properties)
			function props.onSubmit(_, d)
				if d then
					util.pcall(function() t:new(wx, wy, 0, unpack(d)):spawn() end)
				end
				self:setActive()
			end
		else
			util.pcall(function() t:new(wx, wy, 0):spawn() end)
		end
	else
		print("Type "..name.." doesn't exist or isn't a baseentity!")
	end
end

end)

