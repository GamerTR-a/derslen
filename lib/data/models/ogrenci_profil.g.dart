// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ogrenci_profil.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OgrenciProfil _$OgrenciProfilFromJson(Map<String, dynamic> json) =>
    _OgrenciProfil(
      hedefBolum: json['hedefBolum'] as String? ?? 'sayisal',
      hedefUniversite: json['hedefUniversite'] as String?,
      hedefPuan: (json['hedefPuan'] as num?)?.toInt(),
      sinifSeviyesi: json['sinifSeviyesi'] as String?,
      gunlukSaat: (json['gunlukSaat'] as num?)?.toInt() ?? 3,
      ogrenmeMetod:
          $enumDecodeNullable(_$OgrenmeMetodEnumMap, json['ogrenmeMetod']) ??
          OgrenmeMetod.dengeli,
      onboardingTamamlandi: json['onboardingTamamlandi'] as bool? ?? false,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      sonAktifGun: json['sonAktifGun'] as String?,
      toplamCalismaDk: (json['toplamCalismaDk'] as num?)?.toInt() ?? 0,
      gunlukHedefTamamlanma:
          (json['gunlukHedefTamamlanma'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$OgrenciProfilToJson(_OgrenciProfil instance) =>
    <String, dynamic>{
      'hedefBolum': instance.hedefBolum,
      'hedefUniversite': instance.hedefUniversite,
      'hedefPuan': instance.hedefPuan,
      'sinifSeviyesi': instance.sinifSeviyesi,
      'gunlukSaat': instance.gunlukSaat,
      'ogrenmeMetod': _$OgrenmeMetodEnumMap[instance.ogrenmeMetod]!,
      'onboardingTamamlandi': instance.onboardingTamamlandi,
      'streak': instance.streak,
      'sonAktifGun': instance.sonAktifGun,
      'toplamCalismaDk': instance.toplamCalismaDk,
      'gunlukHedefTamamlanma': instance.gunlukHedefTamamlanma,
    };

const _$OgrenmeMetodEnumMap = {
  OgrenmeMetod.stratejist: 'stratejist',
  OgrenmeMetod.derinlemeci: 'derinlemeci',
  OgrenmeMetod.pratik: 'pratik',
  OgrenmeMetod.savasan: 'savasan',
  OgrenmeMetod.dengeli: 'dengeli',
};
