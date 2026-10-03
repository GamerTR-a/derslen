// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flash_kart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlashKart _$FlashKartFromJson(Map<String, dynamic> json) => _FlashKart(
  id: json['id'] as String,
  ders: json['ders'] as String,
  unite: json['unite'] as String,
  on: json['on'] as String,
  arka: json['arka'] as String,
  ipucu: json['ipucu'] as String?,
);

Map<String, dynamic> _$FlashKartToJson(_FlashKart instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ders': instance.ders,
      'unite': instance.unite,
      'on': instance.on,
      'arka': instance.arka,
      'ipucu': instance.ipucu,
    };
