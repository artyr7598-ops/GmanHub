-- ===== STBB Gman Hub (Toggle Auto Skills) =====
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

-- ===== TAB 1: HUNTER =====
local HunterTab = Window:CreateTab("Hunter")
HunterTab:CreateSection("Rare NPC Hunter")

local isDetecting = false
local keyword = "agent"
local doTeleport = false

HunterTab:CreateInput({
    Name = "NPC Name (keyword)",
    PlaceholderText = "agent, secret, case",
    RemoveTextAfterFocusLost = false,
    Flag = "NPCKeyword",
    Callback = function(text)
        if text ~= "" then keyword = string.lower(text) end
    end
})

HunterTab:CreateToggle({
    Name = "Teleport to NPC",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(state) doTeleport = state end
})

HunterTab:CreateToggle({
    Name = "Enable Detector",
    CurrentValue = false,
    Flag = "DetectorToggle",
    Callback = function(state)
        isDetecting = state
        if state then
            Rayfield:Notify({Title = "Searching", Content = "Scanning for '"..keyword.."'...", Duration = 3})
        end
    end
})

Workspace.DescendantAdded:Connect(function(obj)
    if not isDetecting then return end
    if obj:IsA("Model") and string.find(string.lower(obj.Name), keyword) then
        if obj:FindFirstChild("Humanoid") then
            if not obj:FindFirstChild("HunterHighlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "HunterHighlight"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = obj
            end
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://138078392"
            sound.Volume = 10
            sound.Parent = game.SoundService
            sound:Play()

            Rayfield:Notify({Title = "🚨 FOUND!", Content = obj.Name .. " spawned!", Duration = 10})
            if doTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = obj:GetPivot() + Vector3.new(0, 5, 0)
            end
        end
    end
end)

-- ===== TAB 2: COMBAT =====
local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateSection("Auto Skills (Toggles)")

local autoSkillEnabled = false
local skillDelay = 1
local activeKeys = {}

-- List of available keys to toggle
local KeyList = {"Q", "E", "R", "T", "Y", "F", "G", "H", "Z", "X", "C", "V", "B", "Space"}

-- Create a toggle for each key
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
                        -- Loop through all keys and press the active ones
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

Rayfield:Notify({
    Title = "Gman Hub",
    Content = "Script loaded. Press K for menu.",
    Duration = 5
})
