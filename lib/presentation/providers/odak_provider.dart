/// Odak sayacı durumu — sekme değiştirilince sıfırlanmaması için global.
///
/// Süre, bitiş zaman damgasından hesaplanır; uygulama arka plana alınıp
/// geri gelindiğinde sayaç doğru kalır. Süren seans cihaza da yazılır:
/// uygulama kapatılır ya da sistem tarafından sonlandırılırsa bir sonraki
/// açılışta kaldığı yerden devam eder (süresi dolduysa kaydedilir).
/// Yıldızlar, burada sayılan odak dakikasına göre sunucuda verilir; sunucu bu
/// değeri kendi ölçtüğü süreyle sınırlar (bkz. supabase_schema.sql §18
/// complete_study_session).
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ambiyans_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/secure_screen_service.dart';
import '../../core/services/supabase_data_service.dart';
import '../../core/storage/storage_service.dart';
import 'bahce_provider.dart';
import 'ortam_provider.dart';
import 'plan_provider.dart';
import 'profil_provider.dart';

enum OdakAsama { hazir, calisiyor, duraklatildi, tamamlandi }

/// 0 = serbest (yukarı sayan) mod.
const List<int> odakSureleri = [25, 50, 90, 0];
const int serbestModTavanDk = 180;

/// Süren seansın cihazda saklandığı anahtar (buluta eşitlenmez).
const String odakSeansAnahtari = 'odak_aktif_seans';

class OdakState {
  final int sureDk;
  final String ders;
  final OdakAsama asama;
  final int gecenSaniye;
  final String? sessionId;
  final int? sonDakika;
  final int? sonYildiz;

  /// Seans bir program bloğu için başlatıldıysa: bloğun kimliği, günü
  /// (YYYY-MM-DD) ve ekranda gösterilecek konu başlığı.
  final String? blokId;
  final String? blokGun;
  final String? baslik;

  const OdakState({
    this.sureDk = 25,
    this.ders = 'Genel',
    this.asama = OdakAsama.hazir,
    this.gecenSaniye = 0,
    this.sessionId,
    this.sonDakika,
    this.sonYildiz,
    this.blokId,
    this.blokGun,
    this.baslik,
  });

  bool get serbest => sureDk == 0;
  int get hedefSaniye => (serbest ? serbestModTavanDk : sureDk) * 60;
  int get kalanSaniye => (hedefSaniye - gecenSaniye).clamp(0, hedefSaniye);
  int get gosterilenSaniye => serbest ? gecenSaniye : kalanSaniye;
  double get ilerleme => serbest ? (gecenSaniye % 1500) / 1500 : gecenSaniye / hedefSaniye;
  int get gecenDakika => gecenSaniye ~/ 60;
  bool get aktif => asama == OdakAsama.calisiyor || asama == OdakAsama.duraklatildi;

  /// Sunucu formülünün önizlemesi: her 25 dk = 10 yıldız, oturum başı en fazla 40.
  int get tahminiYildiz => ((gecenDakika ~/ 25) * 10).clamp(0, 40);
  int get sonrakiYildizaDk => 25 - (gecenDakika % 25);

  OdakState copyWith({
    int? sureDk,
    String? ders,
    OdakAsama? asama,
    int? gecenSaniye,
    String? sessionId,
    bool sessionTemizle = false,
    int? sonDakika,
    int? sonYildiz,
  }) {
    return OdakState(
      sureDk: sureDk ?? this.sureDk,
      ders: ders ?? this.ders,
      asama: asama ?? this.asama,
      gecenSaniye: gecenSaniye ?? this.gecenSaniye,
      sessionId: sessionTemizle ? null : (sessionId ?? this.sessionId),
      sonDakika: sonDakika ?? this.sonDakika,
      sonYildiz: sonYildiz ?? this.sonYildiz,
      blokId: blokId,
      blokGun: blokGun,
      baslik: baslik,
    );
  }
}

class OdakNotifier extends StateNotifier<OdakState> {
  final Ref _ref;
  final StorageService _yerel;
  Timer? _timer;
  DateTime? _segmentBaslangic;
  int _segmentOncesiSaniye = 0;
  int _tikSayisi = 0;

  /// Sunucudaki oturum satırının oluştuğunun öğrenildiği an (sunucu
  /// damgası bundan önce ya da aynı andadır).
  DateTime? _oturumYaniti;
  bool _oturumAciliyor = false;
  bool _bitiyor = false;

