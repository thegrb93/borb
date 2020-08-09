local wf = require("lib/windfield")

local function vec(x)
    if x==nil or x==0 then return 0,0 else return x.x,-x.y end
end

local jointsTypes = {
    revolute = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newRevoluteJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected,
            joint.refAngle
        )

        if joint.enableLimit then jointDef:setLimitsEnabled(joint.enableLimit) end
        if joint.enableMotor then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.jointSpeed then jointDef:setJointSpeed(joint.jointSpeed) end
        if joint.lowerLimit then jointDef:setLowerLimit(joint.lowerLimit) end
        if joint.maxMotorTorque then jointDef:setMaxMotorTorque(joint.maxMotorTorque) end
        if joint.motorSpeed then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.upperLimit then jointDef:setUpperLimit(joint.upperLimit) end

        return jointDef
    end,

    distance = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newDistanceJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency then jointDef:setFrequency(joint.frequency) end
        if joint.length then jointDef:setLength(joint.length) end

        return jointDef
    end,

    prismatic = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local ax,ay = vec(joint.localAxisA)
        local jointDef = love.physics.newPrismaticJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            ax, ay,
            joint.collideConnected
        )

        if joint.enableLimit then jointDef:setLimitsEnabled(joint.enableLimit) end
        if joint.enableMotor then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.lowerLimit then jointDef:setLowerLimit(joint.lowerLimit) end
        if joint.maxMotorForce then jointDef:setMaxMotorForce(joint.maxMotorForce) end
        if joint.motorSpeed then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.upperLimit then jointDef:setUpperLimit(joint.upperLimit) end

        return jointDef
    end,

    wheel = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local ax,ay = vec(joint.localAxisA)
        local jointDef = love.physics.newWheelJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            ax, ay,
            joint.collideConnected
        )

        if joint.enableMotor then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.maxMotorTorque then jointDef:setMaxMotorTorque(joint.maxMotorTorque) end
        if joint.motorSpeed then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.springDampingRatio then jointDef:setSpringDampingRatio(joint.springDampingRatio) end
        if joint.springFrequency then jointDef:setSpringFrequency(joint.springFrequency) end

        return jointDef
    end,

    rope = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newRopeJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.maxLength,
            joint.collideConnected
        )

        return jointDef
    end,

    motor = function(joint, bodyA, bodyB)
        local jointDef = love.physics.newMotorJoint(
            bodyA, bodyB,
            joint.correctionFactor,
            joint.collideConnected
        )

        return jointDef
    end,

    weld = function(joint, bodyA, bodyB)
        local jointDef = love.physics.newWeldJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency then jointDef:setFrequency(joint.frequency) end

        return jointDef
    end,

    friction = function(joint, bodyA, bodyB)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newFrictionJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.maxForce then jointDef:setMaxForce(joint.maxForce) end
        if joint.maxTorque then jointDef:setMaxTorque(joint.maxTorque) end

        return jointDef
    end
}

local shapeTypes = {
    circle = function(body, name, circle)
        local x, y = vec(circle.center)
        body:addShape(name, "CircleShape", x, y, circle.radius)
    end,

    polygon = function(body, name, polygon)
        local verts = {}
        for i=1, #polygon.vertices.x do
            verts[#verts+1] = polygon.vertices.x[i]
            verts[#verts+1] = -polygon.vertices.y[i]
        end
        body:addShape(name, "PolygonShape", verts)
    end,

    chain = function(body, name, chain)
        local verts = {}
        for i=1, #chain.vertices.x do
            verts[#verts+1] = chain.vertices.x[i]
            verts[#verts+1] = -chain.vertices.y[i]
        end

        if #verts >= 6 then
            if chain.hasNextVertex then

                -- del last vertice to prevent crash from first and last
                -- vertices being to close
                --del chain_vertices[-1]

                body:addShape(name, "ChainShape", false, verts)

                -- setAttr(fixture.chain, "hasNextVertex", shape, "m_hasNextVertex",)
                -- setAttrVec(fixture.chain, "nextVertex", shape, "m_nextVertex",)
                -- setAttr(fixture.chain, "hasPrevVertex", shape, "m_hasPrevVertex",)
                -- setAttrVec(fixture.chain, "prevVertex", shape, "m_prevVertex")
            else
                body:addShape(name, "ChainShape", false, verts)
            end
        else
            body:addShape(name, "EdgeShape", verts[1], verts[2], verts[3], verts[4])
        end
    end
}

local function createFixture(bodyObj, fixture)
    for k, v in pairs(shapeTypes) do
        if fixture[k] then
            v(bodyObj, fixture.name, fixture[k])
            break
        end
    end
    
    local fixtureObj = bodyObj.fixtures[fixture.name]
    if fixture.density then fixtureObj:setDensity(fixture.density) end
    if fixture.friction then fixtureObj:setFriction(fixture.friction) end
    if fixture.sensor then fixtureObj:setSensor(fixture.sensor) end
    if fixture.restitution then fixtureObj:setRestitution(fixture.restitution) end
end

local bodytypes = {
    "static","kinematic","dynamic"
}
local function createBody(world, body)
    local x, y = vec(body.position)
    local bodyObj = wf.Collider.new(
        world, nil,
        x, y
    )

    bodyObj:setType(bodytypes[body.type+1])
    if body.angle then bodyObj:setAngle(body.angle) end
    if body.angularDamping then bodyObj:setAngularDamping(body.angularDamping) end
    if body.angularVelocity then bodyObj:setAngularVelocity(body.angularVelocity) end
    if body.awake then bodyObj:setAwake(body.awake) end
    if body.bullet then bodyObj:setBullet(body.bullet) end
    if body.fixedRotation then bodyObj:setFixedRotation(body.fixedRotation) end
    if body.linearDamping then bodyObj:setLinearDamping(body.linearDamping) end
    if body.linearVelocity then bodyObj:setLinearVelocity(vec(body.linearVelocity)) end
    if body.gravityScale then bodyObj:setGravityScale(body.gravityScale) end
    if body["massData-I"] then bodyObj:setInertia(body["massData-I"]) end

    for _, fixture in ipairs(body.fixture) do
        createFixture(bodyObj, fixture)
    end

    return bodyObj
end

return function(world, rube)
    --[[world = b2.b2World(
        autoClearForces=rube.autoClearForces,
        continuousPhysics=rube.continuousPhysics,
        gravity={rube.gravity.x,rube.gravity.y}
        subStepping=rube.subStepping,
        warmStarting=rube.warmStarting,
    )]]

    local bodies = {}
    if rube.body then
        for id, body in pairs(rube.body) do
            bodies[id] = createBody(world, body)
        end
    end

    local joints = {}
    if rube.joint then
        for _, joint in pairs(rube.joint) do
            local create = jointsTypes[joint.type]
            if create then
                joints[#joints+1] = create(joint, bodies[joint.bodyA+1].body, bodies[joint.bodyB+1].body)
            else
                error("Unknown joint type: "..joint.type)
            end
        end
    end

    return bodies, joints
end
