-- AntiCheatSystem.lua
-- Konum: ServerScriptService -> Security
-- Gelişmiş Anti-Cheat ve Anti-Spoof Sistemi

local AntiCheatSystem = {}

-- Servisler
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modüller
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DebugConfig = require(script.Parent.Parent.ReplicatedStorage.Modules.DebugConfig)

-- =============================================================================
-- [[ ANTİ-CHEAT AYARLARI ]]
-- =============================================================================

AntiCheatSystem.Config = {
	-- Genel Ayarlar
	Enabled = true,
	AutoKickCheaters = false, -- Hile yapanları otomatik at (false = sadece log)
	WarningsBeforeKick = 3,   -- Kick edilmeden önce kaç uyarı
	
	-- Stat Limitleri (Makul Maksimum Değerler)
	MaxStats = {
		IQ = 1e15,           -- 1 Quadrilyon IQ (çok yüksek ama makul)
		Coins = 1e15,        -- 1 Quadrilyon Coin
		Essence = 1e12,      -- 1 Trilyon Essence
		Aura = 1e10,         -- 10 Milyar Aura
		Spin = 1e9,          -- 1 Milyar Spin
		RSToken = 1e9,       -- 1 Milyar RSToken
		Rebirth = 1000,      -- Maksimum 1000 Rebirth
		ClickLevel = 100,    -- Maksimum 100 Click Level
		LuckMultiplier = 10, -- Maksimum 10x Luck
		SpeedLevel = 100,    -- Maksimum 100 Speed Level
	},
	
	-- Değişim Hızı Kontrolleri (Saniye başına)
	MaxChangeRates = {
		IQ = 1e12,           -- Saniyede maksimum IQ artışı
		Coins = 1e12,        -- Saniyede maksimum Coin artışı
		Aura = 1e6,          -- Saniyede maksimum Aura artışı
		Essence = 1e9,       -- Saniyede maksimum Essence artışı
	},
	
	-- Aura Anti-Spoof
	AuraValidation = {
		MaxAuraPerSpin = 100,      -- Çarktan maksimum Aura
		MaxAuraFromReward = 1000,  -- Ödüllerden maksimum Aura
		CheckInterval = 5,         -- Her 5 saniyede kontrol
	},
	
	-- İksir Kontrolleri
	PotionValidation = {
		MaxActivePotions = 10,     -- Aynı anda maksimum aktif iksir
		MaxPotionDuration = 3600,  -- Maksimum iksir süresi (1 saat)
		ValidPotionTypes = {"Luck", "IQ", "Aura", "Essence", "Speed", "Damage"},
	},
}

-- =============================================================================
-- [[ OYUNCU VERİLERİ ]]
-- =============================================================================

local PlayerData = {}
local PlayerWarnings = {}

-- Oyuncu verilerini başlat
local function InitPlayerData(player)
	PlayerData[player.UserId] = {
		LastStats = {},
		LastCheck = tick(),
		SuspiciousActivity = 0,
		TotalWarnings = 0,
	}
	PlayerWarnings[player.UserId] = 0
	
	DebugConfig.Info("AntiCheat", "Player data initialized", player.Name)
end

-- Oyuncu verilerini temizle
local function ClearPlayerData(player)
	PlayerData[player.UserId] = nil
	PlayerWarnings[player.UserId] = nil
	
	DebugConfig.Info("AntiCheat", "Player data cleared", player.Name)
end

-- =============================================================================
-- [[ STAT VALİDASYON ]]
-- =============================================================================

-- Stat'ın makul olup olmadığını kontrol et
function AntiCheatSystem.ValidateStat(player, statName, currentValue)
	if not AntiCheatSystem.Config.Enabled then return true end
	
	local maxValue = AntiCheatSystem.Config.MaxStats[statName]
	if not maxValue then return true end
	
	if currentValue > maxValue then
		DebugConfig.Warning("AntiCheat", 
			string.format("Stat limit exceeded: %s = %s (Max: %s)", 
				statName, tostring(currentValue), tostring(maxValue)), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "StatLimitExceeded", {
			Stat = statName,
			Value = currentValue,
			MaxValue = maxValue
		})
		
		return false
	end
	
	return true
end

-- Stat değişim hızını kontrol et
function AntiCheatSystem.ValidateStatChange(player, statName, oldValue, newValue, deltaTime)
	if not AntiCheatSystem.Config.Enabled then return true end
	
	local maxRate = AntiCheatSystem.Config.MaxChangeRates[statName]
	if not maxRate then return true end
	
	local change = newValue - oldValue
	if change <= 0 then return true end -- Azalma normal
	
	local rate = change / deltaTime
	
	if rate > maxRate then
		DebugConfig.Warning("AntiCheat", 
			string.format("Stat change rate exceeded: %s increased by %s in %.2fs (Rate: %.2f/s, Max: %.2f/s)", 
				statName, tostring(change), deltaTime, rate, maxRate), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "StatChangeRateExceeded", {
			Stat = statName,
			Change = change,
			DeltaTime = deltaTime,
			Rate = rate,
			MaxRate = maxRate
		})
		
		return false
	end
	
	return true
