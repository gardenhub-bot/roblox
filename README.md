MainClickSystem : 



-- ServerScriptService/MainClickSystem.lua (VISUAL FIXES)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MarketplaceService = game:GetService("MarketplaceService")

local Players = game:GetService("Players")



-- [[ 1. MERKEZİ BEYİN ]] --

local Modules = ReplicatedStorage:WaitForChild("Modules")

local GameConfig = require(Modules:WaitForChild("GameConfig"))



-- [[ REMOTE EVENTLER ]] --

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ClickEvent = Remotes:WaitForChild("ClickAction")



local OnIQGained = Remotes:FindFirstChild("OnIQGained")

if not OnIQGained then

	OnIQGained = Instance.new("RemoteEvent")

	OnIQGained.Name = "OnIQGained"

	OnIQGained.Parent = Remotes

end



local FAST_GAMEPASS_ID = 1644219327 

local ATTACK_RANGE = 12 



local lastClickTime = {}

local lastAttackTime = {}



-- [[ IQ KAZANMA ]] --

local function GiveIQ(player)

	local stats = player:FindFirstChild("leaderstats")

	if stats and stats:FindFirstChild("IQ") then

		local gain = GameConfig.CalculateIQ(player)

		stats.IQ.Value += gain

		OnIQGained:FireClient(player, gain)

	end

end



-- [[ SALDIRI SİSTEMİ ]] --

local function ProcessAttack(player)

	local now = tick()

	if lastAttackTime[player.UserId] and (now - lastAttackTime[player.UserId]) < 0.2 then return end 



	local character = player.Character

	local hrp = character and character:FindFirstChild("HumanoidRootPart")



	if not hrp or not character:FindFirstChildOfClass("Tool") then return end



	lastAttackTime[player.UserId] = now 

	local damageValue = GameConfig.CalculateDamage(player)



	-- [[ BU TIKLAMA İÇİN VURULANLAR LİSTESİ (ÇİFT HASARI ÖNLER) ]] --

	local hitHumanoids = {}



	local function ApplyDamage(enemy, zoneId)

		local hum = enemy:FindFirstChild("Humanoid")

		local eroot = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Torso") or enemy.PrimaryPart



		if hum and eroot and hum.Health > 0 then

			-- Eğer bu moba bu turda zaten vurduysak, tekrar vurma!

			if hitHumanoids[hum] then return end



			local dist = (hrp.Position - eroot.Position).Magnitude

			local enemyRadius = math.max(eroot.Size.X, eroot.Size.Z) * 1.5 



			if dist <= (ATTACK_RANGE + enemyRadius) then

				-- Listeye ekle

				hitHumanoids[hum] = true



				-- [[ DUNGEON/BOSS KONTROLÜ ]] --

				if enemy:GetAttribute("IsEventMob") == true then



					-- 1. DungeonManager

					local successDungeon, DungeonManager = pcall(function() 

						return require(game.ServerScriptService.Gameplay.EventSystem.DungeonManager) 

					end)



					if successDungeon and DungeonManager then

						-- Overkill Fix (Sadece kalan can kadar hasar yaz)

						local effectiveDamage = math.min(damageValue, hum.Health)

						local isDungeonMob = DungeonManager.RegisterHit(player, enemy, effectiveDamage)



						if isDungeonMob then 

							hum:TakeDamage(damageValue) 

							return 

						end 

					end



					-- 2. BossManager

					if enemy.Name == "BossLaser" then return end

					local successBoss, BossManager = pcall(function() 

						return require(game.ServerScriptService.Gameplay.EventSystem.BossManager) 

					end)



					if successBoss and BossManager then

						BossManager.AddDamage(player, damageValue)

						hum:TakeDamage(damageValue)

					end



					return 

				end



				-- [[ NORMAL MOBLAR ]] --

				hum:TakeDamage(damageValue)



				local dFolder = enemy:FindFirstChild("Damages")

				if not dFolder then

					dFolder = Instance.new("Folder", enemy)

					dFolder.Name = "Damages"

				end



				local pDmg = dFolder:FindFirstChild(player.Name)

				if not pDmg then

					pDmg = Instance.new("NumberValue", dFolder)

					pDmg.Name = player.Name

				end

				pDmg.Value += damageValue



				if hum.Health <= 0 then

					local isBoss = enemy:FindFirstChild("IsBoss") or string.find(enemy.Name, "Boss") ~= nil

					local zId = tonumber(zoneId) or 1

					local zoneInfo = GameConfig.GetZoneInfo(zId)



					for _, dmgRecord in pairs(dFolder:GetChildren()) do

						local tPlayer = game.Players:FindFirstChild(dmgRecord.Name)

						if tPlayer then

							local tStats = tPlayer:FindFirstChild("leaderstats")

							local damagePercent = (dmgRecord.Value / hum.MaxHealth)



							if tStats and damagePercent >= 0.20 then

								local potCoins = tPlayer:GetAttribute("CoinsMultiplier") or 1

								local potIQ = tPlayer:GetAttribute("IQMultiplier") or 1



								if tStats:FindFirstChild("Coins") then

									local baseCoins = hum.MaxHealth / 100

									tStats.Coins.Value += math.floor(baseCoins * potCoins)

								end



								if tStats:FindFirstChild("IQ") and zoneInfo then

									local baseIQ = isBoss and zoneInfo.BossIQ or zoneInfo.NormalIQ

									tStats.IQ.Value += math.floor(baseIQ * potIQ)

								end



								pcall(function() if _G.AddEnemyKill then _G.AddEnemyKill(tPlayer, 1) end end)

							end

						end

					end

					if dFolder then dFolder:Destroy() end

				end

			end

		end

	end



	-- Normal Mobs

	local mainEnemiesFolder = workspace:FindFirstChild("Enemies")

	if mainEnemiesFolder then

		for _, mapFolder in pairs(mainEnemiesFolder:GetChildren()) do

			local zoneId = string.match(mapFolder.Name, "%d+") 

			if mapFolder:IsA("Folder") or mapFolder:IsA("Model") then

				for _, enemy in pairs(mapFolder:GetChildren()) do

					ApplyDamage(enemy, zoneId)

				end

			end

		end

	end



	-- Event Mobs (Dungeon/Boss)

	for _, obj in pairs(workspace:GetChildren()) do

		if obj:GetAttribute("IsEventMob") == true and obj:FindFirstChild("Humanoid") then

			ApplyDamage(obj, nil)

		end

	end

end



ClickEvent.OnServerEvent:Connect(function(player, mode)

	mode = mode or "Normal"

	if mode == "Fast" then

		local success, hasPass = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, FAST_GAMEPASS_ID) end)

		if not success or not hasPass then mode = "Normal" end

	end



	local cdTime = (mode == "Auto") and GameConfig.Settings.AutoClickSpeed or GameConfig.Settings.ClickCooldown

	if mode == "Fast" then cdTime = 0.1 end



	local now = tick()

	if now - (lastClickTime[player.UserId] or 0) < cdTime then return end

	lastClickTime[player.UserId] = now



	GiveIQ(player)

	ProcessAttack(player)

end)



game.Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function()

		task.wait(1)

		GameConfig.UpdateWalkSpeed(player)

	end)

end)



game.Players.PlayerRemoving:Connect(function(player)

	lastClickTime[player.UserId] = nil; lastAttackTime[player.UserId] = nil

end)



------------------------------------



GameConfig :



local GameConfig = {}



-- ==============================================================================

-- [[ 1. GENEL AYARLAR (BASE STATS) ]] (DOKUNULMADI)

-- ==============================================================================

GameConfig.Settings = {

	BaseIQ = 1,          -- Başlangıç Tıklama Gücü

	BaseDamage = 10,     -- Başlangıç Kılıç Hasarı

	BaseWalkSpeed = 16,  -- Başlangıç Hızı



	ClickCooldown = 0.15, -- Tıklama Hız Limiti (Anti-AutoClicker)

	AutoClickSpeed = 1.0, -- Oyun içi Auto Click hızı

}



-- ==============================================================================

-- [[ 2. ÇARPAN SİSTEMİ (MULTIPLIERS) ]]

-- ==============================================================================

GameConfig.Multipliers = {

	-- Rebirth: Her Rebirth %50 güç katar.

	RebirthScale = 0.50, 



	-- [[ YENİ EKLENDİ ]] 

	-- Spin ödülleri için Rebirth Çarpanı. 

	-- 0.50 = Her rebirth'te çark ödülü %50 artar. (100 -> 150 -> 200...)

	WheelRebirthScale = 0.50 

}



-- [[ ROT SKILL HASAR BONUSLARI ]] (DOKUNULMADI)

GameConfig.RotMultipliers = {

	[1] = 1.2,  -- %20 Bonus

	[2] = 1.5,  -- %50 Bonus

	[3] = 1.75, -- %75 Bonus

	[4] = 2.0,  -- 2 Kat

	[5] = 2.5,  -- 2.5 Kat

	[6] = 5.0,  -- 5 Kat

	[7] = 10.0  -- 10 Kat (Godly)

}



-- ==============================================================================

-- [[ 3. BÖLGE VE DÜŞMAN İSTATİSTİKLERİ (ZONES) ]] (DOKUNULMADI)

-- ==============================================================================

GameConfig.Zones = {

	-- [[ ZONE 1: SPAWN / FOREST ]]

	[1] = { 

		Name = "Spawn",      

		NormalHP = 1000,        NormalIQ = 10,

		BossHP = 15000,         BossIQ = 150 

	},



	-- [[ ZONE 2: DESERT ]]

	[2] = { 

		Name = "Desert",      

		NormalHP = 25000,       NormalIQ = 100,

		BossHP = 500000,        BossIQ = 1500 

	},



	-- [[ ZONE 3: SNOW ]]

	[3] = { 

		Name = "Snow",      

		NormalHP = 150000,      NormalIQ = 500,

		BossHP = 3000000,       BossIQ = 7500 

	},



	-- [[ ZONE 4: VOLCANO ]]

	[4] = { 

		Name = "Volcano",     

		NormalHP = 1000000,     NormalIQ = 2500,

		BossHP = 25000000,      BossIQ = 40000 

	},



	-- [[ ZONE 5: VOID ]] (End Game)

	[5] = { 

		Name = "Void",        

		NormalHP = 15000000,    NormalIQ = 15000,

		BossHP = 500000000,     BossIQ = 250000 

	}

}



-- ==============================================================================

-- [[ 4. HESAPLAMA MOTORU (FORMÜLLER) ]]

-- ==============================================================================



-- [A] TOPLAM GÜÇ ÇARPANI HESAPLAYICI (DOKUNULMADI)

local function GetTotalMultiplier(player, statName)

	local hidden = player:FindFirstChild("HiddenStats")

	local leader = player:FindFirstChild("leaderstats")



	-- 1. Makine/Upgrade Çarpanı

	local machineMult = hidden and hidden:FindFirstChild(statName.."Multiplier") and hidden[statName.."Multiplier"].Value or 1



	-- 2. İksir (Attribute) Çarpanı

	local potionMult = player:GetAttribute(statName.."Multiplier") or 1



	-- 3. Rebirth Çarpanı

	local rebirths = leader and leader:FindFirstChild("Rebirths") and leader.Rebirths.Value or 0

	local rebirthMult = 1 + (rebirths * GameConfig.Multipliers.RebirthScale)



	-- 4. Arkadaş Bonusu

	local friendMult = 1

	if statName == "IQ" then

		friendMult = player:GetAttribute("FriendMultiplier") or 1

	end



	return machineMult * potionMult * rebirthMult * friendMult

end



-- [B] IQ HESAPLAMA (DOKUNULMADI)

function GameConfig.CalculateIQ(player)

	local hidden = player:FindFirstChild("HiddenStats")

	local clickLvl = hidden and hidden:FindFirstChild("ClickLvl") and hidden.ClickLvl.Value or 0



	-- Formül: (Base + Level) * Tüm Çarpanlar

	local basePower = GameConfig.Settings.BaseIQ + clickLvl

	local totalMult = GetTotalMultiplier(player, "IQ")



	return math.ceil(basePower * totalMult)

end



-- [C] HASAR HESAPLAMA (DOKUNULMADI)

function GameConfig.CalculateDamage(player)

	local stats = player:FindFirstChild("leaderstats")

	if not stats then return 0 end



	local currentIQ = stats:FindFirstChild("IQ") and stats.IQ.Value or 0



	-- 1. Temel Hasar (10 + IQ'nun %10'u)

	local damageValue = GameConfig.Settings.BaseDamage + (currentIQ * 0.1)



	-- 2. Pet Çarpanı

	local petMult = player:GetAttribute("PetMultiplier") or 1

	damageValue = damageValue * petMult



	-- 3. Rot Skill Çarpanı (Tablodan)

	local equippedSkill = stats:FindFirstChild("EquippedSkill")

	if equippedSkill then

		local skillID = equippedSkill.Value

		local rotBonus = GameConfig.RotMultipliers[skillID] or 1

		damageValue = damageValue * rotBonus

	end



	return math.floor(damageValue)

end



-- [D] YÜRÜME HIZI GÜNCELLEME (DOKUNULMADI)

function GameConfig.UpdateWalkSpeed(player)

	local char = player.Character

	local hum = char and char:FindFirstChild("Humanoid")

	local hidden = player:FindFirstChild("HiddenStats")



	if hum and hidden and hidden:FindFirstChild("WalkSpeedLvl") then

		local lvl = hidden.WalkSpeedLvl.Value

		-- Base Hız + (Level * 0.2)

		hum.WalkSpeed = GameConfig.Settings.BaseWalkSpeed + (lvl * 0.2)

	end

end



-- [E] ZONE BİLGİSİ ÇEKME (DOKUNULMADI)

function GameConfig.GetZoneInfo(zoneId)

	return GameConfig.Zones[zoneId] or GameConfig.Zones[1]

end



-- ==============================================================================

-- [[ F. YENİ: ÇARK ÖDÜL HESAPLAYICI ]]

-- ==============================================================================

-- SpinSystem içinde bu fonksiyonu çağırarak ödülü hesaplayacaksın.

function GameConfig.CalculateWheelReward(player, baseAmount)

	local leader = player:FindFirstChild("leaderstats")

	local rebirths = 0



	if leader and leader:FindFirstChild("Rebirths") then

		rebirths = leader.Rebirths.Value

	end



	-- Formül: Baz Miktar * (1 + (Rebirth * ÇarkÇarpanı))

	local multiplier = 1 + (rebirths * GameConfig.Multipliers.WheelRebirthScale)



	return math.floor(baseAmount * multiplier)

end



return GameConfig



--------------------------------



UpgradeManager : 



local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ YENİ ]] Remotes Klasörüne Bağlantı

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local remote = Remotes:WaitForChild("MachineUpgrade")



remote.OnServerEvent:Connect(function(player, upgradeType)

	local leaderstats = player:FindFirstChild("leaderstats")

	local hidden = player:FindFirstChild("HiddenStats")



	if not leaderstats or not hidden then return end



	local aura = leaderstats:FindFirstChild("Aura")

	local char = player.Character

	local hum = char and char:FindFirstChild("Humanoid")



	if not aura then return end



	if upgradeType == "Speed" then

		local lvl = hidden:FindFirstChild("WalkSpeedLvl") 

		if not lvl then lvl = Instance.new("IntValue", hidden); lvl.Name = "WalkSpeedLvl"; lvl.Value = 0 end

		local cost = (lvl.Value + 1) * 10 



		if lvl.Value < 100 and aura.Value >= cost then

			aura.Value -= cost

			lvl.Value += 1

			if hum then hum.WalkSpeed = 16 + (lvl.Value * 1) end

		end



	elseif upgradeType == "Click" then

		local lvl = hidden:FindFirstChild("ClickLvl")

		if not lvl then lvl = Instance.new("IntValue", hidden); lvl.Name = "ClickLvl"; lvl.Value = 0 end

		local cost = (lvl.Value + 1) * 25 



		if lvl.Value < 100 and aura.Value >= cost then

			aura.Value -= cost

			lvl.Value += 1

		end



	elseif upgradeType == "Luck" then

		local luckMult = hidden:FindFirstChild("LuckMultiplier")

		if not luckMult then return end

		local cost = math.floor(luckMult.Value * 50) 



		if luckMult.Value < 10 and aura.Value >= cost then

			aura.Value -= cost

			local yeniDeger = luckMult.Value + 0.1

			luckMult.Value = math.floor(yeniDeger * 10 + 0.5) / 10

		end

	end

end)



