-- TAS Recorder (исправления: крупный текст, предотвращение перекрытий, + кнопка создания TAS)
-- В этом варианте 4-я клавиша Back (GoFrameBack)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local SAVE_ROOT = "TAS_Recorder"
local TAS_FOLDER = SAVE_ROOT .. "/tas"
local SETTINGS_FILE = SAVE_ROOT .. "/settings.json"

local function safe_isfolder(p) if isfolder then return isfolder(p) end return false end
local function safe_makefolder(p) if makefolder then return makefolder(p) end return false end
local function safe_isfile(p) if isfile then return isfile(p) end return false end
local function safe_writefile(p, data) if writefile then return writefile(p, data) end return false end
local function safe_readfile(p) if readfile then return readfile(p) end return nil end

local DefaultSettings = {
    Keybinds = {
        AddSavestate = "One",
        RemoveSavestate = "Two",
        BackSavestate = "Eight",
        GoFrameBack = "Four",
        GoFrameForward = "Five",
        SaveRun = "Six",
        UserPause = "CapsLock",
        CollisionToggler = "C",
        ResetToNormal = "Delete",
        ViewTAS = "Zero",
        ToggleGUI = "RightControl",
        StartRecording = "F7",
    },
    UnlockedCamera = false,
    GUIEnabled = true,
}

local Settings = {}
local Keybinds = {}
local Savestates = {}
local PlayerInfo = {}
local TimePaused = 0
local Pause = true
local TimePauseHolder
local TimeStart
local FrameCountLabel
local SavestatesCountLabel
local TimeTextLabel
local CapLockPauseLabel
local KeyBindFrame
local HUD
local MainConnectionLoop
local KeybindsConnect
local InputEndConnect
local DiedConnect
local ViewingTAS = false
local CurrentAnimationState = { Name = "Idle", Weight = 0 }
local Recording = false

local MainFrame, TabContainer, TabsButtons, ContentFrames
local RecordingIndicator, StartStopButton

local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local res = {}
    for k, v in pairs(t) do res[k] = deepcopy(v) end
    return res
end

local function ensureSaveFolders()
    if not safe_isfolder(SAVE_ROOT) then
        safe_makefolder(SAVE_ROOT)
    end
    if not safe_isfolder(TAS_FOLDER) then
        safe_makefolder(TAS_FOLDER)
    end
end

local function loadSettings()
    if safe_isfile(SETTINGS_FILE) then
        local ok, txt = pcall(safe_readfile, SETTINGS_FILE)
        if ok and txt then
            local succ, decoded = pcall(HttpService.JSONDecode, HttpService, txt)
            if succ and type(decoded) == "table" then
                Settings = decoded
                Keybinds = Settings.Keybinds or DefaultSettings.Keybinds
                return
            end
        end
    end
    Settings = deepcopy(DefaultSettings)
    Keybinds = deepcopy(DefaultSettings.Keybinds)
end

local function saveSettings()
    Settings.Keybinds = Keybinds
    local encoded = HttpService:JSONEncode(Settings)
    if writefile then
        ensureSaveFolders()
        pcall(safe_writefile, SETTINGS_FILE, encoded)
    else
        print("Settings (no writefile):")
        print(encoded)
    end
end

local function getCurrentCFrame()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.CFrame
    end
    return CFrame.new()
end

local function getCurrentVelocity()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return LocalPlayer.Character.HumanoidRootPart.Velocity
    end
    return Vector3.new()
end

local function getCurrentCameraCFrame()
    return Workspace.CurrentCamera and Workspace.CurrentCamera.CFrame or CFrame.new()
end

local function ReturnPlayerInfo()
    return {
        CFrame = getCurrentCFrame(),
        CameraCFrame = getCurrentCameraCFrame(),
        Velocity = getCurrentVelocity(),
        Animation = CurrentAnimationState,
        Time = tick() - TimeStart - TimePaused,
    }
end

local function UpdateGUIText()
    if SavestatesCountLabel then
        SavestatesCountLabel.Text = "Savestates: " .. #Savestates
    end
    if FrameCountLabel then
        FrameCountLabel.Text = "Frames: " .. #PlayerInfo
    end
end

local function FormatTime(TimeValue)
    local m = math.floor(TimeValue / 60)
    local s = math.floor(TimeValue % 60)
    local ms = math.floor((TimeValue * 1000) % 1000)
    local msStr = tostring(ms)
    local sStr = tostring(s)

    while #msStr < 3 do msStr = '0' .. msStr end
    while #sStr < 2 do sStr = '0' .. sStr end

    return m .. ":" .. sStr .. "." .. msStr
end

local function UpdateTimeGUI()
    if TimeTextLabel then
        local TimePlayed = tick() - TimeStart - TimePaused
        TimeTextLabel.Text = FormatTime(TimePlayed)
    end
end

local function SetCharacterState(InfoState)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end

    local Hum = LocalPlayer.Character.Humanoid
    local RootPart = LocalPlayer.Character.HumanoidRootPart

    RootPart.CFrame = InfoState.CFrame
    RootPart.Velocity = InfoState.Velocity
    if not Settings.UnlockedCamera then
        if Workspace.CurrentCamera and InfoState.CameraCFrame then
            Workspace.CurrentCamera.CFrame = InfoState.CameraCFrame
        end
    end

    CurrentAnimationState = InfoState.Animation or { Name = "Idle", Weight = 0 }

    if CurrentAnimationState.Name and Hum then
        local Animator = Hum:FindFirstChildOfClass("Animator")
        if Animator then
             local PlayingTracks = Animator:GetPlayingAnimationTracks()
             for _, track in ipairs(PlayingTracks) do
                 if track.Name == CurrentAnimationState.Name then
                    track:AdjustSpeed(CurrentAnimationState.Weight or 1)
                    track.TimePosition = 0
                    break
                 end
             end
        end
    end
