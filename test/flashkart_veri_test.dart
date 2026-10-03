import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/core/constants/flashkart_data.dart';

void main() {
  test('Hazır flash kartlar benzersiz, dolu ve bilinen destelere ait', () {
    expect(flashKartlar.length, greaterThanOrEqualTo(800));
    final idler = <String>{};
    final onYuzler = <String>{};
    for (final k in flashKartlar) {
      expect(idler.add(k.id), isTrue, reason: 'Tekrarlanan kart kimliği: ${k.id}');
      expect(onYuzler.add('${k.ders}|${k.on.trim().toLowerCase()}'), isTrue, reason: 'Aynı kart iki kez var: ${k.id}');
      expect(k.on.trim(), isNotEmpty, reason: k.id);
      expect(k.arka.trim(), isNotEmpty, reason: k.id);
      expect(dersEtiketleri.containsKey(k.ders), isTrue, reason: '${k.id} destesinin etiketi yok');
      expect(dersRenkleri.containsKey(k.ders), isTrue, reason: '${k.id} destesinin rengi yok');
    }
    final desteler = <String, int>{};
    for (final k in flashKartlar) {
      desteler[k.ders] = (desteler[k.ders] ?? 0) + 1;
    }
    for (final e in desteler.entries) {
      expect(e.value, greaterThanOrEqualTo(40), reason: '${e.key} destesinde az kart var');
    }
  });
}