game.Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(char)

		local hum = char:WaitForChild("Humanoid")

		local hidden = player:WaitForChild("HiddenStats")

		if hidden then

			local speedLvl = hidden:FindFirstChild("WalkSpeedLvl")

			if speedLvl then

				hum.WalkSpeed = 16 + (speedLvl.Value * 1)

			else

				hum.WalkSpeed = 16

			end

		end

	end)

end)



-----------------------------------



DataStoreManager : 



local DataStoreService = game:GetService("DataStoreService")

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")



--print("✅ DataStoreManager: Script Başlatıldı... (MaxHatch Eklendi + Güç Sistemi)")



-- [[ AYARLAR ]] --

-- NOT: Yapıyı değiştirdiğimiz için (Sadece isim yerine tablo kaydediyoruz),

-- hataları önlemek adına V18'e geçmen sağlıklı olur. Ama V17 kalsın dersen kodda önlemini aldım.

local DATA_KEY = "BrainrotSave_V17" 

local myDataStore = DataStoreService:GetDataStore(DATA_KEY)



local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ApplyPotion = Remotes:FindFirstChild("ApplyPotion")



-- [[ 1. VERİ KAYDETME FONKSİYONU ]] --

local function savePlayerData(player)

	if not player then return end



	if not player:GetAttribute("DataLoaded") then 

		warn("⚠️ Kayıt Atlandı: " .. player.Name .. " (Verileri henüz yüklenmemişti)")

		return 

	end



	-- Klasörler

	local stats = player:FindFirstChild("leaderstats")

	local hidden = player:FindFirstChild("HiddenStats")

	local playerStats = player:FindFirstChild("PlayerStats") 

	local ownedPets = player:FindFirstChild("OwnedPets")

	local potionInv = player:FindFirstChild("PotionInventory")

	local activeEffectsFolder = player:FindFirstChild("ActiveEffects")

	local rewardDataFolder = player:FindFirstChild("RewardData")



	if not stats then return end

	if not hidden then hidden = Instance.new("Folder", player); hidden.Name = "HiddenStats" end

	-- PlayerStats kontrolü (Yoksa geçici oluştur hatayı önle)

	if not playerStats then playerStats = Instance.new("Folder", player); playerStats.Name = "PlayerStats" end 



	-- [[ GÜNCELLENEN KISIM: Pet Tablosu ]] --

	local petTable = {}

	local equippedPetsSave = {} 



	if ownedPets then

		for _, pet in pairs(ownedPets:GetChildren()) do

			-- Pet ID'sini al (Yoksa oluştur ki hata vermesin)

			local pID = pet:GetAttribute("PetID")

			if not pID then 

				pID = game:GetService("HttpService"):GenerateGUID(false)

				pet:SetAttribute("PetID", pID)

			end



			-- Sadece ismi değil, Gücü (Value) ve ID'yi kaydediyoruz

			table.insert(petTable, {

				N = pet.Name,

				V = pet.Value, -- Petin gücü

				ID = pID       -- Petin Kimliği (KAYIT İÇİN EKLENDİ)

			})



			if pet:GetAttribute("IsEquipped") == true then 

				-- Takılı olanları kaydet (PetID ile eşleşecek)

				table.insert(equippedPetsSave, pID) 

			end

		end

	end



	-- İksir Tablosu

	local potionTable = {}

	if potionInv then

		for _, pVal in pairs(potionInv:GetChildren()) do potionTable[pVal.Name] = pVal.Value end

	end



	-- Efekt Tablosu

	local activeEffectsTable = {}

	if activeEffectsFolder then

		for _, effectVal in pairs(activeEffectsFolder:GetChildren()) do

			if effectVal.Value > 0 then activeEffectsTable[effectVal.Name] = effectVal.Value end

		end

	end



	-- Reward Verisi

	local rewardSave = {LastDaily=0, LastGroupClaim=0, WeeklyDay=1, LastWeekly=0}

	if rewardDataFolder then

		if rewardDataFolder:FindFirstChild("LastDaily") then rewardSave.LastDaily = rewardDataFolder.LastDaily.Value end

		if rewardDataFolder:FindFirstChild("LastGroupClaim") then rewardSave.LastGroupClaim = rewardDataFolder.LastGroupClaim.Value end

		if rewardDataFolder:FindFirstChild("WeeklyDay") then rewardSave.WeeklyDay = rewardDataFolder.WeeklyDay.Value end

		if rewardDataFolder:FindFirstChild("LastWeekly") then rewardSave.LastWeekly = rewardDataFolder.LastWeekly.Value end

	end



	-- [[ ANA VERİ PAKETİ ]] --

	local dataToSave = {

		IQ = stats:FindFirstChild("IQ") and stats.IQ.Value or 0, 

		Rebirths = stats:FindFirstChild("Rebirths") and stats.Rebirths.Value or 0, 

		Coins = stats:FindFirstChild("Coins") and stats.Coins.Value or 0,

		Essence = stats:FindFirstChild("Essence") and stats.Essence.Value or 0,

		Aura = stats:FindFirstChild("Aura") and stats.Aura.Value or 0,



		RSToken = stats:FindFirstChild("RSToken") and stats.RSToken.Value or 0,

		EquippedSkill = stats:FindFirstChild("EquippedSkill") and stats.EquippedSkill.Value or 1,



		-- HiddenStats içindekiler

		LuckMultiplier = hidden:FindFirstChild("LuckMultiplier") and hidden.LuckMultiplier.Value or 1, 

		IQMultiplier = hidden:FindFirstChild("IQMultiplier") and hidden.IQMultiplier.Value or 1,

		AuraMultiplier = hidden:FindFirstChild("AuraMultiplier") and hidden.AuraMultiplier.Value or 1, 

		EssenceMultiplier = hidden:FindFirstChild("EssenceMultiplier") and hidden.EssenceMultiplier.Value or 1,

		ClickLvl = hidden:FindFirstChild("ClickLvl") and hidden.ClickLvl.Value or 0, 

		WalkSpeedLvl = hidden:FindFirstChild("WalkSpeedLvl") and hidden.WalkSpeedLvl.Value or 0,



		-- Max Hatch Verisi

		MaxHatch = playerStats:FindFirstChild("MaxHatch") and playerStats.MaxHatch.Value or 1,



		Pets = petTable, 

		EquippedPets = equippedPetsSave, 

		Potions = potionTable, 

		ActiveEffects = activeEffectsTable,

		RewardData = rewardSave 

	}



	local success, err = pcall(function()

		myDataStore:SetAsync("Player_" .. player.UserId, dataToSave)



		-- Sıralama Kayıtları

		if stats:FindFirstChild("IQ") then 

			DataStoreService:GetOrderedDataStore("TopIQ_Live_Final"):SetAsync(player.UserId, stats.IQ.Value) 

		end

		if stats:FindFirstChild("Coins") then 

			DataStoreService:GetOrderedDataStore("TopCoins_Live_Final"):SetAsync(player.UserId, stats.Coins.Value) 

		end

		if stats:FindFirstChild("Essence") then 

			DataStoreService:GetOrderedDataStore("TopEssence_Live_Final"):SetAsync(player.UserId, stats.Essence.Value) 

		end

	end)



	if success then 

		--		print("💾 Kaydedildi: " .. player.Name)

	else 

		warn("❌ Kayıt Hatası ("..player.Name.."): " .. tostring(err)) 

	end

end



-- [[ 2. OYUNCU GİRİŞİ VE VERİ YÜKLEME ]] --

game.Players.PlayerAdded:Connect(function(player)



	-- Klasör Yapısı

	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder", player)

	leaderstats.Name = "leaderstats"



	local hiddenStats = player:FindFirstChild("HiddenStats") or Instance.new("Folder", player)

	hiddenStats.Name = "HiddenStats"



	-- PlayerStats ve MaxHatch

	local playerStats = player:FindFirstChild("PlayerStats") or Instance.new("Folder", player)

	playerStats.Name = "PlayerStats"



	local maxHatch = playerStats:FindFirstChild("MaxHatch") or Instance.new("IntValue", playerStats)

	maxHatch.Name = "MaxHatch"

	maxHatch.Value = 1 



	local ownedPets = player:FindFirstChild("OwnedPets") or Instance.new("Folder", player); ownedPets.Name = "OwnedPets"

	local potionInv = player:FindFirstChild("PotionInventory") or Instance.new("Folder", player); potionInv.Name = "PotionInventory"

	local activeEffectsFolder = player:FindFirstChild("ActiveEffects") or Instance.new("Folder", player); activeEffectsFolder.Name = "ActiveEffects"

	local rewardDataFolder = player:FindFirstChild("RewardData") or Instance.new("Folder", player); rewardDataFolder.Name = "RewardData"

	local playtimeDataFolder = player:FindFirstChild("PlaytimeData") or Instance.new("Folder", player); playtimeDataFolder.Name = "PlaytimeData"

	local sessionTime = player:FindFirstChild("SessionStartTime") or Instance.new("NumberValue", player); sessionTime.Name = "SessionStartTime"; sessionTime.Value = workspace:GetServerTimeNow()



	-- Reward Values

	local lastDaily = rewardDataFolder:FindFirstChild("LastDaily") or Instance.new("NumberValue", rewardDataFolder); lastDaily.Name = "LastDaily"

	local lastGroup = rewardDataFolder:FindFirstChild("LastGroupClaim") or Instance.new("NumberValue", rewardDataFolder); lastGroup.Name = "LastGroupClaim"

	local weeklyDay = rewardDataFolder:FindFirstChild("WeeklyDay") or Instance.new("NumberValue", rewardDataFolder); weeklyDay.Name = "WeeklyDay"; weeklyDay.Value = 1

	local lastWeekly = rewardDataFolder:FindFirstChild("LastWeekly") or Instance.new("NumberValue", rewardDataFolder); lastWeekly.Name = "LastWeekly"



	for i = 1, 9 do 

		if not playtimeDataFolder:FindFirstChild("Reward"..i) then

			local b = Instance.new("BoolValue", playtimeDataFolder)

			b.Name = "Reward" .. i

		end

	end



	-- [[ STAT OLUŞTURMA ]] --

	local iq = leaderstats:FindFirstChild("IQ") or Instance.new("IntValue", leaderstats); iq.Name = "IQ"

	local rebirths = leaderstats:FindFirstChild("Rebirths") or Instance.new("IntValue", leaderstats); rebirths.Name = "Rebirths"

	local coins = leaderstats:FindFirstChild("Coins") or Instance.new("NumberValue", leaderstats); coins.Name = "Coins"



	local essence = leaderstats:FindFirstChild("Essence") or Instance.new("NumberValue", leaderstats); essence.Name = "Essence"

	local aura = leaderstats:FindFirstChild("Aura") or Instance.new("IntValue", leaderstats); aura.Name = "Aura"

	local rsToken = leaderstats:FindFirstChild("RSToken") or Instance.new("IntValue", leaderstats); rsToken.Name = "RSToken"

	local equippedSkill = leaderstats:FindFirstChild("EquippedSkill") or Instance.new("IntValue", leaderstats); equippedSkill.Name = "EquippedSkill"; equippedSkill.Value = 1



	-- [[ HIDDEN STATS ]] --

	local luckMultiplier = hiddenStats:FindFirstChild("LuckMultiplier") or Instance.new("NumberValue", hiddenStats); luckMultiplier.Name = "LuckMultiplier"; luckMultiplier.Value = 1 

	local iqMultiplier = hiddenStats:FindFirstChild("IQMultiplier") or Instance.new("NumberValue", hiddenStats); iqMultiplier.Name = "IQMultiplier"; iqMultiplier.Value = 1

	local auraMultiplier = hiddenStats:FindFirstChild("AuraMultiplier") or Instance.new("NumberValue", hiddenStats); auraMultiplier.Name = "AuraMultiplier"; auraMultiplier.Value = 1

	local essenceMultiplier = hiddenStats:FindFirstChild("EssenceMultiplier") or Instance.new("NumberValue", hiddenStats); essenceMultiplier.Name = "EssenceMultiplier"; essenceMultiplier.Value = 1

	local clickLvl = hiddenStats:FindFirstChild("ClickLvl") or Instance.new("IntValue", hiddenStats); clickLvl.Name = "ClickLvl"

	local walkSpeedLvl = hiddenStats:FindFirstChild("WalkSpeedLvl") or Instance.new("IntValue", hiddenStats); walkSpeedLvl.Name = "WalkSpeedLvl"; walkSpeedLvl.Value = 0 



	-- [[ VERİ YÜKLEME ]] --

	local userId = "Player_" .. player.UserId

	local data = nil

	local success = false

	local attempts = 0



	repeat

		success, data = pcall(function() return myDataStore:GetAsync(userId) end)

		if not success then

			attempts = attempts + 1

			task.wait(2)

		end

	until success or attempts >= 3



	if success and data then

		-- Veriler Yükleniyor

		iq.Value = data.IQ or 0

		rebirths.Value = data.Rebirths or 0

		coins.Value = data.Coins or 0 

		essence.Value = data.Essence or 0

		aura.Value = data.Aura or 0

		rsToken.Value = data.RSToken or 0 

		equippedSkill.Value = data.EquippedSkill or 1



		luckMultiplier.Value = data.LuckMultiplier or 1

		iqMultiplier.Value = data.IQMultiplier or 1

		auraMultiplier.Value = data.AuraMultiplier or 1

		essenceMultiplier.Value = data.EssenceMultiplier or 1

		clickLvl.Value = data.ClickLvl or 0

		walkSpeedLvl.Value = data.WalkSpeedLvl or 0 



		if data.MaxHatch then

			maxHatch.Value = data.MaxHatch

		else

			maxHatch.Value = 1

		end



		if data.RewardData then

			lastDaily.Value = data.RewardData.LastDaily or 0

			lastGroup.Value = data.RewardData.LastGroupClaim or 0

			weeklyDay.Value = data.RewardData.WeeklyDay or 1

			lastWeekly.Value = data.RewardData.LastWeekly or 0

		end



		-- [[ GÜNCELLENEN KISIM: Pet Yükleme ]] --

		if data.Pets then

			for _, petInfo in pairs(data.Pets) do

				local pName = ""

				local pValue = 1

				local pID = nil



				-- Eski kayıt mı yeni kayıt mı kontrol et

				if type(petInfo) == "string" then

					pName = petInfo -- Eski tip (Sadece isim)

					-- Eski tip kayıtta ID olmadığı için yeni oluşturuyoruz

					pID = game:GetService("HttpService"):GenerateGUID(false)

				else

					pName = petInfo.N -- Yeni tip (İsim)

					pValue = petInfo.V or 1 -- Yeni tip (Güç)

					pID = petInfo.ID or game:GetService("HttpService"):GenerateGUID(false) -- YENİ: ID Yükle

				end



				local p = Instance.new("NumberValue")

				p.Name = pName

				p.Value = pValue -- Gücü buraya yazıyoruz!



				-- Attribute olarak ID'yi ata

				p:SetAttribute("PetID", pID)



				-- Takılı pet kontrolü (ID'ye göre)

				if data.EquippedPets and table.find(data.EquippedPets, pID) then

					p:SetAttribute("IsEquipped", true)

				end



				-- Geriye dönük uyumluluk (Eski datalar isimle kaydedilmiş olabilir)

				-- Eğer ID ile bulamadıysa ve liste eski tipse:

				if data.EquippedPets and table.find(data.EquippedPets, pName) then 

					p:SetAttribute("IsEquipped", true)

				end



				p.Parent = ownedPets

			end

		end



		local potionTypes = {"Luck", "IQ", "Aura", "Essence", "Speed"}

		for _, pName in pairs(potionTypes) do

			local val = potionInv:FindFirstChild(pName) or Instance.new("IntValue", potionInv)

			val.Name = pName

			if data.Potions and data.Potions[pName] then val.Value = data.Potions[pName] else val.Value = 0 end

		end



		if data.ActiveEffects then

			for pName, durationLeft in pairs(data.ActiveEffects) do

				if durationLeft > 5 then 

					if ApplyPotion then ApplyPotion:Fire(player, pName, durationLeft, "🧪") end

				end

			end

		end

		--		print("✅ Veriler Yüklendi: " .. player.Name)

	else

		-- Yeni Oyuncu

		rsToken.Value = 0 

		equippedSkill.Value = 1

		maxHatch.Value = 1 



		local potionTypes = {"Luck", "IQ", "Aura", "Essence", "Speed"}

		for _, pName in pairs(potionTypes) do

			local val = Instance.new("IntValue", potionInv); val.Name = pName; val.Value = 0

		end

	end



	player:SetAttribute("DataLoaded", true)

end)



-- [[ 3. AUTO-SAVE & SHUTDOWN ]] --

task.spawn(function()

	while true do

		task.wait(120) 

		for _, player in ipairs(Players:GetPlayers()) do

			savePlayerData(player)

			task.wait(1) 

		end

	end

end)



game.Players.PlayerRemoving:Connect(function(player) 

	savePlayerData(player) 

end)



game:BindToClose(function()

	if RunService:IsStudio() then task.wait(3) return end 

	for _, player in ipairs(Players:GetPlayers()) do 

		task.spawn(function() savePlayerData(player) end) 

	end

	task.wait(3) 

end)



--------------------------------



PotionManager :



local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ YENİ ]] Remotes Bağlantıları

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local PotionEvent = Remotes:WaitForChild("PotionEvent") 