end

local function PrepareTasData()
    local FullTAS = {}
    for i = 1, #Savestates do
        for j = 1, #Savestates[i] do
            local Frame = Savestates[i][j]
            local MinFrame = {}
            local cfX, cfY, cfZ, cfR00, cfR01, cfR02, cfR10, cfR11, cfR12, cfR20, cfR21, cfR22 = Frame.CFrame:GetComponents()
            local camX, camY, camZ, camR00, camR01, camR02, camR10, camR11, camR12, camR20, camR21, camR22 = Frame.CameraCFrame:GetComponents()

            MinFrame.CCFrame = {cfX, cfY, cfZ, cfR00, cfR01, cfR02, cfR10, cfR11, cfR12, cfR20, cfR21, cfR22}
            MinFrame.CCameraCFrame = {camX, camY, camZ, camR00, camR01, camR02, camR10, camR11, camR12, camR20, camR21, camR22}
            MinFrame.VVelocity = {Frame.Velocity.X, Frame.Velocity.Y, Frame.Velocity.Z}
            MinFrame.AAnimation = Frame.Animation or {Name="Idle", Weight=0}
            MinFrame.time = Frame.Time

            table.insert(FullTAS, MinFrame)
        end
    end
    return FullTAS
end

local function SaveTASToFile(name)
    local FullTAS = PrepareTasData()
    if #FullTAS == 0 then
        print("No TAS data to save.")
        return false
    end
    local safeName = tostring(name):gsub("[^%w_%- ]", "_")
    if safeName == "" then safeName = "untitled" end
    ensureSaveFolders()
    local path = TAS_FOLDER .. "/" .. safeName .. ".json"
    local encoded = HttpService:JSONEncode(FullTAS)
    if writefile then
        pcall(safe_writefile, path, encoded)
        print("TAS saved to: " .. path)
        return true
    else
        print("File saving not supported. TAS JSON:")
        print(encoded)
        return false
    end
end

local function ListTASFiles()
    if not safe_isfolder(TAS_FOLDER) then return {} end
    local res = {}
    if listfiles then
        local ok, items = pcall(listfiles, TAS_FOLDER)
        if ok and type(items) == "table" then
            for _, p in ipairs(items) do
                local name = p:match("([^/\\]+)%.json$")
                if name then table.insert(res, name) end
            end
        end
    end
    return res
end

local function LoadTASFromFile(name)
    local safeName = tostring(name):gsub("[^%w_%- ]", "_")
    if safeName == "" then return nil end
    local path = TAS_FOLDER .. "/" .. safeName .. ".json"
    if not safe_isfile(path) then
        print("TAS file not found: " .. path)
        return nil
    end
    local ok, txt = pcall(safe_readfile, path)
    if not ok or not txt then
        print("Failed to read TAS file.")
        return nil
    end
    local succ, decoded = pcall(HttpService.JSONDecode, HttpService, txt)
    if succ and type(decoded) == "table" then
        return decoded
    end
    return nil
end

local function ViewTASPlayback(TAS)
    if ViewingTAS or #TAS == 0 then return end
    ViewingTAS = true
    print("Starting TAS Playback...")

    local StartTime = tick()
    local CurrentFrameIndex = 1
    local PlaybackConnection

    if Pause then UserPauseToggle() end

    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        print("Character not found for playback.")
        ViewingTAS = false
        return
    end
    local RootPart = Character.HumanoidRootPart
    local Hum = Character:FindFirstChildOfClass("Humanoid")

    local function StopPlayback()
        if PlaybackConnection then
            PlaybackConnection:Disconnect()
            PlaybackConnection = nil
        end
        if RootPart then RootPart.Anchored = false end
        ViewingTAS = false
        print("TAS Playback finished.")
        task.wait()
        UserPauseToggle()
        if not Pause then UserPauseToggle() end
    end

    RootPart.Anchored = false

    PlaybackConnection = RunService.Heartbeat:Connect(function()
        local ElapsedTime = tick() - StartTime
        local TargetFrame = nil

        while CurrentFrameIndex <= #TAS and TAS[CurrentFrameIndex].time <= ElapsedTime do
             TargetFrame = TAS[CurrentFrameIndex]
             CurrentFrameIndex = CurrentFrameIndex + 1
        end

        if TargetFrame then
             local cfData = TargetFrame.CCFrame
             local camData = TargetFrame.CCameraCFrame
             RootPart.CFrame = CFrame.new(cfData[1], cfData[2], cfData[3], cfData[4], cfData[5], cfData[6], cfData[7], cfData[8], cfData[9], cfData[10], cfData[11], cfData[12])
             RootPart.Velocity = Vector3.new(TargetFrame.VVelocity[1], TargetFrame.VVelocity[2], TargetFrame.VVelocity[3])
             if not Settings.UnlockedCamera and Workspace.CurrentCamera then
                 Workspace.CurrentCamera.CFrame = CFrame.new(camData[1], camData[2], camData[3], camData[4], camData[5], camData[6], camData[7], camData[8], camData[9], camData[10], camData[11], camData[12])
             end

             local AnimInfo = TargetFrame.AAnimation
             if AnimInfo and Hum then
                 local Animator = Hum:FindFirstChildOfClass("Animator")
                 if Animator then
                    local Playing = Animator:GetPlayingAnimationTracks()
                    for _, track in ipairs(Playing) do
                        if track.Name == AnimInfo.Name then
                            if not track.IsPlaying then track:Play() end
                            track:AdjustSpeed(AnimInfo.Weight or 1)
                            break
                        end
                    end
                 end
             end
        end

        if CurrentFrameIndex > #TAS then
            StopPlayback()
        end
    end)
