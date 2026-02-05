# TAM SCRIPTLER - KULLANIM KILAVUZU

Bu dosya, root'ta bulunan .md dosyalarındaki tam scriptlerin nasıl kullanılacağını açıklar.

## 📦 DOSYALAR

### AdminClient_FULL (3 Parça):
- `AdminClient_FULL_Part1.md` - 1000 satır (UI sistem, yardımcı fonksiyonlar)
- `AdminClient_FULL_Part2.md` - 1000 satır (Sayfalar: Dashboard, Stats, Potions)
- `AdminClient_FULL_Part3.md` - 1000 satır (Sayfalar: Rot Skills, Events, Logs + Event handlers)

### AdminManager_FULL (2 Parça):
- `AdminManager_FULL_Part1.md` - 1500 satır (Config, events, stat/potion operations)
- `AdminManager_FULL_Part2.md` - 300 satır (Command handler, initialization)

## 🔧 NASIL BİRLEŞTİRİLİR

### Adım 1: .md Dosyalarını Aç
Her dosyayı aç ve içeriği kopyala.

### Adım 2: Markdown İşaretlerini Kaldır
Her dosyada şunları kaldır:
- Başlıktaki `# ...` satırı
- Başlangıçtaki ` ```lua `
- Sondaki ` ``` `

### Adım 3: Birleştir

**AdminClient_FULL.lua için:**
```
Part1 içeriği
+
Part2 içeriği  
+
Part3 içeriği
=
Tam AdminClient_FULL.lua (3000 satır)
```

**AdminManager_FULL.lua için:**
```
Part1 içeriği
+
Part2 içeriği
=
Tam AdminManager_FULL.lua (1800 satır)
```

### Adım 4: Roblox Studio'ya Kopyala

**AdminClient_FULL.lua:**
- StarterPlayer → StarterPlayerScripts
- Yeni LocalScript oluştur
- İsim: "AdminClient"
- Tüm kodu yapıştır

**AdminManager_FULL.lua:**
- ServerScriptService → Administration (veya AdminSystem)
- Yeni ModuleScript oluştur
- İsim: "AdminManager"
- Tüm kodu yapıştır
- Line 28'de UserID'nizi ekleyin: `[4221507527] = true,`

## 🎯 ÖZELLİKLER

### AdminClient:
- Event notification banner (üstte, animasyonlu, geri sayım)
- 6 Sayfa:
  - Dashboard (sistem durumu, hızlı erişim)
  - Stats (IQ, Coins, Essence, Aura, RSToken, Rebirths, EquippedSkill)
  - Potions (Luck, IQ, Aura, Essence, Speed verme)
  - Rot Skills (RSToken, EquippedSkill ayarlama)
  - Events (7 event tetikleme)
  - Logs (gerçek zamanlı log görüntüleme)
- Dropdown menüler (ESC/click-outside ile kapanır)
- F2 tuşu + toggle button
- Tam validation
- Başarı/hata bildirimleri

### AdminManager:
- 7 Event Sistemi:
  1. 2x IQ (IQMultiplier = 2)
  2. 2x Coins (CoinsMultiplier = 2)
  3. Lucky Hour (LuckMultiplier = 1.5)
  4. Speed Frenzy (SpeedMultiplier = 1.5)
  5. Golden Rush (EssenceMultiplier = 2)
  6. Rainbow Stars (AuraMultiplier = 2)
  7. Essence Rain (EssenceMultiplier = 1.5 + periyodik essence drop)
- Event süre yönetimi
- VFX broadcast (tüm oyuncular)
- Stat işlemleri (Add/Remove/Reset)
- Potion sistemi (PotionInventory'ye ekler)
- Rot Skill sistemi (RSToken, EquippedSkill 1-10)
- Rate limiting (10 komut/60 saniye)
- Operation history (son 100 komut)
- Exploit algılama
- EventLogger entegrasyonu
- AntiCheatSystem entegrasyonu

## 🔌 REMOTE'LAR (MEVCUT İSİMLER)

Şunları oluşturun (ReplicatedStorage → Remotes):
- AdminCommand (RemoteEvent)
- AdminDataUpdate (RemoteEvent)
- EventLogUpdate (RemoteEvent)
- EventVFXTrigger (RemoteEvent)

## ✅ KURULUM KONTROL LİSTESİ

- [ ] AdminClient_FULL_Part1.md açıldı ve kopyalandı
- [ ] AdminClient_FULL_Part2.md açıldı ve kopyalandı
- [ ] AdminClient_FULL_Part3.md açıldı ve kopyalandı
- [ ] 3 parça birleştirildi (markdown işaretleri kaldırıldı)
- [ ] StarterPlayerScripts'e AdminClient (LocalScript) olarak yapıştırıldı

- [ ] AdminManager_FULL_Part1.md açıldı ve kopyalandı
- [ ] AdminManager_FULL_Part2.md açıldı ve kopyalandı
- [ ] 2 parça birleştirildi (markdown işaretleri kaldırıldı)
- [ ] ServerScriptService/Administration'a AdminManager (ModuleScript) olarak yapıştırıldı
- [ ] Line 28'de UserID eklendi

- [ ] Remotes klasörü oluşturuldu (ReplicatedStorage)
- [ ] 4 RemoteEvent oluşturuldu
- [ ] Modules klasörü var (DebugConfig, AntiCheatSystem, EventLogger)

- [ ] MainInitScript.lua var ve AdminManager.Initialize() çağırıyor
- [ ] Oyun test edildi
- [ ] F2 tuşu ve toggle button çalışıyor
- [ ] Event sistemi test edildi

## 🚀 TEST

1. Play'e bas
2. Output'ta şunları gör:
   ```
   [AdminClient][INFO] Player is admin, initializing admin panel...
   [AdminClient][INFO] Admin Client initialized successfully! Press F2 or click the button to open panel.
   [AdminManager][INFO] Initializing AdminManager...
   [AdminManager][INFO] Admin player joined: YourName (UserID: 4221507527)
   [AdminManager][INFO] AdminManager initialized successfully!
   ```
3. F2'ye bas veya sağ alttaki 🔧 butonuna tıkla
4. Panel açılmalı
5. Dashboard'da sistem durumunu gör
6. Events sayfasına git
7. Bir event tetikle (örn: 2x IQ, 300 saniye)
8. Üstte event notification banner görünmeli
9. Stats sayfasında bir oyuncuya stat ekle
10. Başarı bildirimi görünmeli

## ❓ SORUN GİDERME

**Panel açılmıyor:**
- Output'ta hata var mı kontrol et
- IsAdmin attribute set edildi mi kontrol et: `print(game.Players.LocalPlayer:GetAttribute("IsAdmin"))`
- UserID doğru mu?

**Event çalışmıyor:**
- AdminManager Initialize() çağrıldı mı?
- Remotes doğru oluşturuldu mu?
- Output'ta hata var mı?

**Stat değişmiyor:**
- leaderstats var mı?
- Stat isimleri doğru mu? (IQ, Coins, Essence, Aura, RSToken, Rebirths, EquippedSkill)

## 📊 BOYUTLAR

- AdminClient_FULL: ~3000 satır (~51 KB)
- AdminManager_FULL: ~1800 satır (~19 KB)
- Toplam: ~4800 satır (~70 KB)

## 🎉 BAŞARILI!

Her şey kurulduysa, tam özellikli admin paneliniz hazır!

Tüm 7 event, stat yönetimi, potion, rot skill sistemi çalışıyor olmalı.

İyi kullanımlar! 🚀
