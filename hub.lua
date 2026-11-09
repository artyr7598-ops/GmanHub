-- ===== STBB NPC Hunter Hub =====
getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Rayfield:CreateWindow({
    Name = "Gman Hub (STBB)",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Gman",
    Theme = "AmberGlow",
    ToggleUIKeybind = "K"
})

local MainTab = Window:CreateTab("Hunter")
local SettingsSection = MainTab:CreateSection("Rare NPC Hunter")

local isDetecting = false
local keyword = "agent"
local doTeleport = false

SettingsSection:CreateInput({
    Name = "NPC Name (keyword)",
    PlaceholderText = "agent, secret, case",
    RemoveTextAfterFocusLost = false,
    Flag = "NPCKeyword",
    Callback = function(text)
        if text ~= "" then keyword = string.lower(text) end
    end
})

SettingsSection:CreateToggle({
    Name = "Teleport to NPC on spawn",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(state) doTeleport = state end
})

SettingsSection:CreateToggle({
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

local function highlightNPC(model)
    if model:FindFirstChild("HunterHighlight") then return end
    local hl = Instance.new("Highlight")
    hl.Name = "HunterHighlight"
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
end

Workspace.DescendantAdded:Connect(function(obj)
    if not isDetecting then return end
    
    if obj:IsA("Model") and string.find(string.lower(obj.Name), keyword) then
        if obj:FindFirstChild("Humanoid") then
            
            highlightNPC(obj)
            
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://138078392"
            sound.Volume = 10
            sound.Parent = game.SoundService
            sound:Play()

            Rayfield:Notify({
                Title = "🚨 FOUND!",
                Content = obj.Name .. " spawned on the map!",
                Duration = 10
            })
            print("[DETECTOR] Found NPC:", obj.Name)

            if doTeleport and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = obj:GetPivot() + Vector3.new(0, 5, 0)
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Gman Hub",
    Content = "Script loaded. Press K for menu.",
    Duration = 5
})
