/// Cihaz-yerel kişiselleştirme: odak manzarası, özel fotoğraf, ambiyans
/// sesi ve asistan karakteri. Buluta senkronlanmaz (fotoğraf cihazda kalır).
library;

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/ambiyans_service.dart';
import 'profil_provider.dart';

const String _ortamStorageKey = 'ortam_ayarlari';

enum OdakSahne {
  orman('Yağmurlu Orman', '🌲', [Color(0xFF1F4037), Color(0xFF99F2C8)]),
  gunBatimi('Gün Batımı', '🌅', [Color(0xFFF3904F), Color(0xFF3B4371)]),
  gece('Yıldızlı Gece', '🌌', [Color(0xFF0F2027), Color(0xFF2C5364)]),
  deniz('Sakin Deniz', '🌊', [Color(0xFF2193B0), Color(0xFF6DD5ED)]),
  kutuphane('Kütüphane', '📚', [Color(0xFF8E6E53), Color(0xFFD9C3A5)]),
  ozel('Kendi Fotoğrafım', '🖼️', [Color(0xFF334155), Color(0xFF64748B)]);

  const OdakSahne(this.etiket, this.emoji, this.renkler);
  final String etiket;
  final String emoji;
  final List<Color> renkler;
}

/// Adlar canli_maskot.dart'taki çizim kimlikleriyle aynıdır.
enum AsistanKarakter {
  kedi('Pati', '🐱'),
  siyam('Pamuk', '🐈'),
  kopek('Bisküvi', '🐶'),
  yengec('Kıskaç', '🦀'),
  tilki('Tilki', '🦊'),
  panda('Panda', '🐼');

  const AsistanKarakter(this.ad, this.emoji);
  final String ad;
  final String emoji;
}

enum AsistanHareket {
  sabit('Sabit dur'),
  zipla('Hafifçe zıpla'),
  gezin('Ekranda gezin');

  const AsistanHareket(this.etiket);
  final String etiket;
}

/// Kullanıcının yüklediği bir arka plan sesi (dosya uygulama klasörüne kopyalanır).
class OzelSes {
  final String ad;
  final String yol;
  const OzelSes(this.ad, this.yol);

  Map<String, dynamic> toJson() => {'ad': ad, 'yol': yol};
  static OzelSes? fromJson(Object? j) {
    if (j is! Map || j['yol'] is! String) return null;
    return OzelSes((j['ad'] as String?) ?? 'Ses', j['yol'] as String);
  }
}

/// En fazla kaç özel ses saklanır ve her birinin boyut sınırı.
const int maksOzelSes = 6;
const int maksOzelSesBayt = 40 * 1024 * 1024;

class OrtamState {
  final OdakSahne sahne;
  final String? ozelFotoYolu;
  final AmbiyansSes ses;
  final List<OzelSes> ozelSesler;

  /// [ses] == [AmbiyansSes.ozel] iken çalınacak dosya.
  final String? ozelSesYolu;
  final double sesSeviyesi;
  final AsistanKarakter asistan;
  final AsistanHareket hareket;
  final bool asistanGorunur;

  const OrtamState({
    this.sahne = OdakSahne.orman,
    this.ozelFotoYolu,
    this.ses = AmbiyansSes.sessiz,
    this.ozelSesler = const [],
    this.ozelSesYolu,
    this.sesSeviyesi = 0.6,
    this.asistan = AsistanKarakter.kedi,
    this.hareket = AsistanHareket.zipla,
    this.asistanGorunur = true,
  });

  OrtamState copyWith({
    OdakSahne? sahne,
    String? ozelFotoYolu,
    AmbiyansSes? ses,
    List<OzelSes>? ozelSesler,
    String? ozelSesYolu,
    bool ozelSesTemizle = false,
    double? sesSeviyesi,
    AsistanKarakter? asistan,
    AsistanHareket? hareket,
    bool? asistanGorunur,
  }) {
    return OrtamState(
      sahne: sahne ?? this.sahne,
      ozelFotoYolu: ozelFotoYolu ?? this.ozelFotoYolu,
      ses: ses ?? this.ses,
      ozelSesler: ozelSesler ?? this.ozelSesler,
      ozelSesYolu: ozelSesTemizle ? null : (ozelSesYolu ?? this.ozelSesYolu),
      sesSeviyesi: sesSeviyesi ?? this.sesSeviyesi,
      asistan: asistan ?? this.asistan,
      hareket: hareket ?? this.hareket,
      asistanGorunur: asistanGorunur ?? this.asistanGorunur,
    );
  }

