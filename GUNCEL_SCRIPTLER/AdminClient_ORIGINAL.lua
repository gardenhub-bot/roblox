-- AdminClient (Tam hali - görsel sorunlar düzeltildi)
-- ✅ DEBUG/PRINT/LOG TOGGLE
local DEBUG_ENABLED = true
local function DebugPrint(...)
	if DEBUG_ENABLED then
		print("[AdminClient]", ...)
	end
end
local function DebugWarn(...)
	if DEBUG_ENABLED then
		warn("[AdminClient]", ...)
	end
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local InventoryConfig = require(Modules:WaitForChild("InventoryConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminEvent = Remotes:WaitForChild("AdminEvent")

local ScreenGui = script.Parent
local OpenBtn = ScreenGui:WaitForChild("OpenBtn")

-- ✅ AÇIK DROPDOWN TAKİBİ
local openDropdowns = {}
local activeDropdown = nil

local function CloseAllDropdowns()
	for _, dropdownInfo in pairs(openDropdowns) do
		if dropdownInfo and dropdownInfo.list and dropdownInfo.list.Parent then
			dropdownInfo.list.Visible = false
			if dropdownInfo.arrow then
				dropdownInfo.arrow.Rotation = 0
			end
		end
	end
	openDropdowns = {}
	activeDropdown = nil
end

-- ✅ DIŞARI TIKLANDIĞINDA DROPDOWN KAPAT
local function SetupDropdownClickAway()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local shouldClose = true

			-- Açık dropdown'larda tıklanıp tıklanmadığını kontrol et
			for _, dropdownInfo in pairs(openDropdowns) do
				if dropdownInfo.frame and dropdownInfo.frame:IsDescendantOf(game) then
					local absolutePosition = dropdownInfo.frame.AbsolutePosition
					local absoluteSize = dropdownInfo.frame.AbsoluteSize

					if mousePos.X >= absolutePosition.X and mousePos.X <= absolutePosition.X + absoluteSize.X and
						mousePos.Y >= absolutePosition.Y and mousePos.Y <= absolutePosition.Y + absoluteSize.Y then
						shouldClose = false
						break
					end

					-- Dropdown listesini kontrol et
					if dropdownInfo.list and dropdownInfo.list.Visible then
						local listPos = dropdownInfo.list.AbsolutePosition
						local listSize = dropdownInfo.list.AbsoluteSize

						if mousePos.X >= listPos.X and mousePos.X <= listPos.X + listSize.X and
							mousePos.Y >= listPos.Y and mousePos.Y <= listPos.Y + listSize.Y then
							shouldClose = false
							break
						end
					end
				end
			end

			if shouldClose then
				CloseAllDropdowns()
			end
		end
	end)
end

SetupDropdownClickAway()

-- ✅ ANA PANEL
local MainFrame = Instance.new("Frame")
MainFrame.Name = "AdminPanel_Final"
MainFrame.Size = UDim2.new(0.7, 0, 0.8, 0)
MainFrame.Position = UDim2.new(0.15, 0, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 1000
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", MainFrame)
UICorner.CornerRadius = UDim.new(0, 15)

local UIGradient = Instance.new("UIGradient")
UIGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 40))
})
UIGradient.Rotation = 45
UIGradient.Parent = MainFrame

-- ✅ SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0.22, 0, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
Sidebar.BackgroundTransparency = 0.05
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 1001
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 15, 0, 0)

local TabList = Instance.new("UIListLayout", Sidebar)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabList.Padding = UDim.new(0, 12)
TabList.SortOrder = Enum.SortOrder.LayoutOrder

local SidebarPadding = Instance.new("UIPadding", Sidebar)
SidebarPadding.PaddingTop = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 70)
Title.BackgroundTransparency = 1
Title.Text = "🛡️ ADMIN PANEL"
Title.TextColor3 = Color3.fromRGB(255, 170, 0)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 24
Title.TextStrokeTransparency = 0.3
Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
Title.ZIndex = 1002
Title.Parent = Sidebar

-- ✅ CONTENT ALANI
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(0.78, 0, 1, 0)
Content.Position = UDim2.new(0.22, 0, 0, 0)
Content.BackgroundTransparency = 1
Content.ZIndex = 1001
Content.Parent = MainFrame

