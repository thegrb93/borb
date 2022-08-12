model{
	name = "branch",
	models = {
		mesh{path = "branch.ply", materials = {"bark.png"}}
	},
	bodies = {
		body{type = "static", model = 1, fixtures = {1}},
	},
	shapes = {
		shape{type = "quadmesh", mesh = 1},
	},
	fixtures = {
		fixture{shape = 1}
	}
}