  /// Seçili özel sesin adı (yoksa null).
  String? get ozelSesAdi {
    for (final s in ozelSesler) {
      if (s.yol == ozelSesYolu) return s.ad;
    }
    return null;
  }

  String get sesEtiketi => ses == AmbiyansSes.ozel ? (ozelSesAdi ?? ses.etiket) : ses.etiket;

  Map<String, dynamic> toJson() => {
        'sahne': sahne.name,
        'ozelFotoYolu': ozelFotoYolu,
        'ses': ses.name,
        'ozelSesler': [for (final s in ozelSesler) s.toJson()],
        'ozelSesYolu': ozelSesYolu,
        'sesSeviyesi': sesSeviyesi,
        'asistan': asistan.name,
        'hareket': hareket.name,
        'asistanGorunur': asistanGorunur,
      };

  static T _enum<T extends Enum>(List<T> values, Object? name, T varsayilan) =>
      values.firstWhere((v) => v.name == name, orElse: () => varsayilan);

  factory OrtamState.fromJson(Map<String, dynamic> j) => OrtamState(
        sahne: _enum(OdakSahne.values, j['sahne'], OdakSahne.orman),
        ozelFotoYolu: j['ozelFotoYolu'] as String?,
        ses: _enum(AmbiyansSes.values, j['ses'], AmbiyansSes.sessiz),
        ozelSesler: [
          for (final e in (j['ozelSesler'] as List?) ?? const []) ?OzelSes.fromJson(e),
        ],
        ozelSesYolu: j['ozelSesYolu'] as String?,
        sesSeviyesi: ((j['sesSeviyesi'] as num?) ?? 0.6).toDouble().clamp(0.05, 1.0),
        asistan: _enum(AsistanKarakter.values, j['asistan'], AsistanKarakter.kedi),
        hareket: _enum(AsistanHareket.values, j['hareket'], AsistanHareket.zipla),
        asistanGorunur: j['asistanGorunur'] as bool? ?? true,
      );
}

class OrtamNotifier extends StateNotifier<OrtamState> {
  final Ref _ref;

  OrtamNotifier(this._ref) : super(const OrtamState()) {
    _yukle();
  }

  Future<void> _yukle() async {
    final map = await _ref.read(localStorageServiceProvider).getMap(_ortamStorageKey);
    if (map == null || !mounted) return;
    var s = OrtamState.fromJson(map);
    final yol = s.ozelFotoYolu;
    if (s.sahne == OdakSahne.ozel && (yol == null || !File(yol).existsSync())) {
      s = s.copyWith(sahne: OdakSahne.orman);
    }
    // Silinmiş ya da taşınmış ses dosyalarını listeden çıkar.
    final mevcut = s.ozelSesler.where((o) => File(o.yol).existsSync()).toList();
    s = s.copyWith(ozelSesler: mevcut);
    if (!mevcut.any((o) => o.yol == s.ozelSesYolu)) {
      s = s.copyWith(ozelSesTemizle: true, ses: s.ses == AmbiyansSes.ozel ? AmbiyansSes.sessiz : null);
    }
    state = s;
  }

  Future<void> _kaydet() => _ref.read(localStorageServiceProvider).setMap(_ortamStorageKey, state.toJson());

  Future<void> sahneSec(OdakSahne sahne) async {
    state = state.copyWith(sahne: sahne);
    await _kaydet();
  }

