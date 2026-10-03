import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tema_verisi.dart';
import 'core/services/hata_bildirim_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/surum_kontrol.dart';
import 'core/services/timeout_http_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/profil_provider.dart';
import 'presentation/providers/settings_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // kalıp.md Item 15 & 26: Yakalanmayan Hata Süzgeci ve Çökmesiz Açılış Koruması
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (!kDebugMode) HataBildirim.bildir(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    HataBildirim.bildir(error, stack);
    return true; // Uygulamanın çökmesini engelle
  };

  // StorageService ilklendir
  final storageService = SharedPrefsStorageService();
  try {
    await storageService.init();
  } catch (_) {
    // SharedPreferences ilklendirme hatasını yut ve bellek moduna geç
  }

  // iOS Keychain uygulama silinince temizlenmez; yeni kurulumda önceki
  // kullanıcının oturumu geri gelmesin diye güvenli depo sıfırlanır.
  await _yeniKurulumdaGuvenliDepoyuTemizle();

  // Supabase Güvenli İlklendirme
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
        // Oturum (JWT access/refresh token) düz SharedPreferences yerine
        // flutter_secure_storage (iOS Keychain / Android Keystore) üzerinde saklanır.
        authOptions: const FlutterAuthClientOptions(
          localStorage: SecureSupabaseLocalStorage(),
        ),
        // Tüm Auth/Postgrest istekleri 15 saniye zaman aşımına tabidir; kötü
        // ağda ekranların süresiz "loading" durumunda takılmasını engeller.
        httpClient: TimeoutHttpClient(http.Client()),
      );
    } catch (_) {
      // Çevrimdışı / Çökme önleyici
    }
  }

  // Uygulamaya gömülü OFL yazı tiplerinin lisansı, Ayarlar › Lisanslar'da listelenir.
  LicenseRegistry.addLicense(() async* {
    final metin = await rootBundle.loadString('assets/fonts/OFL-LISANSLARI.txt');
    yield LicenseEntryWithLineBreaks(const ['Fraunces', 'Plus Jakarta Sans', 'DM Serif Display', 'Manrope'], metin);
  });

  await NotificationService.init();
  await initializeDateFormatting('tr_TR');

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storageService),
      ],
      child: const YksKocuApp(),
    ),
  );
}

Future<void> _yeniKurulumdaGuvenliDepoyuTemizle() async {
  const bayrak = 'kurulum_isaretli_v1';
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(bayrak) == true) return;
    // Bayrak yokken başka anahtar da yoksa bu temiz bir kurulumdur; mevcut
    // kullanıcıların (güncelleme) oturumu korunur.
    if (prefs.getKeys().isEmpty) {
      await SecureStorageService.deleteAll();
    }
    await prefs.setBool(bayrak, true);
  } catch (_) {}
}

class YksKocuApp extends ConsumerStatefulWidget {
  const YksKocuApp({super.key});

  @override
  ConsumerState<YksKocuApp> createState() => _YksKocuAppState();
}

class _YksKocuAppState extends ConsumerState<YksKocuApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.read(authProvider.notifier).bulutlaEsitle();
    ref.invalidate(surumBilgisiProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    final surum = ref.watch(surumBilgisiProvider).valueOrNull ?? SurumBilgisi.uygun;

    return MaterialApp.router(
      title: 'DersNet',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: settings.themeMode,
      builder: (context, child) {
        // Uygulama ayarı, cihazın yazı boyutu tercihinin üzerine uygulanır.
        final sistem = MediaQuery.textScalerOf(context).scale(1.0);
        final olcek = (sistem * settings.textScale).clamp(0.8, 1.6);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(olcek),
          ),
          child: surum.durum == SurumDurumu.uygun ? child! : SurumEngelEkrani(bilgi: surum),
        );
      },
      theme: temaVerisi(AppTheme.light),
      darkTheme: temaVerisi(AppTheme.dark),
    );
  }
}
