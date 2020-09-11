local util = {}

function util.newPDController(body, pgain, dgain)
    local mass, inertia = body:getMass(), body:getInertia()
    local dgain = dgain or math.sqrt(pgain)*2
    return function(dx, dy, da, ddx, ddy, dda)
        body:applyForce((dx*pgain + ddx*dgain)*mass, (dy*pgain + ddy*dgain)*mass)
        body:applyTorque((da*pgain + dda*dgain)*inertia)
    end
end

function util.rungeKutta(x, y, a, dx, dy, da)
    local dt = world.dt
    return
        function(x_, y_, a_, dx_, dy_, da_)
            x, y, a, dx, dy, da = x_, y_, a_, dx_, dy_, da_
        end,
        function()
            return x, y, a, dx, dy, da
        end,
        function(fx, fy, fa)
            dx = dx + fx*dt
            dy = dy + fy*dt
            da = da + fa*dt
            x = x + dx*dt
            y = y + dy*dt
            a = a + da*dt
            return x, y, a, dx, dy, da
        end
end

function util.binarySearch(xmin, xmax, iter, func)
    local size = (xmax - xmin)*0.5
    xmin = xmin + size
    for i=1, iter do
        local val = func(xmin)
        size = size * 0.5
        if val then
            xmin = xmin + size
        else
            xmin = xmin - size
        end
    end
    return xmin
end

function util.traceLine(x1, y1, x2, y2, filter)
    if filter==nil then filter = function() return true end end
    local fixture, x, y, xn, yn, fraction
    world.physworld.box2d_world:rayCast(x1, y1, x2, y2, function(fixture_, x_, y_, xn_, yn_, fraction_)
        if filter(fixture_) then
            fixture, x, y, xn, yn, fraction = fixture_, x_, y_, xn_, yn_, fraction_
            return 0
        end
        return -1
    end)
    return fixture, x, y, xn, yn, fraction
end

function math.normalizeVec(x, y)
    local l = math.sqrt(x^2+y^2)
    return x/l, y/l
end

function math.length(x, y)
    return math.sqrt(x^2+y^2)
end

function math.lengthSqr(x, y)
    return x^2+y^2
end

function math.clamp(x, min, max)
    return math.max(math.min(x, max), min)
end

function math.angnorm(x)
    return (x + math.pi) % (math.pi*2) - math.pi
end

function math.vecToAng(x, y)
    return math.atan2(x, -y)
end

function math.randVecNorm()
    local t = math.random()*(2*math.pi)
    return math.cos(t), math.sin(t)
end

function math.randVecSquare()
    return math.random()*2-1, math.random()*2-1
end

function math.rotVecCW(x, y)
    return -y, x
end

function math.rotVecCCW(x, y)
    return y, -x
end

function math.rotVec(x, y, a)
    local c, s = math.cos(a), math.sin(a)
    return c*x + s*y, c*y - s*x
end

return util
