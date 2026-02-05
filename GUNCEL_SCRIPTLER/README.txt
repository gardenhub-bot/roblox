-- ServerScriptService.Systems.AdminManager

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataKeyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("DataKeyManager"))

local DataStoreService = game:GetService("DataStoreService")
local MyDataStore = DataStoreService:GetDataStore(DataKeyManager.MAIN_KEY)

local Admins = {
	["ChrolloLucifer"] = true,
	["CavusAlah"] = true,
}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"

local AdminEvent = Remotes:FindFirstChild("AdminEvent") or Instance.new("RemoteEvent", Remotes)
AdminEvent.Name = "AdminEvent"

-- ✅ DRINK POTION EVENT
local DrinkPotionEvent = Remotes:FindFirstChild("DrinkPotionEvent") 
if not DrinkPotionEvent then
	DrinkPotionEvent = Instance.new("RemoteEvent", Remotes)
	DrinkPotionEvent.Name = "DrinkPotionEvent"
end

-- ✅ GAMECONFIG
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local InventoryConfig = require(Modules:WaitForChild("InventoryConfig"))

-- ✅ İKSİR TÜRLERİ
local POTION_TYPES = {"IQ", "Damage", "Coins", "Essence", "Aura", "Luck", "Speed"}
local POTION_SIZES = {"Small", "Medium", "Big"}

local function CreateAdminUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "AdminPanelUI_FinalFixed"
	ScreenGui.ResetOnSpawn = false

	local OpenBtn = Instance.new("TextButton")
	OpenBtn.Name = "OpenBtn"
	OpenBtn.Size = UDim2.new(0, 60, 0, 60)
	OpenBtn.Position = UDim2.new(0, 20, 0.9, -30)
	OpenBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	OpenBtn.Text = "🛡️"
	OpenBtn.TextSize = 28
	OpenBtn.Parent = ScreenGui

	local corner = Instance.new("UICorner", OpenBtn)
	corner.CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", OpenBtn)
	stroke.Color = Color3.fromRGB(255, 170, 0)
	stroke.Thickness = 3

	return ScreenGui
end

Players.PlayerAdded:Connect(function(player)
	if Admins[player.Name] then
		local ui = CreateAdminUI()
		ui.Parent = player:WaitForChild("PlayerGui")
		if script:FindFirstChild("AdminClient") then
			local cl = script.AdminClient:Clone()
			cl.Parent = ui
			cl.Disabled = false
		end
	end
end)

-- ✅ OYUNCUNUN TÜM VERİLERİNİ SIFIRLA
local function ResetPlayerData(playerId)
	local success, err = pcall(function()
		MyDataStore:RemoveAsync("Player_" .. playerId)
	end)

	if success then
		print("🗑️ Tüm veriler silindi:", playerId)
		return true
	else
		warn("❌ Veri silme hatası:", err)
		return false
	end
end

-- ✅ İKSİR VER (YENİ FORMAT)
local function GivePotionToPlayer(player, potionName, amount)
	if not player or not player.Parent then return false end

	local potionInv = player:FindFirstChild("PotionInventory")
	if not potionInv then
		potionInv = Instance.new("Folder", player)
		potionInv.Name = "PotionInventory"
	end

	local potionVal = potionInv:FindFirstChild(potionName)
	if not potionVal then
		potionVal = Instance.new("IntValue", potionInv)
		potionVal.Name = potionName
		potionVal.Value = 0
	end

	potionVal.Value = potionVal.Value + (amount or 1)
	return true
end

