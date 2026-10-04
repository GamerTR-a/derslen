/// Müfredatım — ders ve konu ekleme/çıkarma. Serbest modda (üniversite vb.)
/// müfredatın tamamı buradan kurulur; YKS alanlarında hazır derslerin üstüne
/// ders/konu eklenebilir, istenmeyen hazır dersler ve konular çıkarılabilir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yks_kocu/core/theme/theme_extensions.dart';

import '../../../core/algorithms/ders_programi.dart' show alanAytDersleri;
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/sinif_mufredati.dart';
import '../../../data/models/konu.dart';
import '../../providers/konu_provider.dart';
import '../../../core/utils/tarih.dart';
import '../../providers/mufredat_provider.dart';
import '../../providers/plan_provider.dart';
import '../../providers/profil_provider.dart';
import '../../widgets/ui_kit.dart';

class MufredatScreen extends ConsumerStatefulWidget {
  const MufredatScreen({super.key});

  @override
  ConsumerState<MufredatScreen> createState() => _MufredatScreenState();
}

class _MufredatScreenState extends ConsumerState<MufredatScreen> {
  bool _degisti = false;
  late final ProgramNotifier _program = ref.read(programProvider.notifier);

  @override
  void dispose() {
    // Dersler değiştiyse haftalık program yeni müfredata göre yenilenir.
    if (_degisti) Future.microtask(_program.yenidenOlustur);
    super.dispose();
  }

  MufredatNotifier get _n => ref.read(mufredatProvider.notifier);

