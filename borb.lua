local borb = types.borb
local bread = types.bread
local crumbs = types.crumbs
local featherProjectile = types.featherProjectile

borb.graphic = love.graphics.newImage( "img/borb.png" )
borb.angryeye = love.graphics.newImage( "img/borb_angryeye.png" )
borb.feather = love.graphics.newImage( "img/feather.png" )
borb.originx = borb.graphic:getWidth()*0.5
borb.originy = borb.graphic:getHeight()*0.5
borb.featherOriginX = borb.feather:getWidth()*0.5
borb.featherOriginY = borb.feather:getWidth()*0.5
borb.particles = love.graphics.newParticleSystem(borb.feather, 100)
borb.particles:setLinearDamping(2, 2)
borb.particles:setParticleLifetime(2, 5)
borb.particles:setSizeVariation(1)
borb.particles:setSizes(0.005, 0.005)
borb.particles:setSpin(-3, 3)
borb.particles:setRotation(-math.pi, math.pi)
borb.particles:setColors(1, 1, 1, 1, 1, 1, 1, 0)
borb.particles:setLinearAcceleration(0, 0, 0, 10)
borb.particles:setEmissionArea("ellipse", 1, 0.5, 0, false)
borb.particles:setSpread(0.6)
function borb:initialize(x, y, radius)
    self.drawCategory = world.drawCategories.foreground
    self.x, self.dx = x, 0
    self.y, self.dy = y, 0
    self.angle, self.dangle = 0, 0
    self.radius = radius
    self.jumpNum = 8
    self.jumpSpeed = 100
    self.floofNum = 20

    self.body = world.physworld:newCircleCollider(x, y, self.radius*0.8)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Player")
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(0.5)
    self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
        self:postSolve(collider_2:getObject(), contact, normal_impulse1)
    end)
    
    self.bread = bread:new(self, x, y-1)
    world:addEntity(self.bread)
    self.crumbs = crumbs:new(self.body)
    world:addEntity(self.crumbs)
    
    self.think = self.thinkAlive
    self.draw = self.drawAlive

    hook.add("keypressed", self)
    hook.add("mousepressed", self)
end

function borb:destroy()
    if self.jumping then self:endJump() self.jumping = false end
    hook.remove("keypressed", self)
    hook.remove("mousepressed", self)
    error("not implemented")
end

function borb:keypressed()
    -- self:explode(0,-40)
end

function borb:mousepressed(x, y, button)
    if button == 1 then
        local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
        local diffx, diffy = math.normalizeVec(mx - self.x, my - self.y)
        if diffx~=diffx then diffx, diffy = 0, 1 end
        world:addEntity(types.featherProjectile:new(self, self.x, self.y, diffx*50, diffy*50))
    end
end

function borb:postSolve(other,contact,impulse)
    if impulse>50 then
        local x, y = contact:getPositions()
        self.particles:setPosition(x, y)
        self.particles:emit(math.floor((impulse-50)*50))
    end
    if other and other:isInstanceOf(types.spike) then
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

    self.particles:setSpeed(math.length(self.dx, self.dy)*0.5)
    self.particles:setDirection(math.atan2(self.dy, self.dx))

    local mx, my = self.bread:getPos()
    local rx, ry = mx - self.x, my - self.y
    local mag = math.max(math.lengthSqr(rx, ry), 4)
    if mag<64 then
        self.body:applyForce(rx/mag*500, ry/mag*500)
        local mdx, mdy = self.bread.body:getLinearVelocity()
        local trx, try = ry, -rx
        for i=1, 10 do
            if math.random() > 1-(1-math.sqrt(mag)/8)*0.25 then
                self.crumbs:addCrumb(mx, my, math.random()*math.pi*2, mdx+(math.random()-0.5)*trx*10, mdy+(math.random()-0.5)*try*10, self.bread.body:getAngularVelocity())
            end
        end
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
            local R = math.lengthSqr(self.x - x, self.y - y)
            if R>maxR then maxR = R end
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
    for _, floof in ipairs(self.floofs) do
        local x, y = floof:getWorldCenter()
        local dx, dy = floof:getLinearVelocity()
        local angle = floof:getAngle()
        love.graphics.draw(borb.feather, x, y, angle, 0.01, 0.01, borb.featherOriginX, borb.featherOriginY)
        -- util.drawBody(floof.body, self.floof.shape)
    end
end

function borb:jump()
    local jumpRadius = self.radius*0.79
    self.jumpEnts = {}
    for i=1, self.jumpNum do
        local ang = 2*math.pi*i/self.jumpNum
        local body = {}
        body = world.physworld:newCircleCollider(self.x, self.y, jumpRadius)
        body:setMass(0.5)
        body:setInertia(0.5)
        body:setType("dynamic")
        body:setLinearDamping(0)
        body:setAngularDamping(0)
        body:setLinearVelocity(self.dx, self.dy)
        body:setCollisionClass("Player")
        body:setObject(self)
        body.fixtures.Main:setFriction(10)
        body.fixtures.Main:setRestitution(0.2)
        self.jumpEnts[i] = body

        local joint = love.physics.newPrismaticJoint(self.body.body, body.body, self.x, self.y, self.x, self.y, math.cos(ang), math.sin(ang), false)
        joint:setLimitsEnabled(true)
        joint:setLimits(0, jumpRadius*0.5)
        joint:setMotorEnabled(true)
        joint:setMotorSpeed(self.jumpSpeed)
        joint:setMaxMotorForce(200)
    end
end

function borb:endJump()
    for i=1, self.jumpNum do
        local body = self.jumpEnts[i]
        body:destroy()
    end
end

