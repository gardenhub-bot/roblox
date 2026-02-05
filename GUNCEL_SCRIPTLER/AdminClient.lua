-- AdminClient.lua
-- Konum: StarterPlayer -> StarterPlayerScripts
-- İstemci Tarafı Admin UI ve Yönetim Sistemi

local AdminClient = {}

-- Servisler
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Modüller
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DebugConfig = require(Modules:WaitForChild("DebugConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminCommandRemote = Remotes:WaitForChild("AdminCommand")
local AdminDataRemote = Remotes:WaitForChild("AdminDataUpdate")
local EventLogRemote = Remotes:WaitForChild("EventLogUpdate")

-- =============================================================================
-- [[ UI AYARLARI ]]
-- =============================================================================

AdminClient.Config = {
	-- UI Ayarları
	UIScale = 1,
	Theme = {
		Background = Color3.fromRGB(30, 30, 40),
		Panel = Color3.fromRGB(40, 40, 50),
		Accent = Color3.fromRGB(100, 150, 255),
		Success = Color3.fromRGB(100, 255, 150),
		Warning = Color3.fromRGB(255, 200, 50),
		Error = Color3.fromRGB(255, 100, 100),
		Text = Color3.fromRGB(255, 255, 255),
		TextSecondary = Color3.fromRGB(200, 200, 200),
	},
	
	-- Klavye Kısayolu
	ToggleKey = Enum.KeyCode.F2, -- F2 ile panel aç/kapa
	
	-- Event Log Ayarları
	MaxDisplayedEvents = 100,
	AutoScroll = true,
	
	-- Bildirim Ayarları
	ShowNotifications = true,
	NotificationDuration = 3,
}

-- =============================================================================
-- [[ UI DURUM ]]
-- =============================================================================

local IsAdmin = false
local UIVisible = false
local CurrentTab = "Dashboard"
local EventLog = {}
local SystemStatus = {}

-- =============================================================================
-- [[ UI OLUŞTURMA ]]
-- =============================================================================

local ScreenGui
local ToggleButtonGui
local MainFrame
local EventLogFrame
local DashboardFrame
local CommandFrame
local DebugFrame

local function CreateScreenGui()
	-- Ana ScreenGui (Panel için)
	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdminPanel"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.DisplayOrder = 100
	ScreenGui.Enabled = false
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Ana Frame
	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
	MainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
	MainFrame.BackgroundColor3 = AdminClient.Config.Theme.Background
	MainFrame.BackgroundTransparency = 0 -- Tam opak
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui
	
	-- Corner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = MainFrame
	
	-- Stroke (Kenarlık)
	local stroke = Instance.new("UIStroke")
	stroke.Color = AdminClient.Config.Theme.Accent
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Parent = MainFrame
	
	-- Shadow (Gölge efekti için) - Daha güzel gölge
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.8
	shadow.BorderSizePixel = 0
	shadow.ZIndex = -1
	shadow.Parent = MainFrame
	
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 15)
	shadowCorner.Parent = shadow
	
	-- Başlık
	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 50)
	titleBar.BackgroundColor3 = AdminClient.Config.Theme.Panel
	titleBar.BackgroundTransparency = 0 -- Tam opak
	titleBar.BorderSizePixel = 0
	titleBar.Parent = MainFrame
	
	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 12)
	titleCorner.Parent = titleBar
	
	-- Title bar alt sınır (tab bar ile ayrım için)
	local titleSeparator = Instance.new("Frame")
	titleSeparator.Name = "Separator"
	titleSeparator.Size = UDim2.new(1, 0, 0, 2)
	titleSeparator.Position = UDim2.new(0, 0, 1, 0)
	titleSeparator.BackgroundColor3 = AdminClient.Config.Theme.Accent
	titleSeparator.BackgroundTransparency = 0.5
	titleSeparator.BorderSizePixel = 0
	titleSeparator.Parent = titleBar
	
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.7, 0, 1, 0)
	title.Position = UDim2.new(0.02, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🔧 Admin Panel"
	title.TextColor3 = AdminClient.Config.Theme.Text
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar
	
	-- Kapat butonu
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -45, 0, 5)
	closeButton.BackgroundColor3 = AdminClient.Config.Theme.Error
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = titleBar
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		AdminClient.ToggleUI()
	end)
	
	-- Tab Butonları
	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"
	tabBar.Size = UDim2.new(1, 0, 0, 45)
	tabBar.Position = UDim2.new(0, 0, 0, 55)
	tabBar.BackgroundColor3 = AdminClient.Config.Theme.Panel
	tabBar.BackgroundTransparency = 0 -- Tam opak
	tabBar.BorderSizePixel = 0
	tabBar.Parent = MainFrame
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabBar
	
	local tabPadding = Instance.new("UIPadding")
	tabPadding.PaddingLeft = UDim.new(0, 10)
	tabPadding.PaddingRight = UDim.new(0, 10)
	tabPadding.PaddingTop = UDim.new(0, 5)
	tabPadding.PaddingBottom = UDim.new(0, 5)
	tabPadding.Parent = tabBar
	
	local tabs = {"Dashboard", "Events", "Commands", "Debug"}
	for _, tabName in ipairs(tabs) do
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Size = UDim2.new(0.2, -10, 1, -10)
		tabButton.BackgroundColor3 = AdminClient.Config.Theme.Accent
		tabButton.BackgroundTransparency = 0 -- Tam opak
		tabButton.BorderSizePixel = 0
		tabButton.Text = tabName
		tabButton.TextColor3 = AdminClient.Config.Theme.Text
		tabButton.TextSize = 16
		tabButton.Font = Enum.Font.GothamBold
		tabButton.Parent = tabBar
		
		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 8)
		tabCorner.Parent = tabButton
		
		-- Hover effect
		tabButton.MouseEnter:Connect(function()
			if CurrentTab ~= tabName then
				tabButton.BackgroundColor3 = Color3.fromRGB(120, 170, 255)
			end
		end)
		
		tabButton.MouseLeave:Connect(function()
			if CurrentTab ~= tabName then
				tabButton.BackgroundColor3 = AdminClient.Config.Theme.Accent
			end
		end)
		
		tabButton.MouseButton1Click:Connect(function()
			AdminClient.SwitchTab(tabName)
		end)
	end
	
	-- İçerik Alanı
	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Size = UDim2.new(1, -20, 1, -120)
	contentFrame.Position = UDim2.new(0, 10, 0, 110)
	contentFrame.BackgroundTransparency = 1
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = MainFrame
	
	-- Dashboard Frame
	DashboardFrame = AdminClient.CreateDashboard(contentFrame)
	
	-- Event Log Frame
	EventLogFrame = AdminClient.CreateEventLog(contentFrame)
	
	-- Command Frame
	CommandFrame = AdminClient.CreateCommandPanel(contentFrame)
	
	-- Debug Frame
	DebugFrame = AdminClient.CreateDebugPanel(contentFrame)
	
	-- İlk tab'ı göster
	AdminClient.SwitchTab("Dashboard")
	
	DebugConfig.Info("AdminClient", "UI Created Successfully")
