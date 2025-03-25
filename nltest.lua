local Library = {}

local NEVERLOSE_VERSION = "v1.1A"

-- Cache services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Remove previous GUI if it exists
for _, gui in ipairs(CoreGui:GetChildren()) do
    if gui:IsA("ScreenGui") and gui.Name == "Neverlose" then
        gui:Destroy()
    end
end

local theMouse = LocalPlayer:GetMouse()

-- Notification function
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 5
    })
end

-- Drag functionality for UI elements
local function Dragify(frame, parent)
    parent = parent or frame

    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = parent.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            parent.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

-- Rounds a number to a given bracket
local function round(num, bracket)
    bracket = bracket or 1
    local rounded = math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket
    if rounded < 0 then
        rounded = rounded + bracket
    end
    return rounded
end

-- Button hover effect
local function buttoneffect(options)
    pcall(function()
        options.entered.MouseEnter:Connect(function()
            if options.frame.TextColor3 ~= Color3.fromRGB(234, 239, 246) then
                TweenService:Create(options.frame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    TextColor3 = Color3.fromRGB(234, 239, 245)
                }):Play()
            end
        end)
        options.entered.MouseLeave:Connect(function()
            if options.frame.TextColor3 ~= Color3.fromRGB(157, 171, 182) and options.frame.TextColor3 ~= Color3.fromRGB(234, 239, 246) then
                TweenService:Create(options.frame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                    TextColor3 = Color3.fromRGB(157, 171, 182)
                }):Play()
            end
        end)
    end)
end

