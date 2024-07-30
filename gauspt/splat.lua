local lang = require("language")
local quaternion = require("structures.quaternion")
local vector = require("structures.vector")

---@class Splat
---@field position Vector
---@field rotation Quaternion
---@field scale Vector
local Splat = lang.newclass("Splat")

-- splat also has the propeties of SH coefficients, opacity value, but they are omited in this demo
function Splat:ctor()
	self.position = vector.new(3, 0, 0, 0)
	self.rotation = quaternion.identity()
	self.scale = vector.new(3, 1, 1, 1)
end

return Splat