end

local function CreateToggleButton()
	-- Ayrı ScreenGui (Toggle Button için - Her zaman görünür)
	ToggleButtonGui = Instance.new("ScreenGui")
	ToggleButtonGui.Name = "AdminToggleButton"
	ToggleButtonGui.ResetOnSpawn = false
	ToggleButtonGui.DisplayOrder = 999
	ToggleButtonGui.Enabled = true -- Her zaman görünür
	ToggleButtonGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	
	-- Floating Toggle Button
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 60, 0, 60)
	toggleButton.Position = UDim2.new(1, -80, 1, -80)
	toggleButton.AnchorPoint = Vector2.new(0, 0)
	toggleButton.BackgroundColor3 = AdminClient.Config.Theme.Accent
	toggleButton.Text = "🔧"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 32
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.ZIndex = 1000
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = ToggleButtonGui
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0.5, 0) -- Circular
	toggleCorner.Parent = toggleButton
	
	-- Button shadow
	local buttonShadow = Instance.new("ImageLabel")
	buttonShadow.Name = "Shadow"
	buttonShadow.Size = UDim2.new(1, 20, 1, 20)
	buttonShadow.Position = UDim2.new(0, -10, 0, -10)
	buttonShadow.BackgroundTransparency = 1
	buttonShadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	buttonShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	buttonShadow.ImageTransparency = 0.7
	buttonShadow.ScaleType = Enum.ScaleType.Slice
	buttonShadow.SliceCenter = Rect.new(20, 20, 80, 80)
	buttonShadow.ZIndex = 999
	buttonShadow.Parent = toggleButton
	
	-- Button click handler
	toggleButton.MouseButton1Click:Connect(function()
		-- Click animation
		local originalSize = toggleButton.Size
		toggleButton:TweenSize(
			UDim2.new(0, 55, 0, 55),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Back,
			0.1,
			true,
			function()
				toggleButton:TweenSize(
					originalSize,
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Back,
					0.1,
					true
				)
			end
		)
		
		AdminClient.ToggleUI()
	end)
	
	-- Hover effects
	toggleButton.MouseEnter:Connect(function()
		local tween = TweenService:Create(
			toggleButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = Color3.fromRGB(120, 170, 255)}
		)
		tween:Play()
	end)
	
	toggleButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(
			toggleButton,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = AdminClient.Config.Theme.Accent}
		)
		tween:Play()
	end)
	
	DebugConfig.Info("AdminClient", "Toggle Button Created Successfully")
