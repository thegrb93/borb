function createWorldFromJson(jsw)
    world = b2.b2World(
        autoClearForces=jsw.autoClearForces,
        continuousPhysics=jsw.continuousPhysics,
        gravity={jsw.gravity.x,jsw.gravity.y}
        subStepping=jsw.subStepping,
        warmStarting=jsw.warmStarting,
    )

    local bodies = {}
    if jsw.body then
        for _, body in pairs(jsw.body) do
            add_body(world, jsw, js_body)
        end
    end

    if jsw.joint then
        for _, joint in pairs(jsw.joint) do
            local create = jointsTypes[joint.type]
            if create then
                jointDef = create(joint, bodies)
            end
        end
    end
    return world


local jointsTypes = {
    revolute = function(bodies, joint)
        local jointDef = love.physics.newRevoluteJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected,
            joint.refAngle
        )

        setAttr(joint, "enableLimit", jointDef)
        setAttr(joint, "enableMotor", jointDef)
        setAttr(joint, "jointSpeed", jointDef, "motorSpeed")
        setAttr(joint, "lowerLimit", jointDef, "lowerAngle")
        setAttr(joint, "maxMotorTorque", jointDef)
        setAttr(joint, "motorSpeed", jointDef)
        setAttr(joint, "upperLimit", jointDef, "upperAngle")

        return jointDef
    end,

    distance = function(bodies, joint)
        local jointDef = love.physics.newDistanceJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected
        )

        setAttr(joint, "dampingRatio", jointDef)
        setAttr(joint, "frequency", jointDef, "frequencyHz")
        setAttr(joint, "length", jointDef)

        return jointDef
    end,

    prismatic = function(bodies, joint)
        local jointDef = love.physics.newPrismaticJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected
        )

        setAttr(joint, "enableLimit", jointDef)
        setAttr(joint, "enableMotor", jointDef)
        setAttrVec(joint, "localAxisA", jointDef, "axis")
        setAttr(joint, "lowerLimit", jointDef, "lowerTranslation")
        setAttr(joint, "maxMotorForce", jointDef)
        setAttr(joint, "motorSpeed", jointDef)
        setAttr(joint, "refAngle", jointDef, "referenceAngle")
        setAttr(joint, "upperLimit", jointDef, "upperTranslation")

        return jointDef
    end,

    wheel = function(bodies, joint)
        local jointDef = love.physics.newWheelJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected
        )

        setAttr(joint, "enableMotor", jointDef)
        setAttrVec(joint, "localAxisA", jointDef)
        setAttr(joint, "maxMotorTorque", jointDef)
        setAttr(joint, "motorSpeed", jointDef)
        setAttr(joint, "springDampingRatio", jointDef, "dampingRatio")
        setAttr(joint, "springFrequency", jointDef, "frequencyHz")

        return jointDef
    end,

    rope = function(bodies, joint)
        local jointDef = love.physics.newRopeJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
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

        setAttrVec(joint, "anchorA", jointDef, "localAnchorA")
        setAttrVec(joint, "anchorB", jointDef, "localAnchorB")
        setAttr(joint, "maxForce", jointDef)
        setAttr(joint, "maxTorque", jointDef)
        setAttrVec(joint, "anchorA", jointDef, "linearOffset")

        return jointDef
    end,

    weld = function(bodies, joint)
        local jointDef = love.physics.newWeldJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected
        )

        setAttr(joint, "refAngle", jointDef, "referenceAngle")
        setAttr(joint, "dampingRatio", jointDef)
        setAttr(joint, "frequency", jointDef, "frequencyHz")

        return jointDef
    end,

    friction = function(bodies, joint)
        local jointDef = love.physics.newFrictionJoint(
            bodies[joint.bodyA],
            bodies[joint.bodyB],
            joint.anchorA.x, joint.anchorA.y,
            joint.anchorB.x, joint.anchorB.y,
            joint.collideConnected
        )

        setAttr(joint, "maxForce", jointDef)
        setAttr(joint, "maxTorque", jointDef)

        return jointDef
    end
}



