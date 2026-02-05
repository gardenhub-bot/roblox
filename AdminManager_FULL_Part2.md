# AdminManager_FULL.lua - Part 2 (Lines 1501-END - FINAL)

```lua
-- Part 2 - Command Handler, Player Events, and Initialization

-- Command Handler
local function HandleCommand(player, action, data)
	-- Check if player is admin
	if not IsAdmin(player) then
		DebugPrint(string.format("Non-admin player %s attempted command: %s", player.Name, action), "WARN")
		
		-- Log potential exploit attempt
		if AntiCheatSystem then
			pcall(function()
				AntiCheatSystem.LogSuspiciousActivity(player, "AdminCommandSpoof", {
					Action = action,
					Data = data
				})
			end)
		end
		
		return
	end
	
	-- Rate limiting
	if not CheckRateLimit(player) then
		pcall(function()
			AdminDataUpdate:FireClient(player, "CommandResult", {
				Success = false,
				Message = "Rate limit exceeded. Please wait before sending more commands."
			})
		end)
		return
	end
	
	-- Log operation
	LogOperation(player, action, data)
	
	-- Handle different commands
	local success, result
	local targetPlayer
	
	if data and data.Player then
		targetPlayer = GetPlayerByName(data.Player)
		if not targetPlayer then
			pcall(function()
				AdminDataUpdate:FireClient(player, "CommandResult", {
					Success = false,
					Message = "Player not found: " .. data.Player
				})
			end)
			return
		end
	end
	
	-- Execute command
	if action == "AddStat" then
		success, result = AddStat(targetPlayer, data.Stat, data.Amount)
		
	elseif action == "RemoveStat" then
		success, result = RemoveStat(targetPlayer, data.Stat, data.Amount)
		
	elseif action == "ResetStat" then
		success, result = ResetStat(targetPlayer, data.Stat)
		
	elseif action == "GivePotion" then
		success, result = GivePotion(targetPlayer, data.PotionType, data.Amount)
		
	elseif action == "GiveRSToken" then
		success, result = GiveRSToken(targetPlayer, data.Amount)
		
	elseif action == "SetEquippedSkill" then
		success, result = SetEquippedSkill(targetPlayer, data.Skill)
		
	elseif action == "StartEvent" then
		success, result = StartEvent(data.EventType, data.Duration, player)
		
	elseif action == "StopEvent" then
		success, result = StopEvent(data.EventType, false)
		
	elseif action == "CheckAdmin" then
		-- Admin check request from client
		player:SetAttribute("IsAdmin", true)
		success = true
		result = "Admin status confirmed"
		
	else
		success = false
		result = "Unknown command: " .. tostring(action)
	end
	
	-- Send result back to client
	pcall(function()
		AdminDataUpdate:FireClient(player, "CommandResult", {
			Success = success,
			Message = result
		})
	end)
	
	DebugPrint(string.format("Command %s by %s: %s", action, player.Name, result))
end

-- Player Added Event
local function OnPlayerAdded(player)
	-- Wait a moment for character to load
	task.wait(0.5)
	
	-- Check if player is admin
	if IsAdmin(player) then
		player:SetAttribute("IsAdmin", true)
		DebugPrint(string.format("Admin player joined: %s (UserID: %d)", player.Name, player.UserId))
		
		-- Log admin join
		if EventLogger then
			pcall(function()
				EventLogger.LogEvent({
					Category = "AdminJoin",
					Message = string.format("Admin %s joined the game", player.Name),
					Player = player
				})
			end)
		end
		
		-- Apply any active event multipliers
		for eventName, eventInfo in pairs(ActiveEvents) do
			pcall(function()
				player:SetAttribute(eventInfo.EventData.AttributeName, eventInfo.EventData.Multiplier)
			end)
		end
	else
		player:SetAttribute("IsAdmin", false)
	end
end

-- Player Removing Event
local function OnPlayerRemoving(player)
	-- Clear command history
	if CommandHistory[player.UserId] then
		CommandHistory[player.UserId] = nil
	end
	
	if IsAdmin(player) then
		DebugPrint(string.format("Admin player left: %s", player.Name))
	end
end

-- Initialize AdminManager
function AdminManager.Initialize()
	DebugPrint("Initializing AdminManager...")
	
	-- Setup remote connections
	AdminCommand.OnServerEvent:Connect(function(player, action, data)
		task.spawn(function()
			HandleCommand(player, action, data)
		end)
	end)
	
	-- Setup player events
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoving)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			OnPlayerAdded(player)
		end)
	end
	
	-- Log initialization
	DebugPrint("AdminManager initialized successfully!")
	DebugPrint(string.format("Admin count: %d", #Config.Admins))
	DebugPrint("Features: 7 Events, Full Stat Management, Potions, Rot Skills, Rate Limiting, History")
	
	if EventLogger then
		pcall(function()
			EventLogger.LogEvent({
				Category = "System",
				Message = "AdminManager initialized"
			})
		end)
	end
	
	-- Periodic cleanup (every 5 minutes)
	task.spawn(function()
		while true do
			task.wait(300)
			
			-- Clean up old command history
			local currentTime = tick()
			for userId, history in pairs(CommandHistory) do
				local newHistory = {}
				for _, timestamp in ipairs(history) do
					if currentTime - timestamp < Config.RateLimiting.TimeWindow then
						table.insert(newHistory, timestamp)
					end
				end
				CommandHistory[userId] = newHistory
			end
			
			DebugPrint("Performed periodic cleanup")
		end
	end)
end

-- Get System Status
function AdminManager.GetSystemStatus()
	return {
		ActiveEvents = ActiveEvents,
		OnlinePlayers = #Players:GetPlayers(),
		CommandHistorySize = #OperationHistory,
		RateLimitingEnabled = Config.RateLimiting.Enabled
	}
end

-- Get Operation History
function AdminManager.GetOperationHistory(count)
	count = count or 20
	local history = {}
	for i = 1, math.min(count, #OperationHistory) do
		table.insert(history, OperationHistory[i])
	end
	return history
end

-- Manual Event Control (for server scripts)
function AdminManager.StartEventManual(eventName, duration)
	return StartEvent(eventName, duration, nil)
end

function AdminManager.StopEventManual(eventName)
	return StopEvent(eventName, false)
end

-- Get Active Events
function AdminManager.GetActiveEvents()
	local events = {}
	for eventName, eventInfo in pairs(ActiveEvents) do
		events[eventName] = {
			StartTime = eventInfo.StartTime,
			Duration = eventInfo.Duration,
			EndTime = eventInfo.EndTime,
			RemainingTime = math.max(0, eventInfo.EndTime - tick()),
			Multiplier = eventInfo.EventData.Multiplier
		}
	end
	return events
end

return AdminManager
```
