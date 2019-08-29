function createWorldFromJson(jsw)
    world = b2.b2World(
        autoClearForces=jsw.autoClearForces,
        continuousPhysics=jsw.continuousPhysics,
        gravity=rubeVecToB2Vec2(jsw.gravity),
        subStepping=jsw.subStepping,
        warmStarting=jsw.warmStarting,
    )

    local bodies = {}
    if "body" in jsw.keys():
        # add bodies to world
        for js_body in jsw.body:
            add_body(world, jsw, js_body)

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
        setB2Vec2Attr(joint, "localAxisA", jointDef, "axis")
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
        setB2Vec2Attr(joint, "localAxisA", jointDef)
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

        setB2Vec2Attr(joint, "anchorA", jointDef, "localAnchorA")
        setB2Vec2Attr(joint, "anchorB", jointDef, "localAnchorB")
        setAttr(joint, "maxForce", jointDef)
        setAttr(joint, "maxTorque", jointDef)
        setB2Vec2Attr(joint, "anchorA", jointDef, "linearOffset")

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
    setB2Vec2Attr(body, "linearVelocity", bodyDef)
    setAttr(body, "gravityScale", bodyDef)  # pybox2d non documented
    # setAttr(body, "massData-I", bodyDef, "inertiaScale")
    setAttr(body, "type", bodyDef)
    setAttr(body, "awake", bodyDef)

    for _, fixture in pairs(body.fixture) do
        add_fixture(bodyDef, jsw, fixture)
    end

    return bodyDef
end

function add_fixture(world_body, jsw, jsw_fixture)
    local fixtureDef = love.physics.newFixture(world_body, shape, density)

    # special case for rube documentation of
    #"filter-categoryBits": 1, //if not present, interpret as 1
    if "filter-categoryBits" in jsw_fixture.keys():
        setAttr(jsw_fixture, "filter-categoryBits", fixtureDef, "categoryBits")
    else:
        fixtureDef.categoryBits = 1

    # special case for Rube Json property
    #"filter-maskBits": 1, //if not present, interpret as 65535
    if "filter-maskBits" in jsw_fixture.keys():
        setAttr(jsw_fixture, "filter-maskBits", fixtureDef, "maskBits")
    else:
        fixtureDef.maskBits = 65535

    setAttr(jsw_fixture, "density", fixtureDef)
    setAttr(jsw_fixture, "filter-groupIndex", fixtureDef, "groupIndex")
    setAttr(jsw_fixture, "friction", fixtureDef)
    setAttr(jsw_fixture, "sensor", fixtureDef, "isSensor")
    setAttr(jsw_fixture, "restitution", fixtureDef)

    # fixture has one shape that is
    # polygon, circle or chain in json
    # chain may be open or loop, or edge in pyBox2D
    if "circle" in jsw_fixture.keys():  # works ok
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

    if "polygon" in jsw_fixture.keys():  # works ok
        polygon_vertices = rubeVecArrToB2Vec2Arr(
            jsw_fixture.polygon.vertices
            )
        fixtureDef.shape = b2.b2PolygonShape(vertices=polygon_vertices)

    if "chain" in jsw_fixture.keys():  # works ok
        chain_vertices = rubeVecArrToB2Vec2Arr(
            jsw_fixture.chain.vertices
            )

        if len(chain_vertices) >= 3:
            # closed-loop b2LoopShape
            # Done
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
                setB2Vec2Attr(
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
                setB2Vec2Attr(
                    jsw_fixture.chain,
                    "prevVertex",
                    fixtureDef.shape,
                    "m_prevVertex"
                    )

            else:  # open-ended ChainShape
                # Done
                fixtureDef.shape = b2.b2ChainShape(
                    vertices_chain=chain_vertices,
                    count=len(chain_vertices),
                    )

        # json chain is b2EdgeShape
        # Done
        if len(chain_vertices) < 3:
            fixtureDef.shape = b2.b2EdgeShape(
                vertices=chain_vertices,
                )

    # create fixture
    world_body.CreateFixture(fixtureDef)


def rubeVecToB2Vec2(rube_vec):
    # converter from rube json vector to b2Vec2
    return b2.b2Vec2(rube_vec.x, rube_vec.y)


def rubeVecArrToB2Vec2Arr(vector_array):
    """
    # converter from rube json vector array to b2Vec2 array
    """
    return [b2.b2Vec2(x, y) for x, y in zip(
            vector_array.x,
            vector_array.y
            )]


def setB2Vec2Attr(
        source_dict,
        source_key,
        target_obj,
        target_attr=None,  # is source_key if None
        ):
    if source_key in source_dict.keys():
        # setting attr name
        if target_attr is None:
            target_attr = source_key

        # preparing B2Vec
        if source_dict[source_key] == 0:
            vec2 = b2.b2Vec2(0, 0)
        else:
            vec2 = rubeVecToB2Vec2(source_dict[source_key])

        # setting obj's attr value
        setattr(target_obj, target_attr, vec2)
    #else:
    #    print "No key '" + key + "' in dict '" + dict_source.name + "'"
