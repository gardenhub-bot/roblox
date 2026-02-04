# 🎮 ROBLOX OYUNU İÇİNDE KLASÖR YAPILANMASI

**Önemli:** Bu rehber, dosyaları **Roblox Studio içinde** nasıl organize edeceğinizi gösterir.  
GitHub klasörleri sadece kod organizasyonu içindir. Oyunda çalışması için aşağıdaki yapıyı kullanmalısınız.

---

## 📋 ROBLOX STUDIO İÇİNDE OLUŞTURULACAK YAPILANMA

```
🎮 Roblox Oyununuz
│
├── 📦 ServerScriptService
│   ├── 📁 Administration          (Folder)
│   │   └── 📜 AdminManager        (ModuleScript)
│   │
│   ├── 📁 Security                (Folder)
│   │   └── 📜 AntiCheatSystem     (ModuleScript)
│   │
│   ├── 📁 Systems                 (Folder)
│   │   └── 📜 EventLogger         (ModuleScript)
│   │
│   └── 📜 MainInitScript          (Script - Normal Script)
│
├── 📦 ReplicatedStorage
│   ├── 📁 Modules                 (Folder)
│   │   └── 📜 DebugConfig         (ModuleScript)
│   │
│   └── 📁 Remotes                 (Folder)
│       ├── 📡 AdminDataRemote     (RemoteEvent)
│       ├── 📡 AdminCommandRemote  (RemoteFunction)
│       └── 📡 EventLogRemote      (RemoteEvent)
│
└── 📦 StarterPlayer
    └── 📦 StarterPlayerScripts
        └── 📜 AdminClient         (LocalScript)
```

---

## 🔨 ADIM ADIM OLUŞTURMA

### 1️⃣ ServerScriptService Klasörleri

**Adım 1:** ServerScriptService'e sağ tıklayın → Insert Object → Folder
- İsmi: `Administration`

**Adım 2:** Administration klasörüne sağ tıklayın → Insert Object → ModuleScript
- İsmi: `AdminManager`
- İçeriğe `AdminPanelSystem/Server/AdminManager.lua` dosyasının içeriğini yapıştırın

**Adım 3:** ServerScriptService'e sağ tıklayın → Insert Object → Folder
- İsmi: `Security`

**Adım 4:** Security klasörüne sağ tıklayın → Insert Object → ModuleScript
- İsmi: `AntiCheatSystem`
- İçeriğe `AdminPanelSystem/Server/AntiCheatSystem.lua` dosyasının içeriğini yapıştırın

**Adım 5:** ServerScriptService'e sağ tıklayın → Insert Object → Folder
- İsmi: `Systems`

**Adım 6:** Systems klasörüne sağ tıklayın → Insert Object → ModuleScript
- İsmi: `EventLogger`
- İçeriğe `AdminPanelSystem/Server/EventLogger.lua` dosyasının içeriğini yapıştırın

**Adım 7:** ServerScriptService'e sağ tıklayın → Insert Object → Script (Normal Script)
- İsmi: `MainInitScript`
- İçeriğe `AdminPanelSystem/Scripts/MainInitScript.lua` dosyasının içeriğini yapıştırın

### 2️⃣ ReplicatedStorage Klasörleri

**Adım 1:** ReplicatedStorage'e sağ tıklayın → Insert Object → Folder
- İsmi: `Modules`

**Adım 2:** Modules klasörüne sağ tıklayın → Insert Object → ModuleScript
- İsmi: `DebugConfig`
- İçeriğe `AdminPanelSystem/Shared/DebugConfig.lua` dosyasının içeriğini yapıştırın

**Adım 3:** ReplicatedStorage'e sağ tıklayın → Insert Object → Folder
- İsmi: `Remotes`

**Adım 4:** Remotes klasörüne şunları ekleyin:
- Insert Object → RemoteEvent → İsmi: `AdminDataRemote`
- Insert Object → RemoteFunction → İsmi: `AdminCommandRemote`
- Insert Object → RemoteEvent → İsmi: `EventLogRemote`

### 3️⃣ StarterPlayer Klasörü

**Adım 1:** StarterPlayer → StarterPlayerScripts'e sağ tıklayın

**Adım 2:** Insert Object → LocalScript
- İsmi: `AdminClient`
- İçeriğe `AdminPanelSystem/Client/AdminClient.lua` dosyasının içeriğini yapıştırın

---

## ✅ KONTROL LİSTESİ

