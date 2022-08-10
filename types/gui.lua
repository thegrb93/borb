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

function basegui:paint()
end

function basegui:setActive()
	if worldgui.activegui then
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
			local found = v:mouseInside(mx, my)
			if found then return found end
		end
		return self
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

function basegui:onClose()
end
end)

addType("worldgui", "basegui", function(basegui)
local worldgui = types.worldgui

function worldgui:initialize()
	basegui.initialize(self, nil, 0, 0, scrw, scrh)
	self.console = types.console:new()

	hook.add("keypressed", self)
	hook.add("textinput", self)
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
		if self.activegui and self.activegui.keypressed then
			self.activegui:keypressed(key)
		end
	end
end

function worldgui:textinput(key)
	if self.activegui and self.activegui.textinput then
		self.activegui:textinput(key)
	end
end

function worldgui:close()
	self.activegui = nil
	for k, v in ipairs(self.children) do
		v:close()
		self.children[k] = nil
	end
end

end)

addType("panel", "basegui", function(basegui)
local panel = types.panel

function panel:initialize(parent, x, y, w, h, color)
	basegui.initialize(self, parent, x, y, w, h)
	self.color = color
end

function panel:paint()
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end
end)


addType("label", "basegui", function(basegui)
local label = types.label

function label:initialize(parent, x, y, text, color)
	basegui.initialize(self, parent, x, y)
	self.text = text
	self.color = color
end

function label:paint()
	love.graphics.setColor(self.color)
	love.graphics.print(self.text, self.x, self.y)
end
end)


addType("textentry", "basegui", function(basegui)
local textentry = types.textentry

function textentry:initialize(parent, x, y, w, h, bgcolor, txtcolor)
	basegui.initialize(self, parent, x, y, w, h)
	self.entry = types.panel:new(self, 0, 0, w, h, bgcolor)
	self.entrytxt = types.label:new(self, 2, 2, "", txtcolor)
	self.active = false
end

function textentry:keypressed(key)
	if key=="return" then
		local txt = self.entrytxt.text
		self.entrytxt.text = ""
		self:onEnter(txt)
	elseif key=="escape" then
		self.entrytxt.text = ""
		self:onEnter("")
	elseif key=="backspace" then
		local txt = self.entrytxt.text
		self.entrytxt.text = string.sub(txt, 1, #txt-1)
	end
end

function textentry:textinput(txt)
	self.entrytxt.text = self.entrytxt.text .. txt
end

function textentry:setActive()
	basegui.setActive(self)
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


addType("inputpanel", "panel", function(panel)
local inputpanel = types.inputpanel

function inputpanel:initialize(parent, x, y, w, h, title, bgcolor, fgcolor, txtcolor)
	panel.initialize(self, parent, x, y, w, h, bgcolor)
	self.title = types.label:new(self, 10, 2, title, txtcolor)
	self.entry = types.textentry:new(self, 10, 20, w-20, 20, fgcolor, txtcolor)
end

function inputpanel:keypressed(key)
	self.entry:keypressed(key)
end
end)

addType("console", "panel", function(panel)
local console = types.console

function console:initialize(parent)
	local max = 25
	local h = 25+15*max
	panel.initialize(self, parent, 0, scrh-h, 800, h, {0.2, 0.2, 0.2, 0.5})
	self.firstIndex = 1
	self.entries = {}
	for i=1, max do
		self.entries[i] = types.label:new(self, 10, 2, "", {1,1,1})
	end
	self.entry = types.textentry:new(self, 10, self.h-20, self.w-20, 20, {0.4, 0.4, 0.4}, {1,1,1})
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
		self:command(txt)
	end
end

function console:print(...)
	local str = {}
	for k, v in ipairs{...} do
		str[k] = tostring(v)
	end
	for _, line in ipairs(string.split(table.concat(str,"   "), "\n")) do
		self.entries[self.firstIndex].text = line
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
			local ok, err = xpcall(command, debug.traceback, unpack(args, 2))
			if not ok then print(err) end
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
