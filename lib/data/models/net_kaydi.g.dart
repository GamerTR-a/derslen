// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'net_kaydi.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NetKaydi _$NetKaydiFromJson(Map<String, dynamic> json) => _NetKaydi(
  id: json['id'] as String,
  tarih: json['tarih'] as String,
  alan: $enumDecode(_$SinavAlaniEnumMap, json['alan']),
  ders: json['ders'] as String,
  dogru: (json['dogru'] as num?)?.toInt() ?? 0,
  yanlis: (json['yanlis'] as num?)?.toInt() ?? 0,
  bos: (json['bos'] as num?)?.toInt() ?? 0,
  denemeAdi: json['denemeAdi'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$NetKaydiToJson(_NetKaydi instance) => <String, dynamic>{
  'id': instance.id,
  'tarih': instance.tarih,
  'alan': _$SinavAlaniEnumMap[instance.alan]!,
  'ders': instance.ders,
  'dogru': instance.dogru,
  'yanlis': instance.yanlis,
  'bos': instance.bos,
  'denemeAdi': instance.denemeAdi,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$SinavAlaniEnumMap = {SinavAlani.TYT: 'TYT', SinavAlani.AYT: 'AYT'};
