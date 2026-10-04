/// Programı elle kurma bileşenleri: blok ekleme/düzenleme sayfası ve
/// "ders ders, konu konu" seçim ekranı.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/ders_programi.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sinif_mufredati.dart';
import '../../../core/utils/tarih.dart';
import '../../../data/models/konu.dart';
import '../../../data/models/plan_blok.dart';
import '../../providers/konu_provider.dart';
import '../../providers/profil_provider.dart';
import '../../widgets/grafikler.dart';
import '../../widgets/ui_kit.dart';

/// Blok sayfasının sonucu.
class BlokTaslagi {
  final String ders;
  final String konu;
  final int sureDk;
  final PlanBlokTip tip;
  final int baslangicDk;

  const BlokTaslagi({required this.ders, required this.konu, required this.sureDk, required this.tip, required this.baslangicDk});
}

const List<int> blokSureleri = [15, 20, 25, 30, 40, 50, 60, 90, 120];

/// Blok ekleme / düzenleme sayfasını açar. [mevcut] verilirse düzenleme
/// modundadır. Vazgeçilirse null döner.
Future<BlokTaslagi?> blokSayfasiGoster(
  BuildContext context, {
  required String gunAdi,
  required int varsayilanBaslangicDk,
  PlanBlok? mevcut,
}) {
  return showModalBottomSheet<BlokTaslagi>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.colors.surface,
    builder: (_) => _BlokSayfasi(gunAdi: gunAdi, varsayilanBaslangicDk: varsayilanBaslangicDk, mevcut: mevcut),
  );
}

class _BlokSayfasi extends ConsumerStatefulWidget {
  final String gunAdi;
  final int varsayilanBaslangicDk;
  final PlanBlok? mevcut;

  const _BlokSayfasi({required this.gunAdi, required this.varsayilanBaslangicDk, this.mevcut});

  @override
  ConsumerState<_BlokSayfasi> createState() => _BlokSayfasiState();
}

class _BlokSayfasiState extends ConsumerState<_BlokSayfasi> {
  static const _genel = '__genel__';

  late PlanBlokTip _tip = widget.mevcut?.tip == PlanBlokTip.egzersiz ? PlanBlokTip.calisma : (widget.mevcut?.tip ?? PlanBlokTip.calisma);
  late String? _ders = (widget.mevcut?.ders ?? '').isEmpty ? null : widget.mevcut!.ders;
  late String _konu = widget.mevcut?.konu ?? _genel;
  late int _sure = widget.mevcut?.sure ?? 30;
  late int _baslangic = (widget.mevcut == null ? null : blokBaslangicDk(widget.mevcut!)) ?? widget.varsayilanBaslangicDk;

  bool get _mola => _tip == PlanBlokTip.mola;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profil = ref.watch(profilProvider).value;
    final tumKonular = ref.watch(konuProvider);
    final konular = alanKonulari(profil?.hedefBolum ?? 'sayisal', tumKonular);
    final dersler = [...alanDersleri(profil?.hedefBolum ?? 'sayisal', tumKonular), 'Deneme'];
    if (_ders != null && !dersler.contains(_ders)) dersler.add(_ders!);
    final dersKonulari = [for (final k in konular) if (k.ders == _ders) k];
    final konuSecenekleri = <(String, String)>[
      (_genel, _ders == 'Deneme' ? 'Deneme sınavı' : 'Genel tekrar (konu belirtme)'),
      for (final k in dersKonulari) (k.baslik, _konuEtiketi(k)),
      // Düzenlenen bloğun konusu artık müfredatta olmayabilir; yine de listede dursun.
      if (_konu != _genel && !dersKonulari.any((k) => k.baslik == _konu)) (_konu, _konu),
    ];
    final sureler = [...blokSureleri, if (!blokSureleri.contains(_sure)) _sure]..sort();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.mevcut == null ? '${widget.gunAdi} · blok ekle' : '${widget.gunAdi} · bloğu düzenle', style: context.baslik(19)),
                const SizedBox(height: 14),
                _etiket('Ne yapacaksın?'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (tip, ad) in const [
                      (PlanBlokTip.calisma, 'Konu çalışma'),
                      (PlanBlokTip.soru, 'Soru çözme'),
                      (PlanBlokTip.tekrar, 'Tekrar'),
                      (PlanBlokTip.mola, 'Mola'),
                    ])
                      HapSecim(etiket: ad, secili: _tip == tip, onTap: () => setState(() => _tip = tip)),
                  ],
                ),
                if (!_mola) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _ders,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    decoration: _alan('Ders'),
                    hint: const Text('Ders seç'),
                    items: [for (final d in dersler) DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() {
                      _ders = v;
                      _konu = _genel;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('konu-$_ders-${konuSecenekleri.length}'),
                    initialValue: konuSecenekleri.any((k) => k.$1 == _konu) ? _konu : _genel,
                    isExpanded: true,
                    dropdownColor: c.surface,
                    decoration: _alan('Konu'),
                    items: [
                      for (final (deger, ad) in konuSecenekleri)
                        DropdownMenuItem(value: deger, child: Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: _ders == null ? null : (v) => setState(() => _konu = v ?? _genel),
                  ),
                ],
                const SizedBox(height: 16),
                _etiket('Süre'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _mola ? const [5, 10, 15, 20, 30] : sureler)
                      HapSecim(etiket: sureMetni(s), secili: _sure == s, onTap: () => setState(() => _sure = s)),
                  ],
                ),
                const SizedBox(height: 16),
                _etiket('Başlangıç saati'),
                OutlinedButton.icon(
                  onPressed: () async {
                    final secim = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: _baslangic ~/ 60, minute: _baslangic % 60),
                      helpText: 'Başlangıç saati',
                    );
                    if (secim != null) setState(() => _baslangic = secim.hour * 60 + secim.minute);
                  },
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text('${saatMetni(_baslangic)} – ${saatMetni(_baslangic + _gecerliSure)}'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: !_mola && _ders == null ? null : _kaydet,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(widget.mevcut == null ? 'Programa ekle' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _gecerliSure => _mola && _sure > 30 ? 10 : _sure;

  String _konuEtiketi(Konu k) => '${k.tamamlandi ? '✓ ' : ''}${k.baslik}${k.zayif ? '  · zayıf' : ''}';

  void _kaydet() {
    final ders = _mola ? '' : _ders!;
    final konu = _mola
        ? (_gecerliSure >= 10 ? 'Uzun mola' : 'Kısa mola')
        : _konu == _genel
            ? (ders == 'Deneme' ? 'Deneme sınavı' : '$ders genel tekrar')
            : _konu;
    Navigator.pop(context, BlokTaslagi(ders: ders, konu: konu, sureDk: _gecerliSure, tip: _tip, baslangicDk: _baslangic));
  }

  Widget _etiket(String metin) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(metin, style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
      );

  InputDecoration _alan(String etiket) {
    final c = context.colors;
    return InputDecoration(
      labelText: etiket,
      filled: true,
      fillColor: c.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c.border)),
    );
  }
}

