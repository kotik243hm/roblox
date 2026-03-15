-- PastaLand UI
-- Game: Flick
-- Style: Gamesense (Menu) / NeverLose (Watermark/HUD)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Global Connections Table
local Connections = {}
local menuOpen = false -- UI state

-- Create ScreenGui
local PastaLandGui = Instance.new("ScreenGui")
PastaLandGui.Name = "PastaLandGui"
PastaLandGui.ResetOnSpawn = false
PastaLandGui.IgnoreGuiInset = true -- Fixes custom cursor offset mapping accurately
-- To bypass standard anti-cheats (if executed via executor), you would put this in CoreGui.
-- For standard testing in Studio, we put it in PlayerGui.
local success = pcall(function()
    PastaLandGui.Parent = CoreGui
end)
if not success then
    PastaLandGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Utility for Hover Effect
local function ApplyButtonHover(btn, normalColor, hoverColor)
    table.insert(Connections, btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end))
    table.insert(Connections, btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = normalColor}):Play()
    end))
end

-- ==========================================
-- CUSTOM CIRCLE CURSOR
-- ==========================================

local CustomCursor = Instance.new("Frame")
CustomCursor.Name = "CustomCursor"
CustomCursor.Size = UDim2.new(0, 12, 0, 12)
CustomCursor.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
CustomCursor.BorderSizePixel = 0
CustomCursor.ZIndex = 99999
CustomCursor.Visible = false
CustomCursor.Parent = PastaLandGui

local CursorCorner = Instance.new("UICorner")
CursorCorner.CornerRadius = UDim.new(1, 0)
CursorCorner.Parent = CustomCursor

local CursorStroke = Instance.new("UIStroke")
CursorStroke.Color = Color3.fromRGB(10, 10, 10)
CursorStroke.Thickness = 1
CursorStroke.Parent = CustomCursor

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if menuOpen then
        -- Force unlock mouse so the user can interact (even in first person)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        
        -- Update custom cursor correctly
        local mouseLoc = UserInputService:GetMouseLocation()
        CustomCursor.Position = UDim2.new(0, mouseLoc.X - 6, 0, mouseLoc.Y - 6)
    end
end))

-- ==========================================
-- INTRO / LOADING (Fatality Style)
-- ==========================================

local IntroScreen = Instance.new("Frame")
IntroScreen.Size = UDim2.new(1, 0, 1, 0)
IntroScreen.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
IntroScreen.BackgroundTransparency = 1 -- Will tween into view, then out
IntroScreen.BorderSizePixel = 0
IntroScreen.ZIndex = 999
IntroScreen.Parent = PastaLandGui

local IntroLogo = Instance.new("TextLabel")
IntroLogo.Size = UDim2.new(0, 200, 0, 50)
IntroLogo.Position = UDim2.new(0.5, -100, 0.5, -40)
IntroLogo.BackgroundTransparency = 1
IntroLogo.Text = "PL"
IntroLogo.TextColor3 = Color3.fromRGB(255, 180, 0)
IntroLogo.Font = Enum.Font.GothamBold
IntroLogo.TextSize = 54
IntroLogo.TextTransparency = 1
IntroLogo.ZIndex = 1000
IntroLogo.Parent = IntroScreen

local IntroSub = Instance.new("TextLabel")
IntroSub.Size = UDim2.new(0, 200, 0, 20)
IntroSub.Position = UDim2.new(0.5, -100, 0.5, 15)
IntroSub.BackgroundTransparency = 1
IntroSub.Text = "loading PastaLand..."
IntroSub.TextColor3 = Color3.fromRGB(150, 150, 150)
IntroSub.Font = Enum.Font.Code
IntroSub.TextSize = 14
IntroSub.TextTransparency = 1
IntroSub.ZIndex = 1000
IntroSub.Parent = IntroScreen

local LoadingBarBG = Instance.new("Frame")
LoadingBarBG.Size = UDim2.new(0, 200, 0, 2)
LoadingBarBG.Position = UDim2.new(0.5, -100, 0.5, 45)
LoadingBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
LoadingBarBG.BorderSizePixel = 0
LoadingBarBG.BackgroundTransparency = 1
LoadingBarBG.ZIndex = 1000
LoadingBarBG.Parent = IntroScreen

local LoadingBarFill = Instance.new("Frame")
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
LoadingBarFill.BorderSizePixel = 0
LoadingBarFill.ZIndex = 1001
LoadingBarFill.Parent = LoadingBarBG

-- ==========================================
-- HUD & WATERMARK (NeverLose Style)
-- ==========================================

local HUD = Instance.new("Frame")
HUD.Name = "HUD"
HUD.Size = UDim2.new(1, 0, 1, 0)
HUD.BackgroundTransparency = 1
HUD.Visible = false -- Hidden initially until intro is done
HUD.Parent = PastaLandGui

local Watermark = Instance.new("Frame")
Watermark.Name = "Watermark"
Watermark.Size = UDim2.new(0, 260, 0, 30)
Watermark.Position = UDim2.new(1, -270, 0, 15)
Watermark.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Watermark.BorderSizePixel = 0
Watermark.Parent = HUD

-- Adding stroke for better visual quality
local WatermarkStroke = Instance.new("UIStroke")
WatermarkStroke.Color = Color3.fromRGB(45, 45, 45)
WatermarkStroke.Thickness = 1
WatermarkStroke.Parent = Watermark

-- Top Accent Line
local WatermarkAccent = Instance.new("Frame")
WatermarkAccent.Size = UDim2.new(1, 0, 0, 2)
WatermarkAccent.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
WatermarkAccent.BorderSizePixel = 0
WatermarkAccent.Parent = Watermark

-- Watermark Text
local WatermarkText = Instance.new("TextLabel")
WatermarkText.Size = UDim2.new(1, -16, 1, -2)
WatermarkText.Position = UDim2.new(0, 8, 0, 2)
WatermarkText.BackgroundTransparency = 1
WatermarkText.Text = "PL | PastaLand | FPS: 0 | Ping: 0"
WatermarkText.TextColor3 = Color3.fromRGB(220, 220, 220)
WatermarkText.Font = Enum.Font.Code
WatermarkText.TextSize = 14
WatermarkText.TextXAlignment = Enum.TextXAlignment.Left
WatermarkText.Parent = Watermark

-- Update Watermark (FPS & Ping)
local lastUpdate = tick()
local frames = 0
table.insert(Connections, RunService.RenderStepped:Connect(function()
    frames = frames + 1
    local now = tick()
    if now - lastUpdate >= 1 then
        local fps = math.floor(frames / (now - lastUpdate))
        local ping = 0 -- In a real exploit, you'd get real ping depending on the executor environment
        WatermarkText.Text = string.format("PL | PastaLand | FPS: %d | Ping: %dms", fps, ping)
        frames = 0
        lastUpdate = now
    end
end))

-- ==========================================
-- WATERMARK DRAG LOGIC
-- ==========================================

local wmDragging
local wmDragInput
local wmDragStart
local wmStartPos

Watermark.Active = true

table.insert(Connections, Watermark.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        wmDragging = true
        wmDragStart = input.Position
        wmStartPos = Watermark.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                wmDragging = false
            end
        end)
    end
end))

table.insert(Connections, Watermark.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        wmDragInput = input
    end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == wmDragInput and wmDragging then
        local delta = input.Position - wmDragStart
        Watermark.Position = UDim2.new(wmStartPos.X.Scale, wmStartPos.X.Offset + delta.X, wmStartPos.Y.Scale, wmStartPos.Y.Offset + delta.Y)
    end
end))

-- ==========================================
-- MAIN MENU (Gamesense Style)
-- ==========================================

local Menu = Instance.new("Frame")
Menu.Name = "MainMenu"
Menu.Size = UDim2.new(0, 500, 0, 350)
Menu.Position = UDim2.new(0.5, -250, 0.5, -175)
Menu.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Menu.BorderColor3 = Color3.fromRGB(40, 40, 40)
Menu.BorderSizePixel = 2 -- Double outline effect simulated
Menu.Parent = PastaLandGui
Menu.Visible = false -- Hidden by default

-- Top Bar (Draggable)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 20)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TopBar.BorderSizePixel = 0
TopBar.Parent = Menu

