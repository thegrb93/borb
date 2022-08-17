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
	self.selectedEnt = types.entitypanel:new(self)
	world.think = world.thinkNone
end

function levelEditor:onClose()
	world.think = world.thinkGame
end

function levelEditor:keypressed(key)
	if levelEditor.keypressedCmd[key] then
		levelEditor.keypressedCmd[key](self)
	end
end

function levelEditor:mousepressed(x, y, button)
	if button == 1 then
		x, y = world:screenToWorld(x, y)
		local sel = world.physworld:queryPoint(x, y)[1]
		if sel then
			sel = sel:getObject()
		else
			for ent in pairs(world.allEntities) do
				if not ent.bodies and ent.x and ent.x-0.5 < x and ent.y-0.5 < y and x < ent.x+0.5 and y < ent.y+0.5 then
					sel = ent
					break
				end
			end
		end
		if sel then
			self.selectedEnt.hidden = false
			self.selectedEnt:setEntity(sel)
		else
			self.selectedEnt.hidden = true
		end
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
	local buffer = {}
	world:serialize(buffer)
	love.filesystem.write("lvls/"..name..".lvl", table.concat(buffer))
end

function levelEditor:load(name)
	self.filename = name
	self.editingtxt:setText("Editing: "..name)
	world:loadLevel(name, true)
end

function levelEditor:addEntity(name)
	local t = types[name]
	if t and t:isSubclassOf(types.baseentity) then
		local x, y = love.mouse.getPosition()
		local wx, wy = world:screenToWorld(x, y)
		if t.properties then
			local props = types.propertiespanel:new(self, x, y, "Creating: "..name, t.properties)
			props.draggable = true
			function props.onSubmit(_, d)
				if d then
					util.pcall(function() self:setupEntity(t:new(wx, wy, 0, unpack(d))) end)
				end
				self:setActive()
			end
		else
			util.pcall(function() self:setupEntity(t:new(wx, wy, 0)) end)
		end
	else
		print("Type "..name.." doesn't exist or isn't a baseentity!")
	end
end

function levelEditor:setupEntity(ent)
	if not ent.draw then
		function ent:draw()
			love.graphics.setColor(1,0,0)
			love.graphics.rectangle("fill",self.x-0.5,self.y-0.5,1,1)
		end
		ent.drawCategory = world.drawCategories.foreground
	end
	ent:spawn()
end

end)
