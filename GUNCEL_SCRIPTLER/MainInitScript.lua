-- MainInitScript.lua
-- Bu script'i ServerScriptService içine "Script" (normal Script) olarak ekleyin
-- ModuleScript DEĞİL, normal Script olmalı!

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔧 Admin System Başlatılıyor...")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Servisler
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- ============================================================================
-- ADIM 1: Remotes Klasörünü Kontrol Et
-- ============================================================================

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
    warn("❌ HATA: ReplicatedStorage içinde 'Remotes' klasörü bulunamadı!")
    warn("   → ReplicatedStorage'a sağ tıklayın")
    warn("   → Insert Object → Folder")
    warn("   → Adını 'Remotes' yapın")
    return
end
print("✅ Remotes klasörü bulundu")

-- ============================================================================
-- ADIM 2: DebugConfig Modülünü Yükle
-- ============================================================================

local Modules = ReplicatedStorage:FindFirstChild("Modules")
if not Modules then
    warn("❌ HATA: ReplicatedStorage içinde 'Modules' klasörü bulunamadı!")
    warn("   → ReplicatedStorage'a 'Modules' adında Folder ekleyin")
    warn("   → İçine DebugConfig ModuleScript'ini ekleyin")
    return
end

local DebugConfigModule = Modules:FindFirstChild("DebugConfig")
if not DebugConfigModule then
    warn("❌ HATA: Modules klasöründe 'DebugConfig' bulunamadı!")
    warn("   → Modules klasörüne sağ tıklayın")
    warn("   → Insert Object → ModuleScript")
    warn("   → Adını 'DebugConfig' yapın")
    warn("   → DebugConfig.lua içeriğini kopyalayın")
    return
end

local DebugConfig = require(DebugConfigModule)
print("✅ DebugConfig yüklendi")

-- ============================================================================
-- ADIM 3: AdminManager Modülünü Yükle
-- ============================================================================

local Administration = ServerScriptService:FindFirstChild("Administration")
if not Administration then
    warn("❌ HATA: ServerScriptService içinde 'Administration' klasörü bulunamadı!")
    warn("   → ServerScriptService'e 'Administration' adında Folder ekleyin")
    warn("   → İçine AdminManager ModuleScript'ini ekleyin")
    return
end

local AdminManagerModule = Administration:FindFirstChild("AdminManager")
if not AdminManagerModule then
    warn("❌ HATA: Administration klasöründe 'AdminManager' bulunamadı!")
    warn("   → Administration klasörüne ModuleScript ekleyin")
    warn("   → Adını 'AdminManager' yapın")
    warn("   → AdminManager.lua içeriğini kopyalayın")
    return
end

local success, loadResult = pcall(function()
    return require(AdminManagerModule)
end)

if not success then
    warn("❌ HATA: AdminManager yüklenirken hata oluştu:", loadResult)
    warn("   → AdminManager.lua içeriğinin doğru kopyalandığından emin olun")
    warn("   → Output penceresindeki hata mesajlarını okuyun")
    warn("")
    warn("🔍 Detaylı Hata:")
    warn(tostring(loadResult))
    return
end

local AdminManager = loadResult
print("✅ AdminManager yüklendi")

-- ============================================================================
-- ADIM 4: Admin Listesini Kontrol Et
-- ============================================================================

local hasAdmins = false
if AdminManager and AdminManager.Config and AdminManager.Config.Admins then
    for userId, isAdmin in pairs(AdminManager.Config.Admins) do
        if isAdmin then
            print(string.format("✅ Admin UserID: %d", userId))
            hasAdmins = true
        end
    end
else
    warn("❌ HATA: AdminManager.Config.Admins bulunamadı!")
    warn("   → AdminManager modülü düzgün yüklenmedi")
    return
end

if not hasAdmins then
    warn("⚠️  UYARI: Admin listesi boş!")
    warn("   → AdminManager ModuleScript'ini açın")
    warn("   → AdminManager.Config.Admins içine UserID'nizi ekleyin")
    warn("   → Örnek: [123456789] = true,")
    print("")
    print("📝 UserID'nizi nasıl bulursunuz?")
    print("   1. Roblox profilinize gidin")
    print("   2. URL'ye bakın: roblox.com/users/[USERID]/profile")
    print("   3. O sayıyı AdminManager'a ekleyin")
end

-- ============================================================================
-- ADIM 5: Sistemi Başlat
-- ============================================================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🚀 AdminManager başlatılıyor...")

local initSuccess, err = pcall(function()
    AdminManager.Initialize()
end)

if initSuccess then
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✅ Admin System Başarıyla Başlatıldı!")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
    print("📱 Admin Panel Nasıl Açılır:")
    print("   1. F2 tuşuna basın")
    print("   2. VEYA sağ alt köşedeki 🔧 butonuna tıklayın")
    print("")
    print("🎮 Oyuna Katılın ve Test Edin!")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
else
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    warn("❌ HATA: Admin System başlatılamadı!")
    warn("Hata mesajı:", err)
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("")
    print("🔍 Olası Nedenler:")
    print("   1. AntiCheatSystem veya EventLogger eksik (opsiyonel)")
    print("   2. Bir modül yanlış yere konulmuş")
    print("   3. Modül içeriği düzgün kopyalanmamış")
    print("")
    print("💡 Bu hatayı görmezden gelebilirsiniz")
    print("   Sistem yine çalışabilir, ama bazı özellikler olmayabilir")
end

-- ============================================================================
-- ADIM 6: Oyuncu Girişini İzle
-- ============================================================================

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    -- Oyuncunun admin olup olmadığını kontrol et
    if AdminManager.IsAdmin(player) then
        print(string.format("🎖️  Admin oyuncu katıldı: %s (UserID: %d)", player.Name, player.UserId))
        
        -- IsAdmin attribute'u set et
        player:SetAttribute("IsAdmin", true)
        
        -- Biraz bekle, sonra kontrol et
        task.wait(2)
        
        local isAdminSet = player:GetAttribute("IsAdmin")
        if isAdminSet then
            print(string.format("   ✅ %s için IsAdmin attribute set edildi", player.Name))
        else
            warn(string.format("   ⚠️  %s için IsAdmin attribute set edilemedi!", player.Name))
        end
    else
        print(string.format("👤 Normal oyuncu katıldı: %s", player.Name))
    end
end)

-- Mevcut oyuncular için kontrol
for _, player in ipairs(Players:GetPlayers()) do
    if AdminManager.IsAdmin(player) then
        print(string.format("🎖️  Admin zaten oyunda: %s (UserID: %d)", player.Name, player.UserId))
        player:SetAttribute("IsAdmin", true)
        
        -- Hemen kontrol et
        task.wait(0.5)
        local isAdminSet = player:GetAttribute("IsAdmin")
        if isAdminSet then
            print(string.format("   ✅ %s için IsAdmin attribute başarıyla set edildi", player.Name))
        else
            warn(string.format("   ⚠️  %s için IsAdmin attribute set edilemedi!", player.Name))
        end
    else
        print(string.format("👤 Normal oyuncu oyunda: %s (UserID: %d)", player.Name, player.UserId))
    end
end

print("")
print("✅ Başlatma scripti tamamlandı!")
print("   Artık oyunu test edebilirsiniz")
print("")