local TopBarAccent = Instance.new("Frame")
TopBarAccent.Size = UDim2.new(1, 0, 0, 2)
TopBarAccent.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
TopBarAccent.BorderSizePixel = 0
TopBarAccent.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, -2)
Title.Position = UDim2.new(0, 5, 0, 2)
Title.BackgroundTransparency = 1
Title.Text = "PastaLand"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.Code
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Dragging Logic
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
    local delta = input.Position - dragStart
    Menu.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

table.insert(Connections, TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Menu.Position

        table.insert(Connections, input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end))
    end
end))

table.insert(Connections, TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end))

-- Main Container (Tabs & Content)
local MainContainer = Instance.new("Frame")
MainContainer.Size = UDim2.new(1, -10, 1, -30)
MainContainer.Position = UDim2.new(0, 5, 0, 25)
MainContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainContainer.BorderColor3 = Color3.fromRGB(40, 40, 40)
MainContainer.BorderSizePixel = 1
MainContainer.Parent = Menu

-- Tabs Container
local TabsContainer = Instance.new("Frame")
TabsContainer.Size = UDim2.new(0, 100, 1, 0)
TabsContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
TabsContainer.BorderColor3 = Color3.fromRGB(40, 40, 40)
TabsContainer.BorderSizePixel = 1
TabsContainer.Parent = MainContainer

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -100, 1, 0)
ContentContainer.Position = UDim2.new(0, 100, 0, 0)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainContainer

-- State
local tabs = {"Legit", "Rage", "Visuals", "Misc", "Skins", "Settings"}
local activeTab = "Visuals"
local tabButtons = {}
local tabContents = {}

-- Create a generic "Coming Soon" page
local function createComingSoon(parent)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Coming Soon..."
    label.TextColor3 = Color3.fromRGB(100, 100, 100)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.Parent = parent
    return label
end

-- Create Pages
for i, tabName in ipairs(tabs) do
    -- Tab Button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 25)
    btn.Position = UDim2.new(0, 5, 0, (i-1) * 30 + 5) -- proper spacing
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.BorderColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 1
    btn.Text = tabName
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.Code
    btn.TextSize = 12
    btn.Parent = TabsContainer
    tabButtons[tabName] = btn
    
    ApplyButtonHover(btn, Color3.fromRGB(20, 20, 20), Color3.fromRGB(35, 35, 35))

    -- Tab Content Frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = ContentContainer
    tabContents[tabName] = contentFrame

    if tabName == "Settings" then
        local UnloadBtn = Instance.new("TextButton")
        UnloadBtn.Size = UDim2.new(0, 120, 0, 25)
        UnloadBtn.Position = UDim2.new(0.5, -60, 0.5, -12)
        UnloadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        UnloadBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
        UnloadBtn.BorderSizePixel = 1
        UnloadBtn.Text = "Unload PastaLand"
        UnloadBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
        UnloadBtn.Font = Enum.Font.Code
        UnloadBtn.TextSize = 12
        UnloadBtn.Parent = contentFrame
        
        ApplyButtonHover(UnloadBtn, Color3.fromRGB(30, 30, 30), Color3.fromRGB(50, 35, 35))

        table.insert(Connections, UnloadBtn.MouseButton1Click:Connect(function()
            for _, conn in ipairs(Connections) do
                if conn.Connected then
                    conn:Disconnect()
                end
            end
            
            -- Revert changes to users mouse state upon unload
            UserInputService.MouseIconEnabled = true
            for _, h in pairs(espHighlights) do
                pcall(function() h:Destroy() end)
            end
            
            PastaLandGui:Destroy()
            print("PastaLand Unloaded Successfully")
        end))
    elseif tabName ~= "Visuals" and tabName ~= "Rage" and tabName ~= "Legit" and tabName ~= "Misc" then
        createComingSoon(contentFrame)
    end
end

-- ==========================================
-- RAGE PAGE SETUP (Anti-Aim)
-- ==========================================
local ragePage = tabContents["Rage"]

local AAGroup = Instance.new("Frame")
AAGroup.Size = UDim2.new(0.5, -15, 1, -20)
AAGroup.Position = UDim2.new(0, 10, 0, 10)
AAGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
AAGroup.BorderColor3 = Color3.fromRGB(40, 40, 40)
AAGroup.BorderSizePixel = 1
AAGroup.Parent = ragePage

local AAGroupTitleBG = Instance.new("Frame")
AAGroupTitleBG.Size = UDim2.new(1, 0, 0, 15)
AAGroupTitleBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AAGroupTitleBG.BorderSizePixel = 0
AAGroupTitleBG.Parent = AAGroup

local AAGroupTitle = Instance.new("TextLabel")
AAGroupTitle.Size = UDim2.new(1, 0, 1, 0)
AAGroupTitle.BackgroundTransparency = 1
AAGroupTitle.Text = " Anti-Aim"
AAGroupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
AAGroupTitle.Font = Enum.Font.Code
AAGroupTitle.TextSize = 12
AAGroupTitle.TextXAlignment = Enum.TextXAlignment.Left
AAGroupTitle.Parent = AAGroupTitleBG

-- AA Toggle Feature
local AAToggleEnabled = false

local AAToggleHitbox = Instance.new("TextButton")
AAToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
AAToggleHitbox.Position = UDim2.new(0, 10, 0, 25)
AAToggleHitbox.BackgroundTransparency = 1
AAToggleHitbox.Text = ""
AAToggleHitbox.Parent = AAGroup

local AAToggleCircle = Instance.new("Frame")
AAToggleCircle.Size = UDim2.new(0, 8, 0, 8)
AAToggleCircle.Position = UDim2.new(0, 0, 0.5, -4)
AAToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Off by default
AAToggleCircle.BorderSizePixel = 0
AAToggleCircle.Parent = AAToggleHitbox

local AACircleCorner = Instance.new("UICorner")
AACircleCorner.CornerRadius = UDim.new(1, 0)
AACircleCorner.Parent = AAToggleCircle

local AAToggleLabel = Instance.new("TextLabel")
AAToggleLabel.Size = UDim2.new(1, -16, 1, 0)
AAToggleLabel.Position = UDim2.new(0, 16, 0, 0)
AAToggleLabel.BackgroundTransparency = 1
AAToggleLabel.Text = "Anti-Aim"
AAToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AAToggleLabel.Font = Enum.Font.Code
AAToggleLabel.TextSize = 12
AAToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
AAToggleLabel.Parent = AAToggleHitbox

table.insert(Connections, AAToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(AAToggleLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end))
table.insert(Connections, AAToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(AAToggleLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end))

table.insert(Connections, AAToggleHitbox.MouseButton1Click:Connect(function()
    AAToggleEnabled = not AAToggleEnabled
    if AAToggleEnabled then
        TweenService:Create(AAToggleCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 180, 0)}):Play()
    else
        TweenService:Create(AAToggleCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end
end))

-- Yaw Selector
local pitchModes = {"None"} -- Pitch removed for Flick
local pitchIndex = 1
local yawModes = {"None", "Backward", "Spin", "Jitter"}
local yawIndex = 1

local YawBtn = Instance.new("TextButton")
YawBtn.Size = UDim2.new(1, -20, 0, 20)
YawBtn.Position = UDim2.new(0, 10, 0, 50)
YawBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
YawBtn.BorderColor3 = Color3.fromRGB(40, 40, 40)
YawBtn.BorderSizePixel = 1
YawBtn.Text = "Yaw: " .. yawModes[yawIndex]
YawBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
YawBtn.Font = Enum.Font.Code
YawBtn.TextSize = 12
YawBtn.Parent = AAGroup
ApplyButtonHover(YawBtn, Color3.fromRGB(20, 20, 20), Color3.fromRGB(35, 35, 35))

-- Contextual Slider (Spin Speed / Jitter Angle) — defined BEFORE YawBtn click so forward ref works
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -20, 0, 15)
SpeedLabel.Position = UDim2.new(0, 10, 0, 80)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Spin Speed"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.Font = Enum.Font.Code
SpeedLabel.TextSize = 12
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Visible = false -- hidden until a mode with slider is selected
SpeedLabel.Parent = AAGroup

local SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Size = UDim2.new(0, 30, 0, 15)
SpeedValueLabel.Position = UDim2.new(1, -40, 0, 80)
SpeedValueLabel.BackgroundTransparency = 1
SpeedValueLabel.Text = "50"
SpeedValueLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
SpeedValueLabel.Font = Enum.Font.Code
SpeedValueLabel.TextSize = 12
SpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Right
SpeedValueLabel.Visible = false
SpeedValueLabel.Parent = AAGroup

local SliderBG = Instance.new("TextButton")
SliderBG.Size = UDim2.new(1, -20, 0, 6)
SliderBG.Position = UDim2.new(0, 10, 0, 95)
SliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SliderBG.BorderColor3 = Color3.fromRGB(40, 40, 40)
SliderBG.BorderSizePixel = 1
SliderBG.Text = ""
SliderBG.AutoButtonColor = false
SliderBG.Visible = false
SliderBG.Parent = AAGroup

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.5, 0, 1, 0) -- starts at 50%
SliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBG

local draggingSlider = false
local currentSpd = 50

local function updateYawSliderVisibility()
    local mode = yawModes[yawIndex]
    if mode == "Spin" then
        SpeedLabel.Text = "Spin Speed"
        SpeedLabel.Visible = true
        SpeedValueLabel.Visible = true
        SliderBG.Visible = true
    elseif mode == "Jitter" then
        SpeedLabel.Text = "Jitter Angle"
        SpeedLabel.Visible = true
        SpeedValueLabel.Visible = true
        SliderBG.Visible = true
    else
        SpeedLabel.Visible = false
        SpeedValueLabel.Visible = false
        SliderBG.Visible = false
    end
end
updateYawSliderVisibility() -- set initial state

-- Now hook up YawBtn click (function is defined above, no forward-reference issue)
table.insert(Connections, YawBtn.MouseButton1Click:Connect(function()
    yawIndex = yawIndex + 1
    if yawIndex > #yawModes then yawIndex = 1 end
    YawBtn.Text = "Yaw: " .. yawModes[yawIndex]
    updateYawSliderVisibility()
end))

local function updateSlider(input)
    local relX = math.clamp((input.Position.X - SliderBG.AbsolutePosition.X) / SliderBG.AbsoluteSize.X, 0, 1)
    SliderFill.Size = UDim2.new(relX, 0, 1, 0)
    currentSpd = math.floor(relX * 100) -- min 0, max 100
    SpeedValueLabel.Text = tostring(currentSpd)
end

table.insert(Connections, SliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = true
        updateSlider(input)
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingSlider = false
    end
end))

table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSlider(input)
    end
end))

-- ==========================================
-- SILENT AIM GROUPBOX (Rage tab, right column)
-- ==========================================
local SAGroup = Instance.new("Frame")
SAGroup.Size = UDim2.new(0.5, -15, 1, -20)
SAGroup.Position = UDim2.new(0.5, 5, 0, 10)
SAGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
SAGroup.BorderColor3 = Color3.fromRGB(40, 40, 40)
SAGroup.BorderSizePixel = 1
SAGroup.Parent = ragePage

local SAGroupTitleBG = Instance.new("Frame")
SAGroupTitleBG.Size = UDim2.new(1, 0, 0, 15)
SAGroupTitleBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SAGroupTitleBG.BorderSizePixel = 0
SAGroupTitleBG.Parent = SAGroup

local SAGroupTitle = Instance.new("TextLabel")
SAGroupTitle.Size = UDim2.new(1, 0, 1, 0)
SAGroupTitle.BackgroundTransparency = 1
SAGroupTitle.Text = " Silent Aim"
SAGroupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
SAGroupTitle.Font = Enum.Font.Code
SAGroupTitle.TextSize = 12
SAGroupTitle.TextXAlignment = Enum.TextXAlignment.Left
SAGroupTitle.Parent = SAGroupTitleBG

-- Silent Aim Toggle
local SilentEnabled = false

local SAToggleHitbox = Instance.new("TextButton")
SAToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
SAToggleHitbox.Position = UDim2.new(0, 10, 0, 25)
SAToggleHitbox.BackgroundTransparency = 1
SAToggleHitbox.Text = ""
SAToggleHitbox.Parent = SAGroup

local SACircle = Instance.new("Frame")
SACircle.Size = UDim2.new(0, 8, 0, 8)
SACircle.Position = UDim2.new(0, 0, 0.5, -4)
SACircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
SACircle.BorderSizePixel = 0
SACircle.Parent = SAToggleHitbox
Instance.new("UICorner", SACircle).CornerRadius = UDim.new(1, 0)

local SALabel = Instance.new("TextLabel")
SALabel.Size = UDim2.new(1, -16, 1, 0)
SALabel.Position = UDim2.new(0, 16, 0, 0)
SALabel.BackgroundTransparency = 1
SALabel.Text = "Silent Aim"
SALabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SALabel.Font = Enum.Font.Code
SALabel.TextSize = 12
SALabel.TextXAlignment = Enum.TextXAlignment.Left
SALabel.Parent = SAToggleHitbox

