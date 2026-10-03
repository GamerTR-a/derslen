import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/services/ambiyans_service.dart';

void main() {
  test('Üretilen her ambiyans sesi geçerli, duyulabilir ve kırpılmamış bir WAV döngüsüdür', () {
    for (final ses in AmbiyansSes.values.where((s) => s.uretilen)) {
      final sw = Stopwatch()..start();
      final wav = ambiyansWavUret(ses.index);
      sw.stop();
      final b = ByteData.sublistView(wav);
      final kanal = b.getUint16(22, Endian.little);
      final veri = b.getUint32(40, Endian.little);
      expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF', reason: ses.name);
      expect(veri, AmbiyansService.ornekHizi * AmbiyansService.donguSaniye * 2 * kanal, reason: ses.name);
      expect(kanal, ses == AmbiyansSes.alfa ? 2 : 1, reason: ses.name);

      var kare = 0.0;
      var tepe = 0;
      final n = veri ~/ 2;
      for (var i = 0; i < n; i++) {
        final v = b.getInt16(44 + i * 2, Endian.little);
        tepe = max(tepe, v.abs());
        kare += v * v;
      }
      final rms = sqrt(kare / n) / 32767;
      expect(rms, greaterThan(0.03), reason: '${ses.name} çok sessiz (rms $rms)');
      expect(tepe, lessThan(32767), reason: '${ses.name} kırpılıyor');
      // ignore: avoid_print
      print('${ses.name.padRight(10)} rms=${rms.toStringAsFixed(3)} tepe=${(tepe / 32767).toStringAsFixed(2)} ${sw.elapsedMilliseconds} ms');
    }
  });
}