end

local function UserPauseToggle()
    Pause = not Pause
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Anchored = Pause
    end

    if Pause then
        TimePauseHolder = tick()
        if TimeTextLabel then TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 0) end
        if CapLockPauseLabel then
             CapLockPauseLabel.Text = Keybinds.UserPause .. " : Paused"
             CapLockPauseLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
    else
        if TimePauseHolder then
            TimePaused = TimePaused + (tick() - TimePauseHolder)
            TimePauseHolder = nil
        end
        if TimeTextLabel then TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end
        if CapLockPauseLabel then
             CapLockPauseLabel.Text = Keybinds.UserPause .. " : Unpaused"
             CapLockPauseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

local function AddSavestate()
    table.insert(Savestates, PlayerInfo)
    PlayerInfo = {}
    UpdateGUIText()
end

local function RemoveSavestate()
    if #Savestates > 1 then
        table.remove(Savestates)
        UpdateGUIText()
    end
end

local function BackSavestate()
     if #Savestates > 0 and Savestates[#Savestates] and #Savestates[#Savestates] > 0 then
        local InfoState = Savestates[#Savestates][#Savestates[#Savestates]]
        PlayerInfo = {}
        Pause = true
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
        end
        TimePauseHolder = tick()
        TimeStart = tick() - InfoState.Time
        TimePaused = 0
        SetCharacterState(InfoState)
        if TimeTextLabel then TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 0) end
        if CapLockPauseLabel then
             CapLockPauseLabel.Text = Keybinds.UserPause .. " : Paused"
             CapLockPauseLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        end
        UpdateTimeGUI()
    end
end

local function GoFrameForward()
    if Pause then
        UserPauseToggle()
        RunService.Heartbeat:Wait()
        RunService.Heartbeat:Wait()
        UserPauseToggle()
    end
end

local isFrameForwardHeld = false
local function FrameForwardStart()
    isFrameForwardHeld = true
    GoFrameForward()
    while task.wait(0.05) and isFrameForwardHeld do
        GoFrameForward()
    end
end

