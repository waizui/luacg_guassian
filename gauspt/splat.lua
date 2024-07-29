local lang = require("language")
local quaternion = require("structures.quaternion")
local vector = require("structures.vector")

---@class Splat
---@field position Vector
---@field rotation Quaternion
---@field scale Vector
local Splat = lang.newclass("Splat")

function Splat:ctor()
	self.position = vector.new(3, 0, 0, 8)
	self.rotation = quaternion.identity()
	self.scale = vector.new(3, 1, 1, 1)
end

return Splat
