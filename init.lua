io.stdout:setvbuf("no") -- Allows console output to be shown immediately

local cd = ...
cometreq = function(mod)
    return require(cd .. "." .. mod)
end
cometreq("lib.autobatch")

cometreq("tools.mathtools") --- @type comet.tools.mathtools
cometreq("tools.tabletools") --- @type comet.tools.tabletools
cometreq("tools.stringtools") --- @type comet.tools.stringtools

local lfs = love.filesystem

--- Returns whether or not a given file exists.
--- @param  file  string  File path to check
--- @return boolean
local function fsExists(file)
    if lfs.getInfo(file, "file") or lfs.getInfo(file, "directory") or lfs.getInfo(file, "symlink") then
        return true
    end
    return false
end

comet = {
    -- changable values

    flags = {},
    settings = {
        fpsCap = 0,
        bgColor = nil, --- @type comet.gfx.Color
        dimensions = nil, --- @type comet.math.Vec2
        scaleMode = "ratio", --- @type "ratio"|"fill"|"stage"
        parallelUpdate = true,
        vsync = false,

        --- Whether or not to draw certain things usually
        --- only seen in the debugger
        debugDraw = false
    },

    -- modules

    native = cometreq("native"), --- @type comet.Native
    signals = {
        -- This signal has the following attached to it's listeners:
        -- `event`
        onInput = cometreq("util.signal"):new() --- @type comet.util.Signal
    },
    gfx = nil, --- @type comet.modules.gfx
    mixer = nil, --- @type comet.modules.mixer

    -- global values

    plugins = nil, --- @type comet.core.PluginManager
    parentDirectory = cd, -- parent directory that the module is located (thirdparty/comet, lib/comet, etc)

    -- private stuff

    _dt = 0.0,
    _tps = 0,
}

Log = cometreq("util.log") --- @type comet.util.Log
Class = cometreq("util.class") --- @type comet.util.Class

Vec2 = cometreq("math.vec2") --- @type comet.math.Vec2
Rect = cometreq("math.rect") --- @type comet.math.Rect
Color = cometreq("gfx.color") --- @type comet.gfx.Color

Object = cometreq("core.object") --- @type comet.core.Object
Object2D = cometreq("gfx.object2d") --- @type comet.gfx.Object2D
Parallax2D = cometreq("gfx.parallax2d") --- @type comet.gfx.Parallax2D
RefCounted = cometreq("core.refcounted") --- @type comet.core.RefCounted

Image = cometreq("gfx.image") --- @type comet.gfx.Image
Texture = cometreq("gfx.texture") --- @type comet.gfx.Texture

Rectangle = cometreq("gfx.rectangle") --- @type comet.gfx.Rectangle
Label = cometreq("gfx.label") --- @type comet.gfx.Label
Camera = cometreq("gfx.camera") --- @type comet.gfx.Camera
Tween = cometreq("gfx.tween") --- @type comet.gfx.Tween

Source = cometreq("mixer.source") --- @type comet.mixer.Source
Sound = cometreq("mixer.sound") --- @type comet.mixer.Sound

Screen = cometreq("core.screen") --- @type comet.core.Screen
ScreenManager = cometreq("plugins.screenmanager") --- @type comet.plugins.ScreenManager
TweenManager = cometreq("plugins.tweenmanager") --- @type comet.plugins.TweenManager

InputEvent = cometreq("input.inputevent") --- @type comet.input.InputEvent
InputKeyEvent = cometreq("input.inputkeyevent") --- @type comet.input.InputKeyEvent
InputTextEvent = cometreq("input.inputtextevent") --- @type comet.input.InputTextEvent
InputMouseButtonEvent = cometreq("input.inputmousebuttonevent") --- @type comet.input.InputMouseButtonEvent
InputMouseMoveEvent = cometreq("input.inputmousemoveevent") --- @type comet.input.InputMouseMoveEvent

local gfx = love.graphics
local middleclass = cometreq("lib.middleclass") --- @type comet.lib.MiddleClass

local nextUpdate = 0.0
local debugFPSFont = nil --- @type love.Font

local gamePos = {0, 0}
local gameScale = {1, 1}