function add_body(world, body)
    local bodyDef = love.physics.newBody(
        world,
        body.position.x,
        body.position.y,
        body.type
    )

    setAttr(jsw, "allowSleep", bodyDef)
    setAttr(body, "angle", bodyDef)
    setAttr(body, "angularDamping", bodyDef)
    setAttr(body, "angularVelocity", bodyDef)
    setAttr(body, "awake", bodyDef)
    setAttr(body, "bullet", bodyDef)
    setAttr(body, "fixedRotation", bodyDef)
    setAttr(body, "linearDamping", bodyDef)
    setAttrVec(body, "linearVelocity", bodyDef)
    setAttr(body, "gravityScale", bodyDef)  # pybox2d non documented
    # setAttr(body, "massData-I", bodyDef, "inertiaScale")
    setAttr(body, "type", bodyDef)
    setAttr(body, "awake", bodyDef)

    for _, fixture in pairs(body.fixture) do
        add_fixture(bodyDef, jsw, fixture)
    end

    return bodyDef
end

local shapeTypes = {
	circle = function()
        if jsw_fixture.circle.center == 0:
            center_b2Vec2 = b2.b2Vec2(0, 0)
        else:
            center_b2Vec2 = rubeVecToB2Vec2(
                jsw_fixture.circle.center
                )
        fixtureDef.shape = b2.b2CircleShape(
            pos=center_b2Vec2,
            radius=jsw_fixture.circle.radius,
            )
	end,

	polygon = function()
    
        polygon_vertices = rubeVecArrToB2Vec2Arr(
            jsw_fixture.polygon.vertices
            )
        fixtureDef.shape = b2.b2PolygonShape(vertices=polygon_vertices)
	end,

	chain = function()
         chain_vertices = rubeVecArrToB2Vec2Arr(
            jsw_fixture.chain.vertices
            )

        if len(chain_vertices) >= 3 then
            if "hasNextVertex" in jsw_fixture.chain.keys():

                # del last vertice to prevent crash from first and last
                # vertices being to close
                del chain_vertices[-1]

                fixtureDef.shape = b2.b2LoopShape(
                    vertices_loop=chain_vertices,
                    count=len(chain_vertices),
                    )

                setAttr(
                    jsw_fixture.chain,
                    "hasNextVertex",
                    fixtureDef.shape,
                    "m_hasNextVertex",
                    )
                setAttrVec(
                    jsw_fixture.chain,
                    "nextVertex",
                    fixtureDef,
                    "m_nextVertex",
                    )

                setAttr(
                    jsw_fixture.chain,
                    "hasPrevVertex",
                    fixtureDef.shape,
                    "m_hasPrevVertex",
                    )
                setAttrVec(
                    jsw_fixture.chain,
                    "prevVertex",
                    fixtureDef.shape,
                    "m_prevVertex"
                    )

            else
                fixtureDef.shape = b2.b2ChainShape(
                    vertices_chain=chain_vertices,
                    count=len(chain_vertices),
                    )
            end

        if #chain_vertices < 3 then
            fixtureDef.shape = b2.b2EdgeShape(
                vertices=chain_vertices,
                )
        end
	end
}

function add_fixture(world_body, jsw, jsw_fixture)
    local shapeDef
    for k, v in pairs(shapeTypes) do
        if jsw_fixture[k] then
            shapeDef = v(jsw_fixture)
            break
        end
    end
    
    local fixtureDef = love.physics.newFixture(world_body, shapeDef, jsw_fixture.density)

    if jsw_fixture["filter-categoryBits"] then
        setAttr(jsw_fixture, "filter-categoryBits", fixtureDef, "categoryBits")
    else
        fixtureDef.categoryBits = 1
    end

    --"filter-maskBits": 1, if not present, interpret as 65535
    if jsw_fixture["filter-maskBits"] then
        setAttr(jsw_fixture, "filter-maskBits", fixtureDef, "maskBits")
    else
        fixtureDef.maskBits = 65535
    end

    setAttr(jsw_fixture, "filter-groupIndex", fixtureDef, "groupIndex")
    setAttr(jsw_fixture, "friction", fixtureDef)
    setAttr(jsw_fixture, "sensor", fixtureDef, "isSensor")
    setAttr(jsw_fixture, "restitution", fixtureDef)

    return shapeDef, fixtureDef
end

function setAttr(source_dict,source_key,target_obj,target_attr)
    local val = source_dict[source_key]
    if val then
        if target_attr == nil then
            target_attr = source_key
        end
        target_obj[target_attr](target_obj, val)
    end
end

function setAttrVec(source_dict,source_key,target_obj,target_attr)
    local val = source_dict[source_key]
    if val then
        if target_attr == nil then
            target_attr = source_key
        end
        if val == 0 then
            target_obj[target_attr](target_obj, 0, 0)
        else
            target_obj[target_attr](target_obj, val.x, val.y)
        end
    end
end
