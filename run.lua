local encode = require("util.pngencoder")
local splat  = require("gauspt.splat")
local matrix = require("structures.matrix")
local vector = require("structures.vector")
local camera = require("render.camera")

local function writebuf(buf, w, h, fname)
  -- write to png
  local png = encode(w, h)
  for i = 1, w * h do
    local v = buf[i]
    if not v then
      png:write({ 0, 0, 0 })
    else
      png:write({ math.floor(v[1] + 0.5), math.floor(v[2] + 0.5), math.floor(v[3] + 0.5) })
    end
  end

  assert(png.done)
  local pngbin = table.concat(png.output)
  local file = assert(io.open(fname, "wb"))
  file:write(pngbin)
  file:close()
end

-- make changes to propeties of Splat, you can get different results
---@return Splat
local function getgaussian()
  ---@type Splat
  local s = splat.new()
  -- away from camera's front at the distance of 1.7
  s.position = vector.new(3, 0, 0, -1.7)
  -- like a squashed ball
  s.scale = vector.new(3, 1, 0.5, 1)
  local q = s.rotation
  -- rotate 45 degree around z axis, pre-calculated : https://waizui.github.io/a_glimpse_of_quaternion/a_glimpse_of_quaternion.html
  q.r = 0.9238
  q.i = 0
  q.j = 0
  q.k = 0.3826

  return s
end

---@param s Splat
---@return Matrix
local function getcovariance3d(s)
  -- scaling matrix
  ---@type Matrix
  local S = matrix.new(3, 3)
  S:set(1, 1, s.scale[1])
  S:set(2, 2, s.scale[2])
  S:set(3, 3, s.scale[3])

  -- rotation matrix
  local R = s.rotation:matrix()
  local M = S:mul(R)
  -- sigma is symetric, the order doesn't matter, RSS^tR^t = (RSS^tR^t)^t = R^tS^tSR
  local sigma = M:transpose():mul(M)
  return sigma
end


---@param s Splat
---@return Matrix,Vector
local function getcovariance2d(s)
  ---@type Camera
  local cam = camera.new()
  local matvp = cam.matrixVP
  local wordpos = s.position
  local viewpos = matvp:mul(vector.new(4, wordpos[1], wordpos[2], wordpos[3], 1))
  -- no need for NDC?

  -- in the origin implement of 3D Gaussian-Splatting, there should be some criterion cchecking of bounds, but for demostration, it is omited.

  local focal, x, y, z = cam.near, viewpos[1], viewpos[2], viewpos[3]

  -- stylua: ignore
  -- jaccobian
  ---@type Matrix
  local J = matrix.new(3, 3, {
    focal / z, 0, -(focal * x) / (z * z),
    0, focal / z, -(focal * y) / (z * z),
    0, 0, 0,
  })

  -- stylua: ignore
  -- view transformation
  ---@type Matrix
  local W = matrix.new(3, 3, {
    matvp:get(1, 1), matvp:get(1, 2), matvp:get(1, 3),
    matvp:get(2, 1), matvp:get(2, 2), matvp:get(2, 3),
    matvp:get(3, 1), matvp:get(3, 2), matvp:get(3, 3),
  })

  local T = W:mul(J)
  local cov3d = getcovariance3d(s)
  local cov2d = T:transpose():mul(cov3d):mul(T)

  return cov2d, vector.new(3, viewpos[1], viewpos[2], viewpos[3])
end

---@param p Vector
---@param cov2d Matrix
local function checkpixel(p, cov2d, ix, iy)
  local x, y, z = cov2d:get(1, 1), cov2d:get(1, 2), cov2d:get(2, 2)
  local det = x * z - y * y

  if (math.abs(det - 0) < 1e-6) then
    return true
  end

  --invert the covariance matrix according to EWA

  local inv_det = 1 / det

  -- stylua: ignore
  -- inverse of 2x2 sigma
  local conic = matrix.new(2, 2, {
    inv_det * cov2d:get(2, 2), -inv_det * cov2d:get(1, 2),
    -inv_det * cov2d:get(2, 1), inv_det * cov2d:get(1, 1),
  })

  local a, b, c = conic:get(1, 1), conic:get(1, 2), conic:get(2, 2)
  local dx, dy = ix - p[1], iy - p[2]
  -- ellipse equation
  local v = 0.5 * (a * dx * dx + 2 * b * dx * dy + c * dy * dy)

  if v > 1 then
    return true
  end


  -- weight of this pixel for blurring
  local w = math.exp(-v * v * v * 5)

  return false, w
end

---@param s Splat
---@return table
local function rasterizesplat(s, w, h)
  local buf = {}
  local cov2d, mean = getcovariance2d(s)

  -- from top left corner to right bottom rasterize
  for i = h, 1, -1 do
    for j = 1, w do
      local ix = (2 * (j - 1) + 1) / w - 1
      local iy = (2 * (i - 1) + 1) / h - 1

      local discard, weight = checkpixel(mean, cov2d, ix, iy)

      if discard then
        -- background color
        buf[(h - i) * w + j] = { 0xFF, 0xFF, 0xFF }
        goto continue
      end

      -- blending color
      local color = vector.new(3, 0x26, 0x6B, 0x56) * weight
      local bg = vector.new(3, 0xFF, 0xFF, 0xFF) * (1 - weight)
      color = color + bg

      buf[(h - i) * w + j] = { color[1], color[2], color[3] }
      ::continue::
    end
  end
  return buf
end

local function run()
  print("start")
  local w, h = 128, 128
  local s = getgaussian()
  local buf = rasterizesplat(s, w, h)
  writebuf(buf, w, h, "splatting.png")
  print("finished")
end

run()
