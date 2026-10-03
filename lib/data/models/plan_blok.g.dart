// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_blok.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanBlok _$PlanBlokFromJson(Map<String, dynamic> json) => _PlanBlok(
  id: json['id'] as String,
  konu: json['konu'] as String,
  ders: json['ders'] as String?,
  sure: (json['sure'] as num).toInt(),
  tip:
      $enumDecodeNullable(_$PlanBlokTipEnumMap, json['tip']) ??
      PlanBlokTip.calisma,
  tamamlandi: json['tamamlandi'] as bool? ?? false,
  renk: json['renk'] as String?,
  saat: json['saat'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PlanBlokToJson(_PlanBlok instance) => <String, dynamic>{
  'id': instance.id,
  'konu': instance.konu,
  'ders': instance.ders,
  'sure': instance.sure,
  'tip': _$PlanBlokTipEnumMap[instance.tip]!,
  'tamamlandi': instance.tamamlandi,
  'renk': instance.renk,
  'saat': instance.saat,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$PlanBlokTipEnumMap = {
  PlanBlokTip.calisma: 'calisma',
  PlanBlokTip.tekrar: 'tekrar',
  PlanBlokTip.soru: 'soru',
  PlanBlokTip.mola: 'mola',
  PlanBlokTip.egzersiz: 'egzersiz',
};
