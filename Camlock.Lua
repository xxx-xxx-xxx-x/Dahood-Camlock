-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera

-- config adjust as needed
local Config = {
    AimbotEnabled = false,
    AimbotKey = Enum.KeyCode.C,
    AimPart = "Head",
    Smoothness = 0.2,
    Prediction = 0.165,
    MaxDistance = 1000,
}

local currentTarget = nil

local function isTargetVisible(target)
    local targetPart = target.Character and target.Character[Config.AimPart]
    if targetPart then
        local origin = Camera.CFrame.Position
        local direction = (targetPart.Position - origin).Unit
        local ray = Ray.new(origin, direction * Config.MaxDistance)
        local hit, hitPosition = workspace:FindPartOnRay(ray, LocalPlayer.Character)
        return hit and hit:IsDescendantOf(target.Character)
    end
    return false
end

local function findClosestPlayerToMouse()
    local mousePosition = UserInputService:GetMouseLocation()
    local nearestPlayer = nil
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(Config.AimPart) then
            local targetPart = player.Character[Config.AimPart]
            local screenPosition, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

            if onScreen then
                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - Vector2.new(mousePosition.X, mousePosition.Y)).Magnitude

                if distance < shortestDistance and isTargetVisible(player) then
                    nearestPlayer = player
                    shortestDistance = distance
                end
            end
        end
    end

    return nearestPlayer
end

local function predictTargetPosition(targetPart)
    local targetVelocity = targetPart.Parent:FindFirstChild("HumanoidRootPart") and targetPart.Parent:FindFirstChild("HumanoidRootPart").Velocity or Vector3.new(0, 0, 0)
    local predictedPosition = targetPart.Position + (targetVelocity * Config.Prediction)
    return predictedPosition
end

local function aimAtTarget(target)
    if target then
        local predictedPosition = predictTargetPosition(target.Character[Config.AimPart])
        if predictedPosition then
            local cameraPosition = Camera.CFrame.Position
            local direction = (predictedPosition - cameraPosition).Unit
            local newLookVector = Camera.CFrame.LookVector:Lerp(direction, Config.Smoothness)
            Camera.CFrame = CFrame.new(cameraPosition, cameraPosition + newLookVector)
        end
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if not isProcessed and input.KeyCode == Config.AimbotKey then
        Config.AimbotEnabled = not Config.AimbotEnabled
        if Config.AimbotEnabled then
            currentTarget = findClosestPlayerToMouse()
        else
            currentTarget = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Config.AimbotEnabled and currentTarget then
        if currentTarget.Character and currentTarget.Character:FindFirstChild(Config.AimPart) and isTargetVisible(currentTarget) then
            aimAtTarget(currentTarget)
        else
            currentTarget = findClosestPlayerToMouse()
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    if Config.AimbotEnabled then
        currentTarget = findClosestPlayerToMouse()
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if currentTarget == player then
        currentTarget = nil
    end
end)