local ApplyPotion = Remotes:WaitForChild("ApplyPotion")

local DrinkEvent = Remotes:WaitForChild("DrinkPotionEvent")



local activeLoops = {} 



game.Players.PlayerAdded:Connect(function(player)

	player:SetAttribute("IQMultiplier", 1)

	player:SetAttribute("EssenceMultiplier", 1)

	player:SetAttribute("AuraMultiplier", 1)

	player:SetAttribute("LuckBonus", 0) 



	if not player:FindFirstChild("ActiveEffects") then

		local f = Instance.new("Folder", player)

		f.Name = "ActiveEffects"

	end

end)



DrinkEvent.OnServerEvent:Connect(function(player, potionName)

	local inventory = player:FindFirstChild("PotionInventory")

	if not inventory then return end

	local potionVal = inventory:FindFirstChild(potionName)

	if potionVal and potionVal.Value > 0 then

		potionVal.Value -= 1



		local duration = 300

		local emoji = "🧪"

		if potionName == "IQ" then emoji = "🧠"

		elseif potionName == "Luck" then emoji = "🍀"

		elseif potionName == "Aura" then emoji = "✨"

		elseif potionName == "Essence" then emoji = "💎"

		elseif potionName == "Speed" then duration = 60; emoji = "⚡"

		end



		ApplyPotion:Fire(player, potionName, duration, emoji)

	end

end)



ApplyPotion.Event:Connect(function(player, potionName, duration, emoji)

	if not player then return end



	local effectsFolder = player:WaitForChild("ActiveEffects", 5)

	if not effectsFolder then return end



	local timerVal = effectsFolder:FindFirstChild(potionName)

	if not timerVal then

		timerVal = Instance.new("IntValue", effectsFolder)

		timerVal.Name = potionName

	end

	timerVal.Value = duration



	if activeLoops[player.UserId] and activeLoops[player.UserId][potionName] then

		task.cancel(activeLoops[player.UserId][potionName])

	end

	if not activeLoops[player.UserId] then activeLoops[player.UserId] = {} end



	if potionName == "IQ" then player:SetAttribute("IQMultiplier", 2)

	elseif potionName == "Luck" then player:SetAttribute("LuckBonus", (player:GetAttribute("LuckBonus") or 0) + 2)

	elseif potionName == "Aura" then player:SetAttribute("AuraMultiplier", 2)

	elseif potionName == "Essence" then player:SetAttribute("EssenceMultiplier", 2)

	elseif potionName == "Speed" then

		if player.Character and player.Character:FindFirstChild("Humanoid") then

			player.Character.Humanoid.WalkSpeed = 32

		end

	end



	PotionEvent:FireClient(player, potionName, emoji, duration, true)



	activeLoops[player.UserId][potionName] = task.spawn(function()

		while timerVal.Value > 0 do

			task.wait(1)

			if not player or not player.Parent then break end 

			timerVal.Value = timerVal.Value - 1

		end



		if player and player.Parent then

			if potionName == "IQ" then player:SetAttribute("IQMultiplier", 1)

			elseif potionName == "Luck" then 

				local current = player:GetAttribute("LuckBonus") or 2

				player:SetAttribute("LuckBonus", math.max(0, current - 2))

			elseif potionName == "Aura" then player:SetAttribute("AuraMultiplier", 1)

			elseif potionName == "Essence" then player:SetAttribute("EssenceMultiplier", 1)

			elseif potionName == "Speed" then

				if player.Character and player.Character:FindFirstChild("Humanoid") then

					local baseSpeed = 16

					local hidden = player:FindFirstChild("HiddenStats")

					if hidden and hidden:FindFirstChild("WalkSpeedLvl") then

						baseSpeed = 16 + (hidden.WalkSpeedLvl.Value)

					end

					player.Character.Humanoid.WalkSpeed = baseSpeed

				end

			end

			timerVal:Destroy() 

			activeLoops[player.UserId][potionName] = nil

		end

	end)

end)



game.Players.PlayerRemoving:Connect(function(plr)

	if activeLoops[plr.UserId] then

		for _, loop in pairs(activeLoops[plr.UserId]) do task.cancel(loop) end

		activeLoops[plr.UserId] = nil

	end

end)



-----------------------------------



RebirthManager : 



local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [[ YENİ ]] Remotes Klasörüne Bağlantı

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local remote = Remotes:WaitForChild("RebirthEvent")



local cooldowns = {}



remote.OnServerEvent:Connect(function(player)

	if cooldowns[player.UserId] and tick() - cooldowns[player.UserId] < 1 then return end

	cooldowns[player.UserId] = tick()



	local stats = player:FindFirstChild("leaderstats")

	if not stats then return end



	local rb = stats:FindFirstChild("Rebirths")

	local essence = stats:FindFirstChild("Essence")

	local iq = stats:FindFirstChild("IQ")



	if not rb or not essence or not iq then return end



	local maliyet = 10 

	if rb.Value == 1 then maliyet = 25

	elseif rb.Value == 2 then maliyet = 50

	elseif rb.Value >= 3 then maliyet = 100

	end



	if essence.Value >= maliyet then

		essence.Value = essence.Value - maliyet

		iq.Value = 0

		rb.Value = rb.Value + 1

		print("♻️ " .. player.Name .. " Rebirth attı! Yeni Seviye: " .. rb.Value)

	end

end)



--------------------------------



RewardSettings : 



local RewardSettings = {

	-- [[ GÜVENLİ DENGE AYARLARI ]] --

	RebirthMultiplier = 0.50, 



	RarityColors = {

		Common = Color3.fromRGB(200, 200, 200),

		Rare = Color3.fromRGB(85, 255, 127),

		Epic = Color3.fromRGB(170, 85, 255),

		Legendary = Color3.fromRGB(255, 170, 0),

		Mythical = Color3.fromRGB(255, 85, 255),

		Potion = Color3.fromRGB(255, 105, 180),

		Coins = Color3.fromRGB(255, 215, 0)

	},



	Multipliers = {

		Hourly = 1, Daily = 5, Group = 10, Weekly = 15, WeeklyDay7 = 50 

	},



	PlaytimeRewards = {

		{ID = 1, Time = 300},

		{ID = 2, Time = 600},

		{ID = 3, Time = 900},

		{ID = 4, Time = 1800},

		{ID = 5, Time = 2700},

		{ID = 6, Time = 3600},

		{ID = 7, Time = 5400},

		{ID = 8, Time = 7200},

		{ID = 9, Time = 10800},

	},



	-- [[ DENGELENMİŞ MASTER HAVUZ ]] --

	-- Toplam Şans: ~10,000

	MasterPool = {

		-- [[ COMMON (%65 Şans) - Aura YOK ]] --

		-- Aura buradan kaldırıldı. Sadece temel kaynaklar.

		{Type = "Coins",   Amount = 25,   Chance = 2750, Rarity = "Common"}, 

		{Type = "IQ",      Amount = 25,   Chance = 2750, Rarity = "Common"}, 

		{Type = "Essence", Amount = 1,     Chance = 1000, Rarity = "Common"},



		-- [[ RARE (%21 Şans) - Aura Çok Nadir ]] --

		{Type = "Coins",   Amount = 150,  Chance = 1000, Rarity = "Rare"}, 

		{Type = "IQ",      Amount = 150,  Chance = 1000, Rarity = "Rare"},

		-- Aura buraya eklendi ama şansı sadece %1 (100 puan)

		{Type = "Aura",    Amount = 1,     Chance = 100,  Rarity = "Rare"}, 



		-- [[ POTIONS (%10 Şans) ]] --

		-- Aura İksiri şansı düşürüldü (200 -> 100)

		{Type = "LuckPotion",    Duration = 600,  Chance = 250,  Rarity = "Potion", PotionType = "Luck"},

		{Type = "IQPotion",      Duration = 600,  Chance = 250,  Rarity = "Potion", PotionType = "IQ"},

		{Type = "CoinsPotion",   Duration = 600,  Chance = 250,  Rarity = "Potion", PotionType = "Coins"},

		{Type = "EssencePotion", Duration = 600,  Chance = 200,  Rarity = "Potion", PotionType = "Essence"},

		{Type = "AuraPotion",    Duration = 300,  Chance = 50,   Rarity = "Potion", PotionType = "Aura"}, -- Çok nadir iksir



		-- [[ EPIC (%3.5 Şans) ]] --

		{Type = "Coins",   Amount = 750,  Chance = 150,  Rarity = "Epic"}, 

		{Type = "IQ",      Amount = 750,  Chance = 150,  Rarity = "Epic"},

		-- Aura burada da çok az (Sadece 50 puan = %0.5 Şans)

		{Type = "Aura",    Amount = 3,     Chance = 50,   Rarity = "Epic"},



		-- [[ LEGENDARY (%0.5 Şans) ]] --

		{Type = "Coins",   Amount = 5000, Chance = 25,   Rarity = "Legendary"}, 

		{Type = "IQ",      Amount = 5000, Chance = 25,   Rarity = "Legendary"},

	},



	-- [[ 7. GÜN ÖZEL HAVUZU ]] --

	-- 7 Gün giren oyuncuya ayıp olmasın diye buradaki Aura miktarını koruduk ama şansını kıstık.

	SpecialSeventhDayPool = {

		{Type = "Coins",   Amount = 50000, Chance = 4500, Rarity = "Mythical"}, 

		{Type = "IQ",      Amount = 50000, Chance = 4500, Rarity = "Mythical"},

		{Type = "Essence", Amount = 50,    Chance = 950,  Rarity = "Mythical"},

		-- Aura şansı sadece %0.5

		{Type = "Aura",    Amount = 7,     Chance = 50,  Rarity = "Mythical"} 

	},



	Daily = { Cooldown = 86400 },

	Group = { Cooldown = 86400, GroupID = 33524021 },

}



-- [[ HESAPLAMA MOTORU ]] --

function RewardSettings.GetPotionDisplay(duration, pType)

	local mins = math.floor((duration or 300) / 60)

	return mins .. "m " .. (pType or "Potion")

end



function RewardSettings.FormatNumber(n)

	if not n or n < 1000 then return tostring(math.floor(n or 0)) end

	local suffixes = {"", "k", "M", "B", "T", "Q", "Qi", "Sx"}

	local i = 1

	while n >= 1000 and i < #suffixes do

		n = n / 1000

		i = i + 1

	end

	return string.format("%.1f%s", n, suffixes[i]):gsub("%.0", "")

end



function RewardSettings.FormatTime(s)

	if s <= 0 then return "READY!" end

	local hours = math.floor(s / 3600)

	local mins = math.floor((s % 3600) / 60)

	local secs = math.floor(s % 60)

	return string.format("%02d:%02d:%02d", hours, mins, secs)

end



function RewardSettings.GetScaledValue(player, baseValue, category)

	if not baseValue then return 0 end



	local stats = player:FindFirstChild("leaderstats")

	if not stats then return baseValue end



	-- Rebirth Çarpanı

	local rebirths = stats:FindFirstChild("Rebirths") and stats.Rebirths.Value or 0



	-- Kategori Çarpanı

	local catMult = RewardSettings.Multipliers[category or "Hourly"] or 1



	-- Denge Formülü

	local rebirthBonus = 1 + (rebirths * RewardSettings.RebirthMultiplier)



	return math.floor(baseValue * catMult * rebirthBonus)

end



function RewardSettings.RollFromPool(isSeventhDay)

	local pool = isSeventhDay and RewardSettings.SpecialSeventhDayPool or RewardSettings.MasterPool

	local roll = math.random(1, 10000)

	local currentChance = 0



	for _, item in pairs(pool) do

		currentChance = currentChance + item.Chance

		if roll <= currentChance then return item end

	end



	return pool[1] 

end



return RewardSettings



-----------------------------------



RewardManager : 



local ReplicatedStorage = game:GetService("ReplicatedStorage")



-- [[ YENİ ]] Yollar

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Modules = ReplicatedStorage:WaitForChild("Modules")



local RewardSettings = require(Modules:WaitForChild("RewardSettings"))

local RewardEvent = Remotes:WaitForChild("RewardEvent")

local PotionEvent = Remotes:WaitForChild("PotionEvent")



local GROUP_ID = 33524021 



-- [[ ÖDÜL İŞLEME FONKSİYONU (Aynı Kaldı) ]] --

local function processReward(player, rolledItem, category)

	local stats = player:FindFirstChild("leaderstats")

	if not stats or not rolledItem then return false end



	local finalAmount = RewardSettings.GetScaledValue(player, rolledItem.Amount or 0, category)

	local rewardType = rolledItem.Type



	if rewardType:find("Potion") then

		local potionName = rolledItem.PotionType or rewardType:gsub("Potion", "")

		local duration = rolledItem.Duration or 300

		local emoji = (potionName == "Luck") and "🍀" or "🧠"

		local minutes = math.floor(duration / 60)



		PotionEvent:FireClient(player, potionName, emoji, duration, true)

		return true, minutes .. "m " .. potionName, rewardType

	end



	local statObj = stats:FindFirstChild(rewardType)

	if statObj then

		statObj.Value += finalAmount

		return true, finalAmount, rewardType

	end

	return false

end



-- [[ EVENT DİNLEYİCİSİ (Aynı Kaldı) ]] --

RewardEvent.OnServerEvent:Connect(function(player, rType, id, extra)

	if rType == "ClaimReward" then

		local category = id 

		-- Bu klasörleri artık DataManager oluşturuyor, biz sadece kullanıyoruz

		local rData = player:WaitForChild("RewardData", 5) 

		local ptData = player:WaitForChild("PlaytimeData", 5)



		if not rData then return end -- Eğer veri yüklenmediyse işlem yapma



		local canClaim = false

		local isSpecial = false

		local targetID = nil



		local currentTime = os.time()

		local COOLDOWN = 86400



		if category == "Daily" then

			if rData.LastDaily.Value == 0 or (rData.LastDaily.Value + COOLDOWN) <= currentTime then

				canClaim = true

			end

		elseif category == "Weekly" then

			local day = tonumber(extra) 

			if day and day == rData.WeeklyDay.Value and (rData.LastWeekly.Value == 0 or (rData.LastWeekly.Value + COOLDOWN) <= currentTime) then

				canClaim = true

				isSpecial = (day == 7)

				targetID = day

			end

		elseif category == "Group" then

			if player:IsInGroup(GROUP_ID) and (rData.LastGroupClaim.Value == 0 or (rData.LastGroupClaim.Value + COOLDOWN) <= currentTime) then

				canClaim = true

			end

		elseif category == "Playtime" then

			local pID = tonumber(extra)

			if pID then

				local claimObj = ptData and ptData:FindFirstChild("Reward"..tostring(pID))

				local rewardInfo = RewardSettings.PlaytimeRewards[pID]



				-- SessionStartTime'ı DataManager oluşturuyor

				local sessionTime = player:FindFirstChild("SessionStartTime")

				local timePlayed = workspace:GetServerTimeNow() - (sessionTime and sessionTime.Value or workspace:GetServerTimeNow())



				if claimObj and claimObj.Value == false and rewardInfo and timePlayed >= rewardInfo.Time then 

					canClaim = true 

					targetID = pID

				end

			end

		end



		if canClaim then

			local rolled = RewardSettings.RollFromPool(isSpecial)

			local success, amt, rName = processReward(player, rolled, category)



			if success then

				if category == "Daily" then rData.LastDaily.Value = currentTime

				elseif category == "Group" then rData.LastGroupClaim.Value = currentTime

				elseif category == "Weekly" then 

					rData.LastWeekly.Value = currentTime

					rData.WeeklyDay.Value = (rData.WeeklyDay.Value % 7) + 1

				elseif category == "Playtime" then

					local pID = tonumber(extra)

					if pID and ptData:FindFirstChild("Reward"..tostring(pID)) then

						ptData["Reward"..tostring(pID)].Value = true

					end

				end



				local resultText = (typeof(amt) == "string") and amt or (RewardSettings.FormatNumber(amt).." "..rName)



				RewardEvent:FireClient(player, "DailyResultUpdate", true, resultText, {

					Type = rName, 

					Amount = (tonumber(amt) or 0), 

					RawAmt = resultText,

					Category = category,

					ID = targetID

				})

			end

		end

	end

end)



