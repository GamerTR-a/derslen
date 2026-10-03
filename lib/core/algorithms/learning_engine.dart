/// Öğrenme Motoru — Günlük ve Haftalık Plan Oluşturma
/// Web projesindeki `src/lib/ogrenme-engine.ts` dosyasından port edildi.
library;

import 'dart:math';

import '../../core/constants/app_constants.dart';
import '../../data/models/ogrenci_profil.dart';
import '../../data/models/konu.dart';
import '../../data/models/plan_blok.dart';
import '../../data/models/gunluk_checkin.dart';

/// Metod başına blok süresi (dakika)
const Map<OgrenmeMetod, int> metodBlokSure = {
  OgrenmeMetod.stratejist: 25,
  OgrenmeMetod.derinlemeci: 50,
  OgrenmeMetod.pratik: 30,
  OgrenmeMetod.savasan: 20,
  OgrenmeMetod.dengeli: 25,
};

/// Hedef bölüme göre ders öncelikleri
const Map<String, List<String>> hedefDersOnceligi = {
  'sayisal': [
    'Matematik',
    'Fizik',
    'Kimya',
    'Biyoloji',
    'Fen Bilimleri',
    'Türkçe',
    'Sosyal Bilimler',
  ],
  'esit_agirlik': [
    'Matematik',
    'Türkçe',
    'Türk Dili ve Edebiyatı',
    'Tarih',
    'Coğrafya',
    'Fen Bilimleri',
    'Sosyal Bilimler',
  ],
  'sozel': [
    'Türk Dili ve Edebiyatı',
    'Tarih',
    'Coğrafya',
    'Türkçe',
    'Sosyal Bilimler',
    'Matematik',
  ],
  'dil': [
    'Türkçe',
    'Matematik',
    'Fen Bilimleri',
    'Sosyal Bilimler',
  ],
};

/// Metod bilgileri (UI için)
const Map<OgrenmeMetod, Map<String, dynamic>> metodBilgi = {
  OgrenmeMetod.stratejist: {
    'isim': 'Stratejist',
    'ikon': '🧠',
    'renk': 'indigo',
    'aciklama': 'Ebbinghaus unutma eğrisi ile optimize edilmiş tekrar zamanlaması. Uzun vadeli hafıza için ideal.',
    'ozellikler': ['Spaced Repetition', 'Active Recall', 'Optimal tekrar aralığı'],
    'idealKisi': 'Sistematik çalışmayı seven, sabırlı öğrenciler',
    'gunlukYapi': '25dk çalışma + periyodik tekrar blokları',
  },
  OgrenmeMetod.derinlemeci: {
    'isim': 'Derinlemeci',
    'ikon': '🔬',
    'renk': 'blue',
    'aciklama': 'Her konuyu gerçekten anla. Feynman tekniği ile pekiştir, not al.',
    'ozellikler': ['Feynman Tekniği', 'Cornell Notları', 'Derin anlama'],
    'idealKisi': 'Az çalışıp çok anlamak isteyen, kalite odaklı öğrenciler',
    'gunlukYapi': '50dk kesintisiz derin odak seansları',
  },
  OgrenmeMetod.pratik: {
    'isim': 'Pratik',
    'ikon': '✏️',
    'renk': 'amber',
    'aciklama': 'Okuma minimum, soru çözme maksimum. Yanılmaktan öğren.',
    'ozellikler': ['Soru odaklı', 'Hata analizi', 'Hızlı ilerleme'],
    'idealKisi': 'Teoriden sıkılan, somut öğrenmeyi seven öğrenciler',
    'gunlukYapi': '30dk çalışma + yoğun soru çözme',
  },
  OgrenmeMetod.savasan: {
    'isim': 'Savaşan',
    'ikon': '⚡',
    'renk': 'rose',
    'aciklama': 'Konuları karıştırarak çalış, sınav baskısına alış. Transfer öğrenmesi.',
    'ozellikler': ['Interleaving', 'Zamanlı testler', 'Baskı altında performans'],
    'idealKisi': 'Meydan okuma seven, yüksek motivasyonlu öğrenciler',
    'gunlukYapi': '20dk sprint + konu geçişleri',
  },
  OgrenmeMetod.dengeli: {
    'isim': 'Dengeli',
    'ikon': '⚖️',
    'renk': 'emerald',
    'aciklama': 'Koç asistanın netlerine ve plan uyumuna bakarak programın için öneriler hazırlar; önerileri tek dokunuşla uygularsın.',
    'ozellikler': ['Veriye dayalı öneriler', 'Uyarlanabilir program', 'Herkese uygun'],
    'idealKisi': 'Başlangıç için ideal, her öğrenciye uyar',
    'gunlukYapi': '25dk bloklar; program ilerlemene göre güncellenir',
  },
};

