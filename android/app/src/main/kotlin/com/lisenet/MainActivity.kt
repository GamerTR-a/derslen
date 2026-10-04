package com.lisenet

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// kontrol.md denetim bulgusu: hassas ekranlarda (giriş/kayıt/hesap silme)
/// ekran kaydı ve "son uygulamalar" önizlemesi engellenmiyordu.
/// `secure_screen` MethodChannel'ı, Dart tarafından (bkz.
/// lib/core/services/secure_screen_service.dart) yalnızca ilgili ekranlar
/// açıkken FLAG_SECURE'u açıp kapatmak için kullanılır. Aynı kanal, odak seansı
/// sürerken ekranı açık tutar ve geri tuşunda uygulamayı kapatmak yerine arka
/// plana alır.
class MainActivity : FlutterActivity() {
    private val channelName = "com.lisenet/secure_screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "setKeepScreenOn" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "moveTaskToBack" -> result.success(moveTaskToBack(true))
                else -> result.notImplemented()
            }
        }
    }
}