AdminEvent.OnServerEvent:Connect(function(admin, category, action, data)
	if not Admins[admin.Name] then 
		warn("❌ Yetkisiz admin girişimi:", admin.Name)
		return 
	end

	print("🛡️ [ADMIN] İstek:", admin.Name, "→", category, "→", action)

	if category == "Event" then
		-- EventManager'e yönlendir
		local AdminBindable = Remotes:FindFirstChild("AdminControlBindable")
		if AdminBindable then
			print("🛡️ [ADMIN] EventManager Sinyali:", action)
			AdminBindable:Fire(admin, action, data) 
		end
		return
	end

	local targetName = data.Target
	local targetPlayer, targetId = nil, nil

	-- HEDEF BUL
	if targetName and targetName ~= "" then
		-- Önce online oyuncuları kontrol et
		for _, p in pairs(Players:GetPlayers()) do
			if string.lower(p.Name):sub(1, #targetName) == string.lower(targetName) then
				targetPlayer = p
				targetId = p.UserId
				break
			end
		end

		-- Online değilse ID'yi kontrol et
		if not targetPlayer and tonumber(targetName) then 
			targetId = tonumber(targetName) 
		end
	else
		targetPlayer = admin
		targetId = admin.UserId
	end

	if not targetId then 
		warn("❌ [ADMIN] Hedef bulunamadı!")
		return 
	end

	print("🎯 [ADMIN] Hedef:", targetPlayer and targetPlayer.Name or ("Offline:" .. targetId))

	-- ==========================================
	-- 🎯 ROT SKILL VER
	-- ==========================================
	if action == "GiveRotSkill" then
		local mapID = tonumber(data.MapID)
		local skillIndex = tonumber(data.SkillIndex)

		if not mapID or not skillIndex then
			warn("❌ MapID veya SkillIndex eksik!")
			return
		end

		if targetPlayer then
			local leaderstats = targetPlayer:FindFirstChild("leaderstats")
			if leaderstats then
				local skillName = "EquippedSkill" .. (mapID == 1 and "" or tostring(mapID))
				local equippedSkillObj = leaderstats:FindFirstChild(skillName)

				if equippedSkillObj then
					equippedSkillObj.Value = skillIndex
					print("✅ Rot Skill verildi: Map", mapID, "→ Skill", skillIndex)
				else
					warn("❌ EquippedSkill bulunamadı:", skillName)
				end
			end
		else
			-- OFFLINE
			pcall(function()
				local key = "Player_" .. targetId
				MyDataStore:UpdateAsync(key, function(old)
					old = old or {}
					local skillName = "EquippedSkill" .. (mapID == 1 and "" or tostring(mapID))
					old[skillName] = skillIndex
					return old
				end)
				print("💾 [OFFLINE] Rot Skill verildi: Map", mapID, "→ Skill", skillIndex)
			end)
		end

		-- ==========================================
		-- 🪙 ROT SKILL TOKEN VER
		-- ==========================================
	elseif action == "GiveRotSkillToken" then
		local mapID = tonumber(data.MapID)
		local amount = tonumber(data.Amount) or 1

		if not mapID then
			warn("❌ MapID eksik!")
			return
		end

		local mapConfig = GameConfig.MapRotSkills[mapID]
		if not mapConfig then
			warn("❌ Map config bulunamadı:", mapID)
			return
		end

		local tokenName = mapConfig.TokenName

		if targetPlayer then
			local leaderstats = targetPlayer:FindFirstChild("leaderstats")
			if leaderstats then
				local tokenObj = leaderstats:FindFirstChild(tokenName)
				if not tokenObj then
					tokenObj = Instance.new("IntValue", leaderstats)
					tokenObj.Name = tokenName
					tokenObj.Value = 0
				end
				tokenObj.Value = tokenObj.Value + amount
				print("✅ Token verildi:", tokenName, "→", amount)
			end
		else
			-- OFFLINE
			pcall(function()
				local key = "Player_" .. targetId
				MyDataStore:UpdateAsync(key, function(old)
					old = old or {}
					old[tokenName] = (old[tokenName] or 0) + amount
					return old
				end)
				print("💾 [OFFLINE] Token verildi:", tokenName, "→", amount)
			end)
		end

		-- ==========================================
		-- 📊 STAT VER
		-- ==========================================
	elseif action == "AddStat" then
		local stat = data.Stat
		local amount = tonumber(data.Amount) or 1

		print("🔧 [ADMIN] İşlem:", stat, "→ Miktar:", amount)

		if targetPlayer then
			local ps = targetPlayer:FindFirstChild("PlayerStats")
			local ls = targetPlayer:FindFirstChild("leaderstats")
			local hs = targetPlayer:FindFirstChild("HiddenStats")

			if stat == "Aura" then
				if hs then
					local aura = hs:FindFirstChild("Aura")
					if not aura then
						aura = Instance.new("IntValue", hs)
						aura.Name = "Aura"
						aura.Value = 50
					end
					aura.Value = aura.Value + amount
					print("✅ Aura verildi:", amount)
				end

			elseif stat == "MaxHatch" then
				if ps then
					local mh = ps:FindFirstChild("MaxHatch")
					if not mh then
						mh = Instance.new("IntValue", ps)
						mh.Name = "MaxHatch"
						mh.Value = 1
					end
					mh.Value = mh.Value + amount
					print("✅ MaxHatch verildi:", amount)
				end

			elseif stat == "Luck" then
				if hs then
					local luck = hs:FindFirstChild("LuckLvl")
					if not luck then
						luck = Instance.new("IntValue", hs)
						luck.Name = "LuckLvl"
						luck.Value = 0
					end
					luck.Value = luck.Value + amount
					print("✅ Luck verildi:", amount)
				end

			else
				if ls and ls:FindFirstChild(stat) then 
					ls[stat].Value = ls[stat].Value + amount
					print("✅", stat, "verildi:", amount)
				else
					warn("❌ Stat bulunamadı:", stat)
				end
			end

		else
			pcall(function()
				local key = "Player_" .. targetId
				MyDataStore:UpdateAsync(key, function(old)
					old = old or {}
					local baseVal = 0
					if stat == "MaxHatch" then baseVal = 1 end
					if stat == "Aura" then baseVal = 50 end
					old[stat] = (old[stat] or baseVal) + amount
					return old
				end)
				print("💾 [OFFLINE] Veri güncellendi:", stat, "→", amount)
			end)
		end

		-- ==========================================
		-- 🎰 SPIN VER
		-- ==========================================
	elseif action == "GiveSpin" then
		local amount = tonumber(data.Amount) or 1
		if targetPlayer then
			local h = targetPlayer:FindFirstChild("HiddenStats")
			if h then
				local wheelSpin = h:FindFirstChild("WheelSpin")
				if not wheelSpin then
					wheelSpin = Instance.new("IntValue", h)
					wheelSpin.Name = "WheelSpin"
					wheelSpin.Value = 1
				end
				wheelSpin.Value = wheelSpin.Value + amount
				print("✅ Spin verildi:", amount)
			end
		else
			pcall(function()
				local key = "Player_" .. targetId
				MyDataStore:UpdateAsync(key, function(old)
					old = old or {}
					old["WheelSpin"] = (old["WheelSpin"] or 1) + amount
					return old
				end)
				print("💾 [OFFLINE] Spin verildi:", amount)
			end)
		end

		-- ==========================================
		-- 🧪 İKSİR VER (YENİ FORMAT) - ÖĞE OLARAK
		-- ==========================================
	elseif action == "GivePotion" then
		local potionName = data.Potion
		local amount = tonumber(data.Amount) or 1

		if not potionName then
			warn("❌ İksir adı belirtilmedi!")
			return
		end

		-- Format kontrolü: IQ_Small veya sadece IQ
		local potionType, size = string.match(potionName, "^(%w+)_(%w+)$")
		if not potionType then
			potionType = potionName
			size = "Small" -- Varsayılan boyut
			potionName = potionType .. "_" .. size
		end

		if not table.find(POTION_TYPES, potionType) then
			warn("❌ Geçersiz iksir türü:", potionType)
			return
		end

		if not table.find(POTION_SIZES, size) then
			warn("❌ Geçersiz iksir boyutu:", size)
			return
		end

		if targetPlayer then
			local success = GivePotionToPlayer(targetPlayer, potionName, amount)
			if success then
				print("✅ İksir (öğe) verildi:", potionName, "→", amount)
			else
				warn("❌ İksir verilemedi")
			end
		else
			-- OFFLINE
			pcall(function()
				local key = "Player_" .. targetId
				MyDataStore:UpdateAsync(key, function(old)
					old = old or {}
					if not old.Potions then old.Potions = {} end
					old.Potions[potionName] = (old.Potions[potionName] or 0) + amount
					return old
				end)
				print("💾 [OFFLINE] İksir (öğe) verildi:", potionName, "→", amount)
			end)
		end

		-- ==========================================
		-- 🗑️ TÜM VERİLERİ SIFIRLA
		-- ==========================================
	elseif action == "ResetStats" then
		local confirm = data.Confirm or false

		if not confirm then
			-- İlk tıklamada onay iste
			warn("⚠️ Tüm verileri sıfırlamak için tekrar tıklayın!")
			return
		end

		if targetPlayer then 
			-- Oyuncuyu kickle ve verileri sil
			targetPlayer:Kick("Stats resetlendi. Tekrar giriş yapın.") 
		end

		-- Verileri sil
		local success = ResetPlayerData(targetId)
		if success then
			print("🗑️ Tüm veriler silindi:", targetId)
		else
			warn("❌ Veriler silinemedi:", targetId)
		end

		-- ==========================================
		-- 🧪 İKSİR İÇİR (Süreli etki)
		-- ==========================================
	elseif action == "DrinkPotion" then
		local potionName = data.Potion
		if targetPlayer and DrinkPotionEvent then
			-- İksir envanterde var mı kontrol et
			local potionInv = targetPlayer:FindFirstChild("PotionInventory")
			if potionInv then
				local potionVal = potionInv:FindFirstChild(potionName)
				if potionVal and potionVal.Value > 0 then
					-- DrinkPotionEvent'i tetikle (aynı oyuncunun içmesi gibi)
					DrinkPotionEvent:FireClient(targetPlayer, potionName)
					print("✅ İksir içirildi:", potionName, "→", targetPlayer.Name)
				else
					-- İksir yoksa, önce ver sonra içir
					local success = GivePotionToPlayer(targetPlayer, potionName, 1)
					if success then
						DrinkPotionEvent:FireClient(targetPlayer, potionName)
						print("✅ İksir verilip içirildi:", potionName)
					end
				end
			else
				-- Envanter yoksa, oluştur ver içir
				local potionInv = Instance.new("Folder", targetPlayer)
				potionInv.Name = "PotionInventory"
				local success = GivePotionToPlayer(targetPlayer, potionName, 1)
				if success then
					DrinkPotionEvent:FireClient(targetPlayer, potionName)
					print("✅ Envanter oluşturuldu, iksir verilip içirildi:", potionName)
				end
			end
		end
	end
end)

print("✅ AdminManager: Güncellendi ve düzeltildi")

----------------------------------

-- AdminClient (Tam hali - görsel sorunlar düzeltildi)

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

----------------------------------------------------

-- ServerScriptService.EventSystem.EventManager

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local DataStoreService = game:GetService("DataStoreService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminControlBindable = Remotes:FindFirstChild("AdminControlBindable")
if not AdminControlBindable then
	AdminControlBindable = Instance.new("BindableEvent", Remotes)
	AdminControlBindable.Name = "AdminControlBindable"
end

-- ✅ GLOBAL EVENT DATASTORE (TÜM SUNUCULAR İÇİN)
local EventDataStore = DataStoreService:GetDataStore("GlobalEventData_V2")

-- ✅ EVENT TANIMLARI (Boss/Dungeon + 7 Buff Eventi)
local events = {
	-- ✅ BOSS/DUNGEON EVENTLER
	["StartDungeon"] = {
		Name = "⚔️ DUNGEON EVENT",
		Duration = 600, -- 10 dakika
		Multiplier = 2,
		Description = "Dungeon started! All enemies give 2x rewards!",
		Color = Color3.fromRGB(255, 100, 100),
		Icon = "⚔️"
	},
	["StartBoss"] = {
		Name = "👹 BOSS TRIAL",
		Duration = 300, -- 5 dakika
		Multiplier = 3,
		Description = "Boss Trial started! Special boss enemies appeared!",
		Color = Color3.fromRGB(200, 50, 255),
		Icon = "👹"
	},

	-- ✅ 7 BUFF EVENTI
	["2xIQ"] = {
		Name = "50% IQ Boost",
		Duration = 1800, -- 30 dakika
		Description = "IQ rewards increased by 50%!",
		Color = Color3.fromRGB(100, 150, 255),
		Icon = "🧠",
		AttributeName = "EventIQBonus",
		Multiplier = 1.5
	},
	["2xCoins"] = {
		Name = "50% Coins Boost",
		Duration = 1800,
		Description = "Coin rewards increased by 50%!",
		Color = Color3.fromRGB(255, 215, 0),
		Icon = "💰",
		AttributeName = "EventCoinsBonus",
		Multiplier = 1.5
	},
	["LuckyHour"] = {
		Name = "Lucky Hour",
		Duration = 3600, -- 60 dakika
		Description = "Luck increased by 0.1!",
		Color = Color3.fromRGB(0, 255, 150),
		Icon = "🍀",
		AttributeName = "EventLuckBonus",
		Additive = 0.1
	},
	["SpeedFrenzy"] = {
		Name = "Speed Frenzy",
		Duration = 900, -- 15 dakika
		Description = "Walk speed increased by 50%!",
		Color = Color3.fromRGB(0, 255, 255),
		Icon = "⚡",
		AttributeName = "EventSpeedBonus",
		Multiplier = 1.5
	},
	["GoldenRush"] = {
		Name = "Golden Rush",
		Duration = 600, -- 10 dakika
		Description = "Coin rewards increased by 50%!",
		Color = Color3.fromRGB(255, 200, 50),
		Icon = "💸",
		AttributeName = "EventCoinsBonus",
		Multiplier = 1.5
	},
	["RainbowStars"] = {
		Name = "Rainbow Stars",
		Duration = 1800,
		Description = "All rewards increased by 25%!",
		Color = Color3.fromRGB(255, 100, 255),
		Icon = "🌈",
		AttributeName = "EventAllBonus",
		Multiplier = 1.25
	},
	["EssenceRain"] = {
		Name = "50% Essence Drop",
		Duration = 600,
		Description = "Essence drop chance increased by 50%!",
		Color = Color3.fromRGB(180, 100, 255),
		Icon = "✨",
		AttributeName = "EventEssenceBonus",
		Multiplier = 1.5
	}
}

local activeEvent = nil
local eventEndTime = 0

-- ==========================================
-- ✅ GLOBAL EVENT YÖNETİMİ
-- ==========================================
local function GetGlobalEvent()
	local success, data = pcall(function()
		return EventDataStore:GetAsync("CurrentEvent")
	end)
	if success and data then
		return data
	end
	return nil
end

local function SetGlobalEvent(eventKey, startTime, duration)
	pcall(function()
		EventDataStore:SetAsync("CurrentEvent", {
			EventKey = eventKey,
			StartTime = startTime,
			Duration = duration
		})
	end)
end

local function ClearGlobalEvent()
	pcall(function()
		EventDataStore:RemoveAsync("CurrentEvent")
	end)
end

-- ==========================================
-- ✅ OYUNCULARA EVENT UYGULA/KALDIR
-- ==========================================
local function ApplyEventToPlayer(player, eventKey)
	local event = events[eventKey]
	if not event then return end

	-- Boss/Dungeon eventi (MainClickSystem zaten kontrol ediyor)
	if eventKey == "StartDungeon" or eventKey == "StartBoss" then
		-- Özel bir şey yapmaya gerek yok
		return
	end

	-- Buff eventleri
	if event.Multiplier then
		player:SetAttribute(event.AttributeName, event.Multiplier)
	elseif event.Additive then
		local hidden = player:FindFirstChild("HiddenStats")
		if hidden and hidden:FindFirstChild("LuckMultiplier") then
			hidden.LuckMultiplier.Value = hidden.LuckMultiplier.Value + event.Additive
		end
	end

	-- Speed güncellemesi
	if eventKey == "SpeedFrenzy" then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		local GameConfig = require(Modules:WaitForChild("GameConfig"))
		GameConfig.UpdateWalkSpeed(player)
	end

	print("✅ Event uygulandı:", player.Name, "→", eventKey)
end

local function RemoveEventFromPlayer(player, eventKey)
	local event = events[eventKey]
	if not event then return end

	if eventKey == "StartDungeon" or eventKey == "StartBoss" then
		return
	end

	if event.Multiplier then
		player:SetAttribute(event.AttributeName, nil)
	elseif event.Additive then
		local hidden = player:FindFirstChild("HiddenStats")
		if hidden and hidden:FindFirstChild("LuckMultiplier") then
			hidden.LuckMultiplier.Value = math.max(1.0, hidden.LuckMultiplier.Value - event.Additive)
		end
	end

	if eventKey == "SpeedFrenzy" then
		local Modules = ReplicatedStorage:WaitForChild("Modules")
		local GameConfig = require(Modules:WaitForChild("GameConfig"))
		GameConfig.UpdateWalkSpeed(player)
	end

	print("❌ Event kaldırıldı:", player.Name, "→", eventKey)
end

-- ==========================================
-- ✅ TÜM OYUNCULARA BİLDİRİM GÖNDER (ESKİ UI YAPISI)
-- ==========================================
local function NotifyAllPlayers(message, eventName, color, icon, duration)
	for _, player in pairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			-- ✅ ESKİ BİLDİRİM UI'SI (SAĞ ÜST, KÜÇÜK)
			local notification = Instance.new("ScreenGui")
			notification.Name = "EventNotification"
			notification.ResetOnSpawn = false
			notification.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 350, 0, 90)
			frame.Position = UDim2.new(1, 0, 0, 20) -- Ekran dışından gelecek
			frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			frame.BackgroundTransparency = 0.1
			frame.BorderSizePixel = 0
			frame.ZIndex = 2000

			local corner = Instance.new("UICorner", frame)
			corner.CornerRadius = UDim.new(0, 12)

			local stroke = Instance.new("UIStroke", frame)
			stroke.Color = color or Color3.fromRGB(255, 170, 0)
			stroke.Thickness = 3
			stroke.ZIndex = 2000

			-- Icon
			local iconLabel = Instance.new("TextLabel")
			iconLabel.Size = UDim2.new(0, 60, 0, 60)
			iconLabel.Position = UDim2.new(0, 15, 0.5, -30)
			iconLabel.BackgroundTransparency = 1
			iconLabel.Text = icon or "🎉"
			iconLabel.TextSize = 45
			iconLabel.ZIndex = 2001
			iconLabel.Parent = frame

			-- Event Name
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -90, 0, 35)
			title.Position = UDim2.new(0, 80, 0, 15)
			title.BackgroundTransparency = 1
			title.Text = message
			title.TextColor3 = Color3.fromRGB(255, 255, 255)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 16
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextStrokeTransparency = 0.5
			title.ZIndex = 2001
			title.Parent = frame

			-- Timer/Description
			local timerLabel = Instance.new("TextLabel")
			timerLabel.Name = "Timer"
			timerLabel.Size = UDim2.new(1, -90, 0, 25)
			timerLabel.Position = UDim2.new(0, 80, 0, 50)
			timerLabel.BackgroundTransparency = 1
			timerLabel.Text = "⏰ Starting..."
			timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			timerLabel.Font = Enum.Font.Gotham
			timerLabel.TextSize = 14
			timerLabel.TextXAlignment = Enum.TextXAlignment.Left
			timerLabel.ZIndex = 2001
			timerLabel.Parent = frame

			frame.Parent = notification
			notification.Parent = playerGui

			-- ✅ ANIMASYON (SAĞ TARAFTAN GELSİN)
			local tweenIn = game:GetService("TweenService"):Create(frame, 
				TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
				{Position = UDim2.new(1, -370, 0, 20)}
			)
			tweenIn:Play()

			-- ✅ TIMER GÖSTER (EĞER SÜRE VARSA)
			if duration and duration > 0 then
				task.spawn(function()
					local endTime = tick() + duration
					while tick() < endTime and notification.Parent do
						local remaining = math.max(0, endTime - tick())
						local minutes = math.floor(remaining / 60)
						local seconds = math.floor(remaining % 60)
						timerLabel.Text = string.format("⏰ %02d:%02d remaining", minutes, seconds)
						task.wait(1)
					end
				end)
			end

			-- ✅ BELLİ SÜRE SONRA KAPAT (EĞER SÜRE YOKSA 5 SANİYE)
			if not duration or duration == 0 then
				task.delay(5, function()
					if notification and notification.Parent then
						local tweenOut = game:GetService("TweenService"):Create(frame, 
							TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
							{Position = UDim2.new(1, 0, 0, 20)}
						)
						tweenOut:Play()
						tweenOut.Completed:Wait()
						notification:Destroy()
					end
				end)
			end
		end
	end
