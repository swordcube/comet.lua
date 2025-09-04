--- @class comet.core.SplashScreen : comet.core.Screen
local SplashScreen, super = Screen:subclass("SplashScreen")

function SplashScreen:__init__(initialScreen)
    super.__init__(self)
    self.initialScreen = initialScreen
end

function SplashScreen:enter()
    self.camera = Camera:new() --- @type comet.gfx.Camera
    self:addChild(self.camera)

    self.bg = Rectangle:new() --- @type comet.gfx.Rectangle
    self.bg:setSize(comet.getDesiredWidth(), comet.getDesiredHeight())
    self.bg:setTint(0xFF17171a)
    self.bg:screenCenter("xy")
    self.bg.visible = false
    self.camera:addChild(self.bg)

    self.backdrop = Backdrop:new() --- @type comet.gfx.Backdrop
    self.backdrop:loadTexture(comet.getEmbeddedImage("love_logo_heart_small"))
    self.backdrop.spacing:set(20, 20)
    self.backdrop.velocity:set(-60, -60)
    self.backdrop.alpha = 0.05
    self.backdrop.visible = false
    self.camera:addChild(self.backdrop)

    self.bg2 = Rectangle:new() --- @type comet.gfx.Rectangle
    self.bg2:setSize(comet.getDesiredWidth(), comet.getDesiredHeight() * 0.4)
    self.bg2:setTint(0xFF17171a)
    self.bg2:screenCenter("xy")
    self.bg2.visible = false
    self.camera:addChild(self.bg2)

    self.strips = Image:new() --- @type comet.gfx.Image
    self.strips:loadTexture(comet.getEmbeddedImage("love_strips"))
    self.strips:setGraphicSize(0.0001, comet.getDesiredHeight() * 3)
    self.strips:screenCenter("xy")
    self.strips.antialiasing = false
    self.camera:addChild(self.strips)

    self.madeWith = Label:new() --- @type comet.gfx.Label
    self.madeWith:setSize(24)
    self.madeWith:setFont(comet.getEmbeddedFont("handy-andy"))
    self.madeWith.text = "made with"
    self.madeWith:screenCenter("xy")
    self.madeWith.position.y = self.madeWith.position.y - 20
    self.madeWith.visible = false
    self.camera:addChild(self.madeWith)

    self.logo = Image:new() --- @type comet.gfx.Image
    self.logo:loadTexture(comet.getEmbeddedImage("love_logo"))
    self.logo.scale:set(0.3, 0.3)
    self.logo:screenCenter("xy")
    self.logo.position.y = self.logo.position.y + 20
    self.logo.visible = false
    self.camera:addChild(self.logo)

    self.logoBG = Image:new() --- @type comet.gfx.Image
    self.logoBG:loadTexture(comet.getEmbeddedImage("love_logo_bg"))
    self.logoBG.scale:set(4, 4)
    self.logoBG:screenCenter("xy")
    self.logoBG.visible = false
    self.logoBG:rotate(45)
    self.camera:addChild(self.logoBG)

    self.heart = Image:new() --- @type comet.gfx.Image
    self.heart:loadTexture(comet.getEmbeddedImage("love_logo_heart"))
    self.heart:screenCenter("xy")
    self.heart.visible = false
    self.heart.position.y = self.heart.position.y + 5
    self.camera:addChild(self.heart)

    Timer.wait(0.25, function(_)
        local t2 = Tween:new() --- @type comet.gfx.Tween
        t2:target({target = self.strips.scale, properties = {x = (comet.getDesiredWidth() / self.strips:getOriginalWidth()) * 1.25}})
        t2:start({duration = 0.7, ease = "outCubic"})

        local t3 = Tween:new() --- @type comet.gfx.Tween
        t3:target({target = self.strips, properties = {rotation = 90}})
        t3:start({duration = 0.7, ease = "inCubic"})

        t3.onComplete:connect(function()
            self.strips.visible = false
            
            self.bg.visible = true
            self.backdrop.visible = true
            self.logoBG.visible = true
            
            local t4 = Tween:new() --- @type comet.gfx.Tween
            t4:target({target = self.logoBG, properties = {rotation = 360}})
            t4:start({duration = 0.7, ease = "outCubic"})

            local t5 = Tween:new() --- @type comet.gfx.Tween
            t5:target({target = self.logoBG.scale, properties = {x = 0.5, y = 0.5}})
            t5:start({duration = 0.7, ease = "inCubic"})

            t5.onComplete:connect(function()
                local t6 = Tween:new() --- @type comet.gfx.Tween
                t6:target({target = self.logoBG.scale, properties = {x = 0.3, y = 0.3}})
                t6:start({duration = 0.7, ease = "outBack"})

                self.heart.visible = true
                self.heart.scale:set(0.1, 0.6)

                local t7 = Tween:new() --- @type comet.gfx.Tween
                t7:target({target = self.heart.scale, properties = {x = 0.3, y = 0.3}})
                t7:start({duration = 0.7, ease = "outBack"})
                
                self.heart.alpha = 0

                local t8 = Tween:new() --- @type comet.gfx.Tween
                t8:target({target = self.heart, properties = {alpha = 1}})
                t8:start({duration = 0.15, ease = "outCubic"})

                Timer.wait(0.25, function(_)
                    self.madeWith.visible = true
                    self.madeWith.scale:set(0.1, 1.5)

                    local t9 = Tween:new() --- @type comet.gfx.Tween
                    t9:target({target = self.madeWith.scale, properties = {x = 1, y = 1}})
                    t9:start({duration = 0.5, ease = "outBack", delay = 0.25})

                    self.madeWith.alpha = 0

                    local t10 = Tween:new() --- @type comet.gfx.Tween
                    t10:target({target = self.madeWith, properties = {alpha = 1}})
                    t10:start({duration = 0.15, ease = "outCubic", delay = 0.25})

                    self.bg2.visible = true
                    self.bg2.scale.x = 0

                    local t11 = Tween:new() --- @type comet.gfx.Tween
                    t11:target({target = self.bg2.scale, properties = {x = 1}})
                    t11:start({duration = 0.5, ease = "outCubic", delay = 0.25})

                    local upShitters = {self.logoBG, self.heart}
                    for _, img in ipairs(upShitters) do
                        local t12 = Tween:new() --- @type comet.gfx.Tween
                        t12:target({target = img.position, properties = {y = (img.position.y - 60) + 10}})
                        t12:start({duration = 0.7, ease = "inOutBack"})
                    end
                    local downShitters = {self.madeWith, self.logo}
                    for _, img in ipairs(downShitters) do
                        local t12 = Tween:new() --- @type comet.gfx.Tween
                        t12:target({target = img.position, properties = {y = (img.position.y + 60) + 10}})
                        t12:start({duration = 0.7, ease = "inOutBack"})
                    end
                    Timer.wait(0.25, function(_)
                        self.logo.visible = true
                        self.logo.scale:set(0.1, 0.6)

                        local t10 = Tween:new() --- @type comet.gfx.Tween
                        t10:target({target = self.logo.scale, properties = {x = 0.3, y = 0.3}})
                        t10:start({duration = 0.5, ease = "outBack", delay = 0.25})
                        
                        self.logo.alpha = 0

                        local t11 = Tween:new() --- @type comet.gfx.Tween
                        t11:target({target = self.logo, properties = {alpha = 1}})
                        t11:start({duration = 0.15, ease = "outCubic", delay = 0.25})

                    end)
                end)
            end)
        end)
    end)
end

return SplashScreen