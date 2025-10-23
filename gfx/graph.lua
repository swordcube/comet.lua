local gfx = love.graphics

--- @class comet.gfx.Graph : comet.util.Class
local Graph = Class("Graph", ...)

function Graph:__init__(type, x, y, width, height, delay, label, font)
    if ({ mem = 0, fps = 0, custom = 0 })[type] == nil then
        error('Acceptable types: mem, fps, custom')
    end

    self.x = x or 0
    self.y = y or 0
    self.width = width or 50
    self.height = height or 30
    self.delay = delay or 0.5
    self.label = label or type
    self.font = font or gfx.newFont(8)
    self.data = {}
    self._max = 0
    self._time = 0
    self._type = type

    -- Build base data
    for i = 0, math.floor(self.width / 2) do
        table.insert(self.data, 0)
    end
end

function Graph:update(dt, val)
    local lastTime = self._time
    self._time = (self._time + dt) % self.delay

    -- Check if the minimum amount of time has past
    if dt > self.delay or lastTime > self._time then
        -- Fetch data if needed
        if val == nil then
            if self._type == 'fps' then
                -- Collect fps info and update the label
                val = 0.75 * 1 / dt + 0.25 * love.timer.getFPS()
                self.label = "FPS: " .. math.floor(val * 10) / 10
            elseif self._type == 'mem' then
                -- Collect memory info and update the label
                val = collectgarbage('count')
                self.label = "Memory (KB): " .. math.floor(val * 10) / 10
            else
                -- If the val is nil then we'll just skip this time
                return
            end
        end


        -- pop the old data and push new data
        table.remove(self.data, 1)
        table.insert(self.data, val)

        -- Find the highest value
        local max = 0
        for i = 1, #self.data do
            local v = self.data[i]
            if v > max then
                max = v
            end
        end

        self._max = max
    end
end

function Graph:average()
    local a = 0.0
    local len = 0
    for i = 1, #self.data do
        if self.data[i] > 0 then
            a = a + self.data[i]
            len = len + 1
        end
    end
    if len == 0 then
        return 0
    end
    return a / len
end

function Graph:draw()
    -- Store the currently set font and change the font to our own
    local fontCache = gfx.getFont()
    gfx.setFont(self.font)

    local max = math.ceil(self._max / 10) * 10 + 20
    local len = #self.data
    local steps = self.width / len

    -- Build the line data
    local lineData = {}
    for i = 1, len do
        -- Build the X and Y of the point
        local x = steps * (i - 1) + self.x
        local y = self.height * (-self.data[i] / max + 1) + self.y

        -- Append it to the line
        table.insert(lineData, x)
        table.insert(lineData, y)
    end

    -- Draw the line
    gfx.setLineWidth(1)
    gfx.line(unpack(lineData))

    -- Print the label
    if self.label ~= '' then
        gfx.print(self.label, self.x, self.y + self.height - self.font:getHeight())
    end

    -- Reset the font
    gfx.setFont(fontCache)
end

return Graph