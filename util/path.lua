--- @class comet.util.Path : comet.util.Class
local Path = Class("Path", ...)

-- sloppily ported over from haxe itself
-- https://github.com/HaxeFoundation/haxe/blob/4.3.1/std/haxe/io/Path.hx

-- probs gonna be majorly untested, sorry :(

function Path:__init__(path)
    self.dir = nil
    self.file = nil
    self.ext = nil
    self.backslash = false

    if path == "." or path == ".." then
        self.dir = path
        self.file = ""
        return
    end

    local c1 = string.lastIndexOf(path, "/")
    local c2 = string.lastIndexOf(path, "\\")

    if c1 < c2 then
        self.dir = string.sub(path, 1, c2)
        self.path = string.sub(path, c2 + 1)
        self.backslash = true
    elseif c2 < c1 then
        self.dir = string.sub(path, 1, c1)
        self.path = string.sub(path, c1 + 1)
    else
        self.dir = nil
    end

    local cp = string.lastIndexOf(path, ".")
    if cp ~= -1 then
        self.ext = string.sub(path, cp + 1)
        self.file = string.sub(path, 1, cp - 1)
    else
        self.ext = nil
        self.file = path
    end
end

function Path:__tostring()
    local final = (self.dir == nil) and "" or self.dir .. (self.backslash and "\\" or "/")
    final = final .. self.file
    if self.ext ~= nil then
        final = final .. self.ext
    end
    return final
end

function Path.withoutExtension(path)
    local s = Path:new(path)
    s.ext = nil
    return s:__tostring()
end

function Path.withoutDirectory(path)
    local s = Path:new(path)
    s.dir = nil
    return s:__tostring()
end

function Path.directory(path)
    local s = Path:new(path)
    return s.dir ~= nil and s.dir or ""
end

function Path.extension(path)
    local s = Path:new(path)
    return s.ext ~= nil and s.ext or ""
end

function Path.withExtension(path, ext)
    local s = Path:new(path)
    s.ext = ext
    return s:__tostring()
end

function Path.join(_paths)
    local paths = table.filter(_paths, function(s) return s ~= nil and s ~= "" end)
    if #paths < 1 then
        return 0
    end
    local path = paths[1]
    for i = 2, #paths do
        path = Path.addTrailingSlash(path)
        path = path .. paths[i]
    end
    return Path.normalize(path)
end

function Path.normalize(path)
    local slash = "/"
    path = table.join(string.split(path, "\\"), slash)
    if path == slash then
        return slash
    end
    
    local target = {}
    local slashCode = string.byte("/")
    
    for _, token in ipairs(string.split(path, slash)) do
        if token == '..' and #target > 0 and target[#target ] ~= ".." then
            table.remove(target, #target)
        elseif #token < 1 then
            if #target > 0 or string.charCodeAt(path, 1) == slashCode then
                table.insert(target, token)
            end
        elseif token ~= "." then
            table.insert(target, token)
        end
    end
    local tmp = table.join(target, slash)
    
    local acc = ""
    local colon = false
    local slashes = false
    
    for i = 1, #tmp do
        local char = tmp:charAt(i)
        local code = string.charCodeAt(tmp, i)

        if code == string.byte(":") then
            acc = acc .. ":"
            colon = true
        elseif code == slashCode then
            if not colon then
                slashes = true
            end
        else
            colon = false
            if slashes then
                acc = acc .. "/"
                slashes = false
            end
            acc = acc .. char
        end
    end
    if path:charAt(1) == "/" then
        acc = "/" .. acc
    end
    return acc
end

function Path.addTrailingSlash(path)
    if #path < 1 then
        return "/"
    end

    local c1 = string.lastIndexOf(path, "/")
    local c2 = string.lastIndexOf(path, "\\")

    local final = path

    if c1 < c2 then
        if c2 ~= #path then
            final = final .. "\\"
        end
    else
        if c1 ~= #path then
            final = final .. "/"
        end
    end

    return final
end

function Path.removeTrailingSlashes(path)
    local slashCode = string.byte("/")
    local backSlashCode = string.byte("\\")
    while true do
        local code = string.charCodeAt(path, #path)
        if code == slashCode or code == backSlashCode then
            path = string.sub(path, 1, #path - 1)
        else
            break
        end
    end
    return path
end

function Path.isAbsolute(path)
    if string.startsWith(path, "/") then
        return true
    end
    if string.charAt(path, 0) == ":" then
        return true
    end
    if string.startsWith(path, "\\\\") then
        return true
    end
    return false
end

return Path