end

-- =============================================================================
-- [[ AURA ANTİ-SPOOF ]]
-- =============================================================================

-- Aura kazanımını doğrula
function AntiCheatSystem.ValidateAuraGain(player, amount, source)
	if not AntiCheatSystem.Config.Enabled then return true end
	
	local maxAmount = 0
	if source == "Spin" then
		maxAmount = AntiCheatSystem.Config.AuraValidation.MaxAuraPerSpin
	elseif source == "Reward" then
		maxAmount = AntiCheatSystem.Config.AuraValidation.MaxAuraFromReward
	else
		maxAmount = AntiCheatSystem.Config.AuraValidation.MaxAuraFromReward
	end
	
	if amount > maxAmount then
		DebugConfig.Warning("AntiCheat", 
			string.format("Invalid Aura gain: %s from %s (Max: %s)", 
				tostring(amount), source, tostring(maxAmount)), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "InvalidAuraGain", {
			Amount = amount,
			Source = source,
			MaxAmount = maxAmount
		})
		
		return false
	end
	
	DebugConfig.Verbose("AntiCheat", 
		string.format("Aura gain validated: %s from %s", tostring(amount), source), 
		player.Name)
	
	return true
end

-- Aura manipülasyonunu kontrol et
function AntiCheatSystem.CheckAuraManipulation(player)
	if not AntiCheatSystem.Config.Enabled then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local aura = leaderstats:FindFirstChild("Aura")
	if not aura then return end
	
	local userId = player.UserId
	local data = PlayerData[userId]
	if not data then return end
	
	local lastAura = data.LastStats.Aura or 0
	local currentAura = aura.Value
	local deltaTime = tick() - data.LastCheck
	
	-- Ani Aura artışı kontrolü
	if not AntiCheatSystem.ValidateStatChange(player, "Aura", lastAura, currentAura, deltaTime) then
		-- Şüpheli aktivite artır
		data.SuspiciousActivity = data.SuspiciousActivity + 1
		
		if data.SuspiciousActivity >= 5 then
			DebugConfig.Error("AntiCheat", 
				"Multiple suspicious Aura activities detected!", 
				player.Name)
		end
	end
	
	-- Güncelle
	data.LastStats.Aura = currentAura
	data.LastCheck = tick()
end

-- =============================================================================
-- [[ İKSİR VALİDASYONU ]]
-- =============================================================================

-- İksir kullanımını doğrula
function AntiCheatSystem.ValidatePotionUse(player, potionType, duration)
	if not AntiCheatSystem.Config.Enabled then return true end
	
	-- Geçerli iksir tipi mi?
	local validTypes = AntiCheatSystem.Config.PotionValidation.ValidPotionTypes
	local isValid = false
	for _, validType in ipairs(validTypes) do
		if potionType == validType then
			isValid = true
			break
		end
	end
	
	if not isValid then
		DebugConfig.Warning("AntiCheat", 
			string.format("Invalid potion type: %s", potionType), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "InvalidPotionType", {
			PotionType = potionType
		})
		
		return false
	end
	
	-- Süre kontrolü
	if duration > AntiCheatSystem.Config.PotionValidation.MaxPotionDuration then
		DebugConfig.Warning("AntiCheat", 
			string.format("Potion duration too long: %ds (Max: %ds)", 
				duration, AntiCheatSystem.Config.PotionValidation.MaxPotionDuration), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "InvalidPotionDuration", {
			Duration = duration,
			MaxDuration = AntiCheatSystem.Config.PotionValidation.MaxPotionDuration
		})
		
		return false
	end
	
	DebugConfig.Verbose("AntiCheat", 
		string.format("Potion validated: %s (%ds)", potionType, duration), 
		player.Name)
	
	return true
end

-- Aktif iksir sayısını kontrol et
function AntiCheatSystem.CheckActivePotions(player)
	if not AntiCheatSystem.Config.Enabled then return true end
	
	local activePotions = 0
	local validTypes = AntiCheatSystem.Config.PotionValidation.ValidPotionTypes
	
	for _, potionType in ipairs(validTypes) do
		local attrName = potionType .. "Multiplier"
		local multiplier = player:GetAttribute(attrName)
		if multiplier and multiplier > 1 then
			activePotions = activePotions + 1
		end
	end
	
	local maxPotions = AntiCheatSystem.Config.PotionValidation.MaxActivePotions
	if activePotions > maxPotions then
		DebugConfig.Warning("AntiCheat", 
			string.format("Too many active potions: %d (Max: %d)", 
				activePotions, maxPotions), 
			player.Name)
		
		AntiCheatSystem.FlagPlayer(player, "TooManyActivePotions", {
			ActivePotions = activePotions,
			MaxPotions = maxPotions
		})
		
		return false
	end
	
	return true
