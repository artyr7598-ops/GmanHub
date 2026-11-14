-- ===== Gman Hub (Ultimate Vais Edition) =====
getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Gman Hub (STBB)",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Gman",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K"
})

-- ===== VARIABLES =====
local espEnabled = false
local autoTPEnabled = false
local speedEnabled = false
local speedValue = 16
local flyEnabled = false
local flySpeed = 50
local flyMovers = {}
local tpDelay = 0.2
local tpOffsetZ = 4

-- GOD MODE
local autoResetEnabled = false
local resetPercent = 80

-- AUTO PLAY & VOTE
local autoReadyEnabled = false
local autoVoteEnabled = false
local selectedVoteMode = "Average" -- По умолчанию
local cachedZone = nil

-- ===== UTILS =====
local function cleanFlyMovers()
    if flyMovers.bv then flyMovers.bv:Destroy() end
    if flyMovers.bg then flyMovers.bg:Destroy() end
    flyMovers = {}
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.WalkSpeed = speedEnabled and speedValue or 16
        end
    end
end

-- ===== ЛОГИКА ПОИСКА ВРАГОВ (ИЗ VAISHUB) =====
local function getTargetEnemy()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end

    local living = workspace:FindFirstChild("Living")
    if not living then return nil end

    local closest = nil
    local shortestDist = math.huge
    local myPos = myChar.HumanoidRootPart.Position

    for _, m in pairs(living:GetChildren()) do
        if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("AI") and m:FindFirstChild("HumanoidRootPart") then
            local dist = (m.HumanoidRootPart.Position - myPos).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                closest = m
            end
        end
    end
    return closest
end

-- ===== GOD MODE LOOP =====
RunService.Heartbeat:Connect(function()
    if autoResetEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            local threshold = hum.MaxHealth * (resetPercent / 100)
            if hum.Health <= threshold then
                pcall(function() LocalPlayer.Character:BreakJoints() end)
            end
        end
    end
end)

-- ===== FLY LOOP (ИСПРАВЛЕННЫЙ) =====
RunService.RenderStepped:Connect(function()
    if flyEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            -- Пауза ТОЛЬКО если игра реально заякорила персонажа на скилл
            if hrp.Anchored then
                if flyMovers.bv then flyMovers.bv.Velocity = Vector3.new(0,0,0) end
                return
            end

            hum.PlatformStand = true
            if not flyMovers.bv or not flyMovers.bv.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                bv.Parent = hrp
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                bg.P = 10000; bg.D = 500
                bg.Parent = hrp
                flyMovers.bv = bv; flyMovers.bg = bg
            end
            
            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            
            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
                flyMovers.bv.Velocity = moveDir * flySpeed
            else
                flyMovers.bv.Velocity = Vector3.new(0,0,0)
            end
            flyMovers.bg.CFrame = cam.CFrame
        end
    end
end)

-- ===== SPEED LOOP =====
RunService.Heartbeat:Connect(function()
    if speedEnabled and LocalPlayer.Character and not flyEnabled then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= speedValue then hum.WalkSpeed = speedValue end
    end
end)

-- ===== ESP LOOP =====
task.spawn(function()
    while task.wait(0.5) do
        if espEnabled then
            local living = workspace:FindFirstChild("Living")
            if living then
                for _, m in ipairs(living:GetChildren()) do
                    if m:FindFirstChild("Humanoid") and m.Humanoid.Health > 0 and m:FindFirstChild("AI") then
                        local hl = m:FindFirstChild("GmanESP")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "GmanESP"
                            hl.Adornee = m
                            hl.FillColor = Color3.fromRGB(255, 0, 0)
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.FillTransparency = 0.5
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                            hl.Parent = m
                        end
                    end
                end
            end
        else
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("GmanESP")
                if hl then hl:Destroy() end
            end
        end
    end
end)

-- ===== AUTO READY (ZONE) =====
task.spawn(function()
    while task.wait(2) do
        if autoReadyEnabled and (not cachedZone or not cachedZone:IsDescendantOf(workspace)) then
            cachedZone = nil
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and (string.find(string.lower(v.Name), "ready") or string.find(string.lower(v.Name), "zone")) then
                    cachedZone = v; break
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.3) do
        if autoReadyEnabled and cachedZone and cachedZone:IsDescendantOf(workspace) then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (cachedZone.Position - hrp.Position).Magnitude <= 150 then
                task.wait(5)
                if autoReadyEnabled and cachedZone and cachedZone:IsDescendantOf(workspace) then
                    local currentHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if currentHrp then
                        local angle = math.random() * math.pi * 2
                        currentHrp.CFrame = CFrame.new(cachedZone.Position + Vector3.new(math.cos(angle)*3, 3, math.sin(angle)*3))
                        task.wait(4)
                    end
                end
            end
        end
    end
end)

