import 'package:flutter_test/flutter_test.dart';
import 'package:yks_kocu/core/constants/app_constants.dart';
import 'package:yks_kocu/presentation/providers/bahce_provider.dart';
import 'package:yks_kocu/presentation/providers/odak_provider.dart';

String _gun(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

void main() {
  group('Saksı', () {
    test('büyüme puanı aşamaya doğru çevrilir', () {
      expect(const Saksi(bitkiId: 'seed_lale', buyume: 0).asama, 0);
      expect(const Saksi(bitkiId: 'seed_lale', buyume: 2).asama, 1);
      expect(const Saksi(bitkiId: 'seed_lale', buyume: 6).asama, 2);
      expect(const Saksi(bitkiId: 'seed_lale', buyume: 9).olgun, isTrue);
    });

    test('iki gün sulanmayan bitki solar, kaktüs daha dayanıklıdır', () {
      final ikiGunOnce = _gun(DateTime.now().subtract(const Duration(days: 2)));
      expect(Saksi(bitkiId: 'seed_lale', sonSulama: ikiGunOnce).solgun, isTrue);
      expect(Saksi(bitkiId: 'seed_kaktus', sonSulama: ikiGunOnce).solgun, isFalse);
      expect(Saksi(bitkiId: 'seed_lale', sonSulama: _gun(DateTime.now())).solgun, isFalse);
      expect(const Saksi().solgun, isFalse);
    });

    test('bahçe durumu JSON gidiş-dönüşünde korunur', () {
      const durum = BahceState(
        saksilar: [Saksi(bitkiId: 'seed_hus', buyume: 3, ekimTarihi: '2026-09-01'), Saksi()],
        damla: 7,
        envanter: {'seed_lale': 2},
        dekorlar: ['deco_bank'],
        iklim: 'akdeniz',
        ormanlar: {'akdeniz': ['seed_kiraz'], 'tayga': ['seed_cam']},
        hediyeKutusuAcildi: true,
      );
      final geri = BahceState.fromJson(durum.toJson());
      expect(geri.saksilar.first.bitkiId, 'seed_hus');
      expect(geri.saksilar.first.buyume, 3);
      expect(geri.saksilar[1].bos, isTrue);
      expect(geri.damla, 7);
      expect(geri.envanter, {'seed_lale': 2});
      expect(geri.dekorlar, ['deco_bank']);
      expect(geri.iklim, 'akdeniz');
      expect(geri.aktifOrman, ['seed_kiraz']);
      expect(geri.orman, ['seed_kiraz', 'seed_cam']);
      expect(geri.hediyeKutusuAcildi, isTrue);
    });
  });

  group('Odak sayacı', () {
    test('yıldız önizlemesi sunucu formülüyle aynı: 25 dk = 10, tavan 40', () {
      expect(const OdakState(gecenSaniye: 24 * 60).tahminiYildiz, 0);
      expect(const OdakState(gecenSaniye: 25 * 60).tahminiYildiz, 10);
      expect(const OdakState(sureDk: 90, gecenSaniye: 75 * 60).tahminiYildiz, 30);
      expect(const OdakState(sureDk: 0, gecenSaniye: 150 * 60).tahminiYildiz, 40);
    });

    test('geri sayım ve serbest mod gösterimi', () {
      const geri = OdakState(sureDk: 25, gecenSaniye: 60);
      expect(geri.gosterilenSaniye, 24 * 60);
      const serbest = OdakState(sureDk: 0, gecenSaniye: 60);
      expect(serbest.gosterilenSaniye, 60);
    });
  });

  test('YKS tarihi geçmişteyse bir sonraki yıla kayar', () {
    final sonra = sonrakiYksTarihi(DateTime(yksDate.year, 9, 27));
    expect(sonra.year, yksDate.year + 1);
    expect(sonrakiYksTarihi(DateTime(yksDate.year, 1, 1)), yksDate);
  });
}