-- [[ TEST KOMUTU (!ready) ]] --

game.Players.PlayerAdded:Connect(function(player)

	player.Chatted:Connect(function(msg)

		if msg == "!ready" then

			if player:FindFirstChild("RewardData") then

				player.RewardData.LastDaily.Value = 0

				player.RewardData.LastWeekly.Value = 0

				player.RewardData.LastGroupClaim.Value = 0

			end

			if player:FindFirstChild("PlaytimeData") then

				for i=1,9 do player.PlaytimeData["Reward"..i].Value = false end

			end

			if player:FindFirstChild("SessionStartTime") then

				player.SessionStartTime.Value = workspace:GetServerTimeNow() - 50000

			end

		end

	end)

end)



----------------------------------



SpinConfig : 



local SpinConfig = {}



-- [[ 1. ÇARK DİLİMLERİ ]] --

-- Type: "Coins", "IQ", "Essence", "Spin", "Item"

-- Amount: Miktar

-- Chance: Çıkma şansı (Yüksek sayı = Daha kolay)

SpinConfig.Slots = {

	[1] = { Type = "Coins",   Amount = 50,    Chance = 250,  Name = "500 Coins" },

	[2] = { Type = "IQ",      Amount = 250,   Chance = 250,  Name = "2.5K IQ" },

	[3] = { Type = "Spin",    Amount = 1,      Chance = 150,  Name = "+1 Spin" },

	[4] = { Type = "Essence", Amount = 5,     Chance = 100,  Name = "15 Essence" },

	[5] = { Type = "Coins",   Amount = 500,   Chance = 50,   Name = "5K Coins" },

	[6] = { Type = "Spin",    Amount = 3,      Chance = 20,   Name = "+3 Spins" },

	[7] = { Type = "Item",    ItemName = "Pet", Chance = 1,   Name = "SECRET PET" }

}



-- [[ 2. AYARLAR ]] --

SpinConfig.SliceAngle = 360 / 7       -- 7 dilim olduğu için

SpinConfig.Cooldown = 12 * 60 * 60    -- 12 Saat (Saniye cinsinden)

SpinConfig.SpinDuration = 4           -- Çarkın dönme süresi (Saniye)



-- [[ 3. MARKET ID'LERİ (ÖNEMLİ) ]] --

-- Buradaki ID'lerin oyun ayarlarında "Developer Product" olması ZORUNLUDUR.

-- "Pass" (Gamepass) ID'si yazarsan çalışmaz. Lütfen kontrol et.

SpinConfig.Products = {

	SmallPack = 3518911316,          -- 1 Spin Normal

	SmallPack_Discount = 3518911585, -- 1 Spin İndirimli

	MediumPack = 3518912363,         -- 3 Spin

	LargePack = 3518912701,          -- 10 Spin

}



return SpinConfig



-----------------------------------



SpinSystem : 



-- Script: SpinSystem (Server)

-- Konum: ServerScriptService -> Systems



local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local MarketplaceService = game:GetService("MarketplaceService")



local Modules = ReplicatedStorage:WaitForChild("Modules")

local SpinConfig = require(Modules:WaitForChild("SpinConfig"))

local GameConfig = require(Modules:WaitForChild("GameConfig")) 



local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)

Remotes.Name = "Remotes"



local SpinFunction = Remotes:FindFirstChild("SpinAction") or Instance.new("RemoteFunction", Remotes)

SpinFunction.Name = "SpinAction"



local UpdateUI = Remotes:FindFirstChild("UpdateUI") or Instance.new("RemoteEvent", Remotes)

UpdateUI.Name = "UpdateUI"



-- Macro Koruması

local isSpinning = {}



local function PickReward()

	local totalWeight = 0

	for _, data in pairs(SpinConfig.Slots) do totalWeight += data.Chance end

	local r = math.random(1, totalWeight)

	local c = 0

	for i, data in ipairs(SpinConfig.Slots) do

		c += data.Chance

		if r <= c then return i, data end

	end

	return 1, SpinConfig.Slots[1]

end



SpinFunction.OnServerInvoke = function(player)

	-- 1. Kontroller

	if isSpinning[player.UserId] then return false, "Already Spinning" end



	local hidden = player:FindFirstChild("HiddenStats")

	local wheelSpin = hidden and hidden:FindFirstChild("WheelSpin")

	local lastZeroTime = hidden and hidden:FindFirstChild("LastZeroTime")



	if not wheelSpin or wheelSpin.Value <= 0 then

		UpdateUI:FireClient(player) 

		return false, "NoSpin"

	end



	-- 2. İşlem Başlasın

	isSpinning[player.UserId] = true

	wheelSpin.Value -= 1 



	if wheelSpin.Value == 0 then

		lastZeroTime.Value = os.time()

	end



	UpdateUI:FireClient(player) 



	local slotIndex, rewardData = PickReward()



	-- 3. Ödülü Ver

	task.spawn(function()

		task.wait(SpinConfig.SpinDuration)

		if player then

			local leaderstats = player:FindFirstChild("leaderstats")



			-- Miktarı Hesapla (GameConfig üzerinden)

			local finalAmount = rewardData.Amount



			if rewardData.Type == "Coins" or rewardData.Type == "IQ" or rewardData.Type == "Essence" then

				finalAmount = GameConfig.CalculateWheelReward(player, rewardData.Amount)

			end



			-- [[ PRİNT İŞLEMİ BURADA ]] --

			print("------------------------------------------------")

			print("🎉 SPIN KAZANANI: " .. player.Name)

			print("🎁 ÇIKAN ÖDÜL: " .. rewardData.Name)

			print("🔹 BAZ MİKTAR: " .. rewardData.Amount)

			print("📈 VERİLEN (Rebirth Dahil): " .. finalAmount)

			print("------------------------------------------------")



			-- Dağıtım

			if rewardData.Type == "Coins" and leaderstats and leaderstats:FindFirstChild("Coins") then

				leaderstats.Coins.Value += finalAmount



			elseif rewardData.Type == "IQ" and leaderstats and leaderstats:FindFirstChild("IQ") then

				leaderstats.IQ.Value += finalAmount



			elseif rewardData.Type == "Essence" and leaderstats and leaderstats:FindFirstChild("Essence") then

				leaderstats.Essence.Value += finalAmount



			elseif rewardData.Type == "Spin" then

				wheelSpin.Value += rewardData.Amount 

				UpdateUI:FireClient(player)



			elseif rewardData.Type == "Item" then

				print("⚠️ Eşya kazanıldı (Envanter kodu eklenmeli): " .. rewardData.ItemName)

			end



			isSpinning[player.UserId] = false

		end

	end)



	return true, slotIndex, rewardData.Name

end



-- 12 Saat Kontrolü

task.spawn(function()

	while true do

		task.wait(5)

		for _, player in pairs(Players:GetPlayers()) do

			local hidden = player:FindFirstChild("HiddenStats")

			if hidden then

				local spins = hidden:FindFirstChild("WheelSpin")

				local lastTime = hidden:FindFirstChild("LastZeroTime")



				if spins and spins.Value == 0 and lastTime then

					if (os.time() - lastTime.Value) >= SpinConfig.Cooldown then

						spins.Value = 1

						lastTime.Value = os.time()

						UpdateUI:FireClient(player)

					end

				end

			end

		end

	end

end)



-- Satın Alım

MarketplaceService.ProcessReceipt = function(receiptInfo)

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end



	local hidden = player:FindFirstChild("HiddenStats")

	local wheelSpin = hidden and hidden:FindFirstChild("WheelSpin")

	local pid = receiptInfo.ProductId

	local prods = SpinConfig.Products



	if wheelSpin then

		if pid == prods.SmallPack or pid == prods.SmallPack_Discount then

			wheelSpin.Value += 1

		elseif pid == prods.MediumPack then

			wheelSpin.Value += 3

		elseif pid == prods.LargePack then

			wheelSpin.Value += 10

		end

		UpdateUI:FireClient(player)

		return Enum.ProductPurchaseDecision.PurchaseGranted

	end

	return Enum.ProductPurchaseDecision.NotProcessedYet

end



------------------------------------------



FriendBoostHandler :



local Players = game:GetService("Players")



-- [[ AYARLAR ]] --

local MAX_FRIENDS = 5       -- Maksimum 5 arkadaş

local BOOST_PER_FRIEND = 0.05 -- Kişi başı %5



local function UpdateFriendBoost(player)

	if not player or not player.Parent then return end



	local friendCount = 0



	-- Sunucudaki diğer oyuncuları kontrol et

	for _, otherPlayer in pairs(Players:GetPlayers()) do

		if otherPlayer ~= player then

			local success, isFriend = pcall(function()

				return player:IsFriendsWith(otherPlayer.UserId)

			end)



			if success and isFriend then

				friendCount += 1

			end

		end

	end



	-- Max 5 kişi sınırı

	if friendCount > MAX_FRIENDS then friendCount = MAX_FRIENDS end



	-- Çarpanı Hesapla ve Kaydet

	local multiplier = 1 + (friendCount * BOOST_PER_FRIEND)



	player:SetAttribute("FriendMultiplier", multiplier)

	player:SetAttribute("ActiveFriends", friendCount) -- UI için sayı

end



-- Herkesi Güncelle

local function UpdateEveryone()

	for _, player in pairs(Players:GetPlayers()) do

		task.spawn(function() UpdateFriendBoost(player) end)

	end

end



Players.PlayerAdded:Connect(function(player)

	player:SetAttribute("FriendMultiplier", 1)

	player:SetAttribute("ActiveFriends", 0)

	task.wait(2)

	UpdateEveryone()

end)



Players.PlayerRemoving:Connect(function()

	UpdateEveryone()

end)



---------------------------------------------



EnemyHealthHandler :



local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Workspace = game:GetService("Workspace")



-- [[ MODÜL BAĞLANTISI ]] --

local Modules = ReplicatedStorage:WaitForChild("Modules")

local GameConfig = require(Modules:WaitForChild("GameConfig"))



local EnemiesFolder = Workspace:WaitForChild("Enemies")



-- [[ DÜŞMAN CANINI AYARLAMA ]] --

local function SetupEnemy(enemy, zoneId)

	-- Humanoid'i bekle (Yüklenmesi gecikebilir)

	local humanoid = enemy:WaitForChild("Humanoid", 5)

	if not humanoid then return end



	-- Boss mu Normal mi?

	local isBoss = enemy:FindFirstChild("IsBoss") or string.find(enemy.Name, "Boss") ~= nil



	-- Config'den Can Verisini Çek

	local zoneData = GameConfig.GetZoneInfo(tonumber(zoneId)) -- Sayısal değere çevir

	local targetHP = isBoss and zoneData.BossHP or zoneData.NormalHP



	-- Canı Uygula

	humanoid.MaxHealth = targetHP

	humanoid.Health = targetHP

end



-- [[ KLASÖRLERİ TARA ]] --

local function InitializeEnemies()

	-- Enemies klasörünün içindeki "Enemies-Map1" gibi klasörleri tarar

	for _, mapFolder in pairs(EnemiesFolder:GetChildren()) do



		-- İsimden sadece sayıyı al (Örn: "Enemies-Map3" -> "3")

		local zoneId = string.match(mapFolder.Name, "%d+")



		-- Eğer bir sayı bulduysa ve bu bir klasörse

		if zoneId and (mapFolder:IsA("Folder") or mapFolder:IsA("Model")) then



			-- A) MEVCUT DÜŞMANLARI AYARLA

			for _, enemy in pairs(mapFolder:GetChildren()) do

				if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then

					SetupEnemy(enemy, zoneId)

				end

			end



			-- B) YENİ DOĞANLARI (RESPAWN) DİNLE

			-- Oyun içinde script ile düşman doğuyorsa burası yakalar

			mapFolder.ChildAdded:Connect(function(newEnemy)

				if newEnemy:IsA("Model") then

					task.wait(0.1) -- Humanoid'in yüklenmesi için ufak bekleme

					SetupEnemy(newEnemy, zoneId)

				end

			end)

		end

	end

end



-- Script başladığında çalıştır

task.wait(1) -- Diğer sistemlerin yüklenmesi için güvenli bekleme

InitializeEnemies()



--print("✅ Systems/EnemyHealthHandler: Düşman canları harita numaralarına göre ayarlandı.")



---------------------------------------------------------



EventConfig : 



local EventConfig = {}



-- [[ 🕒 ZAMANLAMA AYARLARI ]]

EventConfig.DungeonStartMinute = 0  

EventConfig.BossStartMinute = 30

EventConfig.JoinDuration = 300  

EventConfig.DungeonDuration = 300 -- 5 Dakika

EventConfig.BossDuration = 300    -- 5 Dakika



-- [[ 🔥 DUNGEON AYARLARI ]]

EventConfig.TotalWaves = 50

EventConfig.WaveMultiplier = 1.2 



-- [[ 👹 BOSS AYARLARI ]]

EventConfig.Bosses = {

	"Bombombini Gusini",

	"Noobini",

	"Tim Cheese",

	"Trippi Troppi",

	"Tung Tung Tung Sahur"

}



EventConfig.MaxBossStrikes = 3 



-- [[ 💰 ÖDÜL KAZANMA ZORLUĞU ]] --

EventConfig.DamageMilestoneStart = 10000 -- İlk ödül 10k hasarda

EventConfig.DamageMilestoneMultiplier = 2.5 -- Sonraki 2.5 katı (10k -> 25k -> 62.5k)



-- [[ 🎁 ÖDÜL HAVUZU (LOOT TABLE) ]] --

EventConfig.BossRewards = {

	{Name = "1,000 Coins", Type = "Coin", Amount = 1000, Chance = 50, Image = "rbxassetid://10619172274"},

	{Name = "5,000 Coins", Type = "Coin", Amount = 5000, Chance = 30, Image = "rbxassetid://10619172274"},

	{Name = "Boss Sword",  Type = "Item", ItemName = "Sword", Chance = 20, Image = "rbxassetid://10619220977"},

}



EventConfig.DungeonRewards = {

	{Name = "500 Coins",   Type = "Coin", Amount = 500, Chance = 60, Image = "rbxassetid://10619172274"},

	{Name = "Mystery Box", Type = "Item", ItemName = "Box", Chance = 40, Image = "rbxassetid://10619220977"},

}



return EventConfig



-----------------------------------------

PetSettings :

local PetSettings = {}

-- [[ 1. RARITY TEMEL IQ DEĞERLERİ ]] --
-- Bu sayılar direkt IQ olarak eklenecek.
PetSettings.RarityMultipliers = {
	["Common"] 		= 3,
	["Rare"] 		= 6,
	["Epic"] 		= 9,
	["Legendary"] 	= 12,
	["Mythic"] 		= 15,
	["Eternal"] 	= 20,
	["Secret"] 		= 45
}

-- [[ 2. TASARIM ]] --
PetSettings.Design = { CornerRadius = 18, StrokeThickness = 2 }

-- [[ 3. RENKLER ]] --
PetSettings.Rarities = {
	["Common"]    = { Fill = Color3.fromHex("373737"), Stroke = Color3.fromHex("7D7A7A"), Order = 1 },
	["Rare"]      = { Fill = Color3.fromHex("254582"), Stroke = Color3.fromHex("4F8AF6"), Order = 2 },
	["Epic"]      = { Fill = Color3.fromHex("3E064C"), Stroke = Color3.fromHex("AB09D3"), Order = 3 },
	["Legendary"] = { Fill = Color3.fromHex("633F05"), Stroke = Color3.fromHex("EA9813"), Order = 4 },
	["Mythic"]    = { Fill = Color3.fromHex("3D093A"), Stroke = Color3.fromHex("F800E7"), Order = 5 },
	["Eternal"]   = { Fill = Color3.fromHex("360806"), Stroke = Color3.fromHex("F6150D"), Order = 6 },
	["Secret"]    = { Fill = Color3.fromHex("191818"), Stroke = Color3.fromHex("000000"), Order = 7 }
}

