--- @class comet.gfx.TiledImage : comet.gfx.Image
local TiledImage, super = Image:subclass("TiledImage", ...)

local gfx = love.graphics -- Faster access with local variable
local vertexFormat = {
    {format = "floatvec3", offset = 0,  arraylength = 0, location = 0},
    {format = "floatvec2", offset = 12, arraylength = 0, location = 1}
}
local defaultTriangles = {}
local defaultTri = {0, 0, 0, 0, 0, 0}
for _ = 1, 1000 do
    defaultTriangles[#defaultTriangles + 1] = defaultTri
end
local ceil, lerp = math.ceil, math.lerp

local function preMultiplyChannels(r, g, b, a)
    return r * a, g * a, b * a, a
end

function TiledImage:__init__(x, y)
    super.__init__(self, x, y)

    self.horizontallyRepeat = true
    self.verticallyRepeat = true

    self.horizontalLength = 0
    self.verticalLength = 0

    self.horizontalPadding = 0
    self.verticalPadding = 0

    --- @type love.Mesh
    self._mesh = gfx.newMesh(vertexFormat, defaultTriangles, "triangles", "stream") --- @protected
end

function TiledImage:getFrameWidth(frame)
    return super.getWidth(self, frame)
end

function TiledImage:getOriginalFrameWidth(frame)
    return super.getOriginalWidth(self, frame)
end

function TiledImage:getFrameHeight(frame)
    return super.getHeight(self, frame)
end

function TiledImage:getOriginalFrameHeight(frame)
    return super.getOriginalHeight(self, frame)
end

function TiledImage:getOriginalWidth(frame)
    return self.horizontallyRepeat and self.horizontalLength or super.getOriginalWidth(self, frame)
end

function TiledImage:getWidth(frame)
    return self.horizontallyRepeat and self.horizontalLength or super.getWidth(self, frame)
end

function TiledImage:getOriginalHeight(frame)
    return self.verticallyRepeat and self.verticalLength or super.getOriginalHeight(self, frame)
end

function TiledImage:getHeight(frame)
    return self.verticallyRepeat and self.verticalLength or super.getHeight(self, frame)
end

--- @param  frame   comet.gfx.Texture
--- @param  hTiles  integer
--- @param  vTiles  integer
--- 
--- @return table[]
function TiledImage:calculateVertices(frame, hTiles, vTiles)
    local fw, fh = frame:getWidth(), frame:getHeight()
    local texW, texH = frame:getWidth(), frame:getHeight()
    local uvx, uvy, uvw, uvh = 0, 0, 1, 1

    local uvOffsetX = self.horizontalPadding / texW
    local uvOffsetY = self.verticalPadding / texH

    local roundHTiles = self.horizontallyRepeat and (ceil(hTiles) - 1) or 1
    local roundVTiles = self.verticallyRepeat and (ceil(vTiles) - 1) or 1

    local uvLeftBase = uvx + uvOffsetX
    local uvRightBase = uvx + uvw - uvOffsetX
    local uvTopBase = uvy + uvOffsetY
    local uvBottomBase = uvy + uvh - uvOffsetY

    local vertices = self._vertices
    local vi = 1

    for x = 0, roundHTiles do
        local rightMult, uvRight = 1.0, uvRightBase
        if x == roundHTiles and hTiles ~= (roundHTiles + 1) then
            rightMult = hTiles % 1
            uvRight = uvLeftBase + (uvRightBase - uvLeftBase) * rightMult
        end
        local x0 = x * fw
        local x1 = x0 + fw * rightMult

        for y = 0, roundVTiles do
            local bottomMult, uvBottom = 1.0, uvBottomBase
            if y == roundVTiles and vTiles ~= (roundVTiles + 1) then
                bottomMult = vTiles % 1
                uvBottom = uvTopBase + (uvBottomBase - uvTopBase) * bottomMult
            end
            local y0 = y * fh
            local y1 = y0 + fh * bottomMult

            local v = vertices
            v[vi]   = v[vi]   or {0, 0, 0, 0, 0}
            v[vi+1] = v[vi+1] or {0, 0, 0, 0, 0}
            v[vi+2] = v[vi+2] or {0, 0, 0, 0, 0}
            v[vi+3] = v[vi+3] or {0, 0, 0, 0, 0}
            v[vi+4] = v[vi+4] or {0, 0, 0, 0, 0}
            v[vi+5] = v[vi+5] or {0, 0, 0, 0, 0}

            local p = v[vi]
            p[1],p[2],p[3],p[4],p[5] = x0, y0, 1, uvLeftBase, uvTopBase
            
            p = v[vi+1]
            p[1],p[2],p[3],p[4],p[5] = x1, y0, 1, uvRight, uvTopBase
            
            p = v[vi+2]
            p[1],p[2],p[3],p[4],p[5] = x0, y1, 1, uvLeftBase, uvBottom
            
            p = v[vi+3]
            p[1],p[2],p[3],p[4],p[5] = x0, y1, 1, uvLeftBase, uvBottom
            
            p = v[vi+4]
            p[1],p[2],p[3],p[4],p[5] = x1, y1, 1, uvRight, uvBottomBase
            
            p = v[vi+5]
            p[1],p[2],p[3],p[4],p[5] = x1, y0, 1, uvRight, uvTopBase

            vi = vi + 6
        end
    end
    for i = vi, #vertices do
        vertices[i] = nil
    end
    return vertices
end

--- Returns the bounding box of this image, as a rectangle
--- @param trans comet.math.Transform?   The transform to use for the bounding box (optional)
--- @param rect  comet.math.Rect?  The rectangle to use as the bounding box (optional)
--- @return comet.math.Rect
function Image:getBoundingBox(trans, rect)
    if not trans then
        trans = self:getTransform()
    end
    if not rect then
        rect = Rect:new()
    end
    local w, h = self:getOriginalWidth(), self:getOriginalHeight()
    local x1, y1 = trans:transformPoint(0, 0)
    local x2, y2 = trans:transformPoint(w, 0)
    local x3, y3 = trans:transformPoint(w, h)
    local x4, y4 = trans:transformPoint(0, h)

    local minX = min(x1, x2, x3, x4)
    local minY = min(y1, y2, y3, y4)
    local maxX = max(x1, x2, x3, x4)
    local maxY = max(y1, y2, y3, y4)

    rect:set(minX, minY, maxX - minX, maxY - minY)
    return rect
end

function TiledImage:draw()
    if self.alpha <= 0.0001 or not self.texture then
        return
    end
    local transform = self:getTransform(true, true, true)
    local box = not Image.NO_OFF_SCREEN_CHECKS and self:getBoundingBox(transform, self._rect) or nil
    if box and not self:isOnScreen(box) then
        return
    end
    local pr, pg, pb, pa = gfx.getColor()
    if self.blendAlpha == "premultiplied" then
        gfx.setColor(preMultiplyChannels(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa))
    else
        gfx.setColor(self._tint.r * pr, self._tint.g * pg, self._tint.b * pb, self._tint.a * self.alpha * pa)
    end
    gfx.setBlendMode(self.blend, self.blendAlpha)

    if self._shader then
        gfx.setShader(self._shader.data)
    else
        gfx.setShader()
    end
    local vertices = self:calculateVertices(self.texture, self.horizontalLength / self.texture:getWidth(), self.verticalLength / self.texture:getHeight())
    local vertexCount = #vertices

    local mesh = self._mesh
    if vertexCount > mesh:getVertexCount() then
        -- if you reach higher vertex count than the mesh
        -- can currently handle, make a new mesh

        -- seems to be the best solution other than
        -- giving the mesh a shit ton of triangles immediately

        mesh:release()
        mesh = gfx.newMesh(vertexFormat, vertices, "triangles", "stream")

        self._mesh = mesh
    else
        mesh:setDrawRange(1, vertexCount)
        mesh:setVertices(vertices)
    end
    mesh:setTexture(self.texture:getImage(self.antialiasing and "linear" or "nearest").image)
    gfx.draw(mesh, transform:getRenderValues())

    if comet.settings.debugDraw then
        if not box then
            box = self:getBoundingBox(transform, self._rect)
        end
        gfx.setLineWidth(4)
        gfx.setColor(1, 1, 1, 1)
        gfx.rectangle("line", box.x, box.y, box.width, box.height)
    end
    gfx.setColor(pr, pg, pb, pa)
end

function TiledImage:destroy()
    if self._mesh then
        self._mesh:release()
        self._mesh = nil
    end
    super.destroy(self)
end

return TiledImage