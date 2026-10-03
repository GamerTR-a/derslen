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
