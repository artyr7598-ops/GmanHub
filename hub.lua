-- ===== Gman Hub (Full Ultimate + Fixed Auto Play) =====
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
local espAllEnabled = false
local autoTPEnabled = false
local speedEnabled = false
local speedValue = 16
local flyEnabled = false
local flySpeed = 50
local flyMovers = {}
local tpDelay = 0.2
local tpOffsetY = 3
local tpOffsetZ = 2
local tpMaxDist = 300
local lockedTarget = nil

-- GOD MODE
local autoResetEnabled = false
local resetPercent = 80

-- AUTO PLAY
local autoReadyEnabled = false
local autoDifficultyEnabled = false
local selectedDifficulty = "Hard"

-- ===== UTILS =====
local function getModelHRP(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Head") or model.PrimaryPart
end

local function isValidEnemy(obj)
    if not obj or not obj:IsA("Model") or not obj.Parent then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(obj) then return false end
    local hrp = getModelHRP(obj)
    if not hrp or hrp.Anchored or hum.WalkSpeed == 0 or hum.Health == math.huge then return false end
    
    local name = string.lower(obj.Name)
    local bad = {"cutscene", "utcm", "scientist", "helicopter", "shop", "quest", "base", "core", "door", "wall", "turret", "seller", "giver", "dummy", "statue"}
    for _, b in ipairs(bad) do
        if string.find(name, b) then return false end
    end
    if string.find(name, "toilet") or string.find(name, "skibidi") or string.find(name, "mutant") or string.find(name, "speaker") or string.find(name, "camera") then
        return true
    end
    return false
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

local function forceClickUI(btn)
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

-- ===== FLY LOOP =====
RunService.RenderStepped:Connect(function()
    if flyEnabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            local state = hum:GetState()
            local isCasting = (state == Enum.HumanoidStateType.Attacking) or (state == Enum.HumanoidStateType.Action) or (state == Enum.HumanoidStateType.Physics) or hrp.Anchored
            if isCasting then
                if flyMovers.bv then flyMovers.bv.Velocity = Vector3.new(0,0,0) end
                return
            end

            hum.PlatformStand = true
            if not flyMovers.bv or not flyMovers.bv.Parent then
                local bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bv.Parent = hrp
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
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

-- ===== ESP LOOP =====
task.spawn(function()
    while task.wait(0.5) do
        if espEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isValidEnemy(obj) then
                    local hl = obj:FindFirstChild("GmanESP")
                    local isTarget = (lockedTarget == obj)
                    local color = isTarget and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "GmanESP"
                        hl.Adornee = obj
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = obj
                    end
                    hl.FillColor = color
                end
            end
        end
        if espAllEnabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj ~= LocalPlayer.Character then
                    if not obj:FindFirstChild("GmanAllESP") and not obj:FindFirstChild("GmanESP") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "GmanAllESP"
                        hl.Adornee = obj
                        hl.FillColor = Color3.fromRGB(0, 150, 255)
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

-- ===== AUTO PLAY LOGIC (FIXED) =====
task.spawn(function()
    while task.wait(1.5) do
        if autoReadyEnabled then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                -- 1. Жмем Ready (UNREADY) в меню выбора персонажа
                local chrGui = pg:FindFirstChild("ChrGUI")
                if chrGui and chrGui:FindFirstChild("Frame-Ready") then
                    local btn = chrGui["Frame-Ready"]:FindFirstChild("Menu") and chrGui["Frame-Ready"]["Menu"]:FindFirstChild("Ready") and chrGui["Frame-Ready"]["Menu"]["Ready"]:FindFirstChild("Button")
                    if btn and btn.Visible then 
                        forceClickUI(btn) 
                    end
                end
                
                -- 2. Жмем Continue (после выбора титана/сложности)
                local modeResult = pg:FindFirstChild("ModeResult")
                if modeResult and modeResult:FindFirstChild("Root") then
                    local btn = modeResult["Root"]:FindFirstChild("Holder") and modeResult["Root"]["Holder"]:FindFirstChild("Content") and modeResult["Root"]["Holder"]["Content"]:FindFirstChild("Footer") and modeResult["Root"]["Holder"]["Content"]["Footer"]:FindFirstChild("Continue")
                    if btn and btn.Visible then 
                        forceClickUI(btn) 
                    end
                end
                
                -- 3. Жмем Next / Replay (после волны)
                for _, gui in ipairs(pg:GetDescendants()) do
                    if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                        local text = string.lower(gui.Text or "")
                        local lbl = gui:FindFirstChildWhichIsA("TextLabel")
                        if lbl then text = text .. " " .. string.lower(lbl.Text or "") end
                        
                        if string.find(text, "next") or string.find(text, "replay") or string.find(text, "lets go") then
                            -- Исключаем кнопки сложности, чтобы не нажать их случайно
                            if not string.find(text, "hard") and not string.find(text, "insane") then
                                forceClickUI(gui)
                                break
                            end
                        end
                    end
                end
            end
        end
        
        if autoDifficultyEnabled then
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _, gui in ipairs(pg:GetDescendants()) do
                    if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
                        local text = string.lower(gui.Text or "")
                        local lbl = gui:FindFirstChildWhichIsA("TextLabel")
                        if lbl then text = text .. " " .. string.lower(lbl.Text or "") end
                        
                        -- Ищем точное совпадение с выбранной сложностью
                        if string.find(text, string.lower(selectedDifficulty)) then
                            forceClickUI(gui)
                            task.wait(1.5) -- Пауза, чтобы не спамить
                        end
                    end
                end
            end
        end
    end
end)

-- ===== TARGET LOCK LOGIC =====
local function getTargetEnemy()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    if lockedTarget and lockedTarget.Parent then
        local hum = lockedTarget:FindFirstChildOfClass("Humanoid")
        local hrp = getModelHRP(lockedTarget)
        if hum and hum.Health > 0 and hrp and not hrp.Anchored and (hrp.Position - myPos).Magnitude <= tpMaxDist then 
            return hrp 
        else 
            lockedTarget = nil 
        end
    end
    local closest = nil
    local shortestDist = math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isValidEnemy(obj) then
            local hrp = getModelHRP(obj)
            if hrp then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < shortestDist and dist <= tpMaxDist then
                    shortestDist = dist
                    closest = obj
                end
            end
        end
    end
    if closest then lockedTarget = closest; return getModelHRP(closest) end
    return nil
end

-- ===== TABS =====
local TPTab = Window:CreateTab("Teleport")
TPTab:CreateSection("Hard Lock TP")
TPTab:CreateToggle({ Name = "Enable Auto TP", Callback = function(state)
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
TPTab:CreateButton({ Name = "Clear Target", Callback = function() lockedTarget = nil end })
TPTab:CreateSlider({ Name = "TP Speed", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.2, Callback = function(v) tpDelay = v end })
TPTab:CreateSlider({ Name = "Max TP Distance", Range = {50, 1000}, Increment = 10, CurrentValue = 300, Callback = function(v) tpMaxDist = v end })
TPTab:CreateSlider({ Name = "Offset Y (Height)", Range = {0, 10}, Increment = 1, CurrentValue = 3, Callback = function(v) tpOffsetY = v end })
TPTab:CreateSlider({ Name = "Offset Z (Behind)", Range = {0, 10}, Increment = 1, CurrentValue = 2, Callback = function(v) tpOffsetZ = v end })

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
VisualsTab:CreateToggle({ Name = "Enable Enemy ESP", Callback = function(state) 
    espEnabled = state 
    if not state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local hl = obj:FindFirstChild("GmanESP")
            if hl then hl:Destroy() end
        end
    end
end })
VisualsTab:CreateToggle({ Name = "Enable All Humanoids ESP", Callback = function(state) 
    espAllEnabled = state 
    if not state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local hl = obj:FindFirstChild("GmanAllESP")
            if hl then hl:Destroy() end
        end
    end
end })
VisualsTab:CreateSection("Debug (F9)")
VisualsTab:CreateButton({
    Name = "Print All Humanoids to F9",
    Callback = function()
        print("=== SCANNING ALL HUMANOIDS ===")
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local hrp = getModelHRP(obj)
                local isPlayer = Players:GetPlayerFromCharacter(obj) ~= nil
                local isEnemy = isValidEnemy(obj)
                print(string.format("[%s] | HP: %s | Anchored: %s | Player: %s | IsEnemy: %s", obj.Name, tostring(hum.Health), tostring(hrp and hrp.Anchored or "NoHRP"), tostring(isPlayer), tostring(isEnemy)))
            end
        end
        Rayfield:Notify({Title = "Debug", Content = "Check F9 Console!", Duration = 4})
    end
})

local AutoPlayTab = Window:CreateTab("Auto Play")
AutoPlayTab:CreateSection("UI Clicker")
AutoPlayTab:CreateToggle({ Name = "Enable Auto Ready / Next", Callback = function(state) autoReadyEnabled = state end })
AutoPlayTab:CreateSection("Auto Difficulty")
AutoPlayTab:CreateDropdown({
    Name = "Select Difficulty",
    Options = {"Hard", "Extreme", "Insane", "Boss Rush"},
    CurrentOption = {"Hard"},
    MultipleOptions = false,
    Callback = function(option) selectedDifficulty = option[1] end,
})
AutoPlayTab:CreateToggle({ Name = "Enable Auto Difficulty", Callback = function(state) autoDifficultyEnabled = state end })

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

Rayfield:Notify({ Title = "Gman Hub", Content = "Ultimate Loaded. Press K.", Duration = 5 })
