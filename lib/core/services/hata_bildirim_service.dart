/// Yakalanmayan hataları sunucudaki `client_errors` tablosuna kaydeder
/// (bkz. supabase_migrations/19 `hata_bildir`). Üçüncü taraf bir hizmete veri
/// gönderilmez. Yalnızca giriş yapmış kullanıcı için ve oturum başına sınırlı
/// sayıda kayıt gönderilir; sunucu ayrıca günlük sınır uygular.
library;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HataBildirim {
  HataBildirim._();

  static const int _oturumSiniri = 8;
  static final Set<String> _gonderilenler = {};
  static String? _surum;

  static Future<void> bildir(Object hata, StackTrace? yigin) async {
    if (kDebugMode) {
      debugPrint('Hata: $hata\n$yigin');
      return;
    }
    try {
      final mesaj = _ozet(hata);
      if (_gonderilenler.length >= _oturumSiniri || !_gonderilenler.add(mesaj)) return;

      final db = Supabase.instance.client;
      if (db.auth.currentUser == null) return;

      final surum = _surum ??= await _surumOku();
      await db.rpc('hata_bildir', params: {
        'p_mesaj': mesaj,
        'p_yigin': _kisalt(yigin?.toString() ?? '', 6000),
        'p_surum': surum,
        'p_platform': defaultTargetPlatform.name,
      });
    } catch (_) {
      // Raporlama hiçbir koşulda uygulamayı etkilememeli.
    }
  }

  /// Hata metninde kullanıcı girdisi bulunabilir; yalnızca tür ve kısa bir
  /// başlangıç gönderilir.
  static String _ozet(Object hata) => _kisalt('${hata.runtimeType}: $hata', 300);

  static String _kisalt(String s, int uzunluk) => s.length <= uzunluk ? s : s.substring(0, uzunluk);

  static Future<String> _surumOku() async {
    try {
      final bilgi = await PackageInfo.fromPlatform();
      return '${bilgi.version}+${bilgi.buildNumber}';
    } catch (_) {
      return 'bilinmiyor';
    }
  }
}
