// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gorev.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Gorev _$GorevFromJson(Map<String, dynamic> json) => _Gorev(
  id: json['id'] as String,
  baslik: json['baslik'] as String,
  aciklama: json['aciklama'] as String?,
  tarih: json['tarih'] as String,
  tamamlandi: json['tamamlandi'] as bool? ?? false,
  oncelik:
      $enumDecodeNullable(_$GorevOncelikEnumMap, json['oncelik']) ??
      GorevOncelik.orta,
  ders: json['ders'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GorevToJson(_Gorev instance) => <String, dynamic>{
  'id': instance.id,
  'baslik': instance.baslik,
  'aciklama': instance.aciklama,
  'tarih': instance.tarih,
  'tamamlandi': instance.tamamlandi,
  'oncelik': _$GorevOncelikEnumMap[instance.oncelik]!,
  'ders': instance.ders,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$GorevOncelikEnumMap = {
  GorevOncelik.dusuk: 'dusuk',
  GorevOncelik.orta: 'orta',
  GorevOncelik.yuksek: 'yuksek',
};
