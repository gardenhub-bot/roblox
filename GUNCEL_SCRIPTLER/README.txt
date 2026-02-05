===============================================
GUNCEL_SCRIPTLER - ÇALIŞAN ADMIN PANELİ SİSTEMİ
===============================================

Bu klasördeki scriptler kullanıcının ÇALIŞAN admin paneli sistemidir.
Oyunun mevcut yapısıyla entegre edilmiştir (DataKeyManager, GameConfig, InventoryConfig).

===============================================
DOSYALAR VE YERLEŞİM
===============================================

1. AdminManager.lua (461 satır)
   Yer: ServerScriptService/Systems/AdminManager
   Tür: ModuleScript
   
   Özellikler:
   - ✅ Rot Skill sistemi (MapID bazlı)
   - ✅ Rot Skill Token verme
   - ✅ İksir verme (Small/Medium/Big boyutları)
   - ✅ Stat verme (IQ, Coins, Essence, Aura, Luck, MaxHatch, vb.)
   - ✅ Oyuncu verilerini resetleme
   - ✅ Offline player desteği (DataStore)
   - ✅ DataKeyManager entegrasyonu

2. AdminClient.lua (803 satır)
   Yer: ServerScriptService/Systems/AdminManager/AdminClient
   Tür: LocalScript
   
   Özellikler:
   - ✅ Modern UI (dropdown, tab sistemi)
   - ✅ 5 sayfa: Statlar, İksirler, Rot Skills, Events, Logs
   - ✅ Click-outside ve ESC tuşu ile dropdown kapatma
   - ✅ Gerçek zamanlı event bildirimleri
   - ✅ Stat verme UI
   - ✅ İksir verme UI (tür ve boyut seçimi)
   - ✅ Rot Skill verme UI (MapID, SkillIndex, Token)
   - ✅ Event başlatma UI

3. EventManager.lua (539 satır)
   Yer: ServerScriptService/EventSystem/EventManager
   Tür: ModuleScript
   
   Özellikler:
   - ✅ 7 Event türü (2xIQ, 2xCoins, Lucky Hour, Speed Frenzy, Golden Rush, Rainbow Stars, Essence Rain)
   - ✅ Multiplier sistem (Attribute bazlı)
   - ✅ Event VFX tetikleme
   - ✅ Event süresi ve countdown
   - ✅ Admin kontrolü ile event başlatma
   - ✅ Tüm oyunculara broadcast

4. AntiCheatSystem.lua
   Yer: ServerScriptService/Administration/AntiCheatSystem
   Tür: ModuleScript

5. EventLogger.lua
   Yer: ServerScriptService/Administration/EventLogger
   Tür: ModuleScript

6. DebugConfig.lua
   Yer: ReplicatedStorage/Modules/DebugConfig
   Tür: ModuleScript

7. MainInitScript.lua
   Yer: ServerScriptService/Administration/MainInit
   Tür: Script

===============================================
ROBLOX STUDIO'DA YERLEŞİM
===============================================

ServerScriptService/
├── Systems/
│   └── AdminManager (ModuleScript)
│       └── AdminClient (LocalScript) ← AdminClient.lua
├── EventSystem/
│   └── EventManager (ModuleScript) ← EventManager.lua
└── Administration/
    ├── AntiCheatSystem (ModuleScript)
    ├── EventLogger (ModuleScript)
    └── MainInit (Script)

ReplicatedStorage/
├── Modules/
│   ├── DebugConfig (ModuleScript)
│   ├── GameConfig (ModuleScript) ← Oyunun kendi config'i
│   └── InventoryConfig (ModuleScript) ← Oyunun kendi config'i
└── Remotes/
    ├── AdminEvent (RemoteEvent)
    ├── AdminControlBindable (BindableEvent)
    └── DrinkPotionEvent (RemoteEvent)

===============================================
ÖZEL NOTLAR
===============================================

1. ADMIN LİSTESİ (AdminManager.lua satır 11-14):
   local Admins = {
       ["ChrolloLucifer"] = true,
       ["CavusAlah"] = true,
   }

2. BAĞIMLILIKLAR:
   - DataKeyManager (ServerScriptService/Systems)
   - GameConfig (ReplicatedStorage/Modules)
   - InventoryConfig (ReplicatedStorage/Modules)
   - Bu modüller oyunun kendi sistemidir!

3. REMOTE EVENTS:
   - AdminEvent: Client → Server komutlar için
   - AdminControlBindable: EventManager kontrolü için
   - DrinkPotionEvent: İksir içme için

4. ÇALIŞAN ÖZELLİKLER:
   ✅ Stat verme (online ve offline)
   ✅ İksir verme (boyut seçimi ile)
   ✅ Rot Skill verme (MapID bazlı)
   ✅ Rot Skill Token verme
   ✅ Event başlatma (7 tür)
   ✅ Oyuncu verisi resetleme
   ✅ Modern UI
   ✅ Gerçek zamanlı bildirimler

===============================================
KURULUM
===============================================

1. AdminManager.lua'yı ServerScriptService/Systems/AdminManager (ModuleScript) olarak yerleştir
2. AdminClient.lua'yı AdminManager'ın içine AdminClient (LocalScript) olarak yerleştir
3. EventManager.lua'yı ServerScriptService/EventSystem/EventManager (ModuleScript) olarak yerleştir
4. Diğer scriptleri (AntiCheatSystem, EventLogger, DebugConfig, MainInit) yerleştir
5. Admin listesine kendi adını ekle (AdminManager.lua satır 11-14)
6. Oyunu çalıştır!

===============================================
TEST
===============================================

1. Oyunu başlat
2. Sol alt köşede 🛡️ butonu görünmeli
3. Butona tıkla → Admin paneli açılır
4. "Statlar" sekmesinde bir oyuncuya stat verebilirsin
5. "İksirler" sekmesinde iksir verebilirsin
6. "Rot Skills" sekmesinde rot skill/token verebilirsin
7. "Events" sekmesinde event başlatabilirsin

===============================================
SORUN GİDERME
===============================================

Eğer panel açılmazsa:
1. Admin listesinde adının doğru yazıldığını kontrol et
2. Output penceresine "❌ Yetkisiz admin girişimi" yazıyorsa, isim yanlış
3. 🛡️ butonu gözükmüyorsa, AdminClient LocalScript olarak doğru yerde mi kontrol et

Komutlar çalışmıyorsa:
1. RemoteEvent'lerin olduğundan emin ol (AdminEvent, AdminControlBindable)
2. DataKeyManager, GameConfig, InventoryConfig modüllerinin var olduğundan emin ol
3. Output'ta hata mesajı var mı kontrol et

===============================================