local ContentCorner = Instance.new("UICorner", Content)
ContentCorner.CornerRadius = UDim.new(0, 0, 15, 0)

local Pages = {} 
local CurrentPage = nil
local CurrentTabButton = nil

-- ✅ MODERN TAB BUTTON
function CreateTabButton(name, icon, pageFrame)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0, 50)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	btn.BackgroundTransparency = 0.2
	btn.Text = icon .. "  " .. name
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.ZIndex = 1002
	btn.Parent = Sidebar

	local pad = Instance.new("UIPadding", btn)
	pad.PaddingLeft = UDim.new(0, 20)

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(70, 70, 80)
	stroke.Thickness = 2
	stroke.ZIndex = 1003

	btn.MouseEnter:Connect(function()
		if CurrentTabButton ~= btn then
			TweenService:Create(btn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.1,
				BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			}):Play()
		end
	end)

	btn.MouseLeave:Connect(function()
		if CurrentTabButton ~= btn then
			TweenService:Create(btn, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.2,
				BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			}):Play()
		end
	end)

	btn.MouseButton1Click:Connect(function()
		-- Tüm dropdown'ları kapat
		CloseAllDropdowns()

		-- Tüm sayfaları gizle
		for _, p in pairs(Pages) do 
			p.Visible = false 
		end

		-- Yeni sayfayı göster
		pageFrame.Visible = true
		CurrentPage = pageFrame

		-- Önceki tab butonunu sıfırla
		if CurrentTabButton then
			TweenService:Create(CurrentTabButton, TweenInfo.new(0.2), {
				BackgroundColor3 = Color3.fromRGB(40, 40, 45),
				BackgroundTransparency = 0.2,
				TextColor3 = Color3.fromRGB(240, 240, 240)
			}):Play()
			CurrentTabButton.UIStroke.Color = Color3.fromRGB(70, 70, 80)
		end

		-- Yeni tab butonunu aktif yap
		CurrentTabButton = btn
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(255, 170, 0),
			BackgroundTransparency = 0,
			TextColor3 = Color3.fromRGB(25, 25, 30)
		}):Play()
		btn.UIStroke.Color = Color3.fromRGB(255, 200, 100)
	end)

	return btn
end

-- ✅ MODERN PAGE
function CreatePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, -20, 1, -20)
	page.Position = UDim2.new(0, 10, 0, 10)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 6
	page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	page.ScrollBarImageTransparency = 0.5
	page.BorderSizePixel = 0
	page.Visible = false
	page.ZIndex = 1002
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Parent = Content

	local list = Instance.new("UIListLayout", page)
	list.Padding = UDim.new(0, 15)
	list.SortOrder = Enum.SortOrder.LayoutOrder

	table.insert(Pages, page)
	return page
end

-- ✅ MODERN SECTION
function AddSectionTitle(page, text)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 45)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 1003
	frame.Parent = page

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "📌 " .. text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 20
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextStrokeTransparency = 0.3
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.ZIndex = 1004
	lbl.Parent = frame

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, 0, 0, 2)
	line.Position = UDim2.new(0, 0, 1, -2)
	line.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
	line.BorderSizePixel = 0
	line.ZIndex = 1004
	line.Parent = frame

	return frame
end

-- ✅ MODERN INPUT
function AddInput(page, placeholder, defaultValue)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 1003
	frame.Parent = page

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 1, 0)
	box.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	box.BackgroundTransparency = 0.1
	box.PlaceholderText = placeholder
	box.Text = defaultValue or ""
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
	box.ClearTextOnFocus = false
	box.ZIndex = 1004
	box.Parent = frame

	local corner = Instance.new("UICorner", box)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", box)
	stroke.Color = Color3.fromRGB(80, 80, 90)
	stroke.Thickness = 2
	stroke.ZIndex = 1004

	box.Focused:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2), {
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(55, 55, 60)
		}):Play()
		TweenService:Create(box.UIStroke, TweenInfo.new(0.2), {
			Color = Color3.fromRGB(255, 170, 0)
		}):Play()
	end)

	box.FocusLost:Connect(function()
		TweenService:Create(box, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.1,
			BackgroundColor3 = Color3.fromRGB(45, 45, 50)
		}):Play()
		TweenService:Create(box.UIStroke, TweenInfo.new(0.2), {
			Color = Color3.fromRGB(80, 80, 90)
		}):Play()
	end)

	return box
