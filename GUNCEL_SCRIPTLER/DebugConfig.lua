-- DebugConfig.lua
-- Konum: ReplicatedStorage -> Modules
-- Gelişmiş Debug/Print Ayarları Modülü

local DebugConfig = {}

-- =============================================================================
-- [[ DEBUG AYARLARI ]]
-- =============================================================================

-- Ana Debug Seviyeleri
DebugConfig.Settings = {
	-- Genel Debug Kontrolü
	MasterDebugEnabled = true, -- Ana debug anahtarı (tüm debug'ları kapatır)
	
	-- Debug Seviyeleri
	EnableInfo = true,        -- Bilgilendirme mesajları
	EnableWarning = true,     -- Uyarı mesajları
	EnableError = true,       -- Hata mesajları
	EnableVerbose = false,    -- Detaylı log mesajları
	
	-- Sistem Bazlı Debug
	DebugSystems = {
		AdminManager = true,      -- Admin sistem debug'ı
		AdminClient = true,       -- Admin UI debug'ı
		AntiCheat = true,         -- Anti-cheat sistem debug'ı
		EventLogger = true,       -- Event log debug'ı
		StatManager = true,       -- Stat yönetim debug'ı
		PotionManager = true,     -- İksir yönetim debug'ı
		AuraSystem = true,        -- Aura sistem debug'ı
		DataStore = false,        -- DataStore işlemleri (çok fazla log)
		RemoteEvents = false,     -- Remote event çağrıları
	},
	
	-- Özel Filtreler
	ShowPlayerNames = true,      -- Oyuncu adlarını göster
	ShowTimestamps = true,       -- Zaman damgası göster
	ShowStackTrace = false,      -- Stack trace göster (hata ayıklama için)
	
	-- Performans
	MaxLogsPerSecond = 50,      -- Saniyede maksimum log sayısı (spam önleme)
	LogBufferSize = 100,        -- Bellekte tutulacak log sayısı
}

-- =============================================================================
-- [[ RENK KODLARI ]]
-- =============================================================================

DebugConfig.Colors = {
	Info = Color3.fromRGB(100, 200, 255),    -- Mavi
	Warning = Color3.fromRGB(255, 200, 50),  -- Sarı
	Error = Color3.fromRGB(255, 100, 100),   -- Kırmızı
	Success = Color3.fromRGB(100, 255, 150), -- Yeşil
	Verbose = Color3.fromRGB(200, 200, 200), -- Gri
	Critical = Color3.fromRGB(255, 50, 50),  -- Koyu Kırmızı
}

-- =============================================================================
-- [[ LOG SEVİYE ENUMları ]]
-- =============================================================================

DebugConfig.LogLevel = {
	VERBOSE = 1,
	INFO = 2,
	WARNING = 3,
	ERROR = 4,
	CRITICAL = 5,
}

-- =============================================================================
-- [[ YARDıMCı FONKSİYONLAR ]]
-- =============================================================================

local lastLogTime = 0
local logCount = 0

-- Zaman damgası oluştur
local function GetTimestamp()
	if not DebugConfig.Settings.ShowTimestamps then
		return ""
	end
	local now = os.date("*t")
	return string.format("[%02d:%02d:%02d]", now.hour, now.min, now.sec)
end

-- Rate limiting kontrol
local function CheckRateLimit()
	local now = tick()
	if now - lastLogTime >= 1 then
		lastLogTime = now
		logCount = 0
		return true
	end
	
	logCount = logCount + 1
	if logCount > DebugConfig.Settings.MaxLogsPerSecond then
		return false
	end
	
	return true
end

-- =============================================================================
-- [[ LOG FONKSİYONLARI ]]
-- =============================================================================

-- Genel log fonksiyonu
function DebugConfig.Log(systemName, message, logLevel, playerName)
	-- Master switch kontrolü
	if not DebugConfig.Settings.MasterDebugEnabled then
		return
	end
	
	-- Sistem bazlı kontrol
	if systemName and DebugConfig.Settings.DebugSystems[systemName] == false then
		return
	end
	
	-- Log seviyesi kontrolü
	logLevel = logLevel or DebugConfig.LogLevel.INFO
	if logLevel == DebugConfig.LogLevel.VERBOSE and not DebugConfig.Settings.EnableVerbose then
		return
	end
	if logLevel == DebugConfig.LogLevel.INFO and not DebugConfig.Settings.EnableInfo then
		return
	end
	if logLevel == DebugConfig.LogLevel.WARNING and not DebugConfig.Settings.EnableWarning then
		return
	end
	if logLevel == DebugConfig.LogLevel.ERROR and not DebugConfig.Settings.EnableError then
		return
	end
	
	-- Rate limiting
	if not CheckRateLimit() then
		return
	end
	
	-- Log mesajı oluştur
	local timestamp = GetTimestamp()
	local playerInfo = ""
	if playerName and DebugConfig.Settings.ShowPlayerNames then
		playerInfo = string.format("[%s]", playerName)
	end
	
	local levelText = ""
	if logLevel == DebugConfig.LogLevel.VERBOSE then
		levelText = "[VERBOSE]"
	elseif logLevel == DebugConfig.LogLevel.INFO then
		levelText = "[INFO]"
	elseif logLevel == DebugConfig.LogLevel.WARNING then
		levelText = "[WARNING]"
	elseif logLevel == DebugConfig.LogLevel.ERROR then
		levelText = "[ERROR]"
	elseif logLevel == DebugConfig.LogLevel.CRITICAL then
		levelText = "[CRITICAL]"
	end
	
	local systemInfo = systemName and string.format("[%s]", systemName) or ""
	local fullMessage = string.format("%s%s%s%s %s", 
		timestamp, levelText, systemInfo, playerInfo, message)
	
	-- Yazdır
	if logLevel >= DebugConfig.LogLevel.WARNING then
		warn(fullMessage)
	else
		print(fullMessage)
	end
end

-- Kısayol fonksiyonlar
function DebugConfig.Info(systemName, message, playerName)
	DebugConfig.Log(systemName, message, DebugConfig.LogLevel.INFO, playerName)
end

function DebugConfig.Warning(systemName, message, playerName)
	DebugConfig.Log(systemName, message, DebugConfig.LogLevel.WARNING, playerName)
end

function DebugConfig.Error(systemName, message, playerName)
	DebugConfig.Log(systemName, message, DebugConfig.LogLevel.ERROR, playerName)
end

function DebugConfig.Verbose(systemName, message, playerName)
	DebugConfig.Log(systemName, message, DebugConfig.LogLevel.VERBOSE, playerName)
end

function DebugConfig.Critical(systemName, message, playerName)
	DebugConfig.Log(systemName, message, DebugConfig.LogLevel.CRITICAL, playerName)
end

-- =============================================================================
-- [[ AYARLARI GÜNCELLEfonksiyonu ]]
-- =============================================================================

function DebugConfig.UpdateSettings(newSettings)
	for key, value in pairs(newSettings) do
		if DebugConfig.Settings[key] ~= nil then
			DebugConfig.Settings[key] = value
			DebugConfig.Info("DebugConfig", string.format("Setting updated: %s = %s", key, tostring(value)))
		end
	end
end

function DebugConfig.UpdateSystemDebug(systemName, enabled)
	if DebugConfig.Settings.DebugSystems[systemName] ~= nil then
		DebugConfig.Settings.DebugSystems[systemName] = enabled
		DebugConfig.Info("DebugConfig", string.format("System debug updated: %s = %s", systemName, tostring(enabled)))
	end
end

-- =============================================================================
-- [[ BİLGİ FONKSIYONLARI ]]
-- =============================================================================

function DebugConfig.GetSettings()
	return DebugConfig.Settings
end

function DebugConfig.PrintCurrentSettings()
	print("=== DEBUG AYARLARI ===")
	print("Master Debug:", DebugConfig.Settings.MasterDebugEnabled)
	print("Info:", DebugConfig.Settings.EnableInfo)
	print("Warning:", DebugConfig.Settings.EnableWarning)
	print("Error:", DebugConfig.Settings.EnableError)
	print("Verbose:", DebugConfig.Settings.EnableVerbose)
	print("\n=== SİSTEM DEBUG DURUMLARI ===")
	for system, enabled in pairs(DebugConfig.Settings.DebugSystems) do
		print(string.format("  %s: %s", system, tostring(enabled)))
	end
	print("=====================")
end

-- İlk yüklemede bilgi ver
DebugConfig.Info("DebugConfig", "Debug Config Module Loaded Successfully ✅")

return DebugConfig