function comet.init(params)
    -- if love.graphics and love.graphics.isActive() then
    --     error("comet.init must be called before love.load!")
    -- end
    if not params then
        params = {}
    end
    if not params.flags then
        params.flags = {}
    end
    if not params.settings then
        params.settings = {}
    end
    comet.flags = params.flags
    comet.settings = params.settings
    
    comet.flags.WINDOWS = love.system.getOS() == "Windows"
    comet.flags.MAC = love.system.getOS() == "OS X"
    comet.flags.MACOS = love.system.getOS() == "OS X"
    comet.flags.LINUX = love.system.getOS() == "Linux"
    comet.flags.ANDROID = love.system.getOS() == "Android"
    comet.flags.IOS = love.system.getOS() == "iOS"

    comet.flags.DESKTOP = comet.flags.WINDOWS or comet.flags.MAC or comet.flags.LINUX
    comet.flags.MOBILE = comet.flags.ANDROID or comet.flags.IOS

    if comet.flags.STREAM_AUDIO == nil then
        comet.flags.STREAM_AUDIO = true
    end
    comet.settings.fpsCap = comet.settings.fpsCap or 240
    comet.settings.dimensions = comet.settings.dimensions and Vec2:new(comet.settings.dimensions[1], comet.settings.dimensions[2]) or Vec2:new(800, 600)
    comet.settings.scaleMode = comet.settings.scaleMode or "ratio"

    if comet.settings.parallelUpdate == nil then
        comet.settings.parallelUpdate = true
    end
    if comet.settings.debugDraw == nil then
        comet.settings.debugDraw = false
    end
    if (love.filesystem.isFused() or not love.filesystem.getInfo("icon.png", "file")) and love.filesystem.mountFullPath then
        local sourceBaseDir = os.getenv("OWD") -- use OWD for linux app image support
        if not sourceBaseDir then
            sourceBaseDir = love.filesystem.getSourceBaseDirectory()
        end
        love.filesystem.mountFullPath(sourceBaseDir, "")
    end
    if not params.screen then
        params.screen = Screen:new()
    end
    debugFPSFont = love.graphics.newFont(comet.getEmbeddedFont("Roboto-Regular"), 12, "light")

    comet.gfx = cometreq("modules.gfx"):new()
    comet.mixer = cometreq("modules.mixer"):new()

    comet.plugins = cometreq("core.pluginmanager"):new()
    comet.plugins:add(ScreenManager:new())
    comet.plugins:add(TweenManager:new())

    comet.settings.bgColor = comet.settings.bgColor or Color:new(0.5, 0.5, 0.5, 1.0)
    ScreenManager.switchTo(params.screen or Screen:new())

    love.run = comet.run
    love.update = comet.update
    love.draw = comet.draw
    love.timer.getTPS = comet.getTPS

    love.keypressed = comet.handleKeyPress
    love.keyreleased = comet.handleKeyRelease

    love.textinput = comet.handleTextInput

    love.mousepressed = comet.handleMousePress
    love.mousereleased = comet.handleMouseRelease

    love.mousemoved = comet.handleMouseMove
    love.filesystem.exists = fsExists

    if comet.flags.DESKTOP then
        love.keyboard.setKeyRepeat(true)
        love.keyboard.setTextInput(true)
    end
    -- TODO: handle gamepad input
end

function comet.getEmbeddedResourceDir()
    return cd:replace(".", "/") .. "/res"
end

function comet.getEmbeddedFontDir()
    return comet.getEmbeddedResourceDir() .. "/font"
end

function comet.getEmbeddedFont(name)
    local possiblePaths = {
        comet.getEmbeddedFontDir() .. "/" .. name .. ".ttf",
        comet.getEmbeddedFontDir() .. "/" .. name .. ".TTF",
        comet.getEmbeddedFontDir() .. "/" .. name .. ".otf",
        comet.getEmbeddedFontDir() .. "/" .. name .. ".OTF"
    }
    for i = 1, #possiblePaths do
        if love.filesystem.getInfo(possiblePaths[i], "file") then
            return possiblePaths[i]
        end
    end
    return nil
end

function comet.getEmbeddedImageDir()
    return comet.getEmbeddedResourceDir() .. "/image"
end

