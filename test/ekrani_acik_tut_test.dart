import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/services/secure_screen_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kanal = MethodChannel('com.lisenet/secure_screen');
  final gonderilen = <bool>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    gonderilen.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, (call) async {
      if (call.method == 'setKeepScreenOn') gonderilen.add((call.arguments as Map)['on'] as bool);
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(kanal, null);
  });

  test('ekran, isteyen son sayaç bırakana kadar açık kalır', () async {
    await SecureScreenService.ekraniAcikTut(true);
    await SecureScreenService.ekraniAcikTut(true, sahip: 'test');
    await SecureScreenService.ekraniAcikTut(false, sahip: 'test');
    expect(gonderilen, [true, true, true], reason: 'odak seansı sürerken test bitince ekran kapanmamalı');

    await SecureScreenService.ekraniAcikTut(false);
    expect(gonderilen.last, isFalse);
  });

  test('aynı sayacın yinelenen isteği tek bırakmayla geri alınır', () async {
    await SecureScreenService.ekraniAcikTut(true);
    await SecureScreenService.ekraniAcikTut(true);
    await SecureScreenService.ekraniAcikTut(false);
    expect(gonderilen, [true, true, false]);
  });
}