  /// Sistem fotoğraf seçicisini açar (Android 13+ Photo Picker; ek izin gerekmez)
  /// ve seçilen görseli uygulamanın kendi klasörüne kopyalar. İptal edilirse false.
  Future<bool> ozelFotoSec() async {
    final secilen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (secilen == null) return false;
    final klasor = await getApplicationDocumentsDirectory();
    final hedef = '${klasor.path}/odak_arka_plan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(secilen.path).copy(hedef);

    final eski = state.ozelFotoYolu;
    if (eski != null && eski != hedef) {
      try {
        await File(eski).delete();
      } catch (_) {}
    }
    state = state.copyWith(sahne: OdakSahne.ozel, ozelFotoYolu: hedef);
    await _kaydet();
    return true;
  }

  Future<void> sesSec(AmbiyansSes ses) async {
    state = state.copyWith(ses: ses);
    await _kaydet();
  }

  Future<void> ozelSesSec(String yol) async {
    state = state.copyWith(ses: AmbiyansSes.ozel, ozelSesYolu: yol);
    await _kaydet();
  }

  Future<void> sesSeviyesiAyarla(double seviye) async {
    state = state.copyWith(sesSeviyesi: seviye.clamp(0.05, 1.0));
    await _kaydet();
  }

  /// Cihazdan bir ses dosyası seçtirir, uygulama klasörüne kopyalar ve seçili
  /// ses yapar. İptal edilirse null, sorun olursa hata mesajı, başarıda boş
  /// metin döner.
  Future<String?> ozelSesEkle() async {
    if (state.ozelSesler.length >= maksOzelSes) {
      return 'En fazla $maksOzelSes ses ekleyebilirsin. Yenisini eklemek için birini sil.';
    }
    final dosya = await FilePicker.pickFile(type: FileType.audio, dialogTitle: 'Arka plan sesi seç');
    if (dosya == null) return null;
    final boyut = await dosya.length();
    if (boyut != null && boyut > maksOzelSesBayt) {
      return 'Dosya çok büyük (en fazla ${maksOzelSesBayt ~/ (1024 * 1024)} MB).';
    }
    final klasor = Directory('${(await getApplicationDocumentsDirectory()).path}/ambiyans');
    await klasor.create(recursive: true);
    final uzanti = (dosya.extension ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final hedef = File('${klasor.path}/ses_${DateTime.now().millisecondsSinceEpoch}.${uzanti.isEmpty ? 'mp3' : uzanti}');
    final yazici = hedef.openWrite();
    try {
      await yazici.addStream(dosya.readAsByteStream());
    } finally {
      await yazici.close();
    }
    final noktaIndex = dosya.name.lastIndexOf('.');
    var ad = noktaIndex > 0 ? dosya.name.substring(0, noktaIndex) : dosya.name;
    if (ad.length > 40) ad = '${ad.substring(0, 40)}…';
    state = state.copyWith(
      ozelSesler: [...state.ozelSesler, OzelSes(ad.isEmpty ? 'Sesim' : ad, hedef.path)],
      ses: AmbiyansSes.ozel,
      ozelSesYolu: hedef.path,
    );
    await _kaydet();
    return '';
  }

  Future<void> ozelSesSil(String yol) async {
    try {
      await File(yol).delete();
    } catch (_) {}
    final secili = state.ozelSesYolu == yol;
    state = state.copyWith(
      ozelSesler: state.ozelSesler.where((o) => o.yol != yol).toList(),
      ozelSesTemizle: secili,
      ses: secili && state.ses == AmbiyansSes.ozel ? AmbiyansSes.sessiz : null,
    );
    await _kaydet();
  }

  Future<void> asistanSec(AsistanKarakter k) async {
    state = state.copyWith(asistan: k);
    await _kaydet();
  }

  Future<void> hareketSec(AsistanHareket h) async {
    state = state.copyWith(hareket: h);
    await _kaydet();
  }

  Future<void> asistanGorunurluk(bool gorunur) async {
    state = state.copyWith(asistanGorunur: gorunur);
    await _kaydet();
  }
}

final ortamProvider = StateNotifierProvider<OrtamNotifier, OrtamState>((ref) => OrtamNotifier(ref));
