// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gunluk_checkin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GunlukCheckin _$GunlukCheckinFromJson(Map<String, dynamic> json) =>
    _GunlukCheckin(
      tarih: json['tarih'] as String,
      enerji: (json['enerji'] as num).toInt(),
      odak: (json['odak'] as num).toInt(),
      stres: (json['stres'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$GunlukCheckinToJson(_GunlukCheckin instance) =>
    <String, dynamic>{
      'tarih': instance.tarih,
      'enerji': instance.enerji,
      'odak': instance.odak,
      'stres': instance.stres,
      'createdAt': instance.createdAt.toIso8601String(),
    };
