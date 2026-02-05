# AdminManager_FULL.lua - Part 1 (Lines 1-1500)

```lua
-- AdminManager_FULL.lua
-- Tam özellikli admin paneli server scripti
-- 7 event sistemi, stat yönetimi, potion, rot skill, rate limiting, history

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

local AdminManager = {}

-- Configuration
local Config = {
	Admins = {
		-- Admin UserIDs (SuperAdmin level)
		[4221507527] = true,  -- User's ID
		-- Add more admin IDs here
	},
	
	-- Admin Levels
	AdminLevels = {
		SuperAdmin = 3,
		Admin = 2,
		Moderator = 1
	},
	
	-- Rate Limiting
	RateLimiting = {
		Enabled = true,
		MaxCommandsPerMinute = 10,
		TimeWindow = 60
	},
	
	-- Event Settings
	EventSettings = {
		DefaultDuration = 300,  -- 5 minutes
		MinDuration = 60,       -- 1 minute
		MaxDuration = 1800      -- 30 minutes
	},
	
	-- Debug Settings
	Debug = {
		Enabled = true,
		ShowInfo = true,
		ShowWarnings = true,
		ShowErrors = true
	}
}

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AdminCommand = Remotes:WaitForChild("AdminCommand")
local AdminDataUpdate = Remotes:WaitForChild("AdminDataUpdate")
local EventLogUpdate = Remotes:WaitForChild("EventLogUpdate")
local EventVFXTrigger = Remotes:WaitForChild("EventVFXTrigger")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DebugConfig, AntiCheatSystem, EventLogger

-- Safe module loading
local function SafeRequire(module, name)
	local success, result = pcall(function()
		return require(module)
	end)
	if success then
		return result
	else
		warn("[AdminManager] Failed to load " .. name .. ": " .. tostring(result))
		return nil
	end
end

DebugConfig = SafeRequire(Modules:WaitForChild("DebugConfig"), "DebugConfig")
AntiCheatSystem = SafeRequire(Modules:WaitForChild("AntiCheatSystem"), "AntiCheatSystem")
EventLogger = SafeRequire(Modules:WaitForChild("EventLogger"), "EventLogger")

-- Debug Print
local function DebugPrint(message, level)
	if not Config.Debug.Enabled then return end
	level = level or "INFO"
	
	if level == "INFO" and Config.Debug.ShowInfo then
		print("[AdminManager][INFO]", message)
	elseif level == "WARN" and Config.Debug.ShowWarnings then
		warn("[AdminManager][WARN]", message)
	elseif level == "ERROR" and Config.Debug.ShowErrors then
		warn("[AdminManager][ERROR]", message)
	end
end

-- Rate Limiting
local CommandHistory = {}  -- [PlayerUserId] = {timestamps}

local function CheckRateLimit(player)
	if not Config.RateLimiting.Enabled then return true end
	
	local userId = player.UserId
	local currentTime = tick()
	
	if not CommandHistory[userId] then
		CommandHistory[userId] = {}
	end
	
	-- Remove old timestamps
	local history = CommandHistory[userId]
	local newHistory = {}
	for _, timestamp in ipairs(history) do
		if currentTime - timestamp < Config.RateLimiting.TimeWindow then
			table.insert(newHistory, timestamp)
		end
	end
	CommandHistory[userId] = newHistory
	
	-- Check limit
	if #newHistory >= Config.RateLimiting.MaxCommandsPerMinute then
		return false
	end
	
	-- Add current timestamp
	table.insert(CommandHistory[userId], currentTime)
	return true
end

-- Operation History
local OperationHistory = {}  -- Stores last 100 operations
local MaxHistorySize = 100

local function LogOperation(adminPlayer, operation, data)
	local entry = {
		Admin = adminPlayer.Name,
		AdminId = adminPlayer.UserId,
		Operation = operation,
		Data = data,
		Timestamp = os.time(),
		TimeString = os.date("%Y-%m-%d %H:%M:%S")
	}
	
	table.insert(OperationHistory, 1, entry)
	
	-- Keep only last 100
	if #OperationHistory > MaxHistorySize then
		table.remove(OperationHistory)
	end
	
	DebugPrint(string.format("Operation logged: %s by %s", operation, adminPlayer.Name))
	
	-- Also log to EventLogger if available
	if EventLogger then
		pcall(function()
			EventLogger.LogEvent({
				Category = "AdminCommand",
				Message = string.format("%s used %s", adminPlayer.Name, operation),
				Player = adminPlayer,
				Data = data
			})
		end)
	end
end

-- Check if player is admin
local function IsAdmin(player)
	if not player then return false end
	return Config.Admins[player.UserId] == true
end

-- Get Admin Level
local function GetAdminLevel(player)
	if Config.Admins[player.UserId] then
		return Config.AdminLevels.SuperAdmin
	end
	return 0
end

-- Event System
local ActiveEvents = {}  -- [EventName] = {StartTime, Duration, EndTime}

local EventTypes = {
	["2x IQ"] = {
		AttributeName = "IQMultiplier",
		Multiplier = 2,
		Description = "Doubles IQ gain"
	},
	["2x Coins"] = {
		AttributeName = "CoinsMultiplier",
		Multiplier = 2,
		Description = "Doubles coin gain"
	},
	["Lucky Hour"] = {
		AttributeName = "LuckMultiplier",
		Multiplier = 1.5,
		Description = "Boosts luck stat"
	},
	["Speed Frenzy"] = {
		AttributeName = "SpeedMultiplier",
		Multiplier = 1.5,
		Description = "Increases movement speed"
	},
	["Golden Rush"] = {
		AttributeName = "EssenceMultiplier",
		Multiplier = 2,
		Description = "Increases essence gain"
	},
	["Rainbow Stars"] = {
		AttributeName = "AuraMultiplier",
		Multiplier = 2,
		Description = "Boosts aura gain"
	},
	["Essence Rain"] = {
		AttributeName = "EssenceMultiplier",
		Multiplier = 1.5,
		Description = "Essence boost + periodic drops",
		HasPeriodicDrop = true
	}
}

-- Start Event
local function StartEvent(eventName, duration, adminPlayer)
	if not EventTypes[eventName] then
		DebugPrint("Unknown event type: " .. tostring(eventName), "ERROR")
		return false, "Unknown event type"
	end
	
	if ActiveEvents[eventName] then
		return false, "Event already active"
	end
	
	duration = duration or Config.EventSettings.DefaultDuration
	duration = math.clamp(duration, Config.EventSettings.MinDuration, Config.EventSettings.MaxDuration)
	
	local eventData = EventTypes[eventName]
	local startTime = tick()
	local endTime = startTime + duration
	
	ActiveEvents[eventName] = {
		StartTime = startTime,
		Duration = duration,
		EndTime = endTime,
		EventData = eventData
	}
	
	-- Apply multiplier to all players
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			player:SetAttribute(eventData.AttributeName, eventData.Multiplier)
		end)
	end
	
	-- Broadcast VFX trigger to all clients
	pcall(function()
		EventVFXTrigger:FireAllClients({
			Action = "Start",
			EventName = eventName,
			Duration = duration,
			Multiplier = eventData.Multiplier
		})
	end)
	
	-- Log event
	DebugPrint(string.format("Event started: %s for %d seconds", eventName, duration))
	
	if EventLogger then
		pcall(function()
			EventLogger.LogEvent({
				Category = "Event",
				Message = string.format("Event started: %s (%ds)", eventName, duration),
				Player = adminPlayer
			})
		end)
	end
	
	-- Schedule event end
	task.delay(duration, function()
		StopEvent(eventName, true)
	end)
	
	-- Essence Rain periodic drops
	if eventData.HasPeriodicDrop then
		task.spawn(function()
			while ActiveEvents[eventName] do
				task.wait(30)  -- Every 30 seconds
				if ActiveEvents[eventName] then
					for _, player in ipairs(Players:GetPlayers()) do
						pcall(function()
							local leaderstats = player:FindFirstChild("leaderstats")
							if leaderstats then
								local essence = leaderstats:FindFirstChild("Essence")
								if essence then
									essence.Value = essence.Value + 100  -- Drop 100 essence
								end
							end
						end)
					end
				end
			end
		end)
	end
	
	return true, "Event started successfully"
end

-- Stop Event
local function StopEvent(eventName, autoEnd)
	if not ActiveEvents[eventName] then
		return false, "Event not active"
	end
	
	local eventData = ActiveEvents[eventName].EventData
	
	-- Remove multiplier from all players
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(function()
			player:SetAttribute(eventData.AttributeName, 1)
		end)
	end
	
	-- Broadcast VFX trigger
	pcall(function()
		EventVFXTrigger:FireAllClients({
			Action = "Stop",
			EventName = eventName
		})
	end)
	
	ActiveEvents[eventName] = nil
	
	local endReason = autoEnd and "ended automatically" or "stopped manually"
	DebugPrint(string.format("Event %s: %s", endReason, eventName))
	
	if EventLogger then
		pcall(function()
			EventLogger.LogEvent({
				Category = "Event",
				Message = string.format("Event %s: %s", endReason, eventName)
			})
		end)
	end
	
	return true, "Event stopped successfully"
end

-- Get Player by Name
local function GetPlayerByName(name)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == name:lower() or player.DisplayName:lower() == name:lower() then
			return player
		end
	end
	return nil
end

-- Stat Operations
local function AddStat(targetPlayer, statName, amount)
	if not targetPlayer then return false, "Player not found" end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found" end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then return false, "Stat not found: " .. statName end
	
	pcall(function()
		stat.Value = stat.Value + amount
	end)
	
	DebugPrint(string.format("Added %d %s to %s", amount, statName, targetPlayer.Name))
	return true, string.format("Added %d %s to %s", amount, statName, targetPlayer.Name)
end

local function RemoveStat(targetPlayer, statName, amount)
	if not targetPlayer then return false, "Player not found" end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found" end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then return false, "Stat not found: " .. statName end
	
	pcall(function()
		stat.Value = math.max(0, stat.Value - amount)
	end)
	
	DebugPrint(string.format("Removed %d %s from %s", amount, statName, targetPlayer.Name))
	return true, string.format("Removed %d %s from %s", amount, statName, targetPlayer.Name)
end

local function ResetStat(targetPlayer, statName)
	if not targetPlayer then return false, "Player not found" end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found" end
	
	local stat = leaderstats:FindFirstChild(statName)
	if not stat then return false, "Stat not found: " .. statName end
	
	pcall(function()
		stat.Value = 0
	end)
	
	DebugPrint(string.format("Reset %s for %s", statName, targetPlayer.Name))
	return true, string.format("Reset %s for %s", statName, targetPlayer.Name)
end

-- Potion Operations
local function GivePotion(targetPlayer, potionType, amount)
	if not targetPlayer then return false, "Player not found" end
	
	local potionInventory = targetPlayer:FindFirstChild("PotionInventory")
	if not potionInventory then
		-- Create PotionInventory if it doesn't exist
		potionInventory = Instance.new("Folder")
		potionInventory.Name = "PotionInventory"
		potionInventory.Parent = targetPlayer
	end
	
	local potion = potionInventory:FindFirstChild(potionType)
	if not potion then
		-- Create potion if it doesn't exist
		potion = Instance.new("IntValue")
		potion.Name = potionType
		potion.Value = 0
		potion.Parent = potionInventory
	end
	
	pcall(function()
		potion.Value = potion.Value + amount
	end)
	
	DebugPrint(string.format("Gave %d %s potion(s) to %s", amount, potionType, targetPlayer.Name))
	return true, string.format("Gave %d %s potion(s) to %s", amount, potionType, targetPlayer.Name)
end

-- Rot Skill Operations
local function GiveRSToken(targetPlayer, amount)
	if not targetPlayer then return false, "Player not found" end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found" end
	
	local rsToken = leaderstats:FindFirstChild("RSToken")
	if not rsToken then return false, "RSToken not found" end
	
	pcall(function()
		rsToken.Value = rsToken.Value + amount
	end)
	
	DebugPrint(string.format("Gave %d RSToken to %s", amount, targetPlayer.Name))
	return true, string.format("Gave %d RSToken to %s", amount, targetPlayer.Name)
end

local function SetEquippedSkill(targetPlayer, skillNumber)
	if not targetPlayer then return false, "Player not found" end
	
	if skillNumber < 1 or skillNumber > 10 then
		return false, "Skill number must be between 1 and 10"
	end
	
	local leaderstats = targetPlayer:FindFirstChild("leaderstats")
	if not leaderstats then return false, "Leaderstats not found" end
	
	local equippedSkill = leaderstats:FindFirstChild("EquippedSkill")
	if not equippedSkill then return false, "EquippedSkill not found" end
	
	pcall(function()
		equippedSkill.Value = skillNumber
	end)
	
	DebugPrint(string.format("Set EquippedSkill to %d for %s", skillNumber, targetPlayer.Name))
	return true, string.format("Set EquippedSkill to %d for %s", skillNumber, targetPlayer.Name)
end

-- Continue in Part 2...
```
