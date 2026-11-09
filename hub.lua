-- ===== STBB Gman Hub (Fly Fixed) =====
getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Gman Hub (STBB)",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Gman",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K"
})

-- ===== VARIABLES =====
local enemyNames = {"toilet", "skibidi", "speaker", "camera", "mutant", "brute", "titan"}
local badNames = {"npc", "helicopter", "heli", "scientist", "civilian", "worker", "shop", "quest", "turret", "base", "core", "door", "vehicle", "car", "truck", "seller", "giver", "cutscene", "utcm", "dummy", "statue", "lobby", "mannequin", "display", "test"}

local espEnabled = false
local autoTPEnabled = false
local autoClickEnabled = false

local speedEnabled = false
local speedValue = 16
local flyEnabled = false
local flySpeed = 50
local flyMovers = {}

local function isValidEnemy(obj)
    if not obj:IsA("Model") then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local hrp = obj:FindFirstChild("HumanoidRootPart")
    if not hrp or hrp.Anchored then return false end
    if hum.Health == math.huge or hum.MaxHealth == math.huge then return false end
    
    local name = string.lower(obj.Name)
    for _, bad in ipairs(badNames) do
        if string.find(name, bad) then return false end
    end
    for _, enemyWord in ipairs(enemyNames) do
        if string.find(name, enemyWord) then return true end
    end
    return false
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isSafeToTeleport(targetPos)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position
    if (targetPos - myPos).Magnitude > 1500 then return false end
    if targetPos.Y < Workspace.FallenPartsDestroyHeight + 50 then return false end
    local result = Workspace:Raycast(targetPos + Vector3.new(0, 10, 0), Vector3.new(0, -50, 0), rayParams)
    if result then return true else return false end
end

-- ===== СБРОС ФЛАЯ =====
local function cleanFlyMovers()
    if flyMovers.bv then flyMovers.bv:Destroy() end
    if flyMovers.bg then flyMovers.bg:Destroy() end
    flyMovers = {}
    
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            if speedEnabled then
                hum.WalkSpeed = speedValue
            else
                hum.WalkSpeed = 16
            end
        end
    end
end

-- ===== ПОЛЕТ (СТАБИЛЬНЫЙ) =====
RunService.RenderStepped:Connect(function()
    -- Фикс камеры при ТП
    if autoTPEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local cam = Workspace.CurrentCamera
        if (cam.CFrame.Position - hrp.Position).Magnitude > 35 then
            local rot = cam.CFrame - cam.CFrame.Position
            cam.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 8, 30)) * rot
        end
    end

    if flyEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        if hrp and hum then
            hum.PlatformStand = true

            -- Создаем физику, если ее нет (без сброса настроек)
            if not flyMovers.bv or not flyMovers.bv.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "GmanFlyBV"
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = hrp
                
                local bg = Instance.new("BodyGyro")
                bg.Name = "GmanFlyBG"
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                bg.P = 10000
                bg.D = 500
                bg.Parent = hrp
                
                flyMovers.bv = bv
                flyMovers.bg = bg
            end

            local cam = Workspace.CurrentCamera
            local moveDir = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end

            if moveDir.Magnitude > 0 then
                moveDir = moveDir.Unit
            end

            -- Если игра заякорила тебя для скилла, BodyVelocity просто не сработает, и ты зависнешь на анимацию. 
            -- Как только скилл закончится, полет мгновенно продолжится.
            flyMovers.bv.Velocity = moveDir * flySpeed
            flyMovers.bg.CFrame = cam.CFrame
        end
    end
end)

-- ===== ПОСТОЯННАЯ СКОРОСТЬ =====
RunService.Heartbeat:Connect(function()
    if speedEnabled and LocalPlayer.Character and not flyEnabled then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= speedValue then
            hum.WalkSpeed = speedValue
        end
    end
end)

-- ===== TAB 1: MOVEMENT =====
local MoveTab = Window:CreateTab("Movement")
MoveTab:CreateSection("Speed Hack")

MoveTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 400}, Increment = 1, Suffix = " studs/s", CurrentValue = 16, Flag = "SpeedValue",
    Callback = function(value) speedValue = value end,
})

