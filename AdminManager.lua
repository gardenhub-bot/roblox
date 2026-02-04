-- AdminManager.lua
-- Konum: ServerScriptService -> Administration
-- Sunucu Tarafı Admin Yönetim Sistemi

local AdminManager = {}

-- Servisler
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Modüller
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DebugConfig = require(Modules:WaitForChild("DebugConfig"))

-- Security ve Systems modülleri
local Security = ServerScriptService:WaitForChild("Security")
local Systems = ServerScriptService:WaitForChild("Systems")
local AntiCheatSystem = require(Security:WaitForChild("AntiCheatSystem"))
local EventLogger = require(Systems:WaitForChild("EventLogger"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Admin komut remote'u
local AdminCommandRemote = Remotes:FindFirstChild("AdminCommand")
if not AdminCommandRemote then
	AdminCommandRemote = Instance.new("RemoteEvent")
	AdminCommandRemote.Name = "AdminCommand"
	AdminCommandRemote.Parent = Remotes
	DebugConfig.Info("AdminManager", "AdminCommand Remote created")
end

-- Admin data update remote'u
local AdminDataRemote = Remotes:FindFirstChild("AdminDataUpdate")
if not AdminDataRemote then
	AdminDataRemote = Instance.new("RemoteEvent")
	AdminDataRemote.Name = "AdminDataUpdate"
	AdminDataRemote.Parent = Remotes
	DebugConfig.Info("AdminManager", "AdminDataUpdate Remote created")
end

-- =============================================================================
-- [[ ADMİN AYARLARI ]]
-- =============================================================================

AdminManager.Config = {
	-- Admin Listesi (UserId bazlı)
	Admins = {
		[1] = true, -- Placeholder - Gerçek admin ID'leri buraya eklenecek
	},
	
	-- Admin Seviyeleri
	AdminLevels = {
		[1] = "SuperAdmin", -- Tam yetki
		[2] = "Admin",      -- Çoğu yetki
		[3] = "Moderator",  -- Sınırlı yetki
	},
	
	-- Komut İzinleri (Level bazlı)
	CommandPermissions = {
		-- Level 1 (SuperAdmin) - Tüm komutlar
		[1] = {
			"GiveStat", "TakeStat", "SetStat", "ResetPlayer",
			"KickPlayer", "BanPlayer", "TeleportPlayer",
			"GivePotion", "ClearPotions", "SetDebug",
			"ViewLogs", "ClearLogs", "ToggleAntiCheat",
			"GiveAura", "ResetAura", "ForceRebirth",
		},
		
		-- Level 2 (Admin)
		[2] = {
			"GiveStat", "GivePotion", "TeleportPlayer",
			"ViewLogs", "SetDebug",
		},
		
		-- Level 3 (Moderator)
		[3] = {
			"ViewLogs", "TeleportPlayer",
		},
	},
	
	-- Otomatik Sistemler
	AutoSystems = {
		AntiCheat = true,
		EventLogging = true,
		StatMonitoring = true,
	},
}

-- =============================================================================
-- [[ ADMİN YETKİ KONTROLÜ ]]
-- =============================================================================

-- Oyuncunun admin olup olmadığını kontrol et
function AdminManager.IsAdmin(player)
	local userId = player.UserId
	return AdminManager.Config.Admins[userId] == true
end

-- Admin seviyesini al
function AdminManager.GetAdminLevel(player)
	if not AdminManager.IsAdmin(player) then return nil end
	
	-- Şimdilik hepsi SuperAdmin, ileride özelleştirilebilir
	return 1
end

-- Komut için yetki kontrolü
function AdminManager.HasPermission(player, command)
	local level = AdminManager.GetAdminLevel(player)
	if not level then return false end
	
	local permissions = AdminManager.Config.CommandPermissions[level]
	if not permissions then return false end
	
	for _, allowedCommand in ipairs(permissions) do
		if allowedCommand == command then
			return true
		end
	end
	
	return false
end

-- Oyuncuyu admin olarak işaretle
function AdminManager.SetAdmin(player, isAdmin)
	player:SetAttribute("IsAdmin", isAdmin)
	
	if isAdmin then
		DebugConfig.Info("AdminManager", "Player marked as admin", player.Name)
		EventLogger.LogAdminAction(player, "AdminGranted", player, {})
		
		-- Admin'e mevcut sistem durumunu gönder
		AdminManager.SendSystemStatus(player)
	else
		DebugConfig.Info("AdminManager", "Player admin status removed", player.Name)
	end
end

-- =============================================================================
-- [[ STAT YÖNETİMİ ]]
-- =============================================================================

function AdminManager.GiveStat(admin, targetPlayer, statName, amount)
	if not AdminManager.HasPermission(admin, "GiveStat") then
		DebugConfig.Warning("AdminManager", "Permission denied for GiveStat", admin.Name)
		return false, "İzin reddedildi"
	end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats bulunamadı"
	end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		return false, "Stat bulunamadı: " .. statName
	end
	
	local oldValue = stat.Value
	stat.Value = stat.Value + amount
	
	DebugConfig.Info("AdminManager", 
		string.format("Stat given: %s +%s to %s", statName, tostring(amount), targetPlayer.Name), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "GiveStat", targetPlayer, {
		Stat = statName,
		Amount = amount,
		OldValue = oldValue,
		NewValue = stat.Value,
	})
	
	EventLogger.LogStatChange(targetPlayer, statName, oldValue, stat.Value)
	
	return true, "Başarılı"
end

function AdminManager.SetStat(admin, targetPlayer, statName, value)
	if not AdminManager.HasPermission(admin, "SetStat") then
		DebugConfig.Warning("AdminManager", "Permission denied for SetStat", admin.Name)
		return false, "İzin reddedildi"
	end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats bulunamadı"
	end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then
		return false, "Stat bulunamadı: " .. statName
	end
	
	local oldValue = stat.Value
	stat.Value = value
	
	DebugConfig.Info("AdminManager", 
		string.format("Stat set: %s = %s for %s", statName, tostring(value), targetPlayer.Name), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "SetStat", targetPlayer, {
		Stat = statName,
		OldValue = oldValue,
		NewValue = value,
	})
	
	EventLogger.LogStatChange(targetPlayer, statName, oldValue, value)
	
	return true, "Başarılı"
end

-- =============================================================================
-- [[ İKSİR YÖNETİMİ ]]
-- =============================================================================

function AdminManager.GivePotion(admin, targetPlayer, potionType, duration)
	if not AdminManager.HasPermission(admin, "GivePotion") then
		DebugConfig.Warning("AdminManager", "Permission denied for GivePotion", admin.Name)
		return false, "İzin reddedildi"
	end
	
	duration = duration or 300
	
	-- Anti-cheat kontrolü
	if not AntiCheatSystem.ValidatePotionUse(targetPlayer, potionType, duration) then
		return false, "İksir validasyonu başarısız"
	end
	
	-- İksir ver
	local attrName = potionType .. "Multiplier"
	targetPlayer:SetAttribute(attrName, 2) -- 2x multiplier
	
	DebugConfig.Info("AdminManager", 
		string.format("Potion given: %s (%ds) to %s", potionType, duration, targetPlayer.Name), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "GivePotion", targetPlayer, {
		PotionType = potionType,
		Duration = duration,
	})
	
	EventLogger.LogPotionUse(targetPlayer, potionType, duration)
	
	-- Süre sonunda kaldır
	task.delay(duration, function()
		if targetPlayer and targetPlayer.Parent then
			targetPlayer:SetAttribute(attrName, 1)
			DebugConfig.Verbose("AdminManager", 
				string.format("Potion expired: %s for %s", potionType, targetPlayer.Name))
		end
	end)
	
	return true, "Başarılı"
end

function AdminManager.ClearPotions(admin, targetPlayer)
	if not AdminManager.HasPermission(admin, "ClearPotions") then
		DebugConfig.Warning("AdminManager", "Permission denied for ClearPotions", admin.Name)
		return false, "İzin reddedildi"
	end
	
	local potionTypes = {"Luck", "IQ", "Aura", "Essence", "Speed", "Damage"}
	
	for _, potionType in ipairs(potionTypes) do
		local attrName = potionType .. "Multiplier"
		targetPlayer:SetAttribute(attrName, 1)
	end
	
	DebugConfig.Info("AdminManager", "All potions cleared", admin.Name)
	
	EventLogger.LogAdminAction(admin, "ClearPotions", targetPlayer, {})
	
	return true, "Başarılı"
end

-- =============================================================================
-- [[ AURA YÖNETİMİ ]]
-- =============================================================================

function AdminManager.GiveAura(admin, targetPlayer, amount)
	if not AdminManager.HasPermission(admin, "GiveAura") then
		DebugConfig.Warning("AdminManager", "Permission denied for GiveAura", admin.Name)
		return false, "İzin reddedildi"
	end
	
	-- Anti-cheat kontrolü (admin tarafından verildiği için daha yüksek limit)
	if amount > 1000000 then
		return false, "Miktar çok yüksek (Max: 1M)"
	end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats bulunamadı"
	end
	
	local aura = leaderstats:FindFirstChild("Aura")
	if not aura then
		return false, "Aura bulunamadı"
	end
	
	local oldValue = aura.Value
	aura.Value = aura.Value + amount
	
	DebugConfig.Info("AdminManager", 
		string.format("Aura given: +%s to %s", tostring(amount), targetPlayer.Name), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "GiveAura", targetPlayer, {
		Amount = amount,
		OldValue = oldValue,
		NewValue = aura.Value,
	})
	
	EventLogger.LogAuraGain(targetPlayer, amount, "AdminGrant")
	
	return true, "Başarılı"
end

-- =============================================================================
-- [[ DEBUG YÖNETİMİ ]]
-- =============================================================================

function AdminManager.SetDebug(admin, systemName, enabled)
	if not AdminManager.HasPermission(admin, "SetDebug") then
		DebugConfig.Warning("AdminManager", "Permission denied for SetDebug", admin.Name)
		return false, "İzin reddedildi"
	end
	
	if systemName == "Master" then
		DebugConfig.Settings.MasterDebugEnabled = enabled
	else
		DebugConfig.UpdateSystemDebug(systemName, enabled)
	end
	
	DebugConfig.Info("AdminManager", 
		string.format("Debug setting changed: %s = %s", systemName, tostring(enabled)), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "SetDebug", nil, {
		System = systemName,
		Enabled = enabled,
	})
	
	-- Tüm admin'lere güncellenmiş ayarları gönder
	AdminManager.BroadcastSystemStatus()
	
	return true, "Başarılı"
end

-- =============================================================================
-- [[ ANTİ-CHEAT YÖNETİMİ ]]
-- =============================================================================

function AdminManager.ToggleAntiCheat(admin, enabled)
	if not AdminManager.HasPermission(admin, "ToggleAntiCheat") then
		DebugConfig.Warning("AdminManager", "Permission denied for ToggleAntiCheat", admin.Name)
		return false, "İzin reddedildi"
	end
	
	AntiCheatSystem.Config.Enabled = enabled
	
	DebugConfig.Info("AdminManager", 
		string.format("Anti-Cheat toggled: %s", tostring(enabled)), 
		admin.Name)
	
	EventLogger.LogAdminAction(admin, "ToggleAntiCheat", nil, {
		Enabled = enabled,
	})
	
	AdminManager.BroadcastSystemStatus()
	
	return true, "Başarılı"
end

-- =============================================================================
-- [[ SİSTEM DURUMU ]]
-- =============================================================================

function AdminManager.GetSystemStatus()
	return {
		Debug = {
			MasterEnabled = DebugConfig.Settings.MasterDebugEnabled,
			Systems = DebugConfig.Settings.DebugSystems,
		},
		AntiCheat = {
			Enabled = AntiCheatSystem.Config.Enabled,
			AutoKick = AntiCheatSystem.Config.AutoKickCheaters,
		},
		EventLogger = {
			Enabled = EventLogger.Config.Enabled,
			StoredEvents = #EventLogger.GetRecentEvents(1),
		},
		Server = {
			Players = #Players:GetPlayers(),
			Uptime = tick(),
		},
	}
end

function AdminManager.SendSystemStatus(player)
	if not player:GetAttribute("IsAdmin") then return end
	
	local status = AdminManager.GetSystemStatus()
	
	task.spawn(function()
		local success, err = pcall(function()
			AdminDataRemote:FireClient(player, {
				Type = "SystemStatus",
				Data = status,
			})
		end)
		
		if not success then
			DebugConfig.Warning("AdminManager", 
				string.format("Failed to send system status: %s", tostring(err)), 
				player.Name)
		end
	end)
end

function AdminManager.BroadcastSystemStatus()
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("IsAdmin") then
			AdminManager.SendSystemStatus(player)
		end
	end
end

-- =============================================================================
-- [[ KOMUT İŞLEYİCİ ]]
-- =============================================================================

local CommandHandlers = {
	GiveStat = function(admin, args)
		local targetName, statName, amount = args[1], args[2], tonumber(args[3])
		local target = Players:FindFirstChild(targetName)
		
		if not target then
			return false, "Oyuncu bulunamadı"
		end
		
		return AdminManager.GiveStat(admin, target, statName, amount)
	end,
	
	SetStat = function(admin, args)
		local targetName, statName, value = args[1], args[2], tonumber(args[3])
		local target = Players:FindFirstChild(targetName)
		
		if not target then
			return false, "Oyuncu bulunamadı"
		end
		
		return AdminManager.SetStat(admin, target, statName, value)
	end,
	
	GivePotion = function(admin, args)
		local targetName, potionType, duration = args[1], args[2], tonumber(args[3]) or 300
		local target = Players:FindFirstChild(targetName)
		
		if not target then
			return false, "Oyuncu bulunamadı"
		end
		
		return AdminManager.GivePotion(admin, target, potionType, duration)
	end,
	
	GiveAura = function(admin, args)
		local targetName, amount = args[1], tonumber(args[2])
		local target = Players:FindFirstChild(targetName)
		
		if not target then
			return false, "Oyuncu bulunamadı"
		end
		
		return AdminManager.GiveAura(admin, target, amount)
	end,
	
	SetDebug = function(admin, args)
		local systemName, enabled = args[1], args[2] == "true"
		return AdminManager.SetDebug(admin, systemName, enabled)
	end,
	
	ToggleAntiCheat = function(admin, args)
		local enabled = args[1] == "true"
		return AdminManager.ToggleAntiCheat(admin, enabled)
	end,
}

function AdminManager.ProcessCommand(player, command, args)
	if not AdminManager.IsAdmin(player) then
		DebugConfig.Warning("AdminManager", "Non-admin attempted command", player.Name)
		return false, "Yetki yok"
	end
	
	local handler = CommandHandlers[command]
	if not handler then
		return false, "Bilinmeyen komut"
	end
	
	DebugConfig.Info("AdminManager", 
		string.format("Processing command: %s", command), 
		player.Name)
	
	local success, result = pcall(handler, player, args)
	
	if not success then
		DebugConfig.Error("AdminManager", 
			string.format("Command error: %s", tostring(result)), 
			player.Name)
		return false, "Komut hatası: " .. tostring(result)
	end
	
	return result
end

-- =============================================================================
-- [[ BAŞLATMA ]]
-- =============================================================================

function AdminManager.Initialize()
	DebugConfig.Info("AdminManager", "Initializing Admin Manager...")
	
	-- Anti-Cheat başlat
	if AdminManager.Config.AutoSystems.AntiCheat then
		AntiCheatSystem.Initialize()
	end
	
	-- Event Logger başlat
	if AdminManager.Config.AutoSystems.EventLogging then
		EventLogger.Initialize()
	end
	
	-- Mevcut oyuncular için admin kontrolü
	for _, player in ipairs(Players:GetPlayers()) do
		if AdminManager.IsAdmin(player) then
			AdminManager.SetAdmin(player, true)
		end
	end
	
	-- Yeni oyuncular için admin kontrolü
	Players.PlayerAdded:Connect(function(player)
		if AdminManager.IsAdmin(player) then
			AdminManager.SetAdmin(player, true)
		end
	end)
	
	-- Admin komut remote handler
	AdminCommandRemote.OnServerEvent:Connect(function(player, command, args)
		local success, message = AdminManager.ProcessCommand(player, command, args or {})
		
		-- Sonucu gönder
		task.spawn(function()
			pcall(function()
				AdminDataRemote:FireClient(player, {
					Type = "CommandResult",
					Success = success,
					Message = message,
					Command = command,
				})
			end)
		end)
	end)
	
	-- Admin data request handler
	AdminDataRemote.OnServerEvent:Connect(function(player, requestType)
		if not player:GetAttribute("IsAdmin") then return end
		
		if requestType == "SystemStatus" then
			AdminManager.SendSystemStatus(player)
		end
	end)
	
	-- Periyodik sistem durumu güncellemesi (her 10 saniye)
	task.spawn(function()
		while true do
			task.wait(10)
			AdminManager.BroadcastSystemStatus()
		end
	end)
	
	DebugConfig.Info("AdminManager", "Admin Manager Initialized Successfully ✅")
end

return AdminManager