table.insert(Connections, SAToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(SALabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, SAToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(SALabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, SAToggleHitbox.MouseButton1Click:Connect(function()
    SilentEnabled = not SilentEnabled
    TweenService:Create(SACircle, TweenInfo.new(0.2), {BackgroundColor3 = SilentEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- FOV Slider (0-300px; base 180 degree hemisphere always applies on top)
local SilentFov = 150

local SAFovLabel = Instance.new("TextLabel")
SAFovLabel.Size = UDim2.new(1, -20, 0, 15)
SAFovLabel.Position = UDim2.new(0, 10, 0, 50)
SAFovLabel.BackgroundTransparency = 1
SAFovLabel.Text = "FOV"
SAFovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SAFovLabel.Font = Enum.Font.Code
SAFovLabel.TextSize = 12
SAFovLabel.TextXAlignment = Enum.TextXAlignment.Left
SAFovLabel.Parent = SAGroup

local SAFovValueLabel = Instance.new("TextLabel")
SAFovValueLabel.Size = UDim2.new(0, 35, 0, 15)
SAFovValueLabel.Position = UDim2.new(1, -45, 0, 50)
SAFovValueLabel.BackgroundTransparency = 1
SAFovValueLabel.Text = tostring(SilentFov)
SAFovValueLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
SAFovValueLabel.Font = Enum.Font.Code
SAFovValueLabel.TextSize = 12
SAFovValueLabel.TextXAlignment = Enum.TextXAlignment.Right
SAFovValueLabel.Parent = SAGroup

local SAFovSliderBG = Instance.new("TextButton")
SAFovSliderBG.Size = UDim2.new(1, -20, 0, 6)
SAFovSliderBG.Position = UDim2.new(0, 10, 0, 65)
SAFovSliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SAFovSliderBG.BorderColor3 = Color3.fromRGB(40, 40, 40)
SAFovSliderBG.BorderSizePixel = 1
SAFovSliderBG.Text = ""
SAFovSliderBG.AutoButtonColor = false
SAFovSliderBG.Parent = SAGroup

local SAFovSliderFill = Instance.new("Frame")
SAFovSliderFill.Size = UDim2.new(0.5, 0, 1, 0)
SAFovSliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
SAFovSliderFill.BorderSizePixel = 0
SAFovSliderFill.Parent = SAFovSliderBG

local saFovDragging = false
local function updateSAFovSlider(input)
    local relX = math.clamp((input.Position.X - SAFovSliderBG.AbsolutePosition.X) / SAFovSliderBG.AbsoluteSize.X, 0, 1)
    SilentFov = math.floor(relX * 300)
    SAFovSliderFill.Size = UDim2.new(relX, 0, 1, 0)
    SAFovValueLabel.Text = tostring(SilentFov)
end
table.insert(Connections, SAFovSliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        saFovDragging = true
        updateSAFovSlider(input)
    end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        saFovDragging = false
    end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if saFovDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSAFovSlider(input)
    end
end))

-- Auto Fire Toggle
local AutoFireEnabled = false

local AFToggleHitbox = Instance.new("TextButton")
AFToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
AFToggleHitbox.Position = UDim2.new(0, 10, 0, 82)
AFToggleHitbox.BackgroundTransparency = 1
AFToggleHitbox.Text = ""
AFToggleHitbox.Parent = SAGroup

local AFCircle = Instance.new("Frame")
AFCircle.Size = UDim2.new(0, 8, 0, 8)
AFCircle.Position = UDim2.new(0, 0, 0.5, -4)
AFCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
AFCircle.BorderSizePixel = 0
AFCircle.Parent = AFToggleHitbox
Instance.new("UICorner", AFCircle).CornerRadius = UDim.new(1, 0)

local AFLabel = Instance.new("TextLabel")
AFLabel.Size = UDim2.new(1, -16, 1, 0)
AFLabel.Position = UDim2.new(0, 16, 0, 0)
AFLabel.BackgroundTransparency = 1
AFLabel.Text = "Auto Fire"
AFLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AFLabel.Font = Enum.Font.Code
AFLabel.TextSize = 12
AFLabel.TextXAlignment = Enum.TextXAlignment.Left
AFLabel.Parent = AFToggleHitbox

table.insert(Connections, AFToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(AFLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, AFToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(AFLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, AFToggleHitbox.MouseButton1Click:Connect(function()
    AutoFireEnabled = not AutoFireEnabled
    TweenService:Create(AFCircle, TweenInfo.new(0.2), {BackgroundColor3 = AutoFireEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- ==========================================
-- VISUALS PAGE SETUP
-- ==========================================
local visualsPage = tabContents["Visuals"]

-- Groupbox
local MainVisualsGroup = Instance.new("Frame")
MainVisualsGroup.Size = UDim2.new(0.5, -15, 1, -20)
MainVisualsGroup.Position = UDim2.new(0, 10, 0, 10)
MainVisualsGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainVisualsGroup.BorderColor3 = Color3.fromRGB(40, 40, 40)
MainVisualsGroup.BorderSizePixel = 1
MainVisualsGroup.Parent = visualsPage

local GroupTitleBG = Instance.new("Frame")
GroupTitleBG.Size = UDim2.new(1, 0, 0, 15)
GroupTitleBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
GroupTitleBG.BorderSizePixel = 0
GroupTitleBG.Parent = MainVisualsGroup

local GroupTitle = Instance.new("TextLabel")
GroupTitle.Size = UDim2.new(1, 0, 1, 0)
GroupTitle.BackgroundTransparency = 1
GroupTitle.Text = " Main Visuals"
GroupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
GroupTitle.Font = Enum.Font.Code
GroupTitle.TextSize = 12
GroupTitle.TextXAlignment = Enum.TextXAlignment.Left
GroupTitle.Parent = GroupTitleBG

-- Toggle (Enable HUD)
local ToggleEnabled = true

local ToggleHitbox = Instance.new("TextButton")
ToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
ToggleHitbox.Position = UDim2.new(0, 10, 0, 25)
ToggleHitbox.BackgroundTransparency = 1
ToggleHitbox.Text = ""
ToggleHitbox.Parent = MainVisualsGroup

local ToggleCircle = Instance.new("Frame")
ToggleCircle.Size = UDim2.new(0, 8, 0, 8)
ToggleCircle.Position = UDim2.new(0, 0, 0.5, -4)
ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- On (GUI Color)
ToggleCircle.BorderSizePixel = 0
ToggleCircle.Parent = ToggleHitbox

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = ToggleCircle

local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.Size = UDim2.new(1, -16, 1, 0)
ToggleLabel.Position = UDim2.new(0, 16, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "HUD"
ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ToggleLabel.Font = Enum.Font.Code
ToggleLabel.TextSize = 12
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.Parent = ToggleHitbox

-- Hover effects for the text
table.insert(Connections, ToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(ToggleLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end))
table.insert(Connections, ToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(ToggleLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
end))

table.insert(Connections, ToggleHitbox.MouseButton1Click:Connect(function()
    ToggleEnabled = not ToggleEnabled
    if ToggleEnabled then
        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 180, 0)}):Play()
        HUD.Visible = true
    else
        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
        HUD.Visible = false
    end
end))

-- Toggle: Player ESP (Chams)
local ESPEnabled = false

local ESPHitbox = Instance.new("TextButton")
ESPHitbox.Size = UDim2.new(1, -20, 0, 16)
ESPHitbox.Position = UDim2.new(0, 10, 0, 50)
ESPHitbox.BackgroundTransparency = 1
ESPHitbox.Text = ""
ESPHitbox.Parent = MainVisualsGroup

local ESPCircle = Instance.new("Frame")
ESPCircle.Size = UDim2.new(0, 8, 0, 8)
ESPCircle.Position = UDim2.new(0, 0, 0.5, -4)
ESPCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
ESPCircle.BorderSizePixel = 0
ESPCircle.Parent = ESPHitbox
Instance.new("UICorner", ESPCircle).CornerRadius = UDim.new(1, 0)

local ESPLabel = Instance.new("TextLabel")
ESPLabel.Size = UDim2.new(1, -16, 1, 0)
ESPLabel.Position = UDim2.new(0, 16, 0, 0)
ESPLabel.BackgroundTransparency = 1
ESPLabel.Text = "Player ESP"
ESPLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ESPLabel.Font = Enum.Font.Code
ESPLabel.TextSize = 12
ESPLabel.TextXAlignment = Enum.TextXAlignment.Left
ESPLabel.Parent = ESPHitbox

table.insert(Connections, ESPHitbox.MouseEnter:Connect(function()
    TweenService:Create(ESPLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, ESPHitbox.MouseLeave:Connect(function()
    TweenService:Create(ESPLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))

table.insert(Connections, ESPHitbox.MouseButton1Click:Connect(function()
    ESPEnabled = not ESPEnabled
    if ESPEnabled then
        TweenService:Create(ESPCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 180, 0)}):Play()
    else
        TweenService:Create(ESPCircle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 50, 50)}):Play()
    end
    for _, h in pairs(espHighlights) do
        h.Enabled = ESPEnabled
    end
end))

-- Switch Tab Logic
local function SwitchTab(name)
    for tName, frame in pairs(tabContents) do
        frame.Visible = (tName == name)
        if tName == name then
            tabButtons[tName].TextColor3 = Color3.fromRGB(255, 180, 0)
        else
            tabButtons[tName].TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

for tName, btn in pairs(tabButtons) do
    table.insert(Connections, btn.MouseButton1Click:Connect(function()
        SwitchTab(tName)
    end))
end

-- Initialize with Visuals tab
SwitchTab("Visuals")

-- ==========================================
-- MENU TOGGLE LOGIC
-- ==========================================

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        menuOpen = not menuOpen
        if menuOpen then
            UserInputService.MouseIconEnabled = false
            CustomCursor.Visible = true
            Menu.Visible = true
        else
            UserInputService.MouseIconEnabled = true
            CustomCursor.Visible = false
            Menu.Visible = false
        end
    end
end))

-- ==========================================
-- ESP (PLAYER CHAMS) LOGIC
-- Uses Roblox Highlight instance: orange outline + semi-transparent fill.
-- Works through walls. Respects toggle. Cleans up on player leave and unload.
-- ==========================================

local espHighlights = {} -- [Player] = Highlight
local espCharConns  = {} -- [Player] = CharacterAdded connection

local function createHighlight(char)
    local h = Instance.new("Highlight")
    h.FillColor           = Color3.fromRGB(255, 180, 0)
    h.FillTransparency    = 0.75  -- semi-transparent fill
    h.OutlineColor        = Color3.fromRGB(255, 180, 0)
    h.OutlineTransparency = 0     -- solid outline
    h.Adornee             = char
    h.Enabled             = ESPEnabled
    h.Parent              = char
    return h
end

local function addPlayerESP(player)
    if player == LocalPlayer then return end

    local function applyToChar(char)
        -- Remove old highlight if exists
        if espHighlights[player] then
            pcall(function() espHighlights[player]:Destroy() end)
            espHighlights[player] = nil
        end
        task.wait(0.1) -- wait for parts to load
        if char and char.Parent then
            espHighlights[player] = createHighlight(char)
        end
    end

    if player.Character then
        applyToChar(player.Character)
    end

    -- Re-apply when character respawns
    espCharConns[player] = player.CharacterAdded:Connect(function(char)
        applyToChar(char)
    end)
end

local function removePlayerESP(player)
    if espHighlights[player] then
        pcall(function() espHighlights[player]:Destroy() end)
        espHighlights[player] = nil
    end
    if espCharConns[player] then
        espCharConns[player]:Disconnect()
        espCharConns[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayerESP(p) end
table.insert(Connections, Players.PlayerAdded:Connect(addPlayerESP))
table.insert(Connections, Players.PlayerRemoving:Connect(removePlayerESP))

-- ==========================================
-- ANTI-AIM
-- Technique: Heartbeat → apply fake HRP.CFrame yaw + neck pitch (server sees this).
--            RenderStepped → restore HRP + neck to real state before rendering (silent).
-- Yaw uses ABSOLUTE world-space angle derived from camera so Backward/Jitter actually face away.
-- ==========================================

local aaSpinAngle = 0
local aaNeckC0     = nil
local aaWaistC0    = nil
local aaRestoredHRPCF = nil -- last known real HRP CFrame

local function aaGetCamYaw()
    local lv = workspace.CurrentCamera.CFrame.LookVector
    return math.atan2(-lv.X, -lv.Z) -- world-space yaw radians the camera faces
end

local function aaGetNeck(char)
    if char:FindFirstChild("UpperTorso") then -- R15
        return char.Head and char.Head:FindFirstChild("Neck"),
               char.UpperTorso and char.UpperTorso:FindFirstChild("Waist")
    else -- R6
        return char.Torso and char.Torso:FindFirstChild("Neck"), nil
    end
end

-- Reset caches when character respawns
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    aaNeckC0 = nil
    aaWaistC0 = nil
    aaSpinAngle = 0
    aaRestoredHRPCF = nil
end))

-- HEARTBEAT: write fake state → Roblox replicates to server after this step
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    if not AAToggleEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end

    hum.AutoRotate = false

    -- Cache neck/waist originals once
    local neck, waist = aaGetNeck(char)
    if neck  and not aaNeckC0  then aaNeckC0  = neck.C0  end
    if waist and not aaWaistC0 then aaWaistC0 = waist.C0 end

    -- YAW via HumanoidRootPart.CFrame (absolute world-space rotation)
    local yMode = yawModes[yawIndex]
    if yMode ~= "None" then
        local camYaw = aaGetCamYaw()
        local fakeYaw

        if yMode == "Backward" then
            -- Exactly opposite to camera direction
            fakeYaw = camYaw + math.pi

        elseif yMode == "Spin" then
            -- currentSpd 0‑100 → 0‑5000 deg/s
            aaSpinAngle = (aaSpinAngle + math.rad(currentSpd * 50) * dt) % (2 * math.pi)
            fakeYaw = aaSpinAngle

        elseif yMode == "Jitter" then
            -- Jitter angle (currentSpd 0‑100 → 0‑180°) around the 180° baseline
            local jRad = math.rad(currentSpd * 1.8)
            fakeYaw = camYaw + math.pi + (tick() % 0.05 < 0.025 and jRad or -jRad)
        end

        -- Apply: keep real position, only change yaw
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, fakeYaw, 0)
    end
end))

-- RENDERSTEPPED: restore everything before frame is drawn (we never see our own AA)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if not AAToggleEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end

    -- Restore HRP to face camera direction so movement feels normal
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp and yawModes[yawIndex] ~= "None" then
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, aaGetCamYaw(), 0)
    end
end))

