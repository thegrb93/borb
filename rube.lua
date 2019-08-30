
local function vec(x)
    if x==nil or x==0 then return 0,0 else return x.x,-x.y end
end

local function numToBits(x)
    local t = {}
    for i=1, 16 do
        if x % (i+i) >= i then
            t[#t+1] = i
        end
    end
    return unpack(t)
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
    circle = function(circle)
        if circle.center == 0 then
            return love.physics.newCircleShape(0, 0, circle.radius)
        else
            return love.physics.newCircleShape(circle.center.x, -circle.center.y, circle.radius)
        end
    end,

    polygon = function(polygon)
        local verts = {}
        for i=1, #polygon.vertices.x do
            verts[#verts+1] = polygon.vertices.x[i]
            verts[#verts+1] = -polygon.vertices.y[i]
        end
        return love.physics.newPolygonShape(verts)
    end,

    chain = function(chain)
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

                local shape = love.physics.newChainShape(false, verts)

                -- setAttr(fixture.chain, "hasNextVertex", shape, "m_hasNextVertex",)
                -- setAttrVec(fixture.chain, "nextVertex", shape, "m_nextVertex",)
                -- setAttr(fixture.chain, "hasPrevVertex", shape, "m_hasPrevVertex",)
                -- setAttrVec(fixture.chain, "prevVertex", shape, "m_prevVertex")

                return shape
            else
                return love.physics.newChainShape(false, verts)
            end
        else
            return love.physics.newEdgeShape(verts[1], verts[2], verts[3], verts[4])
        end
    end
}

local function createFixture(bodyObj, fixture)
    local shapeObj
    for k, v in pairs(shapeTypes) do
        if fixture[k] then
            shapeObj = v(fixture[k])
            break
        end
    end
    
    local fixtureObj = love.physics.newFixture(bodyObj, shapeObj, fixture.density)

    -- if fixture["filter-categoryBits"] then
        -- fixtureObj:setCategory(numToBits(fixture["filter-categoryBits"]))
    -- else
        -- fixtureObj:setCategory(1)
    -- end
    -- if fixture["filter-maskBits"] then
        -- fixtureObj:setMask(numToBits(fixture["filter-maskBits"]))
    -- else
        -- fixtureObj:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
    -- end
    
    -- if fixture["filter-groupIndex"] then fixtureObj:setGroupIndex(fixture["filter-groupIndex"]) end
    if fixture.friction then fixtureObj:setFriction(fixture.friction) end
    if fixture.sensor then fixtureObj:setSensor(fixture.sensor) end
    if fixture.restitution then fixtureObj:setRestitution(fixture.restitution) end

    return shapeObj, fixtureObj
end

local bodytypes = {
    "static","kinematic","dynamic"
}
local function createBody(world, body)
    local x, y = vec(body.position)
    local bodyObj = love.physics.newBody(
        world,
        x, y,
        bodytypes[body.type+1]
    )

    --if world.allowSleep then world:(world.allowSleep) end
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

    local fixtures = {}
    for _, fixture in pairs(body.fixture) do
        fixtures[fixture.name] = createFixture(bodyObj, fixture)
    end

    return bodyObj, fixtures
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
            local bodyObj, fixtures = createBody(world, body)
            bodies[id] = {body = bodyObj, fixtures = fixtures}
        end
    end

    if rube.joint then
        for _, joint in pairs(rube.joint) do
            local create = jointsTypes[joint.type]
            if create then
                jointDef = create(joint, bodies[joint.bodyA+1].body, bodies[joint.bodyB+1].body)
            else
                error("Unknown joint type: "..joint.type)
            end
        end
    end

    return bodies
end
