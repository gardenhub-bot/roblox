# Admin Sistemi - Kurulum ve Kullanım Kılavuzu

## 📋 İçindekiler
- [Genel Bakış](#genel-bakış)
- [Dosya Yapısı](#dosya-yapısı)
- [Kurulum](#kurulum)
- [Özellikler](#özellikler)
- [Kullanım](#kullanım)
- [API Dokümantasyonu](#api-dokümantasyonu)

---

## 🎯 Genel Bakış

Bu admin sistemi, Roblox oyununuz için tam özellikli bir yönetim paneli sağlar. Sistem şu bileşenlerden oluşur:

### Modüller:
1. **DebugConfig.lua** - Gelişmiş debug/print ayarları sistemi
2. **AntiCheatSystem.lua** - Anti-cheat ve anti-spoof sistemi
3. **EventLogger.lua** - Gerçek-zamanlı event logging
4. **AdminManager.lua** - Sunucu tarafı admin yönetimi
5. **AdminClient.lua** - İstemci tarafı admin UI ve kontrol paneli

---

## 📁 Dosya Yapısı

### Roblox Studio'da Dosya Konumları:

```
ReplicatedStorage
├── Modules
│   └── DebugConfig.lua ✅

ServerScriptService
├── Security
│   └── AntiCheatSystem.lua ✅
├── Systems
│   └── EventLogger.lua ✅
└── Administration
    └── AdminManager.lua ✅

StarterPlayer
└── StarterPlayerScripts
    └── AdminClient.lua ✅

ReplicatedStorage
└── Remotes (Folder)
    ├── AdminCommand (RemoteEvent) - Otomatik oluşturulur
    ├── AdminDataUpdate (RemoteEvent) - Otomatik oluşturulur
    └── EventLogUpdate (RemoteEvent) - Otomatik oluşturulur
```

---

## 🚀 Kurulum

### Adım 1: Dosyaları Yerleştirme

1. **DebugConfig.lua** dosyasını:
   - `ReplicatedStorage > Modules` klasörüne yerleştirin

2. **AntiCheatSystem.lua** dosyasını:
   - `ServerScriptService > Security` klasörü oluşturun
   - Dosyayı bu klasöre yerleştirin

3. **EventLogger.lua** dosyasını:
   - `ServerScriptService > Systems` klasörü oluşturun
   - Dosyayı bu klasöre yerleştirin

4. **AdminManager.lua** dosyasını:
   - `ServerScriptService > Administration` klasörü oluşturun
   - Dosyayı bu klasöre yerleştirin

5. **AdminClient.lua** dosyasını:
   - `StarterPlayer > StarterPlayerScripts` klasörüne yerleştirin

### Adım 2: Remotes Klasörü

ReplicatedStorage içinde "Remotes" adlı bir **Folder** oluşturun. Remote event'ler otomatik olarak oluşturulacaktır.

### Adım 3: Admin Kullanıcıları Ayarlama

**AdminManager.lua** dosyasını açın ve admin kullanıcı ID'lerini ekleyin:

```lua
AdminManager.Config = {
    Admins = {
        [12345678] = true, -- Kendi UserID'nizi buraya ekleyin
        [87654321] = true, -- Diğer admin ID'leri
    },
    -- ...
}
```

**UserID'nizi nasıl bulursunuz?**
- Roblox profilinize gidin
- URL'deki sayıya bakın: `roblox.com/users/[BURADA]/profile`

### Adım 4: Ana Oyun Script'ine Entegrasyon

ServerScriptService içindeki ana oyun script'inize (veya ayrı bir başlatma script'ine) şunu ekleyin:

```lua
-- Admin Sistemi Başlatma
local AdminManager = require(script.Parent.Administration.AdminManager)
AdminManager.Initialize()
```

---

## ✨ Özellikler

### 1. Debug/Print Ayarları ✅

- **Master Debug Switch**: Tüm debug mesajlarını tek tuşla açma/kapama
- **Sistem Bazlı Debug**: Her sistem için ayrı debug kontrolü
- **Log Seviyeleri**: INFO, WARNING, ERROR, VERBOSE, CRITICAL
- **Rate Limiting**: Spam önleme için saniyede maksimum log limiti
- **Zaman Damgası**: Her log mesajında otomatik zaman damgası

**Örnek Kullanım:**
```lua
local DebugConfig = require(game.ReplicatedStorage.Modules.DebugConfig)

-- Basit log
DebugConfig.Info("MySystem", "İşlem başarılı!")

-- Oyuncu bilgisiyle log
DebugConfig.Warning("MySystem", "Şüpheli aktivite!", player.Name)

-- Debug ayarlarını güncelleme
DebugConfig.UpdateSystemDebug("AdminManager", false) -- AdminManager debug'ını kapat
```

### 2. Anti-Cheat ve Anti-Spoof ✅

- **Stat Validasyonu**: Maksimum değer kontrolleri
- **Değişim Hızı Kontrolü**: Anormal stat artışlarını tespit
- **Aura Anti-Spoof**: Aura manipülasyonunu önleme
- **İksir Validasyonu**: İksir kullanım kontrolü
- **Otomatik Uyarı Sistemi**: Hile yapan oyunculara otomatik uyarı
- **Opsiyonel Auto-Kick**: Belirlenen uyarı sayısından sonra otomatik atma

**Örnek Kullanım:**
```lua
local AntiCheatSystem = require(game.ServerScriptService.Security.AntiCheatSystem)

-- Stat doğrulama
if AntiCheatSystem.ValidateStat(player, "IQ", 1000000) then
    print("Stat geçerli")
end

-- Aura kazanımı doğrulama
if AntiCheatSystem.ValidateAuraGain(player, 50, "Spin") then
    -- Aura'yı ver
end

-- İksir kullanımı doğrulama
if AntiCheatSystem.ValidatePotionUse(player, "Luck", 300) then
    -- İksiri aktifleştir
end
```

### 3. Gerçek-Zamanlı Event Logging ✅

- **Otomatik Event Kaydı**: Oyun içi tüm önemli olayları kaydet
- **Gerçek-Zamanlı Broadcast**: Admin'lere anında event bildirimi
- **Event Kategorileri**: PlayerJoin, StatChange, PotionUse, AuraGain, AntiCheat, vb.
- **Event Geçmişi**: Geçmiş event'leri görüntüleme
- **Filtreleme**: Kategori, oyuncu ve log seviyesine göre filtreleme

**Örnek Kullanım:**
```lua
local EventLogger = require(game.ServerScriptService.Systems.EventLogger)

-- Özel event log'lama
EventLogger.LogEvent(player, "CustomEvent", "PlayerAchievement", {
    Achievement = "FirstWin",
    Reward = 1000
})

-- Hazır fonksiyonlar
EventLogger.LogStatChange(player, "IQ", 1000, 2000)
EventLogger.LogPotionUse(player, "Luck", 300)
EventLogger.LogAuraGain(player, 50, "Spin")
EventLogger.LogRebirth(player, 5)
```

### 4. Admin Manager (Sunucu) ✅

- **Yetki Sistemi**: 3 seviyeli admin yetkisi (SuperAdmin, Admin, Moderator)
- **Stat Yönetimi**: Oyuncu stat'larını verme/alma/ayarlama
- **İksir Yönetimi**: İksir verme ve temizleme
- **Aura Yönetimi**: Aura verme ve kontrol
- **Debug Kontrol**: Sunucu üzerinden debug ayarlarını değiştirme
- **Anti-Cheat Kontrol**: Anti-cheat sistemini açma/kapama
- **Komut İşleme**: Admin komutlarını güvenli şekilde işleme

**Komutlar:**
- `GiveStat` - Oyuncuya stat ver
- `SetStat` - Oyuncunun stat'ını ayarla
- `GivePotion` - Oyuncuya iksir ver
- `ClearPotions` - Oyuncunun iksirlerini temizle
- `GiveAura` - Oyuncuya Aura ver
- `SetDebug` - Debug ayarlarını değiştir
- `ToggleAntiCheat` - Anti-cheat'i aç/kapat

### 5. Admin Client (İstemci UI) ✅

- **Modern UI**: Temiz ve kullanışlı arayüz
- **Dashboard**: Sistem durumu ve aktif oyuncular
- **Event Log Viewer**: Gerçek-zamanlı event görüntüleme
- **Komut Paneli**: Kullanımı kolay komut arayüzü
- **Debug Paneli**: Debug ayarlarını görsel olarak kontrol
- **Klavye Kısayolu**: F2 ile paneli açma/kapama
- **Bildirimler**: İşlem sonuçları için otomatik bildirimler

**Özellikler:**
- Gerçek-zamanlı sistem durumu
- Aktif oyuncu listesi
- Event akışı (real-time)
- Tek tıkla komut çalıştırma
- Visual debug toggle'lar

---

## 🎮 Kullanım

### Admin Panel'i Açma

1. Oyuna admin hesabıyla girin
2. **F2** tuşuna basın
3. Admin paneli açılacak

### Dashboard

- **Sistem Durumu Kartları**: Debug, Anti-Cheat, Event Logger ve Server durumunu gösterir
- **Aktif Oyuncular**: Oyundaki tüm oyuncuları listeler

### Event Log

- Gerçek-zamanlı olarak tüm game event'lerini gösterir
- Otomatik olarak en son event'lere kaydırır
- Her event'te zaman, kategori ve detaylar görünür

### Commands

- Kategorilere ayrılmış komutlar
- Her komut için gerekli parametreler gösterilir
- Tek tıkla komut çalıştırma (gelecekte input alanları eklenebilir)

### Debug Panel

- Her sistem için ayrı debug toggle
- Master debug switch ile tümünü kontrol
- Değişiklikler anında sunucuya gönderilir

---

## 📚 API Dokümantasyonu

### DebugConfig API

```lua
-- Log fonksiyonları
DebugConfig.Info(systemName, message, playerName?)
DebugConfig.Warning(systemName, message, playerName?)
DebugConfig.Error(systemName, message, playerName?)
DebugConfig.Verbose(systemName, message, playerName?)
DebugConfig.Critical(systemName, message, playerName?)

-- Ayar güncelleme
DebugConfig.UpdateSettings({MasterDebugEnabled = true})
DebugConfig.UpdateSystemDebug("SystemName", true)

-- Bilgi alma
DebugConfig.GetSettings()
DebugConfig.PrintCurrentSettings()
```

### AntiCheatSystem API

```lua
-- Başlatma
AntiCheatSystem.Initialize()

-- Validasyon
AntiCheatSystem.ValidateStat(player, statName, value) -> boolean
AntiCheatSystem.ValidateStatChange(player, statName, oldValue, newValue, deltaTime) -> boolean
AntiCheatSystem.ValidateAuraGain(player, amount, source) -> boolean
AntiCheatSystem.ValidatePotionUse(player, potionType, duration) -> boolean

-- Oyuncu yönetimi
AntiCheatSystem.FlagPlayer(player, reason, details)
AntiCheatSystem.ClearPlayer(player)

-- Bilgi alma
AntiCheatSystem.GetPlayerWarnings(player) -> number
AntiCheatSystem.GetPlayerData(player) -> table
AntiCheatSystem.PrintStats()
```

### EventLogger API

```lua
-- Başlatma
EventLogger.Initialize()

-- Event log'lama
EventLogger.LogEvent(player, category, eventType, details)

-- Özel log fonksiyonları
EventLogger.LogPlayerJoin(player)
EventLogger.LogPlayerLeave(player)
EventLogger.LogStatChange(player, statName, oldValue, newValue)
EventLogger.LogPotionUse(player, potionType, duration)
EventLogger.LogAuraGain(player, amount, source)
EventLogger.LogAntiCheat(player, reason, details)
EventLogger.LogAdminAction(admin, action, target, details)
EventLogger.LogRebirth(player, newRebirthCount)
EventLogger.LogSpin(player, reward, rarity)
EventLogger.LogError(player, errorType, errorMessage)

-- Sorgu
EventLogger.GetRecentEvents(count?) -> table
EventLogger.GetPlayerEvents(playerUserId, count?) -> table
EventLogger.GetCategoryEvents(category, count?) -> table

-- Yönetim
EventLogger.ClearLogs()
EventLogger.GetStats() -> table
EventLogger.PrintStats()
```

### AdminManager API

```lua
-- Başlatma
AdminManager.Initialize()

-- Yetki kontrolü
AdminManager.IsAdmin(player) -> boolean
AdminManager.GetAdminLevel(player) -> number?
AdminManager.HasPermission(player, command) -> boolean
AdminManager.SetAdmin(player, isAdmin)

-- Stat yönetimi
AdminManager.GiveStat(admin, targetPlayer, statName, amount) -> success, message
AdminManager.SetStat(admin, targetPlayer, statName, value) -> success, message

-- İksir yönetimi
AdminManager.GivePotion(admin, targetPlayer, potionType, duration?) -> success, message
AdminManager.ClearPotions(admin, targetPlayer) -> success, message

-- Aura yönetimi
AdminManager.GiveAura(admin, targetPlayer, amount) -> success, message

-- Debug yönetimi
AdminManager.SetDebug(admin, systemName, enabled) -> success, message

-- Anti-cheat yönetimi
AdminManager.ToggleAntiCheat(admin, enabled) -> success, message

-- Sistem durumu
AdminManager.GetSystemStatus() -> table
AdminManager.SendSystemStatus(player)
AdminManager.BroadcastSystemStatus()
```

### AdminClient API

```lua
-- Başlatma (Otomatik)
AdminClient.Initialize()

-- UI kontrolü
AdminClient.ToggleUI()
AdminClient.SwitchTab(tabName)

-- Güncelleme
AdminClient.UpdateDashboard()
AdminClient.UpdateEventLog()

-- Bildirimler
AdminClient.ShowNotification(message, notifType?)
```

---

## ⚙️ Yapılandırma

### Debug Ayarları (DebugConfig.lua)

```lua
DebugConfig.Settings = {
    MasterDebugEnabled = true,  -- Ana debug anahtarı
    EnableInfo = true,          -- Bilgilendirme mesajları
    EnableWarning = true,       -- Uyarı mesajları
    EnableError = true,         -- Hata mesajları
    EnableVerbose = false,      -- Detaylı log mesajları
    
    DebugSystems = {
        AdminManager = true,    -- Sistem bazlı debug
        -- ...
    },
    
    MaxLogsPerSecond = 50,      -- Spam önleme
}
```

### Anti-Cheat Ayarları (AntiCheatSystem.lua)

```lua
AntiCheatSystem.Config = {
    Enabled = true,
    AutoKickCheaters = false,   -- Otomatik kick
    WarningsBeforeKick = 3,
    
    MaxStats = {
        IQ = 1e15,              -- Maksimum değerler
        Aura = 1e10,
        -- ...
    },
    
    MaxChangeRates = {
        IQ = 1e12,              -- Saniyede maksimum artış
        // ...
    },
}
```

### Event Logger Ayarları (EventLogger.lua)

```lua
EventLogger.Config = {
    Enabled = true,
    MaxStoredEvents = 500,
    BroadcastToAdmins = true,
    LogToConsole = true,
    
    EnabledCategories = {
        PlayerJoin = true,
        StatChange = true,
        // ...
    },
}
```

---

## 🔧 Sorun Giderme

### Admin Paneli Açılmıyor

1. Player'ın `IsAdmin` attribute'u set edilmiş mi kontrol edin
2. AdminManager'da UserID'niz admin listesinde mi kontrol edin
3. Console'da hata mesajlarını kontrol edin

### Event'ler Görünmüyor

1. EventLogger'ın Initialize edildiğinden emin olun
2. EventLogRemote'un ReplicatedStorage > Remotes içinde olduğunu kontrol edin
3. Admin attribute'unun doğru set edildiğini kontrol edin

### Debug Mesajları Görünmüyor

1. DebugConfig.Settings.MasterDebugEnabled = true olduğunu kontrol edin
2. İlgili sistemin debug ayarının açık olduğunu kontrol edin
3. Log seviyesinin yeterince düşük olduğunu kontrol edin

---

## 🎉 Özelleştirme

### Tema Değiştirme (AdminClient.lua)

```lua
AdminClient.Config.Theme = {
    Background = Color3.fromRGB(30, 30, 40),
    Panel = Color3.fromRGB(40, 40, 50),
    Accent = Color3.fromRGB(100, 150, 255),
    // Kendi renklerinizi ekleyin
}
```

### Yeni Komut Ekleme (AdminManager.lua)

```lua
-- CommandHandlers tablosuna yeni komut ekleyin
CommandHandlers.MyCommand = function(admin, args)
    -- Komut mantığınız
    return true, "Başarılı"
end

-- Permissions listesine ekleyin
CommandPermissions[1] = {
    "MyCommand",
    // ...
}
```

### Yeni Event Kategorisi Ekleme (EventLogger.lua)

```lua
EnabledCategories = {
    MyCategory = true,
    // ...
}

-- Özel log fonksiyonu
function EventLogger.LogMyEvent(player, details)
    EventLogger.LogEvent(player, "MyCategory", "MyEvent", details)
end
```

---

## 📝 Notlar

1. **Performans**: Sistem optimize edilmiştir ancak çok fazla event logging performansı etkileyebilir
2. **Güvenlik**: Admin UserID'leri güvenli tutun
3. **Test**: Yeni özellikleri eklerken test sunucusunda test edin
4. **Backup**: Değişiklik yapmadan önce dosyalarınızı yedekleyin

---

## 🚀 Gelecek Özellikler

- [ ] Grafik ve istatistikler
- [ ] Admin chat sistemi
- [ ] Oyuncu ban/unban sistemi
- [ ] Detaylı player profil görüntüleme
- [ ] Command history
- [ ] Export/import ayarları
- [ ] Mobile uyumlu UI

---

## 📞 Destek

Sorun yaşarsanız veya öneriniz varsa lütfen bize ulaşın!

**Önemli**: Bu sistem production kullanıma hazırdır ancak kendi oyun mantığınıza göre özelleştirme gerektirebilir.

---

## ✅ Kurulum Kontrol Listesi

- [ ] Tüm dosyalar doğru konumlara yerleştirildi
- [ ] Remotes klasörü oluşturuldu
- [ ] Admin UserID'leri eklendi
- [ ] AdminManager.Initialize() çağrıldı
- [ ] Oyun test edildi
- [ ] Admin paneli açılıyor (F2)
- [ ] Debug mesajları görünüyor
- [ ] Event'ler loglanıyor
- [ ] Anti-cheat çalışıyor

---

**Başarılar! 🎮**
