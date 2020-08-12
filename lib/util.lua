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
    return
    function()
        return x, y, a, dx, dy, da
    end,
    function(fx, fy, fa)
        dx = dx + fx*world.dt
        dy = dy + fy*world.dt
        da = da + fa*world.dt
        x = x + dx*world.dt
        y = y + dy*world.dt
        a = a + da*world.dt
        return x, y, a, dx, dy, da
    end
end

return util