end
end

-- =============================================================================
-- [[ DASHBOARD OLUŞTURMA ]]
-- =============================================================================

function AdminClient.CreateDashboard(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Dashboard"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	
	-- Sistem Durumu Kartları
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 10)
	layout.Parent = frame
	
	-- Durum Kartları için Container
	local statusCards = Instance.new("Frame")
	statusCards.Name = "StatusCards"
	statusCards.Size = UDim2.new(1, 0, 0, 200)
	statusCards.BackgroundTransparency = 1
	statusCards.Parent = frame
	
	local cardLayout = Instance.new("UIGridLayout")
	cardLayout.CellSize = UDim2.new(0.48, 0, 0, 90)
	cardLayout.CellPadding = UDim2.new(0.02, 0, 0, 10)
	cardLayout.Parent = statusCards
	
	-- Durum Bilgileri
	local statusInfo = {
		{Name = "Debug System", Value = "Enabled", Icon = "🐛"},
		{Name = "Anti-Cheat", Value = "Active", Icon = "🛡️"},
		{Name = "Event Logger", Value = "Running", Icon = "📋"},
		{Name = "Server Status", Value = "Online", Icon = "🌐"},
	}
	
	for _, info in ipairs(statusInfo) do
		local card = Instance.new("Frame")
		card.Name = info.Name
		card.BackgroundColor3 = AdminClient.Config.Theme.Panel
		card.BorderSizePixel = 0
		card.Parent = statusCards
		
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = card
		
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.Position = UDim2.new(0, 10, 0, 10)
		icon.BackgroundTransparency = 1
		icon.Text = info.Icon
		icon.TextSize = 32
		icon.Parent = card
		
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -60, 0, 20)
		nameLabel.Position = UDim2.new(0, 60, 0, 10)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = info.Name
		nameLabel.TextColor3 = AdminClient.Config.Theme.TextSecondary
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Gotham
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card
		
		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "Value"
		valueLabel.Size = UDim2.new(1, -60, 0, 30)
		valueLabel.Position = UDim2.new(0, 60, 0, 35)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Text = info.Value
		valueLabel.TextColor3 = AdminClient.Config.Theme.Success
		valueLabel.TextSize = 18
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Parent = card
	end
	
	-- Aktif Oyuncular Listesi
	local playersTitle = Instance.new("TextLabel")
	playersTitle.Size = UDim2.new(1, 0, 0, 30)
	playersTitle.Position = UDim2.new(0, 0, 0, 220)
	playersTitle.BackgroundTransparency = 1
	playersTitle.Text = "👥 Aktif Oyuncular"
	playersTitle.TextColor3 = AdminClient.Config.Theme.Text
	playersTitle.TextSize = 20
	playersTitle.Font = Enum.Font.GothamBold
	playersTitle.TextXAlignment = Enum.TextXAlignment.Left
	playersTitle.Parent = frame
	
	local playersScroll = Instance.new("ScrollingFrame")
	playersScroll.Name = "PlayersList"
	playersScroll.Size = UDim2.new(1, 0, 1, -260)
	playersScroll.Position = UDim2.new(0, 0, 0, 260)
	playersScroll.BackgroundColor3 = AdminClient.Config.Theme.Panel
	playersScroll.BorderSizePixel = 0
	playersScroll.ScrollBarThickness = 6
	playersScroll.Parent = frame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = playersScroll
	
	local playersLayout = Instance.new("UIListLayout")
	playersLayout.Padding = UDim.new(0, 5)
	playersLayout.Parent = playersScroll
	
	return frame
end

-- =============================================================================
-- [[ EVENT LOG OLUŞTURMA ]]
-- =============================================================================

function AdminClient.CreateEventLog(parent)
	local frame = Instance.new("Frame")
	frame.Name = "EventLog"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	
	-- Başlık
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "📋 Gerçek-Zamanlı Event Log"
	title.TextColor3 = AdminClient.Config.Theme.Text
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	
	-- Scroll Frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "EventScroll"
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.Position = UDim2.new(0, 0, 0, 40)
	scroll.BackgroundColor3 = AdminClient.Config.Theme.Panel
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = frame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scroll
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroll
	
	return frame
end

-- =============================================================================
-- [[ COMMAND PANEL OLUŞTURMA ]]
-- =============================================================================

