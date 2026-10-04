/// Fizik ve kimya soru şablonları (9, 10 ve 11. sınıf Maarif Modeli
/// konuları). Sayılar her üretimde değişir; cevap ve çözüm aynı sayılardan
/// hesaplanır. Yer çekimi ivmesi sorularda g = 10 m/s² (N/kg) alınır.
library;

import '../../data/models/soru.dart';
import '../algorithms/soru_uretici.dart';

const _fiz = 'Fizik';
const _kim = 'Kimya';
const _k = SoruZorluk.kolay;
const _o = SoruZorluk.orta;
const _z = SoruZorluk.zor;

/// İlk 20 elementten seçilenler: [sembol, ad, atom numarası, periyot, grup (A)].
const _elementler = [
  ['Li', 'Lityum', 3, 2, 1],
  ['Be', 'Berilyum', 4, 2, 2],
  ['B', 'Bor', 5, 2, 3],
  ['C', 'Karbon', 6, 2, 4],
  ['N', 'Azot', 7, 2, 5],
  ['O', 'Oksijen', 8, 2, 6],
  ['F', 'Flor', 9, 2, 7],
  ['Ne', 'Neon', 10, 2, 8],
  ['Na', 'Sodyum', 11, 3, 1],
  ['Mg', 'Magnezyum', 12, 3, 2],
  ['Al', 'Alüminyum', 13, 3, 3],
  ['Si', 'Silisyum', 14, 3, 4],
  ['P', 'Fosfor', 15, 3, 5],
  ['S', 'Kükürt', 16, 3, 6],
  ['Cl', 'Klor', 17, 3, 7],
  ['Ar', 'Argon', 18, 3, 8],
  ['K', 'Potasyum', 19, 4, 1],
  ['Ca', 'Kalsiyum', 20, 4, 2],
];

/// [formül, ad, mol kütlesi (g/mol)]
const _bilesikler = [
  ['H₂O', 'su', 18],
  ['CO₂', 'karbondioksit', 44],
  ['NH₃', 'amonyak', 17],
  ['CH₄', 'metan', 16],
  ['NaOH', 'sodyum hidroksit', 40],
  ['CaCO₃', 'kalsiyum karbonat', 100],
  ['O₂', 'oksijen gazı', 32],
  ['H₂SO₄', 'sülfürik asit', 98],
  ['C₆H₁₂O₆', 'glikoz', 180],
  ['MgO', 'magnezyum oksit', 40],
  ['SO₃', 'kükürt trioksit', 80],
  ['N₂', 'azot gazı', 28],
];

const _ustRakamlar = {'0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹', '-': '⁻'};

/// Üst simge metni: -5 → "⁻⁵".
String _ust(int n) => '$n'.split('').map((c) => _ustRakamlar[c] ?? c).join();

