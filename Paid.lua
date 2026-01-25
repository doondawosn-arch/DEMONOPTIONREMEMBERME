--[=[ 
    NovaOps | PREMIUM Trident Survival v3
    INTEGRATED VERSION: KeyAuth + Custom UI
]=]--

-- Services needed for both parts
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")

-- Forward declaration of the Main Script function
local StartNovaOps = nil

-- ============================================================================
-- === KEYAUTH LOADER SYSTEM ===
-- ============================================================================

local function RunKeyAuth()
    -- === CLEANUP ===
    pcall(function()
        if CoreGui:FindFirstChild("NovaOps_KeyLoader") then
            CoreGui.NovaOps_KeyLoader:Destroy()
        end
    end)

    local Connections = {}
    local function cleanup()
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        Connections = {}
        if Lighting:FindFirstChild("NovaOpsBlur") then
            Lighting.NovaOpsBlur:Destroy()
        end
    end

    -- === EXECUTOR DETECTION ===
    local SupportedExecutors = {
        "jjsploit", "seliware", "xeno", "solara", "bunni", "ronix", 
        "drift", "volcano", "volt", "wave", "potassium"
    }

    local function getExecutorInfo()
        local detectedName = "Unknown"
        local isSupported = false

        pcall(function()
            if identifyexecutor then
                detectedName = identifyexecutor()
            elseif get_executor_name then
                detectedName = get_executor_name()
            end
        end)

        local lowerName = string.lower(detectedName)

        if lowerName:find("synapse") or lowerName:find("delta") then
            detectedName = "Delta" 
        end

        for _, v in ipairs(SupportedExecutors) do
            if lowerName:find(v:lower()) then
                isSupported = true
                detectedName = v
                break
            end
        end

        return detectedName, isSupported
    end

    local currentExecutor, isExecutorSupported = getExecutorInfo()

    -- === CONFIGURATION (API ONLY) ===
    local API_URL = "https://e88bb348-4fd8-48ff-9469-05d98430ecac-00-2cnfwqkk5cebq.kirk.replit.dev/validate"
    local ACCENT_COLOR = Color3.fromRGB(255, 145, 40)
    local ACCENT_GLOW = Color3.fromRGB(255, 180, 100)
    local ACCENT_DARK = Color3.fromRGB(200, 100, 20)
    local BG_COLOR = Color3.fromRGB(12, 12, 14)
    local BG_SECONDARY = Color3.fromRGB(18, 18, 22)
    local SUCCESS_COLOR = Color3.fromRGB(80, 255, 120)
    local ERROR_COLOR = Color3.fromRGB(255, 80, 80)

    -- Blur
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "NovaOpsBlur"
    Blur.Size = 0
    Blur.Parent = Lighting
    TweenService:Create(Blur, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {Size = 28}):Play()

    -- Root Gui
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "NovaOps_KeyLoader"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.Parent = CoreGui

    -- Main Container
    local Main = Instance.new("Frame", Gui)
    Main.Size = UDim2.fromOffset(480, 360)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = BG_COLOR
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

    -- Main border glow effect
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = ACCENT_COLOR
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.7

    -- Animated border glow
    task.spawn(function()
        while Main.Parent do
            TweenService:Create(MainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.4}):Play()
            task.wait(2)
            TweenService:Create(MainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.8}):Play()
            task.wait(2)
        end
    end)

    -- Shadow
    local Shadow = Instance.new("ImageLabel", Main)
    Shadow.Name = "Shadow"
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 20)
    Shadow.Size = UDim2.new(1, 180, 1, 180)
    Shadow.ZIndex = -1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = ACCENT_DARK
    Shadow.ImageTransparency = 0.85
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)

    -- Inner gradient
    local BGGradient = Instance.new("UIGradient", Main)
    BGGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 25)),
        ColorSequenceKeypoint.new(0.5, BG_COLOR),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 18))
    }
    BGGradient.Rotation = 135

    -- === DRAGGING ===
    local DragFrame = Instance.new("Frame", Main)
    DragFrame.Size = UDim2.new(1, 0, 1, 0)
    DragFrame.BackgroundTransparency = 1
    DragFrame.ZIndex = 100

    local dragging, dragInput, dragStart, startPos
    table.insert(Connections, DragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    table.insert(Connections, DragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(Main, TweenInfo.new(0.08), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}):Play()
        end
    end))

    -- ============================================
    -- === LOADING SCREEN ===
    -- ============================================
    local LoadingGroup = Instance.new("CanvasGroup", Main)
    LoadingGroup.Size = UDim2.new(1, 0, 1, 0)
    LoadingGroup.BackgroundTransparency = 1
    LoadingGroup.GroupTransparency = 0
    LoadingGroup.Visible = true

    -- === ANIMATED GRID BACKGROUND ===
    local GridContainer = Instance.new("Frame", LoadingGroup)
    GridContainer.Size = UDim2.new(1, 40, 1, 40)
    GridContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    GridContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    GridContainer.BackgroundTransparency = 1
    GridContainer.ClipsDescendants = false
    GridContainer.ZIndex = 0

    local gridLines = {}
    local gridSpacing = 30
    local gridSize = 20

    for i = -gridSize, gridSize do
        local vLine = Instance.new("Frame", GridContainer)
        vLine.Size = UDim2.new(0, 1, 2, 0)
        vLine.Position = UDim2.new(0.5, i * gridSpacing, 0.5, 0)
        vLine.AnchorPoint = Vector2.new(0.5, 0.5)
        vLine.BackgroundColor3 = ACCENT_COLOR
        vLine.BackgroundTransparency = 0.95
        vLine.BorderSizePixel = 0
        vLine.ZIndex = 0
        table.insert(gridLines, vLine)
        
        local hLine = Instance.new("Frame", GridContainer)
        hLine.Size = UDim2.new(2, 0, 0, 1)
        hLine.Position = UDim2.new(0.5, 0, 0.5, i * gridSpacing)
        hLine.AnchorPoint = Vector2.new(0.5, 0.5)
        hLine.BackgroundColor3 = ACCENT_COLOR
        hLine.BackgroundTransparency = 0.95
        hLine.BorderSizePixel = 0
        hLine.ZIndex = 0
        table.insert(gridLines, hLine)
    end

    local gridOffset = 0
    table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
        if GridContainer.Parent then
            gridOffset = (gridOffset + dt * 15) % gridSpacing
            GridContainer.Position = UDim2.new(0.5, gridOffset, 0.5, gridOffset)
        end
    end))

    -- === CONSTELLATION PARTICLE SYSTEM ===
    local ParticleContainer = Instance.new("Frame", LoadingGroup)
    ParticleContainer.Size = UDim2.new(1, 0, 1, 0)
    ParticleContainer.BackgroundTransparency = 1
    ParticleContainer.ClipsDescendants = true
    ParticleContainer.ZIndex = 1

    local constellationParticles = {}
    local maxParticles = 25
    local connectionDistance = 120

    local function createConstellationParticle()
        local particle = {
            x = math.random(0, 480),
            y = math.random(0, 360),
            vx = (math.random() - 0.5) * 30,
            vy = (math.random() - 0.5) * 30,
            size = math.random(3, 6)
        }
        
        local frame = Instance.new("Frame", ParticleContainer)
        frame.Size = UDim2.fromOffset(particle.size, particle.size)
        frame.Position = UDim2.fromOffset(particle.x, particle.y)
        frame.BackgroundColor3 = ACCENT_COLOR
        frame.BackgroundTransparency = 0.4
        frame.BorderSizePixel = 0
        frame.ZIndex = 2
        Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
        
        local glow = Instance.new("ImageLabel", frame)
        glow.Size = UDim2.new(4, 0, 4, 0)
        glow.Position = UDim2.new(0.5, 0, 0.5, 0)
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = ACCENT_GLOW
        glow.ImageTransparency = 0.7
        glow.ZIndex = 1
        
        particle.frame = frame
        table.insert(constellationParticles, particle)
        
        return particle
    end

    for i = 1, maxParticles do
        createConstellationParticle()
    end

    local LinesContainer = Instance.new("Frame", ParticleContainer)
    LinesContainer.Size = UDim2.new(1, 0, 1, 0)
    LinesContainer.BackgroundTransparency = 1
    LinesContainer.ZIndex = 1

    table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
        if not ParticleContainer.Parent then return end
        
        for _, child in ipairs(LinesContainer:GetChildren()) do
            child:Destroy()
        end
        
        for _, p in ipairs(constellationParticles) do
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            
            if p.x < 0 or p.x > 480 then p.vx = -p.vx end
            if p.y < 0 or p.y > 360 then p.vy = -p.vy end
            
            p.x = math.clamp(p.x, 0, 480)
            p.y = math.clamp(p.y, 0, 360)
            
            if p.frame then
                p.frame.Position = UDim2.fromOffset(p.x, p.y)
            end
        end
        
        for i, p1 in ipairs(constellationParticles) do
            for j, p2 in ipairs(constellationParticles) do
                if i < j then
                    local dx = p2.x - p1.x
                    local dy = p2.y - p1.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    
                    if dist < connectionDistance then
                        local line = Instance.new("Frame", LinesContainer)
                        local angle = math.atan2(dy, dx)
                        local transparency = 0.7 + (dist / connectionDistance) * 0.25
                        
                        line.Size = UDim2.fromOffset(dist, 1)
                        line.Position = UDim2.fromOffset(p1.x, p1.y)
                        line.Rotation = math.deg(angle)
                        line.AnchorPoint = Vector2.new(0, 0.5)
                        line.BackgroundColor3 = ACCENT_COLOR
                        line.BackgroundTransparency = transparency
                        line.BorderSizePixel = 0
                        line.ZIndex = 1
                    end
                end
            end
        end
    end))

    -- === FLOATING GEOMETRIC SHAPES ===
    local ShapesContainer = Instance.new("Frame", LoadingGroup)
    ShapesContainer.Size = UDim2.new(1, 0, 1, 0)
    ShapesContainer.BackgroundTransparency = 1
    ShapesContainer.ZIndex = 1

    local function createFloatingShape()
        local shapeTypes = {"diamond", "triangle", "hexagon"}
        local shapeType = shapeTypes[math.random(1, #shapeTypes)]
        
        local shape = Instance.new("Frame", ShapesContainer)
        local size = math.random(15, 30)
        shape.Size = UDim2.fromOffset(size, size)
        shape.Position = UDim2.new(math.random(0, 100) / 100, 0, 1.2, 0)
        shape.BackgroundColor3 = ACCENT_COLOR
        shape.BackgroundTransparency = 0.85
        shape.BorderSizePixel = 0
        shape.Rotation = math.random(0, 360)
        shape.ZIndex = 1
        
        if shapeType == "diamond" then
            shape.Rotation = 45
            Instance.new("UICorner", shape).CornerRadius = UDim.new(0, 4)
        elseif shapeType == "hexagon" then
            Instance.new("UICorner", shape).CornerRadius = UDim.new(0.3, 0)
        else
            Instance.new("UICorner", shape).CornerRadius = UDim.new(0, 2)
        end
        
        local stroke = Instance.new("UIStroke", shape)
        stroke.Color = ACCENT_COLOR
        stroke.Thickness = 1
        stroke.Transparency = 0.5
        
        local duration = math.random(8, 14)
        local targetX = shape.Position.X.Scale + (math.random(-30, 30) / 100)
        local targetRot = shape.Rotation + math.random(-180, 180)
        
        TweenService:Create(shape, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
            Position = UDim2.new(targetX, 0, -0.2, 0),
            Rotation = targetRot,
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(duration, function()
            shape:Destroy()
        end)
    end

    task.spawn(function()
        while LoadingGroup.Visible do
            createFloatingShape()
            task.wait(math.random(800, 1500) / 1000)
        end
    end)

    -- === SPINNER ===
    local SpinnerContainer = Instance.new("Frame", LoadingGroup)
    SpinnerContainer.Size = UDim2.fromOffset(120, 120)
    SpinnerContainer.Position = UDim2.new(0.5, 0, 0.35, 0)
    SpinnerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    SpinnerContainer.BackgroundTransparency = 1
    SpinnerContainer.ZIndex = 10

    local OuterGlow = Instance.new("ImageLabel", SpinnerContainer)
    OuterGlow.Size = UDim2.new(2, 0, 2, 0)
    OuterGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    OuterGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    OuterGlow.BackgroundTransparency = 1
    OuterGlow.Image = "rbxassetid://5028857084"
    OuterGlow.ImageColor3 = ACCENT_COLOR
    OuterGlow.ImageTransparency = 0.7
    OuterGlow.ZIndex = 5

    local pulseOut = TweenService:Create(OuterGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        Size = UDim2.new(2.5, 0, 2.5, 0),
        ImageTransparency = 0.5
    })
    pulseOut:Play()

    local Ring1 = Instance.new("Frame", SpinnerContainer)
    Ring1.Size = UDim2.fromOffset(100, 100)
    Ring1.Position = UDim2.new(0.5, 0, 0.5, 0)
    Ring1.AnchorPoint = Vector2.new(0.5, 0.5)
    Ring1.BackgroundTransparency = 1
    Ring1.ZIndex = 6
    local ring1Stroke = Instance.new("UIStroke", Ring1)
    ring1Stroke.Color = ACCENT_COLOR
    ring1Stroke.Thickness = 2
    ring1Stroke.Transparency = 0.3
    Instance.new("UICorner", Ring1).CornerRadius = UDim.new(1, 0)

    local Ring2 = Instance.new("Frame", SpinnerContainer)
    Ring2.Size = UDim2.fromOffset(75, 75)
    Ring2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Ring2.AnchorPoint = Vector2.new(0.5, 0.5)
    Ring2.BackgroundTransparency = 1
    Ring2.ZIndex = 7
    local ring2Stroke = Instance.new("UIStroke", Ring2)
    ring2Stroke.Color = ACCENT_GLOW
    ring2Stroke.Thickness = 1.5
    ring2Stroke.Transparency = 0.5
    Instance.new("UICorner", Ring2).CornerRadius = UDim.new(1, 0)

    local Ring3 = Instance.new("Frame", SpinnerContainer)
    Ring3.Size = UDim2.fromOffset(50, 50)
    Ring3.Position = UDim2.new(0.5, 0, 0.5, 0)
    Ring3.AnchorPoint = Vector2.new(0.5, 0.5)
    Ring3.BackgroundTransparency = 1
    Ring3.ZIndex = 8
    local ring3Stroke = Instance.new("UIStroke", Ring3)
    ring3Stroke.Color = Color3.fromRGB(100, 100, 100)
    ring3Stroke.Thickness = 1
    ring3Stroke.Transparency = 0.6
    Instance.new("UICorner", Ring3).CornerRadius = UDim.new(1, 0)

    local Core = Instance.new("Frame", SpinnerContainer)
    Core.Size = UDim2.fromOffset(28, 28)
    Core.Position = UDim2.new(0.5, 0, 0.5, 0)
    Core.AnchorPoint = Vector2.new(0.5, 0.5)
    Core.BackgroundColor3 = ACCENT_COLOR
    Core.BorderSizePixel = 0
    Core.ZIndex = 12
    Instance.new("UICorner", Core).CornerRadius = UDim.new(0, 8)

    local coreGradient = Instance.new("UIGradient", Core)
    coreGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT_GLOW),
        ColorSequenceKeypoint.new(1, ACCENT_COLOR)
    }
    coreGradient.Rotation = 45

    local coreInnerGlow = Instance.new("ImageLabel", Core)
    coreInnerGlow.Size = UDim2.new(3, 0, 3, 0)
    coreInnerGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    coreInnerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    coreInnerGlow.BackgroundTransparency = 1
    coreInnerGlow.Image = "rbxassetid://5028857084"
    coreInnerGlow.ImageColor3 = ACCENT_GLOW
    coreInnerGlow.ImageTransparency = 0.4
    coreInnerGlow.ZIndex = 11

    local orbitLayers = {
        {radius = 38, dots = 4, speed = 4, size = 8, offset = 0},
        {radius = 50, dots = 6, speed = -2.5, size = 6, offset = math.pi/6},
        {radius = 28, dots = 3, speed = 6, size = 5, offset = math.pi/4}
    }

    local allOrbitDots = {}

    for layerIdx, layer in ipairs(orbitLayers) do
        for i = 1, layer.dots do
            local dot = Instance.new("Frame", SpinnerContainer)
            dot.Size = UDim2.fromOffset(layer.size, layer.size)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.BackgroundColor3 = ACCENT_COLOR
            dot.BackgroundTransparency = 0.2
            dot.BorderSizePixel = 0
            dot.ZIndex = 9
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            
            local trail = Instance.new("Frame", SpinnerContainer)
            trail.Size = UDim2.fromOffset(layer.size * 0.6, layer.size * 0.6)
            trail.AnchorPoint = Vector2.new(0.5, 0.5)
            trail.BackgroundColor3 = ACCENT_COLOR
            trail.BackgroundTransparency = 0.6
            trail.BorderSizePixel = 0
            trail.ZIndex = 8
            Instance.new("UICorner", trail).CornerRadius = UDim.new(1, 0)
            
            local dotGlow = Instance.new("ImageLabel", dot)
            dotGlow.Size = UDim2.new(3, 0, 3, 0)
            dotGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
            dotGlow.AnchorPoint = Vector2.new(0.5, 0.5)
            dotGlow.BackgroundTransparency = 1
            dotGlow.Image = "rbxassetid://5028857084"
            dotGlow.ImageColor3 = ACCENT_GLOW
            dotGlow.ImageTransparency = 0.5
            dotGlow.ZIndex = 8
            
            table.insert(allOrbitDots, {
                dot = dot,
                trail = trail,
                angle = (i - 1) * (math.pi * 2 / layer.dots) + layer.offset,
                radius = layer.radius,
                speed = layer.speed
            })
        end
    end

    local orbitTime = 0
    table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
        if not SpinnerContainer.Parent then return end
        
        orbitTime = orbitTime + dt
        
        Ring1.Rotation = Ring1.Rotation + dt * 45
        Ring2.Rotation = Ring2.Rotation - dt * 60
        Ring3.Rotation = Ring3.Rotation + dt * 90
        Core.Rotation = Core.Rotation - dt * 30
        
        coreGradient.Rotation = (coreGradient.Rotation + dt * 100) % 360
        
        for _, data in ipairs(allOrbitDots) do
            local angle = data.angle + orbitTime * data.speed
            local x = math.cos(angle) * data.radius
            local y = math.sin(angle) * data.radius
            
            data.dot.Position = UDim2.new(0.5, x, 0.5, y)
            
            local trailAngle = angle - 0.3 * (data.speed > 0 and 1 or -1)
            local tx = math.cos(trailAngle) * data.radius
            local ty = math.sin(trailAngle) * data.radius
            data.trail.Position = UDim2.new(0.5, tx, 0.5, ty)
        end
    end))

    -- === LOADING TEXT ===
    local LoadingTextContainer = Instance.new("Frame", LoadingGroup)
    LoadingTextContainer.Size = UDim2.new(1, -60, 0, 60)
    LoadingTextContainer.Position = UDim2.new(0.5, 0, 0.35, 85)
    LoadingTextContainer.AnchorPoint = Vector2.new(0.5, 0)
    LoadingTextContainer.BackgroundTransparency = 1
    LoadingTextContainer.ZIndex = 15

    local LoadingText = Instance.new("TextLabel", LoadingTextContainer)
    LoadingText.Size = UDim2.new(1, 0, 1, 0)
    LoadingText.BackgroundTransparency = 1
    LoadingText.Font = Enum.Font.GothamBold
    LoadingText.TextSize = 16
    LoadingText.TextColor3 = Color3.fromRGB(240, 240, 240)
    LoadingText.TextWrapped = true
    LoadingText.Text = ""
    LoadingText.ZIndex = 15

    local TextGlow = Instance.new("TextLabel", LoadingTextContainer)
    TextGlow.Size = UDim2.new(1, 0, 1, 0)
    TextGlow.Position = UDim2.new(0, 2, 0, 2)
    TextGlow.BackgroundTransparency = 1
    TextGlow.Font = Enum.Font.GothamBold
    TextGlow.TextSize = 16
    TextGlow.TextColor3 = ACCENT_COLOR
    TextGlow.TextTransparency = 0.7
    TextGlow.TextWrapped = true
    TextGlow.Text = ""
    TextGlow.ZIndex = 14

    local function typewriterEffect(text, speed)
        LoadingText.Text = ""
        TextGlow.Text = ""
        for i = 1, #text do
            local char = text:sub(i, i)
            LoadingText.Text = LoadingText.Text .. char
            TextGlow.Text = TextGlow.Text .. char
            task.wait(speed or 0.03)
        end
    end

    local LoadingSubtext = Instance.new("TextLabel", LoadingGroup)
    LoadingSubtext.Size = UDim2.new(1, -60, 0, 20)
    LoadingSubtext.Position = UDim2.new(0.5, 0, 0.35, 145)
    LoadingSubtext.AnchorPoint = Vector2.new(0.5, 0)
    LoadingSubtext.BackgroundTransparency = 1
    LoadingSubtext.Font = Enum.Font.Gotham
    LoadingSubtext.TextSize = 11
    LoadingSubtext.TextColor3 = Color3.fromRGB(100, 100, 110)
    LoadingSubtext.Text = ""
    LoadingSubtext.ZIndex = 15

    -- === PROGRESS BAR ===
    local ProgressContainer = Instance.new("Frame", LoadingGroup)
    ProgressContainer.Size = UDim2.new(0.7, 0, 0, 8)
    ProgressContainer.Position = UDim2.new(0.5, 0, 0.88, 0)
    ProgressContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    ProgressContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    ProgressContainer.BorderSizePixel = 0
    ProgressContainer.ZIndex = 15
    Instance.new("UICorner", ProgressContainer).CornerRadius = UDim.new(1, 0)

    local progressStroke = Instance.new("UIStroke", ProgressContainer)
    progressStroke.Color = Color3.fromRGB(50, 50, 55)
    progressStroke.Thickness = 1

    local ProgressFill = Instance.new("Frame", ProgressContainer)
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = ACCENT_COLOR
    ProgressFill.BorderSizePixel = 0
    ProgressFill.ZIndex = 16
    Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)

    local fillGradient = Instance.new("UIGradient", ProgressFill)
    fillGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, ACCENT_GLOW),
        ColorSequenceKeypoint.new(1, ACCENT_COLOR)
    }

    table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
        if ProgressFill.Parent then
            fillGradient.Offset = Vector2.new((math.sin(tick() * 3) + 1) / 4, 0)
        end
    end))

    local ProgressGlow = Instance.new("Frame", ProgressFill)
    ProgressGlow.Size = UDim2.fromOffset(30, 20)
    ProgressGlow.Position = UDim2.new(1, 0, 0.5, 0)
    ProgressGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    ProgressGlow.BackgroundTransparency = 1
    ProgressGlow.ZIndex = 17

    local glowImage = Instance.new("ImageLabel", ProgressGlow)
    glowImage.Size = UDim2.new(1, 0, 1, 0)
    glowImage.BackgroundTransparency = 1
    glowImage.Image = "rbxassetid://5028857084"
    glowImage.ImageColor3 = ACCENT_GLOW
    glowImage.ImageTransparency = 0.3

    local ProgressPercent = Instance.new("TextLabel", LoadingGroup)
    ProgressPercent.Size = UDim2.fromOffset(50, 20)
    ProgressPercent.Position = UDim2.new(0.5, 0, 0.88, 20)
    ProgressPercent.AnchorPoint = Vector2.new(0.5, 0)
    ProgressPercent.BackgroundTransparency = 1
    ProgressPercent.Font = Enum.Font.GothamBold
    ProgressPercent.TextSize = 11
    ProgressPercent.TextColor3 = ACCENT_COLOR
    ProgressPercent.Text = "0%"
    ProgressPercent.ZIndex = 15

    -- ============================================
    -- === KEY INTERFACE ===
    -- ============================================
    local KeyGroup = Instance.new("CanvasGroup", Main)
    KeyGroup.Size = UDim2.new(1, 0, 1, 0)
    KeyGroup.BackgroundTransparency = 1
    KeyGroup.GroupTransparency = 1
    KeyGroup.Visible = false

    local KeyBGPattern = Instance.new("Frame", KeyGroup)
    KeyBGPattern.Size = UDim2.new(1, 0, 1, 0)
    KeyBGPattern.BackgroundTransparency = 1
    KeyBGPattern.ZIndex = 1

    local HeaderAccent = Instance.new("Frame", KeyGroup)
    HeaderAccent.Size = UDim2.new(1, 0, 0, 3)
    HeaderAccent.Position = UDim2.new(0, 0, 0, 0)
    HeaderAccent.BorderSizePixel = 0
    HeaderAccent.ZIndex = 5

    local accentGradient = Instance.new("UIGradient", HeaderAccent)
    accentGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT_DARK),
        ColorSequenceKeypoint.new(0.5, ACCENT_GLOW),
        ColorSequenceKeypoint.new(1, ACCENT_DARK)
    }

    table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
        if HeaderAccent.Parent then
            accentGradient.Offset = Vector2.new((math.sin(tick() * 2) + 1) / 4 - 0.25, 0)
        end
    end))

    local LogoContainer = Instance.new("Frame", KeyGroup)
    LogoContainer.Size = UDim2.fromOffset(50, 50)
    LogoContainer.Position = UDim2.new(0, 25, 0, 25)
    LogoContainer.BackgroundColor3 = ACCENT_COLOR
    LogoContainer.BorderSizePixel = 0
    LogoContainer.ZIndex = 6
    Instance.new("UICorner", LogoContainer).CornerRadius = UDim.new(0, 12)

    local logoGradient = Instance.new("UIGradient", LogoContainer)
    logoGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT_GLOW),
        ColorSequenceKeypoint.new(1, ACCENT_COLOR)
    }
    logoGradient.Rotation = 45

    local LogoText = Instance.new("TextLabel", LogoContainer)
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "TS"
    LogoText.Font = Enum.Font.GothamBlack
    LogoText.TextSize = 20
    LogoText.TextColor3 = Color3.fromRGB(20, 20, 20)
    LogoText.ZIndex = 7

    local TitleLabel = Instance.new("TextLabel", KeyGroup)
    TitleLabel.Size = UDim2.new(1, -100, 0, 28)
    TitleLabel.Position = UDim2.new(0, 85, 0, 25)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Trident Survival"
    TitleLabel.Font = Enum.Font.GothamBlack
    TitleLabel.TextSize = 22
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.ZIndex = 6

    local SubTitle = Instance.new("TextLabel", KeyGroup)
    SubTitle.Size = UDim2.new(1, -100, 0, 18)
    SubTitle.Position = UDim2.new(0, 85, 0, 52)
    SubTitle.BackgroundTransparency = 1
    SubTitle.Text = "Premium Script • Key Verification"
    SubTitle.Font = Enum.Font.Gotham
    SubTitle.TextSize = 12
    SubTitle.TextXAlignment = Enum.TextXAlignment.Left
    SubTitle.TextColor3 = ACCENT_COLOR
    SubTitle.ZIndex = 6

    local VersionBadge = Instance.new("Frame", KeyGroup)
    VersionBadge.Size = UDim2.fromOffset(55, 22)
    VersionBadge.Position = UDim2.new(1, -70, 0, 30)
    VersionBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    VersionBadge.BorderSizePixel = 0
    VersionBadge.ZIndex = 6
    Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(0, 6)

    local versionStroke = Instance.new("UIStroke", VersionBadge)
    versionStroke.Color = ACCENT_COLOR
    versionStroke.Thickness = 1
    versionStroke.Transparency = 0.5

    local VersionText = Instance.new("TextLabel", VersionBadge)
    VersionText.Size = UDim2.new(1, 0, 1, 0)
    VersionText.BackgroundTransparency = 1
    VersionText.Text = "v3.0"
    VersionText.Font = Enum.Font.GothamBold
    VersionText.TextSize = 11
    VersionText.TextColor3 = ACCENT_COLOR
    VersionText.ZIndex = 7

    local Divider = Instance.new("Frame", KeyGroup)
    Divider.Size = UDim2.new(1, -50, 0, 1)
    Divider.Position = UDim2.new(0, 25, 0, 95)
    Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    Divider.BorderSizePixel = 0
    Divider.ZIndex = 5

    local InfoText = Instance.new("TextLabel", KeyGroup)
    InfoText.Size = UDim2.new(1, -50, 0, 30)
    InfoText.Position = UDim2.new(0, 25, 0, 110)
    InfoText.BackgroundTransparency = 1
    InfoText.Text = "Enter your premium access key below to unlock the script."
    InfoText.Font = Enum.Font.Gotham
    InfoText.TextSize = 12
    InfoText.TextColor3 = Color3.fromRGB(150, 150, 160)
    InfoText.TextXAlignment = Enum.TextXAlignment.Left
    InfoText.TextWrapped = true
    InfoText.ZIndex = 5

    local InputContainer = Instance.new("Frame", KeyGroup)
    InputContainer.Size = UDim2.new(1, -50, 0, 55)
    InputContainer.Position = UDim2.new(0, 25, 0, 150)
    InputContainer.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    InputContainer.BorderSizePixel = 0
    InputContainer.ZIndex = 5
    Instance.new("UICorner", InputContainer).CornerRadius = UDim.new(0, 12)

    local InputStroke = Instance.new("UIStroke", InputContainer)
    InputStroke.Color = Color3.fromRGB(50, 50, 55)
    InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InputStroke.Thickness = 1.5

    local KeyIconBG = Instance.new("Frame", InputContainer)
    KeyIconBG.Size = UDim2.fromOffset(40, 40)
    KeyIconBG.Position = UDim2.new(0, 8, 0.5, 0)
    KeyIconBG.AnchorPoint = Vector2.new(0, 0.5)
    KeyIconBG.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    KeyIconBG.BorderSizePixel = 0
    KeyIconBG.ZIndex = 6
    Instance.new("UICorner", KeyIconBG).CornerRadius = UDim.new(0, 8)

    local KeyIcon = Instance.new("TextLabel", KeyIconBG)
    KeyIcon.Size = UDim2.new(1, 0, 1, 0)
    KeyIcon.BackgroundTransparency = 1
    KeyIcon.Text = "🔑"
    KeyIcon.TextSize = 18
    KeyIcon.ZIndex = 7

    local KeyInput = Instance.new("TextBox", InputContainer)
    KeyInput.Size = UDim2.new(1, -65, 1, 0)
    KeyInput.Position = UDim2.new(0, 55, 0, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.Font = Enum.Font.GothamMedium
    KeyInput.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
    KeyInput.TextSize = 15
    KeyInput.ClearTextOnFocus = false
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    KeyInput.ZIndex = 6

    table.insert(Connections, KeyInput.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3), {Color = ACCENT_COLOR, Thickness = 2}):Play()
        TweenService:Create(InputContainer, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(28, 28, 32)}):Play()
        TweenService:Create(KeyIconBG, TweenInfo.new(0.3), {BackgroundColor3 = ACCENT_COLOR}):Play()
    end))

    table.insert(Connections, KeyInput.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(50, 50, 55), Thickness = 1.5}):Play()
        TweenService:Create(InputContainer, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}):Play()
        TweenService:Create(KeyIconBG, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
    end))

    local SubmitBtn = Instance.new("TextButton", KeyGroup)
    SubmitBtn.Size = UDim2.new(1, -50, 0, 55)
    SubmitBtn.Position = UDim2.new(0, 25, 0, 220)
    SubmitBtn.BackgroundColor3 = ACCENT_COLOR
    SubmitBtn.Text = ""
    SubmitBtn.AutoButtonColor = false
    SubmitBtn.ZIndex = 5
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 12)

    local btnGradient = Instance.new("UIGradient", SubmitBtn)
    btnGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, ACCENT_GLOW),
        ColorSequenceKeypoint.new(0.5, ACCENT_COLOR),
        ColorSequenceKeypoint.new(1, ACCENT_DARK)
    }
    btnGradient.Rotation = 90

    local SubmitText = Instance.new("TextLabel", SubmitBtn)
    SubmitText.Size = UDim2.new(1, 0, 1, 0)
    SubmitText.BackgroundTransparency = 1
    SubmitText.Text = "VERIFY & UNLOCK"
    SubmitText.Font = Enum.Font.GothamBlack
    SubmitText.TextSize = 15
    SubmitText.TextColor3 = Color3.fromRGB(15, 15, 15)
    SubmitText.ZIndex = 6

    local ButtonShine = Instance.new("Frame", SubmitBtn)
    ButtonShine.Size = UDim2.new(0.3, 0, 1, 0)
    ButtonShine.Position = UDim2.new(-0.3, 0, 0, 0)
    ButtonShine.BackgroundTransparency = 0.7
    ButtonShine.BorderSizePixel = 0
    ButtonShine.ZIndex = 6
    ButtonShine.ClipsDescendants = true

    local shineGradient = Instance.new("UIGradient", ButtonShine)
    shineGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
    }
    shineGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 1)
    }
    shineGradient.Rotation = 75

    task.spawn(function()
        while SubmitBtn.Parent do
            ButtonShine.Position = UDim2.new(-0.3, 0, 0, 0)
            TweenService:Create(ButtonShine, TweenInfo.new(1.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1, 0, 0, 0)}):Play()
            task.wait(4)
        end
    end)

    table.insert(Connections, SubmitBtn.MouseEnter:Connect(function()
        TweenService:Create(SubmitBtn, TweenInfo.new(0.3), {BackgroundColor3 = ACCENT_GLOW}):Play()
        TweenService:Create(btnGradient, TweenInfo.new(0.3), {Rotation = 45}):Play()
    end))

    table.insert(Connections, SubmitBtn.MouseLeave:Connect(function()
        TweenService:Create(SubmitBtn, TweenInfo.new(0.3), {BackgroundColor3 = ACCENT_COLOR}):Play()
        TweenService:Create(btnGradient, TweenInfo.new(0.3), {Rotation = 90}):Play()
    end))

    local FooterContainer = Instance.new("Frame", KeyGroup)
    FooterContainer.Size = UDim2.new(1, 0, 0, 40)
    FooterContainer.Position = UDim2.new(0, 0, 1, -45)
    FooterContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    FooterContainer.BackgroundTransparency = 0.5
    FooterContainer.BorderSizePixel = 0
    FooterContainer.ZIndex = 5

    local Footer = Instance.new("TextLabel", FooterContainer)
    Footer.Size = UDim2.new(1, 0, 1, 0)
    Footer.BackgroundTransparency = 1
    Footer.Text = "🔒 Secured With NovaOps  •  by @revile_"
    Footer.Font = Enum.Font.Gotham
    Footer.TextSize = 11
    Footer.TextColor3 = Color3.fromRGB(80, 80, 90)
    Footer.ZIndex = 6

    -- === NOTIFICATIONS ===
    local NotifContainer = Instance.new("Frame", Gui)
    NotifContainer.Size = UDim2.new(0, 340, 1, 0)
    NotifContainer.Position = UDim2.new(1, -360, 0, 20)
    NotifContainer.BackgroundTransparency = 1
    NotifContainer.ZIndex = 50

    local NotifLayout = Instance.new("UIListLayout", NotifContainer)
    NotifLayout.Padding = UDim.new(0, 12)
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    local function notify(text, color, icon)
        local notif = Instance.new("Frame", NotifContainer)
        notif.Size = UDim2.new(1, 0, 0, 50)
        notif.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        notif.BorderSizePixel = 0
        notif.ClipsDescendants = true
        notif.ZIndex = 51
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 10)
        
        local notifStroke = Instance.new("UIStroke", notif)
        notifStroke.Color = Color3.fromRGB(40, 40, 45)
        notifStroke.Thickness = 1
        
        local accent = Instance.new("Frame", notif)
        accent.Size = UDim2.new(0, 4, 1, 0)
        accent.BackgroundColor3 = color or ACCENT_COLOR
        accent.BorderSizePixel = 0
        accent.ZIndex = 52
        Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)
        
        local iconLabel = Instance.new("TextLabel", notif)
        iconLabel.Size = UDim2.fromOffset(30, 50)
        iconLabel.Position = UDim2.new(0, 15, 0, 0)
        iconLabel.BackgroundTransparency = 1
        iconLabel.Text = icon or "ℹ️"
        iconLabel.TextSize = 18
        iconLabel.ZIndex = 52
        
        local l = Instance.new("TextLabel", notif)
        l.Size = UDim2.new(1, -60, 1, 0)
        l.Position = UDim2.new(0, 50, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.Font = Enum.Font.GothamMedium
        l.TextColor3 = Color3.fromRGB(240, 240, 240)
        l.TextSize = 13
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.ZIndex = 52

        notif.Position = UDim2.new(1.2, 0, 0, 0)
        TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

        task.delay(4, function()
            TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1.2, 0, 0, 0)}):Play()
            task.wait(0.5)
            notif:Destroy()
        end)
    end

    -- === INTRO SEQUENCE ===
    task.spawn(function()
        local totalDuration = 5
        local startTime = tick()
        
        task.spawn(function()
            while LoadingGroup.Visible do
                local elapsed = tick() - startTime
                local progress = math.clamp(elapsed / totalDuration, 0, 1)
                TweenService:Create(ProgressFill, TweenInfo.new(0.1), {Size = UDim2.new(progress, 0, 1, 0)}):Play()
                ProgressPercent.Text = math.floor(progress * 100) .. "%"
                task.wait(0.05)
            end
        end)
        
        task.wait(0.5)
        LoadingSubtext.Text = "Initializing premium features..."
        typewriterEffect("Welcome To Our Premium Trident Survival Script", 0.035)
        
        task.wait(1.2)
        
        LoadingSubtext.Text = "Loading modules..."
        LoadingText.TextTransparency = 0
        TweenService:Create(LoadingText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(TextGlow, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.4)
        
        LoadingText.TextColor3 = ACCENT_GLOW
        typewriterEffect("Thank You For Choosing Us!", 0.04)
        
        task.wait(1)
        
        LoadingSubtext.Text = "Almost ready..."
        TweenService:Create(LoadingText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        TweenService:Create(TextGlow, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
        task.wait(0.4)
        
        LoadingText.TextColor3 = Color3.fromRGB(255, 255, 255)
        LoadingText.Font = Enum.Font.GothamBlack
        TextGlow.Font = Enum.Font.GothamBlack
        typewriterEffect("ALL SCRIPTS MADE BY @revile_.", 0.05)
        
        task.wait(1.2)
        
        LoadingSubtext.Text = "✓ Ready!"
        LoadingSubtext.TextColor3 = SUCCESS_COLOR
        ProgressPercent.Text = "100%"
        ProgressPercent.TextColor3 = SUCCESS_COLOR
        
        task.wait(0.5)
        
        TweenService:Create(LoadingGroup, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {GroupTransparency = 1}):Play()
        task.wait(0.7)
        LoadingGroup.Visible = false
        
        KeyGroup.Visible = true
        TweenService:Create(KeyGroup, TweenInfo.new(0.7, Enum.EasingStyle.Quart), {GroupTransparency = 0}):Play()
        
        task.wait(0.3)
        notify("Welcome! Please enter your key.", ACCENT_COLOR, "👋")
    end)

    -- === SUBMIT LOGIC ===
    table.insert(Connections, SubmitBtn.MouseButton1Click:Connect(function()
        local key = KeyInput.Text

        if key == "" then
            notify("Please enter a valid key!", ERROR_COLOR, "⚠️")
            local originalPos = InputContainer.Position
            for i = 1, 3 do
                TweenService:Create(InputContainer, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, 5, 0, 0)}):Play()
                task.wait(0.05)
                TweenService:Create(InputContainer, TweenInfo.new(0.05), {Position = originalPos + UDim2.new(0, -5, 0, 0)}):Play()
                task.wait(0.05)
            end
            TweenService:Create(InputContainer, TweenInfo.new(0.05), {Position = originalPos}):Play()
            return
        end

        SubmitText.Text = "VERIFYING..."
        SubmitBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        SubmitBtn.Active = false

        local success, response = pcall(function()
            local requestFunc = syn and syn.request or http_request or request or (fluxus and fluxus.request)
            return requestFunc({
                Url = API_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode({
                    key = key,
                    username = Players.LocalPlayer.Name,
                    displayName = Players.LocalPlayer.DisplayName,
                    userId = tostring(Players.LocalPlayer.UserId),
                    executor = currentExecutor,
                    accountAge = Players.LocalPlayer.AccountAge,
                    gameId = tostring(game.PlaceId),
                    gameName = game.Name
                })
            })
        end)

        if success and response and (response.Success or response.StatusCode == 200) then
            local res = HttpService:JSONDecode(response.Body)
            if res.success then
                notify("Access Granted! Loading script...", SUCCESS_COLOR, "✅")
                SubmitText.Text = "✓ SUCCESS"
                SubmitBtn.BackgroundColor3 = SUCCESS_COLOR

                task.delay(1.5, function()
                    TweenService:Create(Blur, TweenInfo.new(0.6), {Size = 0}):Play()
                    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                        Size = UDim2.new(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    }):Play()
                    task.wait(0.6)
                    cleanup()
                    Gui:Destroy()

                    -- [[ INTEGRATION POINT: EXECUTE MAIN SCRIPT ]]
                    if StartNovaOps then
                        task.spawn(StartNovaOps)
                    else
                        warn("Critical Error: NovaOps Main Function not found.")
                    end
                end)
            else
                notify(res.message or "Invalid Key!", ERROR_COLOR, "❌")
                SubmitText.Text = "VERIFY & UNLOCK"
                SubmitBtn.BackgroundColor3 = ACCENT_COLOR
                SubmitBtn.Active = true
            end
        else
            local err = "Server Error"
            if response and response.StatusMessage then
                err = response.StatusMessage
            elseif not success then
                err = "Connection Failed"
            end
            notify(err, ERROR_COLOR, "⚠️")
            SubmitText.Text = "VERIFY & UNLOCK"
            SubmitBtn.BackgroundColor3 = ACCENT_COLOR
            SubmitBtn.Active = true
        end
    end))

    table.insert(Connections, KeyInput.FocusLost:Connect(function(enter)
        if enter then
            SubmitBtn.MouseButton1Click:Fire()
        end
    end))
