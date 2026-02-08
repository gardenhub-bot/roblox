-- EventManager.lua v9 COMPLETE (ModuleScript)
-- Location: ReplicatedStorage > Modules > EventManager
-- VFX + Sky + Atmosphere + Lighting + Sound + Doğru bildirim yazıları

local EventManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local function GetOrCreate(className, name)
	local obj = Remotes:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = Remotes
	end
	return obj
end

local JoinEvent = GetOrCreate("RemoteEvent", "JoinEvent")
local NotificationEvent = GetOrCreate("RemoteEvent", "GameNotification")
local UpdateTimer = GetOrCreate("RemoteEvent", "UpdateTimer")
local ExitEvent = GetOrCreate("RemoteEvent", "ExitDungeon")
local UpdateGameStats = GetOrCreate("RemoteEvent", "UpdateGameStats")
local ShowReward = GetOrCreate("RemoteEvent", "ShowReward")
local AdminControlBindable = GetOrCreate("BindableEvent", "AdminControlBindable")
local EventStartBindable = GetOrCreate("BindableEvent", "EventStartBindable")
local EventStopBindable = GetOrCreate("BindableEvent", "EventStopBindable")
local Announcement = GetOrCreate("RemoteEvent", "Announcement")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local EventConfig = require(Modules:WaitForChild("EventConfig"))

local EventSystemFolder = ServerScriptService:WaitForChild("EventSystem")
local BossManager = require(EventSystemFolder:WaitForChild("BossManager"))
local DungeonManager = require(EventSystemFolder:WaitForChild("DungeonManager"))

-- ============================================================================
-- VFX SYSTEM
-- ============================================================================
local EventVFXFolder = ReplicatedStorage:FindFirstChild("EventVFX")

local originalLighting = {}
local originalAtmosphere = nil
local originalSky = nil
local activeVFXSound = nil
local activeVFXParticles = {}
local activeVFXPointLights = {}
local vfxApplied = false

local function SaveOriginalLighting()
	if next(originalLighting) then return end
	originalLighting = {
		Ambient = Lighting.Ambient,
		Brightness = Lighting.Brightness,
		OutdoorAmbient = Lighting.OutdoorAmbient,
	}
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		originalAtmosphere = {
			Color = atm.Color,
			Density = atm.Density,
			Glare = atm.Glare,
		}
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		originalSky = sky:Clone()
	end
end

local function RestoreOriginalLighting()
	if originalLighting.Ambient then
		Lighting.Ambient = originalLighting.Ambient
		Lighting.Brightness = originalLighting.Brightness
		Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
	end

	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm and originalAtmosphere then
		atm.Color = originalAtmosphere.Color
		atm.Density = originalAtmosphere.Density
		atm.Glare = originalAtmosphere.Glare
	end

	-- Sky'ı geri yükle
	local currentSky = Lighting:FindFirstChildOfClass("Sky")
	if currentSky then
		if currentSky:GetAttribute("EventSky") then
			currentSky:Destroy()
			if originalSky then
				local restored = originalSky:Clone()
				restored.Parent = Lighting
			end
		end
	end
end