MoveTab:CreateToggle({
    Name = "Enable Speed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(state)
        speedEnabled = state
        if not state and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

MoveTab:CreateSection("Fly Hack")

MoveTab:CreateSlider({
    Name = "Fly Speed",
    Range = {16, 400}, Increment = 1, Suffix = " studs/s", CurrentValue = 50, Flag = "FlySpeed",
    Callback = function(value) flySpeed = value end,
})

MoveTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(state)
        flyEnabled = state
        if not state then cleanFlyMovers() end
    end,
})

-- ===== TAB 2: TELEPORT =====
local TPTab = Window:CreateTab("Teleport")
TPTab:CreateSection("Enemy Teleport")

local tpDelay = 0.5

local function getClosestEnemy()
    local closest = nil
    local shortestDist = math.huge
    local myChar = LocalPlayer.Character
    
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidEnemy(obj) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < shortestDist and isSafeToTeleport(hrp.Position) then
                    shortestDist = dist
                    closest = hrp
                end
            end
        end
    end
    return closest
end

TPTab:CreateToggle({
    Name = "Enable Safe Auto TP",
    CurrentValue = false,
    Flag = "AutoTPToggle",
    Callback = function(state)
        autoTPEnabled = state
        if state then
            task.spawn(function()
                while autoTPEnabled do
                    local target = getClosestEnemy()
                    if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 3, 2)
                    end
                    task.wait(tpDelay)
                end
            end)
        end
    end
})

TPTab:CreateSlider({
    Name = "Auto TP Delay (seconds)",
    Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 0.5, Flag = "TPDelay",
    Callback = function(value) tpDelay = value end,
})

-- ===== TAB 3: VISUALS =====
local VisualsTab = Window:CreateTab("Visuals")
VisualsTab:CreateSection("Enemy ESP")

VisualsTab:CreateToggle({
    Name = "Enable Enemy ESP",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(state)
        espEnabled = state
        if not state then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local hl = obj:FindFirstChild("GmanESP")
                if hl then hl:Destroy() end
            end
        end
    end,
})

task.spawn(function()
    while task.wait(1) do
        if espEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isValidEnemy(obj) then
                    if not obj:FindFirstChild("GmanESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "GmanESP"
                        hl.Adornee = obj
                        hl.FillColor = Color3.fromRGB(255, 0, 0)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = obj
                    end
                end
            end
        end
    end
end)

-- ===== TAB 4: COMBAT =====
local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Auto Skills")

local autoSkillEnabled = false
local skillDelay = 1
local activeKeys = {}
local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}

for _, keyName in ipairs(KeyList) do
    CombatTab:CreateToggle({
        Name = keyName,
        CurrentValue = false,
        Flag = keyName .. "KeyToggle",
        Callback = function(state) activeKeys[keyName] = state end,
    })
end

CombatTab:CreateSlider({
    Name = "Skill Delay (seconds)",
    Range = {0.1, 5}, Increment = 0.1, Suffix = "s", CurrentValue = 1, Flag = "SkillDelay",
    Callback = function(value) skillDelay = value end,
})

CombatTab:CreateToggle({
    Name = "Enable Auto Press",
    CurrentValue = false,
    Flag = "AutoSkillToggle",
    Callback = function(state)
        autoSkillEnabled = state
        if state then
            task.spawn(function()
                while autoSkillEnabled do
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if char and hum and hum.Health > 0 then
                        for _, keyName in ipairs(KeyList) do
                            if activeKeys[keyName] then
                                local keyCode = Enum.KeyCode[keyName]
                                if keyCode then
                                    pcall(function() VirtualInputManager:SendKeyEvent(true, keyCode, false, game) end)
                                    task.wait(0.05)
                                    pcall(function() VirtualInputManager:SendKeyEvent(false, keyCode, false, game) end)
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                    task.wait(skillDelay)
                end
            end)
        end
    end
})

CombatTab:CreateSection("Auto Clicker")
local clickDelay = 0.1

CombatTab:CreateSlider({
    Name = "Click Delay (seconds)",
    Range = {0.05, 1}, Increment = 0.05, Suffix = "s", CurrentValue = 0.1, Flag = "ClickDelay",
    Callback = function(value) clickDelay = value end,
})

CombatTab:CreateToggle({
    Name = "Enable Auto Click (LMB)",
    CurrentValue = false,
    Flag = "AutoClickToggle",
    Callback = function(state)
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
    end
})

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

Rayfield:Notify({
    Title = "Gman Hub",
    Content = "Fly Fixed. Press K for menu.",
    Duration = 5
})
