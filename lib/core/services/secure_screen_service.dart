import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Android'de `FLAG_SECURE` bayrağını açıp kapatır (ekran kaydı ve "son
/// uygulamalar" önizlemesinde hassas ekranların (giriş, kayıt, hesap silme)
/// görünmesini engeller). iOS'ta no-op'tur (iOS'ta eşdeğer bir genel API yok).
/// Yalnızca ilgili ekran açıkken etkinleştirilip kapatılmalıdır — tüm
/// uygulamada kalıcı olarak açık bırakmak kullanıcının ilerleme/net
/// grafiklerini ekran görüntüsü ile paylaşmasını (istenen bir özellik)
/// engeller.
class SecureScreenService {
  static const _channel = MethodChannel('com.lisenet/secure_screen');

  static Future<void> setSecure(bool secure) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } catch (_) {
      // Platform desteklemiyorsa veya kanal hazır değilse sessizce yut.
    }
  }

  static bool get _mobil =>
      defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  /// Odak seansı sürerken ekranın kendiliğinden kapanmasını (ve telefonun
  /// kilitlenip uygulamanın arka planda sonlandırılmasını) engeller.
  static Future<void> ekraniAcikTut(bool acik) async {
    if (!_mobil) return;
    try {
      await _channel.invokeMethod('setKeepScreenOn', {'on': acik});
    } catch (_) {}
  }

  /// Android'de uygulamayı kapatmadan arka plana alır (geri tuşu, süren bir
  /// odak seansını yok etmesin diye). Başarılıysa `true` döner.
  static Future<bool> arkaPlanaAl() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('moveTaskToBack') ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Bir [State] içine eklendiğinde, ekran açıkken FLAG_SECURE'u etkinleştirir
/// ve ekran kapanınca otomatik geri alır.
mixin SecureScreenMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SecureScreenService.setSecure(true);
  }

  @override
  void dispose() {
    SecureScreenService.setSecure(false);
    super.dispose();
  }
}