-- Click effect for buttons
local function clickEffect(options)
    options.button.MouseButton1Click:Connect(function()
        local newSize = options.button.TextSize - tonumber(options.amount)
        local revertSize = newSize + tonumber(options.amount)
        TweenService:Create(options.button, TweenInfo.new(0.15, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { TextSize = newSize }):Play()
        wait(0.1)
        TweenService:Create(options.button, TweenInfo.new(0.1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), { TextSize = revertSize }):Play()
    end)
end

-- Toggle the GUI's visibility
function Library:Toggle(value)
    local gui = CoreGui:FindFirstChild("Neverlose")
    if not gui then return end

    local enabled = (type(value) == "boolean" and value) or gui.Enabled
    gui.Enabled = not enabled
end

-- Create the main window
function Library:Window(options)
    options = options or {}
    options.text = options.text or "NEVERLOSE"

    -- Create main ScreenGui and UI elements
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Neverlose"
    screenGui.Parent = CoreGui

    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Parent = screenGui
    body.AnchorPoint = Vector2.new(0.5, 0.5)
    body.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
    body.BorderSizePixel = 0
    body.Position = UDim2.new(0.4657, 0, 0.5, 0)
    body.Size = UDim2.new(0, 658, 0, 516)
    Dragify(body)

    local bodyCorner = Instance.new("UICorner")
    bodyCorner.CornerRadius = UDim.new(0, 4)
    bodyCorner.Name = "bodyCorner"
    bodyCorner.Parent = body

    local sideBar = Instance.new("Frame")
    sideBar.Name = "SideBar"
    sideBar.Parent = body
    sideBar.BackgroundColor3 = Color3.fromRGB(26, 36, 48)
    sideBar.BorderSizePixel = 0
    sideBar.Size = UDim2.new(0, 187, 0, 516)

    local sidebarCorner = Instance.new("UICorner")
    sidebarCorner.CornerRadius = UDim.new(0, 4)
    sidebarCorner.Name = "sidebarCorner"
    sidebarCorner.Parent = sideBar

    local sbLine = Instance.new("Frame")
    sbLine.Name = "sbLine"
    sbLine.Parent = sideBar
    sbLine.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
    sbLine.BorderSizePixel = 0
    sbLine.Position = UDim2.new(0.9949, 0, 0, 0)
    sbLine.Size = UDim2.new(0, 3, 0, 516)

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Parent = body
    topBar.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
    topBar.BackgroundTransparency = 1
    topBar.BorderSizePixel = 0
    topBar.Position = UDim2.new(0.2517, 0, 0, 0)
    topBar.Size = UDim2.new(0, 562, 0, 49)

    local tbLine = Instance.new("Frame")
    tbLine.Name = "tbLine"
    tbLine.Parent = topBar
    tbLine.BackgroundColor3 = Color3.fromRGB(15, 23, 36)
    tbLine.BorderSizePixel = 0
    tbLine.Position = UDim2.new(0.04, 0, 1, 0)
    tbLine.Size = UDim2.new(0, 469, 0, 3)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = sideBar
    title.BackgroundColor3 = Color3.fromRGB(234, 239, 245)
    title.BackgroundTransparency = 1
    title.BorderSizePixel = 0
    title.Position = UDim2.new(0.0615, 0, 0.0213, 0)
    title.Size = UDim2.new(0, 162, 0, 26)
    title.Font = Enum.Font.ArialBold
    title.Text = options.text
    title.TextColor3 = Color3.fromRGB(234, 239, 245)
    title.TextSize = 28
    title.TextWrapped = true

    local allPages = Instance.new("Frame")
    allPages.Name = "allPages"
    allPages.Parent = body
    allPages.BackgroundTransparency = 1
    allPages.BorderSizePixel = 0
    allPages.Position = UDim2.new(0.2951, 0, 0.1008, 0)
    allPages.Size = UDim2.new(0, 463, 0, 464)

    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "tabContainer"
    tabContainer.Parent = sideBar
    tabContainer.BackgroundTransparency = 1
    tabContainer.BorderSizePixel = 0
    tabContainer.Position = UDim2.new(0, 0, 0.1008, 0)
    tabContainer.Size = UDim2.new(0, 187, 0, 464)

    -- Tab sections API
    local tabsections = {}

    function tabsections:TabSection(options)
        options = options or {}
        options.text = options.text or "Tab Section"

        local tabLayout = Instance.new("UIListLayout")
        tabLayout.Name = "tabLayout"
        tabLayout.Parent = tabContainer

        local tabSection = Instance.new("Frame")
        tabSection.Name = "tabSection"
        tabSection.Parent = tabContainer
        tabSection.BackgroundTransparency = 1
        tabSection.BorderSizePixel = 0
        tabSection.Size = UDim2.new(0, 189, 0, 22)

        local function ResizeTS(num)
            tabSection.Size = tabSection.Size + UDim2.new(0, 0, 0, num)
        end

        local tabSectionLabel = Instance.new("TextLabel")
        tabSectionLabel.Name = "tabSectionLabel"
        tabSectionLabel.Parent = tabSection
        tabSectionLabel.BackgroundTransparency = 1
        tabSectionLabel.BorderSizePixel = 0
        tabSectionLabel.Size = UDim2.new(0, 190, 0, 22)
        tabSectionLabel.Font = Enum.Font.Gotham
        tabSectionLabel.Text = "     " .. options.text
        tabSectionLabel.TextColor3 = Color3.fromRGB(79, 107, 126)
        tabSectionLabel.TextSize = 17
        tabSectionLabel.TextXAlignment = Enum.TextXAlignment.Left

        local tabSectionLayout = Instance.new("UIListLayout")
        tabSectionLayout.Name = "tabSectionLayout"
        tabSectionLayout.Parent = tabSection
        tabSectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        tabSectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabSectionLayout.Padding = UDim.new(0, 7)

        local tabs = {}

        function tabs:Tab(options)
            options = options or {}
            options.text = options.text or "New Tab"
            options.icon = options.icon or "rbxassetid://7999345313"

            local tabButton = Instance.new("TextButton")
            tabButton.Name = "tabButton"
            tabButton.Parent = tabSection
            tabButton.BackgroundColor3 = Color3.fromRGB(13, 57, 84)
            tabButton.BorderSizePixel = 0
            tabButton.Size = UDim2.new(0, 165, 0, 30)
            tabButton.AutoButtonColor = false
            tabButton.Font = Enum.Font.GothamSemibold
            tabButton.Text = "         " .. options.text
            tabButton.TextColor3 = Color3.fromRGB(234, 239, 245)
            tabButton.TextSize = 14
            tabButton.BackgroundTransparency = 1
            tabButton.TextXAlignment = Enum.TextXAlignment.Left

            local tabButtonCorner = Instance.new("UICorner")
            tabButtonCorner.CornerRadius = UDim.new(0, 4)
            tabButtonCorner.Name = "tabButtonCorner"
            tabButtonCorner.Parent = tabButton

            local tabIcon = Instance.new("ImageLabel")
            tabIcon.Name = "tabIcon"
            tabIcon.Parent = tabButton
            tabIcon.BackgroundTransparency = 1
            tabIcon.Size = UDim2.new(0, 21, 0, 21)
            tabIcon.Position = UDim2.new(0.04, 0, 0.1333, 0)
            tabIcon.Image = options.icon
            tabIcon.ImageColor3 = Color3.fromRGB(43, 154, 198)

            local newPage = Instance.new("ScrollingFrame")
            newPage.Name = "newPage"
            newPage.Parent = allPages
            newPage.Visible = false
            newPage.BackgroundTransparency = 1
            newPage.BorderSizePixel = 0
            newPage.ClipsDescendants = false
            newPage.Position = UDim2.new(0.0216, 0, 0.0237, 0)
            newPage.Size = UDim2.new(0, 442, 0, 440)
            newPage.ScrollBarThickness = 4
            newPage.CanvasSize = UDim2.new(0, 0, 0, 0)

            local pageLayout = Instance.new("UIGridLayout")
            pageLayout.Name = "pageLayout"
            pageLayout.Parent = newPage
            pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
            pageLayout.CellPadding = UDim2.new(0, 12, 0, 12)
            pageLayout.CellSize = UDim2.new(0, 215, 0, -10)
            pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                newPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y)
            end)

            ResizeTS(50)

            local sections = {}

            function sections:Section(options)
                options = options or {}
                options.text = options.text or "Section"

                local sectionFrame = Instance.new("Frame")
                sectionFrame.Name = "sectionFrame"
                sectionFrame.Parent = newPage
                sectionFrame.BackgroundColor3 = Color3.fromRGB(0, 15, 30)
                sectionFrame.BorderSizePixel = 0
                sectionFrame.Size = UDim2.new(0, 215, 0, 134)

                local sectionLabel = Instance.new("TextLabel")
                sectionLabel.Name = "sectionLabel"
                sectionLabel.Parent = sectionFrame
                sectionLabel.BackgroundTransparency = 1
                sectionLabel.Position = UDim2.new(0.0122, 0, 0, 0)
                sectionLabel.Size = UDim2.new(0, 213, 0, 25)
                sectionLabel.Font = Enum.Font.GothamSemibold
                sectionLabel.Text = "   " .. options.text
                sectionLabel.TextColor3 = Color3.fromRGB(234, 239, 245)
                sectionLabel.TextSize = 14
                sectionLabel.TextXAlignment = Enum.TextXAlignment.Left

                local sectionFrameCorner = Instance.new("UICorner")
                sectionFrameCorner.CornerRadius = UDim.new(0, 4)
                sectionFrameCorner.Name = "sectionFrameCorner"
                sectionFrameCorner.Parent = sectionFrame

                local sectionLayout = Instance.new("UIListLayout")
                sectionLayout.Name = "sectionLayout"
                sectionLayout.Parent = sectionFrame
                sectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                sectionLayout.Padding = UDim.new(0, 2)

                local sLine = Instance.new("TextLabel")
                sLine.Name = "sLine"
                sLine.Parent = sectionFrame
                sLine.BackgroundColor3 = Color3.fromRGB(13, 28, 44)
                sLine.BorderSizePixel = 0
                sLine.Position = UDim2.new(0.0256, 0, 0.4154, 0)
                sLine.Size = UDim2.new(0, 202, 0, 3)
                sLine.Text = ""
                
                local sectionSizeConstraint = Instance.new("UISizeConstraint")
                sectionSizeConstraint.Name = "sectionSizeConstraint"
                sectionSizeConstraint.Parent = sectionFrame
                sectionSizeConstraint.MinSize = Vector2.new(215, 35)

                local function Resize(num)
                    sectionSizeConstraint.MinSize = sectionSizeConstraint.MinSize + Vector2.new(0, num)
                end

                local elements = {}

                function elements:Button(options)
                    if not options.text or not options.callback then
                        Notify("Button", "Missing arguments!")
                        return
                    end

                    local btn = Instance.new("TextButton")
                    btn.Name = "TextButton"
                    btn.Parent = sectionFrame
                    btn.BackgroundColor3 = Color3.fromRGB(13, 57, 84)
                    btn.BorderSizePixel = 0
                    btn.Size = UDim2.new(0, 200, 0, 22)
                    btn.AutoButtonColor = false
                    btn.Text = options.text
                    btn.Font = Enum.Font.Gotham
                    btn.TextColor3 = Color3.fromRGB(157, 171, 182)
                    btn.TextSize = 14
                    btn.BackgroundTransparency = 1
                    buttoneffect({frame = btn, entered = btn})
                    clickEffect({button = btn, amount = 5})
                    btn.MouseButton1Click:Connect(options.callback)

                    Resize(25)
                end

                function elements:Toggle(options)
                    if not options.text or not options.callback then
                        Notify("Toggle", "Missing arguments!")
                        return
                    end

                    local toggleLabel = Instance.new("TextLabel")
                    local toggleFrame = Instance.new("TextButton")
                    local toggleButton = Instance.new("TextButton")
                    local togFrameCorner = Instance.new("UICorner")
                    local togBtnCorner = Instance.new("UICorner")
                    
                    local state = options.state or false

                    toggleLabel.Name = "toggleLabel"
                    toggleLabel.Parent = sectionFrame
                    toggleLabel.BackgroundTransparency = 1
                    toggleLabel.Position = UDim2.new(0.0349, 0, 0.9655, 0)
                    toggleLabel.Size = UDim2.new(0, 200, 0, 22)
                    toggleLabel.Font = Enum.Font.Gotham
                    toggleLabel.Text = " " .. options.text
                    toggleLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    toggleLabel.TextSize = 14
                    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    buttoneffect({frame = toggleLabel, entered = toggleLabel})

                    local function PerformToggle()
                        state = not state
                        options.callback(state)
                        TweenService:Create(toggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            Position = state and UDim2.new(0.74, 0, 0.5, 0) or UDim2.new(0.25, 0, 0.5, 0)
                        }):Play()
                        TweenService:Create(toggleLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            TextColor3 = state and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182)
                        }):Play()
                        TweenService:Create(toggleButton, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = state and Color3.fromRGB(2, 162, 243) or Color3.fromRGB(77, 77, 77)
                        }):Play()
                        TweenService:Create(toggleFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            BackgroundColor3 = state and Color3.fromRGB(2, 23, 49) or Color3.fromRGB(4, 4, 11)
                        }):Play()
                    end

                    toggleFrame.Name = "toggleFrame"
                    toggleFrame.Parent = toggleLabel
                    toggleFrame.BackgroundColor3 = Color3.fromRGB(4, 4, 11)
                    toggleFrame.BorderSizePixel = 0
                    toggleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    toggleFrame.Position = UDim2.new(0.9, 0, 0.5, 0)
                    toggleFrame.Size = UDim2.new(0, 38, 0, 18)
                    toggleFrame.AutoButtonColor = false
                    toggleFrame.Font = Enum.Font.SourceSans
                    toggleFrame.Text = ""
                    toggleFrame.MouseButton1Click:Connect(PerformToggle)

                    togFrameCorner.CornerRadius = UDim.new(0, 50)
                    togFrameCorner.Parent = toggleFrame

                    toggleButton.Name = "toggleButton"
                    toggleButton.Parent = toggleFrame
                    toggleButton.BackgroundColor3 = state and Color3.fromRGB(2, 162, 243) or Color3.fromRGB(77, 77, 77)
                    toggleButton.BorderSizePixel = 0
                    toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    toggleButton.Position = state and UDim2.new(0.74, 0, 0.5, 0) or UDim2.new(0.25, 0, 0.5, 0)
                    toggleButton.Size = UDim2.new(0, 16, 0, 16)
                    toggleButton.AutoButtonColor = false
                    toggleButton.Font = Enum.Font.SourceSans
                    toggleButton.Text = ""
                    toggleButton.MouseButton1Click:Connect(PerformToggle)

                    togBtnCorner.CornerRadius = UDim.new(0, 50)
                    togBtnCorner.Parent = toggleButton

                    Resize(25)
                end

                function elements:Slider(options)
                    if not options.text or not options.min or not options.max or not options.callback then
                        Notify("Slider", "Missing arguments!")
                        return
                    end

                    local Slider = Instance.new("Frame")
                    local sliderLabel = Instance.new("TextLabel")
                    local sliderFrame = Instance.new("TextButton")
                    local sliderBall = Instance.new("TextButton")
                    local sliderBallCorner = Instance.new("UICorner")
                    local sliderTextBox = Instance.new("TextBox")
                    buttoneffect({frame = sliderLabel, entered = Slider})

                    local Value
                    local Held = false

                    local UIS = UserInputService
                    local RS = game:GetService("RunService")
                    local Mouse = LocalPlayer:GetMouse()

                    local percentage = 0
                    local step = 0.01

                    local function snap(number, factor)
                        if factor == 0 then
                            return number
                        else
                            return math.floor(number/factor+0.5)*factor
                        end
                    end

                    UIS.InputEnded:Connect(function()
                        Held = false
                    end)

                    Slider.Name = "Slider"
                    Slider.Parent = sectionFrame
                    Slider.BackgroundTransparency = 1
                    Slider.Size = UDim2.new(0, 200, 0, 22)

                    sliderLabel.Name = "sliderLabel"
                    sliderLabel.Parent = Slider
                    sliderLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderLabel.Position = UDim2.new(0.2, 0, 0.5, 0)
                    sliderLabel.Size = UDim2.new(0, 77, 0, 22)
                    sliderLabel.Font = Enum.Font.Gotham
                    sliderLabel.Text = " " .. options.text
                    sliderLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    sliderLabel.TextSize = 14
                    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sliderLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
                        sliderLabel.TextScaled = sliderLabel.TextBounds.X > 75
                    end)

                    sliderFrame.Name = "sliderFrame"
                    sliderFrame.Parent = sliderLabel
                    sliderFrame.BackgroundColor3 = Color3.fromRGB(29, 87, 118)
                    sliderFrame.BorderSizePixel = 0
                    sliderFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderFrame.Position = UDim2.new(1.6, 0, 0.5, 0)
                    sliderFrame.Size = UDim2.new(0, 72, 0, 2)
                    sliderFrame.Text = ""
                    sliderFrame.AutoButtonColor = false
                    sliderFrame.MouseButton1Down:Connect(function()
                        Held = true
                    end)

                    sliderBall.Name = "sliderBall"
                    sliderBall.Parent = sliderFrame
                    sliderBall.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderBall.BackgroundColor3 = Color3.fromRGB(67, 136, 231)
                    sliderBall.BorderSizePixel = 0
                    sliderBall.Position = UDim2.new(0, 0, 0.5, 0)
                    sliderBall.Size = UDim2.new(0, 14, 0, 14)
                    sliderBall.AutoButtonColor = false
                    sliderBall.Font = Enum.Font.SourceSans
                    sliderBall.Text = ""
                    sliderBall.MouseButton1Down:Connect(function()
                        Held = true
                    end)

                    RS.RenderStepped:Connect(function()
                        if Held then
                            local BtnPos = sliderBall.Position
                            local MousePos = UIS:GetMouseLocation().X
                            local FrameSize = sliderFrame.AbsoluteSize.X
                            local FramePos = sliderFrame.AbsolutePosition.X
                            local pos = snap((MousePos - FramePos) / FrameSize, step)
                            percentage = math.clamp(pos, 0, 0.9)
                            Value = ((((tonumber(options.max) - tonumber(options.min)) / 0.9) * percentage)) + tonumber(options.min)
                            Value = round(Value, options.float)
                            Value = math.clamp(Value, options.min, options.max)
                            sliderTextBox.Text = Value
                            options.callback(Value)
                            sliderBall.Position = UDim2.new(percentage, 0, BtnPos.Y.Scale, BtnPos.Y.Offset)
                        end
                    end)

                    sliderBallCorner.CornerRadius = UDim.new(0, 50)
                    sliderBallCorner.Parent = sliderBall

                    sliderTextBox.Name = "sliderTextBox"
                    sliderTextBox.Parent = sliderLabel
                    sliderTextBox.BackgroundColor3 = Color3.fromRGB(1, 7, 17)
                    sliderTextBox.AnchorPoint = Vector2.new(0.5, 0.5)
                    sliderTextBox.Position = UDim2.new(2.4, 0, 0.5, 0)
                    sliderTextBox.Size = UDim2.new(0, 31, 0, 15)
                    sliderTextBox.Font = Enum.Font.Gotham
                    sliderTextBox.Text = tostring(options.min)
                    sliderTextBox.TextColor3 = Color3.fromRGB(234, 239, 245)
                    sliderTextBox.TextSize = 11
                    sliderTextBox.TextWrapped = true

                    sliderTextBox.Focused:Connect(function()
                        TweenService:Create(sliderLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextColor3 = Color3.fromRGB(234, 239, 246) }):Play()
                    end)

                    sliderTextBox.FocusLost:Connect(function(enterPressed)
                        TweenService:Create(sliderLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { TextColor3 = Color3.fromRGB(157, 171, 182) }):Play()
                        if enterPressed and sliderTextBox.Text and sliderTextBox.Text ~= "" then
                            local num = tonumber(sliderTextBox.Text)
                            if num > options.max then
                                sliderTextBox.Text = tostring(options.max)
                                options.callback(options.max)
                            elseif num < options.min then
                                sliderTextBox.Text = tostring(options.min)
                                options.callback(options.min)
                            else
                                options.callback(num)
                            end
                        end
                    end)

                    Resize(25)
                end

                function elements:Dropdown(options)
                    if not options.text or not options.default or not options.list or not options.callback then
                        Notify("Dropdown", "Missing arguments!")
                        return
                    end

                    local dropYSize = 0
                    local Dropped = false

                    local Dropdown = Instance.new("Frame")
                    Dropdown.Name = "Dropdown"
                    Dropdown.Parent = sectionFrame
                    Dropdown.BackgroundTransparency = 1
                    Dropdown.Size = UDim2.new(0, 200, 0, 22)
                    Dropdown.ZIndex = 2

                    local dropdownLabel = Instance.new("TextLabel")
                    dropdownLabel.Name = "dropdownLabel"
                    dropdownLabel.Parent = Dropdown
                    dropdownLabel.BackgroundTransparency = 1
                    dropdownLabel.Size = UDim2.new(0, 105, 0, 22)
                    dropdownLabel.Font = Enum.Font.Gotham
                    dropdownLabel.Text = " " .. options.text
                    dropdownLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    dropdownLabel.TextSize = 14
                    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                    dropdownLabel.TextWrapped = true

                    local dropdownText = Instance.new("TextLabel")
                    dropdownText.Name = "dropdownText"
                    dropdownText.Parent = dropdownLabel
                    dropdownText.BackgroundColor3 = Color3.fromRGB(2, 5, 12)
                    dropdownText.Position = UDim2.new(1.0857, 0, 0.091, 0)
                    dropdownText.Size = UDim2.new(0, 87, 0, 18)
                    dropdownText.Font = Enum.Font.Gotham
                    dropdownText.Text = " " .. options.default
                    dropdownText.TextColor3 = Color3.fromRGB(234, 239, 245)
                    dropdownText.TextSize = 12
                    dropdownText.TextXAlignment = Enum.TextXAlignment.Left
                    dropdownText.TextWrapped = true

                    local dropdownArrow = Instance.new("ImageButton")
                    dropdownArrow.Name = "dropdownArrow"
                    dropdownArrow.Parent = dropdownText
                    dropdownArrow.BackgroundTransparency = 1
                    dropdownArrow.Position = UDim2.new(0.8736, 0, 0.1389, 0)
                    dropdownArrow.Size = UDim2.new(0, 11, 0, 13)
                    dropdownArrow.AutoButtonColor = false
                    dropdownArrow.Image = "rbxassetid://8008296380"
                    dropdownArrow.ImageColor3 = Color3.fromRGB(157, 171, 182)

                    local dropdownList = Instance.new("Frame")
                    dropdownList.Name = "dropdownList"
                    dropdownList.Parent = dropdownText
                    dropdownList.BackgroundColor3 = Color3.fromRGB(2, 5, 12)
                    dropdownList.Position = UDim2.new(0, 0, 1, 0)
                    dropdownList.Size = UDim2.new(0, 87, 0, 0)
                    dropdownList.ClipsDescendants = true
                    dropdownList.BorderSizePixel = 0
                    dropdownList.ZIndex = 10

                    local dropListLayout = Instance.new("UIListLayout")
                    dropListLayout.Name = "dropListLayout"
                    dropListLayout.Parent = dropdownList
                    dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    Resize(25)

                    for _, v in ipairs(options.list) do
                        local dropdownBtn = Instance.new("TextButton")
                        dropdownBtn.Name = "dropdownBtn"
                        dropdownBtn.Parent = dropdownList
                        dropdownBtn.BackgroundTransparency = 1
                        dropdownBtn.Size = UDim2.new(0, 87, 0, 18)
                        dropdownBtn.AutoButtonColor = false
                        dropdownBtn.Font = Enum.Font.Gotham
                        dropdownBtn.TextColor3 = Color3.fromRGB(234, 239, 245)
                        dropdownBtn.TextSize = 12
                        dropdownBtn.Text = v
                        dropdownBtn.ZIndex = 15
                        clickEffect({button = dropdownBtn, amount = 5})

                        dropYSize = dropYSize + 18
                        dropdownList.ZIndex = dropdownList.ZIndex - 1

                        dropdownBtn.MouseButton1Click:Connect(function()
                            dropdownText.Text = " " .. v
                            options.callback(v)
                        end)
                    end
                end

                function elements:Textbox(options)
                    if not options.text or not options.value or not options.callback then
                        Notify("Textbox", "Missing arguments!")
                        return
                    end

                    local Textbox = Instance.new("Frame")
                    Textbox.Name = "Textbox"
                    Textbox.Parent = sectionFrame
                    Textbox.BackgroundTransparency = 1
                    Textbox.Size = UDim2.new(0, 200, 0, 22)
                    buttoneffect({frame = Textbox, entered = Textbox})

                    local textBoxLabel = Instance.new("TextLabel")
                    textBoxLabel.Name = "textBoxLabel"
                    textBoxLabel.Parent = Textbox
                    textBoxLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    textBoxLabel.Position = UDim2.new(0.237, 0, 0.5, 0)
                    textBoxLabel.Size = UDim2.new(0, 99, 0, 22)
                    textBoxLabel.Font = Enum.Font.Gotham
                    textBoxLabel.Text = "  " .. options.text
                    textBoxLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    textBoxLabel.TextSize = 14
                    textBoxLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local textBox = Instance.new("TextBox")
                    textBox.Name = "textBox"
                    textBox.Parent = Textbox
                    textBox.AnchorPoint = Vector2.new(0.5, 0.5)
                    textBox.BackgroundColor3 = Color3.fromRGB(1, 7, 17)
                    textBox.Position = UDim2.new(0.85, 0, 0.5, 0)
                    textBox.Size = UDim2.new(0, 53, 0, 15)
                    textBox.Font = Enum.Font.Gotham
                    textBox.Text = tostring(options.value)
                    textBox.TextColor3 = Color3.fromRGB(234, 239, 245)
                    textBox.TextSize = 11
                    textBox.TextWrapped = true

                    Resize(25)

                    textBox.Focused:Connect(function()
                        TweenService:Create(textBoxLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextColor3 = Color3.fromRGB(234, 239, 246) }):Play()
                    end)

                    textBox.FocusLost:Connect(function(enterPressed)
                        TweenService:Create(textBoxLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextColor3 = Color3.fromRGB(157, 171, 182) }):Play()
                        if enterPressed and textBox.Text and textBox.Text ~= "" then
                            options.callback(textBox.Text)
                        end
                    end)
                end

                function elements:Colorpicker(options)
                    if not options.text or not options.color or not options.callback then
                        Notify("Colorpicker", "Missing arguments!")
                        return
                    end

                    local initialColor = options.color
                    local hue, sat, val = Color3.toHSV(initialColor)

                    local Colorpicker = Instance.new("Frame")
                    Colorpicker.Name = "Colorpicker"
                    Colorpicker.Parent = sectionFrame
                    Colorpicker.BackgroundTransparency = 1
                    Colorpicker.Size = UDim2.new(0, 200, 0, 22)
                    Colorpicker.ZIndex = 2

                    local colorpickerLabel = Instance.new("TextLabel")
                    colorpickerLabel.Name = "colorpickerLabel"
                    colorpickerLabel.Parent = Colorpicker
                    colorpickerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    colorpickerLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                    colorpickerLabel.Size = UDim2.new(0, 200, 0, 22)
                    colorpickerLabel.Font = Enum.Font.Gotham
                    colorpickerLabel.Text = " " .. options.text
                    colorpickerLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    colorpickerLabel.TextSize = 14
                    colorpickerLabel.TextXAlignment = Enum.TextXAlignment.Left

                    local colorpickerButton = Instance.new("ImageButton")
                    colorpickerButton.Name = "colorpickerButton"
                    colorpickerButton.Parent = colorpickerLabel
                    colorpickerButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    colorpickerButton.Position = UDim2.new(0.92, 0, 0.57, 0)
                    colorpickerButton.Size = UDim2.new(0, 15, 0, 15)
                    colorpickerButton.Image = "rbxassetid://8023491332"
                    colorpickerButton.MouseButton1Click:Connect(function()
                        colorpickerFrame.Visible = not colorpickerFrame.Visible
                        local vis = colorpickerFrame.Visible
                        TweenService:Create(colorpickerLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
                            TextColor3 = vis and Color3.fromRGB(234, 239, 246) or Color3.fromRGB(157, 171, 182)
                        }):Play()
                    end)

                    local colorpickerFrame = Instance.new("Frame")
                    colorpickerFrame.Name = "colorpickerFrame"
                    colorpickerFrame.Parent = Colorpicker
                    colorpickerFrame.Visible = false
                    colorpickerFrame.BackgroundColor3 = Color3.fromRGB(0, 10, 21)
                    colorpickerFrame.Position = UDim2.new(1.15, 0, 0.5, 0)
                    colorpickerFrame.Size = UDim2.new(0, 251, 0, 221)
                    colorpickerFrame.ZIndex = 15
                    Dragify(colorpickerFrame, Colorpicker)

                    -- RGB area
                    local RGB = Instance.new("ImageButton")
                    RGB.Name = "RGB"
                    RGB.Parent = colorpickerFrame
                    RGB.BackgroundTransparency = 1
                    RGB.Position = UDim2.new(0.067, 0, 0.068, 0)
                    RGB.Size = UDim2.new(0, 179, 0, 161)
                    RGB.Image = "rbxassetid://6523286724"
                    RGB.ZIndex = 16

                    local RGBCircle = Instance.new("ImageLabel")
                    RGBCircle.Name = "RGBCircle"
                    RGBCircle.Parent = RGB
                    RGBCircle.BackgroundTransparency = 1
                    RGBCircle.Size = UDim2.new(0, 14, 0, 14)
                    RGBCircle.Image = "rbxassetid://3926309567"
                    RGBCircle.ImageRectOffset = Vector2.new(628, 420)
                    RGBCircle.ImageRectSize = Vector2.new(48, 48)
                    RGBCircle.ZIndex = 16

                    local Darkness = Instance.new("ImageButton")
                    Darkness.Name = "Darkness"
                    Darkness.Parent = colorpickerFrame
                    Darkness.Position = UDim2.new(0.832, 0, 0.068, 0)
                    Darkness.Size = UDim2.new(0, 33, 0, 161)
                    Darkness.Image = "rbxassetid://156579757"
                    Darkness.ZIndex = 16

                    local DarknessCircle = Instance.new("Frame")
                    DarknessCircle.Name = "DarknessCircle"
                    DarknessCircle.Parent = Darkness
                    DarknessCircle.Position = UDim2.new(0, 0, 0, 0)
                    DarknessCircle.Size = UDim2.new(0, 33, 0, 5)
                    DarknessCircle.ZIndex = 16

                    local colorHex = Instance.new("TextLabel")
                    colorHex.Name = "colorHex"
                    colorHex.Parent = colorpickerFrame
                    colorHex.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
                    colorHex.Position = UDim2.new(0.0717, 0, 0.8507, 0)
                    colorHex.Size = UDim2.new(0, 94, 0, 24)
                    colorHex.Font = Enum.Font.GothamSemibold
                    colorHex.Text = "#FFFFFF"
                    colorHex.TextColor3 = Color3.fromRGB(234, 239, 245)
                    colorHex.TextSize = 14
                    colorHex.ZIndex = 16

                    local Copy = Instance.new("TextButton")
                    Copy.Name = "Copy"
                    Copy.Parent = colorpickerFrame
                    Copy.BackgroundColor3 = Color3.fromRGB(9, 8, 13)
                    Copy.Position = UDim2.new(0.7211, 0, 0.8507, 0)
                    Copy.Size = UDim2.new(0, 60, 0, 24)
                    Copy.AutoButtonColor = false
                    Copy.Font = Enum.Font.GothamSemibold
                    Copy.Text = "Copy"
                    Copy.TextColor3 = Color3.fromRGB(234, 239, 245)
                    Copy.TextSize = 14
                    Copy.ZIndex = 16
                    Resize(25)
                    
                    Copy.MouseButton1Click:Connect(function()
                        if setclipboard then
                            setclipboard(colorHex.Text)
                            Notify("Cryptweb:", colorHex.Text)
                            Notify("Cryptweb:", "Done!")
                        else
                            print(colorHex.Text)
                            Notify("Cryptweb:", colorHex.Text)
                            Notify("Cryptweb:", "Your exploit does not support 'setclipboard', so we've printed it out.")
                        end
                    end)

                    -- Colorpicker logic (using HSV conversion and mouse tracking)
                    local ceil, clamp, atan2, pi = math.ceil, math.clamp, math.atan2, math.pi
                    local to_hex = function(color)
                        return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
                    end

                    local color = {1, 1, 1}

                    local function update()
                        local realColor = Color3.fromHSV(color[1], color[2], color[3])
                        colorHex.Text = to_hex(realColor)
                    end

                    local function UpdateSlide()
                        local mouseLoc = LocalPlayer:GetMouse()
                        local y = mouseLoc.Y - Darkness.AbsolutePosition.Y
                        local maxY = Darkness.AbsoluteSize.Y
                        y = math.clamp(y, 0, maxY) / maxY
                        local cy = DarknessCircle.AbsoluteSize.Y / 2
                        color[3] = 1 - y
                        local realColor = Color3.fromHSV(color[1], color[2], color[3])
                        DarknessCircle.BackgroundColor3 = realColor
                        DarknessCircle.Position = UDim2.new(0, 0, y, -cy)
                        options.callback(realColor)
                        update()
                    end

                    local function UpdateRing()
                        local mouseLoc = LocalPlayer:GetMouse()
                        local x = math.clamp(mouseLoc.X - RGB.AbsolutePosition.X, 0, RGB.AbsoluteSize.X) / RGB.AbsoluteSize.X
                        local y = math.clamp(mouseLoc.Y - RGB.AbsolutePosition.Y, 0, RGB.AbsoluteSize.Y) / RGB.AbsoluteSize.Y
                        local cx = RGBCircle.AbsoluteSize.X / 2
                        local cy = RGBCircle.AbsoluteSize.Y / 2
                        RGBCircle.Position = UDim2.new(x, -cx, y, -cy)
                        color[1] = 1 - x
                        color[2] = 1 - y
                        local realColor = Color3.fromHSV(color[1], color[2], color[3])
                        Darkness.BackgroundColor3 = realColor
                        DarknessCircle.BackgroundColor3 = realColor
                        options.callback(realColor)
                        update()
                    end

                    local WheelDown, SlideDown = false, false

                    RGB.MouseButton1Down:Connect(function()
                        WheelDown = true
                        UpdateRing()
                    end)
                    Darkness.MouseButton1Down:Connect(function()
                        SlideDown = true
                        UpdateSlide()
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            WheelDown = false
                            SlideDown = false
                        end
                    end)
                    RGB.MouseMoved:Connect(function()
                        if WheelDown then
                            UpdateRing()
                        end
                    end)
                    Darkness.MouseMoved:Connect(function()
                        if SlideDown then
                            UpdateSlide()
                        end
                    end)
                end

                function elements:Keybind(options)
                    if not options.text or not options.default or not options.callback then
                        Notify("Keybind", "Missing arguments")
                        return
                    end

                    Resize(25)

                    local blacklisted = {
                        Return = true,
                        Space = true,
                        Tab = true,
                        W = true,
                        A = true,
                        S = true,
                        D = true,
                        I = true,
                        O = true,
                        Unknown = true
                    }

                    local short = {
                        RightControl = "RCtrl",
                        LeftControl = "LCtrl",
                        LeftShift = "LShift",
                        RightShift = "RShift",
                        MouseButton1 = "M1",
                        MouseButton2 = "M2",
                        LeftAlt = "LAlt",
                        RightAlt = "RAlt"
                    }

                    local oldKey = options.default.Name

                    local Keybind = Instance.new("Frame")
                    Keybind.Name = "Keybind"
                    Keybind.Parent = sectionFrame
                    Keybind.BackgroundTransparency = 1
                    Keybind.Size = UDim2.new(0, 200, 0, 22)
                    Keybind.ZIndex = 2
                    buttoneffect({frame = Keybind, entered = Keybind})

                    local keybindButton = Instance.new("TextButton")
                    keybindButton.Name = "keybindButton"
                    keybindButton.Parent = Keybind
                    keybindButton.AnchorPoint = Vector2.new(0.5, 0.5)
                    keybindButton.BackgroundTransparency = 1
                    keybindButton.Size = UDim2.new(0, 200, 0, 22)
                    keybindButton.AutoButtonColor = false
                    keybindButton.Font = Enum.Font.Gotham
                    keybindButton.Text = " " .. options.text
                    keybindButton.TextColor3 = Color3.fromRGB(157, 171, 182)
                    keybindButton.TextSize = 14
                    keybindButton.TextXAlignment = Enum.TextXAlignment.Left

                    local keybindLabel = Instance.new("TextLabel")
                    keybindLabel.Name = "keybindLabel"
                    keybindLabel.Parent = keybindButton
                    keybindLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                    keybindLabel.Position = UDim2.new(0.91, 0, 0.5, 0)
                    keybindLabel.Size = UDim2.new(0, 36, 0, 22)
                    keybindLabel.Font = Enum.Font.Gotham
                    keybindLabel.Text = short[oldKey] or oldKey
                    keybindLabel.TextColor3 = Color3.fromRGB(157, 171, 182)
                    keybindLabel.TextSize = 14
                    keybindLabel.TextXAlignment = Enum.TextXAlignment.Right

                    keybindButton.MouseButton1Click:Connect(function()
                        keybindLabel.Text = "... "
                        TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            TextColor3 = Color3.fromRGB(234, 239, 246)
                        }):Play()
                        TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                            TextColor3 = Color3.fromRGB(234, 239, 246)
                        }):Play()
                        local inputBegan = UserInputService.InputBegan:Wait()
                        if not blacklisted[inputBegan.KeyCode.Name] then
                            TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            keybindLabel.Text = short[inputBegan.KeyCode.Name] or inputBegan.KeyCode.Name
                            oldKey = inputBegan.KeyCode.Name
                        else
                            TweenService:Create(keybindButton, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            TweenService:Create(keybindLabel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                TextColor3 = Color3.fromRGB(157, 171, 182)
                            }):Play()
                            keybindLabel.Text = short[oldKey] or oldKey
                        end
                    end)

                    UserInputService.InputBegan:Connect(function(key, focused)
                        if not focused then
                            if key.KeyCode.Name == oldKey then
                                options.callback(oldKey)
                            end
                        end
                    end)
                end

                return elements
            end

            return sections
        end

        return tabs
    end

    return tabsections
end

return Library