end

-- ✅ MODERN DROPDOWN
function AddDropdown(page, options, defaultText)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 1003
	frame.Parent = page

	local mainBtn = Instance.new("TextButton")
	mainBtn.Size = UDim2.new(1, 0, 1, 0)
	mainBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	mainBtn.BackgroundTransparency = 0.1
	mainBtn.Text = defaultText
	mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	mainBtn.Font = Enum.Font.GothamBold
	mainBtn.TextSize = 14
	mainBtn.ZIndex = 1004
	mainBtn.Parent = frame

	local corner = Instance.new("UICorner", mainBtn)
	corner.CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", mainBtn)
	stroke.Color = Color3.fromRGB(80, 80, 90)
	stroke.Thickness = 2
	stroke.ZIndex = 1004

	local arrow = Instance.new("ImageLabel")
	arrow.Size = UDim2.new(0, 20, 0, 20)
	arrow.Position = UDim2.new(1, -25, 0.5, -10)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6031090990"
	arrow.ImageColor3 = Color3.fromRGB(200, 200, 200)
	arrow.ZIndex = 1005
	arrow.Parent = mainBtn

	local list = Instance.new("Frame")
	list.Visible = false
	list.Size = UDim2.new(1, 0, 0, math.min(#options * 45, 200))
	list.Position = UDim2.new(0, 0, 1, 5)
	list.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	list.BackgroundTransparency = 0
	list.ZIndex = 1006
	list.Parent = frame

	local corner2 = Instance.new("UICorner", list)
	corner2.CornerRadius = UDim.new(0, 8)

	local stroke2 = Instance.new("UIStroke", list)
	stroke2.Color = Color3.fromRGB(60, 60, 70)
	stroke2.Thickness = 2
	stroke2.ZIndex = 1006

	local ll = Instance.new("UIListLayout", list)
	ll.Padding = UDim.new(0, 2)

	local padding = Instance.new("UIPadding", list)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)

	local selected = nil

	-- Dropdown bilgisini kaydet
	local dropdownInfo = {
		frame = frame,
		list = list,
		arrow = arrow,
		mainBtn = mainBtn
	}
	table.insert(openDropdowns, dropdownInfo)

	for _, opt in ipairs(options) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -10, 0, 40)
		b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		b.BackgroundTransparency = 0.1
		b.Text = opt
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.ZIndex = 1007
		b.Parent = list

		local corner3 = Instance.new("UICorner", b)
		corner3.CornerRadius = UDim.new(0, 6)

		b.MouseButton1Click:Connect(function()
			selected = opt
			mainBtn.Text = opt
			list.Visible = false
			arrow.Rotation = 0

			-- Dropdown'ı açık listesinden çıkar
			for i, dd in ipairs(openDropdowns) do
				if dd == dropdownInfo then
					table.remove(openDropdowns, i)
					break
				end
			end

			TweenService:Create(mainBtn.UIStroke, TweenInfo.new(0.2), {
				Color = Color3.fromRGB(80, 80, 90)
			}):Play()
		end)

		b.MouseEnter:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.2), {
				BackgroundTransparency = 0,
				BackgroundColor3 = Color3.fromRGB(50, 50, 55)
			}):Play()
		end)

		b.MouseLeave:Connect(function()
			TweenService:Create(b, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.1,
				BackgroundColor3 = Color3.fromRGB(40, 40, 45)
			}):Play()
		end)
	end

	mainBtn.MouseButton1Click:Connect(function() 
		-- Önce tüm diğer dropdown'ları kapat
		CloseAllDropdowns()

		-- Sonra bu dropdown'ı aç
		list.Visible = not list.Visible
		if list.Visible then
			arrow.Rotation = 180
			TweenService:Create(mainBtn.UIStroke, TweenInfo.new(0.2), {
				Color = Color3.fromRGB(255, 170, 0)
			}):Play()

			-- Açık listesine ekle
			table.insert(openDropdowns, dropdownInfo)
		else
			arrow.Rotation = 0
			TweenService:Create(mainBtn.UIStroke, TweenInfo.new(0.2), {
				Color = Color3.fromRGB(80, 80, 90)
			}):Play()

			-- Açık listesinden çıkar
			for i, dd in ipairs(openDropdowns) do
				if dd == dropdownInfo then
					table.remove(openDropdowns, i)
					break
				end
			end
		end
	end)

	return function() return selected end
