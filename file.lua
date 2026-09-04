-- FE Object Manipulator v12 (with direct size change)
-- Place this file in a LocalScript under StarterPlayerScripts or similar so it runs on the client.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")

-- Inputs
local VelocityInput = Instance.new("TextBox")
local SizeModInput = Instance.new("TextBox")
local MsgTextInput = Instance.new("TextBox")
local BallSizeInput = Instance.new("TextBox") -- NEW: direct size input

-- Buttons
local MagnetBtn = Instance.new("TextButton")
local FreezeBtn = Instance.new("TextButton")
local FlingBtn = Instance.new("TextButton")
local ScatterBtn = Instance.new("TextButton")
local BfdiBtn = Instance.new("TextButton")
local VoidBtn = Instance.new("TextButton")
local AntiAnchorBtn = Instance.new("TextButton")
local FireTrailBtn = Instance.new("TextButton")
local DetonateBtn = Instance.new("TextButton")
local OrbitCamBtn = Instance.new("TextButton")
local ApplySizeBtn = Instance.new("TextButton") -- NEW: apply size button

ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "BFDI_Ultimate_FE_Hub_V12"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
MainFrame.Position = UDim2.new(0.05, 0, 0.1, 0)
MainFrame.Size = UDim2.new(0, 260, 0, 600)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(55, 70, 95)
Title.Text = "FE Object Manipulator v12"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

StatusLabel.Parent = MainFrame
StatusLabel.Position = UDim2.new(0.05, 0, 0.06, 0)
StatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
StatusLabel.Text = "Objects Linked: 0"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
StatusLabel.TextSize = 12
StatusLabel.BackgroundTransparency = 1

VelocityInput.Parent = MainFrame
VelocityInput.Position = UDim2.new(0.05, 0, 0.11, 0)
VelocityInput.Size = UDim2.new(0.9, 0, 0, 25)
VelocityInput.PlaceholderText = "Velocity Vector X,Y,Z (e.g. 0,100,0)"

SizeModInput.Parent = MainFrame
SizeModInput.Position = UDim2.new(0.05, 0, 0.17, 0)
SizeModInput.Size = UDim2.new(0.9, 0, 0, 25)
SizeModInput.PlaceholderText = "Local Size Scale multiplier (e.g. 2)"

MsgTextInput.Parent = MainFrame
MsgTextInput.Position = UDim2.new(0.05, 0, 0.23, 0)
MsgTextInput.Size = UDim2.new(0.9, 0, 0, 25)
MsgTextInput.PlaceholderText = "Target Player Message / Broadcast"

BallSizeInput.Parent = MainFrame
BallSizeInput.Position = UDim2.new(0.05, 0, 0.29, 0)
BallSizeInput.Size = UDim2.new(0.9, 0, 0, 25)
BallSizeInput.PlaceholderText = "Ball Size: X,Y,Z or single (e.g. 2 or 2,2,2)"

local dynamicY = 0.35
local function setupBtn(btn, text, color)
    btn.Parent = MainFrame
    btn.Position = UDim2.new(0.05, 0, dynamicY, 0)
    btn.Size = UDim2.new(0.9, 0, 0, 26)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    dynamicY = dynamicY + 0.057
end

setupBtn(MagnetBtn, "🧲 Bring All Map Objects (Network Ownership)", Color3.fromRGB(45, 110, 185))
setupBtn(FreezeBtn, "❄️ Toggle Physics Anchor (Freeze/Unfreeze)", Color3.fromRGB(150, 70, 70))
setupBtn(FlingBtn, "🌪️ Orbit / Insane Fling Loop Around You", Color3.fromRGB(180, 110, 30))
setupBtn(ScatterBtn, "🎲 Scatter Objects Over Map Randomly", Color3.fromRGB(100, 60, 150))
setupBtn(BfdiBtn, "✨ BFDI Mode: Force Exactly 2763 Velocity", Color3.fromRGB(0, 160, 110))
setupBtn(VoidBtn, "🕳️ Send All Selected Objects into the Void", Color3.fromRGB(25, 25, 30))
setupBtn(AntiAnchorBtn, "🔒 Anti-Anchor Loop (Keep Physics Active)", Color3.fromRGB(190, 140, 0))
setupBtn(FireTrailBtn, "🔥 Attach Fire & Light Cosmetics to Objects", Color3.fromRGB(210, 85, 0))
setupBtn(DetonateBtn, "💥 Detonate (Explode Objects Outward)", Color3.fromRGB(165, 30, 30))
setupBtn(OrbitCamBtn, "🎥 Orbit Camera View on Last Selected Object", Color3.fromRGB(85, 85, 100))
setupBtn(ApplySizeBtn, "🔧 Apply Size to Selected (X,Y,Z or single)", Color3.fromRGB(40, 150, 60))

