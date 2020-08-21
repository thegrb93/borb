local util = {}

function util.newPDController(body, pgain)
    local mass, inertia = body:getMass(), body:getInertia()
    local dgain = math.sqrt(pgain)*2
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

return util