-- [[ 4. PET LİSTESİ ]] --
PetSettings.Pets = {
	-- [[ MAP 1 ]] --
	["M1_Dog"]        = { Rarity = "Common",    ViewDistance = 6.5 },
	["M1_Cat"]        = { Rarity = "Rare",      ViewDistance = 6.5 }, 
	["M1_Block"]      = { Rarity = "Epic",      ViewDistance = 6.5 }, 
	["M1_Noob"]       = { Rarity = "Legendary", ViewDistance = 6.5 }, 
	["M1_Toucan"]     = { Rarity = "Mythic",    ViewDistance = 6.5 },
	["M1_Sahur"]      = { Rarity = "Eternal",   ViewDistance = 6.0, ViewY = 0.2 },
	["M1_Tim Cheese"] = { Rarity = "Secret",    ViewDistance = 6.0 },

	-- [[ MAP 2 ]] --
	["M2_Sloth"]              = { Rarity = "Common",    ViewDistance = 6.5 },
	["M2_Husky"]              = { Rarity = "Rare",      ViewDistance = 6.5 },
	["M2_Reindeer"]           = { Rarity = "Epic",      ViewDistance = 6.5 },
	["M2_Guest"]              = { Rarity = "Legendary", ViewDistance = 6.5 },
	["M2_King Axolotl"]       = { Rarity = "Mythic",    ViewDistance = 6.5 },
	["M2_Noobini Pizzanini"]  = { Rarity = "Eternal",   ViewDistance = 6.0 },
	["M2_Malame Amarele"]     = { Rarity = "Secret",    ViewDistance = 6.0 },

	-- [[ MAP 3 ]] --
	["M3_Tiger"]            = { Rarity = "Common",    ViewDistance = 6.5 },
	["M3_Moon Dog"]         = { Rarity = "Rare",      ViewDistance = 6.5 },
	["M3_Cyberpunk Dragon"] = { Rarity = "Epic",      ViewDistance = 6.5 },
	["M3_Unicorn"]          = { Rarity = "Legendary", ViewDistance = 6.5 },
	["M3_Lucky Cat"]        = { Rarity = "Mythic",    ViewDistance = 6.5 },
	["M3_Bombicus"]         = { Rarity = "Eternal",   ViewDistance = 7, ViewY = 0.5 },
	["M3_Odin Din Din Dun"] = { Rarity = "Secret",    ViewDistance = 6.0 },

	-- [[ MAP 4 ]] --
	["M4_Alien"]                   = { Rarity = "Common",    ViewDistance = 6.5 },
	["M4_Ghost Dog"]               = { Rarity = "Rare",      ViewDistance = 6.5 },
	["M4_Spider"]                  = { Rarity = "Epic",      ViewDistance = 6.5 },
	["M4_Cow"]                     = { Rarity = "Legendary", ViewDistance = 6.5 },
	["M4_TV"]                      = { Rarity = "Mythic",    ViewDistance = 6.5 },
	["M4_Frogato Pirato"]          = { Rarity = "Eternal",   ViewDistance = 6.0 },
	["M4_Blueberrinni Octopusini"] = { Rarity = "Secret",    ViewDistance = 6.0 },

	-- [[ MAP 5 ]] --
	["M5_Firework"]          = { Rarity = "Common",    ViewDistance = 6.5, ViewY = 0.2 },
	["M5_Cloud Bunny"]       = { Rarity = "Rare",      ViewDistance = 6.5, ViewY = 0.2 },
	["M5_Anime Doggy"]       = { Rarity = "Epic",      ViewDistance = 6.5, ViewY = 0.2 },
	["M5_Puzzle Cube"]       = { Rarity = "Legendary", ViewDistance = 6.5, ViewY = 0.2 },
	["M5_Galaxy Doggy"]      = { Rarity = "Mythic",    ViewDistance = 6.5, ViewY = 0.2 },
	["M5_Bandito Axolito"]   = { Rarity = "Eternal",   ViewDistance = 6.0 },
	["M5_Spioniro Golubiro"] = { Rarity = "Secret",    ViewDistance = 6.0 },
}

-- [[ 5. YUMURTA AYARLARI (TOPLAMA SİSTEMİ) ]] --
-- BaseAdd: O haritadaki tüm petlere eklenecek IQ.
PetSettings.Eggs = {
	["NormalStar1"] = {
		BaseAdd = 0, -- 3 IQ
		Cost = 100,
		Currency = "Coins",
		Pets = {
			{ Name = "M1_Dog",        Chance = 4500 },
			{ Name = "M1_Cat",        Chance = 2500 }, 
			{ Name = "M1_Block",      Chance = 1500 }, 
			{ Name = "M1_Noob",       Chance = 1000 },
			{ Name = "M1_Toucan",     Chance = 450 },
			{ Name = "M1_Sahur",      Chance = 45 },
			{ Name = "M1_Tim Cheese", Chance = 5 }, 
		}
	},
	["NormalStar2"] = {
		BaseAdd = 5, -- 3 + 5 = 8 IQ
		Cost = 500,
		Currency = "Coins",
		Pets = {
			{ Name = "M2_Sloth", Chance = 4500 },
			{ Name = "M2_Husky", Chance = 2500 }, 
			{ Name = "M2_Reindeer", Chance = 1500 }, 
			{ Name = "M2_Guest", Chance = 1000 },
			{ Name = "M2_King Axolotl", Chance = 450 },
			{ Name = "M2_Noobini Pizzanini", Chance = 45 },
			{ Name = "M2_Malame Amarele", Chance = 5 }, 
		}
	},
	["NormalStar3"] = {
		BaseAdd = 16, -- 3 + 16 = 19 IQ
		Cost = 2500,
		Currency = "Coins",
		Pets = {
			{ Name = "M3_Tiger", Chance = 4500 },
			{ Name = "M3_Moon Dog", Chance = 2500 }, 
			{ Name = "M3_Cyberpunk Dragon", Chance = 1500 }, 
			{ Name = "M3_Unicorn", Chance = 1000 },
			{ Name = "M3_Lucky Cat", Chance = 450 },
			{ Name = "M3_Bombicus", Chance = 45 },
			{ Name = "M3_Odin Din Din Dun", Chance = 5 }, 
		}
	},
	["NormalStar4"] = {
		BaseAdd = 44, -- 3 + 44 = 47 IQ
		Cost = 15000,
		Currency = "Coins",
		Pets = {
			{ Name = "M4_Alien", Chance = 4500 },
			{ Name = "M4_Ghost Dog", Chance = 2500 }, 
			{ Name = "M4_Spider", Chance = 1500 }, 
			{ Name = "M4_Cow", Chance = 1000 },
			{ Name = "M4_TV", Chance = 450 },
			{ Name = "M4_Frogato Pirato", Chance = 45 },
			{ Name = "M4_Blueberrinni Octopusini", Chance = 5 }, 
		}
	},
	["NormalStar5"] = {
		BaseAdd = 114, -- 3 + 114 = 117 IQ
		Cost = 100000,
		Currency = "Coins",
		Pets = {
			{ Name = "M5_Firework", Chance = 4500 },
			{ Name = "M5_Cloud Bunny", Chance = 2500 }, 
			{ Name = "M5_Anime Doggy", Chance = 1500 }, 
			{ Name = "M5_Puzzle Cube", Chance = 1000 },
			{ Name = "M5_Galaxy Doggy", Chance = 450 },
			{ Name = "M5_Bandito Axolito", Chance = 45 },
			{ Name = "M5_Spioniro Golubiro", Chance = 5 }, 
		}
	},
}

return PetSettings

--------------------------------------

StarServer : 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local PetSettings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetSettings"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HatchRemote = Remotes:WaitForChild("PetEvents"):WaitForChild("HatchPet")

local DEFAULT_MAX_STORAGE = 50

-- [[ PET SEÇME ]] --
local function choosePet(eggId, player)
	local eggData = PetSettings.Eggs[eggId]
	if not eggData then return nil end

	local luckMulti = 1
	if player:FindFirstChild("HiddenStats") and player.HiddenStats:FindFirstChild("LuckMultiplier") then
		luckMulti = player.HiddenStats.LuckMultiplier.Value
	elseif player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("LuckMultiplier") then
		luckMulti = player.PlayerStats.LuckMultiplier.Value
	end
	if luckMulti < 1 then luckMulti = 1 end

	local tempPets = {}
	local totalPetsCount = #eggData.Pets
	local bonusPoints = math.floor((luckMulti - 1) * 10)
	local totalAdded = 0

	for i, pet in ipairs(eggData.Pets) do
		local calculatedChance = pet.Chance
		if i >= (totalPetsCount - 2) then
			calculatedChance = calculatedChance + bonusPoints
			totalAdded = totalAdded + bonusPoints
		end
		table.insert(tempPets, {Name = pet.Name, Chance = calculatedChance})
	end

	if tempPets[1] then
		tempPets[1].Chance = tempPets[1].Chance - totalAdded
		if tempPets[1].Chance < 0 then tempPets[1].Chance = 0 end
	end

	local totalWeight = 0
	for _, pet in pairs(tempPets) do totalWeight = totalWeight + pet.Chance end
	local randomNum = math.random() * totalWeight 
	local currentWeight = 0
	for _, pet in pairs(tempPets) do
		currentWeight = currentWeight + pet.Chance
		if randomNum <= currentWeight then return pet.Name end
	end
	return nil
end

HatchRemote.OnServerEvent:Connect(function(player, starId, mode, autoDeleteList)
	local eggData = PetSettings.Eggs[starId]
	if not eggData then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	local ownedPets = player:FindFirstChild("OwnedPets")
	local playerStats = player:FindFirstChild("PlayerStats")

	if not leaderstats or not ownedPets then return end

	local amountToHatch = 1
	if mode == "Multi" then
		if playerStats and playerStats:FindFirstChild("MaxHatch") then 
			amountToHatch = playerStats.MaxHatch.Value 
		end
	end

	-- Envanter Kontrolü
	local currentMaxStorage = DEFAULT_MAX_STORAGE
	if playerStats and playerStats:FindFirstChild("MaxStorage") then
		currentMaxStorage = playerStats.MaxStorage.Value
	end
	local currentPetCount = #ownedPets:GetChildren()
	if (currentPetCount + amountToHatch) > currentMaxStorage then
		return 
	end

	local currencyName = eggData.Currency or "Coins"
	local currencyValue = leaderstats:FindFirstChild(currencyName)
	if not currencyValue then return end

	local totalCost = eggData.Cost * amountToHatch
	if currencyValue.Value < totalCost then return end 

	currencyValue.Value = currencyValue.Value - totalCost

	local hatchedPetsList = {}
	local currentMachinePower = 1
	if playerStats and playerStats:FindFirstChild("MachineMultiplier") then
		currentMachinePower = playerStats.MachineMultiplier.Value
	end

	-- [[ YENİ: HARİTA EK GÜCÜ (TOPLAMA) ]] --
	local eggBaseAdd = eggData.BaseAdd or 0

	for i = 1, amountToHatch do
		local petName = choosePet(starId, player)

		if petName then
			local petStats = PetSettings.Pets[petName]
			if petStats then
				local isDeleted = false

				if autoDeleteList and autoDeleteList[petName] == true then
					isDeleted = true
				else
					-- [[ GÜÇ HESAPLAMA: TOPLAMA ]] --
					local rarityValue = PetSettings.RarityMultipliers[petStats.Rarity] or 1

					-- Formül: Rarity IQ + Harita Ekstra IQ
					local finalStrength = rarityValue + eggBaseAdd

					finalStrength = math.floor(finalStrength)

					local newPet = Instance.new("NumberValue")
					newPet.Name = petName
					newPet.Value = finalStrength
					newPet:SetAttribute("PetID", HttpService:GenerateGUID(false))
					newPet:SetAttribute("IsEquipped", false)
					newPet:SetAttribute("Locked", false)
					newPet:SetAttribute("Rarity", petStats.Rarity)
					newPet:SetAttribute("Strength", finalStrength)

					newPet.Parent = ownedPets
				end

				table.insert(hatchedPetsList, {
					Name = petName,
					Deleted = isDeleted
				})
			end
		end
	end

	if #hatchedPetsList > 0 then
		HatchRemote:FireClient(player, hatchedPetsList, currentMachinePower)
	end
end)

----------------------------------------------

InventoryClient :

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local gui = script.Parent
local mainFrame = gui:WaitForChild("MainFrame")
local petScroll = mainFrame:WaitForChild("PetScroll")
local template = petScroll:WaitForChild("Template")
local gridLayout = petScroll:WaitForChild("UIGridLayout")

local CloseButton = mainFrame:WaitForChild("CloseButton")
local MaxInventoryText = mainFrame:WaitForChild("MaxInventoryText")
local MaxPetText = mainFrame:WaitForChild("MaxPetText")

local DEFAULT_MAX_EQUIPPED = 3
local DEFAULT_MAX_STORAGE = 50

local PetSettings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetSettings"))
local Assets = ReplicatedStorage:WaitForChild("Assets")
local petsFolder = Assets:WaitForChild("Pets")

local normalButtonsFrame = mainFrame:WaitForChild("NormalButtons")
local selectButtonsFrame = mainFrame:WaitForChild("SelectionButtons")

local bestButton = normalButtonsFrame:FindFirstChild("BestButton")
local unequipButton = normalButtonsFrame:FindFirstChild("UnequipButton")
local deleteModeButton = normalButtonsFrame:FindFirstChild("DeleteModeButton")
local lockModeButton = normalButtonsFrame:FindFirstChild("LockButton")

local confirmButton = selectButtonsFrame:FindFirstChild("ConfirmButton")
local cancelButton = selectButtonsFrame:FindFirstChild("CancelButton")
local selectAllButton = selectButtonsFrame:FindFirstChild("SelectAllButton")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PetEvents = Remotes:WaitForChild("PetEvents")
local ownedPets = player:WaitForChild("OwnedPets")

local RefreshPetVisuals = PetEvents:WaitForChild("RefreshPetVisuals")
local EquipEvent = PetEvents:WaitForChild("EquipPet")
local GetEquippedPets = PetEvents:WaitForChild("GetEquippedPets")
local DeleteEvent = PetEvents:WaitForChild("DeletePet")

local EquipBestEvent = PetEvents:FindFirstChild("EquipBest")
local UnequipAllEvent = PetEvents:FindFirstChild("UnequipAll")
local LockEvent = PetEvents:FindFirstChild("LockPet")

local petShowFrame = gui:WaitForChild("PetShowFrame")
local infoFrame = petShowFrame:WaitForChild("InfoFrame")
local actionFrame = petShowFrame:WaitForChild("ActionFrame")

local HEADER_HEIGHT = 210
local FULL_HEIGHT = 370
local MENU_WIDTH = 270

local isLockedOpen = false
local currentSelectedPetObject = nil
local equippedPetsList = {}

local isSelectionMode = false
local isLockMode = false
local petsToDelete = {}

template.Visible = false
petShowFrame.Visible = false
petShowFrame.ZIndex = 100
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- [[ UYARI LABEL ]] --
local warningLabel = mainFrame:FindFirstChild("FullWarningLabel")
if not warningLabel then
	warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "FullWarningLabel"
	warningLabel.Parent = mainFrame
	warningLabel.Size = UDim2.new(1, 0, 0.1, 0)
	warningLabel.Position = UDim2.new(0, 0, 1.02, 0)
	warningLabel.BackgroundTransparency = 1
	warningLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	warningLabel.TextStrokeTransparency = 0
	warningLabel.Font = Enum.Font.FredokaOne
	warningLabel.TextSize = 25 
	warningLabel.Text = "INVENTORY FULL!"
	warningLabel.Visible = false
end

-- [[ SAYI KISALTMA FONKSİYONU ]] --
local function AbbreviateNumber(n)
	if n >= 1e12 then return string.format("%.1ft", n / 1e12) end
	if n >= 1e9 then return string.format("%.1fb", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fm", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fk", n / 1e3) end
	return tostring(n)
end

RunService.RenderStepped:Connect(function()
	if petShowFrame.Visible and not isLockedOpen then
		local mousePos = UserInputService:GetMouseLocation()
		petShowFrame.Position = UDim2.fromOffset(mousePos.X + 15, mousePos.Y + 15)
	end
end)

local function GetClientPetMultiplier(petObject)
	if petObject and petObject:IsA("NumberValue") then
		return petObject.Value
	end
	return 1
end