end

-- ✅ MODERN BUTTON
function AddButton(page, text, color, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 55)
	btn.BackgroundColor3 = color
	btn.BackgroundTransparency = 0.1
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 16
	btn.TextStrokeTransparency = 0.3
	btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	btn.ZIndex = 1004
	btn.Parent = page

	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = color:Lerp(Color3.new(0, 0, 0), 0.3)
	stroke.Thickness = 2
	stroke.ZIndex = 1004

	btn.MouseButton1Click:Connect(callback)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundTransparency = 0,
			Size = UDim2.new(1.02, 0, 0, 58)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.1,
			Size = UDim2.new(1, 0, 0, 55)
		}):Play()
	end)

	return btn
end

-- ✅ SAYFA 1: STATLAR
local StatPage = CreatePage("StatPage")
AddSectionTitle(StatPage, "🎯 Hedef Oyuncu")
local StatTarget = AddInput(StatPage, "Kullanıcı Adı veya ID (Boş = Sen)", "")

AddSectionTitle(StatPage, "📊 Stat Seçimi")
local GetStat = AddDropdown(StatPage, {
	"Coins", 
	"IQ", 
	"Rebirths", 
	"Essence",
	"Aura",
	"Luck",
	"ClickLvl",
	"WalkSpeedLvl",
	"MaxHatch",
	"DamageLvl",
	"CoinsLvl"
}, "Stat Seçiniz ▼")

local StatAmount = AddInput(StatPage, "Miktar", "")

local resetConfirm = false
AddButton(StatPage, "📥 STAT EKLE", Color3.fromRGB(0, 170, 255), function()
	local s = GetStat()
	if s then
		AdminEvent:FireServer("Player", "AddStat", {
			Target = StatTarget.Text,
			Stat = s,
			Amount = tonumber(StatAmount.Text) or 0
		})
	end
end)

AddButton(StatPage, "⚠️ TÜM VERİLERİ SIFIRLA", Color3.fromRGB(200, 50, 50), function()
	if not resetConfirm then
		resetConfirm = true
		warn("⚠️ Tüm verileri sıfırlamak için tekrar tıklayın!")
		task.delay(3, function() resetConfirm = false end)
		return
	end

	AdminEvent:FireServer("Player", "ResetStats", {
		Target = StatTarget.Text,
		Confirm = true
	})
	resetConfirm = false
end)

-- ✅ SAYFA 2: İKSİRLER
local PotPage = CreatePage("PotPage")
AddSectionTitle(PotPage, "🎯 Hedef Oyuncu")
local PotTarget = AddInput(PotPage, "Kullanıcı Adı veya ID (Boş = Sen)", "")

AddSectionTitle(PotPage, "🧪 İksir Türü")
local GetPotionType = AddDropdown(PotPage, {
	"IQ", "Damage", "Coins", "Essence", 
	"Aura", "Luck", "Speed"
}, "İksir Türü ▼")

AddSectionTitle(PotPage, "📦 İksir Boyutu")
local GetPotionSize = AddDropdown(PotPage, {
	"Small", "Medium", "Big"
}, "Boyut Seçiniz ▼")

local PotAmount = AddInput(PotPage, "Miktar", "")

-- İKSİR ÖĞE OLARAK VER
AddButton(PotPage, "🧪 İKSİRİ ÖĞE OLARAK VER", Color3.fromRGB(150, 50, 255), function()
	local pType = GetPotionType()
	local pSize = GetPotionSize()

	if pType and pSize then
		local potionName = pType .. "_" .. pSize

		AdminEvent:FireServer("Player", "GivePotion", {
			Target = PotTarget.Text,
			Potion = potionName,
			Amount = tonumber(PotAmount.Text) or 1
		})

		print("✅ İksir öğe olarak veriliyor:", potionName, "x", PotAmount.Text)
	end
end)