end

-- =============================================================================
-- [[ OYUNCU BAYRAKLAMA VE CEZALANDIRMA ]]
-- =============================================================================

function AntiCheatSystem.FlagPlayer(player, reason, details)
	local userId = player.UserId
	
	-- Uyarı sayısını artır
	PlayerWarnings[userId] = (PlayerWarnings[userId] or 0) + 1
	local warnings = PlayerWarnings[userId]
	
	-- Log
	DebugConfig.Warning("AntiCheat", 
		string.format("Player flagged: %s (Warnings: %d/%d) - Details: %s", 
			reason, warnings, AntiCheatSystem.Config.WarningsBeforeKick, 
			game:GetService("HttpService"):JSONEncode(details or {})), 
		player.Name)
	
	-- Event Logger'a bildir (varsa)
	local eventLogger = script.Parent:FindFirstChild("EventLogger")
	if eventLogger then
		local EventLoggerModule = require(eventLogger)
		EventLoggerModule.LogEvent(player, "AntiCheat", reason, details)
	end
	
	-- Kick kontrolü
	if AntiCheatSystem.Config.AutoKickCheaters and warnings >= AntiCheatSystem.Config.WarningsBeforeKick then
		DebugConfig.Error("AntiCheat", 
			string.format("Player kicked for cheating: %s", reason), 
			player.Name)
		
		player:Kick(string.format("Anti-Cheat: %s uyarı sonucu atıldınız. Sebep: %s", 
			warnings, reason))
	end
end

-- Oyuncuyu temizle (uyarıları sıfırla)
function AntiCheatSystem.ClearPlayer(player)
	PlayerWarnings[player.UserId] = 0
	DebugConfig.Info("AntiCheat", "Player warnings cleared", player.Name)
end

-- =============================================================================
-- [[ OTOMATİK KONTROLLER ]]
-- =============================================================================

-- Tüm oyuncuları periyodik olarak kontrol et
function AntiCheatSystem.StartPeriodicChecks()
	if not AntiCheatSystem.Config.Enabled then return end
	
	DebugConfig.Info("AntiCheat", "Periodic checks started")
	
	task.spawn(function()
		while AntiCheatSystem.Config.Enabled do
			task.wait(AntiCheatSystem.Config.AuraValidation.CheckInterval)
			
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					AntiCheatSystem.CheckAuraManipulation(player)
					AntiCheatSystem.CheckActivePotions(player)
				end)
			end
		end
	end)
end

-- =============================================================================
-- [[ BAŞLATMA VE EVENT HANDLERları ]]
-- =============================================================================

function AntiCheatSystem.Initialize()
	DebugConfig.Info("AntiCheat", "Initializing Anti-Cheat System...")
	
	-- Mevcut oyuncular için veri başlat
	for _, player in ipairs(Players:GetPlayers()) do
		InitPlayerData(player)
	end
	
	-- Yeni oyuncular için event
	Players.PlayerAdded:Connect(function(player)
		InitPlayerData(player)
	end)
	
	-- Oyuncu çıkış eventi
	Players.PlayerRemoving:Connect(function(player)
		ClearPlayerData(player)
	end)
	
	-- Periyodik kontrolleri başlat
	AntiCheatSystem.StartPeriodicChecks()
	
	DebugConfig.Info("AntiCheat", "Anti-Cheat System Initialized Successfully ✅")
end

-- =============================================================================
-- [[ BİLGİ FONKSİYONLARI ]]
-- =============================================================================

function AntiCheatSystem.GetPlayerWarnings(player)
	return PlayerWarnings[player.UserId] or 0
end

function AntiCheatSystem.GetPlayerData(player)
	return PlayerData[player.UserId]
end

function AntiCheatSystem.PrintStats()
	print("=== ANTI-CHEAT İSTATİSTİKLER ===")
	print("Enabled:", AntiCheatSystem.Config.Enabled)
	print("Auto Kick:", AntiCheatSystem.Config.AutoKickCheaters)
	print("Active Players:", #Players:GetPlayers())
	
	local totalWarnings = 0
	for _, warnings in pairs(PlayerWarnings) do
		totalWarnings = totalWarnings + warnings
	end
	print("Total Warnings:", totalWarnings)
	print("===============================")
end

return AntiCheatSystem
