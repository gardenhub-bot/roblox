# 🎮 Admin Sistemi - Hızlı Başlangıç Kılavuzu (Türkçe)

## 📥 Kurulum (5 Dakika)

### 1. Dosyaları Yerleştir

Tüm .lua dosyalarını Roblox Studio'da şu konumlara kopyalayın:

```
📁 ReplicatedStorage
   └─📁 Modules
      └─📄 DebugConfig.lua

📁 ServerScriptService  
   ├─📁 Security
   │  └─📄 AntiCheatSystem.lua
   ├─📁 Systems
   │  └─📄 EventLogger.lua
   └─📁 Administration
      └─📄 AdminManager.lua

📁 StarterPlayer
   └─📁 StarterPlayerScripts
      └─📄 AdminClient.lua

📁 ReplicatedStorage
   └─📁 Remotes (Klasör oluştur - içi boş bırak)
```

### 2. Admin Kullanıcılarını Ekle

`AdminManager.lua` dosyasını aç ve kendi UserID'ni ekle:

```lua
-- Satır ~45 civarı
AdminManager.Config = {
    Admins = {
        [12345678] = true, -- BURAYA KENDİ USERID'Nİ YAZ
    },
}
```

💡 **UserID nasıl bulunur?** 
- Roblox profiline git → URL'deki sayı senin UserID'n
- Örnek: `roblox.com/users/12345678/profile`

### 3. Sistemi Başlat

Ana oyun script'ine (ServerScriptService içinde) şunu ekle:

```lua
-- En üste ekle
local AdminManager = require(script.Parent.Administration.AdminManager)

-- Script başladığında
AdminManager.Initialize()
```

### 4. Test Et

1. Play tuşuna bas
2. **F2** tuşuna bas
3. Admin paneli açılmalı! 🎉

---

## 🎯 Temel Kullanım

### Admin Panelini Aç/Kapat
- **F2** tuşu ile panel açılır/kapanır
- **🔧 Butonu** (sağ alt köşe) ile de açılır/kapanır - YENİ! 🎉

### Panel Sekmeleri

#### 📊 Dashboard (Ana Sayfa)
- Sistem durumunu gösterir
- Aktif oyuncuları listeler
- Her şeyin çalışıp çalışmadığını kontrol et

#### 📋 Events (Olaylar)
- Oyunda olan her şeyi gerçek zamanlı gösterir
- Oyuncu giriş/çıkış
- Stat değişimleri
- İksir kullanımları
- Anti-cheat uyarıları

#### ⌨️ Commands (Komutlar)
- Admin komutlarını çalıştır
- Stat ver, iksir ver, vb.
- Her komut için parametreler gösterilir

#### 🐛 Debug (Hata Ayıklama)
- Debug mesajlarını aç/kapat
- Her sistem için ayrı kontrol
- Master switch ile hepsini birden kapat

---

## 🔧 Sık Kullanılan Özellikler

### Oyuncuya Stat Vermek

**Kod ile (ServerScript):**
```lua
local AdminManager = require(game.ServerScriptService.Administration.AdminManager)

-- Oyuncu bul
local player = game.Players:FindFirstChild("OyuncuAdi")

-- Stat ver (admin, hedef, stat adı, miktar)
local success, message = AdminManager.GiveStat(
    adminPlayer,  -- Admin oyuncu
    player,       -- Hedef oyuncu  
    "IQ",        -- Stat adı
    10000        -- Miktar
)

print(message) -- "Başarılı" veya hata mesajı
```

### Oyuncuya İksir Vermek

**Kod ile:**
```lua
local AdminManager = require(game.ServerScriptService.Administration.AdminManager)

-- İksir ver (admin, hedef, iksir tipi, süre)
AdminManager.GivePotion(
    adminPlayer,
    targetPlayer,
    "Luck",  -- veya "IQ", "Aura", "Essence", "Speed", "Damage"
    300      -- Süre (saniye) - opsiyonel, varsayılan 300
)
```

### Oyuncuya Aura Vermek

**Kod ile:**
```lua
local AdminManager = require(game.ServerScriptService.Administration.AdminManager)

-- Aura ver
AdminManager.GiveAura(
    adminPlayer,
    targetPlayer,
    1000  -- Aura miktarı
)
```

---

## 📝 Event Logging (Olay Kaydetme)

### Kendi Eventlerini Kaydet

Oyununda önemli bir olay olduğunda kaydet:

```lua
local EventLogger = require(game.ServerScriptService.Systems.EventLogger)

-- Basit event
EventLogger.LogEvent(
    player,           -- Oyuncu
    "MyCategory",     -- Kategori
    "PlayerWon",      -- Event tipi
    {                 -- Detaylar
        Prize = 1000,
        Time = 60
    }
)

-- Hazır fonksiyonlar
EventLogger.LogStatChange(player, "IQ", 1000, 2000)
EventLogger.LogPotionUse(player, "Luck", 300)
EventLogger.LogAuraGain(player, 50, "Spin")
EventLogger.LogRebirth(player, 5)
```

Tüm bu eventler:
- Otomatik kaydedilir
- Admin panelinde gerçek zamanlı görünür
- Console'a yazdırılır (debug açıksa)

---

## 🛡️ Anti-Cheat Kullanımı

### Otomatik Koruma

Anti-cheat sistemi otomatik çalışır:
- Stat değerlerini kontrol eder
- Anormal artışları tespit eder
- Aura manipülasyonunu önler
- İksir kullanımını doğrular

### Manuel Kontroller

Kendi kodunda da kullanabilirsin:

```lua
local AntiCheatSystem = require(game.ServerScriptService.Security.AntiCheatSystem)

-- Stat vermeden önce kontrol et
if AntiCheatSystem.ValidateStat(player, "IQ", yeniDeger) then
    -- Güvenli, stat'ı ver
else
    -- Şüpheli, reddet
end

-- Aura vermeden önce kontrol et
if AntiCheatSystem.ValidateAuraGain(player, miktar, "Spin") then
    -- Güvenli, aura ver
else
    -- Şüpheli, reddet
end
```

---

## 🐛 Debug Mesajları

### Kendi Sisteminde Debug Kullan

```lua
local DebugConfig = require(game.ReplicatedStorage.Modules.DebugConfig)

-- Bilgi mesajı
DebugConfig.Info("MySystem", "Oyuncu kazandı!")

-- Uyarı mesajı
DebugConfig.Warning("MySystem", "Şüpheli aktivite!", player.Name)

-- Hata mesajı
DebugConfig.Error("MySystem", "Bir hata oluştu!")

-- Detaylı mesaj (sadece debug modda görünür)
DebugConfig.Verbose("MySystem", "Detaylı bilgi...")

-- Kritik hata
DebugConfig.Critical("MySystem", "Ciddi hata!!!")
```

### Debug Ayarlarını Değiştir

**Kod ile:**
```lua
local DebugConfig = require(game.ReplicatedStorage.Modules.DebugConfig)

-- Bir sistemi kapat
DebugConfig.UpdateSystemDebug("MySystem", false)

-- Tüm debug'ı kapat
DebugConfig.UpdateSettings({MasterDebugEnabled = false})

-- Verbose mesajları aç
DebugConfig.UpdateSettings({EnableVerbose = true})
```

**Panel ile:**
- Admin panelini aç (F2)
- Debug sekmesine git
- İstediğin sistemi aç/kapat

---

## ⚙️ Önemli Ayarlar

### Anti-Cheat Hassasiyeti

`AntiCheatSystem.lua` içinde:

```lua
-- Satır ~30 civarı
MaxStats = {
    IQ = 1e15,      -- Maksimum IQ (artır/azalt)
    Aura = 1e10,    -- Maksimum Aura
    -- ...
}

-- Satır ~45 civarı
MaxChangeRates = {
    IQ = 1e12,      -- Saniyede max IQ artışı
    Aura = 1e6,     -- Saniyede max Aura artışı
}
```

### Otomatik Kick

`AntiCheatSystem.lua` içinde:

```lua
-- Satır ~25 civarı
Enabled = true,             -- Anti-cheat açık/kapalı
AutoKickCheaters = false,   -- true yap otomatik kick için
WarningsBeforeKick = 3,     -- Kaç uyarıdan sonra kick
```

### Event Log Miktarı

`EventLogger.lua` içinde:

```lua
-- Satır ~25 civarı
MaxStoredEvents = 500,      -- Kaç event saklanacak
BroadcastToAdmins = true,   -- Admin'lere gönder
LogToConsole = true,        -- Console'a yazdır
```

---

## 🎨 UI Özelleştirme

`AdminClient.lua` dosyasında tema renklerini değiştirebilirsin:

```lua
-- Satır ~20 civarı
Theme = {
    Background = Color3.fromRGB(30, 30, 40),      -- Arka plan
    Panel = Color3.fromRGB(40, 40, 50),           -- Panel
    Accent = Color3.fromRGB(100, 150, 255),       -- Vurgu rengi
    Success = Color3.fromRGB(100, 255, 150),      -- Başarı
    Warning = Color3.fromRGB(255, 200, 50),       -- Uyarı
    Error = Color3.fromRGB(255, 100, 100),        -- Hata
}
```

---

## ❓ Sorun Giderme

### "Admin Paneli Açılmıyor"

1. **UserID doğru mu?**
   - AdminManager.lua içinde UserID'ni kontrol et

2. **Remotes klasörü var mı?**
   - ReplicatedStorage > Remotes klasörü olmalı

3. **Sistem başlatıldı mı?**
   - `AdminManager.Initialize()` çağrıldığından emin ol

### "Event'ler Görünmüyor"

1. **EventLogger başlatıldı mı?**
   - AdminManager.Initialize() EventLogger'ı da başlatır

2. **Admin attribute set edildi mi?**
   - Oyuna girdiğinde otomatik set edilmeli

### "Debug Mesajları Yok"

1. **Master debug açık mı?**
   ```lua
   DebugConfig.Settings.MasterDebugEnabled = true
   ```

2. **Sistem debug'ı açık mı?**
   - Admin panel > Debug sekmesinden kontrol et

---

## 💡 İpuçları

### Performans
- Çok fazla event logging performansı etkileyebilir
- Gereksiz debug'ları kapat
- Verbose modunu sadece gerektiğinde kullan

### Güvenlik
- Admin UserID'lerini kimseyle paylaşma
- AutoKickCheaters'ı dikkatli kullan (false önerilir)
- Test sunucusunda önce dene

### Geliştirme
- Kendi event kategorilerini ekle
- Özel komutlar oluştur
- UI temasını oyununa göre düzenle

---

## 📞 Hızlı Referans

### Modül Gereksinimleri

```lua
-- Debug
local DebugConfig = require(game.ReplicatedStorage.Modules.DebugConfig)

-- Anti-Cheat (ServerScript)
local AntiCheatSystem = require(game.ServerScriptService.Security.AntiCheatSystem)

-- Event Logger (ServerScript)
local EventLogger = require(game.ServerScriptService.Systems.EventLogger)

-- Admin Manager (ServerScript)
local AdminManager = require(game.ServerScriptService.Administration.AdminManager)

-- Admin Client (LocalScript - otomatik başlar)
```

### En Çok Kullanılan Fonksiyonlar

```lua
-- Debug
DebugConfig.Info("System", "Message")
DebugConfig.Warning("System", "Warning", playerName)

-- Event Logger
EventLogger.LogEvent(player, "Category", "Type", {details})
EventLogger.LogStatChange(player, "IQ", old, new)

-- Anti-Cheat
AntiCheatSystem.ValidateStat(player, "StatName", value)
AntiCheatSystem.ValidateAuraGain(player, amount, "Source")

-- Admin Manager
AdminManager.GiveStat(admin, target, "StatName", amount)
AdminManager.GivePotion(admin, target, "PotionType", duration)
AdminManager.GiveAura(admin, target, amount)
```

---

## ✅ Kontrol Listesi

Kurulum sonrası kontrol et:

- [ ] Tüm dosyalar doğru yerlerde
- [ ] Remotes klasörü oluşturuldu
- [ ] Admin UserID eklendi
- [ ] AdminManager.Initialize() çağrıldı
- [ ] Oyun test edildi
- [ ] F2 ile panel açılıyor
- [ ] Dashboard çalışıyor
- [ ] Event'ler görünüyor
- [ ] Debug mesajları console'da

---

## 🎓 Daha Fazla Bilgi

Detaylı dokümantasyon için `ADMIN_SYSTEM_GUIDE.md` dosyasına bak.

**İyi eğlenceler! 🚀**
