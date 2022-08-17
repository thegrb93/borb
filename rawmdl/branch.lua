model{
	name = "branch",
	meshgroups = {
		meshgroup{path = "branch.ply", materials = {"bark.png"}}
	},
	bodies = {
		body{type = "static", meshgroup = 1, fixtures = {1}},
	},
	shapes = {
		shape{type = "quadmesh", meshgroup = 1},
	},
	fixtures = {
		fixture{shape = 1}
	}
}