-- ==========================================
-- SHARED WALL-CHECK UTILITY (used by Silent Aim + Aim Assist)
-- ==========================================

local function isVisible(from, target)
    local dir = (target - from)
    local ray = RaycastParams.new()
    ray.FilterDescendantsInstances = {LocalPlayer.Character}
    ray.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(from, dir, ray)
    if result then
        local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
        if hitChar then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == hitChar then return true end
            end
        end
        return false
    end
    return true
end

-- ==========================================
-- SILENT AIM LOGIC
-- On LMB press: camera rotates to face nearest target in FOV.
-- The game sees the camera already pointing at the target → shot lands.
-- Auto Fire: aim + auto click when target in FOV.
-- ==========================================

local silentOrigCF = nil
local silentFireCooldown = 0
local silentPlayerCooldowns = {} -- [Player] = tick() when cooldown expires

local function getBestTargetSilent()
    local cam = workspace.CurrentCamera
    local mouseLoc = UserInputService:GetMouseLocation()
    local mouseVec = Vector2.new(mouseLoc.X, mouseLoc.Y)
    local bestPart = nil
    local bestPlayer = nil
    local bestDist = math.huge
    local now = tick()

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        -- Skip players still on per-player cooldown
        if silentPlayerCooldowns[p] and now < silentPlayerCooldowns[p] then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end

        local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local screenVec = Vector2.new(screenPos.X, screenPos.Y)
        local dist = (screenVec - mouseVec).Magnitude
        if SilentFov > 0 and dist > SilentFov then continue end

        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if not isVisible(hrp.Position, head.Position) then continue end

        if dist < bestDist then
            bestDist = dist
            bestPart = head
            bestPlayer = p
        end
    end
    return bestPart, bestPlayer
end

-- On LMB press: snap camera to target → game fires the shot → restore after short delay
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not SilentEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local targetPart, targetPlayer = getBestTargetSilent()
    if not targetPart then return end
    if targetPlayer then
        silentPlayerCooldowns[targetPlayer] = tick() + 1
    end
    local cam = workspace.CurrentCamera
    local origCF = cam.CFrame
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
    task.delay(0.08, function()
        cam.CFrame = origCF
    end)
end))

-- Auto Fire: snap → click → release + restore
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    if not SilentEnabled or not AutoFireEnabled then return end
    silentFireCooldown = silentFireCooldown - dt
    if silentFireCooldown > 0 then return end
    local targetPart, targetPlayer = getBestTargetSilent()
    if not targetPart then return end
    if targetPlayer then
        silentPlayerCooldowns[targetPlayer] = tick() + 1
    end
    local cam = workspace.CurrentCamera
    local origCF = cam.CFrame
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
    silentFireCooldown = 0.15
    pcall(function() mouse1press() end)
    task.delay(0.05, function()
        pcall(function() mouse1release() end)
        cam.CFrame = origCF
    end)
end))

-- ==========================================
-- LEGIT PAGE SETUP (Aim Assist)
-- ==========================================
local legitPage = tabContents["Legit"]

local AAimGroup = Instance.new("Frame")
AAimGroup.Size = UDim2.new(0.5, -15, 1, -20)
AAimGroup.Position = UDim2.new(0, 10, 0, 10)
AAimGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
AAimGroup.BorderColor3 = Color3.fromRGB(40, 40, 40)
AAimGroup.BorderSizePixel = 1
AAimGroup.Parent = legitPage

local AAimTitleBG = Instance.new("Frame")
AAimTitleBG.Size = UDim2.new(1, 0, 0, 15)
AAimTitleBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
AAimTitleBG.BorderSizePixel = 0
AAimTitleBG.Parent = AAimGroup

local AAimTitle = Instance.new("TextLabel")
AAimTitle.Size = UDim2.new(1, 0, 1, 0)
AAimTitle.BackgroundTransparency = 1
AAimTitle.Text = " Aim Assist"
AAimTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
AAimTitle.Font = Enum.Font.Code
AAimTitle.TextSize = 12
AAimTitle.TextXAlignment = Enum.TextXAlignment.Left
AAimTitle.Parent = AAimTitleBG

-- Toggle
local AimEnabled = false

local AimToggleHitbox = Instance.new("TextButton")
AimToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
AimToggleHitbox.Position = UDim2.new(0, 10, 0, 25)
AimToggleHitbox.BackgroundTransparency = 1
AimToggleHitbox.Text = ""
AimToggleHitbox.Parent = AAimGroup

local AimCircle = Instance.new("Frame")
AimCircle.Size = UDim2.new(0, 8, 0, 8)
AimCircle.Position = UDim2.new(0, 0, 0.5, -4)
AimCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
AimCircle.BorderSizePixel = 0
AimCircle.Parent = AimToggleHitbox
Instance.new("UICorner", AimCircle).CornerRadius = UDim.new(1, 0)

