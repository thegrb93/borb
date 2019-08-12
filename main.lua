local winW, winH = love.graphics.getPixelDimensions()

local class = require("middleclass")
local world = class("world")
local halfpipe = class("halfpipe")
local ball = class("ball")
local camera = class("camera")

local myworld

function world:initialize()
    myworld = self
    self.physworld = love.physics.newWorld(0, -10, true)
    self.camera = camera:new()
    self.ents = {ball:new(3, 5, 1.5), halfpipe:new()}
end

function world:draw()
    self.camera:push()
    for i, v in ipairs(self.ents) do
        v:draw()
    end
    self.camera:pop()
    self.physworld:update(love.timer.getDelta())
end

function halfpipe:initialize()
    local points = {-5, 2.5, -4.5, 2.5,
    -- 20 nil points
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    4.5, 2.5, 5, 2.5, 5, -2.5, -5, -2.5, -5, 2.5}
    for i=1, 20 do
        local rad = i*math.pi/21
        points[i*2+3] = -4.5 * math.cos(rad)
        points[i*2+4] = -4.5 * math.sin(rad) + 2.5
    end
    
    self.body = love.physics.newBody(myworld.physworld, 0, 0, "static")
    local shape = love.physics.newChainShape( false, points )
    love.physics.newFixture(self.body, shape, 1)
    
    self.points = points
end

function halfpipe:draw()
    love.graphics.setLineWidth(0.02)
    love.graphics.line(self.points)
end

ball.graphic = love.graphics.newImage( "borb.png" )
ball.graphicw = ball.graphic:getWidth()*0.5
ball.graphich = ball.graphic:getHeight()*0.5

function ball:initialize(x, y, radius)
    self.radius = radius
    self.shape = love.physics.newCircleShape(self.radius*0.8)
    self.body = love.physics.newBody(myworld.physworld, x, y, "dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setFriction(10)
    self.fixture:setRestitution(1)
end

function ball:draw()
    local x, y = self.body:getWorldCenter()
    love.graphics.draw(ball.graphic, x, y, self.body:getAngle(), self.radius/ball.graphicw, self.radius/ball.graphich, ball.graphicw, ball.graphich)
    
    if love.mouse.isDown(1) then
        local mpos = love.graphics.inverseTransformPoint(love.mouse.getPosition())
        self.body:applyForce((mpos - x)/100, (mpos - y)/100)
    end
end

function camera:initialize()
    self.x = 0
    self.y = 0
    self.zoom = 50
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
    self.transform:scale(self.zoom, -self.zoom)
    self.transform:translate(self.x, self.y)
end

function camera:addZoom(zoom)
    self.zoom = self.zoom + zoom
    self:update()
end

world:new()

function love.wheelmoved(x,y)
    myworld.camera:addZoom(y)
end

function love.draw()
    myworld:draw()
end
