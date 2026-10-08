# Okul Panelleri: Kurulum ve İlk Okul

Bu belge, okul özelliklerini (müdür, öğretmen, veli, öğrenci panelleri) canlıya almak ve ilk okulu açmak için gereken adımları anlatır.

## 1. Sunucu kurulumu (bir kez)

Supabase SQL Editor'de, sırayla ve henüz çalıştırılmamış olanları çalıştırın:

1. `supabase_migrations/19_yayin_oncesi_sikilastirma.sql`
2. `supabase_migrations/20_asistan_genel_kota.sql`
3. `supabase_migrations/21_okul_yapisi.sql`
4. `supabase_migrations/22_okul_raporlama.sql`

Dosyaların hepsi yeniden çalıştırılabilir; ikinci kez çalıştırmak veriyi silmez. 21 ve 22 bu makinede gerçek bir veritabanında denenmedi (yerel PostgreSQL yok); yalnızca PostgreSQL ayrıştırıcısıyla sözdizimi doğrulandı. İlk çalıştırmada hata çıkarsa hata iletisini olduğu gibi iletin.

Migration'lar kurulmadan da uygulama çalışır: okul ekranları "Okul özellikleri sunucuda henüz etkinleştirilmedi" iletisini gösterir, öğrenci tarafı etkilenmez.

## 2. İlk okulu açmak

1. Yönetici (admin) hesabıyla girin: Profil › Admin paneli › **Okullar** › Okul ekle.
2. Listede çıkan **müdür kodunu** (M-XXXX-XXXX) müdüre iletin. Kod tek kullanımlıktır, 30 gün geçerlidir.
3. Müdür uygulamayı açar: **Müdür** kartı › hesap açar › adını ve okul kodunu girer.
4. Müdür, Yönetim sekmesinden şubeleri ekler. Her şubenin bir **öğrenci katılım kodu** (S-...) olur.
5. Müdür, her öğretmen için bir **öğretmen kodu** (T-...) üretir; rehber ya da branş (ders) olarak.
6. Öğretmen **Öğretmen** kartından hesap açıp kodu girer. Müdür, Yönetim sekmesinde öğretmene dokunup şubelerini atar.
7. Öğrenci (yeni ya da mevcut hesap): Profil › **Okulum ve velim** › şube kodunu girer, bilgilendirme ekranını kabul eder.
8. Öğrenci aynı ekrandan **veli kodu** (V-...) üretir; veli **Veli** kartından hesap açıp kodu girer.

## 3. Kim ne görür

| Rol | Görür | Görmez |
| --- | --- | --- |
| Rehber öğretmen | Atandığı şubelerdeki öğrencilerin süre, program uyumu, konu, deneme, test verisi; uyarılar; görüşme notları | Ruh hâli, asistan sohbetleri, bahçe, notlar |
| Branş öğretmeni | Atandığı şubelerde yalnızca kendi dersinin süre ve test verisi | Diğer dersler, uyarılar, görüşme notları |
| Veli | Yalnızca kod veren çocuğunun haftalık özeti ve dört haftalık geçmişi | Görüşme notları, diğer öğrenciler |
| Müdür | Şube toplamları, katılım oranı, uyarı sayısı | Tek tek öğrenci verisi |

Süre, sunucunun ölçtüğü odak oturumlarından gelir; öğrenci sayaç kullanmadan çalıştıysa o çalışma panelde görünmez (yalnızca o gün hiç ölçüm yoksa öğrencinin kendi kaydı gösterilir).

## 4. Okul hesabında değişenler

- Öğrencinin Topluluk sekmesi **Okulum** olur: sınıf ormanı, öğretmen önerileri, veli bağlantısı.
- Açık akış ve herkese açık etüt odaları kapanır; sunucu da paylaşımı engeller.
- Kişi sıralaması yoktur; yalnızca şube toplamı ve öğrencinin kendi katkısı gösterilir (MEB 2026/70 genelgesi).
- Öğretmen "ödev" değil "öneri" gönderir; öğrenci isterse programına ekler.

## 5. Okul görüşmesinden önce

- Gizlilik politikasına veri sorumlusu kimliği eklenmeli ve destek e-postası tekleştirilmeli.
- Okulla yazılı veri işleme sözleşmesi yapılmalı; 18 yaş altı için veli onay formunu okul toplar.
- Bölüm 3'teki tablo ve politika metninin "Okul ve Veli Paylaşımı" bölümü bir KVKK uzmanına okutulmalı.
