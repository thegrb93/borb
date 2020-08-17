local winW, winH = love.graphics.getPixelDimensions()
local camera = types.camera

function camera:initialize()
    self.x = 0
    self.y = 0
    self.zoom = 25
    self.transform = love.math.newTransform()
    self:update()
end

function camera:push()
    love.graphics.push("transform")
    love.graphics.replaceTransform(self.transform)
end

function camera:pop()
    love.graphics.pop("transform")
end

function camera:update()
    self.transform:reset()
    self.transform:translate(winW/2, winH/2)
    self.transform:scale(self.zoom, self.zoom)
    self.transform:translate(-self.x, -self.y)
end

function camera:setPos(x, y)
    self.x = x
    self.y = y
end

function camera:addZoom(zoom)
    self.zoom = math.max(self.zoom + zoom, 1)
    self:update()
end
