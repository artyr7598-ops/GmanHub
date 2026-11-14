-- ===== Gman Hub (Auto Reset 100%) =====
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
local autoTPEnabled = false
local speedEnabled = false
local speedValue = 16
local flyEnabled = false
local flySpeed = 50
local flyMovers = {}
local tpDelay = 0.2
local tpOffsetY = 3
local tpMaxDist = 300
local lockedTarget = nil

-- GOD MODE
local autoResetEnabled = false
local resetPercent = 80 -- По умолчанию 80

-- AUTO PLAY
local autoReadyEnabled = false
local cachedZone = nil

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

-- ===== GOD MODE (AUTO RESET) =====
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

-- ===== TARGET LOCK =====
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
                    LocalPlayer.Character.HumanoidRootPart.CFrame = targetHRP.CFrame * CFrame.new(0, tpOffsetY, 0)
                end
                task.wait(tpDelay)
            end
        end)
    end
end })
TPTab:CreateButton({ Name = "Clear Target", Callback = function() lockedTarget = nil end })
TPTab:CreateSlider({ Name = "TP Speed", Range = {0.05, 1}, Increment = 0.05, CurrentValue = 0.2, Callback = function(v) tpDelay = v end })
TPTab:CreateSlider({ Name = "Max TP Distance", Range = {50, 1000}, Increment = 10, CurrentValue = 300, Callback = function(v) tpMaxDist = v end })

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

-- ТУТ ТЕПЕРЬ ДО 100%
CombatTab:CreateSlider({ Name = "Reset at HP (%)", Range = {5, 100}, Increment = 1, CurrentValue = 80, Callback = function(v) resetPercent = v end })

CombatTab:CreateSection("Auto Skills")
local autoSkillEnabled = false
local activeKeys = {}
local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}
for _, k in ipairs(KeyList) do CombatTab:CreateToggle({ Name = k, Callback = function(s) activeKeys[k] = s end }) end
CombatTab:CreateSlider({ Name = "Skill Delay", Range = {0.1, 5}, Increment = 0.1, CurrentValue = 1, Callback = function(v) skillDelay = v end })
CombatTab:CreateToggle({ Name = "Enable Auto Skills", Callback = function(state)
    autoSkillEnabled = state
    if state then
        task.spawn(function()
            while autoSkillEnabled do
                for _, k in ipairs(KeyList) do
                    if activeKeys[k] then
                        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[k], false, game) end)
                        task.wait(0.05)
                        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[k], false, game) end)
                        task.wait(0.05)
                    end
                end
                task.wait(skillDelay or 1)
            end
        end)
    end
end })

local AutoPlayTab = Window:CreateTab("Auto Play")
AutoPlayTab:CreateSection("Auto Ready (Zone)")
AutoPlayTab:CreateToggle({ Name = "Enable Auto Ready", Callback = function(state) autoReadyEnabled = state end })

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

Rayfield:Notify({ Title = "Gman Hub", Content = "Loaded. Press K to open.", Duration = 5 })
