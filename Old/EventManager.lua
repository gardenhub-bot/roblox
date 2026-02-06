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