local function ApplyVFX(eventKey)
	if not EventVFXFolder then return end
	local vfxData = EventVFXFolder:FindFirstChild(eventKey)
	if not vfxData then return end

	SaveOriginalLighting()
	vfxApplied = true

	-- Sky
	local skyObj = vfxData:FindFirstChild("Sky")
	if skyObj and skyObj:IsA("Sky") then
		local currentSky = Lighting:FindFirstChildOfClass("Sky")
		if currentSky then currentSky:Destroy() end
		local newSky = skyObj:Clone()
		newSky:SetAttribute("EventSky", true)
		newSky.Parent = Lighting
	end

	-- AtmosphereConfig
	local atmConfig = vfxData:FindFirstChild("AtmosphereConfig")
	if atmConfig then
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			local colorVal = atmConfig:FindFirstChild("Color")
			if colorVal then atm.Color = colorVal.Value end
			local densityVal = atmConfig:FindFirstChild("Density")
			if densityVal then atm.Density = densityVal.Value end
			local glareVal = atmConfig:FindFirstChild("Glare")
			if glareVal then atm.Glare = glareVal.Value end
		end
	end

	-- LightingConfig
	local lightConfig = vfxData:FindFirstChild("LightingConfig")
	if lightConfig then
		local ambientVal = lightConfig:FindFirstChild("Ambient")
		if ambientVal then Lighting.Ambient = ambientVal.Value end
		local brightnessVal = lightConfig:FindFirstChild("Brightness")
		if brightnessVal then Lighting.Brightness = brightnessVal.Value end
		local outdoorVal = lightConfig:FindFirstChild("OutdoorAmbient")
		if outdoorVal then Lighting.OutdoorAmbient = outdoorVal.Value end
	end

	-- Sound
	local soundObj = vfxData:FindFirstChild("Sound")
	if soundObj and soundObj:IsA("Sound") then
		if activeVFXSound then
			activeVFXSound:Stop()
			activeVFXSound:Destroy()
		end
		activeVFXSound = soundObj:Clone()
		activeVFXSound.Parent = SoundService
		activeVFXSound.Looped = true
		activeVFXSound:Play()
	end

	-- ParticleEmitter (workspace'e ekle - tüm oyuncular görsün)
	local particleObj = vfxData:FindFirstChild("ParticleEmitter")
	if particleObj and particleObj:IsA("ParticleEmitter") then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local pe = particleObj:Clone()
					pe.Name = "EventParticle"
					pe:SetAttribute("EventVFX", true)
					pe.Parent = player.Character.HumanoidRootPart
					table.insert(activeVFXParticles, pe)
				end
			end)
		end
	end

	-- PointLight
	local pointLightObj = vfxData:FindFirstChild("PointLight")
	if pointLightObj and pointLightObj:IsA("PointLight") then
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local pl = pointLightObj:Clone()
					pl.Name = "EventPointLight"
					pl:SetAttribute("EventVFX", true)
					pl.Parent = player.Character.HumanoidRootPart
					table.insert(activeVFXPointLights, pl)
				end
			end)
		end
	end
end

local function RemoveVFX()
	if not vfxApplied then return end
	vfxApplied = false

	RestoreOriginalLighting()

	if activeVFXSound then
		activeVFXSound:Stop()
		activeVFXSound:Destroy()
		activeVFXSound = nil
	end

	for _, pe in ipairs(activeVFXParticles) do
		if pe and pe.Parent then pe:Destroy() end
	end
	activeVFXParticles = {}

	for _, pl in ipairs(activeVFXPointLights) do
		if pl and pl.Parent then pl:Destroy() end
	end
	activeVFXPointLights = {}

	-- Workspace'teki tüm EventVFX attribute'lu şeyleri temizle
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local hrp = player.Character.HumanoidRootPart
				for _, child in pairs(hrp:GetChildren()) do
					if child:GetAttribute("EventVFX") then child:Destroy() end
				end
			end
		end)
	end
end

-- Yeni oyuncu geldiğinde aktif VFX'i uygula
local function ApplyVFXToNewPlayer(player, eventKey)
	if not EventVFXFolder or not eventKey then return end
	local vfxData = EventVFXFolder:FindFirstChild(eventKey)
	if not vfxData then return end

	task.wait(3)

	pcall(function()
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart

			local particleObj = vfxData:FindFirstChild("ParticleEmitter")
			if particleObj and particleObj:IsA("ParticleEmitter") then
				local pe = particleObj:Clone()
				pe.Name = "EventParticle"
				pe:SetAttribute("EventVFX", true)
				pe.Parent = hrp
				table.insert(activeVFXParticles, pe)
			end

			local pointLightObj = vfxData:FindFirstChild("PointLight")
			if pointLightObj and pointLightObj:IsA("PointLight") then
				local pl = pointLightObj:Clone()
				pl.Name = "EventPointLight"
				pl:SetAttribute("EventVFX", true)
				pl.Parent = hrp
				table.insert(activeVFXPointLights, pl)
			end
		end
	end)
end

