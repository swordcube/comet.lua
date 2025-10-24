local json = cometreq("lib.json") --- @type comet.lib.Json
local nativefs = cometreq("lib.nativefs") --- @type comet.lib.nativefs

local fs = love.filesystem

--- @class comet.util.Save : comet.util.Class
--- A simple class for storing and loading data.
local Save = Class:extend("Save", ...)

function Save:__init__()
    self.data = {}

    self.name = ""
    self.dir = ""

    --- @protected
    --- @type function
    self._onQuit = function()
        self:flush()
    end
end

function Save:bind(name, dir)
    self.name = name
    self.dir = dir

    local saveDir = fs.getAppdataDirectory() .. "/" .. dir
    local path = saveDir .. "/" .. name .. ".sav"

    if not nativefs.getInfo(saveDir, "directory") then
        nativefs.createDirectory(saveDir)
    end
    local info = nativefs.getInfo(path, "file")
    if info then
        success, result = pcall(json.decode, love.data.decode("string", "hex", nativefs.read("string", path)))
        if success then
            self.data = result
        else
            Log.warn(("Failed to load save file at %s: "):format(path, result))
            self.data = {}
        end
    end
    if not table.contains(comet.signals.onQuit.listeners, self._onQuit) then
        comet.signals.onQuit:connect(self._onQuit)
    end
end

function Save:flush()
    local saveDir = fs.getAppdataDirectory() .. "/" .. self.dir
    local path = saveDir .. "/" .. self.name .. ".sav"
    nativefs.write(path, love.data.encode("string", "hex", json.encode(self.data)))
end

function Save:close()
    self.data = {}

    self.name = nil
    self.dir = nil

    if table.contains(comet.signals.onQuit.listeners, self._onQuit) then
        comet.signals.onQuit:disconnect(self._onQuit)
    end
end

return Save