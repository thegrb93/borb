
local function getVec(x)
    if x==nil or x==0 then return 0,0 else return x.x,x.y end
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
    revolute = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newRevoluteJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
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

    distance = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newDistanceJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency then jointDef:setFrequency(joint.frequency) end
        if joint.length then jointDef:setLength(joint.length) end

        return jointDef
    end,

    prismatic = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local ax,ay = vec(joint.localAxisA)
        local jointDef = love.physics.newPrismaticJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
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

    wheel = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local ax,ay = vec(joint.localAxisA)
        local jointDef = love.physics.newWheelJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
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

    rope = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newRopeJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            x1, y1,
            x2, y2,
            joint.maxLength,
            joint.collideConnected
        )

        return jointDef
    end,

    motor = function(bodies, joint)
        local jointDef = love.physics.newMotorJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.correctionFactor,
            joint.collideConnected
        )

        return jointDef
    end,

    weld = function(bodies, joint)
        local jointDef = love.physics.newWeldJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            x1, y1,
            x2, y2,
            joint.collideConnected
        )

        if joint.dampingRatio then jointDef:setDampingRatio(joint.dampingRatio) end
        if joint.frequency then jointDef:setFrequency(joint.frequency) end

        return jointDef
    end,

    friction = function(bodies, joint)
        local x1,y1 = vec(joint.anchorA)
        local x2,y2 = vec(joint.anchorB)
        local jointDef = love.physics.newFrictionJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
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
    circle = function(fixture)
        if fixture.circle.center == 0 the
            return love.physics.newCircleShape(0, 0, fixture.circle.radius)
        else
            return love.physics.newCircleShape(fixture.circle.center.x, fixture.circle.center.y, fixture.circle.radius)
        end
    end,

    polygon = function(fixture)
        local verts = {}
        for i=1, #fixture.polygon.vertices.x do
            verts[#verts+1] = fixture.polygon.vertices.x[i]
            verts[#verts+1] = fixture.polygon.vertices.y[i]
        end
        return love.physics.newPolygonShape(verts)
    end,

    chain = function(fixture)
        local verts = {}
        for i=1, #fixture.chain.vertices.x do
            verts[#verts+1] = fixture.chain.vertices.x[i]
            verts[#verts+1] = fixture.chain.vertices.y[i]
        end

        if #verts >= 6 then
            if "hasNextVertex" in fixture.chain.keys():

                -- del last vertice to prevent crash from first and last
                -- vertices being to close
                --del chain_vertices[-1]

                local shape = love.physics.newChainShape(true, verts)

                setAttr(fixture.chain, "hasNextVertex", shape, "m_hasNextVertex",)
                setAttrVec(fixture.chain, "nextVertex", shape, "m_nextVertex",)
                setAttr(fixture.chain, "hasPrevVertex", shape, "m_hasPrevVertex",)
                setAttrVec(fixture.chain, "prevVertex", shape, "m_prevVertex")

                return shape
            else
                return love.physics.newChainShape(false, verts)
            end
        else
            return love.physics.newEdgeShape(verts[1], verts[2], verts[3], verts[4])
        end
    end
}

function createBody(world, body)
    local x,y = vec(body.position)
    local bodyObj = love.physics.newBody(
        world,
        x, y,
        body.type
    )

    --if world.allowSleep then world:(world.allowSleep) end
    if body.angle then body:setAngle(body.angle) end
    if body.angularDamping then body:setAngularDamping(body.angularDamping) end
    if body.angularVelocity then body:setAngularVelocity(body.angularVelocity) end
    if body.awake then body:setAwake(body.awake) end
    if body.bullet then body:setBullet(body.bullet) end
    if body.fixedRotation then body:setFixedRotation(body.fixedRotation) end
    if body.linearDamping then body:setLinearDamping(body.linearDamping) end
    if body.linearVelocity then body:setLinearVelocity(vec(body.linearVelocity)) end
    if body.gravityScale then body:(body.gravityScale) end
    if body["massData-I"] then bodyObj:setInertia(body["massData-I"]) end

    for _, fixture in pairs(body.fixture) do
        createFixture(bodyObj, fixture)
    end

    return bodyObj
end

function createFixture(world_body, fixture)
    local shapeObj
    for k, v in pairs(shapeTypes) do
        if fixture[k] then
            shapeObj = v(fixture)
            break
        end
    end
    
    local fixtureObj = love.physics.newFixture(world_body, shapeObj, fixture.density)

    if fixture["filter-categoryBits"] then
        fixtureObj:setCategory(numToBits(fixture["filter-categoryBits"]))
    else
        fixtureObj:setCategory(1)
    end
    if fixture["filter-maskBits"] then
        fixtureObj:setMask(numToBits(fixture["filter-maskBits"]))
    else
        fixtureObj:setMask(65535)
    end
    
    if fixture["filter-groupIndex"] then fixtureObj:setGroupIndex(fixture["filter-groupIndex"]) end
    if fixture.friction then fixture:setFriction(fixture.friction) end
    if fixture.sensor then fixture:setSensor(fixture.sensor) end
    if fixture.restitution then fixture:setRestitution(fixture.restitution) end

    return shapeObj, fixtureObj
end

return function(world, rube)
    --[[world = b2.b2World(
        autoClearForces=rube.autoClearForces,
        continuousPhysics=rube.continuousPhysics,
        gravity={rube.gravity.x,rube.gravity.y}
        subStepping=rube.subStepping,
        warmStarting=rube.warmStarting,
    )]]

    local bodies, shapes, fixtures = {}
    if rube.body then
        for _, body in pairs(rube.body) do
            bodies[body.name] = createBody(world, body)
        end
    end

    if rube.joint then
        for _, joint in pairs(rube.joint) do
            local create = jointsTypes[joint.type]
            if create then
                jointDef = create(joint, bodies)
            end
        end
    end
    return world
end