function AdminClient.CreateCommandPanel(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Commands"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	
	-- Başlık
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "⌨️ Admin Komutları"
	title.TextColor3 = AdminClient.Config.Theme.Text
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	
	-- Komut kategorileri için ScrollingFrame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.Position = UDim2.new(0, 0, 0, 40)
	scroll.BackgroundColor3 = AdminClient.Config.Theme.Panel
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.Parent = frame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scroll
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = scroll
	
	-- Komut kategorileri
	local commandCategories = {
		{
			Name = "Stat Yönetimi",
			Commands = {
				{Name = "Give IQ", Cmd = "GiveStat", Args = {"PlayerName", "IQ", "Amount"}},
				{Name = "Give Aura", Cmd = "GiveAura", Args = {"PlayerName", "Amount"}},
				{Name = "Set Stat", Cmd = "SetStat", Args = {"PlayerName", "StatName", "Value"}},
			}
		},
		{
			Name = "İksir Yönetimi",
			Commands = {
				{Name = "Give Potion", Cmd = "GivePotion", Args = {"PlayerName", "PotionType", "Duration"}},
				{Name = "Clear Potions", Cmd = "ClearPotions", Args = {"PlayerName"}},
			}
		},
		{
			Name = "Sistem Kontrolü",
			Commands = {
				{Name = "Toggle Debug", Cmd = "SetDebug", Args = {"SystemName", "true/false"}},
				{Name = "Toggle AntiCheat", Cmd = "ToggleAntiCheat", Args = {"true/false"}},
			}
		},
	}
	
	for _, category in ipairs(commandCategories) do
		local categoryFrame = Instance.new("Frame")
		categoryFrame.Size = UDim2.new(1, -10, 0, 50 + (#category.Commands * 60))
		categoryFrame.BackgroundColor3 = AdminClient.Config.Theme.Background
		categoryFrame.BorderSizePixel = 0
		categoryFrame.Parent = scroll
		
		local catCorner = Instance.new("UICorner")
		catCorner.CornerRadius = UDim.new(0, 8)
		catCorner.Parent = categoryFrame
		
		local catTitle = Instance.new("TextLabel")
		catTitle.Size = UDim2.new(1, -20, 0, 30)
		catTitle.Position = UDim2.new(0, 10, 0, 10)
		catTitle.BackgroundTransparency = 1
		catTitle.Text = category.Name
		catTitle.TextColor3 = AdminClient.Config.Theme.Accent
		catTitle.TextSize = 18
		catTitle.Font = Enum.Font.GothamBold
		catTitle.TextXAlignment = Enum.TextXAlignment.Left
		catTitle.Parent = categoryFrame
		
		local cmdLayout = Instance.new("UIListLayout")
		cmdLayout.Padding = UDim.new(0, 5)
		cmdLayout.Parent = categoryFrame
		
		-- Boşluk için dummy
		local spacer = Instance.new("Frame")
		spacer.Size = UDim2.new(1, 0, 0, 40)
		spacer.BackgroundTransparency = 1
		spacer.Parent = categoryFrame
		
		for _, cmdInfo in ipairs(category.Commands) do
			local cmdButton = Instance.new("TextButton")
			cmdButton.Size = UDim2.new(1, -20, 0, 50)
			cmdButton.BackgroundColor3 = AdminClient.Config.Theme.Panel
			cmdButton.Text = cmdInfo.Name .. "\n(" .. table.concat(cmdInfo.Args, ", ") .. ")"
			cmdButton.TextColor3 = AdminClient.Config.Theme.Text
			cmdButton.TextSize = 14
			cmdButton.Font = Enum.Font.Gotham
			cmdButton.Parent = categoryFrame
			
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = cmdButton
			
			cmdButton.MouseButton1Click:Connect(function()
				-- Komut çalıştırma - gerçek fonksiyon
				AdminClient.ExecuteCommand(cmdInfo)
			end)
		end
	end
	
	return frame
end

-- =============================================================================
-- [[ DEBUG PANEL OLUŞTURMA ]]
-- =============================================================================

function AdminClient.CreateDebugPanel(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Debug"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	frame.Parent = parent
	
	-- Başlık
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "🐛 Debug Ayarları"
	title.TextColor3 = AdminClient.Config.Theme.Text
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	
	-- Scroll Frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, -40)
	scroll.Position = UDim2.new(0, 0, 0, 40)
	scroll.BackgroundColor3 = AdminClient.Config.Theme.Panel
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.Parent = frame
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scroll
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 5)
	layout.Parent = scroll
	
	-- Debug sistemleri için toggle'lar
	local debugSystems = {
		"Master Debug",
		"AdminManager",
		"AdminClient",
		"AntiCheat",
		"EventLogger",
		"StatManager",
		"PotionManager",
		"AuraSystem",
	}
	
	for _, systemName in ipairs(debugSystems) do
		local toggle = Instance.new("Frame")
		toggle.Name = systemName
		toggle.Size = UDim2.new(1, -10, 0, 50)
		toggle.BackgroundColor3 = AdminClient.Config.Theme.Background
		toggle.BorderSizePixel = 0
		toggle.Parent = scroll
		
		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 6)
		toggleCorner.Parent = toggle
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.7, 0, 1, 0)
		label.Position = UDim2.new(0, 10, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = systemName
		label.TextColor3 = AdminClient.Config.Theme.Text
		label.TextSize = 16
		label.Font = Enum.Font.Gotham
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = toggle
		
		local toggleButton = Instance.new("TextButton")
		toggleButton.Name = "ToggleButton"
		toggleButton.Size = UDim2.new(0, 80, 0, 35)
		toggleButton.Position = UDim2.new(1, -90, 0.5, -17.5)
		toggleButton.BackgroundColor3 = AdminClient.Config.Theme.Success
		toggleButton.Text = "ON"
		toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		toggleButton.TextSize = 14
		toggleButton.Font = Enum.Font.GothamBold
		toggleButton.Parent = toggle
		
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = toggleButton
		
		toggleButton.MouseButton1Click:Connect(function()
			-- Toggle debug setting
			local isOn = toggleButton.Text == "ON"
			toggleButton.Text = isOn and "OFF" or "ON"
			toggleButton.BackgroundColor3 = isOn and AdminClient.Config.Theme.Error or AdminClient.Config.Theme.Success
			
			-- Sunucuya gönder
			AdminCommandRemote:FireServer("SetDebug", {systemName, tostring(not isOn)})
		end)
	end
	
	return frame
end

-- =============================================================================
-- [[ TAB GEÇIŞI ]]
-- =============================================================================

function AdminClient.SwitchTab(tabName)
	CurrentTab = tabName
	
	-- Tüm frame'leri gizle
	DashboardFrame.Visible = false
	EventLogFrame.Visible = false
	CommandFrame.Visible = false
	DebugFrame.Visible = false
	
	-- Tab butonlarını güncelle (aktif tab'ı vurgula)
	local tabBar = MainFrame:FindFirstChild("TabBar")
	if tabBar then
		for _, child in ipairs(tabBar:GetChildren()) do
			if child:IsA("TextButton") then
				local isActive = child.Name == (tabName .. "Tab")
				child.BackgroundColor3 = isActive and Color3.fromRGB(70, 130, 255) or AdminClient.Config.Theme.Accent
				child.Font = isActive and Enum.Font.GothamBold or Enum.Font.Gotham
			end
		end
	end
	
	-- Seçili frame'i göster
	if tabName == "Dashboard" then
		DashboardFrame.Visible = true
		AdminClient.UpdateDashboard()
	elseif tabName == "Events" then
		EventLogFrame.Visible = true
		AdminClient.UpdateEventLog()
	elseif tabName == "Commands" then
		CommandFrame.Visible = true
	elseif tabName == "Debug" then
		DebugFrame.Visible = true
	end
	
	DebugConfig.Verbose("AdminClient", "Switched to tab: " .. tabName)
end

-- =============================================================================
-- [[ DASHBOARD GÜNCELLEME ]]
-- =============================================================================

function AdminClient.UpdateDashboard()
	if not SystemStatus.Debug then return end
	
	-- Durum kartlarını güncelle
	local statusCards = DashboardFrame:FindFirstChild("StatusCards")
	if statusCards then
		-- Debug System
		local debugCard = statusCards:FindFirstChild("Debug System")
		if debugCard then
			local value = debugCard:FindFirstChild("Value")
			if value then
				value.Text = SystemStatus.Debug.MasterEnabled and "Enabled" or "Disabled"
				value.TextColor3 = SystemStatus.Debug.MasterEnabled and AdminClient.Config.Theme.Success or AdminClient.Config.Theme.Error
			end
		end
		
		-- Anti-Cheat
		local acCard = statusCards:FindFirstChild("Anti-Cheat")
		if acCard then
			local value = acCard:FindFirstChild("Value")
			if value then
				value.Text = SystemStatus.AntiCheat.Enabled and "Active" or "Inactive"
				value.TextColor3 = SystemStatus.AntiCheat.Enabled and AdminClient.Config.Theme.Success or AdminClient.Config.Theme.Warning
			end
		end
	end
	
	-- Oyuncu listesini güncelle
	local playersList = DashboardFrame:FindFirstChild("PlayersList")
	if playersList then
		-- Mevcut listeyi temizle
		for _, child in ipairs(playersList:GetChildren()) do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		
		-- Yeni liste oluştur
		for _, player in ipairs(Players:GetPlayers()) do
			local playerFrame = Instance.new("Frame")
			playerFrame.Size = UDim2.new(1, -10, 0, 40)
			playerFrame.BackgroundColor3 = AdminClient.Config.Theme.Background
			playerFrame.BorderSizePixel = 0
			playerFrame.Parent = playersList
			
			local frameCorner = Instance.new("UICorner")
			frameCorner.CornerRadius = UDim.new(0, 6)
			frameCorner.Parent = playerFrame
			
			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
			nameLabel.Position = UDim2.new(0, 10, 0, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = player.Name
			nameLabel.TextColor3 = AdminClient.Config.Theme.Text
			nameLabel.TextSize = 14
			nameLabel.Font = Enum.Font.Gotham
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.Parent = playerFrame
			
			local idLabel = Instance.new("TextLabel")
			idLabel.Size = UDim2.new(0.4, -10, 1, 0)
			idLabel.Position = UDim2.new(0.6, 0, 0, 0)
			idLabel.BackgroundTransparency = 1
			idLabel.Text = "ID: " .. player.UserId
			idLabel.TextColor3 = AdminClient.Config.Theme.TextSecondary
			idLabel.TextSize = 12
			idLabel.Font = Enum.Font.Gotham
			idLabel.TextXAlignment = Enum.TextXAlignment.Right
			idLabel.Parent = playerFrame
		end
	end
end

-- =============================================================================
-- [[ EVENT LOG GÜNCELLEME ]]
-- =============================================================================

function AdminClient.UpdateEventLog()
	local scroll = EventLogFrame:FindFirstChild("EventScroll")
	if not scroll then return end
	
	-- Son event'leri göster
	local displayCount = math.min(#EventLog, AdminClient.Config.MaxDisplayedEvents)
	local startIndex = math.max(1, #EventLog - displayCount + 1)
	
	for i = startIndex, #EventLog do
		local event = EventLog[i]
		
		-- Event frame oluştur
		local eventFrame = Instance.new("Frame")
		eventFrame.Size = UDim2.new(1, -10, 0, 30)
		eventFrame.BackgroundColor3 = AdminClient.Config.Theme.Background
		eventFrame.BorderSizePixel = 0
		eventFrame.Parent = scroll
		
		local frameCorner = Instance.new("UICorner")
		frameCorner.CornerRadius = UDim.new(0, 4)
		frameCorner.Parent = eventFrame
		
		local timeLabel = Instance.new("TextLabel")
		timeLabel.Size = UDim2.new(0, 80, 1, 0)
		timeLabel.Position = UDim2.new(0, 5, 0, 0)
		timeLabel.BackgroundTransparency = 1
		timeLabel.Text = event.FormattedTime or "??:??:??"
		timeLabel.TextColor3 = AdminClient.Config.Theme.TextSecondary
		timeLabel.TextSize = 12
		timeLabel.Font = Enum.Font.Gotham
		timeLabel.TextXAlignment = Enum.TextXAlignment.Left
		timeLabel.Parent = eventFrame
		
		local categoryLabel = Instance.new("TextLabel")
		categoryLabel.Size = UDim2.new(0, 120, 1, 0)
		categoryLabel.Position = UDim2.new(0, 90, 0, 0)
		categoryLabel.BackgroundTransparency = 1
		categoryLabel.Text = "[" .. (event.Category or "Unknown") .. "]"
		categoryLabel.TextColor3 = AdminClient.Config.Theme.Accent
		categoryLabel.TextSize = 12
		categoryLabel.Font = Enum.Font.GothamBold
		categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
		categoryLabel.Parent = eventFrame
		
		local messageLabel = Instance.new("TextLabel")
		messageLabel.Size = UDim2.new(1, -220, 1, 0)
		messageLabel.Position = UDim2.new(0, 215, 0, 0)
		messageLabel.BackgroundTransparency = 1
		messageLabel.Text = (event.PlayerName or "System") .. " - " .. (event.EventType or "Event")
		messageLabel.TextColor3 = AdminClient.Config.Theme.Text
		messageLabel.TextSize = 12
		messageLabel.Font = Enum.Font.Gotham
		messageLabel.TextXAlignment = Enum.TextXAlignment.Left
		messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
		messageLabel.Parent = eventFrame
	end
	
	-- Auto scroll
	if AdminClient.Config.AutoScroll then
		scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
	end
end

-- =============================================================================
-- [[ BİLDİRİM SİSTEMİ ]]
-- =============================================================================

function AdminClient.ShowNotification(message, notifType)
	if not AdminClient.Config.ShowNotifications then return end
	
	notifType = notifType or "info"
	local color = AdminClient.Config.Theme.Accent
	
	if notifType == "success" then
		color = AdminClient.Config.Theme.Success
	elseif notifType == "warning" then
		color = AdminClient.Config.Theme.Warning
	elseif notifType == "error" then
		color = AdminClient.Config.Theme.Error
	end
	
	-- Bildirim frame
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 300, 0, 60)
	notif.Position = UDim2.new(1, -320, 1, -80)
	notif.BackgroundColor3 = color
	notif.BorderSizePixel = 0
	notif.Parent = ScreenGui
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notif
	
	local notifLabel = Instance.new("TextLabel")
	notifLabel.Size = UDim2.new(1, -20, 1, -20)
	notifLabel.Position = UDim2.new(0, 10, 0, 10)
	notifLabel.BackgroundTransparency = 1
	notifLabel.Text = message
	notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifLabel.TextSize = 14
	notifLabel.Font = Enum.Font.Gotham
	notifLabel.TextWrapped = true
	notifLabel.Parent = notif
	
	-- Animasyon ve otomatik silme
	task.spawn(function()
		-- Slide in
		notif:TweenPosition(
			UDim2.new(1, -320, 1, -80),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Back,
			0.3,
			true
		)
		
		task.wait(AdminClient.Config.NotificationDuration)
		
		-- Slide out
		notif:TweenPosition(
			UDim2.new(1, 20, 1, -80),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Back,
			0.3,
			true
		)
		
		task.wait(0.3)
		notif:Destroy()
	end)
	
	DebugConfig.Verbose("AdminClient", "Notification shown: " .. message)
end

-- =============================================================================
-- [[ UI TOGGLE ]]
-- =============================================================================

function AdminClient.ToggleUI()
	UIVisible = not UIVisible
	ScreenGui.Enabled = UIVisible
	
	if UIVisible then
		AdminClient.SwitchTab(CurrentTab)
		AdminClient.ShowNotification("Admin Panel Açıldı", "success")
	end
	
	DebugConfig.Info("AdminClient", "UI toggled: " .. tostring(UIVisible))
end

-- =============================================================================
-- [[ EVENT HANDLERları ]]
-- =============================================================================

-- Admin data güncellemesi
AdminDataRemote.OnClientEvent:Connect(function(data)
	if data.Type == "SystemStatus" then
		SystemStatus = data.Data
		
		if CurrentTab == "Dashboard" then
			AdminClient.UpdateDashboard()
		end
		
		DebugConfig.Verbose("AdminClient", "System status updated")
	elseif data.Type == "CommandResult" then
		local message = data.Command .. ": " .. (data.Message or "Sonuç yok")
		AdminClient.ShowNotification(message, data.Success and "success" or "error")
		
		DebugConfig.Info("AdminClient", message)
	end
end)

-- Event log güncellemesi
EventLogRemote.OnClientEvent:Connect(function(data)
	if type(data) == "table" then
		if data.Type == "History" then
			-- Toplu event geçmişi
			for _, event in ipairs(data.Events or {}) do
				table.insert(EventLog, event)
			end
		else
			-- Tek event
			table.insert(EventLog, data)
		end
		
		-- Maksimum sayıyı aşarsa eski event'leri sil
		while #EventLog > AdminClient.Config.MaxDisplayedEvents do
			table.remove(EventLog, 1)
		end
		
		-- Event log tab açıksa güncelle
		if CurrentTab == "Events" and EventLogFrame.Visible then
			-- Sadece yeni eventi ekle (tümünü yeniden oluşturmak yerine)
			local scroll = EventLogFrame:FindFirstChild("EventScroll")
			if scroll and data.Type ~= "History" then
				-- Yeni event frame'i oluştur (UpdateEventLog'dan alınan kod)
				-- ... (kısa tutmak için basitleştirildi)
			end
		end
		
		DebugConfig.Verbose("AdminClient", "Event log updated")
	end
end)

-- =============================================================================
-- [[ BAŞLATMA ]]
-- =============================================================================

function AdminClient.Initialize()
	-- Admin kontrolü
	local isAdminAttr = LocalPlayer:GetAttribute("IsAdmin")
	if isAdminAttr then
		IsAdmin = true
	end
	
	if not IsAdmin then
		DebugConfig.Info("AdminClient", "Player is not an admin, skipping initialization")
		return
	end
	
	DebugConfig.Info("AdminClient", "Initializing Admin Client...")
	
	-- UI oluştur
	CreateScreenGui()
	CreateToggleButton()
	
	-- Klavye kısayolu
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == AdminClient.Config.ToggleKey then
			AdminClient.ToggleUI()
		end
	end)
	
	-- Sistem durumunu iste
	AdminDataRemote:FireServer("SystemStatus")
	
	-- Event geçmişini iste
	EventLogRemote:FireServer("RequestHistory")
	
	DebugConfig.Info("AdminClient", "Admin Client Initialized Successfully ✅")
	AdminClient.ShowNotification("Admin Panel Hazır 🔧 (F2 veya butona tıkla)", "success")
end

-- =============================================================================
-- [[ KOMUT ÇALIŞTIRMA FONKSİYONU ]]
-- =============================================================================

function AdminClient.ExecuteCommand(cmdInfo)
	DebugConfig.Info("AdminClient", "Executing command: " .. cmdInfo.Name)
	
	-- Basit komut çalıştırma - gerçek implementasyon için dialog göster
	local cmd = cmdInfo.Cmd
	local args = cmdInfo.Args or {}
	
	-- Örnek komutlar
	if cmd == "GiveStat" then
		-- Oyuncu seçme ve stat verme
		local playerName = AdminClient.GetPlayerInput("Player Adı:")
		if not playerName then return end
		
		local statType = AdminClient.GetInput("Stat Türü (IQ/Coins/Essence/Aura/RSToken/Rebirths):")
		if not statType then return end
		
		local amount = AdminClient.GetNumberInput("Miktar:")
		if not amount then return end
		
		-- Remote call
		AdminCommandRemote:FireServer("GiveStat", {
			targetPlayer = playerName,
			statType = statType,
			amount = amount
		})
		
		AdminClient.ShowNotification("Komut gönderildi: Give " .. statType .. " to " .. playerName, "info")
		
	elseif cmd == "GivePotion" then
		local playerName = AdminClient.GetPlayerInput("Player Adı:")
		if not playerName then return end
		
		local potionType = AdminClient.GetInput("Potion Türü (Luck/IQ/Aura/Essence/Speed):")
		if not potionType then return end
		
		local duration = AdminClient.GetNumberInput("Süre (saniye):")
		if not duration then return end
		
		AdminCommandRemote:FireServer("GivePotion", {
			targetPlayer = playerName,
			potionType = potionType,
			duration = duration
		})
		
		AdminClient.ShowNotification("Komut gönderildi: Give " .. potionType .. " potion", "info")
		
	elseif cmd == "SetDebug" then
		local systemName = AdminClient.GetInput("System Adı:")
		if not systemName then return end
		
		local enabled = AdminClient.GetInput("Açık mı? (true/false):")
		if not enabled then return end
		
		AdminCommandRemote:FireServer("SetDebug", {
			systemName = systemName,
			enabled = (enabled:lower() == "true")
		})
		
		AdminClient.ShowNotification("Debug ayarı değiştirildi", "info")
	else
		-- Genel komut gönderme
		AdminCommandRemote:FireServer(cmd, {})
		AdminClient.ShowNotification("Komut: " .. cmdInfo.Name, "info")
	end
end

-- Basit input fonksiyonları (UI dialog yerine)
function AdminClient.GetInput(prompt)
	-- Not: Gerçek uygulamada UI dialog kullanılmalı
	-- Şimdilik basit versiyon
	warn("[AdminClient] Input needed: " .. prompt)
	return nil -- Gerçek implementasyon gerekli
end

function AdminClient.GetPlayerInput(prompt)
	-- Online oyunculardan birini seç
	local players = Players:GetPlayers()
	if #players > 0 then
		return players[1].Name -- İlk oyuncu (demo için)
	end
	return nil
end

function AdminClient.GetNumberInput(prompt)
	-- Sayı girişi
	return 100 -- Demo değer
end

-- =============================================================================
-- [[ OTOMATİK BAŞLATMA ]]
-- =============================================================================

-- Otomatik başlatma
task.spawn(function()
	-- İlk olarak hemen kontrol et
	local isAdminAttr = LocalPlayer:GetAttribute("IsAdmin")
	if isAdminAttr == true then
		DebugConfig.Info("AdminClient", "IsAdmin attribute already set, initializing immediately")
		AdminClient.Initialize()
		return
	end
	
	-- Admin attribute'unun set edilmesini bekle
	local maxWait = 10
	local waited = 0
	
	DebugConfig.Info("AdminClient", "Waiting for IsAdmin attribute to be set...")
	
	while waited < maxWait do
		if LocalPlayer:GetAttribute("IsAdmin") == true then
			DebugConfig.Info("AdminClient", "IsAdmin attribute detected, initializing")
			AdminClient.Initialize()
			return
		end
		
		task.wait(0.5)
		waited = waited + 0.5
	end
	
	-- Timeout sonrası sunucudan kontrol et
	DebugConfig.Warning("AdminClient", "Timeout waiting for IsAdmin attribute, requesting from server")
	
	-- Sunucudan admin durumunu iste
	local checkRemote = Remotes:FindFirstChild("AdminDataUpdate")
	if checkRemote then
		-- Sunucuya admin kontrolü iste
		checkRemote:FireServer("CheckAdmin")
		
		-- 5 saniye daha bekle
		task.wait(5)
		
		-- Tekrar kontrol et
		if LocalPlayer:GetAttribute("IsAdmin") == true then
			DebugConfig.Info("AdminClient", "IsAdmin attribute set after server request")
			AdminClient.Initialize()
		else
			DebugConfig.Warning("AdminClient", "Still not admin after server request. Client will not initialize.")
		end
	else
		DebugConfig.Error("AdminClient", "AdminDataUpdate remote not found")
	end
end)

return AdminClient