-- ============================================================================
-- BUFF EVENTS (Doğru isimler ve değerler)
-- ============================================================================
local BuffEvents = {
	["2xIQ"] = {
		Name = "IQ Boost",
		DisplayText = "+50% IQ Boost",
		DefaultDuration = 1800,
		AttributeName = "EventIQBonus",
		Multiplier = 1.5,
		Preset = "Neon",
	},
	["2xCoins"] = {
		Name = "Coins Boost",
		DisplayText = "+50% Coins Boost",
		DefaultDuration = 1800,
		AttributeName = "EventCoinsBonus",
		Multiplier = 1.5,
		Preset = "Golden",
	},
	["LuckyHour"] = {
		Name = "Lucky Hour",
		DisplayText = "Lucky Hour (+0.1 Luck)",
		DefaultDuration = 3600,
		AttributeName = "EventLuckBonus",
		Additive = 0.1,
		Preset = "Success",
	},
	["SpeedFrenzy"] = {
		Name = "Speed Frenzy",
		DisplayText = "+50% Speed Frenzy",
		DefaultDuration = 900,
		AttributeName = "EventSpeedBonus",
		Multiplier = 1.5,
		Preset = "Ice",
	},
	["GoldenRush"] = {
		Name = "Golden Rush",
		DisplayText = "+50% Coins Golden Rush",
		DefaultDuration = 600,
		AttributeName = "EventCoinsBonus",
		Multiplier = 1.5,
		Preset = "Golden",
	},
	["RainbowStars"] = {
		Name = "Rainbow Stars",
		DisplayText = "+25% All Stats Rainbow Stars",
		DefaultDuration = 1800,
		AttributeName = "EventAllBonus",
		Multiplier = 1.25,
		Preset = "Royal",
	},
	["EssenceRain"] = {
		Name = "Essence Rain",
		DisplayText = "+50% Essence Rain",
		DefaultDuration = 600,
		AttributeName = "EventEssenceBonus",
		Multiplier = 1.5,
		Preset = "Royal",
	},
}

local isDungeonOpen = false
local isBossOpen = false
local dungeonQueue = {}
local bossQueue = {}
local adminOverride = false

local activeEventKey = nil
local activeEventConfig = nil
local eventEndTime = 0
local eventThread = nil

local function CountTable(t)
	local c = 0
	for _ in pairs(t) do c = c + 1 end
	return c
end

local function SendAnnouncement(message, preset, duration)
	local data = {Type = "Announcement", Message = message, Preset = preset or "Fire", Duration = duration or 6}
	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function() Announcement:FireClient(p, data) end)
	end
end

local function SendAnnouncementToPlayer(player, message, preset, duration)
	pcall(function()
		Announcement:FireClient(player, {Type = "Announcement", Message = message, Preset = preset or "Fire", Duration = duration or 6})
	end)
end

local function SyncAttributes()
	if activeEventKey then
		ReplicatedStorage:SetAttribute("ActiveEventKey", activeEventKey)
		ReplicatedStorage:SetAttribute("EventEndTime", eventEndTime)
	else
		ReplicatedStorage:SetAttribute("ActiveEventKey", "")
		ReplicatedStorage:SetAttribute("EventEndTime", 0)
	end
end

local function ApplyEventToPlayer(player, config)
	pcall(function()
		if config.Multiplier then
			player:SetAttribute(config.AttributeName, config.Multiplier)
		elseif config.Additive then
			local current = player:GetAttribute(config.AttributeName) or 0
			player:SetAttribute(config.AttributeName, current + config.Additive)
		end
	end)
end

local function RemoveEventFromPlayer(player, config)
	pcall(function()
		if config.Multiplier then
			player:SetAttribute(config.AttributeName, 1)
		elseif config.Additive then
			local current = player:GetAttribute(config.AttributeName) or 0
			player:SetAttribute(config.AttributeName, math.max(0, current - config.Additive))
		end
	end)
end

local function StopEventInternal()
	local config = activeEventConfig
	if not config then return false, "No active event" end
	local displayText = config.DisplayText or config.Name

	for _, player in ipairs(Players:GetPlayers()) do
		RemoveEventFromPlayer(player, config)
	end

	if eventThread then
		pcall(function() task.cancel(eventThread) end)
		eventThread = nil
	end

	RemoveVFX()

	local stoppedKey = activeEventKey
	activeEventKey = nil
	activeEventConfig = nil
	eventEndTime = 0
	SyncAttributes()

	SendAnnouncement(displayText .. " has ended!", "Alert", 5)
	print("[EventManager] Stopped:", displayText)
	return true, displayText .. " stopped!"
end