  /// Cihazda kayıtlı seans (varsa) geri yüklenince tamamlanır.
  late final Future<void> hazir;

  OdakNotifier(this._ref, this._yerel) : super(const OdakState()) {
    hazir = _geriYukle();
  }

  void sureSec(int dk) {
    if (state.aktif) return;
    state = OdakState(sureDk: dk, ders: state.ders);
  }

  void dersSec(String ders) {
    if (state.aktif) return;
    state = OdakState(sureDk: state.sureDk, ders: ders);
  }

  /// Bir program bloğu için seans başlatır; seans bittiğinde blok (sürenin
  /// en az %60'ı çalışıldıysa) tamamlandı işaretlenir. Süren bir seans varsa
  /// başlatmaz ve `false` döner.
  Future<bool> blokBaslat({
    required String blokId,
    required String blokGun,
    required int sureDk,
    required String ders,
    required String baslik,
  }) async {
    await hazir;
    if (state.aktif) return false;
    state = OdakState(
      sureDk: sureDk.clamp(1, serbestModTavanDk),
      ders: ders.trim().isEmpty ? 'Genel' : ders,
      blokId: blokId,
      blokGun: blokGun,
      baslik: baslik,
    );
    unawaited(baslat());
    return true;
  }

  Future<void> baslat() async {
    if (state.asama == OdakAsama.calisiyor) return;
    if (state.asama == OdakAsama.tamamlandi) {
      state = OdakState(sureDk: state.sureDk, ders: state.ders);
    }
    _segmentOncesiSaniye = state.gecenSaniye;
    _segmentBaslangic = DateTime.now();
    state = state.copyWith(asama: OdakAsama.calisiyor);
    _sayaciKur();
    unawaited(_kaydet());
    // ignore: discarded_futures
    ambiyansCal(_ref.read(ortamProvider));

    // Duraklat/devam et sırasında ikinci bir oturum satırı açılmasın.
    if (state.sessionId == null && !_oturumAciliyor) {
      _oturumAciliyor = true;
      try {
        final id = await SupabaseDataService.startStudySession(
          label: state.ders,
          plannedMinutes: state.serbest ? serbestModTavanDk : state.sureDk,
        );
        if (id == null || !mounted) return;
        if (state.aktif) {
          _oturumYaniti = DateTime.now();
          state = state.copyWith(sessionId: id);
          unawaited(_kaydet());
        } else {
          // Yanıt gelmeden seans bitirildi ya da sıfırlandı: satır açık kalmasın.
          unawaited(SupabaseDataService.completeStudySession(id, focusMinutes: 0).catchError((_) => (0, 0)));
        }
      } finally {
        _oturumAciliyor = false;
      }
    }
  }

