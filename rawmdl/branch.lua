model{
	name = "branch",
	models = {
		mesh{path = "branch.ply", materials = {"bark.png"}}
	},
	bodies = {
		body{static = true},
	},
	shapes = {
		shape{type="polygonList", mesh = 1},
	},
	fixtures = {
		fixture{shape = 1, body = 1}
	}
}

