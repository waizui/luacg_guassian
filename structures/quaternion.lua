local lang = require("language")
local matrix = require("structures.matrix")

---@class Quaternion
---@field r number
---@field i number
---@field j number
---@field k number
local Quaternion = lang.newclass("Quaternion")

function Quaternion.identity()
	---@type Quaternion
	local q = Quaternion.new()
	q.r = 1 -- cos(0)
	q.i = 0
	q.j = 0
	q.k = 0

	return q
end

--3x3
---@return Matrix
function Quaternion:matrix()
	local r, i, j, k = self.r, self.i, self.j, self.k

  -- stylua: ignore
  local mat = {
    1 - 2 * (j * j + k * k), 2 * (i * j - r * k), 2 * (i * k + r * j),
    2 * (i * j + r * k), 1 - 2 * (i * i + k * k), 2 * (j * k - r * i),
    2 * (i * k - r * j), 2 * (j * k + r * i), 1 - 2 * (i * i + j * j),
  }

	return matrix.new(3, 3, table.unpack(mat))
end

function Quaternion:rotate(x, y, z) end

function Quaternion:mul(q) end

return Quaternion
