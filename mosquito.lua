local mosquito = types.mosquito
local bloodspray = types.bloodspray

function mosquito:initialize(x, y)
    self.drawCategory = world.drawCategories.foreground
    
    self.targetx, self.targety = x, y
    self.body = world.physworld:newCircleCollider(x, y, 1)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Enemy")
    self.body:setGravityScale(0)
    
    self.body:setPostSolve(function(collider_1, collider_2, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
        self:postSolve(collider_2:getObject(), contact, normal_impulse1)
    end)
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(0.5)

    self.pd = util.newPDController(self.body, 20)
    
    self.think = mosquito.aliveThink
    self.draw = mosquito.aliveDraw
    self.alive = true
    self.remove = false
    self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
end

function mosquito:postSolve(other, contact, normal_impulse)
    if self.alive then
    else
        normal_impulse = normal_impulse * 0.01
        local nx, ny = contact:getNormal()
        self:onDamage(self.x, self.y, nx*normal_impulse, ny*normal_impulse)
        self.remove = true
    end
end

function mosquito:onDamage(x, y, xn, yn)
    world:addEntity(bloodspray:new(x, y, xn*10, yn*10))
    self.body:setGravityScale(1)
    self.think = self.deadThink
    self.draw = self.deadDraw
    self.alive = false
end

function mosquito:destroy()
    self.body:destroy()
    world:removeEntity(self)
end

function mosquito:aliveThink()
    self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
    self.pd(self.targetx - self.x, self.targety - self.y, 0 - self.a, -self.dx, -self.dy, -self.da)

    local pl = world.player
    if math.lengthSqr(pl.x - self.x, pl.y - self.y) < 100 then
        self.think = mosquito.chaseThink
    end
end

function mosquito:chaseThink()
    self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()

    local pl = world.player
    local dx, dy = math.normalizeVec(pl.x - self.x, pl.y - self.y)
    self.targetx, self.targety = self.x + dx, self.y + dy

    local tx, ty = math.rotVecCW(dx, dy)
    local wave = math.sin(world.t*5)*5

    self.pd(self.targetx - self.x, self.targety - self.y, math.angnorm(math.vecToAng(dx, dy)) - self.a, tx*wave-self.dx, ty*wave-self.dy, -self.da)
end

function mosquito:deadThink()
    self.x, self.y, self.a, self.dx, self.dy, self.da = self.body:getState()
    if self.remove then
        self:destroy()
    end
end

function mosquito:aliveDraw()
    love.graphics.circle("fill", self.x, self.y, 1)
end

function mosquito:deadDraw()
    love.graphics.circle("fill", self.x, self.y, 1)
end

local dripSize = 0.1
local puddleW = 0.6
local puddleH = 0.1
bloodspray.drip = love.graphics.newMesh({{-dripSize, -dripSize}, {-dripSize, dripSize}, {dripSize, dripSize}, {dripSize, -dripSize}}, "fan", "static")
bloodspray.puddle = love.graphics.newMesh({{-puddleW, -puddleH}, {-puddleW, puddleH}, {puddleW, puddleH}, {puddleW, -puddleH}}, "fan", "static")
bloodspray.collideFilter = function(fixture)
    local udata = fixture:getUserData()
    return udata and udata.collision_class and udata.collision_class == "World"
end

function bloodspray:initialize(x, y, dx, dy)
    self.drawCategory = world.drawCategories.foreground
    self.maxblood = 30
    self.dt = world.dt
    self.gx, self.gy = world.physworld:getGravity()

    self.spray = {}
    for i=1, self.maxblood do
        local rx, ry = math.randVecSquare()
        local setKutta, getKutta, updateKutta = util.rungeKutta()
        setKutta(x+rx*0.2, y+ry*0.2, math.random()*2*math.pi, dx+rx*10, dy+ry*10, math.random()*4-2)
        local blood = {
            setKutta = setKutta,
            getKutta = getKutta,
            updateKutta = updateKutta,
            think = bloodspray.thinkDrip,
            mesh = bloodspray.drip,
        }
        blood.x, blood.y, blood.a = getKutta()
        self.spray[i] = blood
    end
    
    self.alpha = 1
    flux.to(self, 2, { alpha = 0 }):ease("linear"):delay(10):oncomplete(function() self:destroy() end)
end

function bloodspray:think()
    for k, blood in ipairs(self.spray) do
        blood.think(self, blood)
    end
end

function bloodspray:thinkDrip(blood)
    local x, y, a, dx, dy, da = blood.getKutta()

    local fixture, x, y, xn, yn, fraction = util.traceLine(x, y, x+dx*self.dt*2, y+dy*self.dt*2, bloodspray.collideFilter)
    if fixture then
        self:buildBlood(blood, x, y, xn, yn)
    else
        blood.x, blood.y, blood.a = blood.updateKutta(dx*-0.05 + self.gx, dy*-0.05 + self.gy, 0)
    end
end

function bloodspray:buildBlood(blood, x, y, xn, yn)
    blood.x = x
    blood.y = y
    blood.a = math.vecToAng(xn, yn)
    blood.think = bloodspray.thinkPuddle
    
    local custom, leftW, rightW = false, puddleW, puddleW
    local x2, y2 = x+xn*0.005, y+xn*0.005
    do
        local xn2, yn2 = math.rotVecCCW(xn, yn)
        local hit, x3, y3, xn3, yn3, frac = util.traceLine(x2, y2, x2+xn2*puddleW, y2+yn2*puddleW, bloodspray.collideFilter)
        if hit then
            custom = true
            leftW = puddleW*util.binarySearch(0, frac, 6, function(t)
                local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
                local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
                return hit2~=nil
            end)
        else
            local x4, y4 = x2+xn2*puddleW, y2+yn2*puddleW
            local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
            if hit2==nil then
                custom = true
                leftW = puddleW*util.binarySearch(0, 1, 6, function(t)
                    local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
                    local hit3 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
                    return hit3~=nil
                end)
            end
        end
    end
    do
        local xn2, yn2 = math.rotVecCW(xn, yn)
        local hit, x3, y3, xn3, yn3, frac = util.traceLine(x2, y2, x2+xn2*puddleW, y2+yn2*puddleW, bloodspray.collideFilter)
        if hit then
            custom = true
            rightW = puddleW*util.binarySearch(0, frac, 6, function(t)
                local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
                local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
                return hit2~=nil
            end)
        else
            local x4, y4 = x2+xn2*puddleW, y2+yn2*puddleW
            local hit2 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
            if hit2==nil then
                custom = true
                rightW = puddleW*util.binarySearch(0, 1, 6, function(t)
                    local x4, y4 = x2+xn2*puddleW*t, y2+yn2*puddleW*t
                    local hit3 = util.traceLine(x4, y4, x4-xn*0.006, y4-xn*0.006, bloodspray.collideFilter)
                    return hit3~=nil
                end)
            end
        end
    end
    if custom then
        blood.mesh = love.graphics.newMesh({{-leftW, -puddleH}, {-leftW, puddleH}, {rightW, puddleH}, {rightW, -puddleH}}, "fan", "static")
        blood.custommesh = true
    else
        blood.mesh = bloodspray.puddle
    end
end

function bloodspray:thinkPuddle()
end

function bloodspray:draw()
    love.graphics.setColor( 1, 0, 0, self.alpha )
    for k, blood in ipairs(self.spray) do
        love.graphics.draw(blood.mesh, blood.x, blood.y, blood.a)
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function bloodspray:destroy()
    world:removeEntity(self)
    for k, v in ipairs(self.spray) do
        if v.custommesh then
            v.mesh:release()
        end
    end
end
