local meshes = {
	mesh{"branch.ply", materials = {"bark.png"}}
}

local physics = {
	fixture{
		body = body{static = true},
		shape = shape{type="polygon", mesh = meshes[1]},
	}
}

model{
	name = "branch",
	meshes = meshes,
	physics = physics
}

