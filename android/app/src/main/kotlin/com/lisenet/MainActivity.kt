package com.lisenet

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// kontrol.md denetim bulgusu: hassas ekranlarda (giriş/kayıt/hesap silme)
/// ekran kaydı ve "son uygulamalar" önizlemesi engellenmiyordu.
/// `secure_screen` MethodChannel'ı, Dart tarafından (bkz.
/// lib/core/services/secure_screen_service.dart) yalnızca ilgili ekranlar
/// açıkken FLAG_SECURE'u açıp kapatmak için kullanılır.
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
                else -> result.notImplemented()
            }
        }
    }
}
