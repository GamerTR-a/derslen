import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/ders_programi.dart' show alanAytDersleri;
import '../../core/constants/app_constants.dart';
import '../../core/utils/tarih.dart';
import '../providers/mufredat_provider.dart';
import '../providers/net_provider.dart';
import '../providers/profil_provider.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

/// Bir denemenin tüm derslerini tek formda kaydeder. Doğru ve yanlış girilir,
/// boş sayısı dersin soru sayısından otomatik hesaplanır. Hiç doldurulmayan
/// dersler (o oturuma girilmediyse) kaydedilmez.
class DenemeEkleDialog extends ConsumerStatefulWidget {
  const DenemeEkleDialog({super.key});

  @override
  ConsumerState<DenemeEkleDialog> createState() => _DenemeEkleDialogState();
}

class _DersGirdisi {
  final TextEditingController dogru = TextEditingController();
  final TextEditingController yanlis = TextEditingController();

  bool get bos => dogru.text.trim().isEmpty && yanlis.text.trim().isEmpty;
  int get d => int.tryParse(dogru.text.trim()) ?? 0;
  int get y => int.tryParse(yanlis.text.trim()) ?? 0;

  void dispose() {
    dogru.dispose();
    yanlis.dispose();
  }
}

class _DenemeEkleDialogState extends ConsumerState<DenemeEkleDialog> {
  SinavAlani _alan = SinavAlani.TYT;
  DateTime _tarih = DateTime.now();
  bool _tumAytDersleri = false;
  final _denemeAdiController = TextEditingController();
  final Map<String, _DersGirdisi> _girdiler = {};

  @override
  void dispose() {
    _denemeAdiController.dispose();
    for (final g in _girdiler.values) {
      g.dispose();
    }
    super.dispose();
  }

  _DersGirdisi _girdi(String ders) => _girdiler.putIfAbsent('${_alan.name}|$ders', _DersGirdisi.new);

  bool _serbest = false;

  int _maks(String ders) => _serbest ? 100 : denemeSoruSayilari[_alan]![ders]!;

  List<String> _dersler(String hedefBolum) {
    if (_serbest) return ref.read(mufredatProvider).ozelDersler;
    final hepsi = denemeSoruSayilari[_alan]!.keys.toList();
    if (_alan == SinavAlani.TYT || _tumAytDersleri) return hepsi;
    final alan = alanAytDersleri[hedefBolum] ?? const [];
    final ilgili = hepsi.where((d) {
      if (alan.contains(d)) return true;
      // Sözel alanın AYT'sinde felsefe grubu ve din kültürü de vardır.
      return hedefBolum == 'sozel' && (d == 'Felsefe Grubu' || d == 'Din Kültürü');
    }).toList();
    return ilgili.isEmpty ? hepsi : ilgili;
  }

  String? _satirHatasi(String ders) {
    final g = _girdi(ders);
    if (g.bos) return null;
    final max = _maks(ders);
    if (_serbest) return g.d > max ? 'En fazla 100' : null;
    if (g.d + g.y > max) return 'En fazla $max soru';
    return null;
  }

