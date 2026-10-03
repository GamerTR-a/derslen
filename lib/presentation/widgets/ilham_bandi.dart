import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

const List<(String, String)> _sozler = [
  ('Bin kilometrelik bir yolculuk tek bir adımla başlar.', 'Lao Tzu'),
  ('Hayatta en hakiki mürşit ilimdir.', 'Mustafa Kemal Atatürk'),
  ('Başarı, her gün tekrarlanan küçük çabaların toplamıdır.', 'Robert Collier'),
  ('Eğitim, dünyayı değiştirmek için kullanabileceğin en güçlü silahtır.', 'Nelson Mandela'),
  ('Damlaya damlaya göl olur.', 'Türk atasözü'),
  ('Deha yüzde bir ilham, yüzde doksan dokuz terdir.', 'Thomas Edison'),
  ('Öğrenmek, zihni asla yormaz.', 'Leonardo da Vinci'),
  ('İlim ilim bilmektir, ilim kendin bilmektir.', 'Yunus Emre'),
  ('Ne kadar yavaş gittiğin önemli değil, yeter ki durma.', 'Konfüçyüs'),
  ('Sabır acıdır, meyvesi tatlıdır.', 'Jean-Jacques Rousseau'),
  ('Gelecek, ona bugünden hazırlananlara aittir.', 'Malcolm X'),
  ('Emek olmadan yemek olmaz.', 'Türk atasözü'),
  ('Başlamak için mükemmel olmak zorunda değilsin; mükemmel olmak için başlamak zorundasın.', 'Zig Ziglar'),
  ('Zorluk ne kadar büyükse, zafer o kadar görkemlidir.', 'Epiktetos'),
];

/// Birkaç saatte bir değişen, daktilo efektiyle yazılan ilham sözü.
class IlhamBandi extends StatefulWidget {
  const IlhamBandi({super.key});

  @override
  State<IlhamBandi> createState() => _IlhamBandiState();
}

class _IlhamBandiState extends State<IlhamBandi> {
  static const _degisimSaati = 3;
  late int _index = (DateTime.now().millisecondsSinceEpoch ~/ Duration.millisecondsPerHour ~/ _degisimSaati) % _sozler.length;
  int _gorunen = 0;
  Timer? _timer;
  Timer? _imlec;
  bool _imlecAcik = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _gorunen == 0) _yaz();
    _imlec ??= Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _imlecAcik = !_imlecAcik);
    });
  }

  void _yaz() {
    _timer?.cancel();
    final metin = _sozler[_index].$1;
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _gorunen = metin.length);
      return;
    }
    _gorunen = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 34), (t) {
      if (!mounted) return t.cancel();
      setState(() => _gorunen++);
      if (_gorunen >= metin.length) t.cancel();
    });
  }

  void _sonraki() {
    setState(() => _index = (_index + 1) % _sozler.length);
    _yaz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imlec?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (soz, yazar) = _sozler[_index];
    final bitti = _gorunen >= soz.length;
    final stil = context.baslik(18, color: c.onFeature).copyWith(height: 1.4);
    final imlec = TextSpan(text: '|', style: stil.copyWith(color: (c.gece ? c.accent : const Color(0xFFF2B544)).withValues(alpha: _imlecAcik ? 1 : 0)));

    return Semantics(
      label: '$soz — $yazar',
      hint: 'Yeni söz için dokun',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _sonraki,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: c.feature,
            borderRadius: BorderRadius.circular(22),
            border: c.gece ? Border.all(color: c.border) : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.gece)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text('“', style: context.baslik(48, color: c.accent).copyWith(height: 0.9)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tam metin görünmez olarak yerleşir ki yazarken yükseklik zıplamasın.
                    Stack(
                      children: [
                        Opacity(opacity: 0, child: Text('$soz|', style: stil)),
                        Text.rich(TextSpan(children: [
                          TextSpan(text: soz.substring(0, _gorunen.clamp(0, soz.length)), style: stil),
                          imlec,
                        ])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: bitti ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        c.gece ? yazar : '$yazar · dokun, yenisi gelsin',
                        style: TextStyle(color: c.onFeature.withValues(alpha: 0.78), fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