  Future<void> _dersEkle() async {
    final ad = TextEditingController();
    final konular = TextEditingController();
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ders ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ad,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ders adı', hintText: 'Örn: Anatomi, Lineer Cebir'),
              ),
              TextField(
                controller: konular,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Konular (isteğe bağlı)',
                  hintText: 'Her satıra ya da virgülle ayırarak bir konu yaz',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ekle')),
        ],
      ),
    );
    final dersAdi = ad.text;
    final liste = konular.text.split(RegExp(r'[\n,;]')).where((s) => s.trim().isNotEmpty).toList();
    ad.dispose();
    konular.dispose();
    if (sonuc != true || dersAdi.trim().isEmpty) return;
    await _n.dersEkle(dersAdi, liste);
    _degisti = true;
  }

  Future<void> _konuEkle(String ders) async {
    final c = TextEditingController();
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$ders · konu ekle'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Konu adı (birden fazlaysa virgülle ayır)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ekle')),
        ],
      ),
    );
    final liste = c.text.split(RegExp(r'[\n,;]')).where((s) => s.trim().isNotEmpty).toList();
    c.dispose();
    if (sonuc != true || liste.isEmpty) return;
    await _n.dersEkle(ders, liste);
    _degisti = true;
  }

  Future<void> _dersSil(String ders) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('“$ders” silinsin mi?'),
        content: const Text('Dersin eklediğin tüm konuları müfredatından çıkar. Geçmiş çalışma kayıtların silinmez.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
        ],
      ),
    );
    if (onay != true) return;
    await _n.dersSil(ders);
    _degisti = true;
  }

  Future<void> _hedefDuzenle(MufredatState m) async {
    final ad = TextEditingController(text: m.hedefAd ?? '');
    DateTime? tarih = m.hedefTarih == null ? null : DateTime.tryParse(m.hedefTarih!);
    final sonuc = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Hedef sınav'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ad,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Sınav adı', hintText: 'Örn: Finaller, KPSS, YDS'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final simdi = DateTime.now();
                  final secim = await showDatePicker(
                    context: ctx,
                    initialDate: tarih ?? simdi.add(const Duration(days: 30)),
                    firstDate: simdi,
                    lastDate: simdi.add(const Duration(days: 365 * 3)),
                  );
                  if (secim != null) setS(() => tarih = secim);
                },
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(tarih == null ? 'Tarih seç' : '${kisaTarih(tarih!)} ${tarih!.year}'),
              ),
              if (tarih != null)
                TextButton(onPressed: () => setS(() => tarih = null), child: const Text('Tarihi kaldır')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kaydet')),
          ],
        ),
      ),
    );
    final adMetni = ad.text;
    ad.dispose();
    if (sonuc != true) return;
    await _n.hedefAyarla(ad: adMetni, tarih: tarih);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = ref.watch(mufredatProvider);
    final profil = ref.watch(profilProvider).value;
    final serbest = ref.watch(serbestModProvider);
    final ayt = alanAytDersleri[profil?.hedefBolum] ?? const <String>[];

    final sinif = ref.watch(sinifProvider);
    // Hazır dersler: 9-11. sınıflarda o sınıfın Maarif Modeli dersleri;
    // diğerlerinde TYT'nin tamamı + alanın AYT dersleri.
    final hazirDersler = <(String, String), List<Konu>>{};
    for (final k in ref.watch(hazirMufredatProvider)) {
      if (sinif != null) {
        hazirDersler.putIfAbsent(('', k.ders), () => []).add(k);
      } else if (k.alan == SinavAlani.TYT || ayt.contains(k.ders)) {
        hazirDersler.putIfAbsent((k.alan.name, k.ders), () => []).add(k);
      }
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        title: Text('Müfredatım', style: context.baslik(20)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _dersEkle,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ders ekle', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: !m.yuklendi
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              children: [
                Text(
                  serbest
                      ? 'Serbest müfredat: derslerini ve konularını kendin belirlersin. Ders programın, analizlerin ve odak seansların bu derslere göre çalışır.'
                      : sinif != null
                          ? '$sinif. sınıf müfredatın Türkiye Yüzyılı Maarif Modeli konularıyla hazır gelir. Kendi derslerini ekleyebilir, çalışmayacağın ders ve konuları çıkarabilirsin. Sınıfını Profil › Profili Düzenle bölümünden değiştirebilirsin.'
                          : 'Hazır YKS derslerine kendi derslerini ekleyebilir, çalışmayacağın ders ve konuları müfredatından çıkarabilirsin.',
                  style: TextStyle(fontSize: 13, color: c.textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                if (serbest) ...[
                  YumusakKart(
                    onTap: () => _hedefDuzenle(m),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.flag_rounded, color: c.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.hedefAd ?? 'Hedef sınav ekle', style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
                              Text(
                                m.hedefeKalanGun == null ? 'Sınav adı ve tarihi (isteğe bağlı); ana sayfada geri sayım olarak görünür' : '${m.hedefeKalanGun} gün kaldı',
                                style: TextStyle(fontSize: 12.5, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                BolumBasligi('Derslerim (${m.ozelDersler.length})'),
                if (m.ozelDersler.isEmpty)
                  YumusakKart(
                    child: Text(
                      serbest
                          ? 'Henüz ders eklemedin. “Ders ekle” ile ilk dersini ve konularını yaz; programın bu derslerden oluşacak.'
                          : 'Kendi eklediğin ders yok. Okul dersi, kurs ya da ek sınav için “Ders ekle”yi kullanabilirsin.',
                      style: TextStyle(color: c.textSecondary, height: 1.4),
                    ),
                  ),
                for (final d in m.ozelDersler) _ozelDersKarti(context, m, d),
                if (hazirDersler.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  BolumBasligi(sinif != null ? '$sinif. sınıf dersleri' : 'Hazır YKS dersleri'),
                  for (final e in hazirDersler.entries) _hazirDersKarti(context, m, e.key.$1, e.key.$2, e.value),
                ],
              ],
            ),
    );
  }

  Widget _kart(BuildContext context, {required Widget child}) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        // Liste satırları mürekkep efektini en yakın Material'a çizer; renkli
        // kutunun içinde kendi saydam Material'ı olmalıdır.
        child: Material(
          type: MaterialType.transparency,
          child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: child),
        ),
      );

  Widget _ozelDersKarti(BuildContext context, MufredatState m, String ders) {
    final c = context.colors;
    final konular = m.ozelKonular.where((k) => k.ders == ders).toList();
    return _kart(
      context,
      child: ExpansionTile(
        leading: Container(width: 6, height: 36, decoration: BoxDecoration(color: dersRengi(ders), borderRadius: BorderRadius.circular(3))),
        title: Text(ders, style: TextStyle(fontWeight: FontWeight.w800, color: c.textPrimary)),
        subtitle: Text('${konular.length} konu', style: TextStyle(fontSize: 12.5, color: c.textMuted)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
        children: [
          for (final k in konular)
            Row(
              children: [
                Expanded(child: Text(k.baslik, style: TextStyle(color: c.textPrimary))),
                IconButton(
                  tooltip: 'Konuyu sil',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                  onPressed: konular.length == 1
                      ? () => _dersSil(ders)
                      : () async {
                          await _n.konuSil(k.id);
                          _degisti = true;
                        },
                ),
              ],
            ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(onPressed: () => _konuEkle(ders), icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Konu ekle')),
              TextButton.icon(
                onPressed: () => _dersSil(ders),
                icon: Icon(Icons.delete_outline_rounded, size: 18, color: c.danger),
                label: Text('Dersi sil', style: TextStyle(color: c.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hazirDersKarti(BuildContext context, MufredatState m, String alan, String ders, List<Konu> konular) {
    final c = context.colors;
    final acik = konular.where((k) => !m.gizliIdler.contains(k.id)).length;
    return _kart(
      context,
      child: ExpansionTile(
        leading: Container(
          width: 6,
          height: 36,
          decoration: BoxDecoration(color: acik == 0 ? c.border : dersRengi(ders), borderRadius: BorderRadius.circular(3)),
        ),
        title: Text('$alan $ders'.trim(), style: TextStyle(fontWeight: FontWeight.w800, color: acik == 0 ? c.textMuted : c.textPrimary)),
        subtitle: Text(acik == 0 ? 'Müfredatından çıkarıldı' : '$acik/${konular.length} konu müfredatında',
            style: TextStyle(fontSize: 12.5, color: c.textMuted)),
        trailing: Switch(
          value: acik > 0,
          onChanged: (v) async {
            await _n.konulariGizle(konular.map((k) => k.id), !v);
            _degisti = true;
          },
        ),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        children: [
          for (final k in konular)
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: !m.gizliIdler.contains(k.id),
              title: Text(k.baslik, style: TextStyle(color: c.textPrimary)),
              subtitle: konuTemasi(k.id) == null ? null : Text(konuTemasi(k.id)!, style: TextStyle(fontSize: 11.5, color: c.textMuted)),
              onChanged: (v) async {
                await _n.konuGizle(k.id, v != true);
                _degisti = true;
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _konuEkle(ders),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Bu derse kendi konumu ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