function comet.getEmbeddedImage(name)
    local possiblePaths = {
        comet.getEmbeddedImageDir() .. "/" .. name .. ".png",
        comet.getEmbeddedImageDir() .. "/" .. name .. ".PNG",
        comet.getEmbeddedImageDir() .. "/" .. name .. ".jpg",
        comet.getEmbeddedImageDir() .. "/" .. name .. ".JPG",
        comet.getEmbeddedImageDir() .. "/" .. name .. ".jpeg",
        comet.getEmbeddedImageDir() .. "/" .. name .. ".JPEG"
    }
    for i = 1, #possiblePaths do
        if love.filesystem.getInfo(possiblePaths[i], "file") then
            return possiblePaths[i]
        end
    end
    return nil
end

function comet.getEmbeddedSFXDir()
    return comet.getEmbeddedResourceDir() .. "/sfx"
end

function comet.getEmbeddedSFX(name)
    local possiblePaths = {
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".ogg",
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".OGG",
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".wav",
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".WAV",
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".mp3",
        comet.getEmbeddedSFXDir() .. "/" .. name .. ".MP3"
    }
    for i = 1, #possiblePaths do
        if love.filesystem.getInfo(possiblePaths[i], "file") then
            return possiblePaths[i]
        end
    end
    return nil
end

function comet.isDebug()
    local flag = comet.flags.COMET_DEBUG
    return flag == true or flag == 1
end

function comet.getDimensions()
    return comet.settings.dimensions.x, comet.settings.dimensions.y
end

function comet.getDesiredWidth()
    return comet.settings.dimensions.x
end

function comet.getDesiredHeight()
    return comet.settings.dimensions.y
end

function comet.getTPS()
    return comet._tps
end

function comet.handleInputEvent(e)
    local screen = ScreenManager.instance.current
    if screen then
        screen:input(e)
    end
    comet.signals.onInput:emit(e)
end

function comet.handleKeyPress(key, _, isRepeat)
    comet.handleInputEvent(InputKeyEvent:new(key, true, isRepeat))
end

function comet.handleTextInput(text)
    comet.handleInputEvent(InputTextEvent:new(text))
end

function comet.handleKeyRelease(key)
    comet.handleInputEvent(InputKeyEvent:new(key, false, false))
end

function comet.handleMousePress(button, x, y)
    comet.handleInputEvent(InputMouseButtonEvent:new(button, x, y, true))
end

function comet.handleMouseRelease(button, x, y)
    comet.handleInputEvent(InputMouseButtonEvent:new(button, x, y, false))
end

function comet.handleMouseMove(x, y, dx, dy)
    comet.handleInputEvent(InputMouseMoveEvent:new(x, y, dx, dy))
end

function comet.sleep(ns)
    local dt = 0.0
    local threshold = ns - 2148437500

    local start = comet.native.getTicksNS()
    while true do
        dt = comet.native.getTicksNS() - start
        if dt < threshold then
            love.timer.sleep(0.001)
        else
            break
        end
    end
    local remainder = (comet.native.getTicksNS() - start) - dt
    if remainder > 0 then
        while comet.native.getTicksNS() - start < ns do end
    end
end

function comet.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then
        love.timer.step()
    end
    local lastTime = 0

    local tps = 0
    local tpsTimer = 0

	-- Main loop time.
	return function()
        local start = comet.native.getTicksNS()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
        local framePeriod = ((comet.settings.fpsCap > 0.0) and 1 / comet.settings.fpsCap or 0.0) * 1000000000.0
        local rawDt = start - lastTime
        
        tps = tps + 1
        tpsTimer = tpsTimer + rawDt
        
        while tpsTimer >= 1000000000.0 do
            comet._tps = tps
            tpsTimer = tpsTimer - 1000000000.0
            tps = 0
        end
        local dtLimit = framePeriod * 4
        if rawDt > dtLimit then
            rawDt = dtLimit
        end
        nextUpdate = nextUpdate + rawDt
        if nextUpdate >= framePeriod then
            local dt = math.min(love.timer.step(), 0.1)
            comet._dt = dt
            if love.update then love.update(dt) end
    
            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
    
                if love.draw then love.draw() end
    
                love.graphics.present()
            end
            if not comet.settings.parallelUpdate then
                local remainder = comet.native.getTicksNS() - start
                local sleepDuration = framePeriod - remainder
                if sleepDuration > 0 then
                    comet.sleep(sleepDuration)
                end
            end
            nextUpdate = nextUpdate - framePeriod
        end
        if nextUpdate < 0 then
            nextUpdate = 0
        end
        lastTime = start
	end
