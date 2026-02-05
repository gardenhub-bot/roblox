# AdminClient_FULL.lua - Part 1 (Lines 1-1000)

```lua
-- AdminClient_FULL.lua
-- Tam özellikli admin paneli client scripti
-- Tüm 7 event, stat yönetimi, potion, rot skill sistemi
-- Event bildirimleri, 6 sayfa UI, dropdown menüler

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes (mevcut isimleri kullan)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminCommand = Remotes:WaitForChild("AdminCommand")
local AdminDataUpdate = Remotes:WaitForChild("AdminDataUpdate")
local EventLogUpdate = Remotes:WaitForChild("EventLogUpdate")
local EventVFXTrigger = Remotes:WaitForChild("EventVFXTrigger")

-- Debug Config
local DebugConfig = {
	Enabled = true,
	ShowInfo = true,
	ShowWarnings = true
}

local function DebugPrint(message, level)
	if not DebugConfig.Enabled then return end
	level = level or "INFO"
	
	if level == "INFO" and DebugConfig.ShowInfo then
		print("[AdminClient][INFO]", message)
	elseif level == "WARN" and DebugConfig.ShowWarnings then
		warn("[AdminClient][WARN]", message)
	elseif level == "ERROR" then
		warn("[AdminClient][ERROR]", message)
	end
end

-- Admin Panel Variables
local AdminPanel = {}
AdminPanel.IsOpen = false
AdminPanel.CurrentPage = "Dashboard"
AdminPanel.ScreenGui = nil
AdminPanel.MainFrame = nil
AdminPanel.ToggleButton = nil
AdminPanel.EventNotificationFrame = nil
AdminPanel.EventTimer = 0
AdminPanel.ActiveEvent = nil

-- Player List
local PlayerListCache = {}
local SelectedPlayer = nil

-- Event Types
local EventTypes = {
	"2x IQ",
	"2x Coins", 
	"Lucky Hour",
	"Speed Frenzy",
	"Golden Rush",
	"Rainbow Stars",
	"Essence Rain"
}

-- Stat Types
local StatTypes = {
	"IQ",
	"Coins",
	"Essence",
	"Aura",
	"RSToken",
	"Rebirths",
	"EquippedSkill"
}

-- Potion Types
local PotionTypes = {
	"Luck",
	"IQ",
	"Aura",
	"Essence",
	"Speed"
}

-- UI Colors
local Colors = {
	Primary = Color3.fromRGB(45, 45, 55),
	Secondary = Color3.fromRGB(55, 55, 65),
	Accent = Color3.fromRGB(100, 150, 255),
	Success = Color3.fromRGB(80, 200, 120),
	Warning = Color3.fromRGB(255, 200, 80),
	Error = Color3.fromRGB(255, 100, 100),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(200, 200, 200)
}

-- Utility Functions
local function CreateUICorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = parent
	return corner
end

local function CreateUIStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Colors.Accent
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function CreateTextLabel(parent, text, position, size, fontSize)
	local label = Instance.new("TextLabel")
	label.Name = text:gsub("%s", "") .. "Label"
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = fontSize or 14
	label.TextColor3 = Colors.Text
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Parent = parent
	return label
end

local function CreateButton(parent, text, position, size, callback)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s", "") .. "Button"
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.TextColor3 = Colors.Text
	button.BackgroundColor3 = Colors.Accent
	button.Position = position
	button.Size = size
	button.Parent = parent
	
	CreateUICorner(button, 6)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(120, 170, 255)
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			BackgroundColor3 = Colors.Accent
		}):Play()
	end)
	
	-- Click effect
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = size - UDim2.new(0, 4, 0, 4)
		}):Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = size
		}):Play()
	end)
	
	if callback then
		button.MouseButton1Click:Connect(callback)
	end
	
	return button
end

local function CreateTextBox(parent, placeholder, position, size)
	local textBox = Instance.new("TextBox")
	textBox.Name = placeholder:gsub("%s", "") .. "TextBox"
	textBox.PlaceholderText = placeholder
	textBox.Text = ""
	textBox.Font = Enum.Font.Gotham
	textBox.TextSize = 14
	textBox.TextColor3 = Colors.Text
	textBox.PlaceholderColor3 = Colors.TextDim
	textBox.BackgroundColor3 = Colors.Secondary
	textBox.Position = position
	textBox.Size = size
	textBox.ClearTextOnFocus = false
	textBox.Parent = parent
	
	CreateUICorner(textBox, 6)
	CreateUIStroke(textBox, Colors.Accent, 1)
	
	return textBox
end

local function CreateDropdown(parent, items, position, size, callback)
	local dropdown = Instance.new("Frame")
	dropdown.Name = "Dropdown"
	dropdown.BackgroundColor3 = Colors.Secondary
	dropdown.Position = position
	dropdown.Size = size
	dropdown.Parent = parent
	dropdown.ClipsDescendants = false
	dropdown.ZIndex = 100
	
	CreateUICorner(dropdown, 6)
	CreateUIStroke(dropdown, Colors.Accent, 1)
	
	local selectedLabel = Instance.new("TextLabel")
	selectedLabel.Name = "SelectedLabel"
	selectedLabel.Text = items[1] or "Select..."
	selectedLabel.Font = Enum.Font.Gotham
	selectedLabel.TextSize = 14
	selectedLabel.TextColor3 = Colors.Text
	selectedLabel.BackgroundTransparency = 1
	selectedLabel.Size = UDim2.new(1, -30, 1, 0)
	selectedLabel.Position = UDim2.new(0, 10, 0, 0)
	selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
	selectedLabel.Parent = dropdown
	
	local arrowButton = Instance.new("TextButton")
	arrowButton.Name = "ArrowButton"
	arrowButton.Text = "▼"
	arrowButton.Font = Enum.Font.GothamBold
	arrowButton.TextSize = 12
	arrowButton.TextColor3 = Colors.Text
	arrowButton.BackgroundTransparency = 1
	arrowButton.Size = UDim2.new(0, 20, 1, 0)
	arrowButton.Position = UDim2.new(1, -25, 0, 0)
	arrowButton.Parent = dropdown
	
	local itemsList = Instance.new("ScrollingFrame")
	itemsList.Name = "ItemsList"
	itemsList.BackgroundColor3 = Colors.Primary
	itemsList.BorderSizePixel = 0
	itemsList.Position = UDim2.new(0, 0, 1, 5)
	itemsList.Size = UDim2.new(1, 0, 0, 0)
	itemsList.Visible = false
	itemsList.ScrollBarThickness = 4
	itemsList.CanvasSize = UDim2.new(0, 0, 0, #items * 35)
	itemsList.Parent = dropdown
	itemsList.ZIndex = 101
	
	CreateUICorner(itemsList, 6)
	CreateUIStroke(itemsList, Colors.Accent, 1)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = itemsList
	
	local function closeDropdown()
		itemsList.Visible = false
		arrowButton.Text = "▼"
		TweenService:Create(itemsList, TweenInfo.new(0.2), {
			Size = UDim2.new(1, 0, 0, 0)
		}):Play()
	end
	
	local function openDropdown()
		itemsList.Visible = true
		arrowButton.Text = "▲"
		local targetHeight = math.min(#items * 35, 200)
		TweenService:Create(itemsList, TweenInfo.new(0.2), {
			Size = UDim2.new(1, 0, 0, targetHeight)
		}):Play()
	end
	
	arrowButton.MouseButton1Click:Connect(function()
		if itemsList.Visible then
			closeDropdown()
		else
			openDropdown()
		end
	end)
	
	for i, item in ipairs(items) do
		local itemButton = Instance.new("TextButton")
		itemButton.Name = "Item" .. i
		itemButton.Text = item
		itemButton.Font = Enum.Font.Gotham
		itemButton.TextSize = 13
		itemButton.TextColor3 = Colors.Text
		itemButton.BackgroundColor3 = Colors.Secondary
		itemButton.Size = UDim2.new(1, -4, 0, 30)
		itemButton.Position = UDim2.new(0, 2, 0, (i-1) * 35)
		itemButton.Parent = itemsList
		itemButton.ZIndex = 102
		
		CreateUICorner(itemButton, 4)
		
		itemButton.MouseEnter:Connect(function()
			itemButton.BackgroundColor3 = Colors.Accent
		end)
		
		itemButton.MouseLeave:Connect(function()
			itemButton.BackgroundColor3 = Colors.Secondary
		end)
		
		itemButton.MouseButton1Click:Connect(function()
			selectedLabel.Text = item
			closeDropdown()
			if callback then
				callback(item)
			end
		end)
	end
	
	-- Click outside to close
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local dropdownPos = dropdown.AbsolutePosition
			local dropdownSize = dropdown.AbsoluteSize
			
			if itemsList.Visible then
				local isInside = mousePos.X >= dropdownPos.X and 
				                mousePos.X <= dropdownPos.X + dropdownSize.X and
				                mousePos.Y >= dropdownPos.Y and
				                mousePos.Y <= dropdownPos.Y + dropdownSize.Y + 205
				
				if not isInside then
					closeDropdown()
				end
			end
		end
	end)
	
	dropdown.GetSelected = function()
		return selectedLabel.Text
	end
	
	dropdown.SetSelected = function(item)
		selectedLabel.Text = item
	end
	
	dropdown.UpdateItems = function(newItems)
		items = newItems
		itemsList:ClearAllChildren()
		
		local newLayout = Instance.new("UIListLayout")
		newLayout.SortOrder = Enum.SortOrder.LayoutOrder
		newLayout.Padding = UDim.new(0, 2)
		newLayout.Parent = itemsList
		
		itemsList.CanvasSize = UDim2.new(0, 0, 0, #newItems * 35)
		
		for i, item in ipairs(newItems) do
			local itemButton = Instance.new("TextButton")
			itemButton.Name = "Item" .. i
			itemButton.Text = item
			itemButton.Font = Enum.Font.Gotham
			itemButton.TextSize = 13
			itemButton.TextColor3 = Colors.Text
			itemButton.BackgroundColor3 = Colors.Secondary
			itemButton.Size = UDim2.new(1, -4, 0, 30)
			itemButton.Position = UDim2.new(0, 2, 0, (i-1) * 35)
			itemButton.Parent = itemsList
			itemButton.ZIndex = 102
			
			CreateUICorner(itemButton, 4)
			
			itemButton.MouseEnter:Connect(function()
				itemButton.BackgroundColor3 = Colors.Accent
			end)
			
			itemButton.MouseLeave:Connect(function()
				itemButton.BackgroundColor3 = Colors.Secondary
			end)
			
			itemButton.MouseButton1Click:Connect(function()
				selectedLabel.Text = item
				closeDropdown()
				if callback then
					callback(item)
				end
			end)
		end
		
		if #newItems > 0 then
			selectedLabel.Text = newItems[1]
		end
	end
	
	return dropdown
end

-- Show Notification
local function ShowNotification(message, notifType)
	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.BackgroundColor3 = notifType == "success" and Colors.Success or 
	                         notifType == "error" and Colors.Error or
	                         Colors.Warning
	notif.Size = UDim2.new(0, 300, 0, 60)
	notif.Position = UDim2.new(1, 320, 0, 100)
	notif.Parent = AdminPanel.ScreenGui
	notif.ZIndex = 200
	
	CreateUICorner(notif, 8)
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Text = message
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 14
	textLabel.TextColor3 = Colors.Text
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, -20, 1, 0)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = notif
	
	-- Slide in
	TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(1, -320, 0, 100)
	}):Play()
	
	-- Wait and slide out
	task.wait(3)
	TweenService:Create(notif, TweenInfo.new(0.3), {
		Position = UDim2.new(1, 320, 0, 100)
	}):Play()
	
	task.wait(0.3)
	notif:Destroy()
end

-- Update Player List
local function UpdatePlayerList()
	PlayerListCache = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(PlayerListCache, plr.Name)
	end
	return PlayerListCache
end

-- Send Command to Server
local function SendCommand(action, data)
	local success, err = pcall(function()
		AdminCommand:FireServer(action, data)
	end)
	
	if not success then
		DebugPrint("Failed to send command: " .. tostring(err), "ERROR")
		ShowNotification("Command failed to send", "error")
	end
end

-- Create Event Notification UI (Top Banner)
local function CreateEventNotificationUI()
	local notifFrame = Instance.new("Frame")
	notifFrame.Name = "EventNotification"
	notifFrame.BackgroundColor3 = Colors.Accent
	notifFrame.Size = UDim2.new(0, 400, 0, 80)
	notifFrame.Position = UDim2.new(0.5, -200, 0, -100)
	notifFrame.AnchorPoint = Vector2.new(0.5, 0)
	notifFrame.Parent = AdminPanel.ScreenGui
	notifFrame.ZIndex = 150
	notifFrame.Visible = false
	
	CreateUICorner(notifFrame, 10)
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
	}
	gradient.Parent = notifFrame
	
	local eventTitle = Instance.new("TextLabel")
	eventTitle.Name = "EventTitle"
	eventTitle.Text = "EVENT ACTIVE"
	eventTitle.Font = Enum.Font.GothamBlack
	eventTitle.TextSize = 20
	eventTitle.TextColor3 = Colors.Text
	eventTitle.BackgroundTransparency = 1
	eventTitle.Size = UDim2.new(1, 0, 0, 30)
	eventTitle.Position = UDim2.new(0, 0, 0, 10)
	eventTitle.Parent = notifFrame
	
	local eventName = Instance.new("TextLabel")
	eventName.Name = "EventName"
	eventName.Text = "2x IQ"
	eventName.Font = Enum.Font.GothamBold
	eventName.TextSize = 16
	eventName.TextColor3 = Colors.Text
	eventName.BackgroundTransparency = 1
	eventName.Size = UDim2.new(1, 0, 0, 20)
	eventName.Position = UDim2.new(0, 0, 0, 35)
	eventName.Parent = notifFrame
	
	local eventTimer = Instance.new("TextLabel")
	eventTimer.Name = "EventTimer"
	eventTimer.Text = "5:00"
	eventTimer.Font = Enum.Font.Gotham
	eventTimer.TextSize = 14
	eventTimer.TextColor3 = Colors.Text
	eventTimer.BackgroundTransparency = 1
	eventTimer.Size = UDim2.new(1, 0, 0, 20)
	eventTimer.Position = UDim2.new(0, 0, 0, 55)
	eventTimer.Parent = notifFrame
	
	AdminPanel.EventNotificationFrame = notifFrame
	
	return notifFrame
end

-- Show Event Notification
local function ShowEventNotification(eventName, duration)
	if not AdminPanel.EventNotificationFrame then
		CreateEventNotificationUI()
	end
	
	local notifFrame = AdminPanel.EventNotificationFrame
	local eventNameLabel = notifFrame:FindFirstChild("EventName")
	local eventTimerLabel = notifFrame:FindFirstChild("EventTimer")
	
	if eventNameLabel then
		eventNameLabel.Text = eventName
	end
	
	AdminPanel.ActiveEvent = eventName
	AdminPanel.EventTimer = duration or 300
	
	notifFrame.Visible = true
	
	-- Slide down animation
	TweenService:Create(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
		Position = UDim2.new(0.5, -200, 0, 20)
	}):Play()
	
	-- Update timer
	task.spawn(function()
		while AdminPanel.EventTimer > 0 and AdminPanel.ActiveEvent == eventName do
			local minutes = math.floor(AdminPanel.EventTimer / 60)
			local seconds = AdminPanel.EventTimer % 60
			if eventTimerLabel then
				eventTimerLabel.Text = string.format("%d:%02d", minutes, seconds)
			end
			task.wait(1)
			AdminPanel.EventTimer = AdminPanel.EventTimer - 1
		end
		
		if AdminPanel.EventTimer <= 0 then
			HideEventNotification()
		end
	end)
end

-- Hide Event Notification
function HideEventNotification()
	if AdminPanel.EventNotificationFrame then
		local notifFrame = AdminPanel.EventNotificationFrame
		
		-- Slide up animation
		TweenService:Create(notifFrame, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, -200, 0, -100)
		}):Play()
		
		task.wait(0.3)
		notifFrame.Visible = false
	end
	
	AdminPanel.ActiveEvent = nil
	AdminPanel.EventTimer = 0
end

-- Create Toggle Button (Always visible)
local function CreateToggleButton()
	local buttonGui = Instance.new("ScreenGui")
	buttonGui.Name = "AdminToggleButton"
	buttonGui.ResetOnSpawn = false
	buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonGui.Parent = playerGui
	
	local button = Instance.new("TextButton")
	button.Name = "ToggleButton"
	button.Text = "🔧"
	button.Font = Enum.Font.GothamBlack
	button.TextSize = 24
	button.TextColor3 = Colors.Text
	button.BackgroundColor3 = Colors.Accent
	button.Size = UDim2.new(0, 60, 0, 60)
	button.Position = UDim2.new(1, -80, 1, -80)
	button.Parent = buttonGui
	button.ZIndex = 1000
	
	CreateUICorner(button, 30)
	
	-- Shadow effect
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.7
	shadow.Size = UDim2.new(1, 4, 1, 4)
	shadow.Position = UDim2.new(0, -2, 0, 2)
	shadow.ZIndex = 999
	shadow.Parent = button
	
	CreateUICorner(shadow, 30)
	
	-- Hover effect
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = UDim2.new(0, 65, 0, 65),
			BackgroundColor3 = Color3.fromRGB(120, 170, 255)
		}):Play()
	end)
	
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = UDim2.new(0, 60, 0, 60),
			BackgroundColor3 = Colors.Accent
		}):Play()
	end)
	
	-- Click animation
	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 55, 0, 55)
		}):Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.1), {
			Size = UDim2.new(0, 60, 0, 60)
		}):Play()
	end)
	
	button.MouseButton1Click:Connect(function()
		AdminPanel.TogglePanel()
	end)
	
	AdminPanel.ToggleButton = button
	
	return buttonGui
end

-- Create Main Panel
local function CreateMainPanel()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AdminPanel"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	
	AdminPanel.ScreenGui = screenGui
	
	-- Main Frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.BackgroundColor3 = Colors.Primary
	mainFrame.Size = UDim2.new(0, 800, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
	mainFrame.Parent = screenGui
	
	CreateUICorner(mainFrame, 12)
	CreateUIStroke(mainFrame, Colors.Accent, 2)
	
	AdminPanel.MainFrame = mainFrame
	
	-- Title Bar
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundColor3 = Colors.Secondary
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.Parent = mainFrame
	
	CreateUICorner(titleBar, 12)
	
	local titleLabel = CreateTextLabel(titleBar, "Admin Panel - Full System", 
		UDim2.new(0, 15, 0, 0), UDim2.new(0.6, 0, 1, 0), 18)
	
	local closeButton = CreateButton(titleBar, "✕", 
		UDim2.new(1, -45, 0, 10), UDim2.new(0, 30, 0, 30),
		function()
			AdminPanel.TogglePanel()
		end)
	closeButton.BackgroundColor3 = Colors.Error
	
	-- Tab Bar
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.BackgroundColor3 = Colors.Secondary
	tabBar.Size = UDim2.new(1, 0, 0, 45)
	tabBar.Position = UDim2.new(0, 0, 0, 50)
	tabBar.Parent = mainFrame
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 5)
	tabLayout.Parent = tabBar
	
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 10)
	tabPadding.PaddingTop = UDim.new(0, 7)
	tabPadding.Parent = tabBar
	
	-- Content Frame
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.BackgroundTransparency = 1
	contentFrame.Size = UDim2.new(1, -20, 1, -115)
	contentFrame.Position = UDim2.new(0, 10, 0, 105)
	contentFrame.Parent = mainFrame
	
	AdminPanel.ContentFrame = contentFrame
	
	return screenGui
end

-- Continue in Part 2...
```
