local t = require(script.Parent.Parent.t)

return {
	projectileType = t.interface({
		speed = t.number,
		dropRate = t.number,

		maxTravelTime = t.optional(t.number),
		callback = t.optional(t.callback),
	}),

	projectileData = t.interface({
		origin = t.Vector3,
		direction = t.Vector3,
		projectileType = t.string,
	}),
}
