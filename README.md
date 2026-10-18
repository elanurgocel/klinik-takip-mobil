# Klinik Takip Sistemi

Klinik personelinin hasta kayıtlarını ve klinik ölçümlerini dijital olarak takip etmesini sağlayan mobil uygulama.

Uygulama Google Play'de yayındadır: [Klinik Takip Sistemi - Google Play](https://play.google.com/store/apps/details?id=com.gocel.kliniktakip)

## Özellikler

**Hesap işlemleri**
- Personel kaydı ve girişi
- Şifremi unuttum ile geçici şifre alma
- Profil bilgilerini ve şifreyi güncelleme

**Hasta yönetimi**
- Yeni hasta kaydı (TC kimlik, ad soyad, adres, telefon)
- Hasta listesi, TC kimlik veya isimle arama
- Hasta silme (onay penceresiyle; hastaya ait tüm ölçümler de silinir)

**Klinik takip**
- Teşhis ve klinik ölçüm kaydı: tansiyon, nabız, ateş, oksijen düzeyi, notlar
- Hastaya ait geçmiş ölçümleri tarih sırasıyla görüntüleme
- Gün içinde yapılan ölçümlerin özet ekranı
- Hastaları mevcut durumlarına göre gruplayan rapor ekranı

## Mimari

Uygulama üç katmandan oluşur:

1. **Mobil uygulama (Flutter):** Kullanıcı arayüzü. Tüm veri işlemleri için HTTPS üzerinden REST API'ye istek gönderir.
2. **Backend API (.NET 6 Web API):** İş kurallarını yürütür ve Entity Framework Core ile veritabanına erişir. Docker ile paketlenip Render üzerinde çalışır.
3. **Veritabanı (PostgreSQL):** Kullanıcı, hasta ve klinik ölçüm verilerini saklar. Neon üzerinde (AWS Frankfurt bölgesi) barındırılır.

| Katman | Teknoloji | Barındırma |
|---|---|---|
| Mobil uygulama | Flutter, Dart | Google Play |
| Backend API | C#, ASP.NET Core 6 Web API, Entity Framework Core | Render (Docker) |
| Veritabanı | PostgreSQL | Neon (AWS Frankfurt) |

Backend API ayrı bir repoda tutulmaktadır.

## Proje Yapısı

```
lib/
├── main.dart                           # Uygulamanın giriş noktası
├── api_config.dart                     # API adresi (tek noktadan yönetim)
├── login_page.dart                     # Giriş ekranı
├── register_page.dart                  # Kayıt ekranı
├── dashboard_page.dart                 # Ana sayfa / günlük özet
├── patients_page.dart                  # Hasta listesi, arama, silme ve detay
├── new_patient_registration_page.dart  # Yeni hasta kaydı
├── new_patient_data_sheet.dart         # Teşhis ve ölçüm girişi
├── reports_page.dart                   # Durum raporları
├── settings_page.dart                  # Profil ve şifre ayarları
├── app_header_actions.dart
└── header_action_panels.dart
```

## Kurulum

[Flutter SDK](https://docs.flutter.dev/get-started/install) kurulu olmalıdır.

```bash
# Bağımlılıkları yükleyin
flutter pub get

# Bağlı cihazda veya emülatörde çalıştırın
flutter run
```

Uygulamanın bağlandığı API adresi `lib/api_config.dart` dosyasında tanımlıdır:

```dart
const String apiBaseUrl = "https://kliniktakipapi.onrender.com";
```

**Not:** API ücretsiz planda çalıştığı için bir süre kullanılmadığında uyku moduna geçer. Uzun bir aradan sonraki ilk istek yaklaşık bir dakika sürebilir.

## Geliştirici

Ela Nur Göçel - [GitHub](https://github.com/elanurgocel)
