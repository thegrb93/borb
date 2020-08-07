local animation = require("lib/animation")
local borb = types.borb
local bread = types.bread

borb.graphic = love.graphics.newImage( "img/borb.png" )
borb.angryeye = love.graphics.newImage( "img/borb_angryeye.png" )
borb.feather = love.graphics.newImage( "img/feather.png" )
borb.originx = borb.graphic:getWidth()*0.5
borb.originy = borb.graphic:getHeight()*0.5
borb.featherOriginX = borb.feather:getWidth()*0.5
borb.featherOriginY = borb.feather:getWidth()*0.5
function borb:initialize(x, y, radius)
    self.x, self.dx = x, 0
    self.y, self.dy = y, 0
    self.angle, self.dangle = 0, 0
    self.radius = radius
    self.jumpNum = 8
    self.jumpSpeed = 10
    self.floofNum = 20

    self.body = world.physworld:newCircleCollider(x, y, self.radius*0.8)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setFriction(10)
    self.body:setRestitution(1)
    self.body:setCollisionClass("Player")
    self.body:setObject(self)
    self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
        self:postSolve(collider_2:getObject(), contact)
    end)
    
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
    
    self.think = self.thinkAlive
    self.draw = self.drawAlive

    -- scheduler:timer(1, function() self:explode(0,20) end)
    hook.add("keypressed", self)
end

function borb:keypressed()
    self:explode(0,-40)
end

function borb:postSolve(other,contact)
    if l>0.005 then
        local x, y = contact:getPositions()
        self.particles:setPosition(x, y)
        self.particles:emit(math.floor((l-0.005)*500))
    end
    if other and other:isInstanceOf(world.levelclasses.spike) then
        local x, y = contact:getPositions()
        self:explode(self.x - x, self.y - y)
    end
end

function borb:thinkAlive()
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

function borb:thinkDead()
end

function borb:drawAlive()
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

function borb:drawDead()
    for _, floof in ipairs(self.floof) do
        local x, y = floof.body:getWorldCenter()
        local dx, dy = floof.body:getLinearVelocity()
        local angle = floof.body:getAngle()
        love.graphics.draw(borb.feather, x, y, angle, 0.01, 0.01, borb.featherOriginX, borb.featherOriginY)
        -- util.drawBody(floof.body, self.floof.shape)
    end
end

function borb:jump()
    local jumpRadius = self.radius*0.79
    self.jumpEnts = {}
    for i=1, self.jumpNum do
        local ang = 2*math.pi*i/self.jumpNum
        local jump = {}
        jump.body = world.physworld:newCircleCollider(self.x, self.y, jumpRadius)
        jump.body:setType("dynamic")
        jump.body:setLinearDamping(0)
        jump.body:setAngularDamping(0)
        jump.body:setLinearVelocity(self.dx, self.dy)
        jump.body:setFriction(10)
        jump.body:setRestitution(1)
        jump.body:setCollisionClass("Player")
        jump.body:setObject(self)

        jump.joint = world.physworld:addJoint("PrismaticJoint", self.body, jump.body, self.x, self.y, self.x, self.y, math.cos(ang), math.sin(ang), false)
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
        world.physworld:removeJoint(jump.joint)
    end
    self.jumpEnts.shape:release()
end

function borb:explode(velx, vely)
    if self.think == self.thinkDead then return end
    if self.jumping then
        self:endJump()
        self.jumping = false
    end
    self.body:setActive(false)

    local variance = 20
    self.floof = {}
    for i=1, self.floofNum do
        local floof = {}
        floof.body = world.physworld:newRectangleCollider(self.x, self.y, self.radius*1.5, self.radius*0.5)
        floof.body:setType("dynamic")
        floof.body:setAngle(math.random()*math.pi*2)
        floof.body:setLinearDamping(1)
        floof.body:setAngularDamping(0.1)
        floof.body:setLinearVelocity(self.dx + velx + math.random()*variance, self.dy + vely + math.random()*variance)
        floof.body:setAngularVelocity((math.random()-0.5)*variance*5)
        floof.body:setFriction(1)
        floof.body:setRestitution(0.5)
        floof.body:setCollisionClass("Player")
        self.floof[i] = floof
    end
    self.think = self.thinkDead
    self.draw = self.drawDead
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