/// Günlük plan oluştur
/// [profil] öğrenci profili
/// [konular] tüm konular (tamamlandi/zayif durumlarıyla)
/// [checkin] bugünkü check-in (enerji/odak/stres)
/// PlanBlok listesi döner
List<PlanBlok> gunlukPlanOlustur(
  OgrenciProfil profil,
  List<Konu> konular,
  GunlukCheckin checkin,
) {
  final kalanGun = _kalanGunHesapla();
  final enerjiKatsayi = 0.6 + checkin.enerji * 0.08;
  final stresKatsayi = checkin.stres >= 4 ? 0.75 : 1.0;
  final efektifDk = (profil.gunlukSaat * 60 * enerjiKatsayi * stresKatsayi).round();

  final blokSure = metodBlokSure[profil.ogrenmeMetod] ?? 25;
  final oncelikliDersler = hedefDersOnceligi[profil.hedefBolum] ??
      hedefDersOnceligi['dengeli']!;
  final bloklar = <PlanBlok>[];
  final now = DateTime.now();

  // Yüksek stres varsa başta nefes egzersizi ekle
  if (checkin.stres >= 4) {
    bloklar.add(PlanBlok(
      id: 'egzersiz-nefes-${now.millisecondsSinceEpoch}',
      konu: 'Nefes Egzersizi & Odaklanma',
      ders: 'Psikoloji',
      sure: 5,
      tip: PlanBlokTip.egzersiz,
      tamamlandi: false,
      renk: '#10B981',
      createdAt: now,
      updatedAt: now,
    ));
  }

  // Tamamlanmamış konuları filtrele ve skorla
  final tamamlanmamisKonular = konular.where((k) => !k.tamamlandi).toList();

  final oncelikliKonular = tamamlanmamisKonular.map((k) {
    final dersIndex = oncelikliDersler.indexOf(k.ders);
    final dersOnceligi = dersIndex == -1 ? 1 : oncelikliDersler.length - dersIndex;
    final zayifBonus = k.zayif ? 3 : 1;
    final tytBonus = k.alan == SinavAlani.TYT && kalanGun > 30 ? 1.3 : 1.0;
    return _ScoredKonu(k, skor: (dersOnceligi * zayifBonus * tytBonus));
  }).toList()
    ..sort((a, b) => b.skor.compareTo(a.skor));

  // Savaşan metodu için karıştırılmış sıralama
  final siralananKonular = profil.ogrenmeMetod == OgrenmeMetod.savasan
      ? _shuffleAlternating(oncelikliKonular)
      : oncelikliKonular;

  var kalanDk = efektifDk;
  var blokSayisi = 0;

  for (final scoredKonu in siralananKonular.take(10)) {
    if (kalanDk < blokSure) break;

    final konu = scoredKonu.konu;

    // Blok tipini belirle
    final tip = _blokTipiBelirle(konu, profil.ogrenmeMetod, blokSayisi);

    bloklar.add(PlanBlok(
      id: 'blok-$blokSayisi-${konu.id}-${now.millisecondsSinceEpoch}',
      konu: konu.baslik,
      ders: konu.ders,
      sure: blokSure,
      tip: tip,
      tamamlandi: false,
      // PlanBlok.blokRenk '#RRGGBB' bekler ('#' → '0xFF').
      renk: '#${(konu.renk.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
      createdAt: now,
      updatedAt: now,
    ));

    kalanDk -= blokSure;
    blokSayisi++;

    // Her 2 blokta bir mola (derinlemeci hariç)
    if (blokSayisi % 2 == 0 &&
        profil.ogrenmeMetod != OgrenmeMetod.derinlemeci &&
        kalanDk > 5) {
      final molaSure = blokSayisi % 6 == 0 ? 15 : 5;
      bloklar.add(PlanBlok(
        id: 'mola-$blokSayisi-${now.millisecondsSinceEpoch}',
        konu: blokSayisi % 6 == 0 ? 'Uzun Mola' : 'Kısa Mola',
        ders: '',
        sure: molaSure,
        tip: PlanBlokTip.mola,
        tamamlandi: false,
        createdAt: now,
        updatedAt: now,
      ));
      kalanDk -= molaSure;
    }
  }

  return _saatAtaBloklar(bloklar);
}