end

-- ==========================================
-- ✅ EVENT BAŞLAT
-- ==========================================
local function StartEvent(eventKey)
	local event = events[eventKey]
	if not event then 
		warn("❌ Geçersiz event:", eventKey)
		return 
	end

	-- ✅ ÖNCEKİ EVENTİ SONLANDIR
	if activeEvent then
		warn("⚠️ Önceki event sonlandırılıyor:", activeEvent)
		StopEvent(activeEvent, true) -- true = sessiz kapat
	end

	activeEvent = eventKey
	local startTime = tick()
	eventEndTime = startTime + event.Duration

	-- ✅ GLOBAL EVENT KAYDET
	SetGlobalEvent(eventKey, startTime, event.Duration)

	-- ✅ TÜM OYUNCULARA UYGULA
	for _, player in pairs(Players:GetPlayers()) do
		ApplyEventToPlayer(player, eventKey)
	end

	-- ✅ BİLDİRİM GÖNDER
	NotifyAllPlayers(event.Name .. " Active!", event.Name, event.Color, event.Icon, event.Duration)

	-- ✅ MESSAGINGSERVICE İLE TÜM SUNUCULARA YAYINLA
	pcall(function()
		MessagingService:PublishAsync("GlobalEventStart", {
			EventKey = eventKey,
			StartTime = startTime,
			Duration = event.Duration
		})
	end)

	print("🎉 Event başladı:", event.Name, "Süre:", event.Duration .. "s")

	-- ✅ TIMER
	task.spawn(function()
		local elapsed = 0
		local notificationIntervals = {300, 600} -- 5dk, 10dk kala

		while elapsed < event.Duration do
			task.wait(1)
			elapsed = elapsed + 1

			local remaining = event.Duration - elapsed
			for _, interval in ipairs(notificationIntervals) do
				if remaining == interval then
					NotifyAllPlayers(event.Name .. " - " .. math.floor(remaining / 60) .. " min left!", 
						event.Name, event.Color, event.Icon, 0)
				end
			end
		end

		-- ✅ EVENT BİTTİ
		StopEvent(eventKey)
	end)