-- İKSİR SÜRE OLARAK UYGULA (İÇİR)
AddButton(PotPage, "⚗️ İKSİRİ İÇİR (Süreli)", Color3.fromRGB(50, 150, 255), function()
	local pType = GetPotionType()
	local pSize = GetPotionSize()

	if pType and pSize then
		local potionName = pType .. "_" .. pSize

		AdminEvent:FireServer("Player", "DrinkPotion", {
			Target = PotTarget.Text,
			Potion = potionName
		})

		print("✅ İksir içirildi (süreli):", potionName)
	end
end)

-- ✅ SAYFA 3: ENVANTER
local InvPage = CreatePage("InvPage")
AddSectionTitle(InvPage, "🎯 Hedef Oyuncu")
local InvTarget = AddInput(InvPage, "Kullanıcı Adı veya ID (Boş = Sen)", "")

AddSectionTitle(InvPage, "🎰 Spin Market")
local SpinAmt = AddInput(InvPage, "Spin Miktarı", "")
AddButton(InvPage, "🎰 SPİN VER", Color3.fromRGB(255, 170, 0), function()
	AdminEvent:FireServer("Player", "GiveSpin", {
		Target = InvTarget.Text, 
		Amount = tonumber(SpinAmt.Text) or 0
	})
end)

AddSectionTitle(InvPage, "🥚 Hatch Limiti")
local HatchAmt = AddInput(InvPage, "Ekstra Hatch Sayısı", "")
AddButton(InvPage, "🥚 HATCH LİMİTİ ARTTIR", Color3.fromRGB(0, 200, 100), function()
	AdminEvent:FireServer("Player", "AddStat", {
		Target = InvTarget.Text,
		Stat = "MaxHatch",
		Amount = tonumber(HatchAmt.Text) or 0
	})
end)

-- ✅ SAYFA 4: ROT SKİLL
local SkillPage = CreatePage("SkillPage")
AddSectionTitle(SkillPage, "🎯 Hedef Oyuncu")
local SkillTarget = AddInput(SkillPage, "Kullanıcı Adı veya ID (Boş = Sen)", "")

AddSectionTitle(SkillPage, "🗺️ Harita Seçimi")
local GetMap = AddDropdown(SkillPage, {
	"Map 1 - Rot Skill",
	"Map 2 - GigaPower", 
	"Map 3 - SixSeven",
	"Map 4 - RizzlerPower",
	"Map 5 - Sigma"
}, "Harita Seçiniz ▼")

AddSectionTitle(SkillPage, "⭐ Skill Seviyesi")
local GetSkillLevel = AddDropdown(SkillPage, {
	"Level 1", "Level 2", "Level 3", 
	"Level 4", "Level 5", "Level 6", "Level 7"
}, "Skill Seviyesi ▼")

AddButton(SkillPage, "⭐ SKİLL VER", Color3.fromRGB(100, 200, 100), function()
	local map = GetMap()
	local skillLevel = GetSkillLevel()

	if map and skillLevel then
		local mapID = tonumber(string.match(map, "Map (%d)"))
		local skillIndex = tonumber(string.match(skillLevel, "Level (%d)"))

		if mapID and skillIndex then
			AdminEvent:FireServer("Player", "GiveRotSkill", {
				Target = SkillTarget.Text,
				MapID = mapID,
				SkillIndex = skillIndex
			})
		end
	end
end)

AddSectionTitle(SkillPage, "💰 Token Verme")
local TokenAmount = AddInput(SkillPage, "Token Miktarı", "")
AddButton(SkillPage, "💰 TOKEN VER", Color3.fromRGB(255, 200, 50), function()
	local map = GetMap()
	if map then
		local mapID = tonumber(string.match(map, "Map (%d)"))
		if mapID then
			AdminEvent:FireServer("Player", "GiveRotSkillToken", {
				Target = SkillTarget.Text,
				MapID = mapID,
				Amount = tonumber(TokenAmount.Text) or 0
			})
		end
	end
end)

