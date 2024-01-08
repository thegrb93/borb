addType("camera", nil, function()

local winW, winH = love.graphics.getPixelDimensions()
local camera = types.camera

function camera:initialize()
	self.x = 0
	self.y = 0
	self.zoom = 25
	self.transform = love.math.newTransform()
	self.shaking = false
	self.shake = {x = 0, y = 0, a = 0, dx = 0, dy = 0, da = 0}
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
		util.eulerIntegrate3D(self.shake, -self.shake.x*3000 - self.shake.dx*25, -self.shake.y*3000 - self.shake.dy*25, 0)
		if util.isStateZero3D(self.shake) then
			self.shaking = false
		end
	end

	self.transform:reset()
	self.transform:translate(winW/2, winH/2)
	self.transform:scale(self.zoom, self.zoom)
	self.transform:translate(self.shake.x-self.x, self.shake.y-self.y)
end

function camera:setPos(x, y)
	self.x = x
	self.y = y
end

function camera:addZoom(zoom)
	self.zoom = math.max(self.zoom + zoom, 1)
end

function camera:addShake(shakex, shakey)
	self.shaking = true
	self.shake.dx = self.shake.dx + shakex
	self.shake.dy = self.shake.dy + shakey
end

end)
