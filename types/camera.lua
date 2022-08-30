addType("camera", nil, function()

local winW, winH = love.graphics.getPixelDimensions()
local camera = types.camera

function camera:initialize()
	self.x = 0
	self.y = 0
	self.zoom = 25
	self.transform = love.math.newTransform()
	self.shakeEul = util.eulerInt3D(0, 0, 0, 0, 0, 0)
	self.shaking = false
end

function camera:push()
	love.graphics.push("transform")
	love.graphics.replaceTransform(self.transform)
end

function camera:pop()
	love.graphics.pop("transform")
end

function camera:think()
	if self.shaking then
		self.shakeEul(-self.shakeEul.x*3000 - self.shakeEul.dx*25,-self.shakeEul.y*3000 - self.shakeEul.dy*25,0)
		if self.shakeEul:isZero() then
			self.shaking = false
		end
	end

	self.transform:reset()
	self.transform:translate(winW/2, winH/2)
	self.transform:scale(self.zoom, self.zoom)
	self.transform:translate(self.shakeEul.x-self.x, self.shakeEul.y-self.y)
end

function camera:setPos(x, y)
	self.x = x
	self.y = y
end

function camera:addZoom(zoom)
	self.zoom = math.max(self.zoom + zoom, 1)
end

function camera:shake(shakex, shakey)
	self.shaking = true
	self.shakeEul.dx = self.shakeEul.dx + shakex
	self.shakeEul.dy = self.shakeEul.dy + shakey
end

end)