-- ✅ SAYFA 5: EVENTLER
local EventPage = CreatePage("EventPage")
AddSectionTitle(EventPage, "🌍 Server Event Yönetimi")
AddSectionTitle(EventPage, "(Tüm Server Etkilenir)")

AddButton(EventPage, "🔥 DUNGEON BAŞLAT", Color3.fromRGB(255, 80, 80), function()
	AdminEvent:FireServer("Event", "SetTime", "StartDungeon")
end)

AddButton(EventPage, "👹 BOSS TRIAL BAŞLAT", Color3.fromRGB(200, 50, 255), function()
	AdminEvent:FireServer("Event", "SetTime", "StartBoss")
end)

AddButton(EventPage, "💰 2X REWARD", Color3.fromRGB(255, 215, 0), function()
	AdminEvent:FireServer("Event", "SetTime", "DoubleRewards")
end)

AddButton(EventPage, "✨ ESSENCE YAĞMURU", Color3.fromRGB(180, 100, 255), function()
	AdminEvent:FireServer("Event", "SetTime", "EssenceRain")
end)

-- ✅ SEKMELERİ OLUŞTUR
local tab1 = CreateTabButton("Statlar", "📊", StatPage)
local tab2 = CreateTabButton("İksirler", "🧪", PotPage)
local tab3 = CreateTabButton("Envanter", "🎒", InvPage)
local tab4 = CreateTabButton("Rot Skill", "⭐", SkillPage)
local tab5 = CreateTabButton("Eventler", "🌍", EventPage)

-- İlk sayfayı göster ve ilk tab'ı aktif yap
StatPage.Visible = true
CurrentPage = StatPage
CurrentTabButton = tab1
TweenService:Create(tab1, TweenInfo.new(0.2), {
	BackgroundColor3 = Color3.fromRGB(255, 170, 0),
	BackgroundTransparency = 0,
	TextColor3 = Color3.fromRGB(25, 25, 30)
}):Play()
tab1.UIStroke.Color = Color3.fromRGB(255, 200, 100)

-- ✅ PANEL AÇ/KAPA
local isOpen = false
local isAnimating = false

OpenBtn.MouseButton1Click:Connect(function()
	if isAnimating then return end
	isAnimating = true

	isOpen = not isOpen

	if isOpen then
		MainFrame.Visible = true
		MainFrame.Position = UDim2.new(0.15, 0, 0.1, -50)
		MainFrame.Size = UDim2.new(0.7, 0, 0, 0)

		TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.7, 0, 0.8, 0),
			Position = UDim2.new(0.15, 0, 0.1, 0)
		}):Play()
	else
		TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0.7, 0, 0, 0),
			Position = UDim2.new(0.15, 0, 0.1, -50)
		}):Play()

		task.wait(0.3)
		MainFrame.Visible = false
		-- Panel kapanınca dropdown'ları da kapat
		CloseAllDropdowns()
	end

	task.wait(0.1)
	isAnimating = false
end)

-- ✅ ESC TUŞU İLE KAPAT
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.Escape and isOpen then
		OpenBtn.MouseButton1Click:Fire()
	end
end)

print("✅ AdminClient: Görsel sorunlar düzeltildi, modern UI aktif!")

-- ✅ EVENT NOTIFICATION UI
local EventNotificationFrame
local function CreateEventNotification()
	EventNotificationFrame = Instance.new("Frame")
	EventNotificationFrame.Name = "EventNotification"
	EventNotificationFrame.Size = UDim2.new(0.4, 0, 0.1, 0)
	EventNotificationFrame.Position = UDim2.new(0.3, 0, -0.15, 0)
	EventNotificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	EventNotificationFrame.BorderSizePixel = 0
	EventNotificationFrame.Parent = ScreenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = EventNotificationFrame
	
	local eventTitle = Instance.new("TextLabel")
	eventTitle.Name = "Title"
	eventTitle.Size = UDim2.new(1, -20, 0.5, 0)
	eventTitle.Position = UDim2.new(0, 10, 0.1, 0)
	eventTitle.BackgroundTransparency = 1
	eventTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	eventTitle.Font = Enum.Font.GothamBold
	eventTitle.TextSize = 20
	eventTitle.TextXAlignment = Enum.TextXAlignment.Left
	eventTitle.Parent = EventNotificationFrame
	
	local countdown = Instance.new("TextLabel")
	countdown.Name = "Countdown"
	countdown.Size = UDim2.new(1, -20, 0.4, 0)
	countdown.Position = UDim2.new(0, 10, 0.5, 0)
	eventTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	countdown.Font = Enum.Font.Gotham
	countdown.TextSize = 16
	countdown.TextXAlignment = Enum.TextXAlignment.Left
	countdown.Parent = EventNotificationFrame
	
	return EventNotificationFrame
end

if not EventNotificationFrame then
	CreateEventNotification()
end

local function ShowEventNotification(eventName, duration)
	if not EventNotificationFrame then return end
	
	local title = EventNotificationFrame:FindFirstChild("Title")
	local countdown = EventNotificationFrame:FindFirstChild("Countdown")
	
	if title then
		title.Text = "🎉 " .. eventName
	end
	
	-- Animasyonla aç
	TweenService:Create(EventNotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.3, 0, 0.05, 0)
	}):Play()
	
	-- Geri sayım
	local startTime = tick()
	local endTime = startTime + duration
	
	spawn(function()
		while tick() < endTime do
			local remaining = math.ceil(endTime - tick())
			if countdown then
				countdown.Text = string.format("⏱️ Kalan: %d:%02d", math.floor(remaining / 60), remaining % 60)
			end
			task.wait(1)
		end
		
		-- Animasyonla kapat
		TweenService:Create(EventNotificationFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.3, 0, -0.15, 0)
		}):Play()
	end)
end

-- ✅ FEEDBACK SİSTEMİ
local FeedbackFrame
local function CreateFeedbackUI()
	FeedbackFrame = Instance.new("Frame")
	FeedbackFrame.Name = "Feedback"
	FeedbackFrame.Size = UDim2.new(0.3, 0, 0.08, 0)
	FeedbackFrame.Position = UDim2.new(0.35, 0, 0.9, 0)
	FeedbackFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	FeedbackFrame.BorderSizePixel = 0
	FeedbackFrame.Visible = false
	FeedbackFrame.Parent = ScreenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = FeedbackFrame
	
	local feedbackText = Instance.new("TextLabel")
	feedbackText.Name = "Text"
	feedbackText.Size = UDim2.new(1, -20, 1, 0)
	feedbackText.Position = UDim2.new(0, 10, 0, 0)
	feedbackText.BackgroundTransparency = 1
	feedbackText.TextColor3 = Color3.fromRGB(255, 255, 255)
	feedbackText.Font = Enum.Font.GothamBold
	feedbackText.TextSize = 18
	feedbackText.Parent = FeedbackFrame
	
	return FeedbackFrame
end

if not FeedbackFrame then
	CreateFeedbackUI()
end

local function ShowFeedback(message, success)
	if not FeedbackFrame then return end
	
	local textLabel = FeedbackFrame:FindFirstChild("Text")
	if textLabel then
		textLabel.Text = (success and "✅ " or "❌ ") .. message
		textLabel.TextColor3 = success and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)
	end
	
	FeedbackFrame.BackgroundColor3 = success and Color3.fromRGB(20, 50, 30) or Color3.fromRGB(50, 20, 20)
	FeedbackFrame.Visible = true
	
	-- 3 saniye sonra kapat
	task.delay(3, function()
		FeedbackFrame.Visible = false
	end)
end

-- ✅ SERVER'DAN GELEN FEEDBACK'LARI DİNLE
local AdminDataRemote = Remotes:FindFirstChild("AdminDataUpdate")
if AdminDataRemote then
	AdminDataRemote.OnClientEvent:Connect(function(dataType, data)
		if dataType == "CommandResult" then
			ShowFeedback(data.message, data.success)
		elseif dataType == "EventStarted" then
			ShowEventNotification(data.eventName, data.duration)
		end
	end)
end

DebugPrint("✅ Event Notification UI ve Feedback sistemi aktif!")
