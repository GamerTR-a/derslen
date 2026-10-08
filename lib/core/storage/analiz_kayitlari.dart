/// Gelişim analizleri için tutulan, kullanıcıya özel (buluta senkron) günlük
/// kayıtların anahtarları. Hepsi `StorageService.getMap/setMap` ile okunur ve
/// tek bir Map içinde `YYYY-MM-DD` anahtarlarıyla tutulur; böylece bir dönem
/// analizi tek okumayla yapılır.
library;

class AnalizKayitlari {
  AnalizKayitlari._();

  /// { 'YYYY-MM-DD': dakika }
  static const calismaGunluk = 'calisma_gunluk_log';

  /// { 'YYYY-MM-DD': { 'Matematik': dakika, ... } }
  static const calismaDers = 'calisma_ders_log';

  /// { 'YYYY-MM-DD': [planlananBlok, tamamlananBlok, planlananDk, tamamlananDk] }
  static const planUyum = 'plan_uyum_log';

  /// { 'YYYY-MM-DD': [enerji, odak, stres] }
  static const checkin = 'checkin_log';

  /// { 'YYYY-MM-DD': [tamamlananKonu, zayifKonu] }
  static const konuIlerleme = 'konu_ilerleme_log';

  /// { 'items': [ { tarih, ders, dogru, yanlis, bos, saniye }, ... ] }
  static const testGecmisi = 'test_gecmisi';

  /// Konu bazında test sonuçları (okul raporları için):
  /// { 'YYYY-MM-DD': { 'Ders>Konu': [dogru, yanlis, bos] } } — son 60 gün tutulur.
  static const testKonu = 'test_konu_log';

  /// Haftalık ders programı (bu hafta) ve ayarları.
  static const programAyar = 'ders_programi_ayar';
  static const haftalikProgram = 'haftalik_program';

  /// Öğrencinin sabitlediği haftalık program şablonu: { 'gunler': [[blok…] × 7] }
  static const programSablon = 'program_sablon';

  /// Testlerde yanlış yapılan hazır sorular: { soruId: yanlışSayısı }
  static const testYanlislar = 'test_yanlis_sorular';

  /// Uygulama içi denemeler: { 'items': [ { tarih, baslik, sinif, dogru, yanlis, bos, saniye }, … ] }
  static const denemeGecmisi = 'deneme_gecmisi';

  /// { 'YYYY-MM-DD': [blokId, ...] } — son 21 gün tutulur.
  static const planTamamlanan = 'plan_tamamlanan';

  /// Kayıtların en fazla ne kadar geriye tutulacağı (gün).
  static const saklamaGunu = 400;
}

/// Tarih anahtarlı bir kayıttan [saklamaGunu]'ndan eski girdileri atar.
Map<String, dynamic> eskiKayitlariBudanmis(Map<String, dynamic> kayit, {int gun = AnalizKayitlari.saklamaGunu}) {
  final sinir = DateTime.now().subtract(Duration(days: gun));
  kayit.removeWhere((k, _) {
    final t = DateTime.tryParse(k);
    return t != null && t.isBefore(sinir);
  });
  return kayit;
}

/// Uygulamadaki ders adlarını müfredat adlarıyla eşleştirir (ör. Çalış
/// ekranındaki "Edebiyat" → "Türk Dili ve Edebiyatı").
String dersAdiNormalize(String ders) {
  switch (ders.trim()) {
    case 'Edebiyat':
      return 'Türk Dili ve Edebiyatı';
    case '':
      return 'Genel';
    default:
      return ders.trim();
  }
}
