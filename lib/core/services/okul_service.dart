/// Okul yapısı ve raporlama çağrıları. Sunucu tarafı:
/// supabase_migrations/21_okul_yapisi.sql ve 22_okul_raporlama.sql.
/// Tablolara doğrudan erişilmez; her şey yetkiyi kendi denetleyen sunucu
/// fonksiyonlarıyla yapılır.
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/okul_modelleri.dart';

/// Kullanıcıya gösterilebilir hata.
class OkulHatasi implements Exception {
  final String mesaj;

  /// Sunucuda okul özelliği henüz kurulmamış (migration çalıştırılmamış).
  final bool kurulmamis;

  const OkulHatasi(this.mesaj, {this.kurulmamis = false});

  @override
  String toString() => mesaj;
}

class OkulService {
  OkulService._();

  static SupabaseClient get _db => Supabase.instance.client;

  /// Testlerde sunucu çağrılarının yerine geçer (fonksiyon adı, parametreler).
  @visibleForTesting
  static Future<dynamic> Function(String fn, Map<String, dynamic>? params)? sahteCagri;

  static OkulHatasi _hata(Object e) {
    if (e is OkulHatasi) return e;
    if (e is PostgrestException) {
      // Fonksiyon bulunamadı: migration 21/22 henüz çalıştırılmamış.
      if (e.code == 'PGRST202' || e.code == '42883') {
        return const OkulHatasi('Okul özellikleri sunucuda henüz etkinleştirilmedi.', kurulmamis: true);
      }
      // Fonksiyonların kendi yazdığı Türkçe iletiler (P0001) kullanıcıya gösterilir.
      if (e.code == 'P0001' && e.message.isNotEmpty && e.message != 'Unauthorized') {
        return OkulHatasi(e.message);
      }
      return const OkulHatasi('Sunucu şu an yanıt veremiyor. Biraz sonra tekrar dene.');
    }
    return const OkulHatasi('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.');
  }

  static Future<T> _cagir<T>(String fn, T Function(dynamic) cevir, [Map<String, dynamic>? params]) async {
    try {
      final sahte = sahteCagri;
      return cevir(sahte != null ? await sahte(fn, params) : await _db.rpc(fn, params: params));
    } catch (e) {
      throw _hata(e);
    }
  }

  static Map<String, dynamic> _harita(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<Map<String, dynamic>> _liste(dynamic v) =>
      [for (final e in (v as List?) ?? const []) if (e is Map) Map<String, dynamic>.from(e)];

  // ─── Durum ve kodlar ───────────────────────────────────────────────

  static Future<OkulDurumu> durum() => _cagir('okul_durumum', (v) => OkulDurumu.fromJson(_harita(v)));

  /// Yalnızca rol; okul fonksiyonları kurulu değilse profil satırından okunur.
  static Future<String> rol() async {
    try {
      return (await durum()).rol;
    } on OkulHatasi catch (e) {
      if (!e.kurulmamis) rethrow;
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return 'student';
      try {
        final row = await _db.from('profiles').select('role').eq('id', uid).maybeSingle();
        return row?['role'] as String? ?? 'student';
      } catch (e) {
        throw _hata(e);
      }
    }
  }

  static Future<KodSonucu> koduKullan(String kod, KullaniciRolu tur, {bool onay = false}) => _cagir(
        'okul_kodu_kullan',
        (v) => KodSonucu.fromJson(_harita(v)),
        {'p_kod': kod, 'p_tur': tur.tur, 'p_onay': onay},
      );

  /// Görünen adı günceller (öğretmen, veli ve müdür kayıt sırasında girer).
  static Future<void> adGuncelle(String ad) async {
    if (sahteCagri != null) return;
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _db.from('profiles').update({'name': ad.trim()}).eq('id', uid);
    } catch (e) {
      throw _hata(e);
    }
  }

  /// 'ok' | 'yok' | 'mudur'
  static Future<String> okuldanAyril() => _cagir('okuldan_ayril', (v) => v as String? ?? 'yok');

  // ─── Veli bağlantıları ─────────────────────────────────────────────

  /// Kod ya da 'limit'.
  static Future<String> veliKoduUret() => _cagir('veli_kodu_uret', (v) => v as String);

  static Future<List<VeliBaglantisi>> veliBaglantilari() =>
      _cagir('veli_baglantilarim', (v) => [for (final b in _liste(v)) VeliBaglantisi.fromJson(b)]);

  static Future<void> veliBaglantisiniBitir(String id) =>
      _cagir('veli_baglantisini_bitir', (_) {}, {'p_id': id});

  // ─── Öğretmen ──────────────────────────────────────────────────────

  static Future<OgretmenSiniflari> siniflarim() =>
      _cagir('ogretmen_siniflarim', (v) => OgretmenSiniflari.fromJson(_harita(v)));

  static Future<SubeOzeti> subeOzeti(String subeId) =>
      _cagir('sube_ozeti', (v) => SubeOzeti.fromJson(_harita(v)), {'p_sube_id': subeId});

  static Future<List<OgrenciSatiri>> uyarilar() =>
      _cagir('ogretmen_uyarilari', (v) => [for (final o in _liste(v)) OgrenciSatiri.fromJson(o)]);

