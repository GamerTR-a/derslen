// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kart_durum.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KartDurum _$KartDurumFromJson(Map<String, dynamic> json) => _KartDurum(
  id: json['id'] as String,
  tekrarSayisi: (json['tekrarSayisi'] as num?)?.toInt() ?? 0,
  aralik: (json['aralik'] as num?)?.toInt() ?? 1,
  kolaylikFaktoru: (json['kolaylikFaktoru'] as num?)?.toDouble() ?? 2.5,
  sonrakiTekrar: json['sonrakiTekrar'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$KartDurumToJson(_KartDurum instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tekrarSayisi': instance.tekrarSayisi,
      'aralik': instance.aralik,
      'kolaylikFaktoru': instance.kolaylikFaktoru,
      'sonrakiTekrar': instance.sonrakiTekrar,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
