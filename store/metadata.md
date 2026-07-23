# Manifest Alarm — App Store Bilgileri

Bu dosya App Store Connect'e girilecek metinlerin kaynağıdır.
Uygulama kimliği: `com.sharkvision.manifestalarm` · App ID: 6790958826

## Genel

| Alan | Değer |
|---|---|
| Ad | Manifest Alarm |
| Birincil dil | Türkçe |
| Kategori (birincil) | Sağlık ve Fitness |
| Kategori (ikincil) | Yaşam Tarzı |
| Yaş sınırı | 4+ |
| Fiyat | Ücretsiz |
| Gizlilik | Veri Toplanıyor (Data Collected) — Device ID + Advertising Data → Üçüncü Taraf Reklam, izleme (AdMob) |
| Destek URL | https://manifest-alarm.aether-proxy.workers.dev |
| Gizlilik URL | https://manifest-alarm.aether-proxy.workers.dev |

## Durum (23 Tem 2026) — Sürüm 1.3 (pazarlama görselleri) incelemede ✅

- 1.2 (reklam + 3 sn koruma) App Store'da CANLI (kullanıcı yayınladı)
- Sürüm 1.3: 5 yeni **pazarlama ekran görüntüsü** (store/pazarlama.ps1 ile üretildi: kozmik gradyan + altın başlık + telefon çerçevesi), build 23 (v1.3, kod değişikliği yok) ile incelemeye gönderildi, elle yayın
- Ekran görüntüsü sırası: sesli kilit / gerçek alarm / güne niyetle uyan / uyku hesabı / başarı
- NOT: ASC ekran görüntüsü yüklemesini otomasyon yapamıyor (tarayıcı dosya seçme penceresi); kullanıcı Masaüstündeki manifest-ekran-1..5.png dosyalarını "Choose File" ile yükledi, eski düz görseller silindi

## Durum (22 Tem 2026) — Sürüm 1.2 (reklamlı) incelemeye gönderildi ✅

- Sürüm 1.2, build 22 (v1.2, AdMob otomatik: TestFlight'ta test / App Store'da gerçek + kaydır-durdur 3 sn koruma) ile incelemede — build 21 çekilip 22 ile değiştirildi
- Açıklama + tanıtım metni (TR) güncellendi: "reklam yok/sunucu yok/hiçbir verin çıkmaz" ifadeleri kaldırıldı, AdMob açıklandı
- App Privacy → "Veri Toplanıyor": Device ID + Advertising Data → Üçüncü Taraf Reklam + izleme (yayınlandı, canlı)
- Gizlilik sayfasına (Cloudflare) AdMob bölümü eklendi (TR + EN)
- Yayın şekli: elle yayınla (onaydan sonra kontrol kullanıcıda) — 1.2 "Waiting for Review"
- Mağaza listesi yalnızca Türkçe (İngilizce yerelleştirme yayınlanmadı)

## Durum (16 Tem 2026)

