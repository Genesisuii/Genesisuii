-- Roblox-Dienste
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game:GetService("Workspace").CurrentCamera

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Statusanzeigen für Funktionen
local espEnabled = false
local aimbotEnabled = false
local aimbotToggled = false
local flying = false
local flyingSpeed = 50
local bodyVelocity

-- GUI erstellen
local gui = Instance.new("ScreenGui")
gui.Parent = player:WaitForChild("PlayerGui")
gui.Name = "ControlGUI"
gui.Enabled = true  -- Initial sichtbar

-- Hintergrund für das GUI
local background = Instance.new("Frame")
background.Size = UDim2.new(0, 300, 0, 400)
background.Position = UDim2.new(0.8, 0, 0.2, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.6
background.BorderSizePixel = 0
background.Parent = gui

-- Verschiebefunktion des GUI
local dragging, dragInput, dragStart, startPos

background.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = background.Position
    end
end)

background.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        background.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

background.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Titel des GUI
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.Text = "Game Controls"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Parent = background

-- Schließkreuz oben rechts
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -30, 0, 0)
closeButton.Text = "X"
closeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Parent = background

closeButton.MouseButton1Click:Connect(function()
    gui:Destroy()  -- Entfernt das GUI
    script:Destroy()  -- Stoppt das Script
end)

-- ESP-Button
local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(1, 0, 0, 50)
espButton.Position = UDim2.new(0, 0, 0, 50)
espButton.Text = "ESP: Deaktiviert"
espButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.TextScaled = true
espButton.Parent = background

-- Flugmodus-Button
local flyButton = Instance.new("TextButton")
flyButton.Size = UDim2.new(1, 0, 0, 50)
flyButton.Position = UDim2.new(0, 0, 0, 150)
flyButton.Text = "Flugmodus: Deaktiviert"
flyButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.TextScaled = true
flyButton.Parent = background

-- Aimbot-Button
local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(1, 0, 0, 50)
aimbotButton.Position = UDim2.new(0, 0, 0, 250)
aimbotButton.Text = "Aimbot: Deaktiviert"
aimbotButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
aimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotButton.TextScaled = true
aimbotButton.Parent = background

-- ESP Logik
local espMarkers = {}

local function createESPName(player)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 100, 0, 30)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Text = player.Name
    nameLabel.Parent = gui
    return nameLabel
end

local function removeESP(player)
    if espMarkers[player] then
        espMarkers[player]:Destroy()
        espMarkers[player] = nil
    end
end

local function updateESPNamePosition()
    if espEnabled then
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            -- Überprüfe, ob der Spieler nicht der lokale Spieler ist und ob er einen Kopf hat
            if targetPlayer ~= player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
                local head = targetPlayer.Character.Head
                local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)

                if onScreen then
                    local nameLabel = espMarkers[targetPlayer]
                    if not nameLabel then
                        -- Wenn der Spieler noch keinen ESP-Eintrag hat, erstelle einen neuen
                        nameLabel = createESPName(targetPlayer)
                        espMarkers[targetPlayer] = nameLabel
                    end
                    nameLabel.Position = UDim2.new(0, screenPos.X - nameLabel.Size.X.Offset / 2, 0, screenPos.Y - nameLabel.Size.Y.Offset / 2)
                else
                    -- Lösche den ESP-Eintrag, wenn der Spieler nicht mehr im Sichtfeld ist
                    removeESP(targetPlayer)
                end
            else
                -- Lösche den ESP-Eintrag, wenn der Spieler keine Kopf-Instanz hat
                removeESP(targetPlayer)
            end
        end
    end
end

-- ESP-Button Logik
espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espButton.Text = "ESP: " .. (espEnabled and "Aktiviert" or "Deaktiviert")
    espButton.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)

    if not espEnabled then
        -- Lösche alle ESP-Markierungen, wenn ESP deaktiviert wird
        for _, nameLabel in pairs(espMarkers) do
            nameLabel:Destroy()
        end
        espMarkers = {}
    end
end)

-- Flugmodus Logik
local function startFlying()
    humanoid.PlatformStand = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart
end

local function stopFlying()
    humanoid.PlatformStand = false
    if bodyVelocity then
        bodyVelocity:Destroy()
    end
end

local function controlFlight()
    if flying then
        local moveDirection = Vector3.new()

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + humanoidRootPart.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - humanoidRootPart.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - humanoidRootPart.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + humanoidRootPart.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        bodyVelocity.Velocity = moveDirection * flyingSpeed
    end
end

flyButton.MouseButton1Click:Connect(function()
    if flying then
        stopFlying()
        flyButton.Text = "Flugmodus: Deaktiviert"
    else
        startFlying()
        flyButton.Text = "Flugmodus: Aktiviert"
    end
    flying = not flying
end)

-- Aimbot Logik
local function activateAimbot()
    if not aimbotEnabled or not aimbotToggled then return end

    local closestTarget = nil
    local shortestDistance = math.huge
    local targetPosition = nil

    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)

            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local distanceToMouse = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

                if distanceToMouse < shortestDistance then
                    shortestDistance = distanceToMouse
                    closestTarget = head
                    targetPosition = closestTarget.Position
                end
            end
        end
    end

    if closestTarget then
        local targetDirection = (targetPosition - Camera.CFrame.Position).unit
        local targetRotation = CFrame.lookAt(Camera.CFrame.Position, targetPosition)

        -- Kamera schnell auf das Ziel ausrichten
        local rotationSpeed = 0.1
        Camera.CFrame = Camera.CFrame:Lerp(targetRotation, rotationSpeed)
    end
end

aimbotButton.MouseButton1Click:Connect(function()
    aimbotEnabled = not aimbotEnabled
    aimbotButton.Text = "Aimbot: " .. (aimbotEnabled and "Aktiviert" or "Deaktiviert")
    aimbotButton.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        gui.Enabled = not gui.Enabled  -- Schaltet das GUI ein/aus
    end

    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aimbotToggled = not aimbotToggled
        print("Aimbot ist jetzt " .. (aimbotToggled and "Aktiv" or "Inaktiv"))
    end
end)

-- Haupt-Schleifen für Aimbot, Flugmodus und ESP
RunService.Heartbeat:Connect(function()
    if aimbotEnabled and aimbotToggled then
        activateAimbot() -- Wenn Aimbot aktiviert und getoggelt ist, führe die Aimbot-Logik aus
    end

    if flying then
        controlFlight() -- Wenn Flugmodus aktiviert, steuere die Bewegung
    end

    if espEnabled then
        updateESPNamePosition() -- Wenn ESP aktiviert, aktualisiere die Position der ESP-Namen
    end
end)

