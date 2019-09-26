local winW, winH = love.graphics.getPixelDimensions()

local class = require("middleclass")
local rube = require("rube")
local skiplist = require("skiplist")
local animation = require("animation")
local world = class("world")
-- local halfpipe = class("halfpipe")
local ball = class("ball")
local bread = class("bread")
local camera = class("camera")
local levelclasses = {spawn = class("spawn")}

world.backgroundimg = love.graphics.newImage( "background.png" )
world.backgroundw = world.backgroundimg:getWidth()*0.5
world.backgroundh = world.backgroundimg:getHeight()*0.5
function world:initialize()
    world.myworld = self
    self.dt = 0.01666666666 --love.timer.getDelta()
    self.t = 0
    self.physworld = love.physics.newWorld(0, 10, true)
    self:loadLevel(require("level1"))

    self.camera = camera:new()
    self.backcamera = camera:new()
    self.ents = skiplist.new()
    self.player = ball:new(self.spawnpoint.x, self.spawnpoint.y, 1.5)
    self.bread = bread:new()
    self.ents:insert(self.player)
    -- self.ents:insert(halfpipe:new())
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

function world:loadLevel(leveldata)
    self.leveldata = leveldata
    local bodies = rube(self.physworld, leveldata)

    if leveldata.image then
        for id, v in pairs(leveldata.image) do
            if v.name == "world" then
                self.foregroundimg = love.graphics.newImage( v.file )
                self.foregroundw = self.foregroundimg:getWidth()*0.5
                self.foregroundh = self.foregroundimg:getHeight()*0.5
                self.foregroundscale = v.scale / self.foregroundimg:getHeight()
            else
                local obj = levelclasses[v.name]
                if obj then
                    obj:new(v)
                end
            end
        end
    end
end

function world:draw()
    self.t = self.t + self.dt
    self.backcamera.zoom = self.camera.zoom*0.1
    self.backcamera:setPos(self.camera.x, self.camera.y)
    self.backcamera:update()
    self.backcamera:push()
    love.graphics.draw(world.backgroundimg, 0, 0, 0, 0.25, 0.25, world.backgroundw, world.backgroundh)
    self.backcamera:pop()

    self.camera:push()
    love.graphics.draw(self.foregroundimg, 0, 0, 0, self.foregroundscale, self.foregroundscale, self.foregroundw, self.foregroundh)
    for _, v in self.ents:ipairs() do
        v:draw()
    end
    self.camera:pop()
    self.physworld:update(self.dt)
end

function levelclasses.spawn:initialize(data)
    world.myworld.spawnpoint = {x = data.center.x, y = -data.center.y}
end

--[[
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
    
    self.body = love.physics.newBody(world.myworld.physworld, 0, 0, "static")
    local shape = love.physics.newChainShape( false, points )
    love.physics.newFixture(self.body, shape, 1)
    
    self.points = points
end

function halfpipe:draw()
    love.graphics.setLineWidth(0.02)
    love.graphics.line(self.points)
end
]]

ball.graphic = love.graphics.newImage( "borb.png" )
ball.feather = love.graphics.newImage( "feather.png" )
ball.featherscale = 0.5/ball.feather:getWidth()
ball.graphicw = ball.graphic:getWidth()*0.5
ball.graphich = ball.graphic:getHeight()*0.5
function ball:initialize(x, y, radius)
    self.radius = radius
    self.shape = love.physics.newCircleShape(self.radius*0.8)
    self.body = love.physics.newBody(world.myworld.physworld, x, y, "dynamic")
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
    
    do
        local jumpBallRatio = 0.1
        self.jumpAnim = animation:new(0.3, {
            {self.radius, self.radius*(1+jumpBallRatio*0.7), self.radius*(1+jumpBallRatio*0.9), self.radius*(1+jumpBallRatio)}
        }, "cubicBezier")
        
        local r = radius * jumpBallRatio
        local x0 = r - radius
        local dtheta = 2*math.asin((x0 + math.sqrt(x0^2 - r^2))/r)
        local numballs = math.floor(math.pi*2/dtheta)
        dtheta = math.pi*2/numballs
        self.jumpEntPositions = {}
        for i=1, numballs do
            local theta = (i-1)*dtheta
            local x, y = -x0*math.cos(theta), -x0*math.sin(theta)
            self.jumpEntPositions[i] = {x, y}
            self.jumpAnchorPositions[i] = {x*2, y*2}
        end
    end
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
    local drawRadius
    if self.jumping then
        drawRadius = self.jumpAnim:get(world.myworld.t)
    else
        drawRadius = self.radius
    end
    love.graphics.draw(ball.graphic, x, y, self.body:getAngle(), drawRadius/ball.graphicw, drawRadius/ball.graphich, ball.graphicw, ball.graphich)
    
    self.particles:setSpeed(math.sqrt(dx^2+dy^2)*0.5)
    self.particles:setDirection(math.atan2(dy,dx))
    self.particles:update(world.myworld.dt)
    love.graphics.draw(self.particles)
    
    world.myworld.camera:setPos(x, y)
    world.myworld.camera:update()
    
    local mx, my = world.myworld.bread:getPos()
    local rx, ry = (mx - x), (my - y)
    local mag = math.max(math.sqrt(rx^2 + ry^2), 2)
    if mag<8 then
        self.body:applyForce((mx - x)/mag^2*0.1, (my - y)/mag^2*0.1)
    end
end

function ball:jump()
    if self.jumping then return end
    self.jumping = true
    self.jumpAnim:reset(world.myworld.t)
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
    self.angle = self.angle + world.myworld.dt*2
end

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

world:new()

function love.wheelmoved(x,y)
    world.myworld.camera:addZoom(y)
end

function love.draw()
    world.myworld:draw()
end
