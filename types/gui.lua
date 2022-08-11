local skin = {
	panelBg = {0.2, 0.2, 0.2, 0.4},
	panelFg = {0.4, 0.4, 0.4, 0.4},
	text = {1,1,1},
	font = fonts["consola.ttf"][12]
}

addType("basegui", nil, function()
local basegui = types.basegui

function basegui:initialize(parent, x, y, w, h)
	self.x = x or 0
	self.y = y or 0
	self.w = w or -1
	self.h = h or -1
	if parent then
		self.parent = parent
		parent.children[#parent.children+1] = self
	end
	self.children = {}
	self.valid = true
	self.hidden = false
end

function basegui:draw()
	if self.hidden then return end
	self:paint()
	love.graphics.push("transform")
	love.graphics.translate(self.x, self.y)
	for k, v in ipairs(self.children) do
		v:draw()
	end
	love.graphics.pop("transform")
end

function basegui:click()
	self:setActive()
end

function basegui:paint()
end

function basegui:setActive()
	if worldgui.activegui.valid then
		worldgui.activegui:setInactive()
	end
	worldgui.activegui = self
end

function basegui:setInactive()
end

function basegui:mouseInside(mx, my)
	if self.hidden then return end
	if util.inBox(mx, my, self.x, self.y, self.w, self.h) then
		mx = mx - self.x
		my = my - self.y
		for _, v in ipairs(self.children) do
			local found, x, y = v:mouseInside(mx, my)
			if found then return found, x, y end
		end
		return self, mx, my
	end
end

function basegui:addChild(child)
	self.children[#self.children + 1] = child
end

function basegui:close()
	self.valid = false
	if self.parent and self.parent.valid then
		table.removeByValue(self.parent.children, self)
	end
	for k, v in ipairs(self.children) do
		v:close()
	end
	self:onClose()
end

function basegui:sizeToContents()
	local maxw, maxh = 0, 0
	for _, v in ipairs(self.children) do
		local w = v.x+v.w
		local h = v.y+v.h
		if w > maxw then
			maxw = w
		end
		if h > maxh then
			maxh = h
		end
	end
	self.w = maxw
	self.h = maxh
end

function basegui:centerW()
	self.x = self.parent.w*0.5 - self.w*0.5
end

function basegui:centerH()
	self.y = self.parent.h*0.5 - self.h*0.5
end

function basegui:center()
	self:centerW() self:centerH()
end

function basegui:onClose()
end
end)

addType("worldgui", "basegui", function(basegui)
local worldgui = types.worldgui

function worldgui:initialize()
	basegui.initialize(self, nil, 0, 0, scrw, scrh)
	self.console = types.console:new()
	self.activegui = self

	hook.add("keypressed", self)
	hook.add("textinput", self)
	hook.add("mousepressed", self)
end

function worldgui:draw()
	for k, v in ipairs(self.children) do
		v:draw()
	end
	self.console:draw()
end

function worldgui:keypressed(key)
	if key=="`" then
		self.console:toggle()
	else
		if self.activegui~=self and self.activegui.keypressed then
			self.activegui:keypressed(key)
		end
	end
end

function worldgui:textinput(key)
	if self.activegui~=self and self.activegui.textinput then
		self.activegui:textinput(key)
	end
end

function worldgui:mousepressed(x, y, button)
	local gui
	gui, x, y = self:mouseInside(x, y)
	if gui then
		if gui==self then
			self:setActive()
		else
			gui:setActive()
			if gui.mousepressed then
				gui:mousepressed(x, y)
			end
		end
	end
end

function worldgui:close()
	self.activegui = self
	for k, v in ipairs(self.children) do
		v:close()
		self.children[k] = nil
	end
end

end)

addType("panel", "basegui", function(basegui)
local panel = types.panel

function panel:initialize(parent, x, y, w, h, title)
	basegui.initialize(self, parent, x, y, w, h)
	self.color = skin.panelBg
end

function panel:paint()
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end
end)

addType("label", "basegui", function(basegui)
local label = types.label

function label:initialize(parent, x, y, text, font)
	self.font = font or skin.font
	self.fontheight = self.font:getHeight()
	self.textobj = love.graphics.newText(self.font)
	self.color = skin.text
	basegui.initialize(self, parent, x, y, 0, 0)
	self:setText(text)
end

function label:setText(text)
	self.textobj:set({self.color, text})
	self.w, self.h = self.textobj:getDimensions()
	self.h = math.max(self.h, self.fontheight)
end

function label:paint()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.textobj, self.x, self.y)
end
end)

addType("textentry", "panel", function(panel)
local textentry = types.textentry

function textentry:initialize(parent, x, y, w, h)
	panel.initialize(self, parent, x, y, w, h)
	self.color = skin.panelFg
	self.entrytxt = types.label:new(self, 2, 0, "")
	self.entrytxt:centerH()
	self.active = false
	self.text = ""
end

function textentry:keypressed(key)
	if key=="return" then
		self:onEnter(self.text)
	elseif key=="escape" then
		self:setText("")
		self:onEnter("")
	elseif key=="backspace" then
		local txt = self.text
		self:setText(string.sub(txt, 1, #txt-1))
	end
end

function textentry:setText(text)
	self.text = text
	self.entrytxt:setText(text)
end

function textentry:textinput(txt)
	self:setText(self.text .. txt)
end

function textentry:setActive()
	panel.setActive(self)
	self.active = true
	love.keyboard.setKeyRepeat(true)
	love.keyboard.setTextInput(true)
end

function textentry:setInactive()
	if self.active then
		self.active = false
		love.keyboard.setKeyRepeat(false)
		love.keyboard.setTextInput(false)
	end
end

function textentry:onEnter(txt)
end

function textentry:onClose()
	self:setInactive()
end
end)

addType("dialoguelistH", "basegui", function(basegui)
local dialoguelistH = types.dialoguelistH

function dialoguelistH:initialize(parent, x, y)
	basegui.initialize(self, parent, x, y, 0, 0)
	self.padding = 3
	self.curx = 0
	self.cury = 0
end

function dialoguelistH:refresh()
	self.curx = 0
	self.cury = 0
	for _, v in ipairs(self.children) do
		self:add(v)
	end
end

function dialoguelistH:add(panel)
	panel.y = self.padding
	self.h = math.max(self.padding*2+panel.h, self.h)
	self.curx = self.curx + self.padding
	panel.x = self.curx
	self.curx = self.curx + panel.w
	self.w = self.curx + self.padding
	return panel
end
end)

addType("dialoguelistV", "basegui", function(basegui)
local dialoguelistV = types.dialoguelistV

function dialoguelistV:initialize(parent, x, y)
	basegui.initialize(self, parent, x, y, 0, 0)
	self.padding = 3
	self.curx = 0
	self.cury = 0
end

function dialoguelistV:refresh()
	self.curx = 0
	self.cury = 0
	for _, v in ipairs(self.children) do
		self:add(v)
	end
end

function dialoguelistV:add(panel)
	panel.x = self.padding
	self.w = math.max(self.padding*2+panel.w, self.w)
	self.cury = self.cury + self.padding
	panel.y = self.cury
	self.cury = self.cury + panel.h
	self.h = self.cury + self.padding
	return panel
end
end)

addType("inputpanel", "panel", function(panel)
local inputpanel = types.inputpanel

function inputpanel:initialize(parent, x, y, title)
	panel.initialize(self, parent, x, y, 0, 0)
	self.dialogue = types.dialoguelistV:new(self, 0, 0)
	self.dialogue:add(types.label:new(self.dialogue, 0, 0, title))
	self.entry = self.dialogue:add(types.textentry:new(self.dialogue, 0, 0, 300-self.dialogue.padding*2, 20))
	self:sizeToContents()
end

function inputpanel:keypressed(key)
	self.entry:keypressed(key)
end
end)

addType("propertiespanel", "panel", function(panel)
local propertiespanel = types.propertiespanel

function propertiespanel:initialize(parent, x, y, title, properties)
	panel.initialize(self, parent, x, y, 0, 0)
	self.dialogue = types.dialoguelistV:new(self, 0, 0)
	self.dialogue:add(types.label:new(self.dialogue, 0, 0, title))

	self.list = types.dialoguelistV:new(self.dialogue, 0, 0)

	for k, v in ipairs(properties) do
		local entry = types.dialoguelistH:new(self.list, 0, 0)
		entry.property = v.name
		local label = entry:add(types.label:new(entry, 0, 0, v.name))
		local textentry = entry:add(types.textentry:new(entry, 0, 0, 150, 20))
		if v.default then
			textentry:setText(tostring(v.default))
		end
		function textentry.onEnter()
			self:submit()
		end
		self.list:add(entry)
	end
	local maxw = 0
	for k, v in ipairs(self.list.children) do
		maxw = math.max(maxw, v.children[1].w)
	end
	for k, v in ipairs(self.list.children) do
		v.children[1].w = maxw
		v:refresh()
	end

	self.dialogue:add(self.list)
	self:sizeToContents()
end

function propertiespanel:submit()
	local data = {}
	for k, v in ipairs(self.list.children) do
		data[k] = v.children[2].text
	end
	self:onSubmit(data)
	self:close()
end

function propertiespanel:onSubmit(data)
end

end)

addType("console", "panel", function(panel)
local console = types.console

function console:initialize(parent)
	local max = 25
	local h = 25+15*max
	panel.initialize(self, parent, 0, scrh-h, 800, h)
	self.firstIndex = 1
	self.entries = {}
	for i=1, max do
		self.entries[i] = types.label:new(self, 10, 2, "")
	end
	self.entry = types.textentry:new(self, 10, self.h-20, self.w-20, 20)
	self.entry.hidden = true
	self.hidden = true
	self.open = false
	self.reclose = 0
	print = function(...)
		if not self.open then
			self.hidden = false
			self.reclose = 180
		end
		self:print(...)
	end
	function self.entry.onEnter(_, txt)
		self.entry:setText("")
		self:command(txt)
	end
end

function console:print(...)
	local str = {}
	for k, v in ipairs{...} do
		str[k] = tostring(v)
	end
	for _, line in ipairs(string.split(table.concat(str,"   "), "\n")) do
		self.entries[self.firstIndex]:setText(line)
		for i=0, #self.entries-1 do
			self.entries[((self.firstIndex+i-1)%#self.entries)+1].y = self.h-35-i*15
		end
		self.firstIndex = ((self.firstIndex - 2) % #self.entries) + 1
	end
end

function console:toggle()
	if self.open then
		self.entry.hidden = true
		self.hidden = true
		self.open = false
		if self.prevgui then self.prevgui:setActive() end
	else
		self.prevgui = worldgui.activegui
		self.entry.hidden = false
		self.hidden = false
		self.open = true
		self.entry:setActive()
	end
end

function console:command(txt)
	local args = {}
	local inQuotes = false
	local inQuotaTbl = {}
	for _, v in ipairs(string.split(txt, " ")) do
		if inQuotes then
			if string.match(v, "\"$") then
				inQuotaTbl[#inQuotaTbl+1] = string.sub(v, 1, -2)
				v = table.concat(inQuotaTbl, " ")
				inQuotes = false
				inQuotaTbl = {}
				if #v>0 then args[#args+1] = v end
			else
				inQuotaTbl[#inQuotaTbl+1] = v
			end
		else
			if string.match(v, "^\"") then
				inQuotes = true
				inQuotaTbl[#inQuotaTbl+1] = string.sub(v, 2)
			elseif #v>0 then
				args[#args+1] = v
			end
		end
	end
	if #args>0 and #(args[1])>0 then
		local command = commands[args[1]]
		if command then
			util.pcall(command, unpack(args, 2))
		else
			print("Unknown command: "..args[1])
		end
	end
end

function console:paint()
	panel.paint(self)
	if self.reclose>0 then
		if self.open then
			self.reclose = 0
		else
			self.reclose = self.reclose - 1
			if self.reclose==0 then
				self.hidden = true
			end
		end
	end
end
end)