final List<SoruSablonu> fenSablonlari = [
  // ═══ FİZİK · 9. sınıf ═══════════════════════════════════════════════
  SoruSablonu('f-birim-1', _fiz, 'Fizik Bilimine Giriş', 'Birim Dönüşümü', _k, ['s9-fiz-03'], (r) {
    final ms = 5 * rs(r, 1, 8);
    final kmh = ms * 18 ~/ 5;
    return r.nextBool()
        ? SoruTaslagi("Sürati $ms m/s olan bir aracın sürati km/h cinsinden kaçtır?", '$kmh', sayiCeldirici(kmh, [ms * 36, ms * 3, ms * 6, ms * 2]),
            "m/s birimi km/h birimine çevrilirken 3,6 ile çarpılır: $ms · 3,6 = $kmh km/h.")
        : SoruTaslagi("Sürati $kmh km/h olan bir aracın sürati m/s cinsinden kaçtır?", '$ms', sayiCeldirici(ms, [kmh * 36 ~/ 10, ms * 2, ms + 5, kmh ~/ 2]),
            "km/h birimi m/s birimine çevrilirken 3,6 değerine bölünür: $kmh : 3,6 = $ms m/s.");
  }),
  SoruSablonu('f-vektor-1', _fiz, 'Kuvvet ve Hareket', 'Vektörler', _k, ['s9-fiz-04'], (r) {
    final u = sec(r, [
      [3, 4, 5],
      [6, 8, 10],
      [5, 12, 13],
      [9, 12, 15],
      [8, 15, 17],
      [12, 16, 20],
    ]);
    return SoruTaslagi(
      "Aynı noktaya uygulanan ve birbirine dik olan ${u[0]} N ve ${u[1]} N büyüklüğündeki iki kuvvetin bileşkesinin büyüklüğü kaç newtondur?",
      '${u[2]}',
      sayiCeldirici(u[2], [u[0] + u[1], u[1] - u[0], u[1], u[2] + 2]),
      "Dik iki vektörün bileşkesi Pisagor bağıntısıyla bulunur: √(${u[0]}² + ${u[1]}²) = √${u[2] * u[2]} = ${u[2]} N.",
    );
  }),
  SoruSablonu('f-vektor-2', _fiz, 'Kuvvet ve Hareket', 'Vektörler', _k, ['s9-fiz-04'], (r) {
    final a = rs(r, 6, 20), b = rs(r, 2, a - 2);
    final zit = r.nextBool();
    final v = zit ? a - b : a + b;
    return SoruTaslagi(
      "Aynı doğrultuda ve ${zit ? 'zıt' : 'aynı'} yönlü $a N ve $b N büyüklüğündeki iki kuvvetin bileşkesinin büyüklüğü kaç newtondur?",
      '$v',
      sayiCeldirici(v, [zit ? a + b : a - b, a, a * b, b]),
      "${zit ? 'Zıt yönlü kuvvetlerde büyüklükler çıkarılır; bileşke büyük kuvvet yönündedir' : 'Aynı yönlü kuvvetlerde büyüklükler toplanır'}: $a ${zit ? '−' : '+'} $b = $v N.",
    );
  }),
  SoruSablonu('f-surat-1', _fiz, 'Kuvvet ve Hareket', 'Ortalama Sürat', _o, ['s9-fiz-06'], (r) {
    final v1 = 10 * rs(r, 3, 9), t1 = rs(r, 1, 3), t2 = rs(r, 1, 3);
    var v2 = 10 * rs(r, 3, 9);
    if ((v1 * t1 + v2 * t2) % (t1 + t2) != 0) v2 = v1 + 10 * (t1 + t2);
    final yol = v1 * t1 + v2 * t2, ort = yol ~/ (t1 + t2);
    return SoruTaslagi(
      "Bir araç yolun ilk bölümünü $v1 km/h süratle $t1 saatte, ikinci bölümünü $v2 km/h süratle $t2 saatte gidiyor. Aracın tüm yol boyunca ortalama sürati kaç km/h olur?",
      '$ort',
      sayiCeldirici(ort, [(v1 + v2) ~/ 2, v1, v2, yol]),
      "Ortalama sürat = toplam yol / toplam zaman = ($v1 · $t1 + $v2 · $t2) / ($t1 + $t2) = $yol / ${t1 + t2} = $ort km/h.",
    );
  }),
  SoruSablonu('f-basinc-1', _fiz, 'Basınç', 'Katı Basıncı', _k, ['s9-fiz-07'], (r) {
    final a = sec(r, [2, 4, 5, 10]), p = 5 * rs(r, 2, 12);
    final g = a * p;
    return SoruTaslagi(
      "Ağırlığı $g N olan bir cisim, yatay zemine $a m² büyüklüğündeki yüzeyi üzerine konuluyor. Cismin zemine uyguladığı basınç kaç pascal (N/m²) olur?",
      '$p',
      sayiCeldirici(p, [g * a, g + a, g, p * 2]),
      "Katı basıncı P = F / A = $g / $a = $p Pa.",
    );
  }),
  SoruSablonu('f-basinc-2', _fiz, 'Basınç', 'Sıvı Basıncı', _o, ['s9-fiz-07'], (r) {
    final h = rs(r, 2, 9), d = sec(r, [800, 1000, 1200, 13600]);
    final p = h * d * 10;
    return SoruTaslagi(
      "Özkütlesi $d kg/m³ olan bir sıvının, yüzeyden $h m derinlikteki bir noktaya uyguladığı sıvı basıncı kaç pascaldır? (g = 10 N/kg)",
      '$p',
      sayiCeldirici(p, [h * d, p ~/ 2, p * 2, d * 10, h * d * 100]),
      "Sıvı basıncı P = h · d · g = $h · $d · 10 = $p Pa. Sıvı basıncı kabın şekline ve sıvı miktarına değil, derinliğe ve özkütleye bağlıdır.",
    );
  }),
  SoruSablonu('f-kaldirma-1', _fiz, 'Kaldırma Kuvveti', 'Arşimet İlkesi', _o, ['s9-fiz-09'], (r) {
    final vCm = 100 * rs(r, 2, 9);
    final dOnKat = sec(r, [8, 10, 12]);
    // Kaldırma kuvvetinin 10 katı (N): V(cm³) · d(g/cm³) gram sıvı → her 100 g için 1 N.
    final fOnKat = vCm * dOnKat ~/ 100;
    final kutle = vCm * dOnKat ~/ 10;
    return SoruTaslagi(
      "Hacmi $vCm cm³ olan bir cisim, özkütlesi ${ondalik(dOnKat)} g/cm³ olan sıvıya tamamen batırılıyor. Cisme etki eden kaldırma kuvveti kaç newtondur? (g = 10 N/kg)",
      ondalik(fOnKat),
      [ondalik(fOnKat * 10), ondalik(fOnKat * 2), ondalik(fOnKat + 10), ondalik(fOnKat + 5), ondalik(vCm ~/ 10), ondalik(fOnKat + 15)],
      "Kaldırma kuvveti, yer değiştiren sıvının ağırlığına eşittir. Yer değiştiren sıvının kütlesi $vCm · ${ondalik(dOnKat)} = $kutle gramdır; ağırlığı (g = 10 N/kg) ${ondalik(fOnKat)} N olur.",
    );
  }),
  SoruSablonu('f-isi-1', _fiz, 'Isı ve Sıcaklık', 'Öz Isı', _o, ['s9-fiz-12'], (r) {
    final m = 100 * rs(r, 1, 6), dt = 5 * rs(r, 2, 8);
    final yarim = r.nextBool();
    final q = yarim ? m * dt ~/ 2 : m * dt;
    return SoruTaslagi(
      "Öz ısısı ${yarim ? '0,5' : '1'} cal/(g·°C) olan ${yarim ? 'bir sıvıdan' : 'sudan'} $m g alınıp sıcaklığı $dt °C artırılıyor. Bunun için kaç kalori ısı gerekir?",
      '$q',
      sayiCeldirici(q, [q * 2, q ~/ 2, m + dt, q + m, q * 4]),
      "Q = m · c · ΔT = $m · ${yarim ? '0,5' : '1'} · $dt = $q cal.",
    );
  }),
  SoruSablonu('f-isi-2', _fiz, 'Isı ve Sıcaklık', 'Isı Sığası', _k, ['s9-fiz-12'], (r) {
    final cSig = 10 * rs(r, 2, 12), dt = 5 * rs(r, 2, 8);
    return SoruTaslagi(
      "Isı sığası $cSig J/°C olan bir cismin sıcaklığını $dt °C artırmak için kaç joule ısı verilmelidir?",
      '${cSig * dt}',
      sayiCeldirici(cSig * dt, [cSig + dt, cSig * dt * 2, cSig * dt ~/ 2, cSig]),
      "Isı sığası C = m · c olduğundan Q = C · ΔT = $cSig · $dt = ${cSig * dt} J.",
    );
  }),
  SoruSablonu('f-denge-1', _fiz, 'Isı ve Sıcaklık', 'Isıl Denge', _o, ['s9-fiz-13'], (r) {
    final m1 = rs(r, 1, 4), m2 = rs(r, 1, 4), t1 = 10 * rs(r, 1, 3);
    final fark = (m1 + m2) * 5 * rs(r, 1, 3);
    final t2 = t1 + fark;
    final td = (m1 * t1 + m2 * t2) ~/ (m1 + m2);
    return SoruTaslagi(
      "Isıca yalıtılmış bir kapta $t1 °C sıcaklıktaki ${m1 * 100} g su ile $t2 °C sıcaklıktaki ${m2 * 100} g su karıştırılıyor. Isıl denge sağlandığında karışımın sıcaklığı kaç °C olur?",
      '$td',
      sayiCeldirici(td, [(t1 + t2) ~/ 2, t1 + t2, t2, t1, td + 10]),
      "Alınan ısı = verilen ısı: ${m1 * 100} · (T − $t1) = ${m2 * 100} · ($t2 − T) ⟹ T = (${m1 * 100} · $t1 + ${m2 * 100} · $t2) / ${(m1 + m2) * 100} = $td °C.",
    );
  }),
  SoruSablonu('f-hal-1', _fiz, 'Isı ve Sıcaklık', 'Hâl Değişimi', _o, ['s9-fiz-13'], (r) {
    final m = 10 * rs(r, 2, 15);
    return SoruTaslagi(
      "0 °C sıcaklıktaki $m g buzun tamamını 0 °C sıcaklıkta su hâline getirmek için kaç kalori ısı gerekir? (Buzun erime ısısı 80 cal/g)",
      '${m * 80}',
      sayiCeldirici(m * 80, [m * 8, m * 100, m + 80, m * 40, m * 540]),
      "Hâl değişimi sırasında sıcaklık değişmez; Q = m · L = $m · 80 = ${m * 80} cal.",
    );
  }),
  // ═══ FİZİK · 10. sınıf ══════════════════════════════════════════════
  SoruSablonu('f-sabithiz-1', _fiz, 'Kuvvet ve Hareket', 'Düzgün Doğrusal Hareket', _k, ['s10-fiz-01'], (r) {
    final v = 5 * rs(r, 2, 8), t = rs(r, 3, 12);
    return SoruTaslagi(
      "Sabit $v m/s hızla hareket eden bir araç $t saniyede kaç metre yol alır?",
      '${v * t}',
      sayiCeldirici(v * t, [v + t, v * t ~/ 2, v * t * 2, v * (t + 1)]),
      "Sabit hızlı harekette x = v · t = $v · $t = ${v * t} m.",
    );
  }),
  SoruSablonu('f-sabithiz-2', _fiz, 'Kuvvet ve Hareket', 'Düzgün Doğrusal Hareket', _o, ['s10-fiz-01'], (r) {
    final v1 = 5 * rs(r, 2, 6), v2 = 5 * rs(r, 2, 6), t = rs(r, 4, 12);
    final d = (v1 + v2) * t;
    return SoruTaslagi(
      "Aralarında $d m uzaklık bulunan iki araç, aynı anda birbirine doğru sabit $v1 m/s ve $v2 m/s hızlarla harekete başlıyor. Araçlar kaç saniye sonra karşılaşır?",
      '$t',
      sayiCeldirici(t, [d ~/ v1, d ~/ v2, t * 2, t + 2]),
      "Birbirine doğru hareket eden araçlarda yaklaşma hızı toplamdır: t = $d / ($v1 + $v2) = $t s.",
    );
  }),
  SoruSablonu('f-ivme-1', _fiz, 'Kuvvet ve Hareket', 'Sabit İvmeli Hareket', _k, ['s10-fiz-02'], (r) {
    final v0 = rs(r, 0, 10), a = rs(r, 2, 5), t = rs(r, 2, 8);
    return SoruTaslagi(
      "${v0 == 0 ? 'Durgun hâlden' : '$v0 m/s hızla giderken'} $a m/s² sabit ivmeyle hızlanmaya başlayan bir aracın $t saniye sonraki hızı kaç m/s olur?",
      '${v0 + a * t}',
      sayiCeldirici(v0 + a * t, [a * t, v0 + a + t, (v0 + a) * t, v0 + a * t * t ~/ 2]),
      "v = v₀ + a · t = $v0 + $a · $t = ${v0 + a * t} m/s.",
    );
  }),
  SoruSablonu('f-ivme-2', _fiz, 'Kuvvet ve Hareket', 'Sabit İvmeli Hareket', _o, ['s10-fiz-02'], (r) {
    final a = 2 * rs(r, 1, 4), t = rs(r, 2, 8);
    final x = a * t * t ~/ 2;
    return SoruTaslagi(
      "Durgun hâlden $a m/s² sabit ivmeyle harekete geçen bir araç ilk $t saniyede kaç metre yol alır?",
      '$x',
      sayiCeldirici(x, [a * t, a * t * t, x ~/ 2, a * t * 2]),
      "x = (1/2) · a · t² = (1/2) · $a · ${t * t} = $x m.",
    );
  }),
  SoruSablonu('f-is-1', _fiz, 'Enerji', 'İş', _k, ['s10-fiz-03'], (r) {
    final f = 5 * rs(r, 2, 12), x = rs(r, 2, 10);
    return SoruTaslagi(
      "Yatay zemindeki bir cisim, harekete paralel $f N büyüklüğündeki kuvvetle $x m çekiliyor. Kuvvetin yaptığı iş kaç jouledür?",
      '${f * x}',
      sayiCeldirici(f * x, [f + x, f * x ~/ 2, f * x * 2, f * (x + 1)]),
      "İş W = F · x = $f · $x = ${f * x} J. (Kuvvet yer değiştirmeye dik olsaydı iş yapılmazdı.)",
    );
  }),
  SoruSablonu('f-guc-1', _fiz, 'Enerji', 'Güç', _k, ['s10-fiz-03'], (r) {
    final p = 10 * rs(r, 2, 15), t = rs(r, 2, 10);
    return SoruTaslagi(
      "Bir motor $t saniyede ${p * t} J iş yapıyor. Motorun gücü kaç watt olur?",
      '$p',
      sayiCeldirici(p, [p * t, p * t * t, p + t, p ~/ 2]),
      "Güç P = W / t = ${p * t} / $t = $p W.",
    );
  }),
  SoruSablonu('f-enerji-1', _fiz, 'Enerji', 'Kinetik Enerji', _k, ['s10-fiz-04'], (r) {
    final m = 2 * rs(r, 1, 6), v = rs(r, 2, 10);
    final e = m * v * v ~/ 2;
    return SoruTaslagi(
      "Kütlesi $m kg olan bir cisim $v m/s hızla hareket ediyor. Cismin kinetik enerjisi kaç jouledür?",
      '$e',
      sayiCeldirici(e, [m * v * v, m * v, m * v ~/ 2, e * 2 + m]),
      "Ek = (1/2) · m · v² = (1/2) · $m · ${v * v} = $e J.",
    );
  }),
  SoruSablonu('f-enerji-2', _fiz, 'Enerji', 'Potansiyel Enerji', _k, ['s10-fiz-04'], (r) {
    final m = rs(r, 1, 8), h = rs(r, 2, 12);
    return SoruTaslagi(
      "Kütlesi $m kg olan bir cisim yerden $h m yüksekliğe çıkarılıyor. Cismin yere göre kütle çekim potansiyel enerjisi kaç joule olur? (g = 10 m/s²)",
      '${m * 10 * h}',
      sayiCeldirici(m * 10 * h, [m * h, m * 10 * h ~/ 2, m * 10 + h, m * h * h]),
      "Ep = m · g · h = $m · 10 · $h = ${m * 10 * h} J.",
    );
  }),
  SoruSablonu('f-enerji-3', _fiz, 'Enerji', 'Mekanik Enerjinin Korunumu', _o, ['s10-fiz-04'], (r) {
    final v = 10 * rs(r, 1, 4);
    final h = v * v ~/ 20;
    return SoruTaslagi(
      "Sürtünmelerin önemsiz olduğu bir ortamda $h m yükseklikten serbest bırakılan bir cisim yere kaç m/s hızla çarpar? (g = 10 m/s²)",
      '$v',
      sayiCeldirici(v, [h, 2 * h, v ~/ 2, v + 10, 10 * h]),
      "Mekanik enerji korunur: m · g · h = (1/2) · m · v² ⟹ v² = 2 · 10 · $h = ${v * v} ⟹ v = $v m/s. Sonuç kütleden bağımsızdır.",
    );
  }),
  SoruSablonu('f-akim-1', _fiz, 'Elektrik', 'Elektrik Akımı', _k, ['s10-fiz-06'], (r) {
    final i = rs(r, 2, 8), t = 5 * rs(r, 2, 12);
    return SoruTaslagi(
      "Bir iletkenin kesitinden $t saniyede ${i * t} C yük geçiyor. İletkenden geçen akım şiddeti kaç amperdir?",
      '$i',
      sayiCeldirici(i, [i * t, i * t * t, t, i + 2]),
      "Akım şiddeti, birim zamanda geçen yük miktarıdır: I = q / t = ${i * t} / $t = $i A.",
    );
  }),
  SoruSablonu('f-ohm-1', _fiz, 'Elektrik', 'Ohm Yasası', _k, ['s10-fiz-07'], (r) {
    final i = rs(r, 2, 6), d = rs(r, 2, 12);
    final v = i * d;
    return [
      SoruTaslagi("Direnci $d Ω olan bir iletkenin uçları arasındaki potansiyel farkı $v V olduğuna göre iletkenden geçen akım kaç amperdir?", '$i',
          sayiCeldirici(i, [v * d, v - d, d, i + 2]), "Ohm yasası: I = V / R = $v / $d = $i A."),
      SoruTaslagi("Direnci $d Ω olan bir iletkenden $i A akım geçtiğine göre iletkenin uçları arasındaki potansiyel farkı kaç volttur?", '$v',
          sayiCeldirici(v, [i + d, v * 2, v + d, v + i]), "Ohm yasası: V = I · R = $i · $d = $v V."),
      SoruTaslagi("Uçları arasındaki potansiyel farkı $v V olan bir iletkenden $i A akım geçtiğine göre iletkenin direnci kaç ohm olur?", '$d',
          sayiCeldirici(d, [v * i, v - i, i, d + 2]), "Ohm yasası: R = V / I = $v / $i = $d Ω."),
    ][r.nextInt(3)];
  }),
  SoruSablonu('f-direnc-1', _fiz, 'Elektrik', 'Dirençlerin Bağlanması', _o, ['s10-fiz-08'], (r) {
    final p = sec(r, [
      [3, 6, 2],
      [4, 12, 3],
      [6, 12, 4],
      [10, 15, 6],
      [20, 30, 12],
      [6, 6, 3],
      [12, 24, 8],
      [5, 20, 4],
    ]);
    return r.nextBool()
        ? SoruTaslagi("Dirençleri ${p[0]} Ω ve ${p[1]} Ω olan iki iletken seri bağlandığında eşdeğer direnç kaç ohm olur?", '${p[0] + p[1]}',
            sayiCeldirici(p[0] + p[1], [p[2], p[0] * p[1], p[1], p[0] + p[1] + 2]), "Seri bağlamada dirençler toplanır: ${p[0]} + ${p[1]} = ${p[0] + p[1]} Ω.")
        : SoruTaslagi("Dirençleri ${p[0]} Ω ve ${p[1]} Ω olan iki iletken paralel bağlandığında eşdeğer direnç kaç ohm olur?", '${p[2]}',
            sayiCeldirici(p[2], [p[0] + p[1], (p[0] + p[1]) ~/ 2, p[0], p[1]]),
            "Paralel bağlamada Reş = (R₁ · R₂) / (R₁ + R₂) = (${p[0]} · ${p[1]}) / ${p[0] + p[1]} = ${p[2]} Ω. Eşdeğer direnç en küçük dirençten de küçüktür.");
  }),
  SoruSablonu('f-direnc-2', _fiz, 'Elektrik', 'Üreteçlerin Bağlanması', _k, ['s10-fiz-08'], (r) {
    final n = rs(r, 2, 6);
    final seri = r.nextBool();
    return SoruTaslagi(
      "Her birinin gerilimi 1,5 V olan özdeş $n pil ${seri ? 'seri' : 'paralel'} bağlanıyor. Pillerin oluşturduğu toplam gerilim kaç volt olur?",
      seri ? ondalik(n * 15) : '1,5',
      [ondalik(n * 15), '1,5', ondalik(n * 30), ondalik(15 * (n + 1)), '0,5', ondalik(15 * n + 5), '0,75'],
      seri
          ? "Seri bağlı özdeş pillerin gerilimleri toplanır: $n · 1,5 = ${ondalik(n * 15)} V."
          : "Paralel bağlı özdeş pillerin toplam gerilimi tek bir pilin gerilimine eşittir: 1,5 V. Paralel bağlama gerilimi artırmaz, pillerin ömrünü uzatır.",
    );
  }),
  SoruSablonu('f-dalga-1', _fiz, 'Dalgalar', 'Dalga Hızı', _k, ['s10-fiz-10'], (r) {
    final lam = rs(r, 2, 8), f = rs(r, 2, 12);
    return r.nextBool()
        ? SoruTaslagi("Dalga boyu $lam m, frekansı $f Hz olan bir dalganın yayılma hızı kaç m/s olur?", '${lam * f}',
            sayiCeldirici(lam * f, [lam + f, lam * f * 2, lam * lam, f * f]), "v = λ · f = $lam · $f = ${lam * f} m/s.")
        : SoruTaslagi("Yayılma hızı ${lam * f} m/s, frekansı $f Hz olan bir dalganın dalga boyu kaç metredir?", '$lam',
            sayiCeldirici(lam, [lam * f * f, lam * f, f, lam + 2]), "λ = v / f = ${lam * f} / $f = $lam m.");
  }),
  SoruSablonu('f-dalga-2', _fiz, 'Dalgalar', 'Periyot ve Frekans', _k, ['s10-fiz-10'], (r) {
    final n = rs(r, 2, 9), t = rs(r, 2, 6);
    return SoruTaslagi(
      "Bir dalga kaynağı $t saniyede ${n * t} tam dalga üretiyor. Kaynağın frekansı kaç hertz olur?",
      '$n',
      sayiCeldirici(n, [n * t, n * t * t, t, n + t]),
      "Frekans, birim zamanda üretilen dalga sayısıdır: f = ${n * t} / $t = $n Hz. Periyot T = 1 / f = 1/$n s.",
    );
  }),
  // ═══ FİZİK · 11. sınıf ══════════════════════════════════════════════
  SoruSablonu('f-serbest-1', _fiz, 'Kuvvet ve Hareket', 'Serbest Düşme', _k, ['s11-fiz-01'], (r) {
    final t = rs(r, 1, 6);
    return r.nextBool()
        ? SoruTaslagi(
            "Hava direncinin önemsiz olduğu ortamda serbest bırakılan bir cisim $t saniyede yere ulaşıyor. Cismin bırakıldığı yükseklik kaç metredir? (g = 10 m/s²)",
            '${5 * t * t}',
            sayiCeldirici(5 * t * t, [10 * t, 10 * t * t, 5 * t, 5 * t * t + 5]),
            "h = (1/2) · g · t² = 5 · ${t * t} = ${5 * t * t} m.")
        : SoruTaslagi("Hava direncinin önemsiz olduğu ortamda serbest bırakılan bir cismin $t saniye sonraki hızı kaç m/s olur? (g = 10 m/s²)", '${10 * t}',
            sayiCeldirici(10 * t, [5 * t * t, 5 * t, 10 * t * t, 10 * t + 5]), "v = g · t = 10 · $t = ${10 * t} m/s.");
  }),
  SoruSablonu('f-yatay-1', _fiz, 'Kuvvet ve Hareket', 'Yatay Atış', _o, ['s11-fiz-01'], (r) {
    final t = rs(r, 1, 4), v = 5 * rs(r, 1, 6);
    return SoruTaslagi(
      "${5 * t * t} m yükseklikten yatay doğrultuda $v m/s hızla atılan bir cisim, atıldığı noktanın düşeyinden kaç metre uzakta yere düşer? (g = 10 m/s², hava direnci önemsiz)",
      '${v * t}',
      sayiCeldirici(v * t, [v * t * t, 5 * t * t, v, v * t * 2]),
      "Düşeyde serbest düşme: ${5 * t * t} = 5 · t² ⟹ t = $t s. Yatayda hız sabittir: x = v · t = $v · $t = ${v * t} m.",
    );
  }),
  SoruSablonu('f-newton-1', _fiz, 'Kuvvet ve Hareket', 'Newton Hareket Yasaları', _k, ['s11-fiz-02'], (r) {
    final m = rs(r, 2, 10), a = rs(r, 2, 6);
    return r.nextBool()
        ? SoruTaslagi("Sürtünmesiz yatay düzlemde durmakta olan $m kg kütleli cisme yatay ${m * a} N büyüklüğünde net kuvvet uygulanıyor. Cismin ivmesi kaç m/s² olur?",
            '$a', sayiCeldirici(a, [m * a * m, m * a - m, m, a + 2]), "Newton hareket yasalarından ikincisi: a = F_net / m = ${m * a} / $m = $a m/s².")
        : SoruTaslagi(
            "Sürtünmesiz yatay düzlemdeki $m kg kütleli bir cismin $a m/s² ivmeyle hızlanması için cisme uygulanması gereken net kuvvet kaç newtondur?",
            '${m * a}',
            sayiCeldirici(m * a, [m + a, m * a * 10, m * 10, m * a + m]),
            "F_net = m · a = $m · $a = ${m * a} N.");
  }),
  SoruSablonu('f-newton-2', _fiz, 'Kuvvet ve Hareket', 'Newton Hareket Yasaları', _o, ['s11-fiz-02'], (r) {
    final m = rs(r, 2, 8), a = rs(r, 1, 5), f2 = 2 * rs(r, 2, 8);
    final f1 = f2 + m * a;
    return SoruTaslagi(
      "Sürtünmesiz yatay düzlemdeki $m kg kütleli cisme, aynı doğrultuda zıt yönlü $f1 N ve $f2 N büyüklüğünde iki yatay kuvvet uygulanıyor. Cismin ivmesinin büyüklüğü kaç m/s² olur?",
      '$a',
      sayiCeldirici(a, [(f1 + f2) ~/ m, f1 ~/ m, f1 - f2, a + 1]),
      "Net kuvvet: $f1 − $f2 = ${f1 - f2} N. a = F_net / m = ${f1 - f2} / $m = $a m/s².",
    );
  }),
  SoruSablonu('f-surtunme-1', _fiz, 'Kuvvet ve Hareket', 'Sürtünme Kuvveti', _o, ['s11-fiz-03'], (r) {
    final m = rs(r, 2, 10), kOn = sec(r, [1, 2, 4, 5]);
    final fs = m * kOn;
    return SoruTaslagi(
      "Yatay düzlemde hareket eden $m kg kütleli bir cisim ile zemin arasındaki kinetik sürtünme katsayısı ${ondalik(kOn)} olarak veriliyor. Cisme etki eden sürtünme kuvvetinin büyüklüğü kaç newtondur? (g = 10 m/s²)",
      '$fs',
      sayiCeldirici(fs, [m * 10, m * kOn * 10, fs + m, fs + 3]),
      "Yatay düzlemde tepki kuvveti N = m · g = ${m * 10} N. fs = k · N = ${ondalik(kOn)} · ${m * 10} = $fs N.",
    );
  }),
  SoruSablonu('f-cember-1', _fiz, 'Kuvvet ve Hareket', 'Düzgün Çembersel Hareket', _o, ['s11-fiz-04'], (r) {
    final yaricap = sec(r, [1, 2, 4]), v = 2 * rs(r, 1, 5), m = rs(r, 1, 5);
    final ivme = v * v ~/ yaricap;
    final kuvvet = r.nextBool();
    return SoruTaslagi(
      "${kuvvet ? '$m kg kütleli bir' : 'Bir'} cisim $yaricap m yarıçaplı çembersel yörüngede $v m/s sabit süratle dönüyor. Cisme etki eden merkezcil ${kuvvet ? 'kuvvet kaç newton' : 'ivme kaç m/s²'} olur?",
      '${kuvvet ? m * ivme : ivme}',
      sayiCeldirici(kuvvet ? m * ivme : ivme, [v * yaricap, v * v, m * v, v * v * yaricap, ivme + 2]),
      "Merkezcil ivme a = v² / r = ${v * v} / $yaricap = $ivme m/s²${kuvvet ? '. Merkezcil kuvvet F = m · a = $m · $ivme = ${m * ivme} N' : ''}. İvmenin yönü her an çemberin merkezine doğrudur.",
    );
  }),
  SoruSablonu('f-coulomb-1', _fiz, 'Elektrik', 'Coulomb Kuvveti', _o, ['s11-fiz-05'], (r) {
    final v = sec(r, [
      ['aralarındaki uzaklık 2 katına çıkarılırsa', 'F/4', 'Kuvvet uzaklığın karesiyle ters orantılıdır: uzaklık 2 katına çıkınca kuvvet dörtte birine iner.'],
      ['aralarındaki uzaklık yarıya indirilirse', '4F', 'Kuvvet uzaklığın karesiyle ters orantılıdır: uzaklık yarıya inince kuvvet 4 katına çıkar.'],
      ['yüklerden birinin miktarı 2 katına çıkarılırsa', '2F', 'Kuvvet yüklerin çarpımıyla doğru orantılıdır: bir yük 2 katına çıkınca kuvvet de 2 katına çıkar.'],
      ['her iki yükün miktarı 2 katına çıkarılırsa', '4F', 'Kuvvet yüklerin çarpımıyla doğru orantılıdır: 2 · 2 = 4 katına çıkar.'],
      ['aralarındaki uzaklık 3 katına çıkarılırsa', 'F/9', 'Kuvvet uzaklığın karesiyle ters orantılıdır: uzaklık 3 katına çıkınca kuvvet dokuzda birine iner.'],
      ['her iki yükün miktarı ve aralarındaki uzaklık 2 katına çıkarılırsa', 'F', 'Yüklerin çarpımı 4 katına, uzaklığın karesi de 4 katına çıkar; kuvvet değişmez.'],
    ]);
    return SoruTaslagi(
      "Noktasal iki yük birbirine F büyüklüğünde elektriksel kuvvet uyguluyor. Yüklerin ${v[0]} kuvvetin büyüklüğü ne olur?",
      v[1],
      ['F/4', '4F', '2F', 'F/2', 'F/9', 'F', '9F', '8F'],
      "Coulomb yasası: F = k · q₁ · q₂ / d². ${v[2]}",
    );
  }),
  SoruSablonu('f-trafo-1', _fiz, 'Manyetizma', 'Transformatörler', _o, ['s11-fiz-07'], (r) {
    final np = 100 * rs(r, 1, 6), oran = sec(r, [2, 3, 4, 5]), vp = 10 * rs(r, 2, 22);
    final yukselt = r.nextBool();
    final ns = yukselt ? np * oran : np;
    final npG = yukselt ? np : np * oran;
    final vpG = yukselt ? vp : vp * oran;
    final vs = yukselt ? vp * oran : vp;
    return SoruTaslagi(
      "İdeal bir transformatörün primer sarım sayısı $npG, sekonder sarım sayısı $ns olarak veriliyor. Primere $vpG V alternatif gerilim uygulandığında sekonderden alınan gerilim kaç volt olur?",
      '$vs',
      sayiCeldirici(vs, [yukselt ? vpG ~/ oran : vpG * oran, vpG, vpG + ns ~/ 100, vs * 2]),
      "Vs / Vp = Ns / Np ⟹ Vs = $vpG · $ns / $npG = $vs V. Sekonder sarım sayısı ${yukselt ? 'fazla olduğundan gerilim yükselir' : 'az olduğundan gerilim düşer'}.",
    );
  }),
  SoruSablonu('f-aydinlanma-1', _fiz, 'Optik', 'Aydınlanma', _o, ['s11-fiz-08'], (r) {
    final d = rs(r, 2, 5), e = rs(r, 2, 12);
    final i = e * d * d;
    return SoruTaslagi(
      "Işık şiddeti $i cd olan noktasal bir ışık kaynağından $d m uzakta, ışınların dik geldiği yüzeydeki aydınlanma şiddeti kaç lüks olur?",
      '$e',
      sayiCeldirici(e, [i ~/ d, i * d, i, e * 2]),
      "E = I / d² = $i / ${d * d} = $e lüks. Aydınlanma, uzaklığın karesiyle ters orantılıdır.",
    );
  }),
  SoruSablonu('f-ayna-1', _fiz, 'Optik', 'Düzlem Ayna', _k, ['s11-fiz-09'], (r) {
    final d = rs(r, 2, 12), x = rs(r, 1, d - 1);
    return SoruTaslagi(
      "Düzlem aynadan $d m uzakta duran bir kişi aynaya doğru $x m yaklaşıyor. Son durumda kişi ile görüntüsü arasındaki uzaklık kaç metre olur?",
      '${2 * (d - x)}',
      sayiCeldirici(2 * (d - x), [d - x, 2 * d, 2 * d - x, 2 * x]),
      "Düzlem aynada görüntü, aynanın arkasında cismin aynaya uzaklığı kadar uzakta oluşur. Kişinin aynaya uzaklığı $d − $x = ${d - x} m; kişi–görüntü arası 2 · ${d - x} = ${2 * (d - x)} m.",
    );
  }),
  SoruSablonu('f-ayna-2', _fiz, 'Optik', 'Küresel Aynalar', _k, ['s11-fiz-09'], (r) {
    final f = 5 * rs(r, 2, 12);
    return SoruTaslagi(
      "Eğrilik yarıçapı ${2 * f} cm olan bir çukur aynanın odak uzaklığı kaç santimetredir?",
      '$f',
      sayiCeldirici(f, [2 * f, 4 * f, f + 5, f + 10]),
      "Küresel aynalarda odak noktası, tepe noktası ile merkezin tam ortasındadır: f = R / 2 = ${2 * f} / 2 = $f cm.",
    );
  }),
  SoruSablonu('f-kirilma-1', _fiz, 'Optik', 'Görünür Derinlik', _o, ['s11-fiz-10'], (r) {
    final dortUc = r.nextBool();
    final pay = dortUc ? 4 : 3, payda = dortUc ? 3 : 2;
    final h = pay * 10 * rs(r, 1, 5);
    final g = h * payda ~/ pay;
    return SoruTaslagi(
      "Kırılma indisi $pay/$payda olan sıvıyla dolu bir kabın tabanındaki cisme, havadan ve yüzeye dik doğrultuda bakılıyor. Sıvının derinliği $h cm olduğuna göre cismin görünür derinliği kaç santimetredir?",
      '$g',
      sayiCeldirici(g, [h * pay ~/ payda, h, h - 10, g ~/ 2]),
      "Havadan sıvı içindeki cisme dik bakıldığında görünür derinlik = gerçek derinlik / n = $h / ($pay/$payda) = $g cm. Cisim olduğundan daha yakında görünür.",
    );
  }),
  SoruSablonu('f-mercek-1', _fiz, 'Optik', 'Mercekler', _z, ['s11-fiz-12'], (r) {
    final v = sec(r, [
      [30, 15, 10],
      [20, 20, 10],
      [60, 30, 20],
      [12, 6, 4],
      [30, 60, 20],
      [15, 30, 10],
      [40, 40, 20],
      [60, 20, 15],
    ]);
    return SoruTaslagi(
      "Odak uzaklığı ${v[2]} cm olan ince kenarlı (yakınsak) bir merceğin ${v[0]} cm önüne bir cisim konuluyor. Cismin gerçek görüntüsü mercekten kaç santimetre uzakta oluşur?",
      '${v[1]}',
      sayiCeldirici(v[1], [v[0] + v[2], v[0] - v[2], v[2], v[0] * 2]),
      "Mercek denklemi: 1/f = 1/dc + 1/dg ⟹ 1/${v[2]} = 1/${v[0]} + 1/dg ⟹ dg = ${v[1]} cm.",
    );
  }),
  // ═══ KİMYA · 9. sınıf ═══════════════════════════════════════════════
  SoruSablonu('k-atom-1', _kim, 'Atomun Yapısı', 'Temel Tanecikler', _k, ['s9-kim-03'], (r) {
    final e = sec(r, _elementler);
    final z = e[2] as int;
    final n = z + rs(r, 0, 2);
    return SoruTaslagi(
      "Atom numarası $z, kütle numarası ${z + n} olan ${e[1]} (${e[0]}) atomunun nötron sayısı kaçtır?",
      '$n',
      sayiCeldirici(n, [z + n, 2 * z + n, n + 2, n + 1, z == n ? z + 3 : z]),
      "Kütle numarası = proton sayısı + nötron sayısı. Nötron sayısı = ${z + n} − $z = $n.",
    );
  }),
  SoruSablonu('k-atom-2', _kim, 'Atomun Yapısı', 'İyonlar', _o, ['s9-kim-03'], (r) {
    final v = sec(r, [
      ['Na', 11, 1],
      ['Mg', 12, 2],
      ['Al', 13, 3],
      ['K', 19, 1],
      ['Ca', 20, 2],
      ['F', 9, -1],
      ['Cl', 17, -1],
      ['O', 8, -2],
      ['S', 16, -2],
      ['N', 7, -3],
    ]);
    final z = v[1] as int, yuk = v[2] as int;
    final ust = yuk > 0 ? '${yuk == 1 ? '' : yuk}+' : '${yuk == -1 ? '' : -yuk}−';
    return SoruTaslagi(
      "Atom numarası $z olan ${v[0]} elementinin oluşturduğu ${v[0]}^$ust iyonundaki elektron sayısı kaçtır?",
      '${z - yuk}',
      sayiCeldirici(z - yuk, [z, z + yuk, yuk.abs(), z - yuk + 2]),
      "Nötr atomda elektron sayısı proton sayısına ($z) eşittir. İyon ${yuk > 0 ? '$yuk elektron vermiş' : '${-yuk} elektron almış'} olduğundan elektron sayısı ${z - yuk} olur.",
    );
  }),
  SoruSablonu('k-dizilim-1', _kim, 'Atomun Yapısı', 'Elektron Dizilimi', _o, ['s9-kim-04', 's9-kim-05'], (r) {
    final e = sec(r, _elementler);
    final z = e[2] as int, periyot = e[3] as int, grup = e[4] as int;
    final periyotSor = r.nextBool();
    return SoruTaslagi(
      "Atom numarası $z olan ${e[1]} (${e[0]}) elementi periyodik tablonun kaçıncı ${periyotSor ? 'periyodunda' : 'A grubunda'} yer alır?",
      '${periyotSor ? periyot : grup}',
      ['1', '2', '3', '4', '5', '6', '7', '8']..shuffle(r),
      "Katman elektron dizilimi yazılır; katman sayısı periyot numarasını, son katmandaki (değerlik) elektron sayısı A grubu numarasını verir. ${e[0]}: $periyot. periyot, ${grup}A grubu.",
    );
  }),
  SoruSablonu('k-dizilim-2', _kim, 'Atomun Yapısı', 'Orbitaller', _o, ['s9-kim-04'], (r) {
    final v = sec(r, [
      [7, '1s² 2s² 2p³', 3],
      [8, '1s² 2s² 2p⁴', 2],
      [9, '1s² 2s² 2p⁵', 1],
      [6, '1s² 2s² 2p²', 2],
      [15, '1s² 2s² 2p⁶ 3s² 3p³', 3],
      [16, '1s² 2s² 2p⁶ 3s² 3p⁴', 2],
      [11, '1s² 2s² 2p⁶ 3s¹', 1],
      [13, '1s² 2s² 2p⁶ 3s² 3p¹', 1],
      [14, '1s² 2s² 2p⁶ 3s² 3p²', 2],
    ]);
    return SoruTaslagi(
      "Atom numarası ${v[0]} olan elementin temel hâl elektron dizilimindeki yarı dolu orbital sayısı kaçtır?",
      '${v[2]}',
      ['0', '1', '2', '3', '4', '5'],
      "Elektron dizilimi: ${v[1]}. Hund kuralına göre eş enerjili orbitallere elektronlar önce birer birer yerleşir; yarı dolu orbital sayısı ${v[2]} olur.",
    );
  }),
  // ═══ KİMYA · 10. sınıf ══════════════════════════════════════════════
  SoruSablonu('k-mol-1', _kim, 'Mol Kavramı', 'Mol – Kütle İlişkisi', _k, ['s10-kim-02'], (r) {
    final b = sec(r, _bilesikler);
    final ma = b[2] as int, nOn = sec(r, [5, 10, 15, 20, 25, 30, 40]);
    final kutleOn = ma * nOn;
    return r.nextBool()
        ? SoruTaslagi(
            "${ondalik(kutleOn)} gram ${b[1]} (${b[0]}) kaç moldür? (${b[0]}: $ma g/mol)",
            ondalik(nOn),
            [ondalik(nOn * 2), ondalik(nOn + 5), ondalik(nOn + 10), ondalik(nOn * 10), ondalik(nOn + 15), ondalik(nOn + 25)],
            "n = m / M = ${ondalik(kutleOn)} / $ma = ${ondalik(nOn)} mol.")
        : SoruTaslagi(
            "${ondalik(nOn)} mol ${b[1]} (${b[0]}) kaç gramdır? (${b[0]}: $ma g/mol)",
            ondalik(kutleOn),
            [ondalik(kutleOn * 2), ondalik(kutleOn + ma * 5), ondalik(kutleOn + ma * 10), ondalik(ma * 10 + nOn), ondalik(kutleOn + ma * 15), ondalik(kutleOn * 10)],
            "m = n · M = ${ondalik(nOn)} · $ma = ${ondalik(kutleOn)} g.");
  }),
  SoruSablonu('k-mol-2', _kim, 'Mol Kavramı', 'Normal Koşullarda Hacim', _o, ['s10-kim-02', 's10-kim-05'], (r) {
    final nOn = sec(r, [5, 10, 15, 20, 25, 30]);
    final gaz = sec(r, ['O₂', 'N₂', 'CO₂', 'H₂', 'CH₄']);
    final hOn = 224 * nOn ~/ 10;
    return SoruTaslagi(
      "Normal koşullarda (0 °C, 1 atm) ${ondalik(nOn)} mol $gaz gazı kaç litre hacim kaplar?",
      ondalik(hOn),
      [ondalik(hOn * 2), ondalik(hOn + 112), ondalik(hOn + 224), ondalik(nOn * 10), ondalik(hOn + 56), ondalik(hOn * 10)],
      "Normal koşullarda 1 mol ideal gaz 22,4 L hacim kaplar: ${ondalik(nOn)} · 22,4 = ${ondalik(hOn)} L. Hacim gazın türüne bağlı değildir.",
    );
  }),
  SoruSablonu('k-stok-1', _kim, 'Kimyasal Tepkimeler', 'Kimyasal Hesaplamalar', _o, ['s10-kim-03'], (r) {
    final v = sec(r, [
      ['N₂ + 3H₂ → 2NH₃', 'N₂', 'NH₃', 1, 2],
      ['N₂ + 3H₂ → 2NH₃', 'H₂', 'NH₃', 3, 2],
      ['2H₂ + O₂ → 2H₂O', 'O₂', 'H₂O', 1, 2],
      ['CH₄ + 2O₂ → CO₂ + 2H₂O', 'CH₄', 'H₂O', 1, 2],
      ['CH₄ + 2O₂ → CO₂ + 2H₂O', 'O₂', 'CO₂', 2, 1],
      ['2SO₂ + O₂ → 2SO₃', 'O₂', 'SO₃', 1, 2],
      ['C₃H₈ + 5O₂ → 3CO₂ + 4H₂O', 'C₃H₈', 'CO₂', 1, 3],
      ['C₃H₈ + 5O₂ → 3CO₂ + 4H₂O', 'C₃H₈', 'H₂O', 1, 4],
      ['4Al + 3O₂ → 2Al₂O₃', 'Al', 'Al₂O₃', 4, 2],
    ]);
    final g = v[3] as int, u = v[4] as int, k = rs(r, 1, 4);
    return SoruTaslagi(
      "${v[0]} tepkimesine göre ${g * k} mol ${v[1]} tamamen tepkimeye girdiğinde kaç mol ${v[2]} oluşur?",
      '${u * k}',
      sayiCeldirici(u * k, [g * k, g * k * u, k, u * k + g]),
      "Denkleştirilmiş tepkimede katsayılar mol oranlarını verir: $g mol ${v[1]} → $u mol ${v[2]}. ${g * k} mol ${v[1]} için ${u * k} mol ${v[2]} oluşur.",
    );
  }),
  SoruSablonu('k-gaz-1', _kim, 'Gazlar', 'Boyle Yasası', _k, ['s10-kim-04'], (r) {
    final p1 = rs(r, 1, 4), k = rs(r, 2, 4), v2 = rs(r, 2, 8);
    final v1 = v2 * k, p2 = p1 * k;
    return SoruTaslagi(
      "Sabit sıcaklıkta $v1 L hacim kaplayan belirli miktardaki bir gazın basıncı $p1 atm olarak ölçülüyor. Gazın hacmi $v2 litreye düşürülürse basıncı kaç atm olur?",
      '$p2',
      sayiCeldirici(p2, [p1, p1 * v2, v1 - v2, p2 + 1, p1 + k]),
      "Boyle yasası: P₁ · V₁ = P₂ · V₂ ⟹ $p1 · $v1 = P₂ · $v2 ⟹ P₂ = $p2 atm. Sabit sıcaklıkta basınç ile hacim ters orantılıdır.",
    );
  }),
  SoruSablonu('k-gaz-2', _kim, 'Gazlar', 'Charles Yasası', _o, ['s10-kim-04'], (r) {
    final v1 = rs(r, 2, 8), k = sec(r, [2, 3]);
    final t1 = sec(r, [200, 250, 300]);
    return SoruTaslagi(
      "Sabit basınçta $t1 K sıcaklıkta $v1 L hacim kaplayan belirli miktardaki bir gaz ${t1 * k} K sıcaklığa kadar ısıtılıyor. Gazın son hacmi kaç litre olur?",
      '${v1 * k}',
      sayiCeldirici(v1 * k, [v1, v1 + k, v1 * k * k, v1 * k + v1]),
      "Charles yasası: V₁ / T₁ = V₂ / T₂ ⟹ $v1 / $t1 = V₂ / ${t1 * k} ⟹ V₂ = ${v1 * k} L. Sabit basınçta hacim mutlak sıcaklıkla doğru orantılıdır.",
    );
  }),
  SoruSablonu('k-derisim-1', _kim, 'Çözeltiler', 'Molarite', _k, ['s10-kim-07'], (r) {
    final n = rs(r, 1, 6), v = sec(r, [1, 2, 4, 5, 10]);
    // M = n / V; ondalıklı sonucu tek basamakla yazabilmek için 10 katı tam olmalı.
    final nn = (10 * n) % v == 0 ? n : v;
    final mOn = 10 * nn ~/ v;
    return SoruTaslagi(
      "$nn mol tuz suda çözülerek $v L çözelti hazırlanıyor. Çözeltinin molar derişimi kaç mol/L olur?",
      ondalik(mOn),
      [ondalik(nn * v * 10), ondalik(mOn * 2), ondalik(mOn + 5), ondalik(mOn + 10), ondalik((nn + v) * 10), ondalik(mOn + 15)],
      "M = n / V = $nn / $v = ${ondalik(mOn)} mol/L.",
    );
  }),
  SoruSablonu('k-derisim-2', _kim, 'Çözeltiler', 'Kütlece Yüzde Derişim', _k, ['s10-kim-07'], (r) {
    final yuzde = sec(r, [5, 10, 20, 25, 40]), toplam = 100 * rs(r, 1, 5);
    final tuz = toplam * yuzde ~/ 100;
    return SoruTaslagi(
      "$tuz g tuzun ${toplam - tuz} g suda tamamen çözünmesiyle hazırlanan çözelti kütlece yüzde kaçlıktır?",
      '$yuzde',
      sayiCeldirici(yuzde, [100 * tuz ~/ (toplam - tuz), 100 - yuzde, yuzde + 5, yuzde * 2, tuz]),
      "Çözelti kütlesi $tuz + ${toplam - tuz} = $toplam g. Kütlece % = ($tuz / $toplam) · 100 = %$yuzde.",
    );
  }),
  SoruSablonu('k-derisim-3', _kim, 'Çözeltiler', 'Seyreltme', _o, ['s10-kim-07'], (r) {
    final m1 = rs(r, 2, 6), v1 = 100 * rs(r, 1, 4), k = rs(r, 2, 4);
    final son = v1 * k;
    return SoruTaslagi(
      "$m1 M $v1 mL tuz çözeltisine saf su eklenerek hacim $son mL olacak şekilde tamamlanıyor. Son çözeltinin derişimi kaç molar olur?",
      kesir(m1, k),
      [kesir(m1 * k, 1), kesir(m1, k + 1), kesir(m1, 1), kesir(m1, 2 * k), kesir(1, k), kesir(m1 + 1, k)],
      "Seyreltmede çözünen madde miktarı değişmez: M₁ · V₁ = M₂ · V₂ ⟹ $m1 · $v1 = M₂ · $son ⟹ M₂ = ${kesir(m1, k)} M.",
    );
  }),
  // ═══ KİMYA · 11. sınıf ══════════════════════════════════════════════
  SoruSablonu('k-entalpi-1', _kim, 'Kimyasal Tepkimelerde Enerji', 'Entalpi', _o, ['s11-kim-01'], (r) {
    final giren = -10 * rs(r, 5, 30), urun = -10 * rs(r, 5, 40);
    final dh = urun - giren;
    return SoruTaslagi(
      "Bir tepkimede girenlerin standart oluşum entalpileri toplamı $giren kJ, ürünlerin standart oluşum entalpileri toplamı $urun kJ olarak veriliyor. Tepkimenin entalpi değişimi (ΔH) kaç kilojouledür?",
      '$dh',
      sayiCeldirici(dh, [-dh, urun + giren, giren, urun, dh + 10], negatif: true),
      "ΔH = ΣH(ürünler) − ΣH(girenler) = ($urun) − ($giren) = $dh kJ. ${dh < 0 ? 'ΔH < 0 olduğundan tepkime ekzotermiktir (ısı verir).' : dh > 0 ? 'ΔH > 0 olduğundan tepkime endotermiktir (ısı alır).' : ''}",
    );
  }),
  SoruSablonu('k-entalpi-2', _kim, 'Kimyasal Tepkimelerde Enerji', 'Bağ Enerjileri', _z, ['s11-kim-01'], (r) {
    final kirilan = 10 * rs(r, 60, 140), olusan = 10 * rs(r, 60, 160);
    final dh = kirilan - olusan;
    return SoruTaslagi(
      "Bir tepkimede kırılan bağların enerjileri toplamı $kirilan kJ, oluşan bağların enerjileri toplamı $olusan kJ olarak veriliyor. Tepkimenin entalpi değişimi (ΔH) kaç kilojouledür?",
      '$dh',
      sayiCeldirici(dh, [-dh, kirilan + olusan, kirilan, -olusan, dh - 10], negatif: true),
      "Bağ kırılması enerji gerektirir, bağ oluşumu enerji açığa çıkarır: ΔH = Σ(kırılan bağlar) − Σ(oluşan bağlar) = $kirilan − $olusan = $dh kJ.",
    );
  }),
  SoruSablonu('k-hiz-1', _kim, 'Kimyasal Tepkimelerde Hız', 'Ortalama Tepkime Hızı', _o, ['s11-kim-02'], (r) {
    final hizBinde = sec(r, [2, 4, 5, 10, 20]), t = sec(r, [10, 20, 50]);
    final sonYuz = rs(r, 10, 40), ilkYuz = sonYuz + hizBinde * t ~/ 10;
    String d(int yuz) => '${yuz ~/ 100},${(yuz % 100).toString().padLeft(2, '0')}';
    String h(int binde) => '0,${binde.toString().padLeft(3, '0')}';
    return SoruTaslagi(
      "Bir tepkimede X maddesinin derişimi $t saniyede ${d(ilkYuz)} mol/L değerinden ${d(sonYuz)} mol/L değerine düşüyor. X maddesinin bu aralıktaki ortalama harcanma hızı kaç mol/(L·s) olur?",
      h(hizBinde),
      [h(hizBinde * 2), h(hizBinde + 1), h(hizBinde + 5), h(hizBinde + 15), h(hizBinde + 3), h(hizBinde * 4)],
      "Ortalama hız = |Δ[X]| / Δt = (${d(ilkYuz)} − ${d(sonYuz)}) / $t = ${d(ilkYuz - sonYuz)} / $t = ${h(hizBinde)} mol/(L·s).",
    );
  }),
  SoruSablonu('k-denge-1', _kim, 'Kimyasal Denge', 'Denge Sabiti', _o, ['s11-kim-03'], (r) {
    final a = rs(r, 1, 4), b = rs(r, 1, 4), kc = rs(r, 2, 6);
    final c = a * b * kc;
    return SoruTaslagi(
      "A(g) + B(g) ⇌ C(g) tepkimesi dengedeyken derişimler [A] = $a M, [B] = $b M ve [C] = $c M olarak ölçülüyor. Tepkimenin bu sıcaklıktaki derişimler cinsinden denge sabiti (Kc) kaçtır?",
      '$kc',
      sayiCeldirici(kc, [c, a * b, c + a + b, kc * 2, kc + 3]),
      "Kc = [C] / ([A] · [B]) = $c / ($a · $b) = $kc. Denge sabiti yalnızca sıcaklıkla değişir.",
    );
  }),
  SoruSablonu('k-ph-1', _kim, 'Asitler ve Bazlar', 'pH Hesaplama', _k, ['s11-kim-04'], (r) {
    final k = rs(r, 1, 6);
    return [
      SoruTaslagi("25 °C sıcaklıkta H⁺ iyonu derişimi 10${_ust(-k)} M olan çözeltinin pH değeri kaçtır?", '$k', sayiCeldirici(k, [14 - k, k + 1, 7, 14]),
          "pH = −log[H⁺] = −log(10${_ust(-k)}) = $k. pH < 7 olduğundan çözelti asidiktir."),
      SoruTaslagi("25 °C sıcaklıkta OH⁻ iyonu derişimi 10${_ust(-k)} M olan çözeltinin pH değeri kaçtır?", '${14 - k}',
          sayiCeldirici(14 - k, [k, 7, 14, 14 - k - 1]), "pOH = −log[OH⁻] = $k. pH + pOH = 14 ⟹ pH = ${14 - k}. pH > 7 olduğundan çözelti baziktir."),
      SoruTaslagi("25 °C sıcaklıkta pH değeri $k olan bir çözeltinin pOH değeri kaçtır?", '${14 - k}', sayiCeldirici(14 - k, [k, 7, 14 + k, 14 - k + 1]),
          "25 °C sıcaklıkta pH + pOH = 14 olduğundan pOH = 14 − $k = ${14 - k}."),
    ][r.nextInt(3)];
  }),
  SoruSablonu('k-notr-1', _kim, 'Asitler ve Bazlar', 'Nötralleşme', _o, ['s11-kim-05'], (r) {
    final mbOn = sec(r, [1, 2, 4, 5]), k = sec(r, [2, 3, 4]), va = 50 * rs(r, 1, 4);
    final maOn = mbOn * k;
    return SoruTaslagi(
      "${ondalik(maOn)} M $va mL HCl çözeltisini tam nötralleştirmek için ${ondalik(mbOn)} M NaOH çözeltisinden kaç mililitre gerekir?",
      '${va * k}',
      sayiCeldirici(va * k, [va, va ~/ k, va * k * 2, va + 50, va * k + 50]),
      "Tam nötralleşmede n(H⁺) = n(OH⁻): Ma · Va = Mb · Vb ⟹ ${ondalik(maOn)} · $va = ${ondalik(mbOn)} · Vb ⟹ Vb = ${va * k} mL.",
    );
  }),
  SoruSablonu('k-kcc-1', _kim, 'Kimyasal Denge', 'Çözünürlük Dengesi', _z, ['s11-kim-06'], (r) {
    final k = rs(r, 3, 7);
    return SoruTaslagi(
      "Suda az çözünen XY tuzunun (X⁺ ve Y⁻ iyonlarına ayrışır) belirli bir sıcaklıktaki molar çözünürlüğü 10${_ust(-k)} mol/L olarak veriliyor. Bu sıcaklıkta XY tuzunun çözünürlük çarpımı (Kçç) kaçtır?",
      '10${_ust(-2 * k)}',
      ['10${_ust(-k)}', '2·10${_ust(-k)}', '10${_ust(-2 * k - 1)}', '10${_ust(-k - 1)}', '4·10${_ust(-3 * k)}', '10${_ust(-2 * k + 1)}'],
      "XY(k) ⇌ X⁺(suda) + Y⁻(suda). Çözünürlük s ise [X⁺] = [Y⁻] = s ve Kçç = s² = (10${_ust(-k)})² = 10${_ust(-2 * k)}.",
    );
  }),
];