function EventManager.StartEvent(eventKey, customDuration)
	local config = BuffEvents[eventKey]
	if not config then return false, "Unknown event: " .. tostring(eventKey) end

	if activeEventKey then
		StopEventInternal()
		task.wait(0.5)
	end

	local duration = customDuration or config.DefaultDuration
	activeEventKey = eventKey
	activeEventConfig = config
	eventEndTime = tick() + duration
	SyncAttributes()

	for _, player in ipairs(Players:GetPlayers()) do
		ApplyEventToPlayer(player, config)
	end

	ApplyVFX(eventKey)

	local mins = math.floor(duration / 60)
	local displayText = config.DisplayText or config.Name
	SendAnnouncement(displayText .. " started! Duration: " .. mins .. " minutes", config.Preset or "Fire", 8)

	if eventThread then
		pcall(function() task.cancel(eventThread) end)
	end

	eventThread = task.spawn(function()
		while tick() < eventEndTime do
			local remaining = math.floor(eventEndTime - tick())
			SyncAttributes()
			if remaining == 300 then
				SendAnnouncement(displayText .. " — 5 minutes remaining!", config.Preset, 5)
			elseif remaining == 180 then
				SendAnnouncement(displayText .. " — 3 minutes remaining!", config.Preset, 5)
			elseif remaining == 60 then
				SendAnnouncement(displayText .. " — 1 minute remaining!", "Alert", 5)
			elseif remaining == 30 then
				SendAnnouncement(displayText .. " — 30 seconds remaining!", "Alert", 5)
			elseif remaining == 10 then
				SendAnnouncement(displayText .. " — 10 seconds!", "Alert", 4)
			end
			task.wait(1)
		end
		StopEventInternal()
	end)

	print("[EventManager] Started:", displayText, "for", mins, "minutes")
	return true, displayText .. " started for " .. mins .. " minutes!"
end

function EventManager.StopEvent(eventKey)
	return StopEventInternal()
end

function EventManager.GetActiveEvent() return activeEventKey end
function EventManager.GetEventRemainingTime()
	if not activeEventKey then return 0 end
	return math.max(0, eventEndTime - tick())
end

-- ============================================================================
-- PLAYER ADDED
-- ============================================================================
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	if activeEventConfig and activeEventKey then
		ApplyEventToPlayer(player, activeEventConfig)
		ApplyVFXToNewPlayer(player, activeEventKey)
		local remaining = math.floor(math.max(0, eventEndTime - tick()))
		if remaining > 0 then
			local displayText = activeEventConfig.DisplayText or activeEventConfig.Name
			SendAnnouncementToPlayer(player, displayText .. " is active! " .. math.floor(remaining / 60) .. " min remaining", activeEventConfig.Preset or "Fire", 6)
		end
	end

	-- Respawn'da VFX'i tekrar uygula
	player.CharacterAdded:Connect(function(character)
		task.wait(2)
		if activeEventKey and vfxApplied then
			ApplyVFXToNewPlayer(player, activeEventKey)
		end
	end)
end)

-- ============================================================================
-- BINDABLES
-- ============================================================================
EventStartBindable.Event:Connect(function(eventKey, duration)
	EventManager.StartEvent(eventKey, duration)
end)

EventStopBindable.Event:Connect(function(eventKey)
	EventManager.StopEvent(eventKey)
end)

-- ============================================================================
-- DUNGEON/BOSS QUEUE
-- ============================================================================
JoinEvent.OnServerEvent:Connect(function(player, mode)
	if mode == "Dungeon" then
		if not isDungeonOpen then
			SendAnnouncementToPlayer(player, "Dungeon is closed! Wait for the next opening.", "Alert", 4)
			return
		end
		bossQueue[player.UserId] = nil
		dungeonQueue[player.UserId] = player
		local total = CountTable(dungeonQueue)
		SendAnnouncementToPlayer(player, "You joined the Dungeon queue! Players: " .. total, "Success", 5)
		SendAnnouncement(player.Name .. " joined Dungeon queue! Total players: " .. total, "Neon", 4)
		print("[EventManager]", player.Name, "joined Dungeon queue. Total:", total)

	elseif mode == "Boss" then
		if not isBossOpen then
			SendAnnouncementToPlayer(player, "Boss Trial is closed! Wait for the next opening.", "Alert", 4)
			return
		end
		dungeonQueue[player.UserId] = nil
		bossQueue[player.UserId] = player
		local total = CountTable(bossQueue)
		SendAnnouncementToPlayer(player, "You joined the Boss Trial queue! Players: " .. total, "Success", 5)
		SendAnnouncement(player.Name .. " joined Boss Trial queue! Total players: " .. total, "Royal", 4)
		print("[EventManager]", player.Name, "joined Boss queue. Total:", total)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	dungeonQueue[player.UserId] = nil
	bossQueue[player.UserId] = nil
	pcall(function() DungeonManager.RemovePlayer(player, "Exit") end)
	pcall(function() BossManager.RemovePlayer(player, "End") end)
end)

