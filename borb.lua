local class = require("middleclass")
local animation = require("animation")
local borb = class("borb")
local world = _G.world

borb.graphic = love.graphics.newImage( "borb.png" )
borb.feather = love.graphics.newImage( "feather.png" )
borb.featherscale = 0.5/borb.feather:getWidth()
borb.graphicw = borb.graphic:getWidth()*0.5
borb.graphich = borb.graphic:getHeight()*0.5
function borb:initialize(x, y, radius)
    self.radius = radius
    self.shape = love.physics.newCircleShape(self.radius*0.8)
    self.body = love.physics.newBody(world.myworld.physworld, x, y, "dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setFriction(10)
    self.fixture:setRestitution(1)
    self.fixture:setUserData(self)

    self.particles = love.graphics.newParticleSystem(borb.feather, 100)
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
        local jumpborbRatio = 0.1
        self.jumpAnim = animation:new(0.3, {
            {self.radius, self.radius*(1+jumpborbRatio*0.7), self.radius*(1+jumpborbRatio*0.9), self.radius*(1+jumpborbRatio)}
        }, "cubicBezier")
        
        local r = radius * jumpborbRatio
        local x0 = r - radius
        local dtheta = 2*math.asin((x0 + math.sqrt(x0^2 - r^2))/r)
        local numborbs = math.floor(math.pi*2/dtheta)
        dtheta = math.pi*2/numborbs
        self.jumpEntPositions = {}
        for i=1, numborbs do
            local theta = (i-1)*dtheta
            local x, y = -x0*math.cos(theta), -x0*math.sin(theta)
            self.jumpEntPositions[i] = {x, y}
            self.jumpAnchorPositions[i] = {x*2, y*2}
        end
    end
end

function borb:postSolve(dataB,a,b,coll,l,t)
    if l>0.005 then
        local x, y = coll:getPositions()
        self.particles:setPosition(x, y)
        self.particles:emit(math.floor((l-0.005)*500))
    end
end

function borb:draw()
    local x, y = self.body:getWorldCenter()
    local dx, dy = self.body:getLinearVelocity()
    local drawRadius
    if self.jumping then
        drawRadius = self.jumpAnim:get(world.myworld.t)
    else
        drawRadius = self.radius
    end
    love.graphics.draw(borb.graphic, x, y, self.body:getAngle(), drawRadius/borb.graphicw, drawRadius/borb.graphich, borb.graphicw, borb.graphich)
    
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

function borb:jump()
    if self.jumping then return end
    self.jumping = true
    self.jumpAnim:reset(world.myworld.t)
end

return borb
