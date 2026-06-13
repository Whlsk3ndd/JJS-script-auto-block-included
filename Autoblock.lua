--[[
    🥋 JUJUTSU SHENANIGANS – AUTO BLOCK SCRIPT (Enhanced) 🥋
    Features:
        - Custom GUI with radius slider (10-40 studs)
        - Auto blocks (F) when enemy within radius
        - Team detection (red vs blue)
        - NEW: Close button → fully stops script and removes GUI
        - NEW: Rejoin button → teleports you back to the same server
        - NEW: Hide button → hides the GUI (auto-block still works)
        - Right Shift toggles auto-block ON/OFF
    Controls:
        - Drag title bar to move GUI
        - Drag slider to adjust radius
--]]

-- ================================[ SERVICES ]================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ================================[ GLOBAL STATE ]============================
local scriptEnabled = true           -- auto-block toggle
local blockRadius = 20
local lastBlockTime = 0
local BLOCK_COOLDOWN = 0.3
local heartbeatConnection = nil      -- will be assigned
local guiObject = nil                -- to reference GUI for hide/close
local guiVisible = true              -- hide/show state

-- ================================[ UNIVERSAL KEY PRESS SIMULATOR ]===========
local function pressBlockKey()
    local keycodeNumber = 70  -- F key
    if keypress then
        pcall(function() keypress(keycodeNumber) end)
        return true
    elseif pressKey then
        pcall(function() pressKey(keycodeNumber) end)
        return true
    elseif syn and syn.keypress then
        pcall(function() syn.keypress(keycodeNumber) end)
        return true
    elseif KRNL_IMPL and KRNL_IMPL.keypress then
        pcall(function() KRNL_IMPL.keypress(keycodeNumber) end)
        return true
    elseif UserInputService.CreateVirtualInput then
        local success, virtual = pcall(UserInputService.CreateVirtualInput, UserInputService)
        if success and virtual then
            pcall(function() virtual:InjectKeyPress(keycodeNumber) end)
            return true
        end
    end
    if not pressBlockKey.warned then
        warn("[AutoBlock] No keypress method found. Update executor.")
        pressBlockKey.warned = true
    end
    return false
end

-- ================================[ ENEMY DETECTION ]==========================
local function isEnemy(player)
    if player == LocalPlayer then return false end
    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    return true  -- FFA mode
end

-- ================================[ AUTO BLOCK LOGIC ]========================
local function checkAndBlock()
    if not scriptEnabled then return end
    local character = LocalPlayer.Character
    if not character or character.Parent == nil then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local currentTime = tick()
    if currentTime - lastBlockTime < BLOCK_COOLDOWN then return end
    local myPosition = hrp.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local otherChar = player.Character
            if otherChar and otherChar.Parent then
                local otherHrp = otherChar:FindFirstChild("HumanoidRootPart")
                if otherHrp then
                    local distance = (myPosition - otherHrp.Position).Magnitude
                    if distance <= blockRadius then
                        pressBlockKey()
                        lastBlockTime = currentTime
                        break
                    end
                end
            end
        end
    end
end

-- Start the heartbeat loop
heartbeatConnection = RunService.Heartbeat:Connect(checkAndBlock)

-- ================================[ REJOIN FUNCTION ]==========================
local function rejoinServer()
    local placeId = game.PlaceId
    local jobId = game.JobId
    TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
end

-- ================================[ CLOSE SCRIPT ]=============================
local function closeScript()
    -- Disconnect the auto-block loop
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    -- Destroy GUI if it exists
    if guiObject then
        guiObject:Destroy()
        guiObject = nil
    end
    print("[AutoBlock] Script closed. All connections removed.")
end