ExitEvent.OnServerEvent:Connect(function(player)
	if DungeonManager.IsPlayerInGame(player) then
		DungeonManager.RemovePlayer(player, "Exit")
		return
	end
	if BossManager.IsPlayerInGame(player) then
		BossManager.RemovePlayer(player, "Exit")
		return
	end
end)

-- ============================================================================
-- ADMIN FORCE START
-- ============================================================================
AdminControlBindable.Event:Connect(function(player, action, value)
	if action == "SetTime" then
		if value == "StartDungeon" then
			adminOverride = true
			isDungeonOpen = true

			SendAnnouncement("ADMIN: Dungeon portals are OPEN! 60 seconds to join!", "Fire", 8)
			UpdateTimer:FireAllClients("Dungeon", 0, true)

			task.delay(30, function()
				if adminOverride and isDungeonOpen then
					SendAnnouncement("DUNGEON — 30 seconds to join!", "Fire", 5)
				end
			end)
			task.delay(50, function()
				if adminOverride and isDungeonOpen then
					SendAnnouncement("DUNGEON — 10 seconds to join!", "Alert", 4)
				end
			end)
			task.delay(55, function()
				if adminOverride and isDungeonOpen then
					SendAnnouncement("DUNGEON — 5 seconds!", "Alert", 3)
				end
			end)

			task.delay(60, function()
				isDungeonOpen = false
				adminOverride = false

				local count = CountTable(dungeonQueue)
				if next(dungeonQueue) then
					SendAnnouncement("DUNGEON STARTED! " .. count .. " players entering!", "Alert", 6)
					DungeonManager.Start(dungeonQueue)
				else
					SendAnnouncement("Dungeon cancelled — no players joined.", "Dark", 5)
				end
				dungeonQueue = {}
				UpdateTimer:FireAllClients("Dungeon", EventConfig.DungeonStartMinute, false)
			end)

		elseif value == "StartBoss" then
			adminOverride = true
			isBossOpen = true

			SendAnnouncement("ADMIN: Boss Trial portals are OPEN! 60 seconds to join!", "Royal", 8)
			UpdateTimer:FireAllClients("Boss", 0, true)

			task.delay(30, function()
				if adminOverride and isBossOpen then
					SendAnnouncement("BOSS TRIAL — 30 seconds to join!", "Royal", 5)
				end
			end)
			task.delay(50, function()
				if adminOverride and isBossOpen then
					SendAnnouncement("BOSS TRIAL — 10 seconds to join!", "Alert", 4)
				end
			end)
			task.delay(55, function()
				if adminOverride and isBossOpen then
					SendAnnouncement("BOSS TRIAL — 5 seconds!", "Alert", 3)
				end
			end)

			task.delay(60, function()
				isBossOpen = false
				adminOverride = false

				local count = CountTable(bossQueue)
				if next(bossQueue) then
					SendAnnouncement("BOSS TRIAL STARTED! " .. count .. " players entering!", "Alert", 6)
					BossManager.Start(bossQueue)
				else
					SendAnnouncement("Boss Trial cancelled — no players joined.", "Dark", 5)
				end
				bossQueue = {}
				UpdateTimer:FireAllClients("Boss", EventConfig.BossStartMinute, false)
			end)
		end
	end
end)

-- ============================================================================
-- AUTOMATIC TIME-BASED
-- ============================================================================
local dungeonNotified = false
local bossNotified = false
local dungeonCountdowns = {}
local bossCountdowns = {}