end

function comet.update(dt)
    comet.mixer:update(dt)
    comet.plugins:update(dt)
end

function comet.getGameScissor()
    local desiredWidth, desiredHeight = comet.getDimensions()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    local scaleMode = comet.settings.scaleMode
    if scaleMode == "ratio" then
        local ratio = desiredWidth / desiredHeight
        local realRatio = windowWidth / windowHeight

        if realRatio < ratio then
            gameScale[1] = windowWidth / desiredWidth
            gameScale[2] = (windowWidth / desiredWidth)
        else
            gameScale[2] = windowHeight / desiredHeight
            gameScale[1] = (windowHeight / desiredHeight)
        end
        gamePos[1] = (windowWidth - (desiredWidth * gameScale[1])) * 0.5
        gamePos[2] = (windowHeight - (desiredHeight * gameScale[2])) * 0.5
        return gamePos[1], gamePos[2], desiredWidth * gameScale[1], desiredHeight * gameScale[2]
        
    elseif scaleMode == "fill" then
        gameScale[1] = windowWidth / desiredWidth
        gameScale[2] = windowHeight / desiredHeight
        gamePos[1] = 0
        gamePos[2] = 0
        return gamePos[1], gamePos[2], desiredWidth * gameScale[1], desiredHeight * gameScale[2]
        
    elseif scaleMode == "stage" then
        gameScale[1] = 1
        gameScale[2] = 1
        gamePos[1] = 0
        gamePos[2] = 0
        return nil, nil, nil, nil
    end
    return nil, nil, nil, nil
end

function comet.adjustToGameScissor(x, y, width, height)
    x = (x * gameScale[1]) + gamePos[1]
    y = (y * gameScale[2]) + gamePos[2]
    width = width * gameScale[1]
    height = height * gameScale[2]

    local gx, gy, gw, gh = comet.getGameScissor()
    x = math.max(x + (gx - x), x)
    y = math.max(y + (gy - y), y)
    width = math.min(width - ((x + width) - (gx + gw)), width)
    height = math.min(height - ((y + height) - (gy + gh)), height)

    return x, y, width, height
end

function comet.draw()
    love.graphics.setScissor(comet.getGameScissor())
    love.graphics.translate(gamePos[1], gamePos[2])
    love.graphics.scale(gameScale[1], gameScale[2])
    
    if not middleclass.isinstanceof(comet.settings.bgColor, Color) then
        -- convert to valid color object
        comet.settings.bgColor = Color:new(comet.settings.bgColor)
    end
    love.graphics.setColor(comet.settings.bgColor:unpack())
    
    local scaleMode = comet.settings.scaleMode
    local desiredWidth, desiredHeight = comet.getDimensions()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    if scaleMode == "stage" then
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
    else
        love.graphics.rectangle("fill", 0, 0, desiredWidth, desiredHeight)
    end
    love.graphics.setColor(1.0, 1.0, 1.0, 1.0)

    if not comet.plugins.drawOnTop then
        comet.plugins:draw()
    end
    if ScreenManager.instance.current then
        ScreenManager.instance.current:draw()
    end
    if comet.plugins.drawOnTop then
        comet.plugins:draw()
    end
    love.graphics.setScissor()
    love.graphics.origin()

    local isDebug = comet.isDebug()
    if isDebug then
        local fps = love.timer.getFPS()
        if comet.settings.fpsCap > 0 then
            fps = math.min(fps, comet.settings.fpsCap)
        end
        local text = tostring(fps) .. " FPS"
        if comet.settings.parallelUpdate then
            text = text .. " | " .. tostring(comet._tps) .. " TPS"
        end
        love.graphics.print(text, debugFPSFont, gfx.getWidth() - debugFPSFont:getWidth(text) - 3, gfx.getHeight() - debugFPSFont:getHeight() - 3)
    end
end

return comet