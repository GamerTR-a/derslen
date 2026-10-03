/// Odak sayacı durumu — sekme değiştirilince sıfırlanmaması için global.
///
/// Süre, bitiş zaman damgasından hesaplanır; uygulama arka plana alınıp
/// geri gelindiğinde sayaç doğru kalır. Yıldızlar, burada sayılan odak
/// dakikasına göre sunucuda verilir; sunucu bu değeri kendi ölçtüğü süreyle
/// sınırlar (bkz. supabase_schema.sql §18 complete_study_session).
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/ambiyans_service.dart';
import '../../core/services/supabase_data_service.dart';
import 'bahce_provider.dart';
import 'ortam_provider.dart';
import 'profil_provider.dart';

enum OdakAsama { hazir, calisiyor, duraklatildi, tamamlandi }

/// 0 = serbest (yukarı sayan) mod.
const List<int> odakSureleri = [25, 50, 90, 0];
const int serbestModTavanDk = 180;

class OdakState {
  final int sureDk;
  final String ders;
  final OdakAsama asama;
  final int gecenSaniye;
  final String? sessionId;
  final int? sonDakika;
  final int? sonYildiz;

  const OdakState({
    this.sureDk = 25,
    this.ders = 'Genel',
    this.asama = OdakAsama.hazir,
    this.gecenSaniye = 0,
    this.sessionId,
    this.sonDakika,
    this.sonYildiz,
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
    );
  }
}

class OdakNotifier extends StateNotifier<OdakState> {
  final Ref _ref;
  Timer? _timer;
  DateTime? _segmentBaslangic;
  int _segmentOncesiSaniye = 0;

  /// Sunucudaki oturum satırının oluştuğunun öğrenildiği an (sunucu
  /// damgası bundan önce ya da aynı andadır).
  DateTime? _oturumYaniti;
  bool _oturumAciliyor = false;

  OdakNotifier(this._ref) : super(const OdakState());

  void sureSec(int dk) {
    if (state.aktif) return;
    state = OdakState(sureDk: dk, ders: state.ders);
  }

  void dersSec(String ders) {
    if (state.aktif) return;
    state = state.copyWith(ders: ders);
  }

  Future<void> baslat() async {
    if (state.asama == OdakAsama.calisiyor) return;
    if (state.asama == OdakAsama.tamamlandi) {
      state = OdakState(sureDk: state.sureDk, ders: state.ders);
    }
    _segmentOncesiSaniye = state.gecenSaniye;
    _segmentBaslangic = DateTime.now();
    state = state.copyWith(asama: OdakAsama.calisiyor);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
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
        } else {
          // Yanıt gelmeden seans bitirildi ya da sıfırlandı: satır açık kalmasın.
          unawaited(SupabaseDataService.completeStudySession(id, focusMinutes: 0).catchError((_) => (0, 0)));
        }
      } finally {
        _oturumAciliyor = false;
      }
    }
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
    final gecen = _segmentOncesiSaniye + DateTime.now().difference(bas).inSeconds;
    state = state.copyWith(gecenSaniye: gecen.clamp(0, state.hedefSaniye));
    if (gecen >= state.hedefSaniye) bitir();
  }

  void duraklat() {
    if (state.asama != OdakAsama.calisiyor) return;
    _tik();
    _timer?.cancel();
    _segmentBaslangic = null;
    // ignore: discarded_futures
    AmbiyansService.durdur();
    state = state.copyWith(asama: OdakAsama.duraklatildi);
  }

  Future<void> bitir() async {
    if (!state.aktif) return;
    _timer?.cancel();
    _segmentBaslangic = null;
    final id = state.sessionId;
    var dakika = state.gecenDakika;
    var yildiz = 0;
    // ignore: discarded_futures
    AmbiyansService.durdur();
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

    if (dakika > 0) {
      await _ref.read(profilProvider.notifier).calismaSuresiEkle(dakika, ders: state.ders);
      await _ref.read(bahceProvider.notifier).calismaIleBuyut(dakika);
    }
    _ref.read(bahceProvider.notifier).yildizEkle(yildiz);
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
    _timer?.cancel();
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
    state = OdakState(sureDk: state.sureDk, ders: state.ders);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

Future<void> ambiyansCal(OrtamState o) =>
    AmbiyansService.cal(o.ses, dosya: o.ozelSesYolu, seviye: o.sesSeviyesi);

final odakProvider = StateNotifierProvider<OdakNotifier, OdakState>((ref) => OdakNotifier(ref));