function borb:explode(velx, vely)
    if self.think == self.thinkDead then return end
    if self.jumping then self:endJump() self.jumping = false end
    self.body:setActive(false)

    local variance = 20
    self.floofs = {}
    for i=1, self.floofNum do
        local floof = world.physworld:newRectangleCollider(self.x, self.y, self.radius*1.5, self.radius*0.5)
        floof:setType("dynamic")
        floof:setAngle(math.random()*math.pi*2)
        floof:setLinearDamping(1)
        floof:setAngularDamping(0.1)
        floof:setLinearVelocity(self.dx + velx + math.random()*variance, self.dy + vely + math.random()*variance)
        floof:setAngularVelocity((math.random()-0.5)*variance*5)
        floof:setCollisionClass("Player")
        floof.fixtures.Main:setFriction(1)
        floof.fixtures.Main:setRestitution(0.5)
        self.floofs[i] = floof
    end
    self.think = self.thinkDead
    self.draw = self.drawDead
end


featherProjectile.feather = borb.feather
featherProjectile.featherOriginX = borb.featherOriginX
featherProjectile.featherOriginY = borb.featherOriginY
function featherProjectile:initialize(borb, x, y, dx, dy)
    self.borb = borb
    self.drawCategory = world.drawCategories.foreground
    self.body = world.physworld:newCircleCollider(x, y, 0.5)
    self.body:setType("dynamic")
    self.body:setAngle(math.vecToAng(dx, dy))
    self.body:setLinearVelocity(dx, dy)
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Player")
    self.body:setPostSolve(function() self.collided = true end)
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(1)
    
    self.pd = util.newPDController(self.body, 300)
end

function featherProjectile:getPos()
    return self.body:getPosition()
end

function featherProjectile:think()
    if self.collided then self:destroy() return end
    self.pd(0, 0, math.angnorm(math.vecToAng(self.body:getLinearVelocity()) - self.body:getAngle()), 0, 0, -self.body:getAngularVelocity())
end

function featherProjectile:draw()
    local x, y = self.body:getPosition()
    love.graphics.draw(self.feather, x, y, self.body:getAngle()+2.0, 0.01, 0.01, self.featherOriginX-50, self.featherOriginY+30)
end

function featherProjectile:destroy()
    self.body:destroy()
    world:removeEntity(self)
end


bread.graphic = love.graphics.newImage( "img/bread.png" )
bread.originx = bread.graphic:getWidth()*0.5
bread.originy = bread.graphic:getHeight()*0.5
function bread:initialize(borb, x, y)
    self.borb = borb
    self.drawCategory = world.drawCategories.foreground
    self.body = world.physworld:newCircleCollider(x, y, 0.5)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(1)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Player")
    self.body:setGravityScale(0)
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(1)
    
    self.pd = util.newPDController(self.body, 300)
end

function bread:getPos()
    return self.body:getPosition()
end

function bread:think()
    local mx, my = world.camera.transform:inverseTransformPoint(love.mouse.getPosition())
    local x, y = self.body:getPosition()
    local dx, dy = self.body:getLinearVelocity()
    local bdx, bdy = self.borb.body:getLinearVelocity()
    local diffx, diffy = mx - x, my - y
    self.pd(diffx, diffy, 0, bdx-dx, bdy-dy, 0)
end

function bread:draw()
    local x, y = self.body:getPosition()
    love.graphics.draw(self.graphic, x, y, self.body:getAngle(), 0.002, 0.002, self.originx, self.originy)
end



crumbs.graphic = love.graphics.newImage( "img/crumb.png" )
crumbs.originx = crumbs.graphic:getWidth()*0.5
crumbs.originy = crumbs.graphic:getHeight()*0.5
function crumbs:initialize(target)
    self.target = target
    self.drawCategory = world.drawCategories.foreground
    self.maxcrumbs = 100

    self.crumbs = {}
    for i=1, self.maxcrumbs do
        local setKutta, getKutta, updateKutta = util.rungeKutta()
        local crumb = {
            active = false,
            setKutta = setKutta,
            getKutta = getKutta,
            updateKutta = updateKutta,
        }
        self.crumbs[i] = crumb
    end
end

function crumbs:addCrumb(x, y, a, dx, dy, da)
    for k, v in ipairs(self.crumbs) do
        if not v.active then
            v.active = true
            v.setKutta(x, y, a, dx, dy, da)
            break
        end
    end
end

function crumbs.crumbThink(crumb, tx, ty, tdx, tdy)
    local x, y, a, dx, dy, da = crumb.getKutta()
    local dirx, diry = tx - x, ty - y
    local dirlenSqr = math.lengthSqr(dirx, diry)
    if dirlenSqr < 1 then crumb.active = false return end

    local dirlen = math.sqrt(dirlenSqr)
    local veldot = math.max((dirx*dx + diry*dy) / dirlen, 0)
    local tanvelx, tanvely = dx - dirx/dirlen*veldot, dy - diry/dirlen*veldot
    crumb.x, crumb.y, crumb.a = crumb.updateKutta(dirx*10 - tanvelx*5 + (tdx - dx)*0, diry*10 - tanvely*5 + (tdy - dy)*0, 0)
end

function crumbs:think()
    if self.target:isDestroyed() then self:destroy() return end
    local tx, ty = self.target:getPosition()
    local tdx, tdy = self.target:getLinearVelocity()
    for k, crumb in ipairs(self.crumbs) do
        if crumb.active then
            self.crumbThink(crumb, tx, ty, tdx, tdy)
        end
    end
end

function crumbs:destroy()
    world:removeEntity(self)
end

function crumbs:draw()
    for k, crumb in ipairs(self.crumbs) do
        if crumb.active then
            love.graphics.draw(self.graphic, crumb.x, crumb.y, crumb.a, 0.005, 0.005, self.originx, self.originy)
        end
    end
end