local function Setup3DView(viewFrame, petName)
	if not viewFrame then return end
	viewFrame:ClearAllChildren()
	local realModel = petsFolder:FindFirstChild(petName)
	if not realModel then return end

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(1,0,1,0) 
	viewport.BackgroundTransparency = 1
	viewport.Parent = viewFrame

	local cloneModel = realModel:Clone()
	cloneModel.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 25
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local cf, size
	if cloneModel:IsA("Model") then cf, size = cloneModel:GetBoundingBox()
	elseif cloneModel:IsA("BasePart") then cf = cloneModel.CFrame; size = cloneModel.Size end

	local center = cf.Position
	if cloneModel:IsA("Model") and cloneModel.PrimaryPart then center = cloneModel.PrimaryPart.Position end

	local petData = PetSettings.Pets[petName]
	local customDist = petData and petData.ViewDistance
	local customY = petData and petData.ViewY or 0 

	local distance = customDist or (math.max(size.X, size.Y, size.Z) * 2)
	if distance < 4 then distance = 4 end

	local camPos = center + Vector3.new(distance * 0.8, distance * 0.5, distance)
	local lookAtTarget = center + Vector3.new(0, customY, 0)

	camera.CFrame = CFrame.new(camPos, lookAtTarget)

	task.spawn(function()
		while cloneModel and cloneModel.Parent do
			if cloneModel:IsA("Model") and cloneModel.PrimaryPart then
				cloneModel:SetPrimaryPartCFrame(cloneModel.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
			elseif cloneModel:IsA("BasePart") then
				cloneModel.CFrame = cloneModel.CFrame * CFrame.Angles(0, math.rad(1), 0)
			end
			task.wait(0.02)
		end
	end)
end

local function syncWithServer()
	task.spawn(function()
		local success, serverList = pcall(function() return GetEquippedPets:InvokeServer() end)
		if success and serverList then equippedPetsList = serverList end
	end)
end

local function AnimateMenu(open)
	local targetHeight = open and FULL_HEIGHT or HEADER_HEIGHT
	petShowFrame.Size = UDim2.new(0, MENU_WIDTH, 0, targetHeight)
	isLockedOpen = open
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if isLockedOpen and petShowFrame.Visible then
			local mousePos = UserInputService:GetMouseLocation()
			local menuPos = petShowFrame.AbsolutePosition
			local menuSize = petShowFrame.AbsoluteSize
			local guiInset = GuiService:GetGuiInset()
			local mouseY = mousePos.Y - guiInset.Y
			local mouseX = mousePos.X

			local isInside = mouseX >= menuPos.X and mouseX <= (menuPos.X + menuSize.X)
				and mouseY >= menuPos.Y and mouseY <= (menuPos.Y + menuSize.Y)

			if not isInside then
				isLockedOpen = false
				petShowFrame.Visible = false
				AnimateMenu(false)
			end
		end
	end
end)

local function SetMenuPosition()
	local mousePos = UserInputService:GetMouseLocation()
	petShowFrame.Position = UDim2.fromOffset(mousePos.X + 15, mousePos.Y + 15)
end

local function PopulateInfo(petValue, petName, rarity, strokeColor, isEquipped)
	currentSelectedPetObject = petValue
	if infoFrame:FindFirstChild("PetName") then 
		local cleanName = petName:split("_")[2] or petName
		infoFrame.PetName.Text = cleanName 
		infoFrame.PetName.TextScaled = true 
		infoFrame.PetName.TextWrapped = true
	end
	if infoFrame:FindFirstChild("RarityText") then
		infoFrame.RarityText.Text = rarity
		infoFrame.RarityText.TextColor3 = strokeColor
	end
	if infoFrame:FindFirstChild("PetView") then Setup3DView(infoFrame.PetView, petName) end

	-- [[ DÜZELTME: SADECE SAYI GÖSTERİMİ (1.5k) ]] --
	if actionFrame:FindFirstChild("IQShow") and actionFrame.IQShow:FindFirstChild("IQStatusPet") then
		local multiplier = GetClientPetMultiplier(petValue)
		actionFrame.IQShow.IQStatusPet.Text = AbbreviateNumber(multiplier) -- "+IQ" silindi
	end

	if actionFrame:FindFirstChild("EquipButton") then
		local btn = actionFrame.EquipButton
		btn.BackgroundColor3 = isEquipped and Color3.fromRGB(255, 85, 85) or Color3.fromRGB(85, 255, 127)
		local btnLabel = btn:FindFirstChildOfClass("TextLabel")
		if btnLabel then btnLabel.Text = isEquipped and "UNEQUIP" or "EQUIP" end
	end
end

local function UpdateInventory()
	syncWithServer()

	local petTable = ownedPets:GetChildren()

	table.sort(petTable, function(a, b)
		local iqA = GetClientPetMultiplier(a)
		local iqB = GetClientPetMultiplier(b)
		return iqA > iqB
	end)

	local playerStats = player:FindFirstChild("PlayerStats")
	local maxEquip = playerStats and playerStats:FindFirstChild("MaxEquipped") and playerStats.MaxEquipped.Value or DEFAULT_MAX_EQUIPPED
	local maxStore = playerStats and playerStats:FindFirstChild("MaxStorage") and playerStats.MaxStorage.Value or DEFAULT_MAX_STORAGE

	if MaxPetText then MaxPetText.Text = #equippedPetsList .. " / " .. maxEquip end
	if MaxInventoryText then MaxInventoryText.Text = #petTable .. " / " .. maxStore end

	if warningLabel then
		if #petTable >= maxStore then
			warningLabel.Visible = true
			if MaxInventoryText then MaxInventoryText.TextColor3 = Color3.fromRGB(255, 50, 50) end
		else
			warningLabel.Visible = false
			if MaxInventoryText then MaxInventoryText.TextColor3 = Color3.fromRGB(255, 255, 255) end
		end
	end

	local existingFrames = {}
	for _, child in pairs(petScroll:GetChildren()) do
		if child:IsA("ImageButton") and child ~= template then
			if child:FindFirstChild("RealPetObject") then
				existingFrames[child.RealPetObject.Value] = child
			else
				child:Destroy()
			end
		end
	end

	for index, petValue in ipairs(petTable) do
		local card = existingFrames[petValue]
		local isNewCard = false

		if not card then
			isNewCard = true
			card = template:Clone()
			card.Parent = petScroll
			card.Visible = true

			local ref = Instance.new("ObjectValue", card)
			ref.Name = "RealPetObject"
			ref.Value = petValue
			card.BorderSizePixel = 0 
		end

		existingFrames[petValue] = nil
		card.LayoutOrder = index
		card.Name = petValue.Name

		local petName = petValue.Name
		local settingsData = PetSettings.Pets[petName]
		local rarity = settingsData and settingsData.Rarity or "Common"
		local isLocked = petValue:GetAttribute("Locked") == true 
		local rarityInfo = PetSettings.Rarities[rarity]
		local fillColor = rarityInfo.Fill or Color3.fromRGB(50,50,50)
		local strokeColor = rarityInfo.Stroke or Color3.fromRGB(255,255,255)

		local isEquipped = false
		for _, equippedPet in pairs(equippedPetsList) do if equippedPet == petValue then isEquipped = true break end end

		local isSelectedToDelete = false
		if isSelectionMode and table.find(petsToDelete, petValue) then isSelectedToDelete = true end

		local targetColor = isSelectedToDelete and Color3.fromRGB(255, 100, 100) or strokeColor
		local targetFill = isSelectedToDelete and Color3.fromRGB(100, 0, 0) or fillColor

		if card.ImageColor3 ~= targetColor then
			card.ImageColor3 = targetColor
			card.BackgroundColor3 = targetFill
		end

		local uiStroke = card:FindFirstChild("UIStroke")
		if not uiStroke then
			uiStroke = Instance.new("UIStroke")
			uiStroke.Name = "UIStroke"
			uiStroke.Parent = card
			uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
		end

		uiStroke.Thickness = PetSettings.Design.StrokeThickness
		uiStroke.Color = targetColor

		if card:FindFirstChild("EquippedIcon") then card.EquippedIcon.Visible = isEquipped end
		if card:FindFirstChild("LockIcon") then card.LockIcon.Visible = isLocked end
		if card:FindFirstChild("DeleteIcon") then card.DeleteIcon.Visible = isSelectedToDelete end

		if isNewCard then
			if card:FindFirstChild("PetName") then 
				local cleanName = petName:split("_")[2] or petName
				card.PetName.Text = cleanName
				card.PetName.TextColor3 = Color3.new(1, 1, 1) 
				card.PetName.TextScaled = true 
				card.PetName.TextWrapped = true

				if not card.PetName:FindFirstChild("UIStroke") then
					local s = Instance.new("UIStroke")
					s.Parent = card.PetName
					s.Color = Color3.new(0, 0, 0); s.Thickness = 2
				end
			end
			if card:FindFirstChild("PetView") then Setup3DView(card.PetView, petName) end
		end

		if isNewCard then
			card.MouseButton1Click:Connect(function()
				if isSelectionMode then
					if isEquipped then return end
					if isLocked then return end

					if table.find(petsToDelete, petValue) then
						for i, v in pairs(petsToDelete) do if v == petValue then table.remove(petsToDelete, i) break end end
					else
						table.insert(petsToDelete, petValue)
					end
					UpdateInventory()
				elseif isLockMode then
					if LockEvent then
						LockEvent:FireServer(petValue)
						task.wait(0.05); UpdateInventory()
					end
				else
					if isLockedOpen and currentSelectedPetObject == petValue then
						AnimateMenu(false); task.wait(0.1); petShowFrame.Visible = false; isLockedOpen = false
					else
						PopulateInfo(petValue, petName, rarity, strokeColor, isEquipped)
						SetMenuPosition()
						isLockedOpen = true
						petShowFrame.Visible = true
						AnimateMenu(true)
					end
				end
			end)

			card.MouseEnter:Connect(function()
				if isSelectionMode or isLockMode then return end
				if not isLockedOpen then
					PopulateInfo(petValue, petName, rarity, strokeColor, isEquipped)
					SetMenuPosition()
					petShowFrame.Visible = true
					petShowFrame.Size = UDim2.new(0, MENU_WIDTH, 0, HEADER_HEIGHT)
				end
			end)

			card.MouseLeave:Connect(function() 
				if not isLockedOpen then petShowFrame.Visible = false end 
			end)
		end
	end

	for _, leftovers in pairs(existingFrames) do
		leftovers:Destroy()
	end
end

if bestButton then 
	bestButton.MouseButton1Click:Connect(function() 
		if EquipBestEvent then EquipBestEvent:FireServer(); task.wait(0.2); UpdateInventory() end 
	end) 
end
if unequipButton then 
	unequipButton.MouseButton1Click:Connect(function() 
		if UnequipAllEvent then UnequipAllEvent:FireServer(); task.wait(0.2); UpdateInventory() end 
	end) 
end
if lockModeButton then
	lockModeButton.MouseButton1Click:Connect(function()
		isLockMode = not isLockMode
		lockModeButton.BackgroundColor3 = isLockMode and Color3.fromRGB(85, 255, 127) or Color3.fromRGB(45, 45, 45)
		isSelectionMode = false; normalButtonsFrame.Visible = true; selectButtonsFrame.Visible = false; UpdateInventory()
	end)
end
if deleteModeButton then
	deleteModeButton.MouseButton1Click:Connect(function()
		isSelectionMode = true; isLockMode = false; lockModeButton.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		petsToDelete = {}; normalButtonsFrame.Visible = false; selectButtonsFrame.Visible = true; UpdateInventory()
	end)
end
if cancelButton then
	cancelButton.MouseButton1Click:Connect(function()
		isSelectionMode = false; petsToDelete = {}; normalButtonsFrame.Visible = true; selectButtonsFrame.Visible = false; UpdateInventory()
	end)
end
if confirmButton then
	confirmButton.MouseButton1Click:Connect(function()
		if #petsToDelete > 0 then
			DeleteEvent:FireServer(petsToDelete)
			isSelectionMode = false; petsToDelete = {}; normalButtonsFrame.Visible = true; selectButtonsFrame.Visible = false
			task.wait(0.5); UpdateInventory()
		end
	end)
end
if selectAllButton then
	selectAllButton.MouseButton1Click:Connect(function()
		petsToDelete = {}
		for _, pet in pairs(ownedPets:GetChildren()) do
			local isEq = false; for _, p in pairs(equippedPetsList) do if p == pet then isEq = true break end end
			local isLocked = pet:GetAttribute("Locked") == true
			if not isEq and not isLocked then table.insert(petsToDelete, pet) end
		end
		UpdateInventory()
	end)
end

if actionFrame:FindFirstChild("EquipButton") then
	actionFrame.EquipButton.MouseButton1Click:Connect(function()
		if currentSelectedPetObject then 
			EquipEvent:FireServer(currentSelectedPetObject.Name, currentSelectedPetObject)
			task.wait(0.1)
			AnimateMenu(false); petShowFrame.Visible = false; isLockedOpen = false; UpdateInventory() 
		end
	end)
end
if actionFrame:FindFirstChild("CloseButton") then
	actionFrame.CloseButton.MouseButton1Click:Connect(function() 
		AnimateMenu(false); task.wait(0.1); petShowFrame.Visible = false; isLockedOpen = false
	end)
end

if infoFrame:FindFirstChild("DeleteIcon") then
	infoFrame.DeleteIcon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and currentSelectedPetObject then
			DeleteEvent:FireServer(currentSelectedPetObject)
			AnimateMenu(false); petShowFrame.Visible = false; isLockedOpen = false
			task.wait(0.2); UpdateInventory()
		end
	end)
end

if infoFrame:FindFirstChild("LockIcon") then
	infoFrame.LockIcon.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and currentSelectedPetObject then
			LockEvent:FireServer(currentSelectedPetObject)
			task.wait(0.1); UpdateInventory()
		end
	end)
end

if CloseButton then
	CloseButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		petShowFrame.Visible = false
		isLockedOpen = false
	end)
end

for _, child in pairs(petScroll:GetChildren()) do
	if child:IsA("ImageButton") and child ~= template then child:Destroy() end
end

RefreshPetVisuals.OnClientEvent:Connect(UpdateInventory)
ownedPets.ChildAdded:Connect(UpdateInventory)
ownedPets.ChildRemoved:Connect(UpdateInventory)
ownedPets.AttributeChanged:Connect(UpdateInventory)

task.wait(1)
UpdateInventory()

------------------------------------

PetClient :

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- [[ 1. AYARLAR ]] --
local PetSettings = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PetSettings"))
local Assets = ReplicatedStorage:WaitForChild("Assets")
local petsFolder = Assets:WaitForChild("Pets")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local HatchRemote = Remotes:WaitForChild("PetEvents"):WaitForChild("HatchPet")

-- [[ 2. STAT TAKİBİ ]] --
local playerStats = player:WaitForChild("PlayerStats")
local maxHatchVal = playerStats:WaitForChild("MaxHatch")

-- [[ 3. UI TANIMLAMALARI ]] --
local ScreenGui = script.Parent
local MainFrame = ScreenGui:WaitForChild("MainFrame")
local Container = MainFrame:WaitForChild("PetContainer")
local TitleBar = MainFrame:WaitForChild("TitleBar")
local PriceLabel = TitleBar:WaitForChild("TextLabel")

local BtnContainer = MainFrame:WaitForChild("ButtonsContainer")
local BtnMulti = BtnContainer:WaitForChild("BtnMulti")
local BtnSingle = BtnContainer:WaitForChild("BtnSingle")
local BtnAuto = BtnContainer:WaitForChild("BtnAuto")
local CloseButton = MainFrame:FindFirstChild("CloseButton")

local autoDeleteList = {}
local currentStarId = nil
local currentMachineObject = nil 
local currentPrompt = nil 
local isAutoHatching = false
local db = false
local MAX_DISTANCE = 50 
local lastMenuOpenTime = 0 

local function AbbreviateNumber(n)
	if n >= 1e15 then return string.format("%.1fQ", n / 1e15) end
	if n >= 1e12 then return string.format("%.1fT", n / 1e12) end
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(n)
end

-- [[ LUCK İLE HESAPLANMIŞ LİSTEYİ DÖNDÜRÜR ]] --
local function GetAdjustedChances(starId)
	local eggData = PetSettings.Eggs[starId]
	if not eggData then return {} end

	local luckMulti = 1
	local hiddenStats = player:FindFirstChild("HiddenStats")
	if hiddenStats and hiddenStats:FindFirstChild("LuckMultiplier") then
		luckMulti = hiddenStats.LuckMultiplier.Value
	elseif player:FindFirstChild("PlayerStats") and player.PlayerStats:FindFirstChild("LuckMultiplier") then
		luckMulti = player.PlayerStats.LuckMultiplier.Value
	end
	if luckMulti < 1 then luckMulti = 1 end

	local calculatedPets = {}
	local totalPetsCount = #eggData.Pets
	local bonusPoints = math.floor((luckMulti - 1) * 10)
	local totalAdded = 0

	for i, pet in ipairs(eggData.Pets) do
		local baseChance = pet.Chance
		local newChance = baseChance
		if i >= (totalPetsCount - 2) then
			newChance = newChance + bonusPoints
			totalAdded = totalAdded + bonusPoints
		end
		local rarity = "Common"
		if PetSettings.Pets[pet.Name] then rarity = PetSettings.Pets[pet.Name].Rarity end

		table.insert(calculatedPets, {
			Name = pet.Name, 
			BaseChance = baseChance, 
			FinalChance = newChance, 
			Rarity = rarity
		})
	end

	if calculatedPets[1] then
		calculatedPets[1].FinalChance = calculatedPets[1].FinalChance - totalAdded
		if calculatedPets[1].FinalChance < 0 then calculatedPets[1].FinalChance = 0 end
	end
	return calculatedPets
