-- EventLogger.lua
-- Konum: ServerScriptService -> Systems
-- Gerçek-Zamanlı Event Logging Sistemi

local EventLogger = {}

-- Servisler
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Modüller
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DebugConfig = require(Modules:WaitForChild("DebugConfig"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EventLogRemote = Remotes:FindFirstChild("EventLogUpdate")
if not EventLogRemote then
	EventLogRemote = Instance.new("RemoteEvent")
	EventLogRemote.Name = "EventLogUpdate"
	EventLogRemote.Parent = Remotes
	DebugConfig.Info("EventLogger", "EventLogUpdate Remote created")
end

-- =============================================================================
-- [[ EVENT LOGGER AYARLARI ]]
-- =============================================================================

EventLogger.Config = {
	Enabled = true,
	
	-- Log Ayarları
	MaxStoredEvents = 500,        -- Bellekte tutulacak maksimum event sayısı
	BroadcastToAdmins = true,     -- Admin'lere gerçek zamanlı broadcast
	LogToConsole = true,          -- Console'a log yaz
	
	-- Event Kategorileri
	EnabledCategories = {
		PlayerJoin = true,
		PlayerLeave = true,
		StatChange = true,
		PotionUse = true,
		AuraGain = true,
		AntiCheat = true,
		AdminAction = true,
		Purchase = true,
		Rebirth = true,
		Spin = true,
		Error = true,
	},
	
	-- Filtreleme
	MinLogLevel = 1, -- 1=All, 2=Important, 3=Critical
}

-- =============================================================================
-- [[ EVENT DEPOLAMA ]]
-- =============================================================================

local EventLog = {}
local EventIndex = 0

-- Event yapısı
local function CreateEvent(player, category, eventType, details)
	EventIndex = EventIndex + 1
	
	local event = {
		Index = EventIndex,
		Timestamp = tick(),
		FormattedTime = os.date("%H:%M:%S"),
		Category = category,
		EventType = eventType,
		PlayerName = player and player.Name or "System",
		PlayerUserId = player and player.UserId or 0,
		Details = details or {},
		LogLevel = details and details.LogLevel or 2,
	}
	
	return event
end

-- Event'i kaydet
local function StoreEvent(event)
	table.insert(EventLog, event)
	
	-- Maksimum sayıyı aşarsa eski event'leri sil
	if #EventLog > EventLogger.Config.MaxStoredEvents then
		table.remove(EventLog, 1)
	end
end

-- =============================================================================
-- [[ ANA LOG FONKSİYONU ]]
-- =============================================================================

function EventLogger.LogEvent(player, category, eventType, details)
	if not EventLogger.Config.Enabled then return end
	
	-- Kategori kontrolü
	if not EventLogger.Config.EnabledCategories[category] then
		return
	end
	
	-- Event oluştur
	local event = CreateEvent(player, category, eventType, details)
	
	-- Log level kontrolü
	if event.LogLevel < EventLogger.Config.MinLogLevel then
		return
	end
	
	-- Kaydet
	StoreEvent(event)
	
	-- Console'a yaz
	if EventLogger.Config.LogToConsole then
		local logMessage = string.format("[%s] %s - %s: %s", 
			event.FormattedTime, 
			event.Category, 
			event.PlayerName, 
			eventType)
		
		if details then
			logMessage = logMessage .. " | " .. HttpService:JSONEncode(details)
		end
		
		DebugConfig.Info("EventLogger", logMessage)
	end
	
	-- Admin'lere broadcast
	if EventLogger.Config.BroadcastToAdmins then
		EventLogger.BroadcastEvent(event)
	end
	
	return event
end

-- =============================================================================
-- [[ BROADCAST SİSTEMİ ]]
-- =============================================================================

-- Admin oyuncuları bul
local function GetAdminPlayers()
	local admins = {}
	
	for _, player in ipairs(Players:GetPlayers()) do
		-- Admin kontrolü (özelleştirilebilir)
		if player:GetRankInGroup(0) >= 255 or player.UserId == 1 then
			table.insert(admins, player)
		end
		
		-- Attribute kontrolü
		if player:GetAttribute("IsAdmin") == true then
			table.insert(admins, player)
		end
	end
	
	return admins
end

-- Event'i admin'lere gönder
function EventLogger.BroadcastEvent(event)
	local admins = GetAdminPlayers()
	
	for _, admin in ipairs(admins) do
		task.spawn(function()
			local success, err = pcall(function()
				EventLogRemote:FireClient(admin, event)
			end)
			
			if not success then
				DebugConfig.Warning("EventLogger", 
					string.format("Failed to broadcast to %s: %s", admin.Name, tostring(err)))
			end
		end)
	end
end

-- Tüm log'ları bir admin'e gönder (bağlantı kurulduğunda)
function EventLogger.SendLogHistory(player)
	if not player:GetAttribute("IsAdmin") then return end
	
	DebugConfig.Info("EventLogger", 
		string.format("Sending log history to %s (%d events)", player.Name, #EventLog), 
		player.Name)
	
	-- Batch olarak gönder (tek seferde çok fazla veri göndermemek için)
	local batchSize = 50
	for i = 1, #EventLog, batchSize do
		local batch = {}
		for j = i, math.min(i + batchSize - 1, #EventLog) do
			table.insert(batch, EventLog[j])
		end
		
		task.spawn(function()
			local success, err = pcall(function()
				EventLogRemote:FireClient(player, {
					Type = "History",
					Events = batch
				})
			end)
			
			if not success then
				DebugConfig.Warning("EventLogger", 
					string.format("Failed to send history to %s: %s", player.Name, tostring(err)))
			end
		end)
		
		task.wait(0.1) -- Rate limiting
	end
end

-- =============================================================================
-- [[ ÖZEL EVENT FONKSİYONLARI ]]
-- =============================================================================

function EventLogger.LogPlayerJoin(player)
	EventLogger.LogEvent(player, "PlayerJoin", "PlayerJoined", {
		AccountAge = player.AccountAge,
		UserId = player.UserId,
		LogLevel = 2,
	})
end

function EventLogger.LogPlayerLeave(player)
	EventLogger.LogEvent(player, "PlayerLeave", "PlayerLeft", {
		SessionLength = tick() - (player:GetAttribute("JoinTime") or tick()),
		LogLevel = 2,
	})
end

function EventLogger.LogStatChange(player, statName, oldValue, newValue)
	EventLogger.LogEvent(player, "StatChange", "StatChanged", {
		Stat = statName,
		OldValue = oldValue,
		NewValue = newValue,
		Change = newValue - oldValue,
		LogLevel = 1,
	})
end

function EventLogger.LogPotionUse(player, potionType, duration)
	EventLogger.LogEvent(player, "PotionUse", "PotionActivated", {
		PotionType = potionType,
		Duration = duration,
		LogLevel = 2,
	})
end

function EventLogger.LogAuraGain(player, amount, source)
	EventLogger.LogEvent(player, "AuraGain", "AuraGained", {
		Amount = amount,
		Source = source,
		LogLevel = 2,
	})
end

function EventLogger.LogAntiCheat(player, reason, details)
	EventLogger.LogEvent(player, "AntiCheat", reason, {
		Details = details,
		LogLevel = 3, -- Critical
	})
end

function EventLogger.LogAdminAction(admin, action, target, details)
	EventLogger.LogEvent(admin, "AdminAction", action, {
		TargetPlayer = target and target.Name or "None",
		Details = details,
		LogLevel = 3,
	})
end

function EventLogger.LogRebirth(player, newRebirthCount)
	EventLogger.LogEvent(player, "Rebirth", "RebirthCompleted", {
		NewRebirthCount = newRebirthCount,
		LogLevel = 2,
	})
end

function EventLogger.LogSpin(player, reward, rarity)
	EventLogger.LogEvent(player, "Spin", "SpinCompleted", {
		Reward = reward,
		Rarity = rarity,
		LogLevel = 1,
	})
end

function EventLogger.LogError(player, errorType, errorMessage)
	EventLogger.LogEvent(player, "Error", errorType, {
		ErrorMessage = errorMessage,
		LogLevel = 3,
	})
end

-- =============================================================================
-- [[ SORGU FONKSİYONLARI ]]
-- =============================================================================

-- Son N event'i al
function EventLogger.GetRecentEvents(count)
	count = count or 50
	local startIndex = math.max(1, #EventLog - count + 1)
	local events = {}
	
	for i = startIndex, #EventLog do
		table.insert(events, EventLog[i])
	end
	
	return events
end

-- Belirli bir oyuncunun event'lerini al
function EventLogger.GetPlayerEvents(playerUserId, count)
	count = count or 50
	local events = {}
	
	for i = #EventLog, 1, -1 do
		if EventLog[i].PlayerUserId == playerUserId then
			table.insert(events, 1, EventLog[i])
			if #events >= count then break end
		end
	end
	
	return events
end

-- Belirli bir kategorinin event'lerini al
function EventLogger.GetCategoryEvents(category, count)
	count = count or 50
	local events = {}
	
	for i = #EventLog, 1, -1 do
		if EventLog[i].Category == category then
			table.insert(events, 1, EventLog[i])
			if #events >= count then break end
		end
	end
	
	return events
end

-- Tüm event'leri temizle
function EventLogger.ClearLogs()
	EventLog = {}
	EventIndex = 0
	DebugConfig.Info("EventLogger", "All logs cleared")
end

-- =============================================================================
-- [[ BAŞLATMA ]]
-- =============================================================================

function EventLogger.Initialize()
	DebugConfig.Info("EventLogger", "Initializing Event Logger...")
	
	-- Oyuncu join/leave event'leri
	Players.PlayerAdded:Connect(function(player)
		player:SetAttribute("JoinTime", tick())
		EventLogger.LogPlayerJoin(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		EventLogger.LogPlayerLeave(player)
	end)
	
	-- Remote event handler (Admin'lerden gelen istekler)
	EventLogRemote.OnServerEvent:Connect(function(player, action, ...)
		if not player:GetAttribute("IsAdmin") then return end
		
		if action == "RequestHistory" then
			EventLogger.SendLogHistory(player)
		elseif action == "ClearLogs" then
			EventLogger.ClearLogs()
			EventLogger.LogAdminAction(player, "ClearedLogs", nil, {})
		end
	end)
	
	DebugConfig.Info("EventLogger", "Event Logger Initialized Successfully ✅")
end

-- =============================================================================
-- [[ BİLGİ FONKSİYONLARI ]]
-- =============================================================================

function EventLogger.GetStats()
	return {
		TotalEvents = EventIndex,
		StoredEvents = #EventLog,
		Categories = EventLogger.Config.EnabledCategories,
	}
end

function EventLogger.PrintStats()
	local stats = EventLogger.GetStats()
	print("=== EVENT LOGGER İSTATİSTİKLER ===")
	print("Total Events:", stats.TotalEvents)
	print("Stored Events:", stats.StoredEvents)
	print("Max Storage:", EventLogger.Config.MaxStoredEvents)
	print("=====================================")
end

return EventLogger
