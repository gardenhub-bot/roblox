# 📊 DOSYA YAPISI - Görsel Rehber

## 🗂️ YENİ DÜZEN

```
📦 roblox/
│
├── 📄 BASLA.md                        ← İLK BURADAN BAŞLA!
│
└── 📁 AdminPanelSystem/               ← ANA KLASÖR
    │
    ├── 📄 README.md                   ← Sisteme giriş
    ├── 📄 DUZELTMELER.md              ← NE YAPACAKSIN? (ÖNEMLİ!)
    ├── 📄 HANGI_DOSYALAR.md           ← HANGİ DOSYALAR? (ÖNEMLİ!)
    │
    ├── 📁 Server/                     ← Sunucu scriptleri
    │   ├── AdminManager.lua           (ModuleScript)
    │   ├── AntiCheatSystem.lua        (ModuleScript)
    │   └── EventLogger.lua            (ModuleScript)
    │
    ├── 📁 Client/                     ← İstemci scriptleri
    │   └── AdminClient.lua            (LocalScript) ⭐ GÜNCELLEME GEREKLİ
    │
    ├── 📁 Shared/                     ← Ortak modüller
    │   └── DebugConfig.lua            (ModuleScript)
    │
    ├── 📁 Scripts/                    ← Yardımcı scriptler
    │   ├── MainInitScript.lua         (Script - Başlatma)
    │   └── TestAdminSystem.lua        (Script - Test)
    │
    └── 📁 Documentation/              ← Eski dökümanlar (referans)
        ├── ADMIN_SYSTEM_GUIDE.md
        ├── HIZLI_BASLANGIC.md
        ├── TROUBLESHOOTING.md
        └── ... (diğer .md dosyaları)
```

---

## 🎯 HANGİ DOSYA NE İŞE YARIYOR?

### 🔴 MUTLAKA OKUNACAKLAR

| Dosya | Nerede | Ne İçeriyor |
|-------|--------|-------------|
| **BASLA.md** | Kök dizin | İlk giriş noktası |
| **README.md** | AdminPanelSystem/ | Sistem tanıtımı |
| **DUZELTMELER.md** | AdminPanelSystem/ | Ne yapacağın adım adım |
| **HANGI_DOSYALAR.md** | AdminPanelSystem/ | Hangi dosyalar değişti |

### 🎮 OYUN DOSYALARI (LUA)

#### Sunucu Tarafı (Server/)
- **AdminManager.lua** - Ana admin yönetimi
- **AntiCheatSystem.lua** - Anti-cheat sistemi
- **EventLogger.lua** - Event kayıt sistemi

#### İstemci Tarafı (Client/)
- **AdminClient.lua** ⭐ - Admin panel UI (GÜNCELLEME GEREKLİ)

#### Ortak (Shared/)
- **DebugConfig.lua** - Debug ayarları

#### Yardımcılar (Scripts/)
- **MainInitScript.lua** - Sistem başlatıcı
- **TestAdminSystem.lua** - Test scripti (opsiyonel)

### 📚 DÖKÜMANLAR (Documentation/)
Referans için eski dökümanlar. Yeni güncellemeler için DUZELTMELER.md yeterli!

---

## 🚀 ROBLOX'TA KLASÖR YAPISI

Bu dosyaları Roblox Studio'da şöyle yerleştir:

```
🎮 Roblox Studio
│
├── ServerScriptService
│   ├── Administration/
│   │   └── AdminManager (ModuleScript)
│   ├── Security/
│   │   └── AntiCheatSystem (ModuleScript)
│   ├── Systems/
│   │   └── EventLogger (ModuleScript)
│   └── MainInit (Script)
│
├── ReplicatedStorage
│   ├── Modules/
│   │   └── DebugConfig (ModuleScript)
│   └── Remotes/
│       └── AdminRemotes (Folder)
│           └── AdminData (RemoteEvent)
│
└── StarterPlayer
    └── StarterPlayerScripts/
        └── AdminClient (LocalScript)
```

---

## ✅ HIZLI KONTROL LİSTESİ

```
[ ] BASLA.md okudum
[ ] AdminPanelSystem/ klasörünü açtım
[ ] DUZELTMELER.md okudum
[ ] HANGI_DOSYALAR.md kontrol ettim
[ ] AdminClient.lua'yı güncelledim
[ ] Admin ID'mi ekledim (4221507527)
[ ] Dosyaları Roblox'a kopyaladım
[ ] MainInit scriptini oluşturdum
[ ] Oyunu test ettim
[ ] Buton görünüyor ✓
[ ] F2 çalışıyor ✓
[ ] Admin paneli açılıyor ✓
```

---

## 💡 İPUCU

**Karışık mı geldi?**  
Sadece şunu yap:
1. `AdminPanelSystem/DUZELTMELER.md` aç
2. Oradaki adımları takip et
3. Bitti!

Başka hiçbir şeye bakma! 😊

---

_Son Güncelleme: 04 Şubat 2026 - v2.1_
