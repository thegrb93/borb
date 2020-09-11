local mosquito = types.mosquito
local bloodspray = types.bloodspray

function mosquito:initialize(x, y)
    self.drawCategory = world.drawCategories.foreground
    
    self.body = world.physworld:newCircleCollider(x, y, 1)
    self.body:setType("dynamic")
    self.body:setLinearDamping(0)
    self.body:setAngularDamping(0)
    self.body:setBullet(true)
    self.body:setObject(self)
    self.body:setCollisionClass("Enemy")
    self.body:setGravityScale(0)
    
    local fixture = self.body.fixtures.Main
    fixture:setFriction(10)
    fixture:setRestitution(0.5)
end

function mosquito:explode(x, y, xn, yn)
    world:addEntity(bloodspray:new(x, y, xn, yn))
    self.body:setGravityScale(1)
end

function mosquito:destroy()
end

function mosquito:think()
end

function mosquito:draw()
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

    self.bloodspray = {}
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
        self.bloodspray[i] = blood
    end
    
    self.alpha = 1
    flux.to(self, 2, { alpha = 0 }):ease("linear"):delay(10):oncomplete(function() self:destroy() end)
end

function bloodspray:think()
    for k, blood in ipairs(self.bloodspray) do
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
    for k, blood in ipairs(self.bloodspray) do
        love.graphics.draw(blood.mesh, blood.x, blood.y, blood.a)
    end
    love.graphics.setColor( 1, 1, 1, 1 )
end

function bloodspray:destroy()
    world:removeEntity(self)
    for k, v in ipairs(self.bloodspray) do
        if v.custommesh then
            v.mesh:release()
        end
    end
end
