-- ===== STBB Gman Hub (Poly-Style Upgrade) =====
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
local espEnabled = false
local espAllHumansEnabled = false
local autoTPEnabled = false
local autoClickEnabled = false
local speedEnabled = false
local speedValue = 16
local flyEnabled = false
local flySpeed = 50
local flyMovers = {}
local tpDelay = 0.2
local tpOffsetZ = 2
local tpOffsetY = 1
local tpMaxDist = 300
local lockedTarget = nil

local godModeEnabled = false
local autoPlayEnabled = false
local targetMission = "Hard"

-- ===== ФУНКЦИИ =====
local function getModelHRP(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model.PrimaryPart
end

local function isValidEnemy(obj)
    if not obj or not obj:IsA("Model") or not obj.Parent then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local hrp = getModelHRP(obj)
    if not hrp or hrp.Anchored or hum.WalkSpeed == 0 or hum.Health == math.huge then return false end
    local name = string.lower(obj.Name)
    return string.find(name, "toilet") or string.find(name, "skibidi")
end

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

-- Универсальный клик по кнопке (без мышки)
local function forceSignalClick(btn)
    if not btn or not btn.Visible then return false end
    pcall(function()
        if getconnections then
            local conns = getconnections(btn.MouseButton1Click)
            if conns then for _, c in pairs(conns) do c:Fire() end end
        end
        if firesignal then firesignal(btn.MouseButton1Click) end
        btn:Activate()
    end)
    return true
end

-- ===== GOD MODE LOOP =====
RunService.Heartbeat:Connect(function()
    if godModeEnabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
        end
    end
end)

-- ===== FLY LOOP =====
RunService.RenderStepped:Connect(function()
    if flyEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            hum.PlatformStand = true
            if not flyMovers.bv or not flyMovers.bv.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = hrp
                local bg = Instance.new("BodyGyro")
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
            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            flyMovers.bv.Velocity = moveDir * flySpeed
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

-- ===== TAB 1: COMBAT (GOD MODE) =====
local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Player Mods")
CombatTab:CreateToggle({ 
    Name = "God Mode (Infinite HP)", 
    CurrentValue = false, 
    Callback = function(state) 
        godModeEnabled = state 
        if not state and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = 100 hum.Health = 100 end
        end
    end 
})

CombatTab:CreateSection("Auto Skills")
local autoSkillEnabled = false
local skillDelay = 1
local activeKeys = {}
local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}
for _, keyName in ipairs(KeyList) do
    CombatTab:CreateToggle({ Name = keyName, Callback = function(state) activeKeys[keyName] = state end })
end
CombatTab:CreateSlider({ Name = "Skill Delay", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) skillDelay = v end })
CombatTab:CreateToggle({ Name = "Enable Auto Press", Callback = function(state)
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
                            pcall(function() VirtualInputManager:SendKeyEvent(true, keyCode, false, game) end)
                            task.wait(0.05)
                            pcall(function() VirtualInputManager:SendKeyEvent(false, keyCode, false, game) end)
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

-- ===== TAB 2: TELEPORT =====
local TPTab = Window:CreateTab("Teleport")
TPTab:CreateSection("Poly-Style TP")
TPTab:CreateToggle({ Name = "Enable Auto TP (Hard Lock)", Callback = function(state)
    autoTPEnabled = state
    if not state then lockedTarget = nil end
    if state then
        task.spawn(function()
            while autoTPEnabled do
                local targetHRP = getTargetEnemy()
                if targetHRP and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, tpOffsetY, tpOffsetZ)
                end
                task.wait(tpDelay)
            end
        end)
    end
end })
TPTab:CreateButton({ Name = "Force Clear Target", Callback = function() lockedTarget = nil end })
TPTab:CreateSlider({ Name = "TP Speed", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.2, Callback = function(v) tpDelay = v end })
TPTab:CreateSlider({ Name = "Max TP Distance", Range = {50, 1000}, Increment = 10, CurrentValue = 300, Callback = function(v) tpMaxDist = v end })

-- ===== TAB 3: MOVEMENT =====
local MoveTab = Window:CreateTab("Movement")
MoveTab:CreateSection("Speed Hack")
MoveTab:CreateSlider({ Name = "Speed Value", Range = {16, 400}, Increment = 1, CurrentValue = 16, Callback = function(v) speedValue = v end })
MoveTab:CreateToggle({ Name = "Enable Speed", Callback = function(state) speedEnabled = state; if not state and LocalPlayer.Character then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end end })
MoveTab:CreateSection("Fly Hack")
MoveTab:CreateSlider({ Name = "Fly Speed", Range = {16, 400}, Increment = 1, CurrentValue = 50, Callback = function(v) flySpeed = v end })
MoveTab:CreateToggle({ Name = "Enable Fly", Callback = function(state) flyEnabled = state; if not state then cleanFlyMovers() end end })

-- ===== TAB 4: VISUALS =====
local VisualsTab = Window:CreateTab("Visuals")
VisualsTab:CreateSection("Enemy ESP")
VisualsTab:CreateToggle({ Name = "Enable Enemy ESP (Red)", Callback = function(state)
    espEnabled = state
    if not state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local hl = obj:FindFirstChild("GmanESP")
            if hl then hl:Destroy() end
        end
    end
end })
task.spawn(function()
    while task.wait(0.2) do
        if espEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isValidEnemy(obj) then
                    local hl = obj:FindFirstChild("GmanESP")
                    if not hl then
                        hl = Instance.new("Highlight")
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

-- ===== TAB 5: AUTO PLAY (VOTING & READY) =====
local AutoPlayTab = Window:CreateTab("Auto Play")
AutoPlayTab:CreateSection("Mission Selection (Lobby)")

-- Дропдаун для выбора миссии
AutoPlayTab:CreateDropdown({
    Name = "Target Mission",
    Options = {"Hard", "Extreme", "Insane", "Boss Rush"},
    CurrentOption = {"Hard"},
    MultipleOptions = false,
    Flag = "MissionSelect",
    Callback = function(option)
        targetMission = option[1]
    end,
})

-- Поиск и клик по карточке выбранной миссии
AutoPlayTab:CreateButton({
    Name = "Select Mission Now",
    Callback = function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        
        local found = false
        -- Ищем кнопку, внутри которой есть текст нужной миссии
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                -- Проверяем текст внутри этой кнопки
                local hasText = false
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        if string.find(string.lower(child.Text), string.lower(targetMission)) then
                            hasText = true
                            break
                        end
                    end
                end
                
                -- Если нашли - кликаем
                if hasText and obj.Visible then
                    forceSignalClick(obj)
                    found = true
                    break
                end
            end
        end
        
        if found then
            Rayfield:Notify({Title = "Auto Play", Content = "Clicked " .. targetMission, Duration = 2})
        else
            Rayfield:Notify({Title = "Auto Play", Content = "Mission not found.", Duration = 2})
        end
    end
})

AutoPlayTab:CreateButton({
    Name = "Vote / Confirm (Bottom Button)",
    Callback = function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, obj in ipairs(pg:GetDescendants()) do
            if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible then
                local text = string.lower(obj.Text or "")
                if string.find(text, "vote") or string.find(text, "confirm") or string.find(text, "select") then
                    forceSignalClick(obj)
                    break
                end
            end
        end
    end
})

AutoPlayTab:CreateSection("AFK Ready (Character Menu)")

AutoPlayTab:CreateToggle({
    Name = "Enable Auto Play (AFK Ready)",
    CurrentValue = false,
    Callback = function(state)
        autoPlayEnabled = state
        if state then
            task.spawn(function()
                while autoPlayEnabled do
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    if pg then
                        -- Жмем UNREADY / CONTINUE
                        local chrGui = pg:FindFirstChild("ChrGUI")
                        if chrGui and chrGui:FindFirstChild("Frame-Ready") then
                            local btn = chrGui["Frame-Ready"]:FindFirstChild("Menu") and chrGui["Frame-Ready"]["Menu"]:FindFirstChild("Ready") and chrGui["Frame-Ready"]["Menu"]["Ready"]:FindFirstChild("Button")
                            if btn and btn.Visible then forceSignalClick(btn) end
                        end
                        
                        local modeResult = pg:FindFirstChild("ModeResult")
                        if modeResult and modeResult:FindFirstChild("Root") then
                            local btn = modeResult["Root"]:FindFirstChild("Holder") and modeResult["Root"]["Holder"]:FindFirstChild("Content") and modeResult["Root"]["Holder"]["Content"]:FindFirstChild("Footer") and modeResult["Root"]["Holder"]["Content"]["Footer"]:FindFirstChild("Continue")
                            if btn and btn.Visible then forceSignalClick(btn) end
                        end
                        
                        -- Жмем NEXT / REPLAY
                        for _, gui in ipairs(pg:GetDescendants()) do
                            if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                                local text = string.lower(gui.Text or "")
                                if string.find(text, "next") or string.find(text, "replay") or string.find(text, "lets go") then
                                    forceSignalClick(gui)
                                end
                            end
                        end
                    end
                    task.wait(1.5)
                end
            end)
        end
    end
})

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)