-- ===== AUTO VOTE (УМНЫЙ ПОИСК КАРТОЧЕК) =====
task.spawn(function()
    while task.wait(0.5) do
        if autoVoteEnabled then
            -- 1. Пытаемся отправить напрямую на сервер
            pcall(function()
                local voteEvent = ReplicatedStorage:FindFirstChild("Vote")
                if voteEvent then voteEvent:FireServer(selectedVoteMode) end
            end)

            -- 2. Кликаем по карточке в интерфейсе (поиск по тексту внутри карточек)
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                local playGui = pg:FindFirstChild("Play")
                if playGui and playGui:FindFirstChild("Main") and playGui.Main.Visible then
                    for _, obj in ipairs(playGui:GetDescendants()) do
                        -- Ищем Label с нужным текстом
                        if obj:IsA("TextLabel") and string.find(string.lower(obj.Text), string.lower(selectedVoteMode)) then
                            local parent = obj.Parent
                            -- Если родитель - карточка (ImageButton/TextButton) или ImageLabel
                            if parent:IsA("ImageButton") or parent:IsA("TextButton") or parent:IsA("ImageLabel") then
                                local clickable = parent
                                -- Если это ImageLabel, возможно кнопка внутри или родитель родителя
                                if parent:IsA("ImageLabel") then
                                    local btn = parent:FindFirstChildWhichIsA("TextButton") or parent:FindFirstChildWhichIsA("ImageButton")
                                    if btn then clickable = btn end
                                end
                                
                                if clickable then
                                    pcall(function()
                                        if firesignal then firesignal(clickable.MouseButton1Click) end
                                        if clickable.Activate then clickable:Activate() end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ===== TABS =====
local TPTab = Window:CreateTab("Teleport")
TPTab:CreateSection("Auto Farm TP")
TPTab:CreateToggle({ Name = "Enable Auto TP", Callback = function(state)
    autoTPEnabled = state
    if state then
        task.spawn(function()
            while autoTPEnabled do
                local target = getTargetEnemy()
                if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, tpOffsetZ)
                end
                task.wait(tpDelay)
            end
        end)
    end
end })
TPTab:CreateSlider({ Name = "TP Speed", Range = {0.1, 1}, Increment = 0.1, CurrentValue = 0.2, Callback = function(v) tpDelay = v end })
TPTab:CreateSlider({ Name = "Distance (Behind)", Range = {0, 10}, Increment = 1, CurrentValue = 4, Callback = function(v) tpOffsetZ = v end })

local MoveTab = Window:CreateTab("Movement")
MoveTab:CreateSection("Speed")
MoveTab:CreateSlider({ Name = "Speed", Range = {16, 400}, Increment = 1, CurrentValue = 16, Callback = function(v) speedValue = v end })
MoveTab:CreateToggle({ Name = "Enable Speed", Callback = function(state) speedEnabled = state; if not state and LocalPlayer.Character then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end end })
MoveTab:CreateSection("Fly")
MoveTab:CreateSlider({ Name = "Fly Speed", Range = {16, 400}, Increment = 1, CurrentValue = 50, Callback = function(v) flySpeed = v end })
MoveTab:CreateToggle({ Name = "Enable Fly", Callback = function(state) flyEnabled = state; if not state then cleanFlyMovers() end end })

local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Auto Reset God Mode")
CombatTab:CreateToggle({ Name = "Enable God Mode", CurrentValue = false, Callback = function(state) autoResetEnabled = state end })
CombatTab:CreateSlider({ Name = "Reset at HP (%)", Range = {5, 100}, Increment = 1, CurrentValue = 80, Callback = function(v) resetPercent = v end })

CombatTab:CreateSection("Auto Skills")
local autoSkillEnabled = false
local activeKeys = {}
local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}
for _, k in ipairs(KeyList) do CombatTab:CreateToggle({ Name = k, Callback = function(s) activeKeys[k] = s end }) end
local skillDelay = 1
CombatTab:CreateSlider({ Name = "Skill Delay", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) skillDelay = v end })
CombatTab:CreateToggle({ Name = "Enable Auto Skills", Callback = function(state)
    autoSkillEnabled = state
    if state then
        task.spawn(function()
            while autoSkillEnabled do
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if char and hum and hum.Health > 0 then
                    for _, k in ipairs(KeyList) do
                        if activeKeys[k] then
                            pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game) end)
                            task.wait(0.05)
                            pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game) end)
                            task.wait(0.05)
                        end
                    end
                end
                task.wait(skillDelay)
            end
        end)
    end
end })

CombatTab:CreateSection("Auto Clicker")
local autoClickEnabled = false
local clickDelay = 0.1
CombatTab:CreateSlider({ Name = "Click Delay", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.1, Callback = function(v) clickDelay = v end })
CombatTab:CreateToggle({ Name = "Enable Auto Click", Callback = function(state)
    autoClickEnabled = state
    if state then
        task.spawn(function()
            while autoClickEnabled do
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end)
                task.wait(clickDelay)
            end
        end)
    end
end })

local VisualsTab = Window:CreateTab("Visuals")
VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({ Name = "Enable Enemy ESP", Callback = function(state) espEnabled = state end })

local AutoPlayTab = Window:CreateTab("Auto Play")
AutoPlayTab:CreateSection("Auto Ready (Zone)")
AutoPlayTab:CreateToggle({ Name = "Enable Auto Ready", Callback = function(state) autoReadyEnabled = state end })

AutoPlayTab:CreateSection("Auto Vote (Select Mode)")
AutoPlayTab:CreateDropdown({
    Name = "Select Vote Mode",
    Options = {
        "Average", "Hard", "Extreme", "Insane", "Nightmare", 
        "Boss Rush", "In The Mist", "Zombie Act 1", "Christmas", "Hell", 
        "Dark Dimension", "The Invasion", "Invasion Holdout", "Zombie Act 2", 
        "Battle Armor Act 1", "Soundwave", "Halloween"
    },
    CurrentOption = {"Average"},
    MultipleOptions = false,
    Callback = function(option) selectedVoteMode = option[1] end,
})
AutoPlayTab:CreateToggle({ Name = "Enable Auto Vote", Callback = function(state) autoVoteEnabled = state end })

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

Rayfield:Notify({ Title = "Gman Hub", Content = "All Modes Added. Fly Fixed.", Duration = 5 })