local isFrameBackHeld = false
local function GoFrameBack()
    if LocalPlayer.Character then
        local TargetFrameInfo = nil
        if #PlayerInfo > 1 then
            TargetFrameInfo = PlayerInfo[#PlayerInfo - 1]
            PlayerInfo[#PlayerInfo] = nil
        elseif #Savestates > 0 and #Savestates[#Savestates] > 1 then
             TargetFrameInfo = Savestates[#Savestates][#Savestates[#Savestates] - 1]
             Savestates[#Savestates][#Savestates[#Savestates]] = nil
        end

        if TargetFrameInfo then
            if not Pause then UserPauseToggle() end
            TimePauseHolder = tick()
            TimeStart = tick() - TargetFrameInfo.Time
            TimePaused = 0
            SetCharacterState(TargetFrameInfo)
            UpdateTimeGUI()
            UpdateGUIText()
        end
    end
end

local function FrameBackStart()
    isFrameBackHeld = true
    GoFrameBack()
    while task.wait(0.05) and isFrameBackHeld do
        GoFrameBack()
    end
end

local function CollisionToggler()
    local Target = Mouse.Target
    if Target and Target:IsA("BasePart") then
        Target.CanCollide = not Target.CanCollide
        Target.Transparency = Target.CanCollide and 0 or 0.7
    end
end

local function DisconnectAll()
    if MainConnectionLoop then MainConnectionLoop:Disconnect() MainConnectionLoop = nil end
    if KeybindsConnect then KeybindsConnect:Disconnect() KeybindsConnect = nil end
    if InputEndConnect then InputEndConnect:Disconnect() InputEndConnect = nil end
    if DiedConnect then DiedConnect:Disconnect() DiedConnect = nil end
    if HUD then HUD:Destroy() HUD = nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
       LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    print("TAS Recorder Stopped.")
end

-- Draggable helper
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function clearFrameChildren(frame)
    for _, c in ipairs(frame:GetChildren()) do
        pcall(function() c:Destroy() end)
    end
end

local function CreateLabel(parent, props)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = props.Size or UDim2.new(1, 0, 0, 20)
    lbl.Position = props.Position or UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = props.BackgroundTransparency or 1
    lbl.Font = props.Font or Enum.Font.SourceSans
    lbl.Text = props.Text or ""
    lbl.TextColor3 = props.TextColor3 or Color3.fromRGB(230,230,230)
    lbl.TextScaled = props.TextScaled or false
    lbl.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
    lbl.TextWrapped = props.TextWrapped or false
    lbl.TextSize = props.TextSize or 20
    return lbl
end

local function CreateButton(parent, props)
    local b = Instance.new("TextButton", parent)
    b.Size = props.Size or UDim2.new(1, 0, 0, 25)
    b.Position = props.Position or UDim2.new(0, 0, 0, 0)
    b.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(70,70,70)
    b.Font = props.Font or Enum.Font.SourceSansBold
    b.Text = props.Text or "Button"
    b.TextColor3 = props.TextColor3 or Color3.fromRGB(255,255,255)
    b.AutoButtonColor = true
    b.TextScaled = props.TextScaled or false
    b.TextSize = props.TextSize or 24
    return b
end

-- Toggle Recording
local function ToggleRecording()
    if not Recording then
        Recording = true
        Savestates = {}
        PlayerInfo = {}
        TimePaused = 0
        Pause = true
        TimeStart = tick()
        TimePauseHolder = tick()

        local initial = {
            CFrame = getCurrentCFrame(),
            CameraCFrame = getCurrentCameraCFrame(),
            Velocity = getCurrentVelocity(),
            Animation = {Name="Idle", Weight=0},
            Time = 0
        }

        table.insert(Savestates, { initial })
        print("Recording started.")
        if RecordingIndicator then
            RecordingIndicator.Text = "% RECORDING"
            RecordingIndicator.TextColor3 = Color3.fromRGB(200,50,50)
        end
        if StartStopButton then StartStopButton.Text = "Stop" end

        if MainConnectionLoop then
            MainConnectionLoop:Disconnect()
            MainConnectionLoop = nil
        end

        MainConnectionLoop = RunService.Heartbeat:Connect(function(deltaTime)
            if Recording and not Pause then
                UpdateTimeGUI()
                table.insert(PlayerInfo, ReturnPlayerInfo())
                UpdateGUIText()
            end
        end)

        UserPauseToggle()
        if not Pause then UserPauseToggle() end
    else
        Recording = false
        print("Recording stopped.")
        if RecordingIndicator then
            RecordingIndicator.Text = "% Idle"
            RecordingIndicator.TextColor3 = Color3.fromRGB(200,200,200)
        end
        if StartStopButton then StartStopButton.Text = "Start" end
        if MainConnectionLoop then
            MainConnectionLoop:Disconnect()
            MainConnectionLoop = nil
        end
        MainConnectionLoop = RunService.Heartbeat:Connect(function(deltaTime)
            UpdateGUIText()
        end)
    end
end

-- GUI Setup
local function SetUpGui()
    if HUD then HUD:Destroy() end

    -- Bigger ScreenGui
    HUD = Instance.new("ScreenGui", CoreGui)
    HUD.Name = "TASRecorderGUI_v4"
    HUD.ResetOnSpawn = false
    HUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- MAIN FRAME (более крупный)
    MainFrame = Instance.new("Frame", HUD)
    MainFrame.Name = "MainFrame"
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.Position = UDim2.new(0.8, 0, 0.5, 0)
    MainFrame.Size = UDim2.new(0, 900, 0, 680)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BackgroundTransparency = 0
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true

    local uic = Instance.new("UICorner", MainFrame)
    uic.CornerRadius = UDim.new(0, 12)

    -- TOP BAR
    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 44)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TopBar)
    Title.Size = UDim2.new(0.7, -10, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.SourceSansBold
    Title.Text = "TAS Recorder"
    Title.TextColor3 = Color3.fromRGB(255,255,255)
    Title.TextScaled = true
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TopBar)
    CloseBtn.Size = UDim2.new(0, 28, 0, 20)
    CloseBtn.Position = UDim2.new(1, -36, 0, 12)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
    CloseBtn.Text = "X"
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextScaled = true
    CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
    CloseBtn.AutoButtonColor = true
    local closeCorner = Instance.new("UICorner", CloseBtn)

    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
    end)

    makeDraggable(MainFrame, TopBar)

    -- LEFT: Tab buttons (шире)
    TabsButtons = Instance.new("Frame", MainFrame)
    TabsButtons.Size = UDim2.new(0, 180, 1, -56)
    TabsButtons.Position = UDim2.new(0, 12, 0, 44)
    TabsButtons.BackgroundTransparency = 1

    local tb_layout = Instance.new("UIListLayout", TabsButtons)
    tb_layout.Padding = UDim.new(0, 8)
    tb_layout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makeTabButton(text, order)
        local b = Instance.new("TextButton", TabsButtons)
        b.Size = UDim2.new(1, 0, 0, 40)
        b.LayoutOrder = order
        b.BackgroundColor3 = Color3.fromRGB(50,50,50)
        b.Font = Enum.Font.SourceSansBold
        b.Text = text
        b.TextColor3 = Color3.fromRGB(245,245,245)
        b.TextScaled = true
        local c = Instance.new("UICorner", b)
        c.CornerRadius = UDim.new(0, 8)
        return b
    end

    local KeybindsBtn = makeTabButton("Keybinds", 1)
    local TASesBtn = makeTabButton("TASes", 2)
    local SettingsBtn = makeTabButton("Settings", 3)

    -- RIGHT: Content (Scrollable)
    TabContainer = Instance.new("Frame", MainFrame)
    TabContainer.Size = UDim2.new(1, -180, 1, -48)
    TabContainer.Position = UDim2.new(0, 180, 0, 44)
    TabContainer.BackgroundTransparency = 1

    local ContentScroll = Instance.new("ScrollingFrame", TabContainer)
    ContentScroll.Size = UDim2.new(1, 0, 1, 0)
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 1200)
    ContentScroll.CanvasPosition = Vector2.new(0, 0)
    ContentScroll.ScrollBarThickness = 12
    ContentScroll.BackgroundTransparency = 1
    ContentScroll.BorderSizePixel = 0

    ContentFrames = {}

    -- KeyFrame
    local KeyFrame = Instance.new("Frame", ContentScroll)
    KeyFrame.Size = UDim2.new(1, 0, 0, 700)
    KeyFrame.BackgroundTransparency = 1
    ContentFrames["Keybinds"] = KeyFrame

    local kb_layout = Instance.new("UIListLayout", KeyFrame)
    kb_layout.Padding = UDim.new(0,6)
    kb_layout.SortOrder = Enum.SortOrder.LayoutOrder

    local header = CreateLabel(KeyFrame, {Text = "Keybinds", TextWrapped = true, Size = UDim2.new(1,0,0,28), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left})
    header.LayoutOrder = 1
    header.TextSize = 22

    local rebindingState = {waiting = false, keyName = nil, label = nil}

    local function makeBindRow(actionKey, actionName, order)
        local row = Instance.new("Frame", KeyFrame)
        row.Size = UDim2.new(1, 0, 0, 38)
        row.LayoutOrder = order
        row.BackgroundTransparency = 1

        local nameLbl = Instance.new("TextLabel", row)
        nameLbl.Size = UDim2.new(0.58, -6, 1, 0)
        nameLbl.Position = UDim2.new(0, 0, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.SourceSans
        nameLbl.Text = actionName
        nameLbl.TextColor3 = Color3.fromRGB(220,220,220)
        nameLbl.TextScaled = true
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextSize = 22
        nameLbl.TextWrapped = true

        local valBtn = Instance.new("TextButton", row)
        valBtn.Size = UDim2.new(0.42, 6, 1, 0)
        valBtn.Position = UDim2.new(0.58, 6, 0, 0)
        valBtn.Font = Enum.Font.SourceSansBold
        valBtn.Text = Keybinds[actionKey] or "Unknown"
        valBtn.TextScaled = true
        valBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
        valBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local corner = Instance.new("UICorner", valBtn)

        valBtn.MouseButton1Click:Connect(function()
            -- начать переназначение
            rebindingState.waiting = true
            rebindingState.keyName = actionKey
            rebindingState.label = valBtn
            valBtn.Text = "Press any key..."
            valBtn.TextColor3 = Color3.fromRGB(255,200,0)
        end)
        return valBtn
    end

    local order = 2
    local bindButtons = {}
    for k, v in pairs(Keybinds) do
        table.insert(bindButtons, {key=k, name=k, order=order})
        order = order + 1
    end
    table.sort(bindButtons, function(a,b) return a.key < b.key end)
    for _,info in ipairs(bindButtons) do
        makeBindRow(info.key, info.key, info.order)
    end

    -- TASes Frame (крупный текст и кнопка "+ Create TAS")
    local TASFrame = Instance.new("Frame", ContentScroll)
    TASFrame.Size = UDim2.new(1, 0, 1, 0)
    TASFrame.BackgroundTransparency = 1
    ContentFrames["TASes"] = TASFrame

    local tasHeader = CreateLabel(TASFrame, {Text = "TASes", TextWrapped = true, Size = UDim2.new(1,0,0,28), TextScaled = true})
    tasHeader.LayoutOrder = 1

    local nameBox = Instance.new("TextBox", TASFrame)
    nameBox.Size = UDim2.new(1, 0, 0, 34)
    nameBox.Position = UDim2.new(0, 0, 0, 36)
    nameBox.PlaceholderText = "Enter TAS name to save..."
    nameBox.ClearTextOnFocus = false
    nameBox.Font = Enum.Font.SourceSans
    nameBox.TextColor3 = Color3.fromRGB(220,220,220)
    nameBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    local nameCorner = Instance.new("UICorner", nameBox)
    nameBox.LayoutOrder = 2

    -- Big increase: правки размера TAS-элементов и отделение для лучшей читаемости
    local saveBtn = CreateButton(TASFrame, {Text="Save current TAS", Size=UDim2.new(1,0,0,38)})
    saveBtn.LayoutOrder = 3
    saveBtn.Position = UDim2.new(0, 0, 0, 70)
    saveBtn.MouseButton1Click:Connect(function()
        local n = nameBox.Text
        if n == "" then n = "untitled" end
        if SaveTASToFile(n) then
            saveSettings() -- сохранить привязки
            populateTASList()
        end
    end)

    -- + кнопка для быстрого создания
    local plusBtn = CreateButton(TASFrame, {Text="+ Create TAS", Size=UDim2.new(0, 140, 0, 38)})
    plusBtn.Position = UDim2.new(0, 0, 0, 110)
    plusBtn.MouseButton1Click:Connect(function()
        local n = nameBox.Text
        if n == "" then n = "untitled" end
        if SaveTASToFile(n) then
            saveSettings()
            populateTASList()
        end
    end)

    local refreshBtn = CreateButton(TASFrame, {Text="Refresh list", Size=UDim2.new(1,0,0,28)})
    refreshBtn.LayoutOrder = 5
    refreshBtn.Position = UDim2.new(0, 0, 0, 150)

    local tasListFrame = Instance.new("ScrollingFrame", TASFrame)
    tasListFrame.Size = UDim2.new(1,0,0,240)
    tasListFrame.Position = UDim2.new(0,0,0,180)
    tasListFrame.CanvasSize = UDim2.new(0,0)
    tasListFrame.ScrollBarThickness = 6
    tasListFrame.BackgroundTransparency = 1
    local tasLayout = Instance.new("UIListLayout", tasListFrame)
    tasLayout.Padding = UDim.new(0,6)
    tasLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tasListFrame.LayoutOrder = 6

    local function makeTASRow(name)
        local row = Instance.new("Frame", tasListFrame)
        row.Size = UDim2.new(1,0,0,38)
        row.BackgroundTransparency = 1
        -- Сделаем крупный текст для названия TAS
        local label = Instance.new("TextLabel", row)
        label.Size = UDim2.new(0.66,0,1,0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.SourceSans
        label.Text = name
        label.TextColor3 = Color3.fromRGB(230,230,230)
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextSize = 28
        label.TextWrapped = true

        local playBtn = Instance.new("TextButton", row)
        playBtn.Size = UDim2.new(0.14, -6, 1, 0)
        playBtn.Position = UDim2.new(0.66, 6, 0, 0)
        playBtn.Text = "Play"
        playBtn.Font = Enum.Font.SourceSansBold
        playBtn.TextScaled = true
        playBtn.BackgroundColor3 = Color3.fromRGB(70,120,70)
        playBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local playCorner = Instance.new("UICorner", playBtn)

        local loadBtn = Instance.new("TextButton", row)
        loadBtn.Size = UDim2.new(0.14, -6, 1, 0)
        loadBtn.Position = UDim2.new(0.80, 6, 0, 0)
        loadBtn.Text = "Load"
        loadBtn.Font = Enum.Font.SourceSansBold
        loadBtn.TextScaled = true
        loadBtn.BackgroundColor3 = Color3.fromRGB(70,70,130)
        loadBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local loadCorner = Instance.new("UICorner", loadBtn)

        local delBtn = Instance.new("TextButton", row)
        delBtn.Size = UDim2.new(0.14, -6, 1, 0)
        delBtn.Position = UDim2.new(0.94, 6, 0, 0)
        delBtn.Text = "Del"
        delBtn.Font = Enum.Font.SourceSansBold
        delBtn.TextScaled = true
        delBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
        delBtn.TextColor3 = Color3.fromRGB(255,255,255)
        local delCorner = Instance.new("UICorner", delBtn)

        playBtn.MouseButton1Click:Connect(function()
            local tas = LoadTASFromFile(name)
            if tas then
                ViewTASPlayback(tas)
            end
        end)
        loadBtn.MouseButton1Click:Connect(function()
            local tas = LoadTASFromFile(name)
            if tas then
                ViewTASPlayback(tas)
            end
        end)
        delBtn.MouseButton1Click:Connect(function()
            local path = TAS_FOLDER .. "/" .. name .. ".json"
            if safe_isfile(path) and isfile then
                pcall(function() delfile(path) end)
                pcall(function() safe_writefile(path, "[]") end)
                populateTASList()
            end
        end)
        return row
    end

    function populateTASList()
        clearFrameChildren(tasListFrame)
        local files = ListTASFiles()
        if #files == 0 then
            local no = CreateLabel(tasListFrame, {Text="No TAS files found (save one).", Size=UDim2.new(1,0,0,24), TextWrapped=true, TextScaled=true})
            no.LayoutOrder = 1
        else
            local order = 1
            for _, name in ipairs(files) do
                local r = makeTASRow(name)
                r.LayoutOrder = order
                order = order + 1
            end
        end
        local contentSize = 0
        for _,c in ipairs(tasListFrame:GetChildren()) do
            if (c:IsA("Frame") or c:IsA("TextLabel")) and c.Size and c.Size.Y then
                contentSize = contentSize + (c.Size.Y.Offset + 6)
            end
        end
        tasListFrame.CanvasSize = UDim2.new(0,0,0, math.max(contentSize, 1))
    end

    refreshBtn.MouseButton1Click:Connect(function() populateTASList() end)
    populateTASList()

    -- Settings Frame
    local SetFrame = Instance.new("Frame", ContentScroll)
    SetFrame.Size = UDim2.new(1,0,0,700)
    SetFrame.BackgroundTransparency = 1
    ContentFrames["Settings"] = SetFrame

    local setHeader = CreateLabel(SetFrame, {Text="Settings", TextWrapped = true, Size=UDim2.new(1,0,0,28), TextScaled=true})
    setHeader.LayoutOrder = 1

    local unlockCamLabel = CreateLabel(SetFrame, {Text = "Unlocked Camera", TextWrapped = true, Size=UDim2.new(1,0,0,24)})
    unlockCamLabel.LayoutOrder = 2

    local unlockCamToggle = Instance.new("TextButton", SetFrame)
    unlockCamToggle.Size = UDim2.new(0, 140, 0, 34)
    unlockCamToggle.Position = UDim2.new(0, 0, 0, 40)
    unlockCamToggle.Text = Settings.UnlockedCamera and "ON" or "OFF"
    unlockCamToggle.Font = Enum.Font.SourceSansBold
    unlockCamToggle.TextScaled = true
    unlockCamToggle.BackgroundColor3 = Settings.UnlockedCamera and Color3.fromRGB(80,150,80) or Color3.fromRGB(140,80,80)
    local ucCorner = Instance.new("UICorner", unlockCamToggle)
    unlockCamToggle.MouseButton1Click:Connect(function()
        Settings.UnlockedCamera = not Settings.UnlockedCamera
        unlockCamToggle.Text = Settings.UnlockedCamera and "ON" or "OFF"
        unlockCamToggle.BackgroundColor3 = Settings.UnlockedCamera and Color3.fromRGB(80,150,80) or Color3.fromRGB(140,80,80)
    end)

    local saveSettingsBtn = CreateButton(SetFrame, {Text="Save Settings", Size=UDim2.new(0,150,0,30)})
    saveSettingsBtn.Position = UDim2.new(0, 0, 0, 110)
    saveSettingsBtn.MouseButton1Click:Connect(function()
        saveSettings()
        print("Settings saved.")
    end)

    -- Bottom HUD (более крупный шрифт)
    TimeTextLabel = Instance.new("TextLabel", MainFrame)
    TimeTextLabel.Size = UDim2.new(0.5, -20, 0, 28)
    TimeTextLabel.Position = UDim2.new(0, 12, 1, -68)
    TimeTextLabel.BackgroundTransparency = 1
    TimeTextLabel.Font = Enum.Font.SourceSansBold
    TimeTextLabel.Text = "0:00.000"
    TimeTextLabel.TextColor3 = Color3.fromRGB(255,255,0)
    TimeTextLabel.TextScaled = true
    TimeTextLabel.TextXAlignment = Enum.TextXAlignment.Left

    SavestatesCountLabel = Instance.new("TextLabel", MainFrame)
    SavestatesCountLabel.Size = UDim2.new(0.24, -10, 0, 22)
    SavestatesCountLabel.Position = UDim2.new(0.52, 0, 1, -56)
    SavestatesCountLabel.BackgroundTransparency = 1
    SavestatesCountLabel.Font = Enum.Font.SourceSans
    SavestatesCountLabel.Text = "Savestates: 0"
    SavestatesCountLabel.TextColor3 = Color3.fromRGB(220,220,220)
    SavestatesCountLabel.TextScaled = true
    SavestatesCountLabel.TextXAlignment = Enum.TextXAlignment.Left

    FrameCountLabel = Instance.new("TextLabel", MainFrame)
    FrameCountLabel.Size = UDim2.new(0.24, -10, 0, 22)
    FrameCountLabel.Position = UDim2.new(0.76, 0, 1, -56)
    FrameCountLabel.BackgroundTransparency = 1
    FrameCountLabel.Font = Enum.Font.SourceSans
    FrameCountLabel.Text = "Frames: 0"
    FrameCountLabel.TextColor3 = Color3.fromRGB(220,220,220)
    FrameCountLabel.TextScaled = true
    FrameCountLabel.TextXAlignment = Enum.TextXAlignment.Left

    CapLockPauseLabel = Instance.new("TextLabel", MainFrame)
    CapLockPauseLabel.Size = UDim2.new(0.3, -10, 0, 18)
    CapLockPauseLabel.Position = UDim2.new(0.02, 0, 1, -68)
    CapLockPauseLabel.BackgroundTransparency = 1
    CapLockPauseLabel.Font = Enum.Font.SourceSans
    CapLockPauseLabel.Text = Keybinds.UserPause .. " : Paused"
    CapLockPauseLabel.TextColor3 = Color3.fromRGB(255,255,0)
    CapLockPauseLabel.TextScaled = true
    CapLockPauseLabel.TextXAlignment = Enum.TextXAlignment.Left

    RecordingIndicator = Instance.new("TextLabel", MainFrame)
    RecordingIndicator.Size = UDim2.new(0, 140, 0, 28)
    RecordingIndicator.Position = UDim2.new(0, 12, 0, 6)
    RecordingIndicator.BackgroundTransparency = 1
    RecordingIndicator.Font = Enum.Font.SourceSansBold
    RecordingIndicator.Text = Recording and "RECORDING" or "Idle"
    RecordingIndicator.TextColor3 = Recording and Color3.fromRGB(200,50,50) or Color3.fromRGB(200,200,200)
    RecordingIndicator.TextScaled = true
    RecordingIndicator.TextXAlignment = Enum.TextXAlignment.Left

    StartStopButton = Instance.new("TextButton", MainFrame)
    StartStopButton.Size = UDim2.new(0, 80, 0, 28)
    StartStopButton.Position = UDim2.new(1, -96, 0, 6)
    StartStopButton.BackgroundColor3 = Recording and Color3.fromRGB(180,40,40) or Color3.fromRGB(60,140,60)
    StartStopButton.Font = Enum.Font.SourceSansBold
    StartStopButton.Text = Recording and "Stop" or "Start"
    StartStopButton.TextColor3 = Color3.fromRGB(255,255,255)
    StartStopButton.TextScaled = true
    local ssCorner = Instance.new("UICorner", StartStopButton)
    StartStopButton.MouseButton1Click:Connect(function()
        ToggleRecording()
        StartStopButton.BackgroundColor3 = Recording and Color3.fromRGB(180,40,40) or Color3.fromRGB(60,140,60)
    end)

    local function showTab(name)
        for k,v in pairs(ContentFrames) do
            v.Visible = (k == name)
        end
        KeybindsBtn.BackgroundColor3 = name=="Keybinds" and Color3.fromRGB(90,90,90) or Color3.fromRGB(50,50,50)
        TASesBtn.BackgroundColor3 = name=="TASes" and Color3.fromRGB(90,90,90) or Color3.fromRGB(50,50,50)
        SettingsBtn.BackgroundColor3 = name=="Settings" and Color3.fromRGB(90,90,90) or Color3.fromRGB(50,50,50)
    end

    KeybindsBtn.MouseButton1Click:Connect(function() showTab("Keybinds") end)
    TASesBtn.MouseButton1Click:Connect(function() showTab("TASes") end)
    SettingsBtn.MouseButton1Click:Connect(function() showTab("Settings") end)

    showTab("Keybinds")
end

-- Input binding with 4 as Back (FrameBack)
local function SetupRebindingListener()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyName = tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
            for _, guiObj in ipairs(CoreGui:GetDescendants()) do
                if guiObj:IsA("TextButton") and guiObj.Text == "Press any key..." then
                    local parent = guiObj.Parent
                    local left = parent:FindFirstChildOfClass("TextLabel")
                    if left and left.Text then
                        local action = left.Text
                        if Keybinds[action] ~= nil then
                            Keybinds[action] = keyName
                            guiObj.Text = keyName
                            guiObj.TextColor3 = Color3.fromRGB(255,255,255)
                            saveSettings()
                            print("Rebound " .. action .. " -> " .. keyName)
                            break
                        end
                    end
                end
            end
        end
    end)
end

local function SetupKeybinds()
    if KeybindsConnect then KeybindsConnect:Disconnect() end
    KeybindsConnect = UserInputService.InputBegan:Connect(function(Input, Typing)
        if Typing then return end
        if not Input.KeyCode then return end
        local KeyCodeName = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")

        -- ВНИМАНИЕ: 4-й клавишей теперь Back (GoFrameBack)
        if KeyCodeName == "Four" then
            task.spawn(FrameBackStart)
            return
        end

        if Keybinds.StartRecording and KeyCodeName == Keybinds.StartRecording then
            ToggleRecording()
            if StartStopButton then
                StartStopButton.BackgroundColor3 = Recording and Color3.fromRGB(180,40,40) or Color3.fromRGB(60,140,60)
            end
            return
        end

        if Keybinds.ToggleGUI and KeyCodeName == Keybinds.ToggleGUI then
            if HUD and MainFrame then
                MainFrame.Visible = not MainFrame.Visible
            end
            return
        end
        if KeyCodeName == Keybinds.UserPause then
            UserPauseToggle()
        elseif KeyCodeName == Keybinds.AddSavestate then
            AddSavestate()
        elseif KeyCodeName == Keybinds.RemoveSavestate then
            RemoveSavestate()
        elseif KeyCodeName == Keybinds.BackSavestate then
            BackSavestate()
        elseif KeyCodeName == Keybinds.CollisionToggler then
            CollisionToggler()
        elseif KeyCodeName == Keybinds.SaveRun then
            local ts = tostring(os.time())
            SaveTASToFile("autosave_" .. ts)
        elseif KeyCodeName == Keybinds.GoFrameForward then
            task.spawn(FrameForwardStart)
        elseif KeyCodeName == Keybinds.GoFrameBack then
            task.spawn(FrameBackStart)
        elseif KeyCodeName == Keybinds.ResetToNormal then
            DisconnectAll()
        elseif KeyCodeName == Keybinds.ViewTAS then
            if not ViewingTAS then
                 local CurrentTASData = PrepareTasData()
                 ViewTASPlayback(CurrentTASData)
            end
        end
    end)

    InputEndConnect = UserInputService.InputEnded:Connect(function(Input, Typing)
        if Typing then return end
        if not Input.KeyCode then return end
        local KeyCodeName = tostring(Input.KeyCode):gsub("Enum.KeyCode.", "")
        if KeyCodeName == "Four" then
            isFrameBackHeld = false
            return
        end
        if KeyCodeName == Keybinds.GoFrameBack then
            isFrameBackHeld = false
        elseif KeyCodeName == Keybinds.GoFrameForward then
            isFrameForwardHeld = false
        end
    end)
end

local function Initialize()
    ensureSaveFolders()
    loadSettings()

    Keybinds = Settings.Keybinds or DefaultSettings.Keybinds
    Settings.UnlockedCamera = (Settings.UnlockedCamera == true)

    Recording = false
    Pause = true
    TimePaused = 0
    PlayerInfo = {}
    Savestates = {}
    TimeStart = tick()
    TimePauseHolder = tick()

    SetUpGui()
    SetupRebindingListener()
    SetupKeybinds()

    if MainConnectionLoop then
        MainConnectionLoop:Disconnect()
        MainConnectionLoop = nil
    end
    MainConnectionLoop = RunService.Heartbeat:Connect(function(deltaTime)
        if Recording and not Pause then
            UpdateTimeGUI()
            table.insert(PlayerInfo, ReturnPlayerInfo())
            UpdateGUIText()
        else
            UpdateGUIText()
        end
    end)

    if LocalPlayer.Character then
       local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
       if Hum then
           DiedConnect = Hum.Died:Connect(function()
               task.wait(0.1)
               if Recording and not Pause then UserPauseToggle() end
               print("Character died. Attempting to respawn and go to last savestate.")
               LocalPlayer.CharacterAdded:Wait()
               task.wait(1)
               BackSavestate()
               if Recording and Pause then UserPauseToggle() end
               if not Pause then UserPauseToggle() end
           end)
       end
    end

    print("TAS Recorder loaded. Press " .. (Keybinds.StartRecording or "F7") .. " to start/stop recording.")
end

Initialize()