end

-- [[ GRID AYARI ]] --
local function updateGridLayout()
	local grid = Container:FindFirstChild("UIGridLayout") or Instance.new("UIGridLayout", Container)
	grid.CellSize = UDim2.new(0, 100, 0, 130) 
	grid.CellPadding = UDim2.new(0, 25, 0, 25) 
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.VerticalAlignment = Enum.VerticalAlignment.Center
end

-- [[ MAX HATCH BUTONU ]] --
local function updateMultiButton()
	local amount = maxHatchVal.Value
	local textString = tostring(amount) .. "x (R)"
	local label = nil
	for _, child in pairs(BtnMulti:GetChildren()) do
		if child:IsA("TextLabel") then label = child break end
	end
	if not label then
		label = Instance.new("TextLabel", BtnMulti)
		label.Name = "TextLabel"
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1,1,1)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextStrokeTransparency = 0
	end
	label.Text = textString
end
maxHatchVal.Changed:Connect(updateMultiButton)
task.spawn(updateMultiButton)

-- [[ 3D MODEL ]] --
local function Setup3DView(parentFrame, petName)
	if parentFrame:FindFirstChild("ViewportFrame") then parentFrame.ViewportFrame:Destroy() end
	local realModel = petsFolder:FindFirstChild(petName)
	if not realModel then return end

	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0.85, 0, 0.75, 0)
	viewport.Position = UDim2.new(0.075, 0, 0, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parentFrame

	local cloneModel = realModel:Clone()
	cloneModel.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 25
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local cf, size
	if cloneModel:IsA("Model") then
		cf, size = cloneModel:GetBoundingBox()
	elseif cloneModel:IsA("BasePart") then
		cf = cloneModel.CFrame
		size = cloneModel.Size
	end

	local center = cf.Position
	if cloneModel:IsA("Model") and cloneModel.PrimaryPart then
		center = cloneModel.PrimaryPart.Position
	end

	local petData = PetSettings.Pets[petName]
	local customDist = petData and petData.ViewDistance
	local customY = petData and petData.ViewY or 0

	local distance = 6 

	if customDist then
		distance = customDist
	else
		local maxDim = math.max(size.X, size.Y, size.Z)
		distance = maxDim * 2
		if distance < 4 then distance = 4 end
	end

	local camPos = center + Vector3.new(distance * 0.8, distance * 0.5, distance)
	local lookAtTarget = center + Vector3.new(0, customY, 0)

	camera.CFrame = CFrame.new(camPos, lookAtTarget)

	task.spawn(function()
		while cloneModel and cloneModel.Parent do
			if cloneModel:IsA("Model") and cloneModel.PrimaryPart then
				cloneModel:SetPrimaryPartCFrame(cloneModel.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
			elseif cloneModel:IsA("BasePart") then
				cloneModel.CFrame = cloneModel.CFrame * CFrame.Angles(0, math.rad(1), 0)
			end
			task.wait(0.02)
		end
	end)
end

-- [[ KART OLUŞTURMA ]] --
local function clearContainer()
	for _, child in pairs(Container:GetChildren()) do
		if child:IsA("ImageButton") or child:IsA("Frame") then child:Destroy() end
	end
end

local function createPetCard(petData, index)
	local rarityInfo = PetSettings.Rarities[petData.Rarity]

	local card = Instance.new("ImageButton")
	card.Name = petData.Name
	card.BackgroundColor3 = rarityInfo.Fill
	card.AutoButtonColor = false
	card.LayoutOrder = index
	card.Parent = Container

	local uiCorner = Instance.new("UICorner", card)
	uiCorner.CornerRadius = UDim.new(0, PetSettings.Design.CornerRadius)
	local uiStroke = Instance.new("UIStroke", card)
	uiStroke.Color = rarityInfo.Stroke
	uiStroke.Thickness = PetSettings.Design.StrokeThickness
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	Setup3DView(card, petData.Name)

	local xMark = Instance.new("ImageLabel", card)
	xMark.Name = "DeleteMark"
	xMark.AnchorPoint = Vector2.new(0.5, 0.5)
	xMark.Position = UDim2.new(0.5, 0, 0.5, 0)
	xMark.Size = UDim2.new(0.6, 0, 0.6, 0)
	xMark.BackgroundTransparency = 1
	xMark.Image = "rbxassetid://89944452989174"
	xMark.ImageColor3 = Color3.fromRGB(255, 50, 50)
	xMark.ZIndex = 20
	xMark.Visible = false
	if autoDeleteList[petData.Name] then xMark.Visible = true end

	local infoLabel = Instance.new("TextLabel", card)
	infoLabel.Size = UDim2.new(1, 0, 0.25, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.75, 0)
	infoLabel.BackgroundTransparency = 1

	-- [[ DÜZELTME: SADECE Rarity İSMİ ]] --
	local cleanName = petData.Name:split("_")[2] or petData.Name
	infoLabel.Text = cleanName .. "\n" .. petData.Rarity -- Sadece isim ve nadirlik
	infoLabel.TextColor3 = Color3.new(1, 1, 1) -- Her zaman beyaz

	infoLabel.Font = Enum.Font.FredokaOne
	infoLabel.TextScaled = true
	infoLabel.ZIndex = 6

	card.MouseButton1Click:Connect(function()
		if autoDeleteList[petData.Name] then
			autoDeleteList[petData.Name] = nil
			xMark.Visible = false; card.Transparency = 0
		else
			autoDeleteList[petData.Name] = true
			xMark.Visible = true; card.Transparency = 0.5
		end
	end)
end

-- [[ MENÜ MANTIĞI ]] --
local function closeMenu()
	MainFrame.Visible = false
	currentStarId = nil
	currentMachineObject = nil
	isAutoHatching = false
	local autoLabel = nil
	for _, child in pairs(BtnAuto:GetChildren()) do if child:IsA("TextLabel") then autoLabel = child break end end
	if autoLabel then autoLabel.Text = "Auto (T)" elseif BtnAuto:IsA("TextButton") then BtnAuto.Text = "Auto (T)" end
	BtnAuto.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	if currentPrompt then currentPrompt.Enabled = true; currentPrompt = nil end
end

local function openStarMenu(starId, machineObj)
	if MainFrame.Visible and currentMachineObject == machineObj then return end
	local starData = PetSettings.Eggs[starId]
	if not starData then return end
	currentStarId = starId
	currentMachineObject = machineObj
	lastMenuOpenTime = tick()

	local prompt = machineObj:FindFirstChild("ProximityPrompt", true)
	if prompt then currentPrompt = prompt; prompt.Enabled = false end

	MainFrame.Visible = true
	PriceLabel.Text = AbbreviateNumber(starData.Cost)

	clearContainer()
	updateGridLayout()

	local adjustedPets = GetAdjustedChances(starId)

	table.sort(adjustedPets, function(a, b)
		local petA = PetSettings.Pets[a.Name]
		local petB = PetSettings.Pets[b.Name]
		local rA = PetSettings.Rarities[petA.Rarity]
		local rB = PetSettings.Rarities[petB.Rarity]
		return rA.Order < rB.Order
	end)

	for i, p in pairs(adjustedPets) do
		createPetCard(p, i)
	end
	updateMultiButton()
end

RunService.RenderStepped:Connect(function()
	if MainFrame.Visible and currentMachineObject then
		local targetPos = nil
		if currentMachineObject:IsA("Model") then targetPos = currentMachineObject:GetPivot().Position
		elseif currentMachineObject:IsA("BasePart") then targetPos = currentMachineObject.Position end
		if targetPos and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local distance = (player.Character.HumanoidRootPart.Position - targetPos).Magnitude
			if distance > MAX_DISTANCE then closeMenu() end
		end
	end
end)

local function hatchRequest(mode)
	if not currentStarId then return end
	if db then return end 
	db = true 
	local power = currentMachineObject:GetAttribute("MachinePower") or 1
	HatchRemote:FireServer(currentStarId, mode, autoDeleteList)
	task.wait(4.5) 
	db = false 
end

local function toggleAutoHatch()
	isAutoHatching = not isAutoHatching
	local autoLabel = nil
	for _, child in pairs(BtnAuto:GetChildren()) do if child:IsA("TextLabel") then autoLabel = child break end end
	if isAutoHatching then
		if autoLabel then autoLabel.Text = "STOP" elseif BtnAuto:IsA("TextButton") then BtnAuto.Text = "STOP" end
		BtnAuto.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		task.spawn(function()
			while isAutoHatching and MainFrame.Visible do hatchRequest("Multi"); task.wait(0.5) end
			isAutoHatching = false
			if autoLabel then autoLabel.Text = "Auto (T)" elseif BtnAuto:IsA("TextButton") then BtnAuto.Text = "Auto (T)" end
			BtnAuto.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		end)
	else
		if autoLabel then autoLabel.Text = "Auto (T)" elseif BtnAuto:IsA("TextButton") then BtnAuto.Text = "Auto (T)" end
		BtnAuto.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end

BtnSingle.MouseButton1Click:Connect(function() isAutoHatching = false; hatchRequest("Single") end)
BtnMulti.MouseButton1Click:Connect(function() isAutoHatching = false; hatchRequest("Multi") end)
BtnAuto.MouseButton1Click:Connect(toggleAutoHatch)
if CloseButton then CloseButton.MouseButton1Click:Connect(closeMenu) end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not MainFrame.Visible then return end
	local isTyping = UserInputService:GetFocusedTextBox() ~= nil
	if isTyping then return end
	if input.KeyCode == Enum.KeyCode.E then if tick() - lastMenuOpenTime > 0.5 then isAutoHatching = false; hatchRequest("Single") end
	elseif input.KeyCode == Enum.KeyCode.R then isAutoHatching = false; hatchRequest("Multi")
	elseif input.KeyCode == Enum.KeyCode.T then toggleAutoHatch() end
end)

local StarFolder = workspace:WaitForChild("StarCapsules")
local function setupMachine(machine)
	local prompt = machine:FindFirstChild("ProximityPrompt", true) 
	if prompt then
		prompt.Triggered:Connect(function()
			local starId = machine:GetAttribute("StarId")
			if not starId then warn("❌ HATA: StarId yok") return end
			openStarMenu(starId, machine)
		end)
	end
end
for _, child in pairs(StarFolder:GetChildren()) do setupMachine(child) end
StarFolder.ChildAdded:Connect(setupMachine)

----------------------------------

AdminManager :

-- ServerScriptService/Systems/AdminManager.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MessagingService = game:GetService("MessagingService")

local DataKeyManager = require(ServerScriptService:WaitForChild("Systems"):WaitForChild("DataKeyManager"))
local DataStoreService = game:GetService("DataStoreService")
local MyDataStore = DataStoreService:GetDataStore(DataKeyManager.MAIN_KEY)
local EventDataStore = DataStoreService:GetDataStore("GlobalEventData_V3")

local Admins = {
	["ChrolloLucifer"] = true,
	["CavusAlah"] = true,
}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name = "Remotes"

local AdminEvent = Remotes:FindFirstChild("AdminEvent") or Instance.new("RemoteEvent", Remotes)
AdminEvent.Name = "AdminEvent"

local EventNotification = Remotes:FindFirstChild("EventNotification") or Instance.new("RemoteEvent", Remotes)
EventNotification.Name = "EventNotification"

local EventVFXTrigger = Remotes:FindFirstChild("EventVFXTrigger") or Instance.new("RemoteEvent", Remotes)
EventVFXTrigger.Name = "EventVFXTrigger"

local DrinkPotionEvent = Remotes:FindFirstChild("DrinkPotionEvent") 
if not DrinkPotionEvent then
	DrinkPotionEvent = Instance.new("RemoteEvent", Remotes)
	DrinkPotionEvent.Name = "DrinkPotionEvent"
end

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))

local POTION_TYPES = {"IQ", "Damage", "Coins", "Essence", "Aura", "Luck", "Speed"}
local POTION_SIZES = {"Small", "Medium", "Big"}

-- ADMIN CHECK
AdminEvent.OnServerInvoke = function(player)
	return Admins[player.Name] == true
end

-- EVENT SYSTEM
local ActiveEvent = nil
local EventConfig = {
	["2xIQ"] = {Name = "2x IQ Boost", Duration = 1800, AttributeName = "EventIQBonus", Multiplier = 1.5, Icon = "🧠", Color = Color3.fromRGB(100, 150, 255)},
	["2xCoins"] = {Name = "2x Coins Boost", Duration = 1800, AttributeName = "EventCoinsBonus", Multiplier = 1.5, Icon = "💰", Color = Color3.fromRGB(255, 215, 0)},
	["LuckyHour"] = {Name = "Lucky Hour", Duration = 3600, AttributeName = "EventLuckBonus", Additive = 0.1, Icon = "🍀", Color = Color3.fromRGB(0, 255, 150)},
	["SpeedFrenzy"] = {Name = "Speed Frenzy", Duration = 900, AttributeName = "EventSpeedBonus", Multiplier = 1.5, Icon = "⚡", Color = Color3.fromRGB(0, 255, 255)},
	["GoldenRush"] = {Name = "Golden Rush", Duration = 600, AttributeName = "EventCoinsBonus", Multiplier = 1.5, Icon = "💸", Color = Color3.fromRGB(255, 200, 50)},
	["RainbowStars"] = {Name = "Rainbow Stars", Duration = 1800, AttributeName = "EventAllBonus", Multiplier = 1.25, Icon = "🌈", Color = Color3.fromRGB(255, 100, 255)},
	["EssenceRain"] = {Name = "Essence Rain", Duration = 600, AttributeName = "EventEssenceBonus", Multiplier = 1.5, Icon = "✨", Color = Color3.fromRGB(180, 100, 255)}
}

local function GetGlobalEvent() local success, data = pcall(function() return EventDataStore:GetAsync("CurrentEvent") end); return success and data or nil end
local function SetGlobalEvent(eventType, startTime, duration) pcall(function() EventDataStore:SetAsync("CurrentEvent", {EventType = eventType, StartTime = startTime, Duration = duration}) end) end
local function ClearGlobalEvent() pcall(function() EventDataStore:RemoveAsync("CurrentEvent") end) end

local function ApplyEventToPlayer(player, eventType)
	local config = EventConfig[eventType]; if not config then return end
	if config.Multiplier then player:SetAttribute(config.AttributeName, config.Multiplier)
	elseif config.Additive then local hidden = player:FindFirstChild("HiddenStats"); if hidden and hidden:FindFirstChild("LuckMultiplier") then hidden.LuckMultiplier.Value = hidden.LuckMultiplier.Value + config.Additive end end
	if eventType == "SpeedFrenzy" then GameConfig.UpdateWalkSpeed(player) end
end

local function RemoveEventFromPlayer(player, eventType)
	local config = EventConfig[eventType]; if not config then return end
	if config.Multiplier then player:SetAttribute(config.AttributeName, nil)
	elseif config.Additive then local hidden = player:FindFirstChild("HiddenStats"); if hidden and hidden:FindFirstChild("LuckMultiplier") then hidden.LuckMultiplier.Value = math.max(1.0, hidden.LuckMultiplier.Value - config.Additive) end end
	if eventType == "SpeedFrenzy" then GameConfig.UpdateWalkSpeed(player) end
end

local function StartEvent(eventType)
	if ActiveEvent then StopEvent(ActiveEvent.EventType, true) end
	local config = EventConfig[eventType]; if not config then return end
	local startTime = tick()
	SetGlobalEvent(eventType, startTime, config.Duration)
	for _, player in pairs(Players:GetPlayers()) do ApplyEventToPlayer(player, eventType) end
	EventNotification:FireAllClients("Start", {EventType = eventType, Name = config.Name, Duration = config.Duration, Icon = config.Icon, Color = config.Color})
	EventVFXTrigger:FireAllClients("Start", eventType)
	pcall(function() MessagingService:PublishAsync("GlobalEventStart", {EventType = eventType, StartTime = startTime, Duration = config.Duration}) end)
	ActiveEvent = {EventType = eventType, StartTime = startTime, Duration = config.Duration, Config = config}
	task.spawn(function() task.wait(config.Duration); StopEvent(eventType) end)
