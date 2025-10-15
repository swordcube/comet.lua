local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass
local RefCounted = cometreq("core.refcounted") --- @type comet.core.RefCounted

--- @class comet.gfx.Shader : comet.core.RefCounted
--- A basic object for storing a shader.
local Shader, super = RefCounted:subclass("Shader", ...)

local img = love.image
local gfx = love.graphics

--- @param frag string
--- @param vert string
function Shader:__init__(frag, vert)
    super.__init__(self)
    
    -- Love2D doesn't have a way to get uniforms from shaders, so we have to track them ourselves
    self._uniforms = {} --- @protected

    local fragPath, vertPath = "frag", "vert"
    if frag and love.filesystem.exists(frag) then
        fragPath = frag
        frag = love.filesystem.getContent(frag)
    end
    if vert and love.filesystem.exists(vert) then
        vertPath = vert
        vert = love.filesystem.getContent(vert)
    end
    if frag or vert then
        self.data = gfx.newShader(frag, vert) --- @type love.Shader
        
        local warns = self.data:getWarnings()
        if warns and #warns ~= 0 then
            Log.warn("Warnings/errors in " .. fragPath .. "/" .. vertPath .. ": " .. warns)
        end
    else
        if fragPath then
            Log.warn("No fragment shader found at " .. fragPath)
        else
            Log.warn("You can't load a nil fragment shader!")
        end
        if vertPath then
            Log.warn("No vertex shader found at " .. vertPath)
        else
            Log.warn("You can't load a nil vertex shader!")
        end
    end
    self._destroyed = false
end

--- Gets whether a uniform / extern variable exists in the Shader.
--- 
--- If a graphics driver's shader compiler determines that a uniform / extern variable doesn't affect the final output of the shader, it may optimize the variable out. This function will return false in that case.
---
--- @param name string # The name of the uniform variable.
--- @return boolean hasuniform # Whether the uniform exists in the shader and affects its final output.
function Shader:hasUniform(name)
    if not self.data then
        return false
    end
    return self.data:hasUniform(name)
end

--- Gets the values of an uniform / extern variable.
--- @return table
function Shader:getUniform(name)
    return self._uniforms[name]
end

--- Gets the first value of an uniform / extern variable as a number.
--- @return number
function Shader:getUniformNumber(name)
    return tonumber(self._uniforms[name][1] or 0.0)
end

--- Returns any warning and error messages from compiling the shader code. This can be used for debugging your shaders if there's anything the graphics hardware doesn't like.
--- @return string warnings # Warning and error messages (if any).
function Shader:getWarnings()
    return self.data:getWarnings()
end

--- Sends one or more values to a special `uniform` variable inside the shader. Uniform variables have to be marked using the `uniform` or `extern` keyword, e.g.
--- 
--- ```glsl
--- uniform float time;  // 'float' is the typical number type used in GLSL shaders.
--- uniform float vars;
--- uniform vec2 light_pos;
--- uniform vec4 colors[4];
--- ```
--- 
--- The corresponding send calls would be
--- 
--- ```lua
--- shader:send('time', t)
--- shader:send('vars', a, b)
--- shader:send('light_pos', {light_x, light_y})
--- shader:send('colors', {r1, g1, b1, a1},  {r2, g2, b2, a2},  {r3, g3, b3, a3},  {r4, g4, b4, a4})
--- ```
--- 
--- Uniform / extern variables are read-only in the shader code and remain constant until modified by a Shader:send call. Uniform variables can be accessed in both the Vertex and Pixel components of a shader, as long as the variable is declared in each.
---
--- @overload fun(self: comet.gfx.Shader, name: string, vector: table, ...)
--- @overload fun(self: comet.gfx.Shader, name: string, matrix: table, ...)
--- @overload fun(self: comet.gfx.Shader, name: string, texture: love.Texture)
--- @overload fun(self: comet.gfx.Shader, name: string, boolean: boolean, ...)
--- @overload fun(self: comet.gfx.Shader, name: string, matrixlayout: love.MatrixLayout, matrix: table, ...)
--- @overload fun(self: comet.gfx.Shader, name: string, data: love.Data, offset?: number, size?: number)
--- @overload fun(self: comet.gfx.Shader, name: string, data: love.Data, matrixlayout: love.MatrixLayout, offset?: number, size?: number)
--- @overload fun(self: comet.gfx.Shader, name: string, matrixlayout: love.MatrixLayout, data: love.Data, offset?: number, size?: number)
---
--- NOTE: When passing in a `comet.gfx.Texture`, make sure to call `texture:getImage()`, as shaders
--- except Love2D formatted images, and not comet formatted images!
---
--- @param name string Name of the number to send to the shader.
--- @param number number Number to send to store in the uniform variable.
--- @vararg number Additional numbers to send if the uniform variable is an array.
function Shader:send(name, number, ...)
    local values = {number, ...}
    self._uniforms[name] = values

    if self:hasUniform(name) then
        self.data:send(name, number, ...)
    end
end

--- Sends one or more colors to a special (`extern` / `uniform`) vec3 or vec4 variable inside the shader. The color components must be in the range of 1. The colors are gamma-corrected if global gamma-correction is enabled.
--- 
--- Extern variables must be marked using the `extern` keyword, e.g.
--- `extern vec4 Color;`
--- 
--- The corresponding sendColor call would be
--- `shader:sendColor('Color', {r, g, b, a})`
--- 
--- Extern variables can be accessed in both the Vertex and Pixel stages of a shader, as long as the variable is declared in each.
---
---@param name string The name of the color extern variable to send to in the shader.
---@param color table A table with red, green, blue, and optional alpha color components in the range of 1 to send to the extern as a vector.
---@vararg table Additional colors to send in case the extern is an array. All colors need to be of the same size (e.g. only vec3's).
function Shader:sendColor(name, color, ...)
    local values = {color, ...}
    self._uniforms[name] = values
    self.data:sendColor(name, color, ...)
end

function Shader:destroy()
    if self._destroyed then
        return
    end
    if self.data then
        self.data:release()
        self.data = nil
    end
    self._destroyed = true
end

return Shader