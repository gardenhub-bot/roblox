-- EventVFXClient.lua
-- VFX Rain System - Map-based fixed positions
-- Location: StarterPlayer > StarterPlayerScripts (LocalScript)

local Players = game:GetService("Players")
local RPS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TS = game:GetService("TweenService")
local RS = game:GetService("RunService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Remotes = RPS:WaitForChild("Remotes")
local EventVFXTrigger = Remotes:WaitForChild("EventVFXTrigger")

local EventVFXFolder = RPS:FindFirstChild("EventVFX")
if not EventVFXFolder then
	EventVFXFolder = Instance.new("Folder")
	EventVFXFolder.Name = "EventVFX"
	EventVFXFolder.Parent = RPS
end

local ActiveVFX = {}
local ActiveMapVFX = {}

local OriginalLighting = {
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	ClockTime = Lighting.ClockTime,
	FogEnd = Lighting.FogEnd,
	FogColor = Lighting.FogColor,
}

local OriginalAtmosphere = nil
if Lighting:FindFirstChild("Atmosphere") then
	OriginalAtmosphere = {
		Density = Lighting.Atmosphere.Density,
		Color = Lighting.Atmosphere.Color,
		Glare = Lighting.Atmosphere.Glare,
		Haze = Lighting.Atmosphere.Haze,
	}
end

-- ============================================================================
-- FIND ALL MAP RAIN POINTS
-- ============================================================================
local function GetAllRainPoints()
	local points = {}
	local mapFolder = workspace:FindFirstChild("map")
	if not mapFolder then return points end

	for _, child in ipairs(mapFolder:GetChildren()) do
		if child:IsA("Folder") or child:IsA("Model") then
			local rainPoint = child:FindFirstChild("VFXRainPoint")
			if rainPoint and rainPoint:IsA("BasePart") then
				table.insert(points, {
					Name = child.Name,
					Part = rainPoint,
				})
			end
		end
	end

	return points
end

-- ============================================================================
-- CREATE DEFAULT PARTICLE EMITTERS FOR EVENT TYPES
-- ============================================================================
local function CreateDefaultParticle(eventType)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = eventType .. "_Rain"

	if eventType == "2xIQ" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 130, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 200, 255)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0.3),
		}
		emitter.Texture = "rbxassetid://6031068425"
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Rate = 25
		emitter.Speed = NumberRange.new(8, 15)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.RotSpeed = NumberRange.new(-90, 90)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.7, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.4
		emitter.LightInfluence = 0.6

	elseif eventType == "2xCoins" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 30)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(0.5, 1.2),
			NumberSequenceKeypoint.new(1, 0.4),
		}
		emitter.Texture = "rbxassetid://6031068421"
		emitter.Lifetime = NumberRange.new(3, 6)
		emitter.Rate = 20
		emitter.Speed = NumberRange.new(6, 12)
		emitter.SpreadAngle = Vector2.new(40, 40)
		emitter.RotSpeed = NumberRange.new(-120, 120)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.5
		emitter.LightInfluence = 0.5

	elseif eventType == "LuckyHour" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 120)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 255, 180)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 255, 200)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1.8),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0.2),
		}
		emitter.Texture = "rbxassetid://6031068425"
		emitter.Lifetime = NumberRange.new(4, 7)
		emitter.Rate = 15
		emitter.Speed = NumberRange.new(5, 10)
		emitter.SpreadAngle = Vector2.new(50, 50)
		emitter.RotSpeed = NumberRange.new(-60, 60)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.8, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.6
		emitter.LightInfluence = 0.4

	elseif eventType == "SpeedFrenzy" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0.1),
		}
		emitter.Texture = "rbxassetid://6031068425"
		emitter.Lifetime = NumberRange.new(1.5, 3)
		emitter.Rate = 40
		emitter.Speed = NumberRange.new(20, 35)
		emitter.SpreadAngle = Vector2.new(15, 15)
		emitter.RotSpeed = NumberRange.new(-180, 180)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.7
		emitter.LightInfluence = 0.3

	elseif eventType == "GoldenRush" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 170, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 2.5),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0.5),
		}
		emitter.Texture = "rbxassetid://6031068421"
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Rate = 30
		emitter.Speed = NumberRange.new(10, 18)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.RotSpeed = NumberRange.new(-150, 150)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.6, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.6
		emitter.LightInfluence = 0.4

	elseif eventType == "RainbowStars" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 165, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 100, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(130, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 200)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 2),
			NumberSequenceKeypoint.new(0.5, 1.5),
			NumberSequenceKeypoint.new(1, 0.3),
		}
		emitter.Texture = "rbxassetid://6031068425"
		emitter.Lifetime = NumberRange.new(4, 7)
		emitter.Rate = 20
		emitter.Speed = NumberRange.new(5, 12)
		emitter.SpreadAngle = Vector2.new(60, 60)
		emitter.RotSpeed = NumberRange.new(-100, 100)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.8
		emitter.LightInfluence = 0.2

	elseif eventType == "EssenceRain" then
		emitter.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 80, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 150, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 60, 220)),
		}
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1.5),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0.3),
		}
		emitter.Texture = "rbxassetid://6031068425"
		emitter.Lifetime = NumberRange.new(3, 6)
		emitter.Rate = 22
		emitter.Speed = NumberRange.new(8, 14)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.RotSpeed = NumberRange.new(-80, 80)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.7, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		}
		emitter.LightEmission = 0.5
		emitter.LightInfluence = 0.5

	else
		emitter.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
		emitter.Size = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0.2),
		}
		emitter.Lifetime = NumberRange.new(3, 5)
		emitter.Rate = 15
		emitter.Speed = NumberRange.new(8, 12)
		emitter.SpreadAngle = Vector2.new(30, 30)
		emitter.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		}
	end

	-- All emitters emit DOWNWARD
	emitter.EmissionDirection = Enum.NormalId.Bottom

	return emitter