App Store Connect'te GİRİLDİ ✅
- Alt başlık, tanıtım metni, açıklama, anahtar kelimeler (TR), destek/gizlilik URL
- Kategoriler: Sağlık ve Fitness + Yaşam Tarzı · İçerik hakları: üçüncü taraf içerik yok
- Yaş sınırı: 4+ (172 ülke) · Tıbbi cihaz değil beyanı
- Gizlilik: "Veri Toplanmıyor" yayınlandı · Gizlilik sayfası Cloudflare'de canlı
- Fiyat: Ücretsiz · Dağıtım: 175 ülke
- Derleme: Build 11 (v1.0) sürüme bağlandı
- İnceleme notları (reviewer'a nasıl test edileceği) girildi
- Yayın şekli: elle yayınla (onaydan sonra kontrol kullanıcıda)

EKSİK (kullanıcı gerekli) ⏳
- Ekran görüntüleri: 1242×2688 veya 1284×2778 (0/10). iPhone'dan çekilip bana verilecek, ben ölçeklerim.
- App Review iletişim: ad, soyad, telefon, e-posta (kişisel veri — kullanıcı kendi girmeli)
- Son "Add for Review" + Submit onayı

---

## Türkçe

### Alt başlık (30 karakter)
Manifestini söyle, güne başla

### Tanıtım metni (170 karakter)
Alarmı kapatmanın tek yolu manifestini yüksek sesle söylemek. Her gün yeni bir olumlama, 8 huzurlu alarm sesi ve frekans tonlarıyla güne niyetinle uyan. 🌞

### Açıklama
Sabahları alarmı kapatıp yatağa geri dönmek çok kolay. Manifest Alarm bunu değiştiriyor:
alarmı susturmanın tek yolu, manifest cümleni yüksek sesle söylemek.

Gözlerini açıyorsun, ekranda o günün olumlaması var, onu sesli okuyorsun ve alarm susuyor.
Güne şikâyetle değil, niyetle başlıyorsun.

GERÇEK BİR ALARM
Telefonun kilitliyken, uygulama kapalıyken, sessiz moddayken bile çalar. iPhone'un kendi
alarm sistemi (AlarmKit) üzerine kurulu — yani Saat uygulamasının alarmı kadar güvenilir.

SESLİ MANİFEST KİLİDİ
Manifest cümleni söylemeden alarm gerçekten kapanmaz. Söylemeden susturursan alarm
3 dakika sonra bir kez daha çalar. Kelimesi kelimesine mükemmel olmak zorunda değil —
sabah sesin kısık olur diye tanıma toleranslı çalışır, ekranda benzerlik oranını görürsün.

HER GÜN YENİ BİR MANİFEST
Kendi cümleni yazabilir ya da hazır havuzdan her gün otomatik yeni bir olumlama alabilirsin.
Odağını sen seçersin:
• İş ve Başarı
• Aşk ve İlişkiler
• Hayat ve Huzur
• Hepsi

HUZURLU ALARM SESLERİ
Sıçratan bir zil sesi yerine, kısık başlayıp yavaşça yükselen sekiz ses:
• Klasik alarm
• 432 Hz — Doğa Frekansı
• 528 Hz — Sevgi Frekansı
• 639 Hz — Uyum Frekansı
• 852 Hz — Sezgi Frekansı
• Müzik Kutusu
• Tibet Çanağı
• Om 136 Hz — Derin Ton

UYKU KARTI
"Şimdi uyursan 7 sa 20 dk uyursun" — bir sonraki alarmına göre canlı hesap.
Uyku hedefini belirle, hedefine göre en geç yatış saatini gör.

SENİN ATMOSFERİN
Beş arkaplan teması: Kozmik Gece, Gün Doğumu, Okyanus Derinliği, Orman Nefesi, Lavanta Sisi.

14 DİLDE
Türkçe, İngilizce, Almanca, İspanyolca, Fransızca, İtalyanca, Portekizce, Rusça, Arapça,
Hintçe, Endonezce, Japonca, Korece ve Çince. Manifestini kendi dilinde söylersin.

GİZLİLİK
Hesap yok, giriş yok. Sesin kaydedilmez ve saklanmaz; cihazın destekliyorsa konuşma tanıma
tamamen telefonunun içinde yapılır — manifestin telefonundan çıkmaz. Ücretsiz sürümde ekranın
altında Google AdMob reklamları gösterilir; alarm ve konuşma ekranlarında reklam yoktur.

Güne niyetinle uyan.

Gerekli: iOS 26 veya üzeri.

> Not: App Store metin alanları emoji (🌞) kabul etmiyor ("invalid character" hatası); açıklama
> ve tanıtım metninde emoji kullanılmadı.

### Anahtar kelimeler (100 karakter)
manifest,olumlama,alarm,affirmation,frekans,528hz,uyandırma,niyet,motivasyon,sabah,uyku,meditasyon

### Sürüm notları (1.0)
Manifest Alarm'ın ilk sürümü 🌞
• Manifestini söylemeden kapanmayan gerçek alarm
• Her gün yeni olumlama (İş, Aşk, Hayat veya hepsi)
• 8 alarm sesi: frekans tonları ve melodik sesler
• Uyku süresi kartı ve uyku hedefi
• 5 arkaplan teması, 14 dil

### Sürüm notları (1.2) — reklamlı sürüm, 22 Tem 2026 incelemeye gönderildi (build 22: reklam + 3 sn kaydır-durdur koruması)
• Artık ücretsiz: uygulama açıldı, dilediğin kadar kullan.
• Deneyimi sürdürebilmek için ekranın altında ince bir reklam şeridi eklendi; alarm ve konuşma ekranlarında reklam yok.
• Sesin hâlâ kaydedilmez ve saklanmaz.
• Küçük iyileştirmeler ve hata düzeltmeleri.

---

## English

### Subtitle (30 characters)
Speak your manifest to wake up

### Promotional text (170 characters)
The only way to stop the alarm is to say your manifest out loud. Wake up with intention — a new affirmation every day, 8 calming sounds and frequency tones. 🌞

### Description
It's far too easy to turn off the alarm and fall straight back to sleep. Manifest Alarm
changes that: the only way to silence it is to say your manifest sentence out loud.

You open your eyes, today's affirmation is on the screen, you read it aloud, and the alarm
stops. You start the day with intention instead of a groan.

A REAL ALARM
Rings even when your phone is locked, the app is closed, or your phone is on silent.
It's built on the iPhone's own alarm system (AlarmKit) — as reliable as the Clock app.

THE VOICE LOCK
The alarm doesn't truly stop until you speak your manifest. If you silence it without
speaking, it rings once more 3 minutes later. You don't have to be word-perfect — matching
is forgiving because morning voices are, and you see your match percentage on screen.

A NEW MANIFEST EVERY DAY
Write your own sentence, or let the app give you a fresh affirmation each day.
You choose your focus:
• Work & Success
• Love & Relationships
• Life & Peace
• All of them

CALMING ALARM SOUNDS
Instead of a jolt, eight sounds that start soft and rise gently:
• Classic alarm
• 432 Hz — Nature Frequency
• 528 Hz — Love Frequency
• 639 Hz — Harmony Frequency
• 852 Hz — Intuition Frequency
• Music Box
• Tibetan Bowl
• Om 136 Hz — Deep Tone

SLEEP CARD
"If you sleep now: 7 hr 20 min" — a live count based on your next alarm.
Set a sleep goal and see your latest possible bedtime.

YOUR ATMOSPHERE
Five backgrounds: Cosmic Night, Sunrise, Ocean Depth, Forest Breath, Lavender Mist.

IN 14 LANGUAGES
Turkish, English, German, Spanish, French, Italian, Portuguese, Russian, Arabic, Hindi,
Indonesian, Japanese, Korean and Chinese. Speak your manifest in your own language.

PRIVACY
No account, no sign-in. Your voice is never recorded or stored, and where your device
supports it, speech recognition happens entirely on your phone — your manifest never leaves
your device. The free version shows Google AdMob ads at the bottom of the screen; there are
no ads on the alarm or speech screens.

Wake up with intention.

Requires iOS 26 or later.

> Note: The App Store rejects emoji (🌞) in the description/promo fields ("invalid character");
> emoji were removed from those fields. (English localization is not published on the store —
> the listing is Turkish-only — but this draft is kept accurate.)

### Keywords (100 characters)
manifest,affirmation,alarm,clock,frequency,528hz,solfeggio,intention,morning,sleep,meditation,voice

### What's New (1.0)
The first release of Manifest Alarm 🌞
• A real alarm that won't stop until you speak your manifest
• A new affirmation every day (Work, Love, Life or all)
• 8 alarm sounds: frequency tones and melodic options
• Sleep duration card and sleep goal
• 5 background themes, 14 languages

---

## App Review Notes (İnceleyene not — İngilizce girilecek)

Manifest Alarm is an alarm clock that you dismiss by speaking an affirmation
("manifest") out loud, instead of tapping snooze.

HOW TO TEST QUICKLY (no need to wait for a scheduled alarm):
1. On first launch, pick any background theme and any manifest focus, then tap "Get Started".
2. Grant the alarm, microphone and speech recognition permissions when prompted.
3. Scroll to the bottom and tap "Test in 10 seconds".
4. Lock the phone (optional) and wait 10 seconds for the alarm to ring.
5. On the system alarm alert, tap the "Say the Manifest" button. This opens the app.
6. The manifest sentence is displayed in large text on screen. Read that exact sentence
   out loud. The alarm stops and a success message appears.

NOTES:
- The app interface and the manifest sentences follow the device language. Setting the
  device to English shows everything in English.
- Matching is intentionally tolerant (about 72% similarity), so you do not need to be
  word-perfect.
- The alarm alert also has a system "Stop" button. If the alarm is stopped without speaking
  the manifest, a single backup alarm is scheduled 3 minutes later by design — this is the
  app's core feature (preventing users from ignoring their morning intention). It rings only
  once, and never if the manifest was spoken.
- Speech recognition uses Apple's on-device recognition where available. No audio is
  recorded, stored, or sent to any server of ours. The app has no backend at all.
- No account or login is required. There are no purchases.