Aşağıdaki her şeyi oluşturdunuz mu?

### ServerScriptService ✓
- [ ] Administration klasörü var mı?
  - [ ] AdminManager ModuleScript'i var mı?
- [ ] Security klasörü var mı?
  - [ ] AntiCheatSystem ModuleScript'i var mı?
- [ ] Systems klasörü var mı?
  - [ ] EventLogger ModuleScript'i var mı?
- [ ] MainInitScript (Script) var mı?

### ReplicatedStorage ✓
- [ ] Modules klasörü var mı?
  - [ ] DebugConfig ModuleScript'i var mı?
- [ ] Remotes klasörü var mı?
  - [ ] AdminDataRemote (RemoteEvent) var mı?
  - [ ] AdminCommandRemote (RemoteFunction) var mı?
  - [ ] EventLogRemote (RemoteEvent) var mı?

### StarterPlayer ✓
- [ ] StarterPlayerScripts içinde AdminClient (LocalScript) var mı?

---

## 🎯 DOSYA TİPLERİ AÇIKLAMASI

| Dosya Adı | Roblox Tipi | Nerede |
|-----------|-------------|---------|
| AdminManager | **ModuleScript** | ServerScriptService/Administration/ |
| AntiCheatSystem | **ModuleScript** | ServerScriptService/Security/ |
| EventLogger | **ModuleScript** | ServerScriptService/Systems/ |
| MainInitScript | **Script** (Normal Script) | ServerScriptService/ |
| DebugConfig | **ModuleScript** | ReplicatedStorage/Modules/ |
| AdminClient | **LocalScript** | StarterPlayer/StarterPlayerScripts/ |
| AdminDataRemote | **RemoteEvent** | ReplicatedStorage/Remotes/ |
| AdminCommandRemote | **RemoteFunction** | ReplicatedStorage/Remotes/ |
| EventLogRemote | **RemoteEvent** | ReplicatedStorage/Remotes/ |

---

## 🚀 DOĞRULAMA

Oyunu başlattığınızda Output penceresinde şunları görmelisiniz:

```
✅ DebugConfig yüklendi
✅ AntiCheatSystem yüklendi
✅ EventLogger yüklendi
✅ AdminManager yüklendi
🎉 Admin sistem başlatıldı!
```

Eğer herhangi bir hata görürseniz:
1. Dosya isimlerini kontrol edin (büyük/küçük harf önemli!)
2. Dosya tiplerini kontrol edin (ModuleScript, Script, LocalScript)
3. Klasör yapısını kontrol edin
4. Remotes klasöründeki nesneleri kontrol edin

---

## ⚠️ SIKLKÇA YAPILAN HATALAR

❌ **ModuleScript yerine Script kullanmak**
- AdminManager, AntiCheatSystem, EventLogger, DebugConfig → ModuleScript olmalı

❌ **LocalScript yerine Script kullanmak**
- AdminClient → LocalScript olmalı

❌ **Yanlış klasör ismi**
- "Administration" değil "admin" yazmak
- Büyük/küçük harf önemli!

❌ **Remotes klasörünü unutmak**
- Remotes klasörü ve içindeki 3 nesne mutlaka gerekli

❌ **MainInitScript'i LocalScript yapmak**
- MainInitScript normal Script olmalı, LocalScript değil

---

## 💡 İPUÇLARI

✅ **Kopyala-Yapıştır Kullanın**
- GitHub'dan kod alırken tüm içeriği seçip kopyalayın
- Roblox'ta oluşturduğunuz script'in içine yapıştırın

✅ **Adım Adım İlerleyin**
- Bir klasör oluşturun
- İçine gerekli dosyaları ekleyin
- Sonraki klasöre geçin

✅ **Test Edin**
- Her büyük adımdan sonra oyunu test edin
- Output'ta hata var mı kontrol edin

✅ **Yedek Alın**
- Dosyaları ekledikten sonra "File → Publish to Roblox" yapın
- Böylece yedeklenmiş olur

---

## 📚 DAHA FAZLA YARDIM

Sorun yaşıyorsanız:
1. `DUZELTMELER.md` dosyasına bakın
2. Output penceresindeki hata mesajlarını okuyun
3. Dosya isimlerini tekrar kontrol edin
4. Klasör yapısını yukarıdaki şema ile karşılaştırın

---

**Başarılar! Admin panel sisteminiz hazır olacak! 🎉**
