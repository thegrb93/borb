local wf = require("lib/windfield")

local function vec(x)
    if x==nil or x==0 then return 0,0 else return x.x,-x.y end
end

local jointsTypes = {
    revolute = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local jointDef = love.physics.newRevoluteJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected,
            joint.refAngle
        )

        if joint.enableLimit~=nil then jointDef:setLimitsEnabled(joint.enableLimit) end
        if joint.enableMotor~=nil then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.jointSpeed~=nil then jointDef:setJointSpeed(joint.jointSpeed) end
        if joint.lowerLimit~=nil then jointDef:setLowerLimit(joint.lowerLimit) end
        if joint.maxMotorTorque~=nil then jointDef:setMaxMotorTorque(joint.maxMotorTorque) end
        if joint.motorSpeed~=nil then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.upperLimit~=nil then jointDef:setUpperLimit(joint.upperLimit) end

        return jointDef
    end,

    distance = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local jointDef = love.physics.newDistanceJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio~=nil then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency~=nil then jointDef:setFrequency(joint.frequency) end
        if joint.length~=nil then jointDef:setLength(joint.length) end

        return jointDef
    end,

    prismatic = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local ax,ay = bodyA:getWorldVector(vec(joint.localAxisA))
        local jointDef = love.physics.newPrismaticJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            ax, ay,
            joint.collideConnected
        )

        if joint.enableLimit~=nil then jointDef:setLimitsEnabled(joint.enableLimit) end
        if joint.enableMotor~=nil then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.lowerLimit~=nil then jointDef:setLowerLimit(joint.lowerLimit) end
        if joint.maxMotorForce~=nil then jointDef:setMaxMotorForce(joint.maxMotorForce) end
        if joint.motorSpeed~=nil then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.upperLimit~=nil then jointDef:setUpperLimit(joint.upperLimit) end

        return jointDef
    end,

    wheel = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local ax,ay = bodyA:getWorldVector(vec(joint.localAxisA))
        local jointDef = love.physics.newWheelJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            ax, ay,
            joint.collideConnected
        )

        if joint.enableMotor~=nil then jointDef:setMotorEnabled(joint.enableMotor) end
        if joint.maxMotorTorque~=nil then jointDef:setMaxMotorTorque(joint.maxMotorTorque) end
        if joint.motorSpeed~=nil then jointDef:setMotorSpeed(joint.motorSpeed) end
        if joint.springDampingRatio~=nil then jointDef:setSpringDampingRatio(joint.springDampingRatio) end
        if joint.springFrequency~=nil then jointDef:setSpringFrequency(joint.springFrequency) end

        return jointDef
    end,

    rope = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
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
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local jointDef = love.physics.newWeldJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio~=nil then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency~=nil then jointDef:setFrequency(joint.frequency) end

        return jointDef
    end,

    friction = function(joint, bodyA, bodyB)
        local x1,y1 = bodyA:getWorldPoint(vec(joint.anchorA))
        local x2,y2 = bodyB:getWorldPoint(vec(joint.anchorB))
        local jointDef = love.physics.newFrictionJoint(
            bodyA, bodyB,
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.maxForce~=nil then jointDef:setMaxForce(joint.maxForce) end
        if joint.maxTorque~=nil then jointDef:setMaxTorque(joint.maxTorque) end

        return jointDef
    end
}

local shapeTypes = {
    circle = function(body, name, circle)
        local x, y = vec(circle.center)
        body:addFixture(name, "CircleShape", x, y, circle.radius)
    end,

    polygon = function(body, name, polygon)
        local verts = {}
        for i=1, #polygon.vertices.x do
            verts[#verts+1] = polygon.vertices.x[i]
            verts[#verts+1] = -polygon.vertices.y[i]
        end
        body:addFixture(name, "PolygonShape", verts)
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

                body:addFixture(name, "ChainShape", false, verts)

                -- setAttr(fixture.chain, "hasNextVertex", shape, "m_hasNextVertex",)
                -- setAttrVec(fixture.chain, "nextVertex", shape, "m_nextVertex",)
                -- setAttr(fixture.chain, "hasPrevVertex", shape, "m_hasPrevVertex",)
                -- setAttrVec(fixture.chain, "prevVertex", shape, "m_prevVertex")
            else
                body:addFixture(name, "ChainShape", false, verts)
            end
        else
            body:addFixture(name, "EdgeShape", verts[1], verts[2], verts[3], verts[4])
        end
    end
}

local function createFixture(body, fixture)
    for k, v in pairs(shapeTypes) do
        if fixture[k] then
            v(body, fixture.name, fixture[k])
            break
        end
    end
    
    local fixtureObj = body.fixtures[fixture.name]
    if fixture.density~=nil then fixtureObj:setDensity(fixture.density) end
    if fixture.friction~=nil then fixtureObj:setFriction(fixture.friction) end
    if fixture.sensor~=nil then fixtureObj:setSensor(fixture.sensor) end
    if fixture.restitution~=nil then fixtureObj:setRestitution(fixture.restitution) end
end

local bodytypes = {
    "static","kinematic","dynamic"
}
local function createBody(world, bodydata)
    local body = world:newCollider(vec(bodydata.position))

    body:setType(bodytypes[bodydata.type+1])
    if bodydata.angle~=nil then body:setAngle(bodydata.angle) end
    if bodydata.angularDamping~=nil then body:setAngularDamping(bodydata.angularDamping) end
    if bodydata.angularVelocity~=nil then body:setAngularVelocity(bodydata.angularVelocity) end
    if bodydata.awake~=nil then body:setAwake(bodydata.awake) end
    if bodydata.bullet~=nil then body:setBullet(bodydata.bullet) end
    if bodydata.fixedRotation~=nil then body:setFixedRotation(bodydata.fixedRotation) end
    if bodydata.linearDamping~=nil then body:setLinearDamping(bodydata.linearDamping) end
    if bodydata.linearVelocity~=nil then body:setLinearVelocity(vec(bodydata.linearVelocity)) end
    if bodydata.gravityScale~=nil then body:setGravityScale(bodydata.gravityScale) end
    if bodydata["massData-I"]~=nil then body:setInertia(bodydata["massData-I"]) end

    for _, fixture in ipairs(bodydata.fixture) do
        createFixture(body, fixture)
    end

    return body
end

return function(world, data)
    --[[world = b2.b2World(
        autoClearForces=data.autoClearForces,
        continuousPhysics=data.continuousPhysics,
        gravity={data.gravity.x,data.gravity.y}
        subStepping=data.subStepping,
        warmStarting=data.warmStarting,
    )]]

    local bodies = {}
    if data.body then
        for id, bodydata in pairs(data.body) do
            bodies[id] = createBody(world, bodydata)
        end
    end

    local joints = {}
    if data.joint then
        for _, joint in pairs(data.joint) do
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