local AimLabel = Instance.new("TextLabel")
AimLabel.Size = UDim2.new(1, -16, 1, 0)
AimLabel.Position = UDim2.new(0, 16, 0, 0)
AimLabel.BackgroundTransparency = 1
AimLabel.Text = "Aim Assist"
AimLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
AimLabel.Font = Enum.Font.Code
AimLabel.TextSize = 12
AimLabel.TextXAlignment = Enum.TextXAlignment.Left
AimLabel.Parent = AimToggleHitbox

table.insert(Connections, AimToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(AimLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, AimToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(AimLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, AimToggleHitbox.MouseButton1Click:Connect(function()
    AimEnabled = not AimEnabled
    TweenService:Create(AimCircle, TweenInfo.new(0.2), {BackgroundColor3 = AimEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- FOV Slider
local AimFov = 120 -- pixels radius

local FovLabel = Instance.new("TextLabel")
FovLabel.Size = UDim2.new(1, -20, 0, 15)
FovLabel.Position = UDim2.new(0, 10, 0, 50)
FovLabel.BackgroundTransparency = 1
FovLabel.Text = "FOV"
FovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FovLabel.Font = Enum.Font.Code
FovLabel.TextSize = 12
FovLabel.TextXAlignment = Enum.TextXAlignment.Left
FovLabel.Parent = AAimGroup

local FovValueLabel = Instance.new("TextLabel")
FovValueLabel.Size = UDim2.new(0, 35, 0, 15)
FovValueLabel.Position = UDim2.new(1, -45, 0, 50)
FovValueLabel.BackgroundTransparency = 1
FovValueLabel.Text = tostring(AimFov)
FovValueLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
FovValueLabel.Font = Enum.Font.Code
FovValueLabel.TextSize = 12
FovValueLabel.TextXAlignment = Enum.TextXAlignment.Right
FovValueLabel.Parent = AAimGroup

local FovSliderBG = Instance.new("TextButton")
FovSliderBG.Size = UDim2.new(1, -20, 0, 6)
FovSliderBG.Position = UDim2.new(0, 10, 0, 65)
FovSliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
FovSliderBG.BorderColor3 = Color3.fromRGB(40, 40, 40)
FovSliderBG.BorderSizePixel = 1
FovSliderBG.Text = ""
FovSliderBG.AutoButtonColor = false
FovSliderBG.Parent = AAimGroup

local FovSliderFill = Instance.new("Frame")
FovSliderFill.Size = UDim2.new(AimFov/300, 0, 1, 0)
FovSliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
FovSliderFill.BorderSizePixel = 0
FovSliderFill.Parent = FovSliderBG

local fovDragging = false
local function updateFovSlider(input)
    local relX = math.clamp((input.Position.X - FovSliderBG.AbsolutePosition.X) / FovSliderBG.AbsoluteSize.X, 0, 1)
    AimFov = math.floor(relX * 300) -- 0–300px
    FovSliderFill.Size = UDim2.new(relX, 0, 1, 0)
    FovValueLabel.Text = tostring(AimFov)
end
table.insert(Connections, FovSliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fovDragging = true
        updateFovSlider(input)
    end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        fovDragging = false
    end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if fovDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateFovSlider(input)
    end
end))

-- Speed Slider
local AimSpeed = 0.15 -- 0.05 (slow) to 1.0 (instant)

local SpdLabel = Instance.new("TextLabel")
SpdLabel.Size = UDim2.new(1, -20, 0, 15)
SpdLabel.Position = UDim2.new(0, 10, 0, 82)
SpdLabel.BackgroundTransparency = 1
SpdLabel.Text = "Speed"
SpdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpdLabel.Font = Enum.Font.Code
SpdLabel.TextSize = 12
SpdLabel.TextXAlignment = Enum.TextXAlignment.Left
SpdLabel.Parent = AAimGroup

local SpdValueLabel = Instance.new("TextLabel")
SpdValueLabel.Size = UDim2.new(0, 35, 0, 15)
SpdValueLabel.Position = UDim2.new(1, -45, 0, 82)
SpdValueLabel.BackgroundTransparency = 1
SpdValueLabel.Text = "15"
SpdValueLabel.TextColor3 = Color3.fromRGB(255, 180, 0)
SpdValueLabel.Font = Enum.Font.Code
SpdValueLabel.TextSize = 12
SpdValueLabel.TextXAlignment = Enum.TextXAlignment.Right
SpdValueLabel.Parent = AAimGroup

local SpdSliderBG = Instance.new("TextButton")
SpdSliderBG.Size = UDim2.new(1, -20, 0, 6)
SpdSliderBG.Position = UDim2.new(0, 10, 0, 97)
SpdSliderBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SpdSliderBG.BorderColor3 = Color3.fromRGB(40, 40, 40)
SpdSliderBG.BorderSizePixel = 1
SpdSliderBG.Text = ""
SpdSliderBG.AutoButtonColor = false
SpdSliderBG.Parent = AAimGroup

local SpdSliderFill = Instance.new("Frame")
SpdSliderFill.Size = UDim2.new(0.15, 0, 1, 0)
SpdSliderFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
SpdSliderFill.BorderSizePixel = 0
SpdSliderFill.Parent = SpdSliderBG

local spdDragging = false
local function updateSpdSlider(input)
    local relX = math.clamp((input.Position.X - SpdSliderBG.AbsolutePosition.X) / SpdSliderBG.AbsoluteSize.X, 0, 1)
    AimSpeed = math.max(0.01, relX) -- keep min at 0.01 so it always moves
    SpdSliderFill.Size = UDim2.new(relX, 0, 1, 0)
    SpdValueLabel.Text = tostring(math.floor(relX * 100))
end
table.insert(Connections, SpdSliderBG.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        spdDragging = true
        updateSpdSlider(input)
    end
end))
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        spdDragging = false
    end
end))
table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
    if spdDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSpdSlider(input)
    end
end))

-- Multi-Points Toggle (aim / triggerbot hit any body part, not just head)
local MultiPointsEnabled = false

local MPToggleHitbox = Instance.new("TextButton")
MPToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
MPToggleHitbox.Position = UDim2.new(0, 10, 0, 115)
MPToggleHitbox.BackgroundTransparency = 1
MPToggleHitbox.Text = ""
MPToggleHitbox.Parent = AAimGroup

local MPCircle = Instance.new("Frame")
MPCircle.Size = UDim2.new(0, 8, 0, 8)
MPCircle.Position = UDim2.new(0, 0, 0.5, -4)
MPCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
MPCircle.BorderSizePixel = 0
MPCircle.Parent = MPToggleHitbox
Instance.new("UICorner", MPCircle).CornerRadius = UDim.new(1, 0)

local MPLabel = Instance.new("TextLabel")
MPLabel.Size = UDim2.new(1, -16, 1, 0)
MPLabel.Position = UDim2.new(0, 16, 0, 0)
MPLabel.BackgroundTransparency = 1
MPLabel.Text = "Multi-Points"
MPLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
MPLabel.Font = Enum.Font.Code
MPLabel.TextSize = 12
MPLabel.TextXAlignment = Enum.TextXAlignment.Left
MPLabel.Parent = MPToggleHitbox

