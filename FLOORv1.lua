-- LocalScript
-- Z — включить / выключить пол
-- Insert — полностью отключить скрипт

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PLATE_SIZE   = Vector3.new(15,1,15)
local PLATE_COLOR  = Color3.fromRGB(100,200,255)
local PLATE_TRANSP = 0.5
local FEET_OFFSET  = -3.1

local isEnabled = false
local scriptEnabled = true
local platePart = nil
local updateLoop = nil

local screenGui = Instance.new("ScreenGui")
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0,220,0,40)
label.Position = UDim2.new(0,20,1,-70)
label.AnchorPoint = Vector2.new(0,1)
label.BackgroundColor3 = Color3.fromRGB(30,30,30)
label.BackgroundTransparency = 0.3
label.TextColor3 = Color3.new(1,1,1)
label.Text = "🟥 Z — Пол: ВЫКЛ"
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.BorderSizePixel = 0
label.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = label

local function destroyFloor()

	if updateLoop then
		updateLoop:Disconnect()
		updateLoop = nil
	end

	if platePart then
		platePart:Destroy()
		platePart = nil
	end

end

local function spawnFloor()

	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local part = Instance.new("Part")
	part.Name = "LocalFloor"
	part.Size = PLATE_SIZE
	part.Anchored = true
	part.CanCollide = true
	part.Color = PLATE_COLOR
	part.Transparency = PLATE_TRANSP
	part.Material = Enum.Material.Neon
	part.CastShadow = false
	part.Parent = camera

	platePart = part

	updateLoop = RunService.RenderStepped:Connect(function()

		if not platePart then return end
		if not player.Character then return end

		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local pos = Vector3.new(
			root.Position.X,
			root.Position.Y + FEET_OFFSET,
			root.Position.Z
		)

		platePart.Position = pos

		local plateTop = platePart.Position.Y + (platePart.Size.Y/2)

		if root.Position.Y < plateTop then
			platePart.CanCollide = false
			platePart.LocalTransparencyModifier = 0.75
		else
			platePart.CanCollide = true
			platePart.LocalTransparencyModifier = 0
		end

	end)

end

local function toggleFloor()

	if not scriptEnabled then return end

	if isEnabled then

		isEnabled = false
		label.Text = "🟥 Z — Пол: ВЫКЛ"
		destroyFloor()

	else

		isEnabled = true
		label.Text = "🟩 Z — Пол: ВКЛ"
		spawnFloor()

	end

end

UserInputService.InputBegan:Connect(function(input,gp)

	if gp then return end

	if input.KeyCode == Enum.KeyCode.Z then
		toggleFloor()
	end

	if input.KeyCode == Enum.KeyCode.Insert then

		scriptEnabled = false
		isEnabled = false

		destroyFloor()

		if screenGui then
			screenGui:Destroy()
		end

	end

end)

player.CharacterAdded:Connect(function()

	destroyFloor()
	isEnabled = false

	if scriptEnabled and label then
		label.Text = "🟥 Z — Пол: ВЫКЛ"
	end

end)