end

-- ============================================================================
-- CREATE POINT LIGHT FOR EVENT
-- ============================================================================
local function CreateEventLight(eventType)
	local light = Instance.new("PointLight")
	light.Name = eventType .. "_Light"
	light.Range = 60
	light.Brightness = 2

	if eventType == "2xIQ" then
		light.Color = Color3.fromRGB(80, 130, 255)
	elseif eventType == "2xCoins" or eventType == "GoldenRush" then
		light.Color = Color3.fromRGB(255, 200, 50)
	elseif eventType == "LuckyHour" then
		light.Color = Color3.fromRGB(0, 255, 120)
	elseif eventType == "SpeedFrenzy" then
		light.Color = Color3.fromRGB(0, 255, 255)
	elseif eventType == "RainbowStars" then
		light.Color = Color3.fromRGB(255, 150, 255)
	elseif eventType == "EssenceRain" then
		light.Color = Color3.fromRGB(180, 80, 255)
	else
		light.Color = Color3.fromRGB(200, 200, 255)
	end

	return light
end

-- ============================================================================
-- START VFX ON ALL MAPS
-- ============================================================================
local function StartVFX(eventType)
	if ActiveMapVFX[eventType] then
		warn("[VFX] Event already active:", eventType)
		return
	end

	print("[VFX] Starting map-based VFX:", eventType)

	ActiveMapVFX[eventType] = {}

	local rainPoints = GetAllRainPoints()

	if #rainPoints == 0 then
		warn("[VFX] No VFXRainPoint parts found! Add them to map folders.")
		return
	end

	-- Check if custom VFX exists in ReplicatedStorage > EventVFX
	local eventFolder = EventVFXFolder:FindFirstChild(eventType)

	for _, pointData in ipairs(rainPoints) do
		local part = pointData.Part
		local mapName = pointData.Name

		if eventFolder then
			-- USE CUSTOM VFX from EventVFX folder
			for _, obj in ipairs(eventFolder:GetChildren()) do
				if obj:IsA("ParticleEmitter") then
					local clone = obj:Clone()
					clone.EmissionDirection = Enum.NormalId.Bottom
					clone.Parent = part
					table.insert(ActiveMapVFX[eventType], clone)
				elseif obj:IsA("PointLight") then
					local clone = obj:Clone()
					clone.Parent = part
					table.insert(ActiveMapVFX[eventType], clone)
				end
			end
		else
			-- USE DEFAULT GENERATED VFX
			local emitter = CreateDefaultParticle(eventType)
			emitter.Parent = part
			table.insert(ActiveMapVFX[eventType], emitter)

			local light = CreateEventLight(eventType)
			light.Parent = part
			table.insert(ActiveMapVFX[eventType], light)
		end

		print("[VFX] Applied to:", mapName)
	end

	-- LIGHTING CHANGES
	local lightingConfig = eventFolder and eventFolder:FindFirstChild("LightingConfig")
	if lightingConfig then
		if lightingConfig:FindFirstChild("Brightness") then Lighting.Brightness = lightingConfig.Brightness.Value end
		if lightingConfig:FindFirstChild("Ambient") then Lighting.Ambient = lightingConfig.Ambient.Value end
		if lightingConfig:FindFirstChild("OutdoorAmbient") then Lighting.OutdoorAmbient = lightingConfig.OutdoorAmbient.Value end
		if lightingConfig:FindFirstChild("FogEnd") then Lighting.FogEnd = lightingConfig.FogEnd.Value end
		if lightingConfig:FindFirstChild("FogColor") then Lighting.FogColor = lightingConfig.FogColor.Value end
	end

	-- ATMOSPHERE CHANGES
	local atmosphereConfig = eventFolder and eventFolder:FindFirstChild("AtmosphereConfig")
	if atmosphereConfig then
		local atmo = Lighting:FindFirstChild("Atmosphere")
		if not atmo then atmo = Instance.new("Atmosphere", Lighting) end
		if atmosphereConfig:FindFirstChild("Density") then atmo.Density = atmosphereConfig.Density.Value end
		if atmosphereConfig:FindFirstChild("Color") then atmo.Color = atmosphereConfig.Color.Value end
		if atmosphereConfig:FindFirstChild("Glare") then atmo.Glare = atmosphereConfig.Glare.Value end
		if atmosphereConfig:FindFirstChild("Haze") then atmo.Haze = atmosphereConfig.Haze.Value end
	end

	print("[VFX] Started on", #rainPoints, "maps:", eventType)
end

-- ============================================================================
-- STOP VFX
-- ============================================================================
local function StopVFX(eventType)
	if not ActiveMapVFX[eventType] then
		warn("[VFX] Event not active:", eventType)
		return
	end

	print("[VFX] Stopping VFX:", eventType)

	for _, obj in ipairs(ActiveMapVFX[eventType]) do
		if obj and obj.Parent then
			if obj:IsA("ParticleEmitter") then
				obj.Enabled = false
				Debris:AddItem(obj, 5)
			else
				obj:Destroy()
			end
		end
	end

	ActiveMapVFX[eventType] = nil

	-- Restore lighting
	Lighting.Brightness = OriginalLighting.Brightness
	Lighting.Ambient = OriginalLighting.Ambient
	Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
	Lighting.ClockTime = OriginalLighting.ClockTime
	Lighting.FogEnd = OriginalLighting.FogEnd
	Lighting.FogColor = OriginalLighting.FogColor

	if OriginalAtmosphere then
		local atmo = Lighting:FindFirstChild("Atmosphere")
		if atmo then
			atmo.Density = OriginalAtmosphere.Density
			atmo.Color = OriginalAtmosphere.Color
			atmo.Glare = OriginalAtmosphere.Glare
			atmo.Haze = OriginalAtmosphere.Haze
		end
	end

	print("[VFX] Stopped:", eventType)
end

-- ============================================================================
-- LISTEN FOR SERVER SIGNAL
-- ============================================================================
EventVFXTrigger.OnClientEvent:Connect(function(action, eventType)
	if action == "Start" then
		StartVFX(eventType)
	elseif action == "Stop" then
		StopVFX(eventType)
	end
end)

print("[EventVFXClient] Map-based VFX system loaded!")