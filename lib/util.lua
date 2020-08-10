local util = {}

function util.newPDController(body, gain)
    local mass, inertia = body:getMass(), body:getInertia()
    local pgain = gain*world.dt
	local dgain = math.sqrt(pgain*world.dt)*2
    return function(dx, dy, da, ddx, ddy, dda)
        body:applyForce((dx*pgain + ddx*dgain)*mass, (dy*pgain + ddy*dgain)*mass)
        body:applyAngularForce((da*pgain + dda*dgain)*inertia)
    end
end

return util
