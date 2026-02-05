# AdminClient_FULL.lua - Part 2 (Lines 1001-2000)

```lua
-- Part 2 - Page Creation Functions

-- Create Tab Button
local function CreateTabButton(name, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "Tab"
	button.Text = name
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = Colors.Text
	button.BackgroundColor3 = AdminPanel.CurrentPage == name and Colors.Accent or Colors.Primary
	button.Size = UDim2.new(0, 120, 0, 30)
	button.LayoutOrder = order
	button.Parent = AdminPanel.MainFrame:FindFirstChild("TabBar")
	
	CreateUICorner(button, 6)
	
	button.MouseButton1Click:Connect(function()
		AdminPanel.SwitchPage(name)
	end)
	
	return button
end

-- Switch Page
function AdminPanel.SwitchPage(pageName)
	AdminPanel.CurrentPage = pageName
	
	-- Update tab buttons
	local tabBar = AdminPanel.MainFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, tab in ipairs(tabBar:GetChildren()) do
			if tab:IsA("TextButton") then
				if tab.Name == pageName .. "Tab" then
					tab.BackgroundColor3 = Colors.Accent
				else
					tab.BackgroundColor3 = Colors.Primary
				end
			end
		end
	end
	
	-- Clear content
	local contentFrame = AdminPanel.ContentFrame
	contentFrame:ClearAllChildren()
	
	-- Load page
	if pageName == "Dashboard" then
		CreateDashboardPage()
	elseif pageName == "Stats" then
		CreateStatsPage()
	elseif pageName == "Potions" then
		CreatePotionsPage()
	elseif pageName == "Rot Skills" then
		CreateRotSkillsPage()
	elseif pageName == "Events" then
		CreateEventsPage()
	elseif pageName == "Logs" then
		CreateLogsPage()
	end
end

-- Dashboard Page
function CreateDashboardPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "DashboardScroll"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = contentFrame
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame
	
	-- Welcome Section
	local welcomeFrame = Instance.new("Frame")
	welcomeFrame.Name = "WelcomeFrame"
	welcomeFrame.BackgroundColor3 = Colors.Secondary
	welcomeFrame.Size = UDim2.new(1, 0, 0, 80)
	welcomeFrame.Parent = scrollFrame
	
	CreateUICorner(welcomeFrame, 8)
	
	CreateTextLabel(welcomeFrame, "Welcome, " .. player.Name .. "!", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 20)
	
	CreateTextLabel(welcomeFrame, "Admin Panel - Full System v2.0", 
		UDim2.new(0, 15, 0, 40), UDim2.new(1, -30, 0, 30), 14)
	
	-- System Status
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "StatusFrame"
	statusFrame.BackgroundColor3 = Colors.Secondary
	statusFrame.Size = UDim2.new(1, 0, 0, 150)
	statusFrame.Parent = scrollFrame
	
	CreateUICorner(statusFrame, 8)
	
	CreateTextLabel(statusFrame, "System Status", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 25), 16)
	
	-- Status cards
	local cardsFrame = Instance.new("Frame")
	cardsFrame.Name = "CardsFrame"
	cardsFrame.BackgroundTransparency = 1
	cardsFrame.Size = UDim2.new(1, -30, 0, 100)
	cardsFrame.Position = UDim2.new(0, 15, 0, 40)
	cardsFrame.Parent = statusFrame
	
	local cardsLayout = Instance.new("UIListLayout")
	cardsLayout.FillDirection = Enum.FillDirection.Horizontal
	cardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardsLayout.Padding = UDim.new(0, 10)
	cardsLayout.Parent = cardsFrame
	
	local function CreateStatusCard(title, value, color)
		local card = Instance.new("Frame")
		card.BackgroundColor3 = color
		card.Size = UDim2.new(0.32, -7, 1, 0)
		card.Parent = cardsFrame
		
		CreateUICorner(card, 8)
		
		CreateTextLabel(card, title, 
			UDim2.new(0, 10, 0, 10), UDim2.new(1, -20, 0, 30), 14)
		
		CreateTextLabel(card, value, 
			UDim2.new(0, 10, 0, 45), UDim2.new(1, -20, 0, 40), 24)
		
		return card
	end
	
	CreateStatusCard("Active Players", tostring(#Players:GetPlayers()), Colors.Success)
	CreateStatusCard("Active Event", AdminPanel.ActiveEvent or "None", Colors.Accent)
	CreateStatusCard("System", "Online", Colors.Success)
	
	-- Quick Actions
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "ActionsFrame"
	actionsFrame.BackgroundColor3 = Colors.Secondary
	actionsFrame.Size = UDim2.new(1, 0, 0, 200)
	actionsFrame.Parent = scrollFrame
	
	CreateUICorner(actionsFrame, 8)
	
	CreateTextLabel(actionsFrame, "Quick Actions", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 25), 16)
	
	local buttonsFrame = Instance.new("Frame")
	buttonsFrame.BackgroundTransparency = 1
	buttonsFrame.Size = UDim2.new(1, -30, 0, 150)
	buttonsFrame.Position = UDim2.new(0, 15, 0, 40)
	buttonsFrame.Parent = actionsFrame
	
	local buttonsLayout = Instance.new("UIGridLayout")
	buttonsLayout.CellSize = UDim2.new(0.48, 0, 0, 40)
	buttonsLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	buttonsLayout.Parent = buttonsFrame
	
	CreateButton(buttonsFrame, "Refresh Player List", UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 0, 40), 
		function()
			UpdatePlayerList()
			ShowNotification("Player list refreshed!", "success")
		end)
	
	CreateButton(buttonsFrame, "Trigger Event", UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 0, 40), 
		function()
			AdminPanel.SwitchPage("Events")
		end)
	
	CreateButton(buttonsFrame, "Manage Stats", UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 0, 40), 
		function()
			AdminPanel.SwitchPage("Stats")
		end)
	
	CreateButton(buttonsFrame, "Give Potions", UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 0, 40), 
		function()
			AdminPanel.SwitchPage("Potions")
		end)
	
	-- Features List
	local featuresFrame = Instance.new("Frame")
	featuresFrame.Name = "FeaturesFrame"
	featuresFrame.BackgroundColor3 = Colors.Secondary
	featuresFrame.Size = UDim2.new(1, 0, 0, 250)
	featuresFrame.Parent = scrollFrame
	
	CreateUICorner(featuresFrame, 8)
	
	CreateTextLabel(featuresFrame, "Available Features", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 25), 16)
	
	local featuresList = Instance.new("ScrollingFrame")
	featuresList.BackgroundTransparency = 1
	featuresList.Size = UDim2.new(1, -30, 1, -45)
	featuresList.Position = UDim2.new(0, 15, 0, 40)
	featuresList.CanvasSize = UDim2.new(0, 0, 0, 400)
	featuresList.ScrollBarThickness = 4
	featuresList.Parent = featuresFrame
	
	local featuresLayout = Instance.new("UIListLayout")
	featuresLayout.SortOrder = Enum.SortOrder.LayoutOrder
	featuresLayout.Padding = UDim.new(0, 5)
	featuresLayout.Parent = featuresList
	
	local features = {
		"✓ 7 Event System (2x IQ, 2x Coins, Lucky Hour, etc.)",
		"✓ Complete Stat Management (IQ, Coins, Essence, Aura, RSToken, Rebirths)",
		"✓ Potion System (Luck, IQ, Aura, Essence, Speed)",
		"✓ Rot Skill Management (RSToken, EquippedSkill)",
		"✓ Event Notification System",
		"✓ Rate Limiting & Security",
		"✓ Operation History",
		"✓ Real-time Logging"
	}
	
	for _, feature in ipairs(features) do
		local label = CreateTextLabel(featuresList, feature, 
			UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 25), 13)
		label.TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Stats Page
function CreateStatsPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "StatsScroll"
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.Size = UDim2.new(1, 0, 1, 0)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 700)
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.Parent = contentFrame
	
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scrollFrame
	
	-- Title
	CreateTextLabel(scrollFrame, "Stat Management", 
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
	
	-- Stat Operations
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.BackgroundColor3 = Colors.Secondary
	statsFrame.Size = UDim2.new(1, 0, 0, 450)
	statsFrame.Parent = scrollFrame
	
	CreateUICorner(statsFrame, 8)
	
	CreateTextLabel(statsFrame, "Stat Operations", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	-- Stat Type Dropdown
	CreateTextLabel(statsFrame, "Stat Type:", 
		UDim2.new(0, 15, 0, 50), UDim2.new(0.25, 0, 0, 30), 14)
	
	local statDropdown = CreateDropdown(statsFrame, StatTypes, 
		UDim2.new(0.27, 0, 0, 50), UDim2.new(0.4, 0, 0, 35), nil)
	
	-- Amount Input
	CreateTextLabel(statsFrame, "Amount:", 
		UDim2.new(0, 15, 0, 100), UDim2.new(0.25, 0, 0, 30), 14)
	
	local amountInput = CreateTextBox(statsFrame, "Enter amount", 
		UDim2.new(0.27, 0, 0, 100), UDim2.new(0.4, 0, 0, 35))
	amountInput.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Buttons
	local buttonY = 150
	
	CreateButton(statsFrame, "Add Stat", 
		UDim2.new(0, 15, 0, buttonY), UDim2.new(0.3, -5, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local statType = statDropdown.GetSelected()
			local amount = tonumber(amountInput.Text)
			
			if not amount or amount <= 0 then
				ShowNotification("Invalid amount!", "error")
				return
			end
			
			SendCommand("AddStat", {
				Player = SelectedPlayer,
				Stat = statType,
				Amount = amount
			})
			
			ShowNotification("Adding " .. amount .. " " .. statType .. " to " .. SelectedPlayer, "success")
		end)
	
	CreateButton(statsFrame, "Remove Stat", 
		UDim2.new(0.35, 0, 0, buttonY), UDim2.new(0.3, -5, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local statType = statDropdown.GetSelected()
			local amount = tonumber(amountInput.Text)
			
			if not amount or amount <= 0 then
				ShowNotification("Invalid amount!", "error")
				return
			end
			
			SendCommand("RemoveStat", {
				Player = SelectedPlayer,
				Stat = statType,
				Amount = amount
			})
			
			ShowNotification("Removing " .. amount .. " " .. statType .. " from " .. SelectedPlayer, "success")
		end)
	
	CreateButton(statsFrame, "Reset Stat", 
		UDim2.new(0.7, 0, 0, buttonY), UDim2.new(0.28, 0, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local statType = statDropdown.GetSelected()
			
			SendCommand("ResetStat", {
				Player = SelectedPlayer,
				Stat = statType
			})
			
			ShowNotification("Resetting " .. statType .. " for " .. SelectedPlayer, "success")
		end)
	
	-- Info Section
	local infoFrame = Instance.new("Frame")
	infoFrame.BackgroundColor3 = Colors.Primary
	infoFrame.Size = UDim2.new(1, -30, 0, 220)
	infoFrame.Position = UDim2.new(0, 15, 0, 210)
	infoFrame.Parent = statsFrame
	
	CreateUICorner(infoFrame, 6)
	
	CreateTextLabel(infoFrame, "Available Stats:", 
		UDim2.new(0, 10, 0, 5), UDim2.new(1, -20, 0, 25), 14)
	
	local statsInfo = {
		"• IQ - Intelligence points",
		"• Coins - Currency",
		"• Essence - Special currency",
		"• Aura - Aura points",
		"• RSToken - Rot Skill tokens",
		"• Rebirths - Rebirth count",
		"• EquippedSkill - Currently equipped skill (1-10)"
	}
	
	for i, info in ipairs(statsInfo) do
		CreateTextLabel(infoFrame, info, 
			UDim2.new(0, 20, 0, 30 + (i-1)*25), UDim2.new(1, -40, 0, 20), 12).TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Potions Page
function CreatePotionsPage()
	local contentFrame = AdminPanel.ContentFrame
	
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PotionsScroll"
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
	CreateTextLabel(scrollFrame, "Potion Management", 
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
	
	-- Potion Operations
	local potionsFrame = Instance.new("Frame")
	potionsFrame.Name = "PotionsFrame"
	potionsFrame.BackgroundColor3 = Colors.Secondary
	potionsFrame.Size = UDim2.new(1, 0, 0, 350)
	potionsFrame.Parent = scrollFrame
	
	CreateUICorner(potionsFrame, 8)
	
	CreateTextLabel(potionsFrame, "Give Potions", 
		UDim2.new(0, 15, 0, 10), UDim2.new(1, -30, 0, 30), 16)
	
	-- Potion Type Dropdown
	CreateTextLabel(potionsFrame, "Potion Type:", 
		UDim2.new(0, 15, 0, 50), UDim2.new(0.25, 0, 0, 30), 14)
	
	local potionDropdown = CreateDropdown(potionsFrame, PotionTypes, 
		UDim2.new(0.27, 0, 0, 50), UDim2.new(0.4, 0, 0, 35), nil)
	
	-- Amount Input
	CreateTextLabel(potionsFrame, "Amount:", 
		UDim2.new(0, 15, 0, 100), UDim2.new(0.25, 0, 0, 30), 14)
	
	local amountInput = CreateTextBox(potionsFrame, "Enter amount", 
		UDim2.new(0.27, 0, 0, 100), UDim2.new(0.4, 0, 0, 35))
	amountInput.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Give Button
	CreateButton(potionsFrame, "Give Potion", 
		UDim2.new(0, 15, 0, 150), UDim2.new(0.45, 0, 0, 40),
		function()
			if not SelectedPlayer then
				ShowNotification("Please select a player!", "error")
				return
			end
			
			local potionType = potionDropdown.GetSelected()
			local amount = tonumber(amountInput.Text)
			
			if not amount or amount <= 0 then
				ShowNotification("Invalid amount!", "error")
				return
			end
			
			SendCommand("GivePotion", {
				Player = SelectedPlayer,
				PotionType = potionType,
				Amount = amount
			})
			
			ShowNotification("Giving " .. amount .. " " .. potionType .. " potion(s) to " .. SelectedPlayer, "success")
		end)
	
	-- Info Section
	local infoFrame = Instance.new("Frame")
	infoFrame.BackgroundColor3 = Colors.Primary
	infoFrame.Size = UDim2.new(1, -30, 0, 145)
	infoFrame.Position = UDim2.new(0, 15, 0, 200)
	infoFrame.Parent = potionsFrame
	
	CreateUICorner(infoFrame, 6)
	
	CreateTextLabel(infoFrame, "Available Potions:", 
		UDim2.new(0, 10, 0, 5), UDim2.new(1, -20, 0, 25), 14)
	
	local potionsInfo = {
		"• Luck - Boosts luck stat",
		"• IQ - Boosts IQ gain",
		"• Aura - Boosts aura gain",
		"• Essence - Boosts essence gain",
		"• Speed - Increases movement speed"
	}
	
	for i, info in ipairs(potionsInfo) do
		CreateTextLabel(infoFrame, info, 
			UDim2.new(0, 20, 0, 30 + (i-1)*22), UDim2.new(1, -40, 0, 20), 12).TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- Continue in Part 3...
```