/// Haftalık plan oluştur (7 gün önizleme)
List<HaftalikPlanGunu> haftalikPlanOlustur(
  OgrenciProfil profil,
  List<Konu> konular,
) {
  final gunIsimler = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cts', 'Paz'];
  final bugunIndex = DateTime.now().weekday - 1; // 0=Pazartesi

  return List.generate(7, (i) {
    final gun = gunIsimler[i];
    final bugunMu = i == bugunIndex;
    final gecmisMi = i < bugunIndex;

    if (gecmisMi) {
      return HaftalikPlanGunu(
        gun: gun,
        label: gun,
        bloklar: [],
        toplamDk: 0,
        gecmisMi: true,
      );
    }

    final gunCarpani = i >= 5 ? 0.65 : 1.0; // Hafta sonu %65
    final fakeCheckin = GunlukCheckin(
      tarih: '',
      enerji: bugunMu ? 3 : 4,
      odak: 3,
      stres: 2,
      createdAt: DateTime.now(),
    );

    final guncelProfil = profil.copyWith(gunlukSaat: (profil.gunlukSaat * gunCarpani).round());
    final bloklar = gunlukPlanOlustur(guncelProfil, konular, fakeCheckin)
        .where((b) => b.tip != PlanBlokTip.mola && b.tip != PlanBlokTip.egzersiz)
        .toList();

    return HaftalikPlanGunu(
      gun: gun,
      label: gun,
      bloklar: bloklar,
      toplamDk: bloklar.fold(0, (sum, b) => sum + b.sure),
      bugunMu: bugunMu,
    );
  });
}

/// Kalan gün sayısını hesapla (YKS tarihine kadar)
int _kalanGunHesapla() {
  final fark = yksKalanGun();
  return fark > 0 ? fark : 1;
}

/// Blok tipini belirle
PlanBlokTip _blokTipiBelirle(Konu konu, OgrenmeMetod metod, int blokSayisi) {
  if (konu.zayif) return PlanBlokTip.soru;
  if (metod == OgrenmeMetod.stratejist && blokSayisi > 0 && blokSayisi % 3 == 0) {
    return PlanBlokTip.tekrar;
  }
  return PlanBlokTip.calisma;
}

/// Savaşan metodu için konuları dersler arası rastgele karıştır.
/// Hem ders sırası hem de her dersin kendi içindeki sırası her çağrıda
/// rastgele belirlenir; sadece derslerin art arda gelmemesi (interleave)
/// garanti edilir.
List<_ScoredKonu> _shuffleAlternating(List<_ScoredKonu> konular) {
  final random = Random();
  final derslerMap = <String, List<_ScoredKonu>>{};
  for (final k in konular) {
    derslerMap.putIfAbsent(k.konu.ders, () => []).add(k);
  }
  final dersler = derslerMap.keys.toList()..shuffle(random);
  for (final liste in derslerMap.values) {
    liste.shuffle(random);
  }

  final result = <_ScoredKonu>[];
  var i = 0;
  while (result.length < konular.length) {
    final ders = dersler[i % dersler.length];
    final list = derslerMap[ders]!;
    if (list.isNotEmpty) result.add(list.removeAt(0));
    i++;
    if (i > konular.length * 2) break;
  }
  return result;
}

/// Bloklara saat ata (09:00'dan başlayarak)
List<PlanBlok> _saatAtaBloklar(List<PlanBlok> bloklar, {int baslangicSaat = 9}) {
  var dakika = baslangicSaat * 60;
  return bloklar.map((blok) {
    final s = (dakika ~/ 60).toString().padLeft(2, '0');
    final d = (dakika % 60).toString().padLeft(2, '0');
    final saat = '$s:$d';
    dakika += blok.sure;
    return blok.copyWith(saat: saat, updatedAt: DateTime.now());
  }).toList();
}

/// Haftalık plan günü modeli
class HaftalikPlanGunu {
  const HaftalikPlanGunu({
    required this.gun,
    required this.label,
    required this.bloklar,
    required this.toplamDk,
    this.bugunMu = false,
    this.gecmisMi = false,
  });

  final String gun;
  final String label;
  final List<PlanBlok> bloklar;
  final int toplamDk;
  final bool bugunMu;
  final bool gecmisMi;

  String get toplamSureFormatli {
    if (toplamDk < 60) return '$toplamDk dk';
    final saat = toplamDk ~/ 60;
    final dk = toplamDk % 60;
    return dk == 0 ? '$saat saat' : '$saat saat $dk dk';
  }

  double get tamamlamaYuzdesi {
    if (bloklar.isEmpty) return 0;
    final tamamlanan = bloklar.where((b) => b.tamamlandi).length;
    return tamamlanan / bloklar.length;
  }
}

/// Konu skor wrapper
class _ScoredKonu {
  const _ScoredKonu(this.konu, {required this.skor});
  final Konu konu;
  final double skor;
}