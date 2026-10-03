/// YKS Koçu — Uygulama genelinde kullanılan sabitler.
library;

import 'dart:ui';

/// YKS sınav tarihi: 21 Haziran 2026, saat 10:00
final DateTime yksDate = DateTime(2026, 6, 21, 10, 0, 0);

/// Bir sonraki YKS tarihi. [yksDate] geçmişte kaldıysa, ÖSYM yeni tarihi
/// açıklayana kadar aynı gün bir sonraki yıla kaydırılarak tahmin edilir.
DateTime sonrakiYksTarihi([DateTime? simdi]) {
  final t = simdi ?? DateTime.now();
  var tarih = yksDate;
  while (tarih.isBefore(t)) {
    tarih = DateTime(tarih.year + 1, tarih.month, tarih.day, tarih.hour);
  }
  return tarih;
}

/// Bir sonraki YKS'ye kalan tam gün sayısı.
int yksKalanGun() {
  final b = DateTime.now();
  return sonrakiYksTarihi(b).difference(DateTime(b.year, b.month, b.day)).inDays;
}

/// Ders renkleri — TYT/AYT konular ve flashkartlar için kullanılır.
const Map<String, Color> dersRenkleri = {
  // TYT
  'Türkçe': Color(0xFF6366F1),
  'Matematik': Color(0xFFF59E0B),
  'Fen Bilimleri': Color(0xFF10B981),
  'Sosyal Bilimler': Color(0xFFEC4899),
  // AYT
  'Fizik': Color(0xFF3B82F6),
  'Kimya': Color(0xFF8B5CF6),
  'Biyoloji': Color(0xFF14B8A6),
  'Türk Dili ve Edebiyatı': Color(0xFFF97316),
  'Tarih': Color(0xFFEF4444),
  'Coğrafya': Color(0xFF84CC16),
  'Felsefe Grubu': Color(0xFF0EA5E9),
  'Din Kültürü': Color(0xFF64748B),
  // Çalış ekranındaki ek ders adları
  'Geometri': Color(0xFFD97706),
  'Edebiyat': Color(0xFFF97316),
  'Felsefe': Color(0xFF0EA5E9),
  'İngilizce': Color(0xFF6D28D9),
  // Flashkart özel
  'edebiyat': Color(0xFF8B5CF6),
  'tarih': Color(0xFFEF4444),
  'biyoloji': Color(0xFF10B981),
  'cografya': Color(0xFF3B82F6),
  'fizik': Color(0xFFF59E0B),
  'kimya': Color(0xFFEC4899),
  'matematik': Color(0xFFD97706),
  'geometri': Color(0xFFB45309),
  'turkce': Color(0xFF6366F1),
  'felsefe': Color(0xFF0EA5E9),
  'din': Color(0xFF64748B),
  'ingilizce': Color(0xFF6D28D9),
  'yanlislar': Color(0xFFEF4444),
  'ozel': Color(0xFF0EA5E9),
};

/// Tanımlı rengi olmayan (kullanıcının eklediği) dersler için palet.
const List<Color> _ozelDersPaleti = [
  Color(0xFF0EA5E9),
  Color(0xFFF97316),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFFEAB308),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
  Color(0xFF6366F1),
  Color(0xFF84CC16),
];

/// Bir dersin rengi: tanımlıysa sabit renk, değilse ada göre paletten
/// (aynı ders her zaman aynı rengi alır).
Color dersRengi(String ders) {
  final sabit = dersRenkleri[ders];
  if (sabit != null) return sabit;
  var h = 7;
  for (final c in ders.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _ozelDersPaleti[h % _ozelDersPaleti.length];
}

/// Ders etiketleri — UI'da gösterilecek isimler.
const Map<String, String> dersEtiketleri = {
  'edebiyat': 'Edebiyat',
  'tarih': 'Tarih',
  'biyoloji': 'Biyoloji',
  'cografya': 'Coğrafya',
  'fizik': 'Fizik',
  'kimya': 'Kimya',
  'matematik': 'Matematik',
  'geometri': 'Geometri',
  'turkce': 'Türkçe',
  'felsefe': 'Felsefe',
  'din': 'Din Kültürü',
  'ingilizce': 'İngilizce',
  'yanlislar': 'Yanlışlarım',
  'ozel': 'Kartlarım',
};

/// Tema tipleri
enum AppThemeMode { light, dark, cember }

/// Öğrenme metotları
enum OgrenmeMetod { stratejist, derinlemeci, pratik, savasan, dengeli }

/// Plan blok tipleri
enum PlanBlokTip { calisma, tekrar, soru, mola, egzersiz }

/// Görev öncelikleri
enum GorevOncelik { dusuk, orta, yuksek }

/// Sınav alanları
// ignore: constant_identifier_names
enum SinavAlani { TYT, AYT }

/// Uygulama ayarları anahtarları (SharedPreferences)
class StorageKeys {
  static const String tema = 'yks_tema';
  static const String onboardingTamamlandi = 'yks_onboarding_tamamlandi';
  static const String profil = 'yks_profil';
  static const String konular = 'yks_konular';
  static const String gorevler = 'yks_gorevler';
  static const String netler = 'yks_netler';
  static const String calisma = 'yks_calisma';
  static const String checkins = 'yks_checkins';
  static const String planlar = 'yks_planlar';
  static const String flashkartDurumlar = 'yks_flashkart_durumlar';
  static const String supabaseUrl = 'supabase_url';
  static const String supabaseAnonKey = 'supabase_anon_key';
}

/// Pomodoro süreleri (dakika)
const Map<String, int> pomodoroSureleri = {
  'calisma': 25,
  'kisaMola': 5,
  'uzunMola': 15,
};

/// Bildirim kanalı kimlikleri
class NotificationChannels {
  static const String pomodoro = 'pomodoro_channel';
  static const String checkin = 'checkin_channel';
  static const String streak = 'streak_channel';
  static const String general = 'general_channel';
}

/// Animasyon süreleri
const Duration kShortAnimation = Duration(milliseconds: 200);
const Duration kMediumAnimation = Duration(milliseconds: 300);
const Duration kLongAnimation = Duration(milliseconds: 500);

/// Varsayılan günlük çalışma saati
const int kVarsayilanGunlukSaat = 3;

/// SM-2 başlangıç kolaylık faktörü
const double kSm2BaslangicKolaylikFaktoru = 2.5;

/// Maksimum flashkart tekrar aralığı (gün)
const int kMaksTekrarAraligi = 365;