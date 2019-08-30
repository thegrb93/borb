local winW, winH = love.graphics.getPixelDimensions()

local class = require("middleclass")
local rubetolove = require("rubeToLove")
local skiplist = require("skiplist")
local world = class("world")
local halfpipe = class("halfpipe")
local ball = class("ball")
local bread = class("bread")
local camera = class("camera")

local myworld

world.backgroundimg = love.graphics.newImage( "background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5
function world:initialize()
    myworld = self
    self.physworld = love.physics.newWorld(0, 10, true)
    self.camera = camera:new()
    self.backcamera = camera:new()
    self.ents = skiplist.new()
    self.player = ball:new(3, -5, 1.5)
    self.bread = bread:new()
    self.ents:insert(self.player)
    self.ents:insert(halfpipe:new())
    self.ents:insert(self.bread)
    
    self.physworld:setCallbacks(
        function(a,b,coll) end,
        function(a,b,coll) end,
        function(a,b,coll) end,
        function(a,b,coll,l,t)
            local dataA, dataB = a:getUserData(), b:getUserData()
            if dataA and dataA.postSolve then dataA:postSolve(dataB,a,b,coll,l,t) end
            if dataB and dataB.postSolve then dataB:postSolve(dataA,a,b,coll,l,t) end
        end
    )
end

function world:draw()
    self.dt = 0.01666666666 --love.timer.getDelta()

    self.backcamera.zoom = self.camera.zoom*0.1
    self.backcamera:setPos(self.camera.x, self.camera.y)
    self.backcamera:update()
    self.backcamera:push()
    love.graphics.draw(world.backgroundimg, 0, 0, 0, 0.25, 0.25, world.backgroundw, world.backgroundh)
    self.backcamera:pop()

    self.camera:push()
    for _, v in self.ents:ipairs() do
        v:draw()
    end
    self.camera:pop()
    self.physworld:update(self.dt)
end

function halfpipe:initialize()
    local points = {-5, -2.5, -4.5, -2.5,
    -- 20 nil points
    nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
    4.5, -2.5, 5, -2.5, 5, 2.5, -5, 2.5, -5, -2.5}
    for i=1, 20 do
        local rad = i*math.pi/21
        points[i*2+3] = -4.5 * math.cos(rad)
        points[i*2+4] = 4.5 * math.sin(rad) - 2.5
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
ball.feather = love.graphics.newImage( "feather.png" )
ball.featherscale = 0.5/ball.feather:getWidth()
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
    self.fixture:setUserData(self)

    self.particles = love.graphics.newParticleSystem(ball.feather, 100)
    self.particles:setLinearDamping(2, 2)
    self.particles:setParticleLifetime(2, 5)
    self.particles:setSizeVariation(1)
    self.particles:setSizes(0.005, 0.005)
    self.particles:setSpin(-3, 3)
    self.particles:setRotation(-math.pi, math.pi)
    self.particles:setColors(1, 1, 1, 1, 1, 1, 1, 0)
    self.particles:setLinearAcceleration(0, 0, 0, 10)
    self.particles:setEmissionArea("ellipse", 1, 0.5, 0, false)
    self.particles:setSpread(0.6)
end

function ball:postSolve(dataB,a,b,coll,l,t)
    if l>0.005 then
        local x, y = coll:getPositions()
        self.particles:setPosition(x, y)
        self.particles:emit(math.floor((l-0.005)*500))
    end
end

function ball:draw()
    local x, y = self.body:getWorldCenter()
    local dx, dy = self.body:getLinearVelocity()
    love.graphics.draw(ball.graphic, x, y, self.body:getAngle(), self.radius/ball.graphicw, self.radius/ball.graphich, ball.graphicw, ball.graphich)
    
    self.particles:setSpeed(math.sqrt(dx^2+dy^2)/2)
    self.particles:setDirection(math.atan2(dy,dx))
    self.particles:update(myworld.dt)
    love.graphics.draw(self.particles)
    
    myworld.camera:setPos(x, y)
    myworld.camera:update()
    
    local mx, my = myworld.bread:getPos()
    local rx, ry = (mx - x), (my - y)
    local mag = math.max(math.sqrt(rx^2 + ry^2), 2)
    if mag<8 then
        self.body:applyForce((mx - x)/mag^2*0.1, (my - y)/mag^2*0.1)
    end
end

bread.graphic = love.graphics.newImage( "bread.png" )
bread.graphicw = bread.graphic:getWidth()*0.5
bread.graphich = bread.graphic:getHeight()*0.5
function bread:initialize()
    bread.order = 1
    bread.angle = 0
end

function bread:getPos()
    return love.graphics.inverseTransformPoint(love.mouse.getPosition())
end

function bread:draw()
    local x, y = self:getPos()
    love.graphics.draw(bread.graphic, x, y, math.sin(self.angle)*0.1, 0.002, 0.002, bread.graphicw, bread.graphich)
    self.angle = self.angle + myworld.dt*2
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

world:new()

function love.wheelmoved(x,y)
    myworld.camera:addZoom(y)
end

function love.draw()
    myworld:draw()
end
