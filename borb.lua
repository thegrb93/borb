local animation = require("lib/animation")
local borb = types.borb
local bread = types.bread

borb.graphic = love.graphics.newImage( "img/borb.png" )
borb.angryeye = love.graphics.newImage( "img/borb_angryeye.png" )
borb.feather = love.graphics.newImage( "img/feather.png" )
borb.featherscale = 0.5/borb.feather:getWidth()
borb.originx = borb.graphic:getWidth()*0.5
borb.originy = borb.graphic:getHeight()*0.5
function borb:initialize(x, y, radius)
    self.radius = radius
    self.jumpNum = 8
    self.jumpSpeed = 10
    self.shape = love.physics.newCircleShape(self.radius*0.8)
    self.body = love.physics.newBody(world.physworld, x, y, "dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.fixture = love.physics.newFixture(self.body, self.shape, 1)
    self.fixture:setFriction(10)
    self.fixture:setRestitution(1)
    self.fixture:setFilterData( collisionCategories.player, 65535, 0 )
    self.fixture:setUserData(self)
    
    self.bread = bread:new()
    world.ents:insert(self.bread)

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
end

function borb:postSolve(dataB,a,b,coll,l,t)
    if l>0.005 then
        local x, y = coll:getPositions()
        self.particles:setPosition(x, y)
        self.particles:emit(math.floor((l-0.005)*500))
    end
    if dataB and dataB:isInstanceOf(world.levelclasses.spike) then
        self:explode()
    end
end

function borb:think()
    self.x, self.y = self.body:getWorldCenter()
    self.dx, self.dy = self.body:getLinearVelocity()
    self.angle = self.body:getAngle()
    if love.keyboard.isDown("space") then
        if not self.jumping then
            self:jump()
            self.jumping = true
        end
    else
        if self.jumping then
            self:endJump()
            self.jumping = false
        end
    end

    self.particles:setSpeed(math.sqrt(self.dx^2 + self.dy^2)*0.5)
    self.particles:setDirection(math.atan2(self.dy, self.dx))

    local mx, my = self.bread:getPos()
    local rx, ry = (mx - self.x), (my - self.y)
    local mag = math.max(rx^2 + ry^2, 4)
    if mag<64 then
        self.body:applyForce((mx - self.x)/mag*0.1, (my - self.y)/mag*0.1)
    end
    
    world.camera:setPos(self.x, self.y)
    world.camera:update()
end

function borb:draw()
    local drawRadius
    if self.jumping then
        local maxR = 0
        for i=1, self.jumpNum do
            local jump = self.jumpEnts[i]
            local x, y = jump.body:getWorldCenter()
            local R = (self.x-x)^2 + (self.y-y)^2
            if R>maxR then maxR = R end
            
            love.graphics.circle("fill",x,y,self.radius*0.79)
        end
        drawRadius = self.radius+math.sqrt(maxR)
    else
        drawRadius = self.radius
    end
    love.graphics.push()
    love.graphics.applyTransform(love.math.newTransform(self.x, self.y, self.angle, drawRadius/borb.originx, drawRadius/borb.originy, borb.originx, borb.originy))
    love.graphics.draw(borb.graphic)
    if self.jumping then
        love.graphics.draw(borb.angryeye, 241, 83)
    end
    love.graphics.pop()
    
    self.particles:update(world.dt)
    love.graphics.draw(self.particles)
end

function borb:jump()
    self.jumpEnts = {}
    local jumpRadius = self.radius*0.79
    for i=1, self.jumpNum do
        local ang = 2*math.pi*i/self.jumpNum
        local jump = {}
        jump.shape = love.physics.newCircleShape(jumpRadius)
        jump.body = love.physics.newBody(world.physworld, self.x, self.y, "dynamic")
        jump.body:setLinearDamping(0)
        jump.body:setAngularDamping(0)
        jump.body:setLinearVelocity(self.dx, self.dy)
        jump.fixture = love.physics.newFixture(jump.body, jump.shape, 1)
        jump.fixture:setFriction(10)
        jump.fixture:setRestitution(1)
        jump.fixture:setFilterData(collisionCategories.player, 65535 - collisionCategories.player, 0)
        jump.fixture:setUserData(self)
        jump.joint = love.physics.newPrismaticJoint( self.body, jump.body, self.x, self.y, self.x, self.y, math.cos(ang), math.sin(ang), false)
        jump.joint:setLimitsEnabled(true)
        jump.joint:setLimits(0, jumpRadius*0.3)
        jump.joint:setMotorEnabled(true)
        jump.joint:setMotorSpeed(self.jumpSpeed)
        jump.joint:setMaxMotorForce(5)
        self.jumpEnts[i] = jump
    end
end

function borb:endJump()
    for i=1, self.jumpNum do
        local jump = self.jumpEnts[i]
        jump.body:destroy()
        jump.joint:release()
        jump.fixture:release()
        jump.body:release()
        jump.shape:release()
    end
end

function borb:explode()
    
end



bread.graphic = love.graphics.newImage( "img/bread.png" )
bread.originx = bread.graphic:getWidth()*0.5
bread.originy = bread.graphic:getHeight()*0.5
function bread:initialize()
    bread.order = 1
end

function bread:getPos()
    return world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
end

function bread:think()
end

function bread:draw()
    local x, y = bread:getPos()
    love.graphics.draw(bread.graphic, x, y, math.sin(world.t)*0.1, 0.002, 0.002, bread.originx, bread.originy)
end
