-- ===== STBB Gman Hub (Advanced Combat) =====
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

-- ===== ВКЛАДКА 1: HUNTER =====
local HunterTab = Window:CreateTab("Hunter")
local HuntSection = HunterTab:CreateSection("Rare NPC Hunter")

local isDetecting = false
local keyword = "agent"
local doTeleport = false

HuntSection:CreateInput({
    Name = "NPC Name (keyword)",
    PlaceholderText = "agent, secret, case",
    RemoveTextAfterFocusLost = false,
    Flag = "NPCKeyword",
    Callback = function(text)
        if text ~= "" then keyword = string.lower(text) end
    end
})

HuntSection:CreateToggle({
    Name = "Teleport to NPC",
    CurrentValue = false,
    Flag = "AutoTP",
    Callback = function(state) doTeleport = state end
})

HuntSection:CreateToggle({
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


-- ===== ВКЛАДКА 2: COMBAT (ADVANCED AUTO SKILLS) =====
local CombatTab = Window:CreateTab("Combat")
local SkillSection = CombatTab:CreateSection("Auto Skills")

local autoSkillEnabled = false
local comboString = "Q" -- По умолчанию Q
local skillDelay = 1.5
local aerialOnly = false
local autoJump = false

-- Ввод комбо (например: Q,E или Space,Space)
SkillSection:CreateInput({
    Name = "Combo Keys (e.g. Q,E or Space,Space)",
    PlaceholderText = "Q,E",
    RemoveTextAfterFocusLost = false,
    Flag = "ComboInput",
    Callback = function(text)
        if text ~= "" then comboString = text end
    end
})

-- Задержка
SkillSection:CreateSlider({
    Name = "Delay (seconds)",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1.5,
    Flag = "SkillDelay",
    Callback = function(value)
        skillDelay = value
    end,
})

-- Только в воздухе (Aerial)
SkillSection:CreateToggle({
    Name = "Aerial Only (Only in air)",
    CurrentValue = false,
    Flag = "AerialToggle",
    Callback = function(state)
        aerialOnly = state
    end,
})

-- Авто-прыжок (если нужно аэрал, а ты на земле)
SkillSection:CreateToggle({
    Name = "Auto Jump for Aerial",
    CurrentValue = false,
    Flag = "AutoJumpToggle",
    Callback = function(state)
        autoJump = state
    end,
})

-- Главный тумблер
SkillSection:CreateToggle({
    Name = "Enable Auto Skill",
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
                        local isInAir = (hum.FloorMaterial == Enum.Material.Air)
                        
                        -- Проверка на Aerial
                        local canExecute = true
                        if aerialOnly and not isInAir then
                            canExecute = false
                            -- Если включен авто-прыжок, прыгаем
                            if autoJump then
                                hum.Jump = true
                                task.wait(0.2) -- Ждем пока оторвется от земли
                                canExecute = true
                            end
                        end

                        if canExecute then
                            -- Разбиваем комбо по запятой
                            local keys = string.split(comboString, ",")
                            
                            for _, keyName in ipairs(keys) do
                                local key = string.upper(string.gsub(keyName, "%s+", ""))
                                local keyCode = Enum.KeyCode[key]
                                
                                if keyCode then
                                    -- Нажимаем
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                                    end)
                                    task.wait(0.05) -- Микро-задержка
                                    -- Отпускаем
                                    pcall(function()
                                        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
                                    end)
                                    task.wait(0.05) -- Пауза между клавишами в комбо
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