end

-- ============================================================================
-- === MAIN SCRIPT WRAPPER ===
-- ============================================================================

StartNovaOps = function()
    -- ============================================================================
    -- === THEME CONFIGURATION ===
    -- ============================================================================
    local Theme = {
        Accent = Color3.fromRGB(255, 145, 40),
        AccentGlow = Color3.fromRGB(255, 180, 100),
        AccentDark = Color3.fromRGB(200, 100, 20),
        MainBG = Color3.fromRGB(12, 12, 14),
        SecondaryBG = Color3.fromRGB(18, 18, 22),
        ItemBG = Color3.fromRGB(24, 24, 28),
        Text = Color3.fromRGB(240, 240, 240),
        TextDim = Color3.fromRGB(150, 150, 160),
        Success = Color3.fromRGB(80, 255, 120),
        Error = Color3.fromRGB(255, 80, 80),
        Font = Enum.Font.Gotham,
        FontBold = Enum.Font.GothamBold
    }

    -- ============================================================================
    -- === UI LIBRARY (BUILT-IN) ===
    -- ============================================================================
    local Library = {}
    local UI = nil

    function Library:Destroy()
        if UI then UI:Destroy() end
    end

    function Library:CreateWindow(config)
        -- Cleanup
        if CoreGui:FindFirstChild("NovaOps_Trident") then
            CoreGui.NovaOps_Trident:Destroy()
        end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "NovaOps_Trident"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = CoreGui
        UI = ScreenGui

        -- Main Frame
        local Main = Instance.new("Frame", ScreenGui)
        Main.Name = "Main"
        Main.Size = UDim2.fromOffset(650, 450)
        Main.Position = UDim2.fromScale(0.5, 0.5)
        Main.AnchorPoint = Vector2.new(0.5, 0.5)
        Main.BackgroundColor3 = Theme.MainBG
        Main.ClipsDescendants = false
        
        -- Main Styling
        local UICorner = Instance.new("UICorner", Main)
        UICorner.CornerRadius = UDim.new(0, 10)
        
        local UIStroke = Instance.new("UIStroke", Main)
        UIStroke.Color = Theme.Accent
        UIStroke.Thickness = 1.5
        UIStroke.Transparency = 0.6

        -- Shadow/Glow
        local Shadow = Instance.new("ImageLabel", Main)
        Shadow.Name = "Glow"
        Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
        Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        Shadow.Size = UDim2.new(1, 80, 1, 80)
        Shadow.ZIndex = -1
        Shadow.BackgroundTransparency = 1
        Shadow.Image = "rbxassetid://5028857084"
        Shadow.ImageColor3 = Theme.Accent
        Shadow.ImageTransparency = 0.8

        -- Header
        local Header = Instance.new("Frame", Main)
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 45)
        Header.BackgroundColor3 = Theme.SecondaryBG
        Header.BorderSizePixel = 0
        
        local HeaderCorner = Instance.new("UICorner", Header)
        HeaderCorner.CornerRadius = UDim.new(0, 10)
        
        -- Fix bottom corners of header
        local HeaderCover = Instance.new("Frame", Header)
        HeaderCover.Size = UDim2.new(1, 0, 0, 10)
        HeaderCover.Position = UDim2.new(0, 0, 1, -10)
        HeaderCover.BorderSizePixel = 0
        HeaderCover.BackgroundColor3 = Theme.SecondaryBG
        
        -- Title
        local Title = Instance.new("TextLabel", Header)
        Title.Text = config.Name or "NOVAOPS"
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.Size = UDim2.new(0, 200, 1, 0)
        Title.BackgroundTransparency = 1
        Title.Font = Theme.FontBold
        Title.TextSize = 16
        Title.TextColor3 = Theme.Text
        Title.TextXAlignment = Enum.TextXAlignment.Left

        local Version = Instance.new("TextLabel", Header)
        Version.Text = "PREMIUM"
        Version.Position = UDim2.new(0, 200, 0, 0)
        Version.Size = UDim2.new(0, 60, 1, 0)
        Version.BackgroundTransparency = 1
        Version.Font = Theme.FontBold
        Version.TextSize = 10
        Version.TextColor3 = Theme.Accent
        Version.TextXAlignment = Enum.TextXAlignment.Left

        -- Container for Tabs and Content
        local Body = Instance.new("Frame", Main)
        Body.Name = "Body"
        Body.Size = UDim2.new(1, 0, 1, -45)
        Body.Position = UDim2.new(0, 0, 0, 45)
        Body.BackgroundTransparency = 1

        -- Sidebar (Tabs)
        local Sidebar = Instance.new("ScrollingFrame", Body)
        Sidebar.Name = "Sidebar"
        Sidebar.Size = UDim2.new(0, 140, 1, -10)
        Sidebar.Position = UDim2.new(0, 10, 0, 5)
        Sidebar.BackgroundTransparency = 1
        Sidebar.ScrollBarThickness = 0
        
        local SidebarLayout = Instance.new("UIListLayout", Sidebar)
        SidebarLayout.Padding = UDim.new(0, 5)
        SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

        -- Content Area
        local Content = Instance.new("Frame", Body)
        Content.Name = "Content"
        Content.Size = UDim2.new(1, -160, 1, -10)
        Content.Position = UDim2.new(0, 155, 0, 5)
        Content.BackgroundTransparency = 1

        -- Dragging Logic
        local Dragging, DragInput, DragStart, StartPos
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = true
                DragStart = input.Position
                StartPos = Main.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)
        
        Header.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                DragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                local Delta = input.Position - DragStart
                TweenService:Create(Main, TweenInfo.new(0.05), {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)}):Play()
            end
        end)

        -- Window Functions
        local Window = {}
        local FirstTab = true
        
        -- Minimizing [CHANGED TO INSERT KEY]
        UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == Enum.KeyCode.Insert then
                ScreenGui.Enabled = not ScreenGui.Enabled
            end
        end)

        function Window:Tab(name)
            local TabBtn = Instance.new("TextButton", Sidebar)
            TabBtn.Name = name
            TabBtn.Size = UDim2.new(1, 0, 0, 32)
            TabBtn.BackgroundColor3 = Theme.SecondaryBG
            TabBtn.Text = name
            TabBtn.Font = Theme.Font
            TabBtn.TextSize = 13
            TabBtn.TextColor3 = Theme.TextDim
            TabBtn.AutoButtonColor = false
            
            local BtnCorner = Instance.new("UICorner", TabBtn)
            BtnCorner.CornerRadius = UDim.new(0, 6)
            
            local BtnStroke = Instance.new("UIStroke", TabBtn)
            BtnStroke.Color = Theme.Accent
            BtnStroke.Transparency = 1
            BtnStroke.Thickness = 1

            -- Tab Content Container
            local TabContent = Instance.new("ScrollingFrame", Content)
            TabContent.Name = name.."Content"
            TabContent.Size = UDim2.new(1, 0, 1, 0)
            TabContent.BackgroundTransparency = 1
            TabContent.ScrollBarThickness = 2
            TabContent.ScrollBarImageColor3 = Theme.Accent
            TabContent.Visible = false
            
            -- Two Column Layout logic
            local LeftColumn = Instance.new("Frame", TabContent)
            LeftColumn.Name = "Left"
            LeftColumn.Size = UDim2.new(0.49, 0, 1, 0) -- Relative height, handled by listlayout
            LeftColumn.BackgroundTransparency = 1
            
            local RightColumn = Instance.new("Frame", TabContent)
            RightColumn.Name = "Right"
            RightColumn.Size = UDim2.new(0.49, 0, 1, 0)
            RightColumn.Position = UDim2.new(0.51, 0, 0, 0)
            RightColumn.BackgroundTransparency = 1

            local LeftLayout = Instance.new("UIListLayout", LeftColumn)
            LeftLayout.Padding = UDim.new(0, 10)
            LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            local RightLayout = Instance.new("UIListLayout", RightColumn)
            RightLayout.Padding = UDim.new(0, 10)
            RightLayout.SortOrder = Enum.SortOrder.LayoutOrder

            -- Auto resize columns
            local function resizeColumns()
                LeftColumn.Size = UDim2.new(0.49, 0, 0, LeftLayout.AbsoluteContentSize.Y)
                RightColumn.Size = UDim2.new(0.49, 0, 0, RightLayout.AbsoluteContentSize.Y)
                TabContent.CanvasSize = UDim2.new(0, 0, 0, math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y) + 10)
            end
            LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeColumns)
            RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizeColumns)

            -- Selection Logic
            local function Select()
                for _, v in ipairs(Sidebar:GetChildren()) do
                    if v:IsA("TextButton") then
                        TweenService:Create(v, TweenInfo.new(0.2), {BackgroundColor3 = Theme.SecondaryBG, TextColor3 = Theme.TextDim}):Play()
                        TweenService:Create(v.UIStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
                    end
                end
                for _, v in ipairs(Content:GetChildren()) do
                    if v:IsA("ScrollingFrame") then v.Visible = false end
                end
                
                TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 40), TextColor3 = Theme.Accent}):Play()
                TweenService:Create(BtnStroke, TweenInfo.new(0.2), {Transparency = 0.5}):Play()
                TabContent.Visible = true
            end
            
            TabBtn.MouseButton1Click:Connect(Select)
            
            if FirstTab then
                FirstTab = false
                Select()
            end
            
            local TabObj = {}
            
            function TabObj:Section(options)
                local side = options.side or "left"
                local ParentCol = (side:lower() == "left") and LeftColumn or RightColumn
                
                local SectionFrame = Instance.new("Frame", ParentCol)
                SectionFrame.BackgroundColor3 = Theme.SecondaryBG
                SectionFrame.Size = UDim2.new(1, 0, 0, 0) -- Auto sized
                
                local SecCorner = Instance.new("UICorner", SectionFrame)
                SecCorner.CornerRadius = UDim.new(0, 6)
                
                local SecStroke = Instance.new("UIStroke", SectionFrame)
                SecStroke.Color = Color3.fromRGB(40, 40, 45)
                SecStroke.Thickness = 1
                
                local SecTitle = Instance.new("TextLabel", SectionFrame)
                SecTitle.Text = options.name
                SecTitle.Font = Theme.FontBold
                SecTitle.TextSize = 12
                SecTitle.TextColor3 = Theme.Accent
                SecTitle.Size = UDim2.new(1, -20, 0, 25)
                SecTitle.Position = UDim2.new(0, 10, 0, 2)
                SecTitle.BackgroundTransparency = 1
                SecTitle.TextXAlignment = Enum.TextXAlignment.Left
                
                local Container = Instance.new("Frame", SectionFrame)
                Container.Position = UDim2.new(0, 0, 0, 30)
                Container.Size = UDim2.new(1, 0, 0, 0)
                Container.BackgroundTransparency = 1
                
                local ContainerLayout = Instance.new("UIListLayout", Container)
                ContainerLayout.Padding = UDim.new(0, 4)
                ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                
                -- Resize Section
                ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    Container.Size = UDim2.new(1, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 10)
                    SectionFrame.Size = UDim2.new(1, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 40)
                end)
                
                local SectionObj = {}
                
                function SectionObj:Toggle(options)
                    local Togg = Instance.new("TextButton", Container)
                    Togg.Size = UDim2.new(1, -20, 0, 26)
                    Togg.Position = UDim2.new(0, 10, 0, 0)
                    Togg.BackgroundColor3 = Theme.MainBG
                    Togg.Text = ""
                    Togg.AutoButtonColor = false
                    
                    Instance.new("UICorner", Togg).CornerRadius = UDim.new(0, 4)
                    
                    local Title = Instance.new("TextLabel", Togg)
                    Title.Text = options.name
                    Title.Size = UDim2.new(1, -30, 1, 0)
                    Title.Position = UDim2.new(0, 10, 0, 0)
                    Title.BackgroundTransparency = 1
                    Title.TextColor3 = Theme.TextDim
                    Title.TextSize = 12
                    Title.Font = Theme.Font
                    Title.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local Checkbox = Instance.new("Frame", Togg)
                    Checkbox.Size = UDim2.fromOffset(16, 16)
                    Checkbox.Position = UDim2.new(1, -22, 0.5, 0)
                    Checkbox.AnchorPoint = Vector2.new(0, 0.5)
                    Checkbox.BackgroundColor3 = Theme.ItemBG
                    Instance.new("UICorner", Checkbox).CornerRadius = UDim.new(0, 4)
                    
                    local CheckStroke = Instance.new("UIStroke", Checkbox)
                    CheckStroke.Color = Color3.fromRGB(60, 60, 60)
                    CheckStroke.Thickness = 1
                    
                    local CheckFill = Instance.new("Frame", Checkbox)
                    CheckFill.Size = UDim2.fromScale(0, 0)
                    CheckFill.AnchorPoint = Vector2.new(0.5, 0.5)
                    CheckFill.Position = UDim2.fromScale(0.5, 0.5)
                    CheckFill.BackgroundColor3 = Theme.Accent
                    Instance.new("UICorner", CheckFill).CornerRadius = UDim.new(0, 2)
                    
                    local toggled = options.def or false
                    if toggled then
                        CheckFill.Size = UDim2.fromScale(0.7, 0.7)
                        Title.TextColor3 = Theme.Text
                        CheckStroke.Color = Theme.Accent
                        if options.callback then options.callback(true) end
                    end
                    
                    Togg.MouseButton1Click:Connect(function()
                        toggled = not toggled
                        TweenService:Create(CheckFill, TweenInfo.new(0.2), {Size = toggled and UDim2.fromScale(0.7, 0.7) or UDim2.fromScale(0, 0)}):Play()
                        TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = toggled and Theme.Text or Theme.TextDim}):Play()
                        TweenService:Create(CheckStroke, TweenInfo.new(0.2), {Color = toggled and Theme.Accent or Color3.fromRGB(60, 60, 60)}):Play()
                        
                        if options.callback then options.callback(toggled) end
                    end)
                end
                
                function SectionObj:Slider(options)
                    local min, max, val = options.min, options.max, options.def
                    
                    local Frame = Instance.new("Frame", Container)
                    Frame.Size = UDim2.new(1, -20, 0, 38)
                    Frame.Position = UDim2.new(0, 10, 0, 0)
                    Frame.BackgroundTransparency = 1
                    
                    local Title = Instance.new("TextLabel", Frame)
                    Title.Text = options.name
                    Title.Size = UDim2.new(1, 0, 0, 20)
                    Title.BackgroundTransparency = 1
                    Title.TextColor3 = Theme.TextDim
                    Title.TextSize = 12
                    Title.Font = Theme.Font
                    Title.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local ValueLabel = Instance.new("TextLabel", Frame)
                    ValueLabel.Text = tostring(val)
                    ValueLabel.Size = UDim2.new(1, 0, 0, 20)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.TextColor3 = Theme.Accent
                    ValueLabel.TextSize = 12
                    ValueLabel.Font = Theme.Font
                    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    
                    local SliderBG = Instance.new("TextButton", Frame)
                    SliderBG.Size = UDim2.new(1, 0, 0, 6)
                    SliderBG.Position = UDim2.new(0, 0, 0, 24)
                    SliderBG.BackgroundColor3 = Theme.ItemBG
                    SliderBG.AutoButtonColor = false
                    SliderBG.Text = ""
                    Instance.new("UICorner", SliderBG).CornerRadius = UDim.new(0, 3)
                    
                    local SliderFill = Instance.new("Frame", SliderBG)
                    SliderFill.Size = UDim2.fromScale((val - min) / (max - min), 1)
                    SliderFill.BackgroundColor3 = Theme.Accent
                    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 3)
                    
                    local function Update(input)
                        local sizeX = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
                        local newBase = min + (max - min) * sizeX
                        local decimals = options.decimals or 1 -- 1 means 0 decimals (integer), 0.1 means 1 decimal
                        
                        if decimals >= 1 then
                            newBase = math.floor(newBase)
                        else
                            local mult = 1 / decimals
                            newBase = math.floor(newBase * mult + 0.5) / mult
                        end
                        
                        val = newBase
                        ValueLabel.Text = tostring(val)
                        TweenService:Create(SliderFill, TweenInfo.new(0.05), {Size = UDim2.fromScale(sizeX, 1)}):Play()
                        if options.callback then options.callback(val) end
                    end
                    
                    local sliding = false
                    SliderBG.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            sliding = true
                            Update(input)
                            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = Theme.Text}):Play()
                        end
                    end)
                    
                    UserInputService.InputChanged:Connect(function(input)
                        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                            Update(input)
                        end
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            sliding = false
                            TweenService:Create(Title, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim}):Play()
                        end
                    end)
                end
                
                function SectionObj:Keybind(options)
                    local Frame = Instance.new("Frame", Container)
                    Frame.Size = UDim2.new(1, -20, 0, 26)
                    Frame.Position = UDim2.new(0, 10, 0, 0)
                    Frame.BackgroundTransparency = 1
                    
                    local Title = Instance.new("TextLabel", Frame)
                    Title.Text = options.name
                    Title.Size = UDim2.new(0.7, 0, 1, 0)
                    Title.BackgroundTransparency = 1
                    Title.TextColor3 = Theme.TextDim
                    Title.TextSize = 12
                    Title.Font = Theme.Font
                    Title.TextXAlignment = Enum.TextXAlignment.Left
                    
                    local Button = Instance.new("TextButton", Frame)
                    Button.Size = UDim2.new(0, 60, 0, 20)
                    Button.Position = UDim2.new(1, -60, 0, 3)
                    Button.BackgroundColor3 = Theme.ItemBG
                    Button.Text = options.def and options.def.Name or "None"
                    Button.Font = Theme.Font
                    Button.TextSize = 11
                    Button.TextColor3 = Theme.Text
                    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 4)
                    
                    local binding = false
                    local currentKey = options.def
                    
                    Button.MouseButton1Click:Connect(function()
                        binding = true
                        Button.Text = "..."
                        Button.TextColor3 = Theme.Accent
                    end)
                    
                    UserInputService.InputBegan:Connect(function(input, gp)
                        if binding then
                            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                                binding = false
                                currentKey = input.KeyCode
                                if currentKey == Enum.KeyCode.Unknown then currentKey = input.UserInputType end
                                Button.Text = currentKey.Name
                                Button.TextColor3 = Theme.Text
                            end
                        elseif not gp and currentKey then
                            if (input.KeyCode == currentKey or input.UserInputType == currentKey) then
                                if options.mode == "Toggle" then
                                    options.callback()
                                else
                                    options.callback(currentKey, true)
                                end
                            end
                        end
                    end)
                    
                    UserInputService.InputEnded:Connect(function(input)
                        if not binding and currentKey and options.mode == "Hold" then
                            if (input.KeyCode == currentKey or input.UserInputType == currentKey) then
                                options.callback(currentKey, false)
                            end
                        end
                    end)
                end

                function SectionObj:Colorpicker(options)
                    -- Simplified Colorpicker for stability
                    local Frame = Instance.new("Frame", Container)
                    Frame.Size = UDim2.new(1, -20, 0, 26)
                    Frame.Position = UDim2.new(0, 10, 0, 0)
                    Frame.BackgroundTransparency = 1
                    
                    local Title = Instance.new("TextLabel", Frame)
                    Title.Text = options.name
                    Title.Size = UDim2.new(0.7, 0, 1, 0)
                    Title.BackgroundTransparency = 1
                    Title.TextColor3 = Theme.TextDim
                    Title.TextSize = 12
                    Title.Font = Theme.Font
                    Title.TextXAlignment = Enum.TextXAlignment.Left

                    local Preview = Instance.new("TextButton", Frame)
                    Preview.Size = UDim2.new(0, 40, 0, 20)
                    Preview.Position = UDim2.new(1, -40, 0, 3)
                    Preview.BackgroundColor3 = options.def or Color3.new(1,1,1)
                    Preview.Text = ""
                    Instance.new("UICorner", Preview).CornerRadius = UDim.new(0, 4)
                    
                    local colors = {
                        Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
                        Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
                        Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)
                    }
                    local idx = 1
                    
                    Preview.MouseButton1Click:Connect(function()
                        idx = idx + 1
                        if idx > #colors then idx = 1 end
                        local c = colors[idx]
                        Preview.BackgroundColor3 = c
                        if options.callback then options.callback(c) end
                    end)
                end

                return SectionObj
            end
            return TabObj
        end
        return Window
    end

    -- ============================================================================
    -- === GAME LOGIC (Restored from Original) ===
    -- ============================================================================

    local localPlayer = Players.LocalPlayer
    local camera = Workspace.CurrentCamera

    -- Variables
    local Settings = {
        Distances = { Player = 3000, Ore = 750, Vehicle = 1500, Airdrop = 1500, Item = 1500, Corpse = 1500 },
        Aim = { Enabled = false, Smoothness = 15, FovRadius = 80, VisibleCheck = true, ShowFov = false, IsAiming = false, CurrentTarget = nil },
        BigHead = { Enabled = false, Size = 2, Transparency = 0 },
        Crosshair = { Enabled = false, Type = "Cross", Size = 10, Color = Color3.fromRGB(0, 255, 0), Thickness = 1.5 },
        Trails = { BulletEnabled = false, BulletColor = Color3.fromRGB(255, 255, 255), BulletThickness = 0.2, BulletLength = 10, BulletLifetime = 0.1 },
        Zoom = { IsZooming = false, DefaultFOV = 70, ZoomFOV = 20 },
        FreeCam = { Enabled = false, Speed = 150 },
        ESP = { Box = false, Distance = false, Type = false, Skeleton = false, Weapon = false, SleeperCheck = false, Corpse = false, Item = false, Armor = false, Airdrop = false, OreShowDist = false, Ore = {Stone = false, Iron = false, Nitrate = false}, Vehicles = {ATV = false, Boat = false, Helicopter = false, Trolly = false}, VehicleDist = false }
    }

    local Data = {
        ESPObjects = {}, OreESP = {}, VehicleESP = {}, AirdropESP = {}, ItemESP = {}, CorpseESP = {}, BigHeadCache = {}, PlayerWeapons = {}
    }

    -- Constants
    local ORE_COLORS = {
        Stone = {Color3.fromRGB(72, 72, 72)},
        Iron = {Color3.fromRGB(72, 72, 72), Color3.fromRGB(199, 172, 120)},
        Nitrate = {Color3.fromRGB(248, 248, 248), Color3.fromRGB(72, 72, 72)}
    }

    -- FreeCam
    local freeCamPitch, freeCamYaw, freeCamPosition, originalWalkSpeed, originalJumpPower
    local PITCH_LIMIT = math.rad(80)
    local freeCamActiveKeys = {}
    local freeCamKeyMap = {
        [Enum.KeyCode.W] = Vector3.new(0, 0, -1), [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
        [Enum.KeyCode.A] = Vector3.new(-1, 0, 0), [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
        [Enum.KeyCode.Space] = Vector3.new(0, 1, 0), [Enum.KeyCode.LeftShift] = Vector3.new(0, -1, 0)
    }

    local brightNightEnabled = false

    -- Helper Functions
    local function isValidCharacter(model)
        return model:IsA("Model") and model:FindFirstChild("Head") and (model:FindFirstChild("Humanoid") or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso"))
    end

    -- FreeCam Logic
    local function updateFreeCam(deltaTime)
        local mouseDelta = UserInputService:GetMouseDelta()
        freeCamYaw = freeCamYaw - mouseDelta.X * 0.002
        freeCamPitch = math.clamp(freeCamPitch - mouseDelta.Y * 0.002, -PITCH_LIMIT, PITCH_LIMIT)
        local rotation = CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
        local moveDirection = Vector3.zero
        for key, vec in pairs(freeCamKeyMap) do
            if freeCamActiveKeys[key] then moveDirection = moveDirection + vec end
        end
        if moveDirection.Magnitude > 0 then
            freeCamPosition = freeCamPosition + rotation:VectorToWorldSpace(moveDirection).Unit * Settings.FreeCam.Speed * deltaTime
        end
        camera.CFrame = CFrame.new(freeCamPosition) * rotation
    end

    local function enableFreeCam()
        local currentCFrame = camera.CFrame
        freeCamPosition = currentCFrame.Position
        local lookVector = currentCFrame.LookVector
        freeCamPitch = math.asin(-lookVector.Y)
        freeCamYaw = math.atan2(-lookVector.X, -lookVector.Z)
        camera.CameraType = Enum.CameraType.Scriptable
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            originalWalkSpeed = humanoid.WalkSpeed
            originalJumpPower = humanoid.JumpPower
            humanoid.WalkSpeed = 0
            humanoid.JumpPower = 0
        end
        RunService:BindToRenderStep("FreeCam", Enum.RenderPriority.Camera.Value + 1, updateFreeCam)
    end

    local function disableFreeCam()
        RunService:UnbindFromRenderStep("FreeCam")
        camera.CameraType = Enum.CameraType.Custom
        local character = localPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if originalWalkSpeed then humanoid.WalkSpeed = originalWalkSpeed end
            if originalJumpPower then humanoid.JumpPower = originalJumpPower end
        end
    end

    -- Aim Assist
    local function isTargetVisible(part)
        if not Settings.Aim.VisibleCheck then return true end
        local origin = camera.CFrame.Position
        local direction = (part.Position - origin).Unit * 500
        local ray = Ray.new(origin, direction)
        local hit, _ = Workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character})
        return hit and hit:IsDescendantOf(part.Parent)
    end

    local function findClosestTarget()
        local closestTarget = nil
        local closestDistance = Settings.Aim.FovRadius
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        for _, child in ipairs(Workspace:GetChildren()) do
            if child ~= localPlayer.Character and isValidCharacter(child) then
                local head = child:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < closestDistance then
                            if isTargetVisible(head) then
                                closestTarget = child
                                closestDistance = dist
                            end
                        end
                    end
                end
            end
        end
        return closestTarget
    end

    local function adjustAimTowards(targetPosition)
        local mousemoverel = mousemoverel or (Input and Input.MouseMove)
        if not mousemoverel then return end
        local screenPos = camera:WorldToViewportPoint(targetPosition)
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local scaleFactor = math.max(1, 1 + (Settings.Aim.Smoothness * 0.49))
        mousemoverel((screenPos.X - screenCenter.X) / scaleFactor, (screenPos.Y - screenCenter.Y) / scaleFactor)
    end

    -- Armor ESP UI (Styled to match NovaOps)
    local ArmorGui = Instance.new("ScreenGui")
    ArmorGui.Name = "NovaOps_Armor"
    ArmorGui.ResetOnSpawn = false
    ArmorGui.Parent = CoreGui -- Better in CoreGui to avoid checks
    local ArmorFrame = Instance.new("Frame")
    ArmorFrame.Name = "ArmorFrame"
    ArmorFrame.Size = UDim2.new(0, 220, 0, 160)
    ArmorFrame.Position = UDim2.new(1, -240, 0.35, 0)
    ArmorFrame.BackgroundColor3 = Theme.MainBG
    ArmorFrame.BorderColor3 = Theme.Accent
    ArmorFrame.BorderSizePixel = 1
    ArmorFrame.Parent = ArmorGui
    ArmorFrame.Visible = false
    Instance.new("UICorner", ArmorFrame).CornerRadius = UDim.new(0, 8)
    local ArmorStroke = Instance.new("UIStroke", ArmorFrame)
    ArmorStroke.Color = Theme.Accent
    ArmorStroke.Thickness = 1.5
    ArmorStroke.Transparency = 0.5

    local ArmorTitle = Instance.new("TextLabel")
    ArmorTitle.Name = "Title"
    ArmorTitle.Size = UDim2.new(1, 0, 0, 24)
    ArmorTitle.BackgroundTransparency = 1
    ArmorTitle.Font = Theme.FontBold
    ArmorTitle.TextSize = 14
    ArmorTitle.TextColor3 = Theme.Accent
    ArmorTitle.Text = "TARGET ARMOR"
    ArmorTitle.Parent = ArmorFrame

    local ArmorTargetLabel = Instance.new("TextLabel", ArmorFrame)
    ArmorTargetLabel.Position = UDim2.new(0, 10, 0, 28)
    ArmorTargetLabel.Size = UDim2.new(1, -20, 0, 20)
    ArmorTargetLabel.BackgroundTransparency = 1
    ArmorTargetLabel.Font = Theme.Font
    ArmorTargetLabel.TextSize = 12
    ArmorTargetLabel.TextColor3 = Theme.TextDim
    ArmorTargetLabel.Text = "None"
    ArmorTargetLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ArmorListLabel = Instance.new("TextLabel", ArmorFrame)
    ArmorListLabel.Position = UDim2.new(0, 10, 0, 50)
    ArmorListLabel.Size = UDim2.new(1, -20, 1, -55)
    ArmorListLabel.BackgroundTransparency = 1
    ArmorListLabel.Font = Theme.Font
    ArmorListLabel.TextSize = 12
    ArmorListLabel.TextColor3 = Theme.Text
    ArmorListLabel.TextWrapped = true
    ArmorListLabel.TextYAlignment = Enum.TextYAlignment.Top
    ArmorListLabel.Text = "No data"
    ArmorListLabel.TextXAlignment = Enum.TextXAlignment.Left

    local function getArmorTarget()
        if not Settings.Aim.ShowFov then return nil end
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        local bestTarget, bestDist = nil, Settings.Aim.FovRadius
        for _, child in ipairs(Workspace:GetChildren()) do
            if child ~= localPlayer.Character and isValidCharacter(child) then
                local head = child:FindFirstChild("Head")
                if head then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist <= Settings.Aim.FovRadius and dist < bestDist then
                            bestDist = dist
                            bestTarget = child
                        end
                    end
                end
            end
        end
        return bestTarget
    end

    local function getArmorNames(model)
        local armorFolder = model:FindFirstChild("Armor")
        local names = {}
        if armorFolder then
            for _, item in ipairs(armorFolder:GetChildren()) do
                table.insert(names, item.Name)
            end
        end
        table.sort(names)
        return names
    end

    -- Drawings
    local Crosshair = { V = Drawing.new("Line"), H = Drawing.new("Line") }
    Crosshair.V.Visible = false; Crosshair.H.Visible = false

    local fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Color = Color3.fromRGB(255, 255, 255)
    fovCircle.Transparency = 0.5

    -- Bullet Trail
    local function createBulletTrail(bullet)
        local trailData = { points = {} }
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not Settings.Trails.BulletEnabled then conn:Disconnect(); return end
            if bullet and bullet.Parent then
                table.insert(trailData.points, 1, bullet.Position)
                if #trailData.points > Settings.Trails.BulletLength then table.remove(trailData.points) end
                for i = 1, #trailData.points - 1 do
                    local p1, p2 = trailData.points[i], trailData.points[i+1]
                    local dist = (p1 - p2).Magnitude
                    if dist > 0 then
                        local part = Instance.new("Part")
                        part.Anchored = true; part.CanCollide = false
                        part.Size = Vector3.new(Settings.Trails.BulletThickness, Settings.Trails.BulletThickness, dist)
                        part.CFrame = CFrame.new(p1, p2) * CFrame.new(0, 0, -dist/2)
                        part.Color = Settings.Trails.BulletColor; part.Material = Enum.Material.ForceField
                        part.Parent = Workspace; Debris:AddItem(part, Settings.Trails.BulletLifetime)
                    end
                end
            else
                conn:Disconnect()
            end
        end)
    end

    -- Big Head
    local function updateBigHead(model)
        if model == localPlayer.Character then return end
        local head = model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            if Settings.BigHead.Enabled then
                if not Data.BigHeadCache[head] then Data.BigHeadCache[head] = {Size = head.Size, Transparency = head.Transparency, CanCollide = head.CanCollide} end
                head.Size = Vector3.new(Settings.BigHead.Size, Settings.BigHead.Size, Settings.BigHead.Size)
                head.Transparency = Settings.BigHead.Transparency; head.CanCollide = false
            elseif Data.BigHeadCache[head] then
                head.Size = Data.BigHeadCache[head].Size
                head.Transparency = Data.BigHeadCache[head].Transparency
                head.CanCollide = Data.BigHeadCache[head].CanCollide
                Data.BigHeadCache[head] = nil
            end
        end
    end

    local function resetBigHead()
        for head, data in pairs(Data.BigHeadCache) do
            if head and head.Parent then head.Size = data.Size; head.Transparency = data.Transparency; head.CanCollide = data.CanCollide end
        end
        Data.BigHeadCache = {}
    end

    -- ESP Functions
    local function createESPDrawText(text, color)
        local drawing = Drawing.new("Text")
        drawing.Text = text
        drawing.Color = color
        drawing.Size = 16
        drawing.Center = true
        drawing.Outline = true
        return drawing
    end

    local function isCorpse(model)
        local parts = {}
        for _, child in ipairs(model:GetChildren()) do if child:IsA("BasePart") then table.insert(parts, child) end end
        if #parts ~= 2 then return false end
        local mat1, mat2 = parts[1].Material, parts[2].Material
        return (mat1 == Enum.Material.Fabric and mat2 == Enum.Material.Metal) or (mat1 == Enum.Material.Metal and mat2 == Enum.Material.Fabric)
    end

    local function createCorpseESP(model)
        if Data.CorpseESP[model] or not isCorpse(model) then return end
        local drawing = createESPDrawText("Corpse", Color3.fromRGB(255, 0, 0))
        Data.CorpseESP[model] = { drawing = drawing, model = model }
        model.Destroying:Connect(function() pcall(function() drawing:Remove() end) Data.CorpseESP[model] = nil end)
    end

    local function isItem(model)
        return model:FindFirstChild("Union") and model:FindFirstChild("Display") and model:FindFirstChild("Part")
    end

    local function createItemESP(model)
        if Data.ItemESP[model] or not isItem(model) then return end
        local part = model:FindFirstChild("Union") or model:FindFirstChild("Display") or model:FindFirstChild("Part")
        if part then
            local drawing = createESPDrawText("Item", Color3.fromRGB(255, 255, 0))
            Data.ItemESP[model] = { drawing = drawing, part = part }
        end
    end

    local function createPlayerESP(model)
        if Data.ESPObjects[model] then return end
        local h, t = model:FindFirstChild("Head"), model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso")
        if not h or not t then return end
        local obj = { box = Drawing.new("Square"), outline = Drawing.new("Square"), text = Drawing.new("Text"), weapon = Drawing.new("Text"), skeleton = {} }
        obj.box.Thickness = 1; obj.box.Filled = false
        obj.outline.Thickness = 1; obj.outline.Color = Color3.new(0,0,0)
        obj.text.Size = 16; obj.text.Center = true; obj.text.Outline = true
        obj.weapon.Size = 16; obj.weapon.Center = true; obj.weapon.Outline = true
        local conn_list = { {"Head", "Torso"}, {"Torso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"Torso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"Torso", "LowerTorso"}, {"RightUpperLeg", "RightLowerLeg"}, {"LowerTorso", "RightUpperLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"}, {"RightLowerArm", "RightHand"}, {"LeftLowerArm", "LeftHand"} }
        for _, conn in ipairs(conn_list) do
            local l = Drawing.new("Line"); l.Thickness = 1.5
            table.insert(obj.skeleton, {line = l, a = conn[1], b = conn[2]})
        end
        Data.ESPObjects[model] = obj
    end

    local function checkOre(model)
        local parts = {}
        for _, v in ipairs(model:GetChildren()) do if v:IsA("MeshPart") then table.insert(parts, v) end end
        local function compareColor(c1, c2) return math.abs(c1.R - c2.R) < 0.02 and math.abs(c1.G - c2.G) < 0.02 and math.abs(c1.B - c2.B) < 0.02 end
        if #parts == 1 and compareColor(parts[1].Color, ORE_COLORS.Stone[1]) then return "Stone", parts[1]
        elseif #parts == 2 then
            local c1, c2 = parts[1].Color, parts[2].Color
            if (compareColor(c1, ORE_COLORS.Iron[1]) and compareColor(c2, ORE_COLORS.Iron[2])) or (compareColor(c1, ORE_COLORS.Iron[2]) and compareColor(c2, ORE_COLORS.Iron[1])) then return "Iron", parts[1]
            elseif (compareColor(c1, ORE_COLORS.Nitrate[1]) and compareColor(c2, ORE_COLORS.Nitrate[2])) or (compareColor(c1, ORE_COLORS.Nitrate[2]) and compareColor(c2, ORE_COLORS.Nitrate[1])) then return "Nitrate", parts[1] end
        end
    end

    -- Game Environment Functions
    local function getTerrain() repeat task.wait() until workspace:FindFirstChildOfClass("Terrain"); return workspace:FindFirstChildOfClass("Terrain") end
    local terrain = getTerrain()

    local function setGrass(enable)
        if sethiddenproperty then pcall(function() sethiddenproperty(terrain, "Decoration", enable) end) end
    end

    local function toggleLeaves(enable)
        local leafNames = {"Fir3_Leaves", "Elm1_Leaves", "Birch1_Leaves"}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and table.find(leafNames, obj.Name) then obj.Transparency = enable and 0 or 1; obj.CanCollide = enable end
        end
    end

    -- ============================================================================
    -- === RUNTIME LOOPS ===
    -- ============================================================================

    local chamUpdateCounter = 0
    RunService.RenderStepped:Connect(function()
        local camPos = camera.CFrame.Position
        local viewportCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

        -- Zoom
        if not Settings.FreeCam.Enabled then
            camera.FieldOfView = Settings.Zoom.IsZooming and Settings.Zoom.ZoomFOV or Settings.Zoom.DefaultFOV
        end

        -- Aim Assist
        fovCircle.Position = viewportCenter
        fovCircle.Radius = Settings.Aim.FovRadius
        fovCircle.Visible = Settings.Aim.Enabled and Settings.Aim.ShowFov
        if Settings.Aim.Enabled and Settings.Aim.IsAiming then
            if not Settings.Aim.CurrentTarget or not Settings.Aim.CurrentTarget.Parent then Settings.Aim.CurrentTarget = findClosestTarget() end
            if Settings.Aim.CurrentTarget then
                local head = Settings.Aim.CurrentTarget:FindFirstChild("Head")
                if head then adjustAimTowards(head.Position) end
            end
        else
            Settings.Aim.CurrentTarget = nil
        end

        -- Armor ESP UI
        if Settings.ESP.Armor and Settings.Aim.ShowFov then
            ArmorFrame.Visible = true
            local target = getArmorTarget()
            if target and target:FindFirstChild("Head") then
                ArmorTargetLabel.Text = ("Target: %s"):format(target.Name)
                local armorList = getArmorNames(target)
                ArmorListLabel.Text = #armorList > 0 and table.concat(armorList, "\n") or "No armor equipped"
            else
                ArmorTargetLabel.Text = "None"
                ArmorListLabel.Text = "No player inside FOV"
            end
        else
            ArmorFrame.Visible = false
        end

        -- Crosshair
        if Settings.Crosshair.Enabled then
            local size = Settings.Crosshair.Size
            Crosshair.V.Visible = true; Crosshair.H.Visible = true
            Crosshair.V.From = Vector2.new(viewportCenter.X, viewportCenter.Y - size); Crosshair.V.To = Vector2.new(viewportCenter.X, viewportCenter.Y + size)
            Crosshair.H.From = Vector2.new(viewportCenter.X - size, viewportCenter.Y); Crosshair.H.To = Vector2.new(viewportCenter.X + size, viewportCenter.Y)
            Crosshair.V.Color = Settings.Crosshair.Color; Crosshair.H.Color = Settings.Crosshair.Color
            Crosshair.V.Thickness = Settings.Crosshair.Thickness; Crosshair.H.Thickness = Settings.Crosshair.Thickness
        else
            Crosshair.V.Visible = false; Crosshair.H.Visible = false
        end

        -- Bright Night
        if brightNightEnabled then
            local hour, min, sec = string.match(Lighting.TimeOfDay, "(%d+):(%d+):(%d+)")
            local timeInHours = tonumber(hour) + (tonumber(min) / 60) + (tonumber(sec) / 3600)
            local targetExposure = 0
            if timeInHours >= 18.5 or timeInHours < 6.5 then
                if timeInHours >= 18.5 then timeInHours = timeInHours - 24 end
                if timeInHours < 0 then targetExposure = 2.5 * ((timeInHours + 3) / 3) else targetExposure = 2.5 * (1 - math.clamp(timeInHours / 6.5, 0, 1)) end
                Lighting.ExposureCompensation = targetExposure
            end
        else
            Lighting.ExposureCompensation = 0
        end

        -- Player ESP
        for model, esp in pairs(Data.ESPObjects) do
            local h, t = model:FindFirstChild("Head"), model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("LowerTorso")
            local valid = h and t and true or false
            if valid and Settings.ESP.SleeperCheck then
                local lt = model:FindFirstChild("LowerTorso")
                local rr = lt and lt:FindFirstChild("RootRig")
                if rr and typeof(rr.CurrentAngle) == "number" and rr.CurrentAngle ~= 0 then valid = false end
            end
            local screenPos, onScreen, dist
            if valid then
                dist = (h.Position - camPos).Magnitude
                if dist > Settings.Distances.Player then valid = false end
                if valid then screenPos, onScreen = camera:WorldToViewportPoint((h.Position + t.Position)/2) end
            end
            if valid and onScreen then
                local bot = (t:FindFirstChild("LeftBooster") ~= nil)
                local scale = 1000 / (dist * 2) / math.tan(math.rad(camera.FieldOfView / 1.7))
                local w, hb = math.clamp(6.5 * scale, 10, 600), math.clamp(9.5 * scale, 14, 800)
                local x, y = screenPos.X - w/2, screenPos.Y - hb/3.5
                if Settings.ESP.Box then
                    esp.box.Size = Vector2.new(w, hb); esp.box.Position = Vector2.new(x, y)
                    esp.box.Color = bot and Color3.fromRGB(255,255,255) or Color3.fromRGB(0, 150, 255); esp.box.Visible = true
                    esp.outline.Size = Vector2.new(w+2, hb+2); esp.outline.Position = Vector2.new(x-1, y-1); esp.outline.Visible = true
                else
                    esp.box.Visible = false; esp.outline.Visible = false
                end
                
                local tParts = {}
                if Settings.ESP.Type then table.insert(tParts, bot and "Player" or "Bot") end
                if Settings.ESP.Distance then table.insert(tParts, math.floor(dist).."m") end
                esp.text.Text = table.concat(tParts, " | ")
                if #tParts > 0 then
                    esp.text.Position = Vector2.new(screenPos.X, y - 16); esp.text.Color = bot and Color3.fromRGB(255,255,255) or Color3.fromRGB(0, 150, 255); esp.text.Visible = true
                else
                    esp.text.Visible = false
                end

                if Settings.ESP.Weapon then
                    esp.weapon.Text = Data.PlayerWeapons[model] or "None"; esp.weapon.Position = Vector2.new(screenPos.X, y + hb)
                    esp.weapon.Color = bot and Color3.fromRGB(255,255,255) or Color3.fromRGB(0, 150, 255); esp.weapon.Visible = true
                else
                    esp.weapon.Visible = false
                end

                if Settings.ESP.Skeleton then
                    for _, s in ipairs(esp.skeleton) do
                        local pa, pb = model:FindFirstChild(s.a), model:FindFirstChild(s.b)
                        if pa and pb then
                            local p1, v1 = camera:WorldToViewportPoint(pa.Position); local p2, v2 = camera:WorldToViewportPoint(pb.Position)
                            if v1 and v2 then
                                s.line.From = Vector2.new(p1.X, p1.Y); s.line.To = Vector2.new(p2.X, p2.Y)
                                s.line.Color = bot and Color3.fromRGB(255,255,255) or Color3.fromRGB(0, 150, 255); s.line.Visible = true
                            else
                                s.line.Visible = false
                            end
                        else
                            s.line.Visible = false
                        end
                    end
                else
                    for _, s in ipairs(esp.skeleton) do s.line.Visible = false end
                end
            else
                esp.box.Visible = false; esp.outline.Visible = false; esp.text.Visible = false; esp.weapon.Visible = false
                for _, s in ipairs(esp.skeleton) do s.line.Visible = false end
            end
        end

        -- Corpse ESP
        for model, data in pairs(Data.CorpseESP) do
            local primaryPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primaryPart and Settings.ESP.Corpse then
                local dist = (camPos - primaryPart.Position).Magnitude
                if dist <= Settings.Distances.Corpse then
                    local pos, vis = camera:WorldToViewportPoint(primaryPart.Position)
                    data.drawing.Visible = vis
                    if vis then data.drawing.Position = Vector2.new(pos.X, pos.Y - 20) end
                else
                    data.drawing.Visible = false
                end
            else
                data.drawing.Visible = false
            end
        end

        -- Item ESP
        for model, data in pairs(Data.ItemESP) do
            if data.part and data.part.Parent and Settings.ESP.Item then
                local dist = (camPos - data.part.Position).Magnitude
                if dist <= Settings.Distances.Item then
                    local pos, vis = camera:WorldToViewportPoint(data.part.Position)
                    data.drawing.Visible = vis
                    if vis then data.drawing.Position = Vector2.new(pos.X, pos.Y - 20) end
                else
                    data.drawing.Visible = false
                end
            else
                if data and data.drawing then data.drawing.Visible = false end
                if not (data.part and data.part.Parent) then pcall(function() data.drawing:Remove() end) Data.ItemESP[model] = nil end
            end
        end

        -- Ore ESP
        for model, data in pairs(Data.OreESP) do
            if data.part and data.part.Parent then
                local dist = (camPos - data.part.Position).Magnitude
                local pos, vis = camera:WorldToViewportPoint(data.part.Position)
                if vis and dist <= Settings.Distances.Ore and Settings.ESP.Ore[data.oreType] then
                    data.text.Text = Settings.ESP.OreShowDist and string.format("%s [%dm]", data.oreType, math.floor(dist)) or data.oreType
                    data.text.Position = Vector2.new(pos.X, pos.Y); data.text.Visible = true
                else
                    data.text.Visible = false
                end
            else
                pcall(function() data.text:Remove() end); Data.OreESP[model] = nil
            end
        end

        -- Big Head Logic
        if Settings.BigHead.Enabled and chamUpdateCounter % 25 == 0 then
            for _, v in ipairs(Workspace:GetChildren()) do if v:IsA("Model") then updateBigHead(v) end end
        end
        chamUpdateCounter = chamUpdateCounter + 1
    end)

    -- Events
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if freeCamKeyMap[input.KeyCode] then freeCamActiveKeys[input.KeyCode] = true end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if freeCamKeyMap[input.KeyCode] then freeCamActiveKeys[input.KeyCode] = false end
    end)
    Workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "Bullet" and not descendant:IsDescendantOf(ReplicatedStorage) and Settings.Trails.BulletEnabled then createBulletTrail(descendant) end
    end)
    task.spawn(function()
        while task.wait(2) do
            for _, v in ipairs(Workspace:GetChildren()) do
                if v:IsA("Model") then
                    if not Data.OreESP[v] then
                        local oType, oPart = checkOre(v)
                        if oType then
                            local t = Drawing.new("Text"); t.Size = 16; t.Center = true; t.Outline = true; t.Color = Color3.new(1,1,1)
                            Data.OreESP[v] = {text = t, oreType = oType, part = oPart}
                        end
                    end
                    createItemESP(v)
                end
            end
        end
    end)
    Workspace.ChildAdded:Connect(function(child)
        if child:IsA("Model") then createPlayerESP(child); createCorpseESP(child); createItemESP(child) end
    end)
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Model") then createPlayerESP(v); createCorpseESP(v); createItemESP(v) end
    end

    Lighting.GlobalShadows = true
    setGrass(true)
    toggleLeaves(true)

    -- ============================================================================
    -- === INITIALIZE CUSTOM UI ===
    -- ============================================================================

    local Window = Library:CreateWindow({Name = "NovaOps - Trident"})

    -- === ESP Page ===
    local ESPPage = Window:Tab("ESP")
    local PlayerESP = ESPPage:Section({name = "Player ESP", side = "left"})
    local WeaponESP = ESPPage:Section({name = "Weapon ESP", side = "left"})
    local ArmorESP = ESPPage:Section({name = "Armor ESP", side = "left"})
    local WorldESP = ESPPage:Section({name = "World ESP", side = "right"})
    local OreESP = ESPPage:Section({name = "Ore ESP", side = "right"})
    local DistanceSection = ESPPage:Section({name = "Distances", side = "right"})

    PlayerESP:Toggle({name = "Box ESP", callback = function(v) Settings.ESP.Box = v end})
    PlayerESP:Toggle({name = "Distance ESP", callback = function(v) Settings.ESP.Distance = v end})
    PlayerESP:Toggle({name = "Name/Bot ESP", callback = function(v) Settings.ESP.Type = v end})
    PlayerESP:Toggle({name = "Skeleton ESP", callback = function(v) Settings.ESP.Skeleton = v end})
    PlayerESP:Toggle({name = "Sleeper Check", callback = function(v) Settings.ESP.SleeperCheck = v end})
    PlayerESP:Slider({name = "Player Max Dist", min = 1, max = 5000, def = 3000, callback = function(v) Settings.Distances.Player = v end})

    WeaponESP:Toggle({name = "Enable Weapon ESP", callback = function(v) Settings.ESP.Weapon = v end})
    ArmorESP:Toggle({name = "Armor UI", callback = function(v) Settings.ESP.Armor = v end})

    OreESP:Toggle({name = "Stone", callback = function(v) Settings.ESP.Ore.Stone = v end})
    OreESP:Toggle({name = "Iron", callback = function(v) Settings.ESP.Ore.Iron = v end})
    OreESP:Toggle({name = "Nitrate", callback = function(v) Settings.ESP.Ore.Nitrate = v end})
    OreESP:Toggle({name = "Show Distance", callback = function(v) Settings.ESP.OreShowDist = v end})

    WorldESP:Toggle({name = "Corpse ESP", callback = function(v) Settings.ESP.Corpse = v end})
    WorldESP:Toggle({name = "Item ESP", callback = function(v) Settings.ESP.Item = v end})
    WorldESP:Toggle({name = "Airdrop ESP", callback = function(v) Settings.ESP.Airdrop = v end})

    DistanceSection:Slider({name = "Ore Distance", min = 1, max = 1500, def = 750, callback = function(v) Settings.Distances.Ore = v end})
    DistanceSection:Slider({name = "Item Distance", min = 1, max = 1500, def = 1500, callback = function(v) Settings.Distances.Item = v end})
    DistanceSection:Slider({name = "Corpse Distance", min = 1, max = 1500, def = 1500, callback = function(v) Settings.Distances.Corpse = v end})
    DistanceSection:Slider({name = "Vehicle Distance", min = 1, max = 1500, def = 1500, callback = function(v) Settings.Distances.Vehicle = v end})

    -- === AimBot Page ===
    local AimPage = Window:Tab("AimBot")
    local AimAssist = AimPage:Section({name = "Aim Assist", side = "left"})
    local BigHead = AimPage:Section({name = "Big Head", side = "right"})

    AimAssist:Toggle({name = "Aim Assist", callback = function(v) Settings.Aim.Enabled = v end})
    AimAssist:Keybind({name = "Aim Key", def = Enum.UserInputType.MouseButton2, mode = "Hold", callback = function(key, active) Settings.Aim.IsAiming = active; if not active then Settings.Aim.CurrentTarget = nil end end})
    AimAssist:Toggle({name = "Visible Check", callback = function(v) Settings.Aim.VisibleCheck = v end})
    AimAssist:Toggle({name = "Show FOV", callback = function(v) Settings.Aim.ShowFov = v end})
    AimAssist:Slider({name = "Smoothness", min = 1, max = 100, def = 15, callback = function(v) Settings.Aim.Smoothness = v end})
    AimAssist:Slider({name = "FOV Radius", min = 10, max = 200, def = 80, callback = function(v) Settings.Aim.FovRadius = v end})

    BigHead:Toggle({name = "Enabled", callback = function(v) Settings.BigHead.Enabled = v; if not v then resetBigHead() end end})
    BigHead:Slider({name = "Size", min = 1, max = 10, def = 2, callback = function(v) Settings.BigHead.Size = v end})
    BigHead:Slider({name = "Transparency", min = 0, max = 1, def = 0, decimals = 0.1, callback = function(v) Settings.BigHead.Transparency = v end})

    -- === Player Page ===
    local PlayerPage = Window:Tab("Player")
    local CrosshairSec = PlayerPage:Section({name = "Crosshair", side = "left"})
    local CamSec = PlayerPage:Section({name = "Camera", side = "left"})
    local TrailSec = PlayerPage:Section({name = "Trails", side = "right"})

    CrosshairSec:Toggle({name = "Enabled", callback = function(v) Settings.Crosshair.Enabled = v end})
    CrosshairSec:Slider({name = "Size", min = 2, max = 50, def = 10, callback = function(v) Settings.Crosshair.Size = v end})
    CrosshairSec:Colorpicker({name = "Color", def = Color3.fromRGB(0, 255, 0), callback = function(v) Settings.Crosshair.Color = v end})

    CamSec:Keybind({name = "Zoom Key", def = Enum.KeyCode.X, mode = "Hold", callback = function(key, active) Settings.Zoom.IsZooming = active end})
    CamSec:Slider({name = "Base FOV", min = 50, max = 120, def = 70, callback = function(v) Settings.Zoom.DefaultFOV = v end})
    CamSec:Keybind({name = "Free Cam", def = Enum.KeyCode.Z, mode = "Toggle", callback = function() Settings.FreeCam.Enabled = not Settings.FreeCam.Enabled; if Settings.FreeCam.Enabled then enableFreeCam() else disableFreeCam() end end})
    CamSec:Slider({name = "FreeCam Speed", min = 1, max = 500, def = 150, callback = function(v) Settings.FreeCam.Speed = v end})

    TrailSec:Colorpicker({name = "Arrow Color", def = Color3.fromRGB(255, 255, 255), callback = function(v) if ReplicatedStorage:FindFirstChild("Arrow") and ReplicatedStorage.Arrow:FindFirstChild("Trail") then ReplicatedStorage.Arrow.Trail.Color = ColorSequence.new(v) end end})
    TrailSec:Slider({name = "Arrow Life", min = 0.15, max = 20, def = 0.15, decimals = 0.01, callback = function(v) if ReplicatedStorage:FindFirstChild("Arrow") and ReplicatedStorage.Arrow:FindFirstChild("Trail") then ReplicatedStorage.Arrow.Trail.Lifetime = v end end})
    TrailSec:Toggle({name = "Bullet Trail", callback = function(v) Settings.Trails.BulletEnabled = v end})
    TrailSec:Colorpicker({name = "Bullet Color", def = Color3.fromRGB(255, 255, 255), callback = function(v) Settings.Trails.BulletColor = v end})
    TrailSec:Slider({name = "Thickness", min = 0.1, max = 1, def = 0.2, decimals = 0.1, callback = function(v) Settings.Trails.BulletThickness = v end})

    -- === Game Page ===
    local GamePage = Window:Tab("Game")
    local WaterSec = GamePage:Section({name = "Water", side = "left"})
    local OtherSec = GamePage:Section({name = "Environment", side = "left"})
    local CloudSec = GamePage:Section({name = "Clouds", side = "right"})
    local LightSec = GamePage:Section({name = "Lighting", side = "right"})

    WaterSec:Colorpicker({name = "Water Color", def = Color3.fromRGB(12, 84, 92), callback = function(v) game.Workspace.Terrain.WaterColor = v end})
    WaterSec:Toggle({name = "Reflectance", def = true, callback = function(v) game.Workspace.Terrain.WaterReflectance = v and 1 or 0 end})
    WaterSec:Slider({name = "Wave Speed", min = 1, max = 100, def = 10, callback = function(v) game.Workspace.Terrain.WaterWaveSpeed = v end})

    OtherSec:Toggle({name = "Shadows", def = true, callback = function(v) Lighting.GlobalShadows = v end})
    OtherSec:Toggle({name = "Grass", def = true, callback = function(v) setGrass(v) end})
    OtherSec:Toggle({name = "Tree Leaves", def = true, callback = function(v) toggleLeaves(v) end})
    OtherSec:Toggle({name = "Bright Night", callback = function(v) brightNightEnabled = v; if not v then Lighting.ExposureCompensation = 0 end end})

    CloudSec:Colorpicker({name = "Color", def = Color3.fromRGB(255, 255, 255), callback = function(v) if game.Workspace.Terrain:FindFirstChild("Clouds") then game.Workspace.Terrain.Clouds.Color = v end end})
    CloudSec:Slider({name = "Cover", min = 0, max = 1, def = 0.6, decimals = 0.1, callback = function(v) if game.Workspace.Terrain:FindFirstChild("Clouds") then game.Workspace.Terrain.Clouds.Cover = v end end})

    LightSec:Toggle({name = "Enabled", callback = function(v) Lighting.StimEffect.Enabled = v end})
    LightSec:Slider({name = "Brightness", min = 0.1, max = 100, def = 0.1, decimals = 0.1, callback = function(v) Lighting.StimEffect.Brightness = v end})
    LightSec:Slider({name = "Contrast", min = 0, max = 20, def = 1, decimals = 0.1, callback = function(v) Lighting.StimEffect.Contrast = v end})
    LightSec:Slider({name = "Saturation", min = 0, max = 100, def = 10, callback = function(v) Lighting.StimEffect.Saturation = v end})

    -- Notification
    local function notify(text)
        local Notif = Instance.new("Frame", UI)
        Notif.Size = UDim2.new(0, 250, 0, 40)
        Notif.Position = UDim2.new(1, 10, 0.85, 0)
        Notif.BackgroundColor3 = Theme.SecondaryBG
        Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Notif)
        Stroke.Color = Theme.Accent
        Stroke.Thickness = 1
        
        local Lbl = Instance.new("TextLabel", Notif)
        Lbl.Size = UDim2.new(1, 0, 1, 0)
        Lbl.BackgroundTransparency = 1
        Lbl.Text = text
        Lbl.Font = Theme.Font
        Lbl.TextColor3 = Theme.Text
        Lbl.TextSize = 12
        
        TweenService:Create(Notif, TweenInfo.new(0.5), {Position = UDim2.new(1, -260, 0.85, 0)}):Play()
        task.delay(3, function()
            TweenService:Create(Notif, TweenInfo.new(0.5), {Position = UDim2.new(1, 10, 0.85, 0)}):Play()
            task.wait(0.5)
            Notif:Destroy()
        end)
    end

    notify("NovaOps Loaded Successfully! Press INS to Toggle")
end

-- Start KeyAuth System
RunKeyAuth()