end

-- ==========================================
-- ✅ EVENT SONLANDIR
-- ==========================================
function StopEvent(eventKey, silent)
	if activeEvent ~= eventKey then return end

	local event = events[eventKey]
	if not event then return end

	-- ✅ TÜM OYUNCULARDAN KALDIR
	for _, player in pairs(Players:GetPlayers()) do
		RemoveEventFromPlayer(player, eventKey)
	end

	-- ✅ BİLDİRİM (SESSIZ DEĞİLSE)
	if not silent then
		NotifyAllPlayers(event.Name .. " has ended!", "EVENT ENDED", Color3.fromRGB(150, 150, 150), "✅", 0)
	end

	-- ✅ GLOBAL EVENT TEMİZLE
	ClearGlobalEvent()

	-- ✅ MESSAGINGSERVICE İLE TÜM SUNUCULARA YAYINLA
	pcall(function()
		MessagingService:PublishAsync("GlobalEventStop", {
			EventKey = eventKey
		})
	end)

	activeEvent = nil
	eventEndTime = 0
	print("✨ Event bitti:", event.Name)
end

-- ==========================================
-- ✅ MESSAGINGSERVICE DİNLEYİCİ
-- ==========================================
pcall(function()
	MessagingService:SubscribeAsync("GlobalEventStart", function(message)
		local data = message.Data
		local eventKey = data.EventKey
		local startTime = data.StartTime
		local duration = data.Duration

		local elapsed = tick() - startTime
		local remaining = duration - elapsed

		if remaining > 0 then
			local event = events[eventKey]
			if event then
				activeEvent = eventKey
				eventEndTime = tick() + remaining

				for _, player in pairs(Players:GetPlayers()) do
					ApplyEventToPlayer(player, eventKey)
				end

				NotifyAllPlayers(event.Name .. " Active!", event.Name, event.Color, event.Icon, remaining)

				task.spawn(function()
					task.wait(remaining)
					StopEvent(eventKey)
				end)
			end
		end
	end)

	MessagingService:SubscribeAsync("GlobalEventStop", function(message)
		local eventKey = message.Data.EventKey
		if activeEvent == eventKey then
			StopEvent(eventKey, true)
		end
	end)

	-- ✅ ADMIN MESAJ SİSTEMİ
	MessagingService:SubscribeAsync("GlobalAnnouncement", function(message)
		local data = message.Data
		NotifyAllPlayers(data.Message, "📢 ADMIN ANNOUNCEMENT", Color3.fromRGB(255, 50, 50), "📢", 0)
	end)
end)