local selectedObjects = {}
local activeHighlights = {}

local flingActive = false
local antiAnchorActive = false
local lastSelectedObj = nil
local cameraConnection = nil

local function removeHighlight(obj)
    if activeHighlights[obj] then
        if activeHighlights[obj].Parent then
            activeHighlights[obj]:Destroy()
        end
        activeHighlights[obj] = nil
    end
end

local function addHighlight(obj)
    removeHighlight(obj)
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(0, 200, 255)
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(27, 255, 175)
    hl.OutlineTransparency = 0
    hl.Adornee = obj
    hl.Parent = ScreenGui
    activeHighlights[obj] = hl
end

local function updateStatus()
    local count = 0
    for _ in pairs(selectedObjects) do count = count + 1 end
    StatusLabel.Text = "Objects Linked: " .. count
end

local function parseNumbers(str)
    local nums = {}
    if not str or str == "" then return nums end
    for num in string.gmatch(str, "%-?%d+%.?%d*") do
        local n = tonumber(num)
        if n then
            table.insert(nums, n)
        end
    end
    return nums
end

VelocityInput.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    local coords = parseNumbers(VelocityInput.Text)
    if #coords >= 3 then
        local vec = Vector3.new(coords[1], coords[2], coords[3])
        for obj in pairs(selectedObjects) do
            if obj and obj:IsA("BasePart") then
                obj.AssemblyLinearVelocity = vec
            end
        end
    end
end)

SizeModInput.FocusLost:Connect(function(enterPressed)
    if not enterPressed then return end
    local scale = tonumber(SizeModInput.Text)
    if scale then
        for obj in pairs(selectedObjects) do
            if obj and obj:IsA("BasePart") then
                obj.Size = obj.Size * scale
            end
        end
    end
end)

-- NEW: Apply size button handler
ApplySizeBtn.MouseButton1Click:Connect(function()
    local nums = parseNumbers(BallSizeInput.Text)
    if #nums == 0 then
        -- nothing to apply
        return
    end

    local newSize
    if #nums == 1 then
        local v = math.max(0.01, nums[1])
        newSize = Vector3.new(v, v, v)
    else
        local x = math.max(0.01, nums[1] or 1)
        local y = math.max(0.01, nums[2] or x)
        local z = math.max(0.01, nums[3] or x)
        newSize = Vector3.new(x, y, z)
    end

    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") then
            obj.Size = newSize
        end
    end
end)

MagnetBtn.MouseButton1Click:Connect(function()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored and not obj:IsDescendantOf(player.Character) then
            obj.CFrame = hrp.CFrame * CFrame.new(math.random(-5,5), 2, math.random(-8,-3))
            selectedObjects[obj] = true
            addHighlight(obj)
            lastSelectedObj = obj
        end
    end
    updateStatus()
end)

FreezeBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") then
            obj.Anchored = not obj.Anchored
        end
    end
end)

ScatterBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") and obj.Parent then
            obj.CFrame = obj.CFrame * CFrame.new(math.random(-150, 150), math.random(5, 50), math.random(-150, 150))
            obj.AssemblyLinearVelocity = Vector3.new(math.random(-50,50), math.random(10,100), math.random(-50,50))
        end
    end
end)

VoidBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") and obj.Parent then
            obj.CFrame = CFrame.new(obj.Position.X, -500, obj.Position.Z)
            obj.AssemblyLinearVelocity = Vector3.new(0, -500, 0)
        end
    end
end)

BfdiBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") and obj.Parent then
            obj.AssemblyLinearVelocity = Vector3.new(0, 2763, 0)
        end
    end
