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

-- AdminManager modülü oluştur
local AdminManager = {}
AdminManager.Config = {
	Admins = Admins
}

return AdminManager

----------------------------------

