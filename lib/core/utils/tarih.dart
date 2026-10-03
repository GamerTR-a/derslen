/// Tarih yardımcıları — günlük kayıtlar `YYYY-MM-DD` anahtarlarıyla tutulur.
library;

String gunAnahtari(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

DateTime? anahtardanTarih(String anahtar) => DateTime.tryParse(anahtar);

DateTime sadeceGun(DateTime t) => DateTime(t.year, t.month, t.day);

/// Verilen günün haftasının pazartesisi (saat 00:00).
DateTime haftaBaslangici(DateTime t) => sadeceGun(t).subtract(Duration(days: t.weekday - 1));

/// [bitis] dahil geriye doğru [gunSayisi] günün anahtarları (eskiden yeniye).
List<String> sonGunler(int gunSayisi, [DateTime? bitis]) {
  final b = sadeceGun(bitis ?? DateTime.now());
  return [for (var i = gunSayisi - 1; i >= 0; i--) gunAnahtari(b.subtract(Duration(days: i)))];
}

const List<String> gunKisaAdlari = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];
const List<String> gunAdlari = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
const List<String> ayKisaAdlari = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

/// "2 sa 15 dk" / "45 dk"
String sureMetni(int dakika) {
  if (dakika < 60) return '$dakika dk';
  final s = dakika ~/ 60;
  final d = dakika % 60;
  return d == 0 ? '$s sa' : '$s sa $d dk';
}

/// Dakika cinsinden gün içi saat → "HH:MM"
String saatMetni(int gunIciDakika) {
  final d = gunIciDakika % (24 * 60);
  return '${(d ~/ 60).toString().padLeft(2, '0')}:${(d % 60).toString().padLeft(2, '0')}';
}

/// "05 Eki" gibi kısa tarih.
String kisaTarih(DateTime t) => '${t.day.toString().padLeft(2, '0')} ${ayKisaAdlari[t.month - 1]}';
