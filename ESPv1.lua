-- ESP + перетаскиваемое меню + бинд на X (вкл/выкл ESP)

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local ESP_CONFIG = {
    Enabled = true,   -- изначально включено
    FillColor = Color3.fromRGB(255, 0, 0),
    FillTransparency = 0.3,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    OutlineTransparency = 0,
    TeamCheck = false,
}

local sg = Instance.new("ScreenGui")
sg.Name = "SimpleESP"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset = true
sg.Parent = playerGui

local win = Instance.new("Frame")
win.Size = UDim2.new(0, 180, 0, 56)
win.Position = UDim2.new(0, 20, 0.5, -28)
win.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
win.BackgroundTransparency = 0.2
win.BorderSizePixel = 2
win.BorderColor3 = Color3.fromRGB(255, 0, 0)
win.ClipsDescendants = true
win.Parent = sg

local corner = Instance.new("UICorner", win)
corner.CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", win)
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "ESP: ON\n(нажми X, чтобы выключить)"
title.TextColor3 = Color3.fromRGB(255, 200, 200)
title.TextSize = 12
title.TextWrapped = true
title.Font = Enum.Font.GothamBold

local closeBtn = Instance.new("TextButton", win)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -22, 0, 2)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
local btnCorner = Instance.new("UICorner", closeBtn)
btnCorner.CornerRadius = UDim.new(0, 4)

closeBtn.MouseButton1Click:Connect(function()
    win.Visible = not win.Visible
end)

do
    local dragging, dragStart, startPos
    win.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local activeHighlights = {}

local function createHighlight(character)
    if not character then return nil end
    local hl = Instance.new("Highlight")
    hl.FillColor = ESP_CONFIG.FillColor
    hl.FillTransparency = ESP_CONFIG.FillTransparency
    hl.OutlineColor = ESP_CONFIG.OutlineColor
    hl.OutlineTransparency = ESP_CONFIG.OutlineTransparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    return hl
end

local function updatePlayerESP(player)
    if player == LocalPlayer then return end
    if ESP_CONFIG.TeamCheck and player.Team == LocalPlayer.Team then
        local hl = activeHighlights[player]
        if hl then hl:Destroy(); activeHighlights[player] = nil end
        return
    end
    
    local character = player.Character
    if not character then
        local hl = activeHighlights[player]
        if hl then hl:Destroy(); activeHighlights[player] = nil end
        return
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        local hl = activeHighlights[player]
        if hl then hl:Destroy(); activeHighlights[player] = nil end
        return
    end
    
    if not activeHighlights[player] then
        activeHighlights[player] = createHighlight(character)
    elseif activeHighlights[player].Parent ~= character then
        activeHighlights[player]:Destroy()
        activeHighlights[player] = createHighlight(character)
    end
    
    activeHighlights[player].Enabled = ESP_CONFIG.Enabled
end

local function refreshAllESP()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayerESP(player)
    end
end

local function toggleESP()
    ESP_CONFIG.Enabled = not ESP_CONFIG.Enabled
    -- обновляем текст в меню
    if ESP_CONFIG.Enabled then
        title.Text = "ESP: ON\n(нажми X, чтобы выключить)"
        win.BorderColor3 = Color3.fromRGB(255, 0, 0)
    else
        title.Text = "ESP: OFF\n(нажми X, чтобы включить)"
        win.BorderColor3 = Color3.fromRGB(100, 100, 100)
    end
    -- применяем ко всем игрокам
    for player, hl in pairs(activeHighlights) do
        if hl then hl.Enabled = ESP_CONFIG.Enabled end
    end
    refreshAllESP()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.X then
        toggleESP()
    end
end)

Players.PlayerAdded:Connect(function(player)
    updatePlayerESP(player)
    player.CharacterAdded:Connect(function()
        updatePlayerESP(player)
    end)
    player.CharacterRemoving:Connect(function()
        local hl = activeHighlights[player]
        if hl then hl:Destroy(); activeHighlights[player] = nil end
    end)
    if ESP_CONFIG.TeamCheck then
        player:GetPropertyChangedSignal("Team"):Connect(function()
            updatePlayerESP(player)
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local hl = activeHighlights[player]
    if hl then hl:Destroy(); activeHighlights[player] = nil end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        updatePlayerESP(player)
        player.CharacterAdded:Connect(function()
            updatePlayerESP(player)
        end)
        player.CharacterRemoving:Connect(function()
            local hl = activeHighlights[player]
            if hl then hl:Destroy(); activeHighlights[player] = nil end
        end)
        if ESP_CONFIG.TeamCheck then
            player:GetPropertyChangedSignal("Team"):Connect(function()
                updatePlayerESP(player)
            end)
        end
    end
end

print("[ESP] Загружен. Нажми X, чтобы включить/выключить подсветку. Окно можно перетаскивать.")