  static Future<List<KonuSatiri>> subeKonuOzeti(String subeId) => _cagir(
        'sube_konu_ozeti',
        (v) => [for (final k in _liste(v)) KonuSatiri.fromJson(k)],
        {'p_sube_id': subeId},
      );

  static Future<OgrenciOzeti> ogrenciOzeti(String ogrenciId) =>
      _cagir('ogrenci_ozeti', (v) => OgrenciOzeti.fromJson(_harita(v)), {'p_ogrenci_id': ogrenciId});

  static Future<void> gorusmeEkle(String ogrenciId, String not, String? hedef) =>
      _cagir('gorusme_ekle', (_) {}, {'p_ogrenci_id': ogrenciId, 'p_not': not, 'p_hedef': hedef});

  static Future<void> gorusmeSil(String id) => _cagir('gorusme_sil', (_) {}, {'p_id': id});

  // ─── Öneriler ──────────────────────────────────────────────────────

  static Future<void> oneriOlustur({
    required String subeId,
    required String ders,
    required String konu,
    String? not,
    int sureDk = 30,
    DateTime? bitis,
  }) =>
      _cagir('oneri_olustur', (_) {}, {
        'p_sube_id': subeId,
        'p_ders': ders,
        'p_konu': konu,
        'p_not': not,
        'p_sure_dk': sureDk,
        'p_bitis': bitis == null
            ? null
            : '${bitis.year}-${bitis.month.toString().padLeft(2, '0')}-${bitis.day.toString().padLeft(2, '0')}',
      });

  static Future<void> oneriSil(String id) => _cagir('oneri_sil', (_) {}, {'p_id': id});

  static Future<List<Oneri>> ogretmenOnerileri() =>
      _cagir('ogretmen_onerilerim', (v) => [for (final o in _liste(v)) Oneri.fromJson(o)]);

  static Future<List<Oneri>> onerilerim() =>
      _cagir('onerilerim', (v) => [for (final o in _liste(v)) Oneri.fromJson(o)]);

  /// [durum]: 'eklendi' | 'tamamlandi'
  static Future<void> oneriIsaretle(String id, String durum) =>
      _cagir('oneri_isaretle', (_) {}, {'p_id': id, 'p_durum': durum});

  // ─── Öğrenci: sınıfım ──────────────────────────────────────────────

  static Future<SinifDurumu?> sinifDurumu() =>
      _cagir('sinif_durumum', (v) => v is Map ? SinifDurumu.fromJson(_harita(v)) : null);

  // ─── Müdür ─────────────────────────────────────────────────────────

  static Future<OkulOzeti> okulOzeti() => _cagir('okul_ozeti', (v) => OkulOzeti.fromJson(_harita(v)));

  static Future<YonetimOzeti> yonetimOzeti() =>
      _cagir('okul_yonetim_ozeti', (v) => YonetimOzeti.fromJson(_harita(v)));

  /// Yeni şubenin katılım kodu; aynı şube zaten varsa null.
  static Future<String?> subeEkle(String sinif, String ad) => _cagir(
        'okul_sube_ekle',
        (v) => _harita(v)['durum'] == 'ok' ? _harita(v)['kod'] as String? : null,
        {'p_sinif': sinif, 'p_ad': ad},
      );

  static Future<String> subeKoduYenile(String subeId) =>
      _cagir('okul_sube_kodu_yenile', (v) => v as String, {'p_sube_id': subeId});

  /// 'ok' | 'dolu'
  static Future<String> subeSil(String subeId) =>
      _cagir('okul_sube_sil', (v) => v as String? ?? 'ok', {'p_sube_id': subeId});

  static Future<String> ogretmenKoduUret({required bool rehber, String? brans}) =>
      _cagir('okul_ogretmen_kodu_uret', (v) => v as String, {'p_rehber': rehber, 'p_brans': brans});

  static Future<void> davetIptal(String kod) => _cagir('okul_davet_iptal', (_) {}, {'p_kod': kod});

  static Future<void> ogretmenAyarla({
    required String ogretmenId,
    required List<String> subeIdleri,
    required bool rehber,
    String? brans,
  }) =>
      _cagir('okul_ogretmen_ayarla', (_) {}, {
        'p_ogretmen_id': ogretmenId,
        'p_sube_ids': subeIdleri,
        'p_rehber': rehber,
        'p_brans': brans,
      });

  static Future<void> uyeyiCikar(String userId) => _cagir('okul_uyesini_cikar', (_) {}, {'p_user_id': userId});

  // ─── Uygulama yöneticisi ───────────────────────────────────────────

  static Future<List<AdminOkul>> adminOkullar() =>
      _cagir('admin_okullar', (v) => [for (final o in _liste(v)) AdminOkul.fromJson(o)]);

  /// Müdür kodunu döner.
  static Future<String> adminOkulOlustur({required String ad, String il = '', String ilce = ''}) => _cagir(
        'admin_okul_olustur',
        (v) => _harita(v)['kod'] as String,
        {'p_ad': ad, 'p_il': il, 'p_ilce': ilce},
      );

  static Future<String> adminMudurKodu(String okulId) =>
      _cagir('admin_okul_mudur_kodu', (v) => v as String, {'p_okul_id': okulId});

  static Future<void> adminOkulAktiflik(String okulId, bool aktif) =>
      _cagir('admin_okul_aktiflik', (_) {}, {'p_okul_id': okulId, 'p_aktif': aktif});
}
