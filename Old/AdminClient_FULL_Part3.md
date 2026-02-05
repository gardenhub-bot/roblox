# AdminClient_FULL.lua - Part 3 (Lines 2001-3000 - FINAL)

```lua
-- Part 3 - Rot Skills, Events, Logs Pages and Event Handlers

-- Rot Skills Page
function CreateRotSkillsPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "RotSkillsScroll"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = contentFrame
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame
	
	-- Title
	CreateTextLabel(scrollFrame, "Rot Skill Management", 
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 18)
	
	-- Player Selection
	local playerFrame = Instance.new("Frame")
	playerFrame.Name = "PlayerFrame"
	playerFrame.BackgroundColor3 = Colors.Secondary
	playerFrame.Size = UDim2.new(1, 0, 0, 100)
	playerFrame.Parent = scrollFrame
	
	CreateUICorner(playerFrame, 8)
	
	CreateTextLabel(playerFrame, "Select Player:", 
		UDim2.new(0, 15, 0, 10), UDim2.new(0.3, 0, 0, 30), 14)
	
	UpdatePlayerList()
	local playerDropdown = CreateDropdown(playerFrame, PlayerListCache, 
		UDim2.new(0, 15, 0, 45), UDim2.new(0.6, 0, 0, 35),
		function(selected)
			SelectedPlayer = selected
		end)
	
	CreateButton(playerFrame, "Refresh", 
		UDim2.new(0.65, 0, 0, 45), UDim2.new(0.3, 0, 0, 35),
		function()
			UpdatePlayerList()
			playerDropdown.UpdateItems(PlayerListCache)
			ShowNotification("Player list updated!", "success")
		end)
	
	-- RSToken Operations
	local tokenFrame = Instance.new("Frame")
	tokenFrame.Name = "TokenFrame"
	tokenFrame.BackgroundColor3 = Colors.Secondary
	tokenFrame.Size = UDim2.new(1, 0, 0, 180)
	tokenFrame.Parent = scrollFrame
	
	CreateUICorner(tokenFrame, 8)
	
	CreateTextLabel(tokenFrame, "RSToken Operations", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	CreateTextLabel(tokenFrame, "Amount:", 
		UDim2.new(0, 15, 0, 50), UDim2.new(0.25, 0, 0, 30), 14)
	
	local tokenAmountInput = CreateTextBox(tokenFrame, "Enter token amount", 
		UDim2.new(0.27, 0, 0, 50), UDim2.new(0.4, 0, 0, 35))
	tokenAmountInput.TextXAlignment = Enum.TextXAlignment.Left
	
	CreateButton(tokenFrame, "Give RSToken", 
		UDim2.new(0, 15, 0, 100), UDim2.new(0.45, 0, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local amount = tonumber(tokenAmountInput.Text)
			
			if not amount or amount <= 0 then
				ShowNotification("Invalid amount!", "error")
				return
			end
			
			SendCommand("GiveRSToken", {
				Player = SelectedPlayer,
				Amount = amount
			})
			
			ShowNotification("Giving " .. amount .. " RSToken to " .. SelectedPlayer, "success")
		end)
	
	-- EquippedSkill Operations
	local skillFrame = Instance.new("Frame")
	skillFrame.Name = "SkillFrame"
	skillFrame.BackgroundColor3 = Colors.Secondary
	skillFrame.Size = UDim2.new(1, 0, 0, 180)
	skillFrame.Parent = scrollFrame
	
	CreateUICorner(skillFrame, 8)
	
	CreateTextLabel(skillFrame, "Equipped Skill Operations", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	CreateTextLabel(skillFrame, "Skill (1-10):", 
		UDim2.new(0, 15, 0, 50), UDim2.new(0.25, 0, 0, 30), 14)
	
	local skillInput = CreateTextBox(skillFrame, "Enter skill number (1-10)", 
		UDim2.new(0.27, 0, 0, 50), UDim2.new(0.4, 0, 0, 35))
	skillInput.TextXAlignment = Enum.TextXAlignment.Left
	
	CreateButton(skillFrame, "Set Equipped Skill", 
		UDim2.new(0, 15, 0, 100), UDim2.new(0.45, 0, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local skillNum = tonumber(skillInput.Text)
			
			if not skillNum or skillNum < 1 or skillNum > 10 then
				ShowNotification("Skill must be between 1 and 10!", "error")
				return
			end
			
			SendCommand("SetEquippedSkill", {
				Player = SelectedPlayer,
				Skill = math.floor(skillNum)
			})
			
			ShowNotification("Setting EquippedSkill to " .. skillNum .. " for " .. SelectedPlayer, "success")
		end)
	
	-- Info Section
	local infoFrame = Instance.new("Frame")
	infoFrame.BackgroundColor3 = Colors.Primary
	infoFrame.Size = UDim2.new(1, 0, 0, 100)
	infoFrame.Parent = scrollFrame
	
	CreateUICorner(infoFrame, 6)
	
	CreateTextLabel(infoFrame, "Rot Skill System:", 
		UDim2.new(0, 10, 0, 5), UDim2.new(1, -20, 0, 25), 14)
	
	local info = {
		"• RSToken - Rot Skill tokens used to unlock skills",
		"• EquippedSkill - Currently equipped skill slot (1-10)"
	}
	
	for i, text in ipairs(info) do
		CreateTextLabel(infoFrame, text, 
			UDim2.new(0, 20, 0, 30 + (i-1)*22), UDim2.new(1, -40, 0, 20), 12).TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Events Page
function CreateEventsPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "EventsScroll"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = contentFrame
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame
	
	-- Title
	CreateTextLabel(scrollFrame, "Event Management", 
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 18)
	
	-- Event Trigger
	local triggerFrame = Instance.new("Frame")
	triggerFrame.Name = "TriggerFrame"
	triggerFrame.BackgroundColor3 = Colors.Secondary
	triggerFrame.Size = UDim2.new(1, 0, 0, 200)
	triggerFrame.Parent = scrollFrame
	
	CreateUICorner(triggerFrame, 8)
	
	CreateTextLabel(triggerFrame, "Trigger Event", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	CreateTextLabel(triggerFrame, "Event Type:", 
		UDim2.new(0, 15, 0, 50), UDim2.new(0.25, 0, 0, 30), 14)
	
	local eventDropdown = CreateDropdown(triggerFrame, EventTypes, 
		UDim2.new(0.27, 0, 0, 50), UDim2.new(0.4, 0, 0, 35), nil)
	
	CreateTextLabel(triggerFrame, "Duration (seconds):", 
		UDim2.new(0, 15, 0, 100), UDim2.new(0.25, 0, 0, 30), 14)
	
	local durationInput = CreateTextBox(triggerFrame, "300", 
		UDim2.new(0.27, 0, 0, 100), UDim2.new(0.4, 0, 0, 35))
	durationInput.Text = "300"
	durationInput.TextXAlignment = Enum.TextXAlignment.Left
	
	CreateButton(triggerFrame, "Start Event", 
		UDim2.new(0, 15, 0, 150), UDim2.new(0.45, 0, 0, 40),
		function()
			local eventType = eventDropdown.GetSelected()
			local duration = tonumber(durationInput.Text)
			
			if not duration or duration <= 0 then
				ShowNotification("Invalid duration!", "error")
				return
			end
			
			SendCommand("StartEvent", {
				EventType = eventType,
				Duration = duration
			})
			
			ShowNotification("Starting " .. eventType .. " event for " .. duration .. " seconds", "success")
		end)
	
	CreateButton(triggerFrame, "Stop Event", 
		UDim2.new(0.5, 0, 0, 150), UDim2.new(0.45, 0, 0, 40),
		function()
			local eventType = eventDropdown.GetSelected()
			
			SendCommand("StopEvent", {
				EventType = eventType
			})
			
			ShowNotification("Stopping " .. eventType .. " event", "success")
		end)
	
	-- Event List
	local eventsListFrame = Instance.new("Frame")
	eventsListFrame.Name = "EventsListFrame"
	eventsListFrame.BackgroundColor3 = Colors.Secondary
	eventsListFrame.Size = UDim2.new(1, 0, 0, 450)
	eventsListFrame.Parent = scrollFrame
	
	CreateUICorner(eventsListFrame, 8)
	
	CreateTextLabel(eventsListFrame, "Available Events", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	local eventsScroll = Instance.new("ScrollingFrame")
	eventsScroll.BackgroundTransparency = 1
	eventsScroll.Size = UDim2.new(1, -30, 1, -50)
	eventsScroll.Position = UDim2.new(0, 15, 0, 45)
	eventsScroll.CanvasSize = UDim2.new(0, 0, 0, 700)
	eventsScroll.ScrollBarThickness = 4
	eventsScroll.Parent = eventsListFrame
	
	local eventsLayout = Instance.new("UIListLayout")
	eventsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	eventsLayout.Padding = UDim.new(0, 8)
	eventsLayout.Parent = eventsScroll
	
	local eventDescriptions = {
		["2x IQ"] = "Doubles IQ gain for all players (IQMultiplier = 2)",
		["2x Coins"] = "Doubles coin gain for all players (CoinsMultiplier = 2)",
		["Lucky Hour"] = "Boosts luck stat for all players (LuckMultiplier = 1.5)",
		["Speed Frenzy"] = "Increases movement speed (SpeedMultiplier = 1.5)",
		["Golden Rush"] = "Increases essence gain (EssenceMultiplier = 2)",
		["Rainbow Stars"] = "Boosts aura gain (AuraMultiplier = 2)",
		["Essence Rain"] = "Essence boost + periodic essence drops (EssenceMultiplier = 1.5)"
	}
	
	for _, eventType in ipairs(EventTypes) do
		local eventCard = Instance.new("Frame")
		eventCard.BackgroundColor3 = Colors.Primary
		eventCard.Size = UDim2.new(1, -8, 0, 80)
		eventCard.Parent = eventsScroll
		
		CreateUICorner(eventCard, 6)
		
		local eventName = CreateTextLabel(eventCard, eventType, 
			UDim2.new(0, 10, 0, 5), UDim2.new(1, -20, 0, 25), 16)
		eventName.TextXAlignment = Enum.TextXAlignment.Left
		
		local eventDesc = CreateTextLabel(eventCard, eventDescriptions[eventType] or "Event description", 
			UDim2.new(0, 10, 0, 30), UDim2.new(1, -20, 0, 45), 12)
		eventDesc.TextXAlignment = Enum.TextXAlignment.Left
		eventDesc.TextWrapped = true
		eventDesc.TextColor3 = Colors.TextDim
	end
end

-- Logs Page
function CreateLogsPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local logsFrame = Instance.new("Frame")
	logsFrame.Name = "LogsFrame"
	logsFrame.BackgroundTransparency = 1
	logsFrame.Size = UDim2.new(1, 0, 1, 0)
	logsFrame.Parent = contentFrame
	
	-- Title
	CreateTextLabel(logsFrame, "Event Logs", 
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 30), 18)
	
	-- Logs Display
	local logsScroll = Instance.new("ScrollingFrame")
	logsScroll.Name = "LogsScroll"
	logsScroll.BackgroundColor3 = Colors.Secondary
	logsScroll.Size = UDim2.new(1, 0, 1, -40)
	logsScroll.Position = UDim2.new(0, 0, 0, 35)
	logsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	logsScroll.ScrollBarThickness = 6
	logsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	logsScroll.Parent = logsFrame
	
	CreateUICorner(logsScroll, 8)
	
	local logsLayout = Instance.new("UIListLayout")
	logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logsLayout.Padding = UDim.new(0, 2)
	logsLayout.Parent = logsScroll
	
	AdminPanel.LogsScroll = logsScroll
	
	-- Initial message
	local initialMsg = CreateTextLabel(logsScroll, "Waiting for events...", 
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), 12)
	initialMsg.TextXAlignment = Enum.TextXAlignment.Left
	initialMsg.TextColor3 = Colors.TextDim
end

-- Add Log Entry
local function AddLogEntry(message, logType)
	if not AdminPanel.LogsScroll then return end
	
	local color = Colors.Text
	if logType == "success" then
		color = Colors.Success
	elseif logType == "error" then
		color = Colors.Error
	elseif logType == "warning" then
		color = Colors.Warning
	end
	
	local timestamp = os.date("%H:%M:%S")
	local logText = string.format("[%s] %s", timestamp, message)
	
	local logLabel = CreateTextLabel(AdminPanel.LogsScroll, logText, 
		UDim2.new(0, 0, 0, 0), UDim2.new(1, -10, 0, 25), 12)
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextColor3 = color
	
	-- Auto-scroll to bottom
	AdminPanel.LogsScroll.CanvasPosition = Vector2.new(0, AdminPanel.LogsScroll.AbsoluteCanvasSize.Y)
end

-- Toggle Panel
function AdminPanel.TogglePanel()
	AdminPanel.IsOpen = not AdminPanel.IsOpen
	AdminPanel.ScreenGui.Enabled = AdminPanel.IsOpen
	
	if AdminPanel.IsOpen then
		DebugPrint("Admin panel opened")
		-- Refresh player list
		UpdatePlayerList()
		-- Switch to dashboard
		if AdminPanel.CurrentPage then
			AdminPanel.SwitchPage(AdminPanel.CurrentPage)
		else
			AdminPanel.SwitchPage("Dashboard")
		end
	else
		DebugPrint("Admin panel closed")
	end
end

-- Event Handlers
local function SetupEventHandlers()
	-- Admin Data Updates
	AdminDataUpdate.OnClientEvent:Connect(function(action, data)
		DebugPrint("Received admin data update: " .. tostring(action))
		
		if action == "SystemStatus" then
			-- Update system status
			AddLogEntry("System status updated", "info")
		elseif action == "CommandResult" then
			if data.Success then
				ShowNotification(data.Message or "Command successful!", "success")
				AddLogEntry(data.Message or "Command executed successfully", "success")
			else
				ShowNotification(data.Message or "Command failed!", "error")
				AddLogEntry(data.Message or "Command failed", "error")
			end
		end
	end)
	
	-- Event Log Updates
	EventLogUpdate.OnClientEvent:Connect(function(logData)
		if logData and logData.Message then
			local logType = logData.Type or "info"
			AddLogEntry(logData.Message, logType)
			
			-- If it's an event-related log, show notification
			if logData.Category == "Event" then
				ShowNotification(logData.Message, logType)
			end
		end
	end)
	
	-- Event VFX Triggers
	EventVFXTrigger.OnClientEvent:Connect(function(eventData)
		DebugPrint("Received event VFX trigger: " .. tostring(eventData.EventName))
		
		if eventData.Action == "Start" then
			ShowEventNotification(eventData.EventName, eventData.Duration)
			AddLogEntry("Event started: " .. eventData.EventName .. " for " .. eventData.Duration .. "s", "success")
		elseif eventData.Action == "Stop" then
			if AdminPanel.ActiveEvent == eventData.EventName then
				HideEventNotification()
			end
			AddLogEntry("Event stopped: " .. eventData.EventName, "warning")
		end
	end)
end

-- Initialize Admin Panel
local function Initialize()
	-- Check if player is admin (wait for IsAdmin attribute)
	local isAdmin = player:GetAttribute("IsAdmin")
	
	if not isAdmin then
		-- Wait up to 15 seconds for attribute
		local waited = 0
		while not isAdmin and waited < 15 do
			task.wait(1)
			waited = waited + 1
			isAdmin = player:GetAttribute("IsAdmin")
		end
		
		if not isAdmin then
			-- Request admin check from server
			pcall(function()
				AdminCommand:FireServer("CheckAdmin", {})
			end)
			
			-- Wait 5 more seconds
			task.wait(5)
			isAdmin = player:GetAttribute("IsAdmin")
		end
	end
	
	if not isAdmin then
		DebugPrint("Player is not an admin, admin panel will not load", "WARN")
		return
	end
	
	DebugPrint("Player is admin, initializing admin panel...")
	
	-- Create toggle button (always visible)
	CreateToggleButton()
	
	-- Create main panel (hidden by default)
	CreateMainPanel()
	
	-- Create event notification UI
	CreateEventNotificationUI()
	
	-- Create tabs
	CreateTabButton("Dashboard", 1)
	CreateTabButton("Stats", 2)
	CreateTabButton("Potions", 3)
	CreateTabButton("Rot Skills", 4)
	CreateTabButton("Events", 5)
	CreateTabButton("Logs", 6)
	
	-- Setup event handlers
	SetupEventHandlers()
	
	-- Initial page
	AdminPanel.SwitchPage("Dashboard")
	
	-- F2 hotkey
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.F2 then
			AdminPanel.TogglePanel()
		elseif input.KeyCode == Enum.KeyCode.Escape and AdminPanel.IsOpen then
			AdminPanel.TogglePanel()
		end
	end)
	
	DebugPrint("Admin Client initialized successfully! Press F2 or click the button to open panel.")
end

-- Run initialization
task.spawn(Initialize)
```