-- ==========================================
-- ✅ YENİ OYUNCU İÇİN AKTİF EVENT KONTROL
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	task.wait(2)

	local globalEvent = GetGlobalEvent()
	if globalEvent then
		local elapsed = tick() - globalEvent.StartTime
		local remaining = globalEvent.Duration - elapsed

		if remaining > 0 then
			ApplyEventToPlayer(player, globalEvent.EventKey)

			local event = events[globalEvent.EventKey]
			if event then
				local playerGui = player:WaitForChild("PlayerGui")
				-- Bildirim gönder (sadece o oyuncuya)
				-- (NotifyAllPlayers fonksiyonu şu an herkese gönderiyor, 
				-- oyuncuya özel bildirim için ayrı fonksiyon gerekebilir)
			end
		end
	end
end)

-- ==========================================
-- ✅ ADMIN KONTROLÜ
-- ==========================================
AdminControlBindable.Event:Connect(function(admin, action, data)
	print("🎪 EventManager: Admin kontrolü", action, data)

	if action == "SetTime" then
		-- Boss/Dungeon event
		local eventKey = data
		if events[eventKey] then
			StartEvent(eventKey)
		end
	elseif action == "Stop" then
		-- Event durdur
		if activeEvent then
			StopEvent(activeEvent)
		end
	elseif action == "Announcement" then
		-- Admin mesajı
		local message = data.Message
		if message and message ~= "" then
			NotifyAllPlayers(message, "📢 ADMIN ANNOUNCEMENT", Color3.fromRGB(255, 50, 50), "📢", 0)

			pcall(function()
				MessagingService:PublishAsync("GlobalAnnouncement", {
					Message = message,
					AdminName = data.AdminName or "Admin"
				})
			end)
		end
	else
		-- 7 buff eventi
		if events[action] then
			StartEvent(action)
		end
	end
end)

-- ==========================================
-- ✅ PUBLIC FONKSİYONLAR
-- ==========================================
function GetEventMultiplier()
	if not activeEvent then return 1 end
	local event = events[activeEvent]
	return event and event.Multiplier or 1
end

function GetActiveEvent()
	return activeEvent
end

function GetEventRemainingTime()
	if not activeEvent then return 0 end
	return math.max(0, eventEndTime - tick())
end

print("✅ EventManager: Yüklendi - " .. #events .. " event tanımlandı (MessagingService aktif)")

return {
	GetEventMultiplier = GetEventMultiplier,
	GetActiveEvent = GetActiveEvent,
	GetEventRemainingTime = GetEventRemainingTime,
	StartEvent = StartEvent,
	StopEvent = StopEvent
}
