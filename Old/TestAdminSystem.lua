-- TestAdminSystem.lua
-- Bu script'i ServerScriptService'e ekleyip test edebilirsiniz
-- Normal Script olarak ekleyin

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🧪 Admin System Test Başlıyor...")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

wait(3) -- Sistemin yüklenmesini bekle

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- AdminManager'ı yükle
local AdminFolder = ServerScriptService:FindFirstChild("Administration")
if not AdminFolder then
    warn("❌ Administration klasörü bulunamadı!")
    return
end

local AdminManagerModule = AdminFolder:FindFirstChild("AdminManager")
if not AdminManagerModule then
    warn("❌ AdminManager modülü bulunamadı!")
    return
end

local AdminManager = require(AdminManagerModule)

print("\n📋 Admin Listesi:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
local adminCount = 0
for userId, isAdmin in pairs(AdminManager.Config.Admins) do
    if isAdmin then
        print(string.format("✅ UserID: %d", userId))
        adminCount = adminCount + 1
    end
end
print(string.format("Toplam Admin: %d", adminCount))

print("\n👥 Oyuncular:")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
for _, player in ipairs(Players:GetPlayers()) do
    local isAdmin = AdminManager.IsAdmin(player)
    local hasAttribute = player:GetAttribute("IsAdmin")
    
    print(string.format("\n🎮 Oyuncu: %s", player.Name))
    print(string.format("   UserID: %d", player.UserId))
    print(string.format("   Admin listesinde: %s", isAdmin and "✅ EVET" or "❌ HAYIR"))
    print(string.format("   IsAdmin attribute: %s", hasAttribute and "✅ SET" or "❌ YOK"))
    
    if isAdmin and not hasAttribute then
        warn(string.format("   ⚠️  SORUN: %s admin ama attribute set edilmemiş!", player.Name))
        print("   🔧 Attribute'u şimdi set ediyorum...")
        player:SetAttribute("IsAdmin", true)
        wait(0.5)
        local recheck = player:GetAttribute("IsAdmin")
        if recheck then
            print("   ✅ Attribute başarıyla set edildi!")
        else
            warn("   ❌ Attribute hala set edilemedi!")
        end
    end
end

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Test tamamlandı!")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
