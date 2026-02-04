# 🎮 KOLAY KURULUM REHBERİ

## 📋 İçindekiler
1. [Yapı Görünümü](#yapı-görünümü)
2. [Nesne Tipleri Açıklaması](#nesne-tipleri-açıklaması)
3. [Adım Adım Kurulum](#adım-adım-kurulum)
4. [Kontrol Listesi](#kontrol-listesi)
5. [Ayarlar](#ayarlar)
6. [Test ve Doğrulama](#test-ve-doğrulama)

---

## 📁 Yapı Görünümü

Roblox Studio'da oluşturacağınız yapı:

```
🎮 Roblox Oyununuz
│
├── 📂 ServerScriptService
│   └── 📁 Administration
│       ├── 📘 AdminManager (ModuleScript)
│       ├── 📘 AntiCheatSystem (ModuleScript)
│       ├── 📘 EventLogger (ModuleScript)
│       └── 📜 MainInit (Script)
│
├── 📂 ReplicatedStorage
│   ├── 📁 Modules
│   │   └── 📘 DebugConfig (ModuleScript)
│   └── 📁 Remotes
│       └── 📁 Administration
│           ├── 📡 AdminDataRemote (RemoteEvent)
│           ├── 📞 AdminCommandRemote (RemoteFunction)
│           └── 📡 EventLogRemote (RemoteEvent)
│
└── 📂 StarterPlayer
    └── StarterPlayerScripts
        └── 📁 Administration
            └── 📄 AdminClient (LocalScript)
```

### 🔑 Simgeler Açıklaması:
- 📁 **Folder** = Organizasyon klasörü
- 📘 **ModuleScript** = Kod modülü
- 📜 **Script** = Sunucu scripti
- 📄 **LocalScript** = İstemci scripti
- 📡 **RemoteEvent** = Server↔Client iletişim (Fire)
- 📞 **RemoteFunction** = Server↔Client iletişim (Invoke)

---

## 🎯 Nesne Tipleri Açıklaması

### 📘 ModuleScript
- **Ne İşe Yarar:** Tekrar kullanılabilir kod modülleri
- **Nasıl Çalışır:** `require()` ile çağrılır
- **Örnek:** DebugConfig, AdminManager, AntiCheatSystem
- **Nerede Kullanılır:** Hem server hem client'ta kullanılabilir

### 📜 Script
- **Ne İşe Yarar:** Sunucu tarafında çalışan kod
- **Nasıl Çalışır:** Oyun başladığında otomatik çalışır
- **Örnek:** MainInit
- **Nerede Kullanılır:** ServerScriptService içinde

### 📄 LocalScript
- **Ne İşe Yarar:** İstemci (oyuncu) tarafında çalışan kod
- **Nasıl Çalışır:** Oyuncunun bilgisayarında çalışır
- **Örnek:** AdminClient
- **Nerede Kullanılır:** StarterPlayerScripts içinde

### 📡 RemoteEvent
- **Ne İşe Yarar:** Server ve Client arası iletişim
- **Nasıl Çalışır:** `:FireServer()` ve `:FireClient()` ile mesaj gönderme
- **Örnek:** AdminDataRemote, EventLogRemote
- **Nerede Kullanılır:** ReplicatedStorage/Remotes içinde

### 📞 RemoteFunction
- **Ne İşe Yarar:** Server ve Client arası iletişim (cevap beklenir)
- **Nasıl Çalışır:** `:InvokeServer()` ile çağrı yapma ve sonuç alma
- **Örnek:** AdminCommandRemote
- **Nerede Kullanılır:** ReplicatedStorage/Remotes içinde

### 📁 Folder
- **Ne İşe Yarar:** Diğer nesneleri organize etmek
- **Nasıl Çalışır:** Sadece gruplandırma için
- **Örnek:** Administration, Remotes, Modules
- **Nerede Kullanılır:** Her yerde organizasyon için

---

## 🚀 Adım Adım Kurulum

### ADIM 1: ServerScriptService'e Administration Klasörü Ekle
- 🎯 **TİPİ:** Folder
- 📍 **YER:** ServerScriptService içine
- ➕ **NASIL:** ServerScriptService'e sağ tıkla → Insert Object → Folder
- 📝 **İSİM:** "Administration"

---

### ADIM 2: ReplicatedStorage'a Modules Klasörü Ekle
- 🎯 **TİPİ:** Folder
- 📍 **YER:** ReplicatedStorage içine
- ➕ **NASIL:** ReplicatedStorage'a sağ tıkla → Insert Object → Folder
- 📝 **İSİM:** "Modules"

---

### ADIM 3: ReplicatedStorage'a Remotes Klasörü Ekle
- 🎯 **TİPİ:** Folder
- 📍 **YER:** ReplicatedStorage içine
- ➕ **NASIL:** ReplicatedStorage'a sağ tıkla → Insert Object → Folder
- 📝 **İSİM:** "Remotes"

---

### ADIM 4: AdminManager Oluştur
- 🎯 **TİPİ:** ModuleScript (çok önemli!)
- 📍 **YER:** ServerScriptService/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → ModuleScript
- 📝 **İSİM:** "AdminManager"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Server/AdminManager.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİRECEĞİN YER:** Satır 120'ye UserID ekle (örnek: `[4221507527] = true,`)

---

### ADIM 5: AntiCheatSystem Oluştur
- 🎯 **TİPİ:** ModuleScript
- 📍 **YER:** ServerScriptService/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → ModuleScript
- 📝 **İSİM:** "AntiCheatSystem"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Server/AntiCheatSystem.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİR:** Hayır, olduğu gibi bırak

---

### ADIM 6: EventLogger Oluştur
- 🎯 **TİPİ:** ModuleScript
- 📍 **YER:** ServerScriptService/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → ModuleScript
- 📝 **İSİM:** "EventLogger"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Server/EventLogger.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİR:** Hayır, olduğu gibi bırak

---

### ADIM 7: DebugConfig Oluştur
- 🎯 **TİPİ:** ModuleScript
- 📍 **YER:** ReplicatedStorage/Modules/ içinde
- ➕ **NASIL:** Modules klasörüne sağ tıkla → Insert Object → ModuleScript
- 📝 **İSİM:** "DebugConfig"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Shared/DebugConfig.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİR:** Hayır, olduğu gibi bırak

---

### ADIM 8: Remotes İçine Administration Klasörü Ekle
- 🎯 **TİPİ:** Folder
- 📍 **YER:** ReplicatedStorage/Remotes/ içinde
- ➕ **NASIL:** Remotes klasörüne sağ tıkla → Insert Object → Folder
- 📝 **İSİM:** "Administration"

---

### ADIM 9: AdminDataRemote Oluştur
- 🎯 **TİPİ:** RemoteEvent (dikkat!)
- 📍 **YER:** ReplicatedStorage/Remotes/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → RemoteEvent
- 📝 **İSİM:** "AdminDataRemote"
- 📄 **KOD:** Kod yok, sadece obje oluştur

---

### ADIM 10: AdminCommandRemote Oluştur
- 🎯 **TİPİ:** RemoteFunction (RemoteEvent değil!)
- 📍 **YER:** ReplicatedStorage/Remotes/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → RemoteFunction
- 📝 **İSİM:** "AdminCommandRemote"
- 📄 **KOD:** Kod yok, sadece obje oluştur

---

### ADIM 11: EventLogRemote Oluştur
- 🎯 **TİPİ:** RemoteEvent
- 📍 **YER:** ReplicatedStorage/Remotes/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → RemoteEvent
- 📝 **İSİM:** "EventLogRemote"
- 📄 **KOD:** Kod yok, sadece obje oluştur

---

### ADIM 12: StarterPlayerScripts'e Administration Klasörü Ekle
- 🎯 **TİPİ:** Folder
- 📍 **YER:** StarterPlayer/StarterPlayerScripts/ içinde
- ➕ **NASIL:** StarterPlayerScripts'e sağ tıkla → Insert Object → Folder
- 📝 **İSİM:** "Administration"

---

### ADIM 13: AdminClient Oluştur
- 🎯 **TİPİ:** LocalScript (Script değil!)
- 📍 **YER:** StarterPlayer/StarterPlayerScripts/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → LocalScript
- 📝 **İSİM:** "AdminClient"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Client/AdminClient.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİR:** Hayır, olduğu gibi bırak

---

### ADIM 14: MainInit Oluştur
- 🎯 **TİPİ:** Script (LocalScript veya ModuleScript değil!)
- 📍 **YER:** ServerScriptService/Administration/ içinde
- ➕ **NASIL:** Administration klasörüne sağ tıkla → Insert Object → Script
- 📝 **İSİM:** "MainInit"
- 📄 **KOD:** GitHub'dan `AdminPanelSystem/Scripts/MainInitScript.lua` dosyasını kopyala
- ⚙️ **DEĞİŞTİR:** Hayır, olduğu gibi bırak

---

## ✅ Kontrol Listesi

Tamamladıkça işaretle:

### Klasörler:
- [ ] ServerScriptService/Administration (Folder)
- [ ] ReplicatedStorage/Modules (Folder)
- [ ] ReplicatedStorage/Remotes (Folder)
- [ ] ReplicatedStorage/Remotes/Administration (Folder)
- [ ] StarterPlayer/StarterPlayerScripts/Administration (Folder)

### ModuleScript'ler:
- [ ] Administration/AdminManager (ModuleScript) - **UserID ekle!**
- [ ] Administration/AntiCheatSystem (ModuleScript)
- [ ] Administration/EventLogger (ModuleScript)
- [ ] Modules/DebugConfig (ModuleScript)

### Script'ler:
- [ ] Administration/MainInit (Script - normal Script!)

### LocalScript'ler:
- [ ] Administration/AdminClient (LocalScript)

### Remote'lar:
- [ ] Remotes/Administration/AdminDataRemote (RemoteEvent)
- [ ] Remotes/Administration/AdminCommandRemote (RemoteFunction)
- [ ] Remotes/Administration/EventLogRemote (RemoteEvent)

---

## ⚙️ Ayarlar

### AdminManager'a UserID Ekleme:

1. **Dosyayı Aç:** ServerScriptService/Administration/AdminManager
2. **Satır 120'yi Bul:** Config.Admins tablosunu bul
3. **UserID Ekle:**
   ```lua
   Config.Admins = {
       [4221507527] = true,  -- Senin UserID'n buraya
       -- Daha fazla admin ekleyebilirsin:
       -- [123456789] = true,
       -- [987654321] = true,
   }
   ```
4. **Kaydet:** File → Save

### UserID'ni Nasıl Bulursun:
1. Roblox web sitesine gir
2. Profiline git
3. URL'de gözüken numarayı al
4. Örnek: `roblox.com/users/4221507527/profile` → UserID = 4221507527

---

## 🧪 Test ve Doğrulama

### 1. Oyunu Başlat:
- Studio'da **Play** butonuna bas

### 2. Output Penceresini Kontrol Et:
Şunları görmelisin:
```
🎮 Admin Panel Sistemi Başlatılıyor...
✅ Administration klasörü bulundu
✅ AdminManager yüklendi
✅ AntiCheatSystem yüklendi
✅ EventLogger yüklendi
✅ Remotes klasörü hazır
🎖️  Admin oyuncu katıldı: [Senin Adın] (UserID: 4221507527)
   ✅ [Senin Adın] için IsAdmin attribute set edildi
```

### 3. Ekranı Kontrol Et:
- **Sağ alt köşede** 🔧 butonu görünmeli
- **F2 tuşuna** bas → Admin paneli açılmalı
- **Butona tıkla** → Admin paneli kapanmalı/açılmalı

### 4. Admin Paneli Kontrol Et:
- Dashboard sekmesi açılmalı
- Events sekmesinde olaylar görünmeli
- Commands sekmesinde komutlar olmalı
- Debug sekmesinde ayarlar olmalı

---

## ❗ Sık Yapılan Hatalar

### 1. Script Tipi Yanlış
❌ **Yanlış:** AdminClient → Script olarak oluşturmak
✅ **Doğru:** AdminClient → LocalScript olarak oluşturmak

❌ **Yanlış:** MainInit → LocalScript olarak oluşturmak
✅ **Doğru:** MainInit → Script olarak oluşturmak

❌ **Yanlış:** AdminManager → Script olarak oluşturmak
✅ **Doğru:** AdminManager → ModuleScript olarak oluşturmak

### 2. İsim Hataları
❌ **Yanlış:** "Adminstration" (typo)
✅ **Doğru:** "Administration"

❌ **Yanlış:** "AdminDataremote" (küçük 'r')
✅ **Doğru:** "AdminDataRemote" (büyük 'R')

### 3. Konum Hataları
❌ **Yanlış:** AdminClient → ServerScriptService'e koymak
✅ **Doğru:** AdminClient → StarterPlayerScripts'e koymak

❌ **Yanlış:** Remotes → ServerScriptService'e koymak
✅ **Doğru:** Remotes → ReplicatedStorage'a koymak

### 4. UserID Eklemeyi Unutmak
❌ **Yanlış:** AdminManager'ı olduğu gibi bırakmak
✅ **Doğru:** Satır 120'ye kendi UserID'ni eklemek

---

## 🎉 Tamamlandı!

Artık tam çalışır bir admin paneline sahipsin!

### Şimdi Ne Yapabilirsin:
- 🔧 Butona tıklayarak paneli aç/kapat
- ⌨️ F2 tuşuyla paneli aç/kapat
- 📊 Dashboard'dan sistem durumunu gör
- 📝 Events sekmesinden olayları takip et
- 🎮 Commands sekmesinden komutlar çalıştır
- ⚙️ Debug sekmesinden ayarları değiştir

### İhtiyacın Olursa:
- 📖 `OYUN_ICI_YAPILANMA.md` - Detaylı yapı bilgisi
- 🔍 `HANGI_DOSYALAR.md` - Dosya listesi ve durumları
- 📋 `OZET.md` - Hızlı özet
- 🆘 `Documentation/TROUBLESHOOTING.md` - Sorun giderme

**Başarılar!** 🎮✨