/// Programa girecek konuların ders ders seçildiği tam ekran sayfa. Seçilen
/// konu kimliklerini döndürür (tümü seçiliyse boş liste: "tüm müfredat").
class KonuSecimSayfasi extends ConsumerStatefulWidget {
  final List<String> seciliIdler;

  const KonuSecimSayfasi({super.key, required this.seciliIdler});

  @override
  ConsumerState<KonuSecimSayfasi> createState() => _KonuSecimSayfasiState();
}

class _KonuSecimSayfasiState extends ConsumerState<KonuSecimSayfasi> {
  Set<String>? _secili;
  final Set<String> _acik = {};

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final profil = ref.watch(profilProvider).value;
    final konular = alanKonulari(profil?.hedefBolum ?? 'sayisal', ref.watch(konuProvider));
    final tumIdler = {for (final k in konular) k.id};
    // İlk açılış: kayıtlı seçim yoksa hepsi seçili gelir.
    final secili = _secili ??= widget.seciliIdler.isEmpty ? {...tumIdler} : widget.seciliIdler.toSet().intersection(tumIdler);

    final dersler = <String, List<Konu>>{};
    for (final k in konular) {
      dersler.putIfAbsent(k.ders, () => []).add(k);
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text('Konularını seç', style: context.baslik(20)),
        actions: [
          TextButton(
            onPressed: () => setState(() => secili.length == tumIdler.length ? secili.clear() : secili.addAll(tumIdler)),
            child: Text(secili.length == tumIdler.length ? 'Temizle' : 'Tümünü seç'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: secili.isEmpty
                ? null
                : () => Navigator.pop(context, secili.length == tumIdler.length ? <String>[] : [for (final k in konular) if (secili.contains(k.id)) k.id]),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(secili.isEmpty ? 'En az bir konu seç' : '${secili.length} konuyla programı hazırla'),
          ),
        ),
      ),
      body: konular.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: BosGrafikMesaji(metin: 'Müfredatında konu yok. Önce Müfredatım ekranından ders ve konu ekle.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Text(
                  'Bu hafta çalışmak istediğin dersleri ve konuları işaretle. Programın yalnızca seçtiğin konulardan hazırlanır; zayıf ve bitmemiş konular öne alınır.',
                  style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                for (final e in dersler.entries) _dersBolumu(e.key, e.value, secili),
              ],
            ),
    );
  }

  Widget _dersBolumu(String ders, List<Konu> konular, Set<String> secili) {
    final c = context.colors;
    final adet = konular.where((k) => secili.contains(k.id)).length;
    final acik = _acik.contains(ders);
    String? sonTema;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => acik ? _acik.remove(ders) : _acik.add(ders)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                child: Row(
                  children: [
                    Checkbox(
                      tristate: true,
                      value: adet == 0 ? false : (adet == konular.length ? true : null),
                      onChanged: (_) => setState(() {
                        final idler = konular.map((k) => k.id);
                        adet == konular.length ? secili.removeAll(idler) : secili.addAll(idler);
                      }),
                    ),
                    Container(width: 5, height: 30, decoration: BoxDecoration(color: dersRengi(ders), borderRadius: BorderRadius.circular(3))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ders, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                          Text('$adet / ${konular.length} konu seçili', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                        ],
                      ),
                    ),
                    Icon(acik ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: c.textMuted),
                  ],
                ),
              ),
            ),
            if (acik)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final k in konular) ...[
                      if (konuTemasi(k.id) case final String tema when tema != sonTema)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                          child: Text(sonTema = tema, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textMuted)),
                        ),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => secili.contains(k.id) ? secili.remove(k.id) : secili.add(k.id)),
                        child: Row(
                          children: [
                            Checkbox(
                              value: secili.contains(k.id),
                              onChanged: (v) => setState(() => v == true ? secili.add(k.id) : secili.remove(k.id)),
                            ),
                            Expanded(child: Text(k.baslik, style: TextStyle(color: c.textPrimary))),
                            if (k.zayif) Icon(Icons.flag_rounded, size: 16, color: c.danger),
                            if (k.tamamlandi) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.check_circle_rounded, size: 16, color: c.success)),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