-- ================================[ GUI CREATION ]=============================
local function CreateGUI()
    -- Remove any existing GUI first
    if CoreGui:FindFirstChild("AutoBlockGUI") then
        CoreGui:FindFirstChild("AutoBlockGUI"):Destroy()
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoBlockGUI"
    gui.Parent = CoreGui
    gui.ResetOnSpawn = false
    guiObject = gui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 160)  -- made taller for extra buttons
    frame.Position = UDim2.new(0.5, -140, 0.8, -80)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 1
    stroke.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🥋 AUTO BLOCK (JJS) 🥋"
    title.TextColor3 = Color3.fromRGB(255, 200, 100)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame
    
    -- Radius label
    local radiusLabel = Instance.new("TextLabel")
    radiusLabel.Size = UDim2.new(0.7, 0, 0, 22)
    radiusLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
    radiusLabel.BackgroundTransparency = 1
    radiusLabel.Text = "Block Radius: " .. blockRadius .. " studs"
    radiusLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    radiusLabel.Font = Enum.Font.Gotham
    radiusLabel.TextSize = 13
    radiusLabel.TextXAlignment = Enum.TextXAlignment.Left
    radiusLabel.Parent = frame
    
    -- Slider frame
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(0.9, 0, 0, 6)
    sliderFrame.Position = UDim2.new(0.05, 0, 0.58, 0)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = frame
    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(1, 0)
    sliderCorner.Parent = sliderFrame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((blockRadius - 10) / 30, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    fill.BorderSizePixel = 0
    fill.Parent = sliderFrame
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    local dragButton = Instance.new("TextButton")
    dragButton.Size = UDim2.new(0, 16, 0, 16)
    dragButton.Position = UDim2.new((blockRadius - 10) / 30, -8, 0.5, -8)
    dragButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dragButton.BorderSizePixel = 0
    dragButton.Text = ""
    dragButton.AutoButtonColor = false
    dragButton.Parent = sliderFrame
    local dragCorner = Instance.new("UICorner")
    dragCorner.CornerRadius = UDim.new(1, 0)
    dragCorner.Parent = dragButton
    
    -- Status indicator (active/inactive)
    local statusIndicator = Instance.new("Frame")
    statusIndicator.Size = UDim2.new(0, 12, 0, 12)
    statusIndicator.Position = UDim2.new(0.93, 0, 0.08, 0)
    statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    statusIndicator.BorderSizePixel = 0
    statusIndicator.Parent = frame
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(1, 0)
    statusCorner.Parent = statusIndicator
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Size = UDim2.new(0, 50, 0, 22)
    toggleText.Position = UDim2.new(0.65, 0, 0.35, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.Text = "ACTIVE"
    toggleText.TextColor3 = Color3.fromRGB(50, 200, 50)
    toggleText.Font = Enum.Font.GothamBold
    toggleText.TextSize = 12
    toggleText.TextXAlignment = Enum.TextXAlignment.Right
    toggleText.Parent = frame
    
    -- ========== BUTTONS (Close, Rejoin, Hide) ==========
    local buttonWidth = 80
    local buttonY = 0.78
    local spacing = 10
    
    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, buttonWidth, 0, 26)
    closeBtn.Position = UDim2.new(0.05, 0, buttonY, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✖ CLOSE"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.Parent = frame
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        closeScript()
    end)
    
    -- Rejoin Button
    local rejoinBtn = Instance.new("TextButton")
    rejoinBtn.Size = UDim2.new(0, buttonWidth, 0, 26)
    rejoinBtn.Position = UDim2.new(0.05 + (buttonWidth+spacing)/frame.Size.X.Scale, 0, buttonY, 0)
    rejoinBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 150)
    rejoinBtn.BorderSizePixel = 0
    rejoinBtn.Text = "🔄 REJOIN"
    rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rejoinBtn.Font = Enum.Font.GothamBold
    rejoinBtn.TextSize = 12
    rejoinBtn.Parent = frame
    local rejoinCorner = Instance.new("UICorner")
    rejoinCorner.CornerRadius = UDim.new(0, 4)
    rejoinCorner.Parent = rejoinBtn
    rejoinBtn.MouseButton1Click:Connect(function()
        rejoinServer()
    end)
    
    -- Hide Button
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size = UDim2.new(0, buttonWidth, 0, 26)
    hideBtn.Position = UDim2.new(0.05 + 2*(buttonWidth+spacing)/frame.Size.X.Scale, 0, buttonY, 0)
    hideBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    hideBtn.BorderSizePixel = 0
    hideBtn.Text = "👁 HIDE"
    hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    hideBtn.Font = Enum.Font.GothamBold
    hideBtn.TextSize = 12
    hideBtn.Parent = frame
    local hideCorner = Instance.new("UICorner")
    hideCorner.CornerRadius = UDim.new(0, 4)
    hideCorner.Parent = hideBtn
    hideBtn.MouseButton1Click:Connect(function()
        guiVisible = not guiVisible
        gui.Enabled = guiVisible
        hideBtn.Text = guiVisible and "👁 HIDE" or "👁 SHOW"
    end)
    
    -- ========== SLIDER DRAG LOGIC ==========
    local dragging = false
    dragButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    local function updateSlider(mouseX)
        local relativeX = math.clamp((mouseX - sliderFrame.AbsolutePosition.X) / sliderFrame.AbsoluteSize.X, 0, 1)
        local newRadius = math.floor(10 + (relativeX * 30))
        newRadius = math.clamp(newRadius, 10, 40)
        if newRadius ~= blockRadius then
            blockRadius = newRadius
            radiusLabel.Text = "Block Radius: " .. blockRadius .. " studs"
            fill:TweenSize(UDim2.new((blockRadius - 10) / 30, 0, 1, 0), "Out", "Quad", 0.15, true)
            dragButton:TweenPosition(UDim2.new((blockRadius - 10) / 30, -8, 0.5, -8), "Out", "Quad", 0.15, true)
        end
    end
    
    dragButton.MouseButton1Down:Connect(function()
        local mouse = LocalPlayer:GetMouse()
        updateSlider(mouse.X)
        local moveConn
        local releaseConn
        moveConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                updateSlider(input.Position.X)
            end
        end)
        releaseConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                moveConn:Disconnect()
                releaseConn:Disconnect()
            end
        end)
    end)
    
    -- ========== MASTER TOGGLE (Right Shift) ==========
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            scriptEnabled = not scriptEnabled
            if scriptEnabled then
                statusIndicator.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
                toggleText.Text = "ACTIVE"
                toggleText.TextColor3 = Color3.fromRGB(50, 200, 50)
            else
                statusIndicator.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
                toggleText.Text = "OFF"
                toggleText.TextColor3 = Color3.fromRGB(150, 50, 50)
            end
        end
    end)
    
    -- ========== MAKE GUI DRAGGABLE ==========
    local draggingGui = false
    local dragStart, frameStart
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingGui = true
            dragStart = input.Position
            frameStart = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingGui and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingGui = false
        end
    end)
    
    print("[JJS AutoBlock] GUI loaded. Right Shift toggles auto-block. Close button stops script. Rejoin button teleports. Hide button hides GUI.")
end

-- ================================[ INIT ]====================================
task.wait(1.5)
CreateGUI()
print("[JJS AutoBlock] Script ready. Auto-blocking ACTIVE.")