  Future<void> _tarihSec() async {
    final simdi = DateTime.now();
    final secim = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: simdi.subtract(const Duration(days: 365)),
      lastDate: simdi,
      helpText: 'Deneme tarihi',
    );
    if (secim != null) setState(() => _tarih = secim);
  }

  Future<void> _kaydet(List<String> dersler) async {
    final satirlar = <DenemeSatiri>[];
    for (final d in dersler) {
      final g = _girdi(d);
      if (g.bos) continue;
      if (_satirHatasi(d) != null) {
        _uyari(_serbest ? '$d puanı 100\'ü aşamaz.' : '$d için doğru + yanlış, soru sayısını aşıyor.');
        return;
      }
      final max = _maks(d);
      // Serbest modda puan (100 üzerinden) "doğru" alanında saklanır.
      satirlar.add(_serbest ? DenemeSatiri(d, g.d, 0, max - g.d) : DenemeSatiri(d, g.d, g.y, max - g.d - g.y));
    }
    if (satirlar.isEmpty) {
      _uyari(_serbest ? 'En az bir dersin puanını gir.' : 'En az bir dersin doğru/yanlış sayısını gir.');
      return;
    }
    HapticFeedback.mediumImpact();
    await ref.read(netProvider.notifier).denemeEkle(
          alan: _alan,
          tarih: _tarih,
          satirlar: satirlar,
          denemeAdi: _denemeAdiController.text,
          serbest: _serbest,
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _uyari(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hedefBolum = ref.watch(profilProvider).value?.hedefBolum ?? 'sayisal';
    _serbest = ref.watch(serbestModProvider);
    ref.watch(mufredatProvider);
    if (_serbest) _alan = SinavAlani.TYT;
    final dersler = _dersler(hedefBolum);
    final dolu = dersler.where((d) => !_girdi(d).bos).toList();
    final toplamNet = _serbest
        ? (dolu.isEmpty ? 0.0 : dolu.fold<double>(0, (t, d) => t + _girdi(d).d) / dolu.length)
        : dersler.fold<double>(0, (t, d) {
            final g = _girdi(d);
            return t + g.d - g.y * 0.25;
          });
    final otomatikAd = ref.read(netProvider.notifier).otomatikAd(_alan, serbest: _serbest);

    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_serbest ? 'Sınav Sonucu Ekle' : 'Deneme Sonucu Ekle', style: context.baslik(20))),
                    IconButton(
                      icon: Icon(Icons.close, color: c.textMuted),
                      tooltip: 'Kapat',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_serbest) SegmentedButton<SinavAlani>(
                  segments: const [
                    ButtonSegment(value: SinavAlani.TYT, label: Text('TYT')),
                    ButtonSegment(value: SinavAlani.AYT, label: Text('AYT')),
                  ],
                  selected: {_alan},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _alan = s.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _denemeAdiController,
                  style: TextStyle(color: c.textPrimary),
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: _serbest ? 'Sınav adı (isteğe bağlı): Vize, Final…' : 'Deneme adı / yayın (isteğe bağlı)',
                    hintText: otomatikAd,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _tarihSec,
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text(gunAnahtari(_tarih) == gunAnahtari(DateTime.now()) ? 'Bugün' : kisaTarih(_tarih)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text('Ders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.textMuted)),
                    ),
                    SizedBox(width: 62, child: Text(_serbest ? 'Puan' : 'Doğru', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.success))),
                    if (!_serbest) ...[
                      const SizedBox(width: 6),
                      SizedBox(width: 62, child: Text('Yanlış', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.danger))),
                      const SizedBox(width: 6),
                      SizedBox(width: 52, child: Text('Net', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.primary))),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                for (final d in dersler) _dersSatiri(context, d),
                if (_serbest && dersler.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('Önce Müfredatım ekranından ders eklemelisin.', style: TextStyle(color: c.textMuted)),
                  ),
                if (_alan == SinavAlani.AYT && !_serbest)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _tumAytDersleri = !_tumAytDersleri),
                      icon: Icon(_tumAytDersleri ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 18),
                      label: Text(_tumAytDersleri ? 'Yalnızca alanımın derslerini göster' : 'Tüm AYT derslerini göster'),
                    ),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_serbest ? 'Ortalama puan' : 'Toplam ${_alan.name} neti',
                            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold)),
                      ),
                      Text(toplamNet.toStringAsFixed(2),
                          style: TextStyle(color: c.primary, fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    _serbest
                        ? 'Puanları 100 üzerinden gir. Boş bıraktığın dersler kaydedilmez; tek derslik sınavı da girebilirsin.'
                        : '4 yanlış 1 doğruyu götürür. Boş sayısı soru sayısından otomatik hesaplanır; boş bıraktığın dersler kaydedilmez.',
                    style: TextStyle(fontSize: 11.5, color: c.textMuted, height: 1.35)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _kaydet(dersler),
                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(_serbest ? 'Sonucu Kaydet' : 'Denemeyi Kaydet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dersSatiri(BuildContext context, String ders) {
    final c = context.colors;
    final g = _girdi(ders);
    final max = _maks(ders);
    final hata = _satirHatasi(ders);
    final net = g.d - g.y * 0.25;

    Widget alan(TextEditingController ctrl, Color renk) => SizedBox(
          width: 62,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_serbest ? 3 : 2)],
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
            decoration: InputDecoration(
              hintText: '–',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: hata != null ? c.danger : c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: renk, width: 2),
              ),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(color: dersRengi(ders), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ders, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary, fontSize: 13.5)),
                Text(
                  hata ?? (_serbest ? '100 üzerinden' : (g.bos ? '$max soru' : '$max soru · ${max - g.d - g.y} boş')),
                  style: TextStyle(fontSize: 11, color: hata != null ? c.danger : c.textMuted),
                ),
              ],
            ),
          ),
          alan(g.dogru, c.success),
          if (!_serbest) ...[
            const SizedBox(width: 6),
            alan(g.yanlis, c.danger),
            const SizedBox(width: 6),
            SizedBox(
              width: 52,
              child: Text(
                g.bos ? '–' : net.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