end)

AntiAnchorBtn.MouseButton1Click:Connect(function()
    antiAnchorActive = not antiAnchorActive
    AntiAnchorBtn.Text = antiAnchorActive and "🔒 STOP Anti-Anchor Loop" or "🔒 Anti-Anchor Loop"
    
    task.spawn(function()
        while antiAnchorActive do
            for obj in pairs(selectedObjects) do
                if obj and obj:IsA("BasePart") and obj.Anchored then
                    obj.Anchored = false
                end
            end
            task.wait(0.5)
        end
    end)
end)

FireTrailBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") and obj.Parent then
            local fire = Instance.new("Fire")
            fire.Color = Color3.fromRGB(0, 220, 255)
            fire.SecondaryColor = Color3.fromRGB(0, 50, 255)
            fire.Size = 6
            fire.Parent = obj
            
            local light = Instance.new("PointLight")
            light.Color = Color3.fromRGB(0, 200, 255)
            light.Range = 15
            light.Brightness = 3
            light.Parent = obj
        end
    end
end)

DetonateBtn.MouseButton1Click:Connect(function()
    for obj in pairs(selectedObjects) do
        if obj and obj:IsA("BasePart") and obj.Parent then
            local pushVector = Vector3.new(math.random(-150, 150), math.random(50, 150), math.random(-150, 150))
            obj.AssemblyLinearVelocity = pushVector
        end
    end
end)

OrbitCamBtn.MouseButton1Click:Connect(function()
    if cameraConnection then
        cameraConnection:Disconnect()
        cameraConnection = nil
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            workspace.CurrentCamera.CameraSubject = char.Humanoid
        end
        OrbitCamBtn.Text = "🎥 Orbit Camera View on Last Selected Object"
        return
    end

    if lastSelectedObj and lastSelectedObj.Parent then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        OrbitCamBtn.Text = "🎥 RESET Camera Focus (Back to Character)"
        
        cameraConnection = RunService.RenderStepped:Connect(function()
            if lastSelectedObj and lastSelectedObj.Parent then
                local center = lastSelectedObj.Position
                local rotationSpeed = tick() * 2
                local radius = 20
                local cameraPosition = center + Vector3.new(math.sin(rotationSpeed) * radius, 10, math.cos(rotationSpeed) * radius)
                workspace.CurrentCamera.CFrame = CFrame.lookAt(cameraPosition, center)
            else
                if cameraConnection then
                    cameraConnection:Disconnect()
                    cameraConnection = nil
                end
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    workspace.CurrentCamera.CameraSubject = char.Humanoid
                end
                OrbitCamBtn.Text = "🎥 Orbit Camera View on Last Selected Object"
            end
        end)
    end
end)

FlingBtn.MouseButton1Click:Connect(function()
    flingActive = not flingActive
    FlingBtn.Text = flingActive and "🌪️ STOP Fling Engine" or "🌪️ Orbit / Insane Fling Loop Around You"
    
    task.spawn(function()
        while flingActive do
            local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            
            local timeFactor = tick() * 5
            for obj in pairs(selectedObjects) do
                if obj and obj:IsA("BasePart") and obj.Parent then
                    local offset = Vector3.new(math.sin(timeFactor) * 12, 1, math.cos(timeFactor) * 12)
                    obj.CFrame = CFrame.new(hrp.Position + offset)
                    obj.AssemblyLinearVelocity = Vector3.new(0, math.sin(tick()) * 50, 0)
                end
            end
            task.wait()
        end
    end)
end)

-- Mouse selection: CTRL + Left Click to add/remove objects
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
        local target = mouse.Target
        if target and target:IsA("BasePart") then
            if selectedObjects[target] then
                selectedObjects[target] = nil
                removeHighlight(target)
            else
                selectedObjects[target] = true
                addHighlight(target)
                lastSelectedObj = target
            end
            updateStatus()
        end
    end
end)

-- Clean up highlights if parts are removed
workspace.DescendantRemoving:Connect(function(desc)
    if selectedObjects[desc] then
        selectedObjects[desc] = nil
        removeHighlight(desc)
        updateStatus()
    end
end)
