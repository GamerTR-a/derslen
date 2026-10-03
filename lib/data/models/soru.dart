import 'package:flutter/material.dart';

enum SoruZorluk {
  kolay('Kolay', Color(0xFF10B981), '🟢'),
  orta('Orta', Color(0xFFF59E0B), '🟡'),
  zor('Zor', Color(0xFFEF4444), '🔴');

  const SoruZorluk(this.etiket, this.renk, this.emoji);
  final String etiket;
  final Color renk;
  final String emoji;
}

class Soru {
  final String id;
  final String ders;
  final String konu;
  final String altBaslik;
  final SoruZorluk zorluk;
  final String soruMetni;
  final Map<String, String> secenekler; // {'A': '...', 'B': '...', 'C': '...', 'D': '...', 'E': '...'}
  final String dogruSecenek; // 'A', 'B', 'C', 'D', 'E'
  final String cozumAciklama;
  final String kaynak;

  const Soru({
    required this.id,
    required this.ders,
    required this.konu,
    required this.altBaslik,
    required this.zorluk,
    required this.soruMetni,
    required this.secenekler,
    required this.dogruSecenek,
    required this.cozumAciklama,
    this.kaynak = 'DersNet özgün soru',
  });

  factory Soru.fromJson(Map<String, dynamic> json) {
    return Soru(
      id: json['id'],
      ders: json['ders'],
      konu: json['konu'],
      altBaslik: json['altBaslik'],
      zorluk: SoruZorluk.values.firstWhere(
        (e) => e.name == json['zorluk'],
        orElse: () => SoruZorluk.orta,
      ),
      soruMetni: json['soruMetni'],
      secenekler: Map<String, String>.from(json['secenekler']),
      dogruSecenek: json['dogruSecenek'],
      cozumAciklama: json['cozumAciklama'],
      kaynak: json['kaynak'] ?? 'DersNet özgün soru',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ders': ders,
      'konu': konu,
      'altBaslik': altBaslik,
      'zorluk': zorluk.name,
      'soruMetni': soruMetni,
      'secenekler': secenekler,
      'dogruSecenek': dogruSecenek,
      'cozumAciklama': cozumAciklama,
      'kaynak': kaynak,
    };
  }
}
