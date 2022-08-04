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
end

function basegui:draw()
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

function basegui:mouseInside(mx, my)
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
end

function textentry:keypressed(key)
	if key=="return" then
		self:onEnter(self.entrytxt.text)
	elseif key=="escape" then
		self:onEnter("")
	elseif key=="backspace" then
		self.entrytxt.text = string.sub(self.entrytxt.text, 1, #self.entrytxt.text-1)
	elseif string.match(key, "^[%w ]$") then
		self.entrytxt.text = self.entrytxt.text .. key
	end
end

function textentry:onEnter(txt)
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

function console:initialize(parent, x, y, w, h, title, bgcolor, fgcolor, txtcolor)
	panel.initialize(self, parent, x, y, w, h, {0.2, 0.2, 0.2})
	self.title = types.label:new(self, 10, 2, title, txtcolor)
	self.entry = types.textentry:new(self, 10, 20, w-20, 20, fgcolor, txtcolor)
end

function console:keypressed(key)
	self.entry:keypressed(key)
end
end)
