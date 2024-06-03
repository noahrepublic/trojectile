local part = Instance.new("Part")

local size = part.Size

part:Destroy()

return {
	testProjectile = {
		speed = 250,
		dropRate = 0.1, -- drop per frame

		callback = function(hit, hitPoint)
			print("hit", hit, hitPoint)
		end,

		type = {
			method = "Blockcast",
			size = size
		},
	},
}
