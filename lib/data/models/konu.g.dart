// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'konu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Konu _$KonuFromJson(Map<String, dynamic> json) => _Konu(
  id: json['id'] as String,
  ders: json['ders'] as String,
  alan: $enumDecode(_$SinavAlaniEnumMap, json['alan']),
  baslik: json['baslik'] as String,
  tamamlandi: json['tamamlandi'] as bool? ?? false,
  zayif: json['zayif'] as bool? ?? false,
);

Map<String, dynamic> _$KonuToJson(_Konu instance) => <String, dynamic>{
  'id': instance.id,
  'ders': instance.ders,
  'alan': _$SinavAlaniEnumMap[instance.alan]!,
  'baslik': instance.baslik,
  'tamamlandi': instance.tamamlandi,
  'zayif': instance.zayif,
};

const _$SinavAlaniEnumMap = {SinavAlani.TYT: 'TYT', SinavAlani.AYT: 'AYT'};