end

function StopEvent(eventType, silent)
	if not ActiveEvent or ActiveEvent.EventType ~= eventType then return end
	for _, player in pairs(Players:GetPlayers()) do RemoveEventFromPlayer(player, eventType) end
	if not silent then EventNotification:FireAllClients("End", {EventType = eventType, Name = ActiveEvent.Config.Name}) end
	EventVFXTrigger:FireAllClients("Stop", eventType)
	ClearGlobalEvent()
	pcall(function() MessagingService:PublishAsync("GlobalEventStop", {EventType = eventType}) end)
	ActiveEvent = nil
end

pcall(function()
	MessagingService:SubscribeAsync("GlobalEventStart", function(message) local data = message.Data; local remaining = data.Duration - (tick() - data.StartTime); if remaining > 0 then local config = EventConfig[data.EventType]; if config then ActiveEvent = {EventType = data.EventType, StartTime = data.StartTime, Duration = data.Duration, Config = config}; for _, player in pairs(Players:GetPlayers()) do ApplyEventToPlayer(player, data.EventType) end; EventNotification:FireAllClients("Start", {EventType = data.EventType, Name = config.Name, Duration = remaining, Icon = config.Icon, Color = config.Color}); task.spawn(function() task.wait(remaining); StopEvent(data.EventType) end) end end end)
	MessagingService:SubscribeAsync("GlobalEventStop", function(message) if ActiveEvent and ActiveEvent.EventType == message.Data.EventType then StopEvent(message.Data.EventType, true) end end)
	MessagingService:SubscribeAsync("GlobalAnnouncement", function(message) EventNotification:FireAllClients("Announcement", {Message = message.Data.Message, AdminName = message.Data.AdminName}) end)
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	local globalEvent = GetGlobalEvent()
	if globalEvent then local remaining = globalEvent.Duration - (tick() - globalEvent.StartTime); if remaining > 0 then ApplyEventToPlayer(player, globalEvent.EventType); local config = EventConfig[globalEvent.EventType]; if config then EventNotification:FireClient(player, "Start", {EventType = globalEvent.EventType, Name = config.Name, Duration = remaining, Icon = config.Icon, Color = config.Color}) end end end
end)

local function ResetPlayerData(playerId) pcall(function() MyDataStore:RemoveAsync("Player_" .. playerId) end) end

local function GivePotionToPlayer(player, potionName, amount)
	if not player or not player.Parent then return false end
	local potionInv = player:FindFirstChild("PotionInventory") or Instance.new("Folder", player); potionInv.Name = "PotionInventory"
	local potionVal = potionInv:FindFirstChild(potionName) or Instance.new("IntValue", potionInv); potionVal.Name = potionName
	potionVal.Value = potionVal.Value + (amount or 1); return true
end

AdminEvent.OnServerEvent:Connect(function(admin, category, action, data)
	if not Admins[admin.Name] then return end
	if category == "Event" then if action == "Stop" then if ActiveEvent then StopEvent(ActiveEvent.EventType) end else StartEvent(action) end; return end
	if category == "Announcement" then EventNotification:FireAllClients("Announcement", {Message = data.Message, AdminName = admin.Name}); pcall(function() MessagingService:PublishAsync("GlobalAnnouncement", {Message = data.Message, AdminName = admin.Name}) end); return end
	local targetPlayer, targetId = nil, nil
	if data.Target and data.Target ~= "" then for _, p in pairs(Players:GetPlayers()) do if string.lower(p.Name):sub(1, #data.Target) == string.lower(data.Target) then targetPlayer = p; targetId = p.UserId; break end end; if not targetPlayer and tonumber(data.Target) then targetId = tonumber(data.Target) end else targetPlayer = admin; targetId = admin.UserId end
	if not targetId then return end
	if action == "GiveRotSkill" then local mapID, skillIndex = tonumber(data.MapID), tonumber(data.SkillIndex); if not mapID or not skillIndex then return end; if targetPlayer then local ls = targetPlayer:FindFirstChild("leaderstats"); if ls then local obj = ls:FindFirstChild("EquippedSkill" .. (mapID == 1 and "" or tostring(mapID))); if obj then obj.Value = skillIndex end end else pcall(function() MyDataStore:UpdateAsync("Player_" .. targetId, function(old) old = old or {}; old["EquippedSkill" .. (mapID == 1 and "" or tostring(mapID))] = skillIndex; return old end) end) end
	elseif action == "GiveRotSkillToken" then local mapID, amount = tonumber(data.MapID), tonumber(data.Amount) or 1; if not mapID then return end; local mapConfig = GameConfig.MapRotSkills[mapID]; if not mapConfig then return end; local tokenName = mapConfig.TokenName; if targetPlayer then local ls = targetPlayer:FindFirstChild("leaderstats"); if ls then local obj = ls:FindFirstChild(tokenName) or Instance.new("IntValue", ls); obj.Name = tokenName; obj.Value = obj.Value + amount end else pcall(function() MyDataStore:UpdateAsync("Player_" .. targetId, function(old) old = old or {}; old[tokenName] = (old[tokenName] or 0) + amount; return old end) end) end
	elseif action == "AddStat" then local stat, amount = data.Stat, tonumber(data.Amount) or 1; if targetPlayer then local ps, ls, hs = targetPlayer:FindFirstChild("PlayerStats"), targetPlayer:FindFirstChild("leaderstats"), targetPlayer:FindFirstChild("HiddenStats"); if stat == "Aura" and hs then local a = hs:FindFirstChild("Aura") or Instance.new("IntValue", hs); a.Name = "Aura"; a.Value = a.Value + amount elseif stat == "MaxHatch" and ps then local m = ps:FindFirstChild("MaxHatch") or Instance.new("IntValue", ps); m.Name = "MaxHatch"; m.Value = m.Value + amount elseif stat == "Luck" and hs then local l = hs:FindFirstChild("LuckLvl") or Instance.new("IntValue", hs); l.Name = "LuckLvl"; l.Value = l.Value + amount; local lm = hs:FindFirstChild("LuckMultiplier") or Instance.new("NumberValue", hs); lm.Name = "LuckMultiplier"; lm.Value = 1.0 + (l.Value * 0.1) elseif ls and ls:FindFirstChild(stat) then ls[stat].Value = ls[stat].Value + amount end else pcall(function() MyDataStore:UpdateAsync("Player_" .. targetId, function(old) old = old or {}; if stat == "Luck" then old["LuckLvl"] = (old["LuckLvl"] or 0) + amount; old["LuckMultiplier"] = 1.0 + (old["LuckLvl"] * 0.1) else old[stat] = (old[stat] or 0) + amount end; return old end) end) end
	elseif action == "GiveSpin" then local amount = tonumber(data.Amount) or 1; if targetPlayer then local h = targetPlayer:FindFirstChild("HiddenStats"); if h then local w = h:FindFirstChild("WheelSpin") or Instance.new("IntValue", h); w.Name = "WheelSpin"; w.Value = w.Value + amount end else pcall(function() MyDataStore:UpdateAsync("Player_" .. targetId, function(old) old = old or {}; old["WheelSpin"] = (old["WheelSpin"] or 1) + amount; return old end) end) end
	elseif action == "GivePotion" then local potionName, amount = data.Potion, tonumber(data.Amount) or 1; if not potionName then return end; local pType, size = string.match(potionName, "^(%w+)_(%w+)$"); if not pType then pType = potionName; size = "Small"; potionName = pType .. "_" .. size end; if not table.find(POTION_TYPES, pType) or not table.find(POTION_SIZES, size) then return end; if targetPlayer then GivePotionToPlayer(targetPlayer, potionName, amount) else pcall(function() MyDataStore:UpdateAsync("Player_" .. targetId, function(old) old = old or {}; if not old.Potions then old.Potions = {} end; old.Potions[potionName] = (old.Potions[potionName] or 0) + amount; return old end) end) end
	elseif action == "ResetStats" then if not data.Confirm then return end; if targetPlayer then targetPlayer:Kick("Stats resetlendi.") end; ResetPlayerData(targetId) end
end)

print("✅ AdminManager: Loaded!")

----------------------------------

MapConfig :

local MapConfig = {}

-- [[ GAMEPASS ID ]] --
MapConfig.GamepassID = 1662041062

-- [[ HARİTA LİSTESİ (TELEPORT NOKTALARI) ]] --
MapConfig.Maps = {
	[1] = {
		Name = "HUB (Lobby)",
		Image = "rbxassetid://13793617786", 
		Description = "Ana merkez. Market ve takas alanı.",
		RebirthReq = 0,
		Color = Color3.fromRGB(255, 170, 0),
		TargetCFrame = CFrame.new(2723.969, 219.251, 4658.269) -- HUB
	},
	[2] = {
		Name = "Forest Zone",
		Image = "rbxassetid://13793617786",
		Description = "Low-poly orman. Başlangıç bölgesi.",
		RebirthReq = 0,
		Color = Color3.fromRGB(85, 255, 127),
		TargetCFrame = CFrame.new(852.474, 125.081, 4325.726) -- 1. MAP GİRİŞİ
	},
	[3] = {
		Name = "Desert Ruins",
		Image = "rbxassetid://13793617786",
		Description = "Bahçe ve mağara bölgesi.",
		RebirthReq = 1,
		Color = Color3.fromRGB(255, 170, 127),
		TargetCFrame = CFrame.new(-1385.05, 46.784, 4347.199) -- 2. MAP GİRİŞİ
	},
	[4] = {
		Name = "Ice Kingdom",
		Image = "rbxassetid://13793617786",
		Description = "Karlı dağlar ve buz.",
		RebirthReq = 5,
		Color = Color3.fromRGB(130, 230, 255),
		TargetCFrame = CFrame.new(-3259.553, -63.957, 4371.813) -- 3. MAP GİRİŞİ
	},
	[5] = {
		Name = "Minecraftia",
		Image = "rbxassetid://13793617786",
		Description = "Bloklu dünya.",
		RebirthReq = 10,
		Color = Color3.fromRGB(100, 200, 100),
		TargetCFrame = CFrame.new(-5609.817, -118.277, 4445.433) -- 4. MAP GİRİŞİ
	},
	[6] = {
		Name = "City Center",
		Image = "rbxassetid://13793617786",
		Description = "Şehir merkezi.",
		RebirthReq = 25,
		Color = Color3.fromRGB(170, 85, 255),
		TargetCFrame = CFrame.new(875.595, 31.543, 6471.25) -- 5. MAP GİRİŞİ
	}
}

return MapConfig

----------------------------------------------------------


Roblox oyunu geliştiriyorum ve yardımına ihtiyacım var

pet sistemimde bir sorun var petlerin eklediği sayılar mesela 1000 ekliyor diyelim bunu çarpan olarak işliyor oyuncu base iq * petten gelen değer gibisinden bir işlem yapıyor benim istediğim iq değerli + pet değeri + diğer değerler olsun istiyorum



Ayrıca oyunda büyük bir değişikliliğe gitmek istiyorum sanırım elimdeki iq değerlerini etkileyen bütün scriptleri attım ONEMLİ NOT SAKIN İSTEMEDİĞİM HİÇ BİR ŞEYİ SİLME KODLARDAKI SİSTEMLERİ BOZMA EKSİLTME SADECE SENDEN İSTEDİKLERİMİ YAP HEPSİNİ MADDE MADDE AYRICA YAZICAM SİMDİ SAKIN ELİNE YÜZÜNE BULAŞTIRMA OLAYI BÜYÜK DEĞİŞİKLİĞE GİDİYORUZ BÜTÜN OYUN SİSTEMİ BOZULABİLİR YANLISLIK OLURSA



1.IQ Kazanımları + olarak olucak base iq + pet + rebirth + clicklvl * pot başka unuttuğum var ise formüle ekle bir tek iq potu çarpan olarak eklenicek

2.Her Rebirth atıldığında o anda sahip olduğu saf saldırı gücü ve saf iq kazanımı üzerine 2x eklemeli

3.Pet hatch işleminden sonra ekranda çıkan nadirlik yazısının yanında (3x) diye yazılar hala çıkıyor bunu düzelt

4.Bütün bu sistem için dengeli bir GameConfig düzenlemesi istiyorum senden

5.Burada bulunan gerekli tüm sistemlerin tweak game balance ile iligili tüm sistemler GameConfig üzerinden ayarlanabilmeli Önemli Not : RotSkill ve Pet sisteminin ayarlamaları güncel yapıldı onlara karışmanı istemiyorum ama şöyle bir şey var sistem dengelemesi için gerekli düzenlemeler yapılması gerekiyor ise yapabilirsin

6.oyun düzeninin mantığı anlaman için şöyle olmasını istiyorum oyuncu 1 haritadan normal şartlarda 2 saatte çıkabilmeli haritalar yükseldikçe haritada geçirilmesi gereken vakitte artmalı böylece oyuncu sürekli grindlamak zorunda kalıcak normal şartlarda dememin sebebi oyuncu şanslı ise secret pet vs veya güzel bir rotskill kazandı ise bu süreler düşücek ama ortalama bir güce sahip olan oyuncu bu haritaları geçerken zorlanmalı oyunda vakit geçirmeli ayrıca bir yerden sonra oyuncular önceki haritalarda RotSkill'i düşük çıkardı diyelim ilerleyen bölümlerde o haritalara dönüp daha iyi bir RotSkill çıkarmalılar diğer haritalarda başarı sağlamak için

7. En önemli kısım ödül sistemleri ve oyuncuların sistemlerden kazandığı kalıcı veya geçici özellikler bunlar çok dengeli ve birbiri ile uyumlu olmalı ödül havuzlarında şuanda elimizde olan ne var ise onları kullanmalıyız ileride benim değiştirebileceğim şekilde dizayn edilmeli

8.Oyundaki Damage Rebirth Stats Kazanımları Ödül kazanımları hepsi birbiri ile uyum içerisinde olmalı bunu aklından sakın çıkarma çok önemli

9.Oyunda değer sistemini anlaman adına Coins<Essence<Spin<RSToken<Aura ödül sistemlerinde bunların değerleri dengeli olmalı

10.Rebirth sistemi artık essence ile rebirth atılmayacak IQ ile rebirth atıcak oyuncular ve Rebirth sistemini geliştirmek istiyorum şuan kısıtlı sanırsam

11.Haritalarda Boss'ların kesilmesi oyuncular için neredeyse imkansız olmalı para yatırmadılar ise başka oyuncu yardımı ile bile bossun %20 can barajını geçememeleri gerekiyor böylece oyuncu o haritadaki bütün içeriklerde en iyi sayılabilecek ödülleri çıkarır ise ilerleme kaydetmeli mesela oyuncu 2. haritaya geçti her haritada RotSkill makineleri olucak oyuncu 1. rot skill makinesinden RotSkill 3'ü çıkartmış yeni haritada RotSkill 4 var diyelim oyuncu bir önceki haritada RotSkill'in daha yüksek seviyesini çıkartmaya zorluyacak bir zorluk gerekiyor


12. oyunculara görev sistemi vermemiz gerekiyor diğer haritalara rebirth ile geçmek yerine bu görevleri tamamladıklarında diğer haritaya geçiş yapabilecekler örnek olarak 10x Brr Brr Patapim 20x Orangutini Ananassini 30x Los Tralaleritos 5x Noobini(Boss) kesmesi gerekicek böylece diğer haritaya geçiş sağlayabilecek oyuncunun geçiş gereksinimleride scriptlerde bu şekilde ayarlanmalı diğer haritalarda aynı bu şekilde olucak

13.Oyundaki bazı scriptleri atmadım buraya eğer kodlarda gözüne çarpan bir değer vs olur ise gerekli olan bütün scriptleri seninle paylaşabilirim istemen yeterli

14.Damage sistemi konusunda da düzenlemeler yapmanı istiyorum Damage arttıran sistemler çarpan yerine AddDamage olmalı iksir çarpan vermeli yani basedamage + Rebirth + RotSkill * potion bütün değerler + potion * olucak şekilde damage ikisiri bulunmuyor şuan onun da eklemesini yaparsın 

15.Eklemek istediğin şeyleri ihtiyacın olan scriptleri veya bilmem gereken ne bilgi varsa bütün süreçten haberdar olmak istiyorum 


Şuanda aklıma gelen bunlar bu aşamaları mutlaka hatasız ve mükemmel bir şekilde entegre etmeliyiz hata olmaması gerekiyor karışıklık olucak ise teker teker ilerleyebiliriz yeter ki düzgün çalışssın
