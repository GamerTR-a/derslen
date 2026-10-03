/// Öğrenci Profil Modeli
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'ogrenci_profil.freezed.dart';
part 'ogrenci_profil.g.dart';

@freezed
abstract class OgrenciProfil with _$OgrenciProfil {
  const factory OgrenciProfil({
    @Default('sayisal') String hedefBolum,
    String? hedefUniversite,
    int? hedefPuan,
    String? sinifSeviyesi,
    @Default(3) int gunlukSaat,
    @Default(OgrenmeMetod.dengeli) OgrenmeMetod ogrenmeMetod,
    @Default(false) bool onboardingTamamlandi,
    @Default(0) int streak,
    String? sonAktifGun,
    @Default(0) int toplamCalismaDk,
    @Default(0) int gunlukHedefTamamlanma,
  }) = _OgrenciProfil;

  factory OgrenciProfil.fromJson(Map<String, dynamic> json) =>
      _$OgrenciProfilFromJson(json);

  const OgrenciProfil._();

  /// Hedef bölümü Türkçe etiketi
  String get hedefBolumEtiketi {
    switch (hedefBolum) {
      case 'sayisal':
        return 'Sayısal';
      case 'esit_agirlik':
        return 'Eşit Ağırlık';
      case 'sozel':
        return 'Sözel';
      case 'dil':
        return 'Dil';
      case 'serbest':
        return 'Serbest müfredat';
      default:
        return hedefBolum;
    }
  }

  /// Öğrenme metodu Türkçe etiketi
  String get ogrenmeMetodEtiketi {
    switch (ogrenmeMetod) {
      case OgrenmeMetod.stratejist:
        return 'Stratejist';
      case OgrenmeMetod.derinlemeci:
        return 'Derinlemeci';
      case OgrenmeMetod.pratik:
        return 'Pratik';
      case OgrenmeMetod.savasan:
        return 'Savaşan';
      case OgrenmeMetod.dengeli:
        return 'Dengeli';
    }
  }

  /// Metod ikonu
  String get metodIkon {
    switch (ogrenmeMetod) {
      case OgrenmeMetod.stratejist:
        return '🧠';
      case OgrenmeMetod.derinlemeci:
        return '🔬';
      case OgrenmeMetod.pratik:
        return '✏️';
      case OgrenmeMetod.savasan:
        return '⚡';
      case OgrenmeMetod.dengeli:
        return '⚖️';
    }
  }

  /// Metod rengi
  String get metodRenk {
    switch (ogrenmeMetod) {
      case OgrenmeMetod.stratejist:
        return 'indigo';
      case OgrenmeMetod.derinlemeci:
        return 'blue';
      case OgrenmeMetod.pratik:
        return 'amber';
      case OgrenmeMetod.savasan:
        return 'rose';
      case OgrenmeMetod.dengeli:
        return 'emerald';
    }
  }

  /// Profil boş mu (onboarding yapılmamış mı)
  bool get isEmpty => !onboardingTamamlandi;

  /// Günlük çalışma dakikası
  int get gunlukDakika => gunlukSaat * 60;
}