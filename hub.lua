-- ===== STBB Gman Hub (Combat & Teleport) =====
getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Gman Hub (STBB)",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Gman",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K"
})

-- ===== TAB 1: COMBAT =====
local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Auto Skills (Toggles)")

local autoSkillEnabled = false
local skillDelay = 1
local activeKeys = {}

local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}

for _, keyName in ipairs(KeyList) do
    CombatTab:CreateToggle({
        Name = keyName,
        CurrentValue = false,
        Flag = keyName .. "KeyToggle",
        Callback = function(state)
            activeKeys[keyName] = state
        end
    })
end

CombatTab:CreateSection("Settings")

CombatTab:CreateSlider({
    Name = "Delay between presses (seconds)",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "SkillDelay",
    Callback = function(value)
        skillDelay = value
    end,
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
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                                    end)
                                    task.wait(0.05)
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                                    end)
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


-- ===== TAB 2: TELEPORT =====
local TPTab = Window:CreateTab("Teleport")
TPTab:CreateSection("Enemy Teleport")

local autoTPEnabled = false
local tpDelay = 1

-- Function to find the closest enemy
local function getClosestEnemy()
    local closest = nil
    local shortestDist = math.huge
    local myChar = LocalPlayer.Character
    
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            
            -- Check if it's an NPC (has Humanoid, alive, and is not a player)
            if hum and hrp and hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local dist = (hrp.Position - myPos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = hrp
                end
            end
        end
    end
    return closest
end

-- Manual TP Button
TPTab:CreateButton({
    Name = "Teleport to Closest Enemy",
    Callback = function()
        local target = getClosestEnemy()
        if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 2)
            Rayfield:Notify({Title = "Teleported", Content = "Moved to closest enemy.", Duration = 2})
        else
            Rayfield:Notify({Title = "Error", Content = "No enemies found nearby.", Duration = 2})
        end
    end
})

TPTab:CreateSlider({
    Name = "Auto TP Delay (seconds)",
    Range = {0.5, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "TPDelay",
    Callback = function(value)
        tpDelay = value
    end,
})

-- Auto TP Toggle
TPTab:CreateToggle({
    Name = "Enable Auto TP to Closest Enemy",
    CurrentValue = false,
    Flag = "AutoTPToggle",
    Callback = function(state)
        autoTPEnabled = state
        
        if state then
            task.spawn(function()
                while autoTPEnabled do
                    local target = getClosestEnemy()
                    if target and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 2)
                    end
                    task.wait(tpDelay)
                end
            end)
        end
    end
})

Rayfield:Notify({
    Title = "Gman Hub",
    Content = "Script loaded. Press K for menu.",
    Duration = 5
})