table.insert(Connections, MPToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(MPLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, MPToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(MPLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, MPToggleHitbox.MouseButton1Click:Connect(function()
    MultiPointsEnabled = not MultiPointsEnabled
    TweenService:Create(MPCircle, TweenInfo.new(0.2), {BackgroundColor3 = MultiPointsEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- Triggerbot Toggle (sub-feature: auto-fire when crosshair is on a player part)
local TriggerbotEnabled = false

local TBToggleHitbox = Instance.new("TextButton")
TBToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
TBToggleHitbox.Position = UDim2.new(0, 10, 0, 137)
TBToggleHitbox.BackgroundTransparency = 1
TBToggleHitbox.Text = ""
TBToggleHitbox.Parent = AAimGroup

local TBCircle = Instance.new("Frame")
TBCircle.Size = UDim2.new(0, 8, 0, 8)
TBCircle.Position = UDim2.new(0, 0, 0.5, -4)
TBCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
TBCircle.BorderSizePixel = 0
TBCircle.Parent = TBToggleHitbox
Instance.new("UICorner", TBCircle).CornerRadius = UDim.new(1, 0)

local TBLabel = Instance.new("TextLabel")
TBLabel.Size = UDim2.new(1, -16, 1, 0)
TBLabel.Position = UDim2.new(0, 16, 0, 0)
TBLabel.BackgroundTransparency = 1
TBLabel.Text = "Triggerbot"
TBLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TBLabel.Font = Enum.Font.Code
TBLabel.TextSize = 12
TBLabel.TextXAlignment = Enum.TextXAlignment.Left
TBLabel.Parent = TBToggleHitbox

table.insert(Connections, TBToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(TBLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, TBToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(TBLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, TBToggleHitbox.MouseButton1Click:Connect(function()
    TriggerbotEnabled = not TriggerbotEnabled
    TweenService:Create(TBCircle, TweenInfo.new(0.2), {BackgroundColor3 = TriggerbotEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- No Bind Toggle (aim assist works without holding RMB)
local AimNoBind = false

local NBToggleHitbox = Instance.new("TextButton")
NBToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
NBToggleHitbox.Position = UDim2.new(0, 10, 0, 155)
NBToggleHitbox.BackgroundTransparency = 1
NBToggleHitbox.Text = ""
NBToggleHitbox.Parent = AAimGroup

local NBCircle = Instance.new("Frame")
NBCircle.Size = UDim2.new(0, 8, 0, 8)
NBCircle.Position = UDim2.new(0, 0, 0.5, -4)
NBCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
NBCircle.BorderSizePixel = 0
NBCircle.Parent = NBToggleHitbox
Instance.new("UICorner", NBCircle).CornerRadius = UDim.new(1, 0)

local NBLabel = Instance.new("TextLabel")
NBLabel.Size = UDim2.new(1, -16, 1, 0)
NBLabel.Position = UDim2.new(0, 16, 0, 0)
NBLabel.BackgroundTransparency = 1
NBLabel.Text = "No Bind"
NBLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
NBLabel.Font = Enum.Font.Code
NBLabel.TextSize = 12
NBLabel.TextXAlignment = Enum.TextXAlignment.Left
NBLabel.Parent = NBToggleHitbox

table.insert(Connections, NBToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(NBLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, NBToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(NBLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, NBToggleHitbox.MouseButton1Click:Connect(function()
    AimNoBind = not AimNoBind
    TweenService:Create(NBCircle, TweenInfo.new(0.2), {BackgroundColor3 = AimNoBind and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- FOV Circle (drawn on screen, same orange color)
local FovCircle = Instance.new("Frame")
FovCircle.Name = "FovCircle"
FovCircle.BackgroundTransparency = 1
FovCircle.BorderSizePixel = 0
FovCircle.ZIndex = 9998
FovCircle.Parent = PastaLandGui

local FovCircleStroke = Instance.new("UIStroke")
FovCircleStroke.Color = Color3.fromRGB(255, 180, 0)
FovCircleStroke.Thickness = 1.5
FovCircleStroke.Transparency = 0.3
FovCircleStroke.Parent = FovCircle
Instance.new("UICorner", FovCircle).CornerRadius = UDim.new(1, 0)

-- Silent Aim FOV Circle (red, centered on screen)
local SAFovCircle = Instance.new("Frame")
SAFovCircle.Name = "SAFovCircle"
SAFovCircle.BackgroundTransparency = 1
SAFovCircle.BorderSizePixel = 0
SAFovCircle.ZIndex = 9997
SAFovCircle.Visible = false
SAFovCircle.Parent = PastaLandGui

local SAFovCircleStroke = Instance.new("UIStroke")
SAFovCircleStroke.Color = Color3.fromRGB(255, 80, 80)
SAFovCircleStroke.Thickness = 1.5
SAFovCircleStroke.Transparency = 0.3
SAFovCircleStroke.Parent = SAFovCircle
Instance.new("UICorner", SAFovCircle).CornerRadius = UDim.new(1, 0)

-- Update FOV circles every frame
table.insert(Connections, RunService.RenderStepped:Connect(function()
    -- Aim Assist FOV circle (follows mouse)
    if AimEnabled then
        local sz = AimFov * 2
        local center = UserInputService:GetMouseLocation()
        FovCircle.Visible = true
        FovCircle.Size = UDim2.new(0, sz, 0, sz)
        FovCircle.Position = UDim2.new(0, center.X - AimFov, 0, center.Y - AimFov)
    else
        FovCircle.Visible = false
    end
    -- Silent Aim FOV circle (follows mouse cursor)
    if SilentEnabled and SilentFov > 0 then
        local mouseLoc = UserInputService:GetMouseLocation()
        local sz = SilentFov * 2
        SAFovCircle.Visible = true
        SAFovCircle.Size = UDim2.new(0, sz, 0, sz)
        SAFovCircle.Position = UDim2.new(0, mouseLoc.X - SilentFov, 0, mouseLoc.Y - SilentFov)
    else
        SAFovCircle.Visible = false
    end
end))

-- ==========================================
-- AIM ASSIST LOGIC
-- RMB hold to aim, wall check via Raycast, targets closest body part inside FOV.
-- ==========================================

-- Body parts checked when Multi-Points is ON (R15 + R6 names, FindFirstChild skips missing ones)
local multiPointPartNames = {
    "Head", "UpperTorso", "Torso", "LowerTorso",
    "RightUpperArm", "LeftUpperArm", "RightLowerArm", "LeftLowerArm",
    "RightUpperLeg", "LeftUpperLeg",
}

-- Returns (player, part) – part is the closest body part to screen center within FOV
local function getBestTarget()
    local cam = workspace.CurrentCamera
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local bestPlayer = nil
    local bestPart   = nil
    local bestDist   = math.huge

    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local partsToCheck = MultiPointsEnabled and multiPointPartNames or {"Head"}

        for _, partName in ipairs(partsToCheck) do
            local part = char:FindFirstChild(partName)
            if not part then continue end

            local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
            if not onScreen then continue end

            local screenVec = Vector2.new(screenPos.X, screenPos.Y)
            local dist = (screenVec - screenCenter).Magnitude
            if dist > AimFov then continue end

            if not hrp then continue end
            if not isVisible(hrp.Position, part.Position) then continue end

            if dist < bestDist then
                bestDist   = dist
                bestPlayer = p
                bestPart   = part
            end
        end
    end
    return bestPlayer, bestPart
end

table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
    if not AimEnabled then return end
    local rmb = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if not AimNoBind and not rmb then return end

    local target, targetPart = getBestTarget()
    if not target or not targetPart then return end

    local cam = workspace.CurrentCamera
    local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return end

    local targetCF = CFrame.new(cam.CFrame.Position, targetPart.Position)
    cam.CFrame = cam.CFrame:Lerp(targetCF, AimSpeed)
end))

-- ==========================================
-- MISC PAGE SETUP
-- ==========================================
local miscPage = tabContents["Misc"]

local MiscGroup = Instance.new("Frame")
MiscGroup.Size = UDim2.new(0.5, -15, 1, -20)
MiscGroup.Position = UDim2.new(0, 10, 0, 10)
MiscGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MiscGroup.BorderColor3 = Color3.fromRGB(40, 40, 40)
MiscGroup.BorderSizePixel = 1
MiscGroup.Parent = miscPage

local MiscGroupTitleBG = Instance.new("Frame")
MiscGroupTitleBG.Size = UDim2.new(1, 0, 0, 15)
MiscGroupTitleBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MiscGroupTitleBG.BorderSizePixel = 0
MiscGroupTitleBG.Parent = MiscGroup

local MiscGroupTitle = Instance.new("TextLabel")
MiscGroupTitle.Size = UDim2.new(1, 0, 1, 0)
MiscGroupTitle.BackgroundTransparency = 1
MiscGroupTitle.Text = " Movement"
MiscGroupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
MiscGroupTitle.Font = Enum.Font.Code
MiscGroupTitle.TextSize = 12
MiscGroupTitle.TextXAlignment = Enum.TextXAlignment.Left
MiscGroupTitle.Parent = MiscGroupTitleBG

-- Auto Peek Toggle
local AutoPeekEnabled = false

local APToggleHitbox = Instance.new("TextButton")
APToggleHitbox.Size = UDim2.new(1, -20, 0, 16)
APToggleHitbox.Position = UDim2.new(0, 10, 0, 25)
APToggleHitbox.BackgroundTransparency = 1
APToggleHitbox.Text = ""
APToggleHitbox.Parent = MiscGroup

local APCircle = Instance.new("Frame")
APCircle.Size = UDim2.new(0, 8, 0, 8)
APCircle.Position = UDim2.new(0, 0, 0.5, -4)
APCircle.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
APCircle.BorderSizePixel = 0
APCircle.Parent = APToggleHitbox
Instance.new("UICorner", APCircle).CornerRadius = UDim.new(1, 0)

local APLabel = Instance.new("TextLabel")
APLabel.Size = UDim2.new(1, -16, 1, 0)
APLabel.Position = UDim2.new(0, 16, 0, 0)
APLabel.BackgroundTransparency = 1
APLabel.Text = "Auto Peek [V]"
APLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
APLabel.Font = Enum.Font.Code
APLabel.TextSize = 12
APLabel.TextXAlignment = Enum.TextXAlignment.Left
APLabel.Parent = APToggleHitbox

table.insert(Connections, APToggleHitbox.MouseEnter:Connect(function()
    TweenService:Create(APLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(255,255,255)}):Play()
end))
table.insert(Connections, APToggleHitbox.MouseLeave:Connect(function()
    TweenService:Create(APLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(200,200,200)}):Play()
end))
table.insert(Connections, APToggleHitbox.MouseButton1Click:Connect(function()
    AutoPeekEnabled = not AutoPeekEnabled
    TweenService:Create(APCircle, TweenInfo.new(0.2), {BackgroundColor3 = AutoPeekEnabled and Color3.fromRGB(255,180,0) or Color3.fromRGB(255,50,50)}):Play()
end))

-- ==========================================
-- AUTO PEEK LOGIC
-- Hold V → save current position, place orange circle there. Move freely.
-- V release or LMB → walk back to saved position at 1.2x WalkSpeed.
-- Triggerbot fire → same return after shot.
-- ==========================================
local peekActive = false
local peekReturning = false
local peekOriginPos = nil
local peekPath = {} -- recorded waypoints while peeking

-- Flat neon cylinder on the ground at origin spot
local PeekCircle = Instance.new("Part")
PeekCircle.Name = "PastaLandPeekCircle"
PeekCircle.Anchored = true
PeekCircle.CanCollide = false
PeekCircle.CastShadow = false
PeekCircle.Size = Vector3.new(1, 1, 1)
PeekCircle.CFrame = CFrame.new(0, -10000, 0)
PeekCircle.Material = Enum.Material.Neon
PeekCircle.Color = Color3.fromRGB(255, 180, 0)
PeekCircle.Transparency = 1
pcall(function() PeekCircle.Parent = workspace end)

local PeekMesh = Instance.new("SpecialMesh")
PeekMesh.MeshType = Enum.MeshType.Cylinder
PeekMesh.Scale = Vector3.new(0.15, 3, 3)
PeekMesh.Parent = PeekCircle

-- Record path waypoints while peeking (every ~1 stud)
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not peekActive then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    if #peekPath == 0 or (peekPath[#peekPath] - pos).Magnitude >= 1 then
        table.insert(peekPath, pos)
    end
end))

local function startReturn()
    if not peekActive then return end
    if peekReturning then return end
    if not peekOriginPos then
        peekActive = false
        return
    end
    peekActive = false
    peekReturning = true

    -- Build return path: reverse of recorded waypoints, ending at origin
    local returnPath = {}
    for i = #peekPath, 1, -1 do
        table.insert(returnPath, peekPath[i])
    end
    table.insert(returnPath, peekOriginPos)
    peekPath = {}
    local savedOrigin = peekOriginPos

    task.spawn(function()
        for _, waypoint in ipairs(returnPath) do
            if not peekReturning then break end
            local t = 0
            while peekReturning and t < 3 do
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then peekReturning = false; break end
                local dist = (hrp.Position - waypoint).Magnitude
                if dist < 0.5 then break end
                hrp.CFrame = hrp.CFrame:Lerp(
                    CFrame.new(waypoint) * (hrp.CFrame - hrp.CFrame.Position),
                    0.35
                )
                t = t + task.wait()
            end
        end
        -- Final snap to origin
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(savedOrigin) * (hrp.CFrame - hrp.CFrame.Position)
        end
        peekReturning = false
        peekOriginPos = nil
        PeekCircle.Transparency = 1
        PeekCircle.CFrame = CFrame.new(0, -10000, 0)
    end)
end

-- V press: save position, show circle at origin
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not AutoPeekEnabled then return end
    if input.KeyCode ~= Enum.KeyCode.V then return end
    if peekActive or peekReturning then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    peekOriginPos = hrp.Position
    peekPath = {}
    peekActive = true

    -- Place circle on ground at saved position
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(peekOriginPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), rayParams)
    local groundY = hit and hit.Position.Y or (peekOriginPos.Y - 3)
    PeekCircle.CFrame = CFrame.new(peekOriginPos.X, groundY + 0.1, peekOriginPos.Z) * CFrame.Angles(0, 0, math.pi / 2)
    PeekCircle.Transparency = 0.35
end))

-- V release: walk back to origin
table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode ~= Enum.KeyCode.V then return end
    startReturn()
end))

-- LMB while peeking: return after shot registers
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not peekActive then return end
    task.delay(0.12, startReturn)
end))

-- ==========================================
-- TRIGGERBOT LOGIC (sub-feature of Aim Assist)
-- Raycast from camera along LookVector. If it hits a player part → fire.
-- Multi-Points ON: any body part triggers. OFF: head only.
-- ==========================================

local tbFiring = false -- prevent overlapping presses
table.insert(Connections, RunService.Heartbeat:Connect(function()
    if not TriggerbotEnabled then return end
    if tbFiring then return end

    local cam = workspace.CurrentCamera
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 2000, rayParams)
    if not result then return end

    local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
    if not hitChar then return end

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if p.Character ~= hitChar then continue end
        local hum = hitChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then break end

        if not MultiPointsEnabled then
            local head = hitChar:FindFirstChild("Head")
            if result.Instance ~= head then break end
        end

        tbFiring = true
        task.spawn(function()
            pcall(function()
                mouse1press()
                task.wait(0.05)
                mouse1release()
            end)
            startReturn()
            tbFiring = false
        end)
        break
    end
end))

-- ==========================================
-- EXECUTE INTRO SEQUENCE
-- ==========================================

task.spawn(function()
    local introTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    
    -- Fade in Background
    TweenService:Create(IntroScreen, introTweenInfo, {BackgroundTransparency = 0.2}):Play()
    task.wait(0.5)
    
    -- Fade in Text and Bar BG
    TweenService:Create(IntroLogo, introTweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(IntroSub, introTweenInfo, {TextTransparency = 0}):Play()
    TweenService:Create(LoadingBarBG, introTweenInfo, {BackgroundTransparency = 0}):Play()
    task.wait(0.5)
    
    -- Animate Bar Fill
    TweenService:Create(LoadingBarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    task.wait(1.7)
    
    -- Fade Out Everything
    local fadeOutInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(IntroLogo, fadeOutInfo, {TextTransparency = 1}):Play()
    TweenService:Create(IntroSub, fadeOutInfo, {TextTransparency = 1}):Play()
    TweenService:Create(LoadingBarBG, fadeOutInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadingBarFill, fadeOutInfo, {BackgroundTransparency = 1}):Play()
    task.wait(0.4)
    
    local endScreenTween = TweenService:Create(IntroScreen, fadeOutInfo, {BackgroundTransparency = 1})
    endScreenTween:Play()
    endScreenTween.Completed:Connect(function()
        IntroScreen:Destroy()
        -- Show the HUD if ToggleEnabled is true
        if ToggleEnabled then
            HUD.Visible = true
        end
    end)
end)

-- Finish setup
print("PastaLand UI Loaded Successfully")

