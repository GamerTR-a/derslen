import 'dart:async';
import 'package:http/http.dart' as http;

/// Supabase'e giden tüm HTTP isteklerini (Auth/Postgrest/Storage) tek bir
/// noktadan zaman aşımına tabi tutar (kalıp.md Madde 8: "Ağ istekleri 15
/// saniyelik zaman aşımına tabidir"). `Supabase.initialize(httpClient: ...)`
/// ile enjekte edilir; her çağrı noktasını tek tek `.timeout()` ile sarmaya
/// gerek bırakmaz.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(
    this._inner, {
    this.timeout = const Duration(seconds: 15),
    this.fonksiyonTimeout = const Duration(seconds: 60),
  });

  final http.Client _inner;
  final Duration timeout;

  /// Edge Function çağrıları (ör. koç asistanının yapay zeka yanıtı) daha uzun sürebilir.
  final Duration fonksiyonTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    final fonksiyon = request.url.path.contains('/functions/v1/');
    return _inner.send(request).timeout(fonksiyon ? fonksiyonTimeout : timeout);
  }

  @override
  void close() => _inner.close();
}
