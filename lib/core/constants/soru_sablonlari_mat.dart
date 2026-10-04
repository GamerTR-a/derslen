/// Matematik ve geometri soru şablonları (9, 10 ve 11. sınıf Maarif Modeli
/// konuları). Her şablon rastgele sayılarla yeni bir soru üretir; cevap ve
/// çözüm aynı sayılardan hesaplanır.
library;

import 'dart:math';

import '../../data/models/soru.dart';
import '../algorithms/soru_uretici.dart';

const _mat = 'Matematik';
const _geo = 'Geometri';
const _k = SoruZorluk.kolay;
const _o = SoruZorluk.orta;
const _z = SoruZorluk.zor;

/// (a, b, c) Pisagor üçlüleri.
const _uclular = [
  [3, 4, 5],
  [6, 8, 10],
  [5, 12, 13],
  [9, 12, 15],
  [8, 15, 17],
  [12, 16, 20],
  [7, 24, 25],
  [15, 20, 25],
  [10, 24, 26],
  [20, 21, 29],
];

int _us(int taban, int us) => pow(taban, us).toInt();

int _fakt(int n) => n <= 1 ? 1 : n * _fakt(n - 1);

final List<SoruSablonu> matematikSablonlari = [
  // ─── 9. sınıf · Sayılar ───────────────────────────────────────────────
  SoruSablonu('m-us-1', _mat, 'Üslü ve Köklü Sayılar', 'Üslü İfadelerde İşlemler', _k, ['s9-mat-01'], (r) {
    final t = sec(r, [2, 3, 5]);
    final a = rs(r, 3, 9), b = rs(r, 2, 8), c = rs(r, 2, 6);
    final n = a + b - c;
    return SoruTaslagi(
      '($t^$a · $t^$b) : $t^$c = $t^n olduğuna göre n kaçtır?',
      '$n',
      sayiCeldirici(n, [a + b + c, a * b - c, a - b + c, a + b], negatif: true),
      'Aynı tabanlı üslü ifadeler çarpılırken üsler toplanır, bölünürken çıkarılır: n = $a + $b − $c = $n.',
    );
  }),
  SoruSablonu('m-us-2', _mat, 'Üslü ve Köklü Sayılar', 'Üslü İfadelerde İşlemler', _o, ['s9-mat-01'], (r) {
    final m = rs(r, 2, 5), n = rs(r, 2, 4), k = rs(r, 1, 6);
    final x = m * n + k;
    return SoruTaslagi(
      '(a^$m)^$n · a^$k = a^x olduğuna göre x kaçtır? (a ≠ 0, a ≠ ±1)',
      '$x',
      sayiCeldirici(x, [m + n + k, m * n * k, m * (n + k), _us(m, n) + k]),
      'Üssün üssü alınırken üsler çarpılır: (a^$m)^$n = a^${m * n}. Aynı tabanda çarpma: ${m * n} + $k = $x.',
    );
  }),
  SoruSablonu('m-us-3', _mat, 'Üslü ve Köklü Sayılar', 'Üslü Denklemler', _o, ['s9-mat-01', 's11-mat-06'], (r) {
    final a = rs(r, 1, 5), b = rs(r, 3, 6);
    final x = 2 * b - a;
    return SoruTaslagi(
      '2^(x + $a) = 4^$b olduğuna göre x kaçtır?',
      '$x',
      sayiCeldirici(x, [b - a, 2 * b + a, b, 2 * b], negatif: true),
      '4^$b = (2²)^$b = 2^${2 * b}. Tabanlar eşit olduğundan x + $a = ${2 * b}, x = $x.',
    );
  }),
  SoruSablonu('m-kok-1', _mat, 'Üslü ve Köklü Sayılar', 'Köklü İfadelerde İşlemler', _k, ['s9-mat-01'], (r) {
    final m = sec(r, [2, 3, 5, 7]);
    final k = rs(r, 2, 6);
    var l = rs(r, 2, 6);
    if (l == k) l = k == 6 ? 2 : k + 1;
    return SoruTaslagi(
      '√${k * k * m} + √${l * l * m} işleminin sonucu aşağıdakilerden hangisidir?',
      '${k + l}√$m',
      ['${k * l}√$m', '${k + l}√${2 * m}', '√${k * k * m + l * l * m}', '${k + l + 1}√$m', '${(k - l).abs() + 1}√$m', '${k + l}'],
      '√${k * k * m} = $k√$m ve √${l * l * m} = $l√$m. Kök içleri aynı olduğundan katsayılar toplanır: ${k + l}√$m.',
    );
  }),
  SoruSablonu('m-kok-2', _mat, 'Üslü ve Köklü Sayılar', 'Köklü İfadelerde İşlemler', _o, ['s9-mat-01'], (r) {
    final p = sec(r, [2, 3, 5]);
    final x = rs(r, 1, 4);
    var y = rs(r, 2, 5);
    if (y == x) y = x + 1;
    final s = p * x * y;
    return SoruTaslagi(
      '√${p * x * x} · √${p * y * y} işleminin sonucu kaçtır?',
      '$s',
      sayiCeldirici(s, [x * y, p * p * x * y, p * (x + y), p * x * x * y]),
      '√a · √b = √(a · b). ${p * x * x} · ${p * y * y} = ${p * p * x * x * y * y} = ($s)². Sonuç $s olur.',
    );
  }),
  SoruSablonu('m-aralik-1', _mat, 'Kümeler', 'Gerçek Sayı Aralıkları', _o, ['s9-mat-02'], (r) {
    final a = rs(r, -6, 0), c = a + rs(r, 2, 4), b = c + rs(r, 3, 7), d = b + rs(r, 2, 5);
    final n = b - c - 1;
    return SoruTaslagi(
      'A = [$a, $b) ve B = ($c, $d] aralıkları veriliyor. A ∩ B kümesindeki tam sayıların sayısı kaçtır?',
      '$n',
      sayiCeldirici(n, [b - c, b - c + 1, d - a, d - c]),
      'A ∩ B = ($c, $b) olur; uç noktalar dahil değildir. Bu aralıktaki tam sayılar ${c + 1}, …, ${b - 1} olup sayısı $b − $c − 1 = $n.',
    );
  }),
  SoruSablonu('m-kume-1', _mat, 'Kümeler', 'Kümelerde İşlemler', _k, ['s9-mat-02'], (r) {
    final z = rs(r, 2, 8), x = z + rs(r, 3, 12), y = z + rs(r, 2, 10);
    final s = x + y - z;
    return SoruTaslagi(
      's(A) = $x, s(B) = $y ve s(A ∩ B) = $z olduğuna göre s(A ∪ B) kaçtır?',
      '$s',
      sayiCeldirici(s, [x + y, x + y + z, x - z, y - z]),
      's(A ∪ B) = s(A) + s(B) − s(A ∩ B) = $x + $y − $z = $s.',
    );
  }),
  SoruSablonu('m-ardisik-1', _mat, 'Temel Kavramlar', 'Ardışık Sayılar', _k, ['s9-mat-03'], (r) {
    final orta = 2 * rs(r, 4, 30);
    final cift = r.nextBool();
    final o = cift ? orta : orta + 1;
    return SoruTaslagi(
      'Ardışık üç ${cift ? 'çift' : 'tek'} sayının toplamı ${3 * o} olduğuna göre bu sayıların en büyüğü kaçtır?',
      '${o + 2}',
      sayiCeldirici(o + 2, [o, o + 1, o - 2, o + 4]),
      'Ardışık üç ${cift ? 'çift' : 'tek'} sayının ortancası toplamın üçte biridir: ${3 * o} : 3 = $o. En büyük sayı $o + 2 = ${o + 2}.',
    );
  }),
  SoruSablonu('m-basamak-1', _mat, 'Temel Kavramlar', 'Sayı Basamakları', _o, ['s9-mat-03'], (r) {
    final t = rs(r, 5, 17);
    return SoruTaslagi(
      'İki basamaklı AB sayısı ile BA sayısının toplamı ${11 * t} olduğuna göre A + B kaçtır?',
      '$t',
      sayiCeldirici(t, [t + 11, t - 1, 2 * t, t + 9]),
      'AB + BA = (10A + B) + (10B + A) = 11 · (A + B) = ${11 * t}. Buradan A + B = $t.',
    );
  }),
  SoruSablonu('m-ozdeslik-1', _mat, 'Çarpanlara Ayırma', 'Özdeşlikler', _o, ['s9-mat-04'], (r) {
    final a = rs(r, 2, 9), b = rs(r, 1, 8);
    final s = a + b, p = a * b, c = s * s - 2 * p;
    return SoruTaslagi(
      'a + b = $s ve a · b = $p olduğuna göre a² + b² kaçtır?',
      '$c',
      sayiCeldirici(c, [s * s, s * s - p, s * s + 2 * p, s * s - 4 * p]),
      'a² + b² = (a + b)² − 2ab = $s² − 2 · $p = ${s * s} − ${2 * p} = $c.',
    );
  }),
  SoruSablonu('m-ozdeslik-2', _mat, 'Çarpanlara Ayırma', 'İki Kare Farkı', _k, ['s9-mat-04'], (r) {
    final f = rs(r, 2, 9), t = f + 2 * rs(r, 1, 8);
    return SoruTaslagi(
      'x − y = $f ve x + y = $t olduğuna göre x² − y² kaçtır?',
      '${f * t}',
      sayiCeldirici(f * t, [f + t, t * t - f * f, t - f, f * f]),
      'x² − y² = (x − y)(x + y) = $f · $t = ${f * t}.',
    );
  }),
  // ─── 9. sınıf · Nicelikler ve Değişimler ──────────────────────────────
  SoruSablonu('m-dogrusal-1', _mat, 'Fonksiyonlar', 'Doğrusal Fonksiyonlar', _k, ['s9-mat-05'], (r) {
    final a = rs(r, 2, 7), b = rs(r, -9, 9), k = rs(r, -4, 6);
    final v = a * k + b;
    final bm = b < 0 ? '− ${-b}' : '+ $b';
    return SoruTaslagi(
      'f(x) = ${a}x $bm fonksiyonu için f($k) kaçtır?',
      '$v',
      sayiCeldirici(v, [a * k - b, a + k + b, a * k, a * (k + b)], negatif: true),
      'x yerine $k yazılır: f($k) = $a · ($k) $bm = $v.',
    );
  }),
  SoruSablonu('m-dogrusal-2', _mat, 'Fonksiyonlar', 'Doğrusal Fonksiyonlar', _o, ['s9-mat-05'], (r) {
    final m = rs(r, 2, 6), n = rs(r, -5, 8);
    final x1 = rs(r, 0, 3), x2 = x1 + rs(r, 1, 4), x3 = x2 + rs(r, 1, 5);
    final v = m * x3 + n;
    return SoruTaslagi(
      'Doğrusal bir f fonksiyonu için f($x1) = ${m * x1 + n} ve f($x2) = ${m * x2 + n} olduğuna göre f($x3) kaçtır?',
      '$v',
      sayiCeldirici(v, [m * x3, v + m, v - m, m * x2 + n + x3], negatif: true),
      'Değişim oranı (eğim): (${m * x2 + n} − ${m * x1 + n}) : ($x2 − $x1) = $m. f(x) = ${m}x + n ve f($x1) = ${m * x1 + n} ⟹ n = $n. f($x3) = $m · $x3 ${n < 0 ? '− ${-n}' : '+ $n'} = $v.',
    );
  }),
  SoruSablonu('m-dogrusal-3', _mat, 'Fonksiyonlar', 'Doğrusal Fonksiyonlar', _o, ['s9-mat-05'], (r) {
    final acilis = 5 * rs(r, 4, 12), km = sec(r, [8, 10, 12, 15, 20]), yol = rs(r, 3, 12);
    final v = acilis + km * yol;
    return SoruTaslagi(
      'Bir taksinin açılış ücreti $acilis TL, kilometre başına ücreti $km TL\'dir. Ödenen ücret gidilen yola bağlı doğrusal bir fonksiyon olduğuna göre $yol km\'lik yolculuk için kaç TL ödenir?',
      '$v',
      sayiCeldirici(v, [km * yol, (acilis + km) * yol, v + km, v - acilis + km]),
      'Ücret fonksiyonu f(x) = $acilis + ${km}x olur. f($yol) = $acilis + $km · $yol = $v TL.',
    );
  }),
  SoruSablonu('m-mutlak-1', _mat, 'Mutlak Değer ve Eşitsizlikler', 'Mutlak Değerli Denklemler', _k, ['s9-mat-06'], (r) {
    final b = rs(r, 1, 9);
    var a = rs(r, -6, 9);
    if (a == 0) a = 4;
    final am = a < 0 ? '+ ${-a}' : '− $a';
    return SoruTaslagi(
      '|x $am| = $b denklemini sağlayan x değerlerinin toplamı kaçtır?',
      '${2 * a}',
      sayiCeldirici(2 * a, [a, 2 * b, a + b, a - b, 0], negatif: true),
      'x $am = $b veya x $am = −$b olur: x = ${a + b} veya x = ${a - b}. Toplam ${a + b} + (${a - b}) = ${2 * a}.',
    );
  }),
  SoruSablonu('m-mutlak-2', _mat, 'Mutlak Değer ve Eşitsizlikler', 'Mutlak Değerli Eşitsizlikler', _o, ['s9-mat-06'], (r) {
    final b = rs(r, 2, 8);
    var a = rs(r, -5, 8);
    if (a == 0) a = 3;
    final kesin = r.nextBool();
    final n = kesin ? 2 * b - 1 : 2 * b + 1;
    final am = a < 0 ? '+ ${-a}' : '− $a';
    return SoruTaslagi(
      '|x $am| ${kesin ? '<' : '≤'} $b eşitsizliğini sağlayan kaç farklı tam sayı vardır?',
      '$n',
      sayiCeldirici(n, [2 * b, kesin ? 2 * b + 1 : 2 * b - 1, b, 2 * b + 2]),
      '−$b ${kesin ? '<' : '≤'} x $am ${kesin ? '<' : '≤'} $b ⟹ ${a - b} ${kesin ? '<' : '≤'} x ${kesin ? '<' : '≤'} ${a + b}. Bu aralıkta $n tam sayı vardır.',
    );
  }),
  SoruSablonu('m-mutlak-3', _mat, 'Mutlak Değer ve Eşitsizlikler', 'Mutlak Değer Fonksiyonu', _o, ['s9-mat-06'], (r) {
    final a = rs(r, 1, 7), b = rs(r, 1, 9), k = rs(r, -8, -1);
    final v = (k - a).abs() + b;
    return SoruTaslagi(
      'f(x) = |x − $a| + $b fonksiyonu için f($k) kaçtır?',
      '$v',
      sayiCeldirici(v, [k - a + b, (k + a).abs() + b, (k - a).abs() - b, (k - a).abs()], negatif: true),
      'f($k) = |$k − $a| + $b = |${k - a}| + $b = ${(k - a).abs()} + $b = $v.',
    );
  }),
  SoruSablonu('m-denklem-1', _mat, 'Denklemler', 'Birinci Dereceden Denklemler', _k, ['s9-mat-07'], (r) {
    final x = rs(r, -5, 9), c = rs(r, 1, 4), a = c + rs(r, 1, 4), b = rs(r, 1, 6);
    final d = a * (x - b) - c * x;
    final dm = d < 0 ? '− ${-d}' : '+ $d';
    return SoruTaslagi(
      '$a(x − $b) = ${c}x $dm denklemini sağlayan x değeri kaçtır?',
      '$x',
      sayiCeldirici(x, [-x, x + b, x - b, d], negatif: true),
      '${a}x − ${a * b} = ${c}x $dm ⟹ ${a - c}x = ${d + a * b} ⟹ x = $x.',
    );
  }),
  SoruSablonu('m-esitsizlik-1', _mat, 'Mutlak Değer ve Eşitsizlikler', 'Basit Eşitsizlikler', _o, ['s9-mat-07'], (r) {
    final lo = rs(r, -4, 3), hi = lo + rs(r, 3, 8), k = rs(r, 2, 4), b = rs(r, 1, 7);
    final n = hi - lo;
    return SoruTaslagi(
      '${k * lo + b} < ${k}x + $b ≤ ${k * hi + b} eşitsizliğini sağlayan kaç farklı x tam sayısı vardır?',
      '$n',
      sayiCeldirici(n, [n + 1, n - 1, k * n, hi]),
      'Her taraftan $b çıkarılır, sonra her taraf $k sayısına bölünür: $lo < x ≤ $hi. Bu aralıktaki tam sayıların sayısı $hi − ($lo) = $n.',
    );
  }),
  SoruSablonu('m-problem-yuzde', _mat, 'Problemler', 'Yüzde Problemleri', _o, ['s9-mat-07'], (r) {
    final p = 100 * rs(r, 2, 12), a = sec(r, [10, 20, 25, 50]), b = sec(r, [10, 20, 50]);
    final son = p * (100 + a) * (100 - b) ~/ 10000;
    return SoruTaslagi(
      'Etiket fiyatı $p TL olan bir ürüne önce %$a zam, ardından zamlı fiyat üzerinden %$b indirim yapılıyor. Ürünün son fiyatı kaç TL olur?',
      '$son',
      sayiCeldirici(son, [p * (100 + a - b) ~/ 100, p * (100 + a) ~/ 100, p * (100 - b) ~/ 100, p]),
      'Zamlı fiyat: $p · ${100 + a}/100 = ${p * (100 + a) ~/ 100} TL. İndirimli fiyat: ${p * (100 + a) ~/ 100} · ${100 - b}/100 = $son TL.',
    );
  }),
  SoruSablonu('m-problem-yas', _mat, 'Problemler', 'Yaş Problemleri', _o, ['s9-mat-07'], (r) {
    final c = rs(r, 6, 14), kat = rs(r, 3, 4), t = rs(r, 2, 8);
    final b = kat * c;
    return SoruTaslagi(
      'Bir babanın yaşı, oğlunun yaşının $kat katıdır. $t yıl sonra ikisinin yaşları toplamı ${b + c + 2 * t} olacağına göre baba bugün kaç yaşındadır?',
      '$b',
      sayiCeldirici(b, [c, b + t, b - t, b + c]),
      'Oğul x, baba ${kat}x yaşında olsun. $t yıl sonra toplam: ${kat + 1}x + ${2 * t} = ${b + c + 2 * t} ⟹ x = $c. Baba $kat · $c = $b yaşındadır.',
    );
  }),
  SoruSablonu('m-problem-oran', _mat, 'Oran – Orantı', 'Doğru Orantı', _k, ['s9-mat-07'], (r) {
    final a = rs(r, 2, 6), birim = sec(r, [12, 15, 18, 25, 30, 40]), b = a + rs(r, 1, 6);
    return SoruTaslagi(
      '$a kg elma ${a * birim} TL olduğuna göre aynı elmadan $b kg kaç TL eder?',
      '${b * birim}',
      sayiCeldirici(b * birim, [a * birim + b, (a + b) * birim, b * birim + birim, a * b]),
      'Kilogram fiyatı ${a * birim} : $a = $birim TL. $b kg için $b · $birim = ${b * birim} TL.',
    );
  }),
  // ─── 9. sınıf · Geometri ──────────────────────────────────────────────
  SoruSablonu('g-aci-1', _geo, 'Doğruda ve Üçgende Açılar', 'Üçgende İç Açılar', _k, ['s9-mat-08'], (r) {
    final o = sec(r, [
      [1, 2, 3],
      [2, 3, 4],
      [1, 1, 2],
      [2, 3, 5],
      [3, 4, 5],
      [1, 3, 5],
      [2, 2, 5],
      [4, 5, 6],
      [1, 4, 5],
    ]);
    final t = o[0] + o[1] + o[2];
    final b = 180 ~/ t;
    return SoruTaslagi(
      'Bir üçgenin iç açılarının ölçüleri ${o[0]}, ${o[1]} ve ${o[2]} sayılarıyla orantılıdır. Bu üçgenin en büyük açısının ölçüsü kaç derecedir?',
      '${o[2] * b}',
      sayiCeldirici(o[2] * b, [o[0] * b, o[1] * b, 360 * o[2] ~/ t, 180 - o[2] * b]),
      'Açılar ${o[0]}k, ${o[1]}k ve ${o[2]}k olsun. ${t}k = 180° ⟹ k = $b°. En büyük açı ${o[2]} · $b° = ${o[2] * b}°.',
    );
  }),
  SoruSablonu('g-aci-2', _geo, 'Doğruda ve Üçgende Açılar', 'Dış Açı', _k, ['s9-mat-08'], (r) {
    final a = 5 * rs(r, 6, 14), b = 5 * rs(r, 6, 14);
    return SoruTaslagi(
      'Bir ABC üçgeninde m(A) = $a° ve m(B) = $b° olduğuna göre C köşesindeki dış açının ölçüsü kaç derecedir?',
      '${a + b}',
      sayiCeldirici(a + b, [180 - a - b, 180 - a, 180 - b, 360 - a - b]),
      'Bir dış açının ölçüsü, kendisine komşu olmayan iki iç açının ölçüleri toplamına eşittir: $a° + $b° = ${a + b}°.',
    );
  }),
  SoruSablonu('g-kenar-1', _geo, 'Doğruda ve Üçgende Açılar', 'Üçgen Eşitsizliği', _o, ['s9-mat-08'], (r) {
    final a = rs(r, 3, 9), b = a + rs(r, 1, 6);
    final n = 2 * a - 1;
    return SoruTaslagi(
      'İki kenarının uzunluğu $a cm ve $b cm olan bir üçgenin üçüncü kenarının uzunluğu kaç farklı tam sayı değeri alabilir?',
      '$n',
      sayiCeldirici(n, [2 * a, 2 * a + 1, a + b - 1, b - a]),
      'Üçgen eşitsizliği: $b − $a < x < $b + $a ⟹ ${b - a} < x < ${a + b}. x; ${b - a + 1}, …, ${a + b - 1} değerlerini alır: $n farklı değer.',
    );
  }),
  SoruSablonu('g-donusum-1', _geo, 'Analitik Geometri', 'Dönüşümler', _o, ['s9-mat-09'], (r) {
    final a = rs(r, -6, 7), b = rs(r, 1, 8), c = rs(r, -5, 6), d = rs(r, -4, 5);
    final x = a + c, y = -b + d;
    String p(int u, int v) => '($u, $v)';
    return SoruTaslagi(
      'A($a, $b) noktasının x eksenine göre yansıması alınıyor, ardından elde edilen nokta ${c >= 0 ? '$c birim sağa' : '${-c} birim sola'} ve ${d >= 0 ? '$d birim yukarı' : '${-d} birim aşağı'} öteleniyor. Son noktanın koordinatları aşağıdakilerden hangisidir?',
      p(x, y),
      [p(-a + c, b + d), p(a + c, b + d), p(x, -y), p(a - c, -b - d), p(-x, y), p(x + 1, y), p(x, y + 1)],
      'x eksenine göre yansımada ordinat işaret değiştirir: ($a, ${-b}). Öteleme: ($a ${c >= 0 ? '+ $c' : '− ${-c}'}, ${-b} ${d >= 0 ? '+ $d' : '− ${-d}'}) = ${p(x, y)}.',
    );
  }),
  SoruSablonu('g-benzer-1', _geo, 'Benzerlik', 'Benzerlik Oranı', _k, ['s9-mat-10'], (r) {
    final k = rs(r, 2, 4), a = rs(r, 3, 9), b = a + rs(r, 1, 5);
    return SoruTaslagi(
      'ABC ve DEF üçgenleri benzerdir ve benzerlik oranı 1 : $k\'dir. ABC üçgeninde [AB] = $a cm, [BC] = $b cm ve [AB]\'nin karşılığı [DE] olduğuna göre |DE| + |EF| kaç cm\'dir?',
      '${k * (a + b)}',
      sayiCeldirici(k * (a + b), [a + b, k * a + b, k * k * (a + b), a + b + k]),
      'Benzer üçgenlerde karşılıklı kenarlar orantılıdır: |DE| = $k · $a = ${k * a}, |EF| = $k · $b = ${k * b}. Toplam ${k * (a + b)} cm.',
    );
  }),
  SoruSablonu('g-benzer-2', _geo, 'Benzerlik', 'Alanlar Oranı', _o, ['s9-mat-10'], (r) {
    final k = rs(r, 2, 5), alan = rs(r, 3, 12);
    return SoruTaslagi(
      'Benzerlik oranı 1 : $k olan iki benzer üçgenden küçüğünün alanı $alan cm² olduğuna göre büyüğünün alanı kaç cm²\'dir?',
      '${alan * k * k}',
      sayiCeldirici(alan * k * k, [alan * k, alan + k * k, alan * k * k * k, alan * 2 * k]),
      'Benzer şekillerin alanları oranı, benzerlik oranının karesine eşittir: $alan · $k² = ${alan * k * k} cm².',
    );
  }),
  SoruSablonu('g-pisagor-1', _geo, 'Dik Üçgen', 'Pisagor Bağıntısı', _k, ['s9-mat-11'], (r) {
    final u = sec(r, _uclular);
    final hip = r.nextBool();
    return hip
        ? SoruTaslagi(
            'Dik kenarlarının uzunlukları ${u[0]} cm ve ${u[1]} cm olan dik üçgenin hipotenüsü kaç cm\'dir?',
            '${u[2]}',
            sayiCeldirici(u[2], [u[0] + u[1], u[1] + 1, u[2] + 2, (u[0] + u[1]) ~/ 2]),
            'Pisagor bağıntısı: ${u[0]}² + ${u[1]}² = ${u[0] * u[0]} + ${u[1] * u[1]} = ${u[2] * u[2]} = ${u[2]}². Hipotenüs ${u[2]} cm.',
          )
        : SoruTaslagi(
            'Hipotenüsü ${u[2]} cm, dik kenarlarından biri ${u[0]} cm olan dik üçgenin diğer dik kenarı kaç cm\'dir?',
            '${u[1]}',
            sayiCeldirici(u[1], [u[2] - u[0], u[2] + u[0], u[1] + 2, u[0]]),
            'Pisagor bağıntısı: x² = ${u[2]}² − ${u[0]}² = ${u[2] * u[2]} − ${u[0] * u[0]} = ${u[1] * u[1]} ⟹ x = ${u[1]} cm.',
          );
  }),
  SoruSablonu('g-oklid-1', _geo, 'Dik Üçgen', 'Öklid Bağıntısı', _o, ['s9-mat-11'], (r) {
    final pq = sec(r, [
      [1, 4],
      [2, 8],
      [4, 9],
      [3, 12],
      [9, 16],
      [4, 16],
      [1, 9],
      [2, 18],
      [5, 20],
    ]);
    final h = sqrt(pq[0] * pq[1]).round();
    return SoruTaslagi(
      'Bir dik üçgende dik açının köşesinden hipotenüse indirilen yükseklik, hipotenüsü ${pq[0]} cm ve ${pq[1]} cm uzunluğunda iki parçaya ayırıyor. Bu yükseklik kaç cm\'dir?',
      '$h',
      sayiCeldirici(h, [pq[0] + pq[1], pq[0] * pq[1], (pq[0] + pq[1]) ~/ 2, pq[1] - pq[0]]),
      'Öklid bağıntısı: h² = p · q = ${pq[0]} · ${pq[1]} = ${pq[0] * pq[1]} ⟹ h = $h cm.',
    );
  }),
  // ─── 9. sınıf · Algoritma, veri, olasılık ─────────────────────────────
  SoruSablonu('m-algoritma-1', _mat, 'Algoritma ve Bilişim', 'Algoritma Temelli Problemler', _o, ['s9-mat-12'], (r) {
    final x0 = rs(r, 1, 5), c = rs(r, 2, 3), e = rs(r, 1, 5), n = rs(r, 2, 4);
    var x = x0;
    final adimlar = <int>[];
    for (var i = 0; i < n; i++) {
      x = x * c + e;
      adimlar.add(x);
    }
    return SoruTaslagi(
      'Bir algoritma şu adımlardan oluşuyor:\n1. x = $x0 al.\n2. x\'i $c ile çarp ve sonuca $e ekle.\n3. 2. adımı toplam $n kez uygula.\n4. x\'i yaz.\nBu algoritmanın çıktısı kaçtır?',
      '$x',
      sayiCeldirici(x, [x * c + e, adimlar.length > 1 ? adimlar[adimlar.length - 2] : x0 * c, x0 * _us(c, n), x + e]),
      'Adım adım: $x0 → ${adimlar.join(' → ')}. Çıktı $x olur.',
    );
  }),
  SoruSablonu('m-algoritma-2', _mat, 'Algoritma ve Bilişim', 'Algoritma Temelli Problemler', _o, ['s9-mat-12'], (r) {
    final n = rs(r, 5, 12);
    final t = n * (n + 1) ~/ 2;
    return SoruTaslagi(
      'Bir algoritma şu adımlardan oluşuyor:\n1. Toplam = 0 ve i = 1 al.\n2. Toplam\'a i\'yi ekle, i\'yi 1 artır.\n3. i ≤ $n ise 2. adıma dön.\n4. Toplam\'ı yaz.\nBu algoritmanın çıktısı kaçtır?',
      '$t',
      sayiCeldirici(t, [t - n, t + n + 1, n * n, n * (n - 1)]),
      'Algoritma 1\'den $n\'e kadar olan sayıları toplar: $n · ${n + 1} : 2 = $t.',
    );
  }),
  SoruSablonu('m-mantik-1', _mat, 'Mantık', 'Bileşik Önermeler', _k, ['s9-mat-13'], (r) {
    final n = rs(r, 3, 6);
    final v = _us(2, n);
    return SoruTaslagi(
      'Birbirinden bağımsız $n farklı önermeden oluşan bir bileşik önermenin doğruluk tablosunda kaç satır (doğruluk durumu) bulunur?',
      '$v',
      sayiCeldirici(v, [2 * n, n * n, v ~/ 2, v * 2, _fakt(n)]),
      'Her önerme doğru ya da yanlış olmak üzere 2 değer alır; $n önerme için 2^$n = $v farklı durum vardır.',
    );
  }),
  SoruSablonu('m-mantik-2', _mat, 'Mantık', 'Bileşik Önermeler', _o, ['s9-mat-13'], (r) {
    final p = r.nextBool(), q = r.nextBool(), t = r.nextBool();
    String d(bool b) => b ? '1' : '0';
    final veya = p || q, ve = p && q, ise = !p || q, ancak = p == q;
    final toplam = [veya, ve, ise, ancak, !t].where((e) => e).length;
    return SoruTaslagi(
      'p ≡ ${d(p)}, q ≡ ${d(q)} ve r ≡ ${d(t)} olduğuna göre\nI. p ∨ q\nII. p ∧ q\nIII. p ⇒ q\nIV. p ⇔ q\nV. r′\nönermelerinden kaç tanesi doğrudur?',
      '$toplam',
      ['0', '1', '2', '3', '4', '5'],
      'p ∨ q ≡ ${d(veya)}, p ∧ q ≡ ${d(ve)}, p ⇒ q ≡ ${d(ise)}, p ⇔ q ≡ ${d(ancak)}, r′ ≡ ${d(!t)}. Doğru olanların sayısı $toplam.',
    );
  }),
  SoruSablonu('m-veri-1', _mat, 'Veri ve İstatistik', 'Merkezî Eğilim Ölçüleri', _k, ['s9-mat-14'], (r) {
    final ort = rs(r, 5, 20);
    final sap = sec(r, [
      [-4, -1, 0, 2, 3],
      [-3, -2, 0, 1, 4],
      [-5, -1, 1, 2, 3],
      [-2, -1, 0, 1, 2],
      [-6, 0, 1, 2, 3],
    ]);
    final v = [for (final s in sap) ort + s]..shuffle(r);
    return SoruTaslagi(
      '${v.join(', ')} veri grubunun aritmetik ortalaması kaçtır?',
      '$ort',
      sayiCeldirici(ort, [ort + 1, ort - 1, ort + 2, v.reduce(max) - v.reduce(min)]),
      'Veriler toplanıp veri sayısına bölünür: ${v.join(' + ')} = ${5 * ort}; ${5 * ort} : 5 = $ort.',
    );
  }),
  SoruSablonu('m-veri-2', _mat, 'Veri ve İstatistik', 'Merkezî Eğilim ve Yayılım Ölçüleri', _o, ['s9-mat-14'], (r) {
    final taban = rs(r, 3, 12);
    final v = <int>[taban];
    for (var i = 0; i < 6; i++) {
      v.add(v.last + rs(r, 1, 4));
    }
    final medyan = v[3], aciklik = v.last - v.first;
    final karisik = [...v]..shuffle(r);
    return SoruTaslagi(
      '${karisik.join(', ')} veri grubunun medyanı (ortanca) ile açıklığının toplamı kaçtır?',
      '${medyan + aciklik}',
      sayiCeldirici(medyan + aciklik, [medyan, aciklik, v[2] + aciklik, v[4] + aciklik, medyan + v.last]),
      'Veriler sıralanır: ${v.join(', ')}. Ortadaki (4.) değer medyandır: $medyan. Açıklık = ${v.last} − ${v.first} = $aciklik. Toplam ${medyan + aciklik}.',
    );
  }),
  SoruSablonu('m-olasilik-1', _mat, 'Sayma ve Olasılık', 'Olasılık', _k, ['s9-mat-15'], (r) {
    final k = rs(r, 2, 7), m = rs(r, 2, 8), s = rs(r, 1, 6);
    final t = k + m + s;
    return SoruTaslagi(
      'Bir torbada $k kırmızı, $m mavi ve $s sarı top vardır. Torbadan rastgele çekilen bir topun mavi olmama olasılığı kaçtır?',
      kesir(k + s, t),
      [kesir(m, t), kesir(k, t), kesir(s, t), kesir(k + s, m + t), kesir(m, k + s), kesir(1, t), kesir(k + m, t)],
      'Mavi olmayan top sayısı $k + $s = ${k + s}, toplam top sayısı $t. Olasılık ${k + s}/$t${kesir(k + s, t) == '${k + s}/$t' ? '' : ' = ${kesir(k + s, t)}'}.',
    );
  }),
  SoruSablonu('m-olasilik-2', _mat, 'Sayma ve Olasılık', 'Olasılık', _o, ['s9-mat-15'], (r) {
    final hedef = rs(r, 4, 10);
    var adet = 0;
    for (var i = 1; i <= 6; i++) {
      if (hedef - i >= 1 && hedef - i <= 6) adet++;
    }
    return SoruTaslagi(
      'Hilesiz iki zar birlikte atılıyor. Üst yüze gelen sayıların toplamının $hedef olma olasılığı kaçtır?',
      kesir(adet, 36),
      [kesir(adet + 1, 36), kesir(adet - 1 == 0 ? 7 : adet - 1, 36), kesir(1, 6) == kesir(adet, 36) ? '1/4' : '1/6', kesir(hedef, 36), '1/2', '1/3', '1/12'],
      'İki zarda 36 eşit olasılıklı durum vardır. Toplamı $hedef olan $adet durum bulunur. Olasılık $adet/36 = ${kesir(adet, 36)}.',
    );
  }),
  SoruSablonu('m-olasilik-3', _mat, 'Sayma ve Olasılık', 'Deneysel Olasılık', _k, ['s9-mat-15'], (r) {
    final n = sec(r, [40, 50, 80, 100, 200]), yuzde = sec(r, [20, 30, 40, 45, 55, 60]);
    final tura = n * yuzde ~/ 100;
    return SoruTaslagi(
      'Bir madenî para $n kez atılmış ve $tura kez tura gelmiştir. Bu deneye göre tura gelmesinin deneysel olasılığı kaçtır?',
      kesir(tura, n),
      [kesir(n - tura, n), '1/2' == kesir(tura, n) ? '2/5' : '1/2', kesir(tura, n - tura), kesir(tura + n ~/ 10, n), kesir(1, 4), kesir(3, 4), kesir(1, 5)],
      'Deneysel olasılık = istenen sonucun gözlenme sayısı / deneme sayısı = $tura/$n = ${kesir(tura, n)}. (Teorik olasılık 1/2\'dir; deneme sayısı arttıkça deneysel olasılık buna yaklaşır.)',
    );
  }),
  // ─── 10. sınıf ────────────────────────────────────────────────────────
  SoruSablonu('m-trig-oran-1', _mat, 'Trigonometri', 'Dik Üçgende Trigonometrik Oranlar', _k, ['s10-mat-01'], (r) {
    final u = sec(r, _uclular.where((u) => ebob(u[0], u[1]) == 1 || u[2] <= 20).toList());
    final tur = r.nextInt(3);
    final ad = ['sin', 'cos', 'tan'][tur];
    final dogru = [kesir(u[0], u[2]), kesir(u[1], u[2]), kesir(u[0], u[1])][tur];
    return SoruTaslagi(
      'Bir ABC dik üçgeninde m(B) = 90°, |AB| = ${u[1]} cm, |BC| = ${u[0]} cm ve |AC| = ${u[2]} cm\'dir. Buna göre $ad A kaçtır?',
      dogru,
      [kesir(u[0], u[2]), kesir(u[1], u[2]), kesir(u[0], u[1]), kesir(u[1], u[0]), kesir(u[2], u[1]), kesir(u[2], u[0])],
      'A açısının karşısındaki kenar |BC| = ${u[0]}, komşu dik kenar |AB| = ${u[1]}, hipotenüs |AC| = ${u[2]}. sin = karşı/hipotenüs, cos = komşu/hipotenüs, tan = karşı/komşu olduğundan $ad A = $dogru.',
    );
  }),
  SoruSablonu('m-trig-oran-2', _mat, 'Trigonometri', 'Trigonometrik Özdeşlikler', _o, ['s10-mat-01'], (r) {
    final u = sec(r, [
      [3, 4, 5],
      [5, 12, 13],
      [8, 15, 17],
      [7, 24, 25],
    ]);
    return SoruTaslagi(
      'α bir dar açı ve sin α = ${u[0]}/${u[2]} olduğuna göre cos α kaçtır?',
      '${u[1]}/${u[2]}',
      ['${u[0]}/${u[1]}', '${u[1]}/${u[0]}', '${u[2] - u[0]}/${u[2]}', '${u[2]}/${u[1]}', '${u[0]}/${u[2] + 1}', '1/${u[2]}'],
      'sin²α + cos²α = 1 ⟹ cos²α = 1 − ${u[0] * u[0]}/${u[2] * u[2]} = ${u[1] * u[1]}/${u[2] * u[2]}. α dar açı olduğundan cos α = ${u[1]}/${u[2]}.',
    );
  }),
  SoruSablonu('g-yardimci-1', _geo, 'Üçgende Yardımcı Elemanlar', 'Açıortay', _o, ['s10-mat-02'], (r) {
    final k = rs(r, 2, 4), a = rs(r, 2, 5);
    var b = rs(r, 3, 7);
    if (b == a) b = a + 1;
    return SoruTaslagi(
      'Bir ABC üçgeninde [AD] iç açıortaydır (D, [BC] üzerinde). |AB| = ${a * k} cm, |AC| = ${b * k} cm ve |BD| = ${a * 2} cm olduğuna göre |DC| kaç cm\'dir?',
      '${b * 2}',
      sayiCeldirici(b * 2, [a * 2, b * k, a * k, b * 2 + k]),
      'İç açıortay teoremi: |AB| / |AC| = |BD| / |DC| ⟹ ${a * k}/${b * k} = ${a * 2}/|DC| ⟹ |DC| = ${b * 2} cm.',
    );
  }),
  SoruSablonu('g-yardimci-2', _geo, 'Üçgende Yardımcı Elemanlar', 'Kenarortay', _o, ['s10-mat-02'], (r) {
    final g = rs(r, 2, 9);
    return SoruTaslagi(
      'Bir ABC üçgeninde G ağırlık merkezi ve [AD] kenarortaydır. |GD| = $g cm olduğuna göre |AD| kaç cm\'dir?',
      '${3 * g}',
      sayiCeldirici(3 * g, [2 * g, 4 * g, g + 3, 6 * g]),
      'Ağırlık merkezi kenarortayı köşeden itibaren 2 : 1 oranında böler: |AG| = 2 · |GD| = ${2 * g}. |AD| = ${2 * g} + $g = ${3 * g} cm.',
    );
  }),
  SoruSablonu('g-alan-1', _geo, 'Üçgende Alan', 'Taban ve Yükseklik', _k, ['s10-mat-03'], (r) {
    final a = 2 * rs(r, 3, 10), h = rs(r, 3, 12);
    return SoruTaslagi(
      'Bir kenarı $a cm ve bu kenara ait yüksekliği $h cm olan üçgenin alanı kaç cm²\'dir?',
      '${a * h ~/ 2}',
      sayiCeldirici(a * h ~/ 2, [a * h, a + h, a * h ~/ 4, (a + h) * 2]),
      'Alan = (taban · yükseklik) / 2 = ($a · $h) / 2 = ${a * h ~/ 2} cm².',
    );
  }),
  SoruSablonu('g-alan-2', _geo, 'Üçgende Alan', 'Sinüs Alan Formülü', _o, ['s10-mat-03'], (r) {
    final a = 2 * rs(r, 2, 8), b = 2 * rs(r, 2, 7);
    final aci = sec(r, [30, 150]);
    return SoruTaslagi(
      'İki kenarının uzunluğu $a cm ve $b cm, bu kenarlar arasındaki açının ölçüsü $aci° olan üçgenin alanı kaç cm²\'dir?',
      '${a * b ~/ 4}',
      sayiCeldirici(a * b ~/ 4, [a * b ~/ 2, a * b, a * b ~/ 8, a + b]),
      'Alan = (1/2) · a · b · sin C = (1/2) · $a · $b · sin $aci° = (1/2) · $a · $b · (1/2) = ${a * b ~/ 4} cm².',
    );
  }),
  SoruSablonu('g-kosinus-1', _geo, 'Üçgende Alan', 'Kosinüs Teoremi', _z, ['s10-mat-04'], (r) {
    final v = sec(r, [
      [3, 8, 60, 7],
      [5, 8, 60, 7],
      [8, 15, 60, 13],
      [7, 15, 60, 13],
      [6, 16, 60, 14],
      [5, 21, 60, 19],
      [3, 5, 120, 7],
      [7, 8, 120, 13],
      [5, 16, 120, 19],
    ]);
    final a = v[0], b = v[1], aci = v[2], c = v[3];
    return SoruTaslagi(
      'Bir ABC üçgeninde |AB| = $a cm, |AC| = $b cm ve m(A) = $aci° olduğuna göre |BC| kaç cm\'dir?',
      '$c',
      sayiCeldirici(c, [a + b, b - a, c + 2, c - 2, b]),
      'Kosinüs teoremi: |BC|² = $a² + $b² − 2 · $a · $b · cos $aci° = ${a * a + b * b} ${aci == 60 ? '−' : '+'} ${a * b} = ${c * c} ⟹ |BC| = $c cm.',
    );
  }),
  SoruSablonu('g-sinus-1', _geo, 'Üçgende Alan', 'Sinüs Teoremi', _o, ['s10-mat-04'], (r) {
    final a = rs(r, 3, 12);
    return SoruTaslagi(
      'Bir ABC üçgeninde m(A) = 30°, m(B) = 90° ve |BC| = $a cm olduğuna göre |AC| kaç cm\'dir?',
      '${2 * a}',
      sayiCeldirici(2 * a, [a, 3 * a, a + 2, 4 * a]),
      'Sinüs teoremi: |BC| / sin A = |AC| / sin B ⟹ $a / (1/2) = |AC| / 1 ⟹ |AC| = ${2 * a} cm.',
    );
  }),
  SoruSablonu('m-kategorik-1', _mat, 'Veri ve İstatistik', 'İki Kategorik Değişkenli Veriler', _o, ['s10-mat-05'], (r) {
    final toplam = sec(r, [20, 25, 40, 50]);
    final yuzde = sec(r, [20, 40, 60, 80]);
    final kiz = toplam * yuzde ~/ 100, erkek = toplam - kiz;
    final diger = rs(r, 10, 30);
    return SoruTaslagi(
      'Bir okulda yapılan ankete göre spor kulübüne üye $toplam öğrencinin $kiz\'i kız, $erkek\'i erkektir. Spor kulübüne üye olmayan $diger öğrenci daha vardır. Spor kulübüne üye öğrencilerin yüzde kaçı kızdır?',
      '$yuzde',
      sayiCeldirici(yuzde, [100 - yuzde, 100 * kiz ~/ (toplam + diger), kiz, yuzde + 10, yuzde - 10]),
      'Koşul “spor kulübüne üye olanlar” olduğundan yalnızca bu $toplam öğrenciye bakılır: $kiz / $toplam = %$yuzde.',
    );
  }),
  SoruSablonu('m-bolen-1', _mat, 'Temel Kavramlar', 'Asal Çarpanlar ve Bölen Sayısı', _o, ['s10-mat-06'], (r) {
    final a = rs(r, 1, 4), b = rs(r, 1, 3), c = rs(r, 0, 2);
    final n = _us(2, a) * _us(3, b) * _us(5, c);
    final d = (a + 1) * (b + 1) * (c + 1);
    return SoruTaslagi(
      '$n sayısının pozitif tam bölenlerinin sayısı kaçtır?',
      '$d',
      sayiCeldirici(d, [a + b + c, a * b * (c == 0 ? 1 : c), d + 2, 2 * d, a + b + c + 3]),
      '$n = 2^$a · 3^$b${c > 0 ? ' · 5^$c' : ''}. Pozitif bölen sayısı, üslerin birer fazlasının çarpımıdır: ${a + 1} · ${b + 1}${c > 0 ? ' · ${c + 1}' : ''} = $d.',
    );
  }),
  SoruSablonu('m-bolen-2', _mat, 'Temel Kavramlar', 'Asal Çarpanlar ve Bölen Sayısı', _k, ['s10-mat-06'], (r) {
    final v = sec(r, [
      [60, 3, 10],
      [84, 3, 12],
      [90, 3, 10],
      [210, 4, 17],
      [126, 3, 12],
      [330, 4, 21],
      [140, 3, 14],
      [154, 3, 20],
      [390, 4, 23],
      [72, 2, 5],
    ]);
    return SoruTaslagi(
      '${v[0]} sayısının birbirinden farklı asal çarpanlarının toplamı kaçtır?',
      '${v[2]}',
      sayiCeldirici(v[2], [v[1], v[2] + 2, v[2] + 1, v[2] - 2, v[2] + 5]),
      '${v[0]} asal çarpanlarına ayrılır; farklı asal çarpanları ${v[1]} tanedir ve toplamları ${v[2]} olur.',
    );
  }),
  SoruSablonu('m-ebob-1', _mat, 'Temel Kavramlar', 'EBOB – EKOK', _k, ['s10-mat-07'], (r) {
    final g = sec(r, [2, 3, 4, 5, 6, 8, 12]);
    final ps = sec(r, [
      [2, 3],
      [3, 4],
      [2, 5],
      [3, 5],
      [4, 5],
      [1, 4],
      [5, 6],
      [3, 7],
    ]);
    final a = g * ps[0], b = g * ps[1], ekok = g * ps[0] * ps[1];
    final ebobSor = r.nextBool();
    return ebobSor
        ? SoruTaslagi('EBOB($a, $b) kaçtır?', '$g', sayiCeldirici(g, [ekok, b - a, a, 2 * g, 1]),
            '$a = $g · ${ps[0]} ve $b = $g · ${ps[1]}; ${ps[0]} ile ${ps[1]} aralarında asal olduğundan EBOB = $g.')
        : SoruTaslagi('EKOK($a, $b) kaçtır?', '$ekok', sayiCeldirici(ekok, [a * b, g, a + b, 2 * ekok, ekok ~/ 2]),
            '$a = $g · ${ps[0]} ve $b = $g · ${ps[1]}. EKOK = $g · ${ps[0]} · ${ps[1]} = $ekok.');
  }),
  SoruSablonu('m-ebob-2', _mat, 'Temel Kavramlar', 'EBOB – EKOK', _o, ['s10-mat-07'], (r) {
    final a = sec(r, [4, 6, 8, 9, 10, 12]);
    var b = sec(r, [6, 8, 10, 12, 15, 18]);
    if (b == a) b = a + 6;
    final ekok = a * b ~/ ebob(a, b);
    return SoruTaslagi(
      'İki zil sırasıyla $a ve $b dakikada bir çalmaktadır. İkisi birlikte çaldıktan en az kaç dakika sonra yeniden birlikte çalarlar?',
      '$ekok',
      sayiCeldirici(ekok, [a * b, a + b, ebob(a, b), 2 * ekok]),
      'Birlikte çalma anları, sürelerin ortak katlarıdır. İlk ortak an EKOK($a, $b) = $ekok dakika sonradır.',
    );
  }),
  SoruSablonu('m-kalan-1', _mat, 'Temel Kavramlar', 'Bölme ve Kalan', _o, ['s10-mat-08'], (r) {
    final d = sec(r, [5, 7, 9, 11]), kalan = rs(r, 2, d - 1), k = rs(r, 2, 6);
    final v = (kalan * k) % d;
    return SoruTaslagi(
      'Bir A doğal sayısının $d ile bölümünden kalan $kalan\'dir. Buna göre $k · A sayısının $d ile bölümünden kalan kaçtır?',
      '$v',
      [for (var i = 0; i < d && i < 8; i++) '$i', '${kalan * k}'],
      'Kalan da $k ile çarpılır: $k · $kalan = ${kalan * k}. ${kalan * k} sayısının $d ile bölümünden kalan $v.',
    );
  }),
  SoruSablonu('m-kalan-2', _mat, 'Temel Kavramlar', 'Bölünebilme', _k, ['s10-mat-08'], (r) {
    final a = rs(r, 1, 9), b = rs(r, 0, 9), c = rs(r, 0, 9);
    final t = a + b + c;
    final x = (9 - t % 9) % 9;
    return SoruTaslagi(
      'Dört basamaklı $a$b${c}x sayısı 9 ile tam bölünebildiğine göre x rakamı kaçtır? (x ≠ 9)',
      '$x',
      ['0', '1', '2', '3', '4', '5', '6', '7', '8']..shuffle(r),
      'Bir sayının 9 ile bölünebilmesi için rakamları toplamı 9\'un katı olmalıdır: $a + $b + $c + x = $t + x. 9\'un katı olması için x = $x.',
    );
  }),
  SoruSablonu('m-fonk-1', _mat, 'Fonksiyonlar', 'Fonksiyonun Değeri', _k, ['s10-mat-09'], (r) {
    final a = rs(r, 1, 3), b = rs(r, -5, 5), c = rs(r, -6, 8), k = rs(r, -3, 4);
    final v = a * k * k + b * k + c;
    String t(int n, String s) => n == 0 ? '' : ' ${n < 0 ? '−' : '+'} ${n.abs() == 1 && s.isNotEmpty ? '' : n.abs()}$s';
    return SoruTaslagi(
      'f(x) = ${a == 1 ? '' : a}x²${t(b, 'x')}${t(c, '')} fonksiyonu için f($k) kaçtır?',
      '$v',
      sayiCeldirici(v, [a * k * k - b * k + c, 2 * a * k + b * k + c, v + 2 * b, a * k * k + c], negatif: true),
      'f($k) = $a · ($k)² ${b < 0 ? '−' : '+'} ${b.abs()} · ($k) ${c < 0 ? '−' : '+'} ${c.abs()} = ${a * k * k} ${b * k < 0 ? '−' : '+'} ${(b * k).abs()} ${c < 0 ? '−' : '+'} ${c.abs()} = $v.',
    );
  }),
  SoruSablonu('m-karesel-1', _mat, 'Parabol', 'Tepe Noktası', _o, ['s10-mat-10'], (r) {
    final h = rs(r, -4, 6), k = rs(r, -9, 9);
    final b = -2 * h, c = h * h + k;
    String t(int n, String s) => n == 0 ? '' : ' ${n < 0 ? '−' : '+'} ${n.abs()}$s';
    return SoruTaslagi(
      'f(x) = x²${t(b, 'x')}${t(c, '')} fonksiyonunun alabileceği en küçük değer kaçtır?',
      '$k',
      sayiCeldirici(k, [c, h, -k, k + h, b], negatif: true),
      'Tepe noktasının apsisi r = −b / 2a = $h. En küçük değer f($h) = ${h * h} ${-2 * h * h < 0 ? '−' : '+'} ${(2 * h * h).abs()} ${c < 0 ? '−' : '+'} ${c.abs()} = $k.',
    );
  }),
  SoruSablonu('m-karesel-2', _mat, 'İkinci Dereceden Denklemler', 'Kökler Toplamı ve Çarpımı', _k, ['s10-mat-10', 's10-mat-13'], (r) {
    final p = rs(r, -6, 8);
    var q = rs(r, -5, 9);
    if (q == p) q = p + 2;
    final s = p + q, c = p * q;
    String t(int n, String x) => n == 0 ? '' : ' ${n < 0 ? '−' : '+'} ${n.abs() == 1 && x.isNotEmpty ? '' : n.abs()}$x';
    final toplamSor = r.nextBool();
    return SoruTaslagi(
      'x²${t(-s, 'x')}${t(c, '')} = 0 denkleminin köklerinin ${toplamSor ? 'toplamı' : 'çarpımı'} kaçtır?',
      '${toplamSor ? s : c}',
      sayiCeldirici(toplamSor ? s : c, [toplamSor ? c : s, -s, -c, s + c], negatif: true),
      'x² + bx + c = 0 denkleminde kökler toplamı −b, kökler çarpımı c\'dir. Kökler $p ve $q olup ${toplamSor ? 'toplamları $s' : 'çarpımları $c'}.',
    );
  }),
  SoruSablonu('m-karekok-1', _mat, 'Fonksiyonlar', 'Karekök Fonksiyonu', _o, ['s10-mat-11'], (r) {
    final a = rs(r, -6, 9), b = rs(r, -4, 6), kk = rs(r, 2, 6);
    final x = a + kk * kk;
    final am = a < 0 ? '+ ${-a}' : '− $a';
    return SoruTaslagi(
      'f(x) = √(x $am) ${b < 0 ? '− ${-b}' : '+ $b'} fonksiyonu için f($x) kaçtır?',
      '${kk + b}',
      sayiCeldirici(kk + b, [kk * kk + b, kk, kk - b, x + b], negatif: true),
      'f($x) = √($x $am) ${b < 0 ? '− ${-b}' : '+ $b'} = √${kk * kk} ${b < 0 ? '− ${-b}' : '+ $b'} = $kk ${b < 0 ? '− ${-b}' : '+ $b'} = ${kk + b}.',
    );
  }),
  SoruSablonu('m-karekok-2', _mat, 'Fonksiyonlar', 'Tanım Kümesi', _k, ['s10-mat-11'], (r) {
    final a = rs(r, -8, 12);
    final am = a < 0 ? '+ ${-a}' : '− $a';
    return SoruTaslagi(
      'f(x) = √(x $am) fonksiyonunun tanımlı olduğu en küçük x tam sayısı kaçtır?',
      '$a',
      sayiCeldirici(a, [a + 1, -a, a - 1, 0], negatif: true),
      'Karekökün içi negatif olamaz: x $am ≥ 0 ⟹ x ≥ $a. En küçük tam sayı $a.',
    );
  }),
  SoruSablonu('m-rasyonel-1', _mat, 'Fonksiyonlar', 'Rasyonel Fonksiyon', _k, ['s10-mat-11'], (r) {
    final c = rs(r, -7, 9), a = rs(r, 2, 5), b = rs(r, 1, 9);
    final cm = c < 0 ? '+ ${-c}' : '− $c';
    return SoruTaslagi(
      'f(x) = (${a}x + $b) / (x $cm) fonksiyonunu tanımsız yapan x değeri kaçtır?',
      '$c',
      sayiCeldirici(c, [-c, a, -b, b, 0], negatif: true),
      'Rasyonel fonksiyon paydayı sıfır yapan değerde tanımsızdır: x $cm = 0 ⟹ x = $c. (x = $c doğrusu grafiğin düşey asimptotudur.)',
    );
  }),
  SoruSablonu('m-ters-1', _mat, 'Fonksiyonlar', 'Ters Fonksiyon', _o, ['s10-mat-12'], (r) {
    final a = rs(r, 2, 6), b = rs(r, -8, 9), x0 = rs(r, -4, 7);
    final k = a * x0 + b;
    final bm = b < 0 ? '− ${-b}' : '+ $b';
    return SoruTaslagi(
      'f(x) = ${a}x $bm olduğuna göre f⁻¹($k) kaçtır?',
      '$x0',
      sayiCeldirici(x0, [a * k + b, k - b, -x0, x0 + a], negatif: true),
      'f⁻¹($k) = t ise f(t) = $k olur: ${a}t $bm = $k ⟹ ${a}t = ${k - b} ⟹ t = $x0.',
    );
  }),
  SoruSablonu('m-fonkdenk-1', _mat, 'İkinci Dereceden Denklemler', 'Çarpanlara Ayırarak Çözme', _o, ['s10-mat-13'], (r) {
    final p = rs(r, -6, 3), q = p + rs(r, 2, 8);
    final s = p + q, c = p * q;
    String t(int n, String x) => n == 0 ? '' : ' ${n < 0 ? '−' : '+'} ${n.abs() == 1 && x.isNotEmpty ? '' : n.abs()}$x';
    final n = q - p - 1;
    return SoruTaslagi(
      'x²${t(-s, 'x')}${t(c, '')} < 0 eşitsizliğini sağlayan kaç farklı x tam sayısı vardır?',
      '$n',
      sayiCeldirici(n, [n + 1, n + 2, q - p, q]),
      'x²${t(-s, 'x')}${t(c, '')} = (x ${p < 0 ? '+ ${-p}' : '− $p'})(x ${q < 0 ? '+ ${-q}' : '− $q'}). Çarpım, kökler arasında negatiftir: $p < x < $q. Bu aralıkta $n tam sayı vardır.',
    );
  }),
  SoruSablonu('m-sayma-1', _mat, 'Sayma ve Olasılık', 'Permütasyon', _k, ['s10-mat-14'], (r) {
    final n = rs(r, 4, 7), k = rs(r, 2, 3);
    var v = 1;
    for (var i = 0; i < k; i++) {
      v *= n - i;
    }
    return SoruTaslagi(
      '$n kişilik bir gruptan bir başkan${k == 3 ? ', bir başkan yardımcısı' : ''} ve bir sekreter kaç farklı şekilde seçilebilir? (Bir kişi yalnızca bir göreve seçilebilir.)',
      '$v',
      sayiCeldirici(v, [_us(n, k), v ~/ _fakt(k), n * k, _fakt(n) > 2000 ? v + n : _fakt(n)]),
      'Görevler farklı olduğundan sıra önemlidir: P($n, $k) = ${[for (var i = 0; i < k; i++) n - i].join(' · ')} = $v.',
    );
  }),
  SoruSablonu('m-sayma-2', _mat, 'Sayma ve Olasılık', 'Kombinasyon', _o, ['s10-mat-14'], (r) {
    final n = rs(r, 5, 9), k = rs(r, 2, 3);
    var pay = 1;
    for (var i = 0; i < k; i++) {
      pay *= n - i;
    }
    final v = pay ~/ _fakt(k);
    return SoruTaslagi(
      '$n kişilik bir sınıftan $k kişilik bir ekip kaç farklı şekilde oluşturulabilir?',
      '$v',
      sayiCeldirici(v, [pay, n * k, _us(n, k), v + n]),
      'Ekipte sıra önemli değildir: C($n, $k) = (${[for (var i = 0; i < k; i++) n - i].join(' · ')}) / $k! = $pay / ${_fakt(k)} = $v.',
    );
  }),
  SoruSablonu('m-sayma-3', _mat, 'Sayma ve Olasılık', 'Sayma Stratejileri', _k, ['s10-mat-14'], (r) {
    final g = rs(r, 2, 5), p = rs(r, 2, 6), a = rs(r, 2, 4);
    return SoruTaslagi(
      '$g farklı gömleği, $p farklı pantolonu ve $a farklı ayakkabısı olan biri; bir gömlek, bir pantolon ve bir ayakkabıyı kaç farklı şekilde seçip giyebilir?',
      '${g * p * a}',
      sayiCeldirici(g * p * a, [g + p + a, g * p + a, g * p, (g + p) * a]),
      'Çarpma yoluyla sayma: $g · $p · $a = ${g * p * a}.',
    );
  }),
  SoruSablonu('g-analitik-1', _geo, 'Analitik Geometri', 'İki Nokta Arası Uzaklık', _k, ['s10-mat-15'], (r) {
    final u = sec(r, _uclular);
    final x1 = rs(r, -5, 5), y1 = rs(r, -5, 5);
    final x2 = x1 + (r.nextBool() ? u[0] : -u[0]), y2 = y1 + (r.nextBool() ? u[1] : -u[1]);
    return SoruTaslagi(
      'Dik koordinat düzleminde A($x1, $y1) ve B($x2, $y2) noktaları arasındaki uzaklık kaç birimdir?',
      '${u[2]}',
      sayiCeldirici(u[2], [u[0] + u[1], u[1], u[2] + 2, u[0]]),
      '|AB| = √(($x2 − ($x1))² + ($y2 − ($y1))²) = √(${u[0] * u[0]} + ${u[1] * u[1]}) = √${u[2] * u[2]} = ${u[2]}.',
    );
  }),
  SoruSablonu('g-analitik-2', _geo, 'Analitik Geometri', 'Orta Nokta', _k, ['s10-mat-15'], (r) {
    final mx = rs(r, -5, 7), my = rs(r, -5, 7), dx = rs(r, 1, 6), dy = rs(r, 1, 6);
    return SoruTaslagi(
      'A(${mx - dx}, ${my + dy}) ve B(${mx + dx}, ${my - dy}) noktalarını birleştiren doğru parçasının orta noktasının koordinatları toplamı kaçtır?',
      '${mx + my}',
      sayiCeldirici(mx + my, [2 * (mx + my), mx - my, mx * my, dx + dy], negatif: true),
      'Orta nokta: ((${mx - dx} + ${mx + dx}) / 2, (${my + dy} + ${my - dy}) / 2) = ($mx, $my). Koordinatlar toplamı ${mx + my}.',
    );
  }),
  SoruSablonu('g-analitik-3', _geo, 'Analitik Geometri', 'Doğrunun Eğimi', _k, ['s10-mat-16'], (r) {
    final m = sec(r, [-4, -3, -2, 2, 3, 4, 5]), x1 = rs(r, -4, 4), y1 = rs(r, -6, 6), dx = rs(r, 1, 4);
    return SoruTaslagi(
      'A($x1, $y1) ve B(${x1 + dx}, ${y1 + m * dx}) noktalarından geçen doğrunun eğimi kaçtır?',
      '$m',
      sayiCeldirici(m, [-m, m * dx, dx, m + 1], negatif: true),
      'Eğim = (y₂ − y₁) / (x₂ − x₁) = (${y1 + m * dx} − ($y1)) / (${x1 + dx} − ($x1)) = ${m * dx} / $dx = $m.',
    );
  }),
  SoruSablonu('g-analitik-4', _geo, 'Analitik Geometri', 'Doğru Denklemi', _o, ['s10-mat-16'], (r) {
    final m = sec(r, [-3, -2, 2, 3, 4]), n = rs(r, -7, 9), x0 = rs(r, 1, 5);
    return SoruTaslagi(
      'Eğimi $m olan ve A($x0, ${m * x0 + n}) noktasından geçen doğrunun y eksenini kestiği noktanın ordinatı kaçtır?',
      '$n',
      sayiCeldirici(n, [m * x0 + n, -n, n + m, m * x0], negatif: true),
      'y = ${m}x + n doğrusunda A noktası yerine yazılır: ${m * x0 + n} = $m · $x0 + n ⟹ n = $n. Doğru y eksenini (0, $n) noktasında keser.',
    );
  }),
  SoruSablonu('m-kosullu-1', _mat, 'Sayma ve Olasılık', 'Koşullu Olasılık', _o, ['s10-mat-17'], (r) {
    final kiz = rs(r, 8, 16), erkek = rs(r, 8, 16), gk = rs(r, 2, kiz - 3), ge = rs(r, 2, erkek - 3);
    return SoruTaslagi(
      'Bir sınıfta $kiz kız, $erkek erkek öğrenci vardır. Kızların $gk\'i, erkeklerin $ge\'i gözlüklüdür. Rastgele seçilen bir öğrencinin gözlüklü olduğu bilindiğine göre kız olma olasılığı kaçtır?',
      kesir(gk, gk + ge),
      [kesir(gk, kiz), kesir(gk, kiz + erkek), kesir(ge, gk + ge), kesir(kiz, kiz + erkek), kesir(gk + ge, kiz + erkek), kesir(gk, ge + kiz), kesir(1, gk + ge)],
      'Koşul “gözlüklü olmak” olduğundan örnek uzay gözlüklü ${gk + ge} öğrencidir. Bunların $gk\'i kız: $gk/${gk + ge}${kesir(gk, gk + ge) == '$gk/${gk + ge}' ? '' : ' = ${kesir(gk, gk + ge)}'}.',
    );
  }),
  SoruSablonu('m-kosullu-2', _mat, 'Sayma ve Olasılık', 'Bayes Teoremi', _z, ['s10-mat-17'], (r) {
    final v = sec(r, [
      [60, 40, 5, 10],
      [50, 50, 4, 6],
      [70, 30, 10, 20],
      [80, 20, 5, 10],
      [40, 60, 10, 5],
      [25, 75, 20, 4],
    ]);
    final a = v[0] * v[2], b = v[1] * v[3];
    return SoruTaslagi(
      'Bir fabrikada ürünlerin %${v[0]}\'ini A makinesi, %${v[1]}\'ini B makinesi üretmektedir. A\'nın ürettiklerinin %${v[2]}\'i, B\'nin ürettiklerinin %${v[3]}\'i kusurludur. Rastgele seçilen bir ürünün kusurlu olduğu bilindiğine göre A makinesinde üretilmiş olma olasılığı kaçtır?',
      kesir(a, a + b),
      [kesir(b, a + b), kesir(v[0], 100), kesir(v[2], 100), kesir(a, 10000), kesir(v[2], v[2] + v[3]), kesir(a + b, 10000), kesir(1, 2) == kesir(a, a + b) ? '2/3' : '1/2'],
      'Kusurlu ve A\'dan: ${v[0]} · ${v[2]} = $a (on binde). Kusurlu ve B\'den: ${v[1]} · ${v[3]} = $b. Bayes: $a / ($a + $b) = ${kesir(a, a + b)}.',
    );
  }),
  // ─── 11. sınıf ────────────────────────────────────────────────────────
  SoruSablonu('m-regresyon-1', _mat, 'Veri ve İstatistik', 'İki Nicel Değişkenli Veriler', _o, ['s11-mat-01'], (r) {
    final a = rs(r, 2, 6), b = rs(r, 10, 40), x = rs(r, 4, 12);
    return SoruTaslagi(
      'Haftalık çalışma süresi (x, saat) ile sınav puanı (y) arasındaki ilişki için en uygun doğru y = ${a}x + $b olarak bulunmuştur. Bu modele göre haftada $x saat çalışan bir öğrencinin tahmini puanı kaçtır?',
      '${a * x + b}',
      sayiCeldirici(a * x + b, [a * x, a + x + b, (a + b) * x, a * x + b + a]),
      'x yerine $x yazılır: y = $a · $x + $b = ${a * x + b}. Doğrunun eğimi ($a), her ek saatin puanı ortalama $a artırdığını gösterir.',
    );
  }),
  SoruSablonu('m-regresyon-2', _mat, 'Veri ve İstatistik', 'İki Nicel Değişkenli Veriler', _k, ['s11-mat-01'], (r) {
    final v = sec(r, [
      ['Hava sıcaklığı arttıkça satılan dondurma sayısı da artıyor', 'Pozitif yönlü ilişki'],
      ['Bir aracın hızı arttıkça aynı yolu tamamlama süresi azalıyor', 'Negatif yönlü ilişki'],
      ['Çalışma süresi arttıkça yapılan hata sayısı azalıyor', 'Negatif yönlü ilişki'],
      ['Boy uzunluğu arttıkça ayakkabı numarası da artıyor', 'Pozitif yönlü ilişki'],
      ['Öğrencilerin ayakkabı numarası ile matematik notu arasında düzenli bir değişim görülmüyor', 'İlişki yok'],
    ]);
    return SoruTaslagi(
      '“${v[0]}.” Bu durumda iki nicel değişken arasındaki ilişki, saçılım grafiğinde aşağıdakilerden hangisi olarak yorumlanır?',
      v[1],
      ['Pozitif yönlü ilişki', 'Negatif yönlü ilişki', 'İlişki yok', 'Nedensellik kesindir', 'Kategorik ilişki', 'Sabit ilişki'],
      'Biri artarken diğeri de artıyorsa ilişki pozitif, biri artarken diğeri azalıyorsa negatif yönlüdür; düzenli bir değişim yoksa ilişki yoktur. İlişkinin varlığı tek başına nedensellik göstermez.',
    );
  }),
  SoruSablonu('g-dortgen-1', _geo, 'Dörtgenler', 'Yamuk', _k, ['s11-mat-02'], (r) {
    final a = rs(r, 6, 14), c = rs(r, 2, 5), h = 2 * rs(r, 2, 6);
    return SoruTaslagi(
      'Taban uzunlukları $a cm ve $c cm, yüksekliği $h cm olan yamuğun alanı kaç cm²\'dir?',
      '${(a + c) * h ~/ 2}',
      sayiCeldirici((a + c) * h ~/ 2, [(a + c) * h, a * c * h ~/ 2, a * h, (a + c) * h ~/ 4]),
      'Yamuğun alanı = (alt taban + üst taban) · yükseklik / 2 = ($a + $c) · $h / 2 = ${(a + c) * h ~/ 2} cm².',
    );
  }),
  SoruSablonu('g-dortgen-2', _geo, 'Dörtgenler', 'Eşkenar Dörtgen', _o, ['s11-mat-02'], (r) {
    final u = sec(r, _uclular.take(6).toList());
    return SoruTaslagi(
      'Köşegen uzunlukları ${2 * u[0]} cm ve ${2 * u[1]} cm olan eşkenar dörtgenin çevresi kaç cm\'dir?',
      '${4 * u[2]}',
      sayiCeldirici(4 * u[2], [2 * u[2], 2 * (u[0] + u[1]), 4 * (u[0] + u[1]), u[2]]),
      'Köşegenler birbirini dik ortalar; yarım köşegenler ${u[0]} ve ${u[1]} cm\'dir. Kenar: √(${u[0]}² + ${u[1]}²) = ${u[2]} cm. Çevre 4 · ${u[2]} = ${4 * u[2]} cm.',
    );
  }),
  SoruSablonu('g-dortgen-3', _geo, 'Dörtgenler', 'Dikdörtgen', _k, ['s11-mat-02'], (r) {
    final u = sec(r, _uclular);
    return SoruTaslagi(
      'Kenar uzunlukları ${u[0]} cm ve ${u[1]} cm olan dikdörtgenin köşegen uzunluğu kaç cm\'dir?',
      '${u[2]}',
      sayiCeldirici(u[2], [u[0] + u[1], u[0] * u[1], u[2] + 1, 2 * u[2]]),
      'Köşegen, kenarlarla dik üçgen oluşturur: √(${u[0]}² + ${u[1]}²) = √${u[2] * u[2]} = ${u[2]} cm.',
    );
  }),
  SoruSablonu('g-dortgen-4', _geo, 'Dörtgenler', 'Paralelkenar', _k, ['s11-mat-02'], (r) {
    final a = 5 * rs(r, 8, 22);
    return SoruTaslagi(
      'Bir paralelkenarın bir iç açısının ölçüsü $a° olduğuna göre bu açıya komşu olan iç açının ölçüsü kaç derecedir?',
      '${180 - a}',
      sayiCeldirici(180 - a, [a, 360 - a, 90, (180 - a) ~/ 2 + 5]),
      'Paralelkenarda ardışık (komşu) açılar bütünlerdir: 180° − $a° = ${180 - a}°. Karşılıklı açılar ise eşittir.',
    );
  }),
  SoruSablonu('g-cokgen-1', _geo, 'Çokgenler', 'İç Açılar Toplamı', _k, ['s11-mat-03'], (r) {
    final n = rs(r, 5, 12);
    return SoruTaslagi(
      '$n kenarlı bir dışbükey çokgenin iç açılarının ölçüleri toplamı kaç derecedir?',
      '${(n - 2) * 180}',
      sayiCeldirici((n - 2) * 180, [n * 180, (n - 1) * 180, 360, (n - 3) * 180]),
      'İç açılar toplamı (n − 2) · 180° = ${n - 2} · 180° = ${(n - 2) * 180}°.',
    );
  }),
  SoruSablonu('g-cokgen-2', _geo, 'Çokgenler', 'Köşegen Sayısı', _o, ['s11-mat-03'], (r) {
    final n = rs(r, 5, 12);
    final v = n * (n - 3) ~/ 2;
    return SoruTaslagi(
      '$n kenarlı bir dışbükey çokgenin köşegen sayısı kaçtır?',
      '$v',
      sayiCeldirici(v, [n * (n - 3), n * (n - 1) ~/ 2, n - 3, n * (n - 2) ~/ 2]),
      'Köşegen sayısı n(n − 3) / 2 = $n · ${n - 3} / 2 = $v.',
    );
  }),
  SoruSablonu('g-cokgen-3', _geo, 'Çokgenler', 'Düzgün Çokgenler', _o, ['s11-mat-03'], (r) {
    final n = sec(r, [5, 6, 8, 9, 10, 12, 15, 18, 20]);
    final ic = 180 - 360 ~/ n;
    return SoruTaslagi(
      'Bir iç açısının ölçüsü $ic° olan düzgün çokgen kaç kenarlıdır?',
      '$n',
      sayiCeldirici(n, [n + 1, n - 1, n + 2, 360 ~/ (ic == 360 ? 1 : (180 - ic)) + 3]),
      'Bir dış açı 180° − $ic° = ${360 ~/ n}°. Dış açılar toplamı 360° olduğundan kenar sayısı 360 / ${360 ~/ n} = $n.',
    );
  }),
  SoruSablonu('m-trig-deger-1', _mat, 'Trigonometri', 'Birim Çember', _o, ['s11-mat-04'], (r) {
    final v = sec(r, [
      ['sin 150°', '1/2', 'sin 150° = sin(180° − 30°) = sin 30°'],
      ['cos 120°', '−1/2', 'cos 120° = −cos 60° (II. bölgede kosinüs negatiftir)'],
      ['tan 135°', '−1', 'tan 135° = −tan 45° (II. bölgede tanjant negatiftir)'],
      ['sin 210°', '−1/2', 'sin 210° = −sin 30° (III. bölgede sinüs negatiftir)'],
      ['cos 300°', '1/2', 'cos 300° = cos 60° (IV. bölgede kosinüs pozitiftir)'],
      ['sin 330°', '−1/2', 'sin 330° = −sin 30° (IV. bölgede sinüs negatiftir)'],
      ['tan 225°', '1', 'tan 225° = tan 45° (III. bölgede tanjant pozitiftir)'],
      ['cos 180°', '−1', 'Birim çemberde 180°\'lik açının bitim noktası (−1, 0) olduğundan'],
      ['sin 270°', '−1', 'Birim çemberde 270°\'lik açının bitim noktası (0, −1) olduğundan'],
      ['cos 240°', '−1/2', 'cos 240° = −cos 60° (III. bölgede kosinüs negatiftir)'],
      ['sin 120°', '√3/2', 'sin 120° = sin 60° (II. bölgede sinüs pozitiftir)'],
      ['cos 150°', '−√3/2', 'cos 150° = −cos 30° (II. bölgede kosinüs negatiftir)'],
      ['cos 315°', '√2/2', 'cos 315° = cos 45° (IV. bölgede kosinüs pozitiftir)'],
      ['sin 225°', '−√2/2', 'sin 225° = −sin 45° (III. bölgede sinüs negatiftir)'],
    ]);
    return SoruTaslagi(
      '${v[0]} ifadesinin değeri kaçtır?',
      v[1],
      (['1/2', '−1/2', '√3/2', '−√3/2', '1', '−1', '0', '√2/2', '−√2/2']..shuffle(r)),
      '${v[2]} olur; sonuç ${v[1]}.',
    );
  }),
  SoruSablonu('m-trig-periyot-1', _mat, 'Trigonometri', 'Trigonometrik Fonksiyonlar', _o, ['s11-mat-04'], (r) {
    final k = sec(r, [2, 3, 4, 5, 6]);
    final f = sec(r, ['sin', 'cos']);
    return SoruTaslagi(
      'f(x) = $f(${k}x) fonksiyonunun esas periyodu aşağıdakilerden hangisidir?',
      '2π/$k'.replaceAll('2π/2', 'π').replaceAll('2π/4', 'π/2').replaceAll('2π/6', 'π/3'),
      ['2π', 'π', '$kπ', '${2 * k}π', 'π/$k', 'π/${2 * k}', '2π/${k + 1}'],
      'sin(ax) ve cos(ax) fonksiyonlarının esas periyodu 2π / |a| olur: 2π / $k.',
    );
  }),
  SoruSablonu('m-trig-denk-1', _mat, 'Trigonometri', 'Trigonometrik Denklemler', _z, ['s11-mat-05'], (r) {
    final v = sec(r, [
      ['sin x = 1/2', 30, 150],
      ['cos x = 1/2', 60, 300],
      ['sin x = √3/2', 60, 120],
      ['cos x = −1/2', 120, 240],
      ['tan x = 1', 45, 225],
      ['sin x = −1/2', 210, 330],
      ['cos x = √3/2', 30, 330],
      ['tan x = −1', 135, 315],
      ['cos x = 0', 90, 270],
    ]);
    final a = v[1] as int, b = v[2] as int;
    return SoruTaslagi(
      '${v[0]} denkleminin [0°, 360°) aralığındaki köklerinin toplamı kaç derecedir?',
      '${a + b}',
      sayiCeldirici(a + b, [a, b, 2 * a, 360, 180, 540, 270]),
      '${v[0]} denkleminin bu aralıktaki kökleri $a° ve $b°\'dir. Toplam ${a + b}°.',
    );
  }),
  SoruSablonu('m-ustel-1', _mat, 'Logaritma', 'Üstel Fonksiyonlar', _k, ['s11-mat-06'], (r) {
    final a = sec(r, [2, 3]), c = rs(r, 2, 5), x = rs(r, 2, 4);
    return SoruTaslagi(
      'f(x) = $c · $a^x üstel fonksiyonu için f($x) kaçtır?',
      '${c * _us(a, x)}',
      sayiCeldirici(c * _us(a, x), [_us(c * a, x), c * a * x, _us(a, x), c + _us(a, x)]),
      'f($x) = $c · $a^$x = $c · ${_us(a, x)} = ${c * _us(a, x)}.',
    );
  }),
  SoruSablonu('m-ustel-2', _mat, 'Logaritma', 'Üstel Fonksiyonlar', _o, ['s11-mat-06'], (r) {
    final n0 = 100 * rs(r, 1, 8), t = rs(r, 2, 5);
    return SoruTaslagi(
      'Bir bakteri kültüründeki bakteri sayısı her saat 2 katına çıkmaktadır. Başlangıçta $n0 bakteri olduğuna göre $t saat sonra kaç bakteri olur?',
      '${n0 * _us(2, t)}',
      sayiCeldirici(n0 * _us(2, t), [n0 * 2 * t, n0 * t, n0 * _us(2, t - 1), n0 * _us(2, t + 1)]),
      'Üstel büyüme: N(t) = $n0 · 2^t. N($t) = $n0 · ${_us(2, t)} = ${n0 * _us(2, t)}.',
    );
  }),
  SoruSablonu('m-log-1', _mat, 'Logaritma', 'Logaritma Değeri', _k, ['s11-mat-07'], (r) {
    final a = sec(r, [2, 3, 5]), k = rs(r, 2, a == 2 ? 7 : 4);
    return SoruTaslagi(
      'log_$a(${_us(a, k)}) ifadesinin değeri kaçtır?',
      '$k',
      sayiCeldirici(k, [_us(a, k) ~/ a, k + 1, k - 1, a * k, a]),
      '$a^$k = ${_us(a, k)} olduğundan log_$a(${_us(a, k)}) = $k.',
    );
  }),
  SoruSablonu('m-log-2', _mat, 'Logaritma', 'Logaritma Özellikleri', _o, ['s11-mat-07'], (r) {
    final a = sec(r, [2, 3]), m = rs(r, 1, 3), n = rs(r, 1, 3);
    final p = sec(r, [5, 7, 11]);
    final x = _us(a, m) * p, yPay = _us(a, n);
    return SoruTaslagi(
      'log_$a($x) + log_$a($yPay/$p) işleminin sonucu kaçtır?',
      '${m + n}',
      sayiCeldirici(m + n, [m * n, m + n + 1, m - n, _us(a, m + n)], negatif: true),
      'Toplama, çarpımın logaritmasıdır: log_$a($x · $yPay/$p) = log_$a(${_us(a, m + n)}) = ${m + n}.',
    );
  }),
  SoruSablonu('m-logdenk-1', _mat, 'Logaritma', 'Logaritmik Denklemler', _o, ['s11-mat-08'], (r) {
    final a = sec(r, [2, 3, 5]), k = rs(r, 2, 3), c = rs(r, -6, 9);
    final x = _us(a, k) + c;
    final cm = c < 0 ? '+ ${-c}' : '− $c';
    return SoruTaslagi(
      'log_$a(x $cm) = $k denklemini sağlayan x değeri kaçtır?',
      '$x',
      sayiCeldirici(x, [_us(a, k) - c, a * k + c, _us(a, k), _us(k, a) + c], negatif: true),
      'log_a(b) = c ⟺ a^c = b. x $cm = $a^$k = ${_us(a, k)} ⟹ x = $x.',
    );
  }),
  SoruSablonu('m-logdenk-2', _mat, 'Logaritma', 'Üstel Denklemler', _o, ['s11-mat-08'], (r) {
    final a = sec(r, [2, 3, 5]), k = rs(r, 2, 4), p = rs(r, 2, 3), q = rs(r, -5, 5);
    // a^(p·x + q) = a^k·… : x tam sayı olsun
    final x = rs(r, -2, 4);
    final us = p * x + q;
    if (us < 0 || us > 6) {
      return SoruTaslagi('3^(2x − 1) = 27 olduğuna göre x kaçtır?', '2', ['1', '3', '4', '0', '5'], '27 = 3³ ⟹ 2x − 1 = 3 ⟹ x = 2.');
    }
    return SoruTaslagi(
      '$a^(${p}x ${q < 0 ? '− ${-q}' : '+ $q'}) = ${_us(a, us)} olduğuna göre x kaçtır?',
      '$x',
      sayiCeldirici(x, [us, x + 1, x - 1, us - q, k], negatif: true),
      '${_us(a, us)} = $a^$us olduğundan ${p}x ${q < 0 ? '− ${-q}' : '+ $q'} = $us ⟹ x = $x.',
    );
  }),
  SoruSablonu('m-bileske-1', _mat, 'Fonksiyonlar', 'Bileşke Fonksiyon', _o, ['s11-mat-09'], (r) {
    final a = rs(r, 2, 4), b = rs(r, -5, 6), c = rs(r, 2, 4), d = rs(r, -4, 5), k = rs(r, -2, 4);
    final g = c * k + d, v = a * g + b;
    String ek(int n) => n < 0 ? '− ${-n}' : '+ $n';
    return SoruTaslagi(
      'f(x) = ${a}x ${ek(b)} ve g(x) = ${c}x ${ek(d)} olduğuna göre (f ∘ g)($k) kaçtır?',
      '$v',
      sayiCeldirici(v, [c * (a * k + b) + d, (a * k + b) * (c * k + d), (a * k + b) + (c * k + d), g], negatif: true),
      '(f ∘ g)($k) = f(g($k)). g($k) = $c · ($k) ${ek(d)} = $g. f($g) = $a · ($g) ${ek(b)} = $v.',
    );
  }),
  SoruSablonu('m-bileske-2', _mat, 'Fonksiyonlar', 'Fonksiyonlarda Dört İşlem', _k, ['s11-mat-09'], (r) {
    final a = rs(r, 1, 4), b = rs(r, -5, 6), c = rs(r, 1, 4), k = rs(r, -3, 4);
    final fk = a * k + b, gk = k * k + c;
    final carpim = r.nextBool();
    String ek(int n) => n < 0 ? '− ${-n}' : '+ $n';
    return SoruTaslagi(
      'f(x) = ${a == 1 ? '' : a}x ${ek(b)} ve g(x) = x² + $c olduğuna göre (f ${carpim ? '·' : '+'} g)($k) kaçtır?',
      '${carpim ? fk * gk : fk + gk}',
      sayiCeldirici(carpim ? fk * gk : fk + gk, [carpim ? fk + gk : fk * gk, fk - gk, a * gk + b, fk], negatif: true),
      'f($k) = $fk ve g($k) = $gk. (f ${carpim ? '·' : '+'} g)($k) = f($k) ${carpim ? '·' : '+'} g($k) = ${carpim ? fk * gk : fk + gk}.',
    );
  }),
];