task.spawn(function()
	while true do
		if not adminOverride then
			local date = os.date("!*t")
			local min = date.min
			local sec = date.sec

			local dStart = EventConfig.DungeonStartMinute
			local dOpenTime = (dStart - 5) % 60

			local isDungeonTime = false
			if dOpenTime < dStart then
				if min >= dOpenTime and min < dStart then isDungeonTime = true end
			else
				if min >= dOpenTime or min < dStart then isDungeonTime = true end
			end

			if isDungeonTime then
				if not isDungeonOpen then
					isDungeonOpen = true
					dungeonNotified = false
					dungeonCountdowns = {}
				end

				local secsLeft
				if dStart > min then
					secsLeft = (dStart - min) * 60 - sec
				else
					secsLeft = (60 - min + dStart) * 60 - sec
				end

				if not dungeonNotified then
					dungeonNotified = true
					SendAnnouncement("DUNGEON portals are OPEN! " .. math.floor(secsLeft / 60) .. " minutes to join!", "Fire", 8)
				end

				if secsLeft <= 180 and secsLeft > 179 and not dungeonCountdowns["3m"] then
					dungeonCountdowns["3m"] = true
					SendAnnouncement("DUNGEON — 3 minutes remaining!", "Fire", 5)
				end
				if secsLeft <= 60 and secsLeft > 59 and not dungeonCountdowns["1m"] then
					dungeonCountdowns["1m"] = true
					SendAnnouncement("DUNGEON — 1 minute remaining!", "Alert", 5)
				end
				if secsLeft <= 30 and secsLeft > 29 and not dungeonCountdowns["30s"] then
					dungeonCountdowns["30s"] = true
					SendAnnouncement("DUNGEON — 30 seconds!", "Alert", 4)
				end

			elseif min == dStart and sec == 0 then
				if isDungeonOpen then
					isDungeonOpen = false
					dungeonNotified = false
					dungeonCountdowns = {}

					local count = CountTable(dungeonQueue)
					if next(dungeonQueue) then
						SendAnnouncement("DUNGEON STARTED! " .. count .. " players entering!", "Alert", 6)
						DungeonManager.Start(dungeonQueue)
					end
					dungeonQueue = {}
				end
			elseif not isDungeonTime then
				if isDungeonOpen and not adminOverride then
					isDungeonOpen = false
					dungeonNotified = false
					dungeonCountdowns = {}
				end
			end

			local bStart = EventConfig.BossStartMinute
			local bOpenTime = (bStart - 5) % 60

			local isBossTime = false
			if bOpenTime < bStart then
				if min >= bOpenTime and min < bStart then isBossTime = true end
			else
				if min >= bOpenTime or min < bStart then isBossTime = true end
			end

			if isBossTime then
				if not isBossOpen then
					isBossOpen = true
					bossNotified = false
					bossCountdowns = {}
				end

				local secsLeft
				if bStart > min then
					secsLeft = (bStart - min) * 60 - sec
				else
					secsLeft = (60 - min + bStart) * 60 - sec
				end

				if not bossNotified then
					bossNotified = true
					SendAnnouncement("BOSS TRIAL portals are OPEN! " .. math.floor(secsLeft / 60) .. " minutes to join!", "Royal", 8)
				end

				if secsLeft <= 180 and secsLeft > 179 and not bossCountdowns["3m"] then
					bossCountdowns["3m"] = true
					SendAnnouncement("BOSS TRIAL — 3 minutes remaining!", "Royal", 5)
				end
				if secsLeft <= 60 and secsLeft > 59 and not bossCountdowns["1m"] then
					bossCountdowns["1m"] = true
					SendAnnouncement("BOSS TRIAL — 1 minute remaining!", "Alert", 5)
				end
				if secsLeft <= 30 and secsLeft > 29 and not bossCountdowns["30s"] then
					bossCountdowns["30s"] = true
					SendAnnouncement("BOSS TRIAL — 30 seconds!", "Alert", 4)
				end

			elseif min == bStart and sec == 0 then
				if isBossOpen then
					isBossOpen = false
					bossNotified = false
					bossCountdowns = {}

					local count = CountTable(bossQueue)
					if next(bossQueue) then
						SendAnnouncement("BOSS TRIAL STARTED! " .. count .. " players entering!", "Alert", 6)
						BossManager.Start(bossQueue)
					end
					bossQueue = {}
				end
			elseif not isBossTime then
				if isBossOpen and not adminOverride then
					isBossOpen = false
					bossNotified = false
					bossCountdowns = {}
				end
			end
		end

		task.wait(1)
	end
end)

function EventManager.GetDungeonOpen() return isDungeonOpen end
function EventManager.GetBossOpen() return isBossOpen end
function EventManager.GetDungeonQueueCount() return CountTable(dungeonQueue) end
function EventManager.GetBossQueueCount() return CountTable(bossQueue) end

print("[EventManager] v9 loaded! (VFX + Correct names)")

return EventManager