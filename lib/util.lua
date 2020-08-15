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

return util