  /// Çalışan seans için saniyelik sayacı, ekranı açık tutmayı ve bitiş
  /// bildirimini kurar.
  void _sayaciKur() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
    // ignore: discarded_futures
    SecureScreenService.ekraniAcikTut(true);
    final bas = _segmentBaslangic;
    if (bas != null && !state.serbest) {
      final bitis = bas.add(Duration(seconds: state.hedefSaniye - _segmentOncesiSaniye));
      // ignore: discarded_futures
      NotificationService.odakBitisiniZamanla(bitis, state.baslik ?? state.ders);
    }
  }

  void _sayaciDurdur() {
    _timer?.cancel();
    _timer = null;
    // ignore: discarded_futures
    SecureScreenService.ekraniAcikTut(false);
    // ignore: discarded_futures
    NotificationService.odakBildiriminiIptalEt();
  }

  /// Sunucu süreyi oturum satırının oluştuğu andan ölçer; bu an sayacın
  /// başlangıcından biraz sonradır. Hiç duraklatılmamış bir seansta sunucunun
  /// 25 dakikayı 24 saymaması için, gerekirse birkaç saniye beklenir.
  Future<void> _sunucuSuresiniBekle(int dakika) async {
    final yanit = _oturumYaniti;
    if (yanit == null || dakika <= 0) return;
    final eksik = Duration(minutes: dakika) - DateTime.now().difference(yanit);
    if (eksik > Duration.zero && eksik < const Duration(seconds: 12)) {
      await Future<void>.delayed(eksik + const Duration(milliseconds: 300));
    }
  }

  void _tik() {
    final bas = _segmentBaslangic;
    if (bas == null || !mounted) return;
    // Ekranı açık tutma ayarı herhangi bir nedenle kaybolursa en geç 15 sn'de geri gelir.
    if (++_tikSayisi % 15 == 0) {
      // ignore: discarded_futures
      SecureScreenService.ekraniAcikTut(true);
    }
    final gecen = _segmentOncesiSaniye + DateTime.now().difference(bas).inSeconds;
    state = state.copyWith(gecenSaniye: gecen.clamp(0, state.hedefSaniye));
    if (gecen >= state.hedefSaniye) bitir();
  }

  /// Uygulama ön plana dönünce çağrılır: arka planda duran sayaç hemen
  /// gerçek süreye getirilir (süre dolduysa seans kaydedilir).
  void onPlanaDonuldu() {
    if (state.asama != OdakAsama.calisiyor) return;
    // ignore: discarded_futures
    SecureScreenService.ekraniAcikTut(true);
    _tik();
  }

  void duraklat() {
    if (state.asama != OdakAsama.calisiyor) return;
    _tik();
    if (state.asama != OdakAsama.calisiyor) return;
    _sayaciDurdur();
    _segmentBaslangic = null;
    // ignore: discarded_futures
    AmbiyansService.durdur();
    state = state.copyWith(asama: OdakAsama.duraklatildi);
    unawaited(_kaydet());
  }

  Future<void> bitir() async {
    if (!state.aktif || _bitiyor) return;
    _bitiyor = true;
    try {
      await _bitir();
    } finally {
      _bitiyor = false;
    }
  }

  Future<void> _bitir() async {
    if (state.asama == OdakAsama.calisiyor) {
      final bas = _segmentBaslangic;
      if (bas != null) {
        final gecen = _segmentOncesiSaniye + DateTime.now().difference(bas).inSeconds;
        state = state.copyWith(gecenSaniye: gecen.clamp(0, state.hedefSaniye));
      }
    }
    _sayaciDurdur();
    _segmentBaslangic = null;
    final id = state.sessionId;
    var dakika = state.gecenDakika;
    var yildiz = 0;
    // ignore: discarded_futures
    AmbiyansService.durdur();
    // Kayıt sürerken uygulama kapanırsa seans, süresi dondurulmuş olarak geri gelir.
    await _kaydet(asama: OdakAsama.duraklatildi);
    state = state.copyWith(asama: OdakAsama.tamamlandi, sessionTemizle: true);

    final odakDakika = dakika;
    if (id != null) {
      await _sunucuSuresiniBekle(odakDakika);
      for (var deneme = 0; deneme < 2; deneme++) {
        try {
          final sonuc = await SupabaseDataService.completeStudySession(id, focusMinutes: odakDakika);
          // Sunucu süreyi yalnızca kısaltabilir; çalışma kaydı odak süresidir.
          dakika = sonuc.$1.clamp(0, odakDakika);
          if (dakika == 0 && odakDakika > 0) dakika = odakDakika;
          yildiz = sonuc.$2;
          break;
        } catch (_) {
          // Sunucuya ulaşılamazsa yerel süre kullanılır, yıldız verilmez.
          if (deneme == 0) await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    _oturumYaniti = null;
    await _yerel.remove(odakSeansAnahtari);
    if (!mounted) return;

    if (dakika > 0) {
      await _ref.read(profilProvider.notifier).calismaSuresiEkle(dakika, ders: state.ders);
      await _ref.read(bahceProvider.notifier).calismaIleBuyut(dakika);
    }
    _ref.read(bahceProvider.notifier).yildizEkle(yildiz);

    final blokId = state.blokId;
    if (blokId != null && !state.serbest && dakika >= (state.sureDk * 0.6).round()) {
      await _ref
          .read(programProvider.notifier)
          .tamamlandiIsaretle(blokId, gun: state.blokGun == null ? null : DateTime.tryParse(state.blokGun!));
    }
    if (mounted) state = state.copyWith(sonDakika: dakika, sonYildiz: yildiz);
  }

  /// Ses ayarı değişince: seans sürüyorsa yeni sesi çalar; seans yokken
  /// [onizleme] istenirse sesi dinletir, istenmezse susturur.
  Future<void> sesDegisti(OrtamState ortam, {bool onizleme = false}) async {
    if (state.asama == OdakAsama.calisiyor || onizleme) {
      await ambiyansCal(ortam);
    } else {
      await AmbiyansService.durdur();
    }
  }

  void sifirla() {
    _sayaciDurdur();
    // ignore: discarded_futures
    AmbiyansService.durdur();
    _segmentBaslangic = null;
    final id = state.sessionId;
    _oturumYaniti = null;
    if (id != null) {
      // Vazgeçilen seans kaydedilmez: 0 dakika bildirilir, yıldız verilmez.
      // (Sunucu eski sürümdeyse yine de yıldız verebilir; bakiye tazelenir.)
      unawaited(SupabaseDataService.completeStudySession(id, focusMinutes: 0)
          .then((_) => _ref.read(bahceProvider.notifier).yildizYenile())
          .catchError((_) {}));
    }
    state = OdakState(sureDk: state.blokId == null ? state.sureDk : 25, ders: state.ders);
    unawaited(_yerel.remove(odakSeansAnahtari));
  }

  // ─── Kalıcılık ──────────────────────────────────────────────────────

  Future<void> _kaydet({OdakAsama? asama}) async {
    if (!state.aktif) return;
    final a = asama ?? state.asama;
    final calisiyor = a == OdakAsama.calisiyor;
    try {
      await _yerel.setMap(odakSeansAnahtari, {
        'sureDk': state.sureDk,
        'ders': state.ders,
        'asama': a.name,
        'oncesi': calisiyor ? _segmentOncesiSaniye : state.gecenSaniye,
        'bas': calisiyor ? _segmentBaslangic?.toIso8601String() : null,
        'sessionId': state.sessionId,
        'yanit': _oturumYaniti?.toIso8601String(),
        'blokId': state.blokId,
        'blokGun': state.blokGun,
        'baslik': state.baslik,
      });
    } catch (_) {}
  }

  Future<void> _geriYukle() async {
    Map<String, dynamic>? m;
    try {
      m = await _yerel.getMap(odakSeansAnahtari);
    } catch (_) {}
    // Yükleme sürerken kullanıcı yeni bir seans başlattıysa eski kayıt yok sayılır.
    if (m == null || !mounted || state.aktif) return;

    final sureDk = ((m['sureDk'] as num?) ?? 25).toInt().clamp(0, serbestModTavanDk);
    final oncesi = ((m['oncesi'] as num?) ?? 0).toInt();
    final bas = DateTime.tryParse(m['bas'] as String? ?? '');
    final calisiyordu = m['asama'] == OdakAsama.calisiyor.name && bas != null;
    final taban = OdakState(
      sureDk: sureDk,
      ders: m['ders'] as String? ?? 'Genel',
      sessionId: m['sessionId'] as String?,
      blokId: m['blokId'] as String?,
      blokGun: m['blokGun'] as String?,
      baslik: m['baslik'] as String?,
    );
    _oturumYaniti = DateTime.tryParse(m['yanit'] as String? ?? '');

    if (!calisiyordu) {
      state = taban.copyWith(asama: OdakAsama.duraklatildi, gecenSaniye: oncesi.clamp(0, taban.hedefSaniye));
      return;
    }
    final gecen = oncesi + DateTime.now().difference(bas).inSeconds;
    if (gecen < 0) {
      // Cihaz saati geri alınmış: güvenli tarafta kalıp duraklatılmış getir.
      state = taban.copyWith(asama: OdakAsama.duraklatildi, gecenSaniye: oncesi.clamp(0, taban.hedefSaniye));
      return;
    }
    _segmentOncesiSaniye = oncesi;
    _segmentBaslangic = bas;
    state = taban.copyWith(asama: OdakAsama.calisiyor, gecenSaniye: gecen.clamp(0, taban.hedefSaniye));
    if (gecen >= taban.hedefSaniye) {
      // Uygulama kapalıyken süre doldu: seans tam süresiyle kaydedilir.
      await bitir();
      return;
    }
    _sayaciKur();
    // ignore: discarded_futures
    ambiyansCal(_ref.read(ortamProvider));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

Future<void> ambiyansCal(OrtamState o) =>
    AmbiyansService.cal(o.ses, dosya: o.ozelSesYolu, seviye: o.sesSeviyesi);

final odakProvider = StateNotifierProvider<OdakNotifier, OdakState>(
  (ref) => OdakNotifier(ref, ref.watch(localStorageServiceProvider)),
);
