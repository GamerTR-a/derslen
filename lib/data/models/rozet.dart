/// Rozet / Başarım Modeli
library;

import 'package:flutter/material.dart';

class Rozet {
  final String id;
  final String baslik;
  final String aciklama;
  final IconData icon;
  final int xpOdulu;

  /// Bu rozetin kazanılıp kazanılmadığını, ilgili sayaç değerine bakarak belirler.
  final bool Function(RozetIlerlemeVerisi veri) kazanildiMi;

  const Rozet({
    required this.id,
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.xpOdulu,
    required this.kazanildiMi,
  });
}

/// Rozet kriterlerini değerlendirmek için gereken ham sayaçlar.
class RozetIlerlemeVerisi {
  final int streak;
  final int denemeSayisi;
  final int tamamlananKonuSayisi;
  final int toplamFlashkartTekrari;

  const RozetIlerlemeVerisi({
    required this.streak,
    required this.denemeSayisi,
    required this.tamamlananKonuSayisi,
    required this.toplamFlashkartTekrari,
  });
}

final List<Rozet> rozetKatalogu = [
  Rozet(
    id: 'ilk_adim',
    baslik: 'İlk Adım',
    aciklama: 'İlk deneme netini kaydettin.',
    icon: Icons.flag_rounded,
    xpOdulu: 10,
    kazanildiMi: (v) => v.denemeSayisi >= 1,
  ),
  Rozet(
    id: 'bes_deneme',
    baslik: 'Düzenli Denemeci',
    aciklama: '5 deneme sonucu kaydettin.',
    icon: Icons.assignment_turned_in_rounded,
    xpOdulu: 25,
    kazanildiMi: (v) => v.denemeSayisi >= 5,
  ),
  Rozet(
    id: 'yedi_gun_seri',
    baslik: '7 Gün Seri',
    aciklama: '7 gün üst üste çalıştın.',
    icon: Icons.local_fire_department_rounded,
    xpOdulu: 30,
    kazanildiMi: (v) => v.streak >= 7,
  ),
  Rozet(
    id: 'otuz_gun_seri',
    baslik: 'Demir İrade',
    aciklama: '30 gün üst üste çalıştın.',
    icon: Icons.whatshot_rounded,
    xpOdulu: 100,
    kazanildiMi: (v) => v.streak >= 30,
  ),
  Rozet(
    id: 'ilk_konu',
    baslik: 'Konu Avcısı',
    aciklama: 'İlk konunu tamamladın.',
    icon: Icons.check_circle_rounded,
    xpOdulu: 10,
    kazanildiMi: (v) => v.tamamlananKonuSayisi >= 1,
  ),
  Rozet(
    id: 'on_konu',
    baslik: 'Konu Ustası',
    aciklama: '10 konuyu tamamladın.',
    icon: Icons.workspace_premium_rounded,
    xpOdulu: 50,
    kazanildiMi: (v) => v.tamamlananKonuSayisi >= 10,
  ),
  Rozet(
    id: 'elli_tekrar',
    baslik: 'Hafıza Şampiyonu',
    aciklama: '50 flashkart tekrarı yaptın.',
    icon: Icons.style_rounded,
    xpOdulu: 40,
    kazanildiMi: (v) => v.toplamFlashkartTekrari >= 50,
  ),
];
