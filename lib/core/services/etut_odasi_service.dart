/// Etüt odaları — 10 hazır oda, oda başına en fazla 30 kişi. Sunucu tarafı:
/// supabase_migrations/17_etut_odalari.sql. Sıralama, sunucunun ölçtüğü odak
/// oturumlarından (study_sessions) katılma anından itibaren hesaplanır.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

class EtutOdasi {
  final int id;
  final String ad;
  final String aciklama;
  final int kapasite;
  final int uyeSayisi;
  final int calisanSayisi;
  final bool benim;

  const EtutOdasi({
    required this.id,
    required this.ad,
    required this.aciklama,
    required this.kapasite,
    required this.uyeSayisi,
    required this.calisanSayisi,
    required this.benim,
  });

  bool get dolu => uyeSayisi >= kapasite;

  factory EtutOdasi.fromJson(Map<String, dynamic> j) => EtutOdasi(
        id: (j['id'] as num).toInt(),
        ad: j['ad'] as String? ?? 'Etüt odası',
        aciklama: j['aciklama'] as String? ?? '',
        kapasite: (j['kapasite'] as num?)?.toInt() ?? 30,
        uyeSayisi: (j['uye_sayisi'] as num?)?.toInt() ?? 0,
        calisanSayisi: (j['calisan_sayisi'] as num?)?.toInt() ?? 0,
        benim: j['benim'] as bool? ?? false,
      );
}

class EtutUyesi {
  final String userId;
  final String ad;
  final DateTime katilma;

  /// Katıldıktan sonra biten oturumlardaki dakikalar.
  final int tamamlananDk;

  /// Sürmekte olan oturumun katıldıktan sonraki dakikaları.
  final int aktifDk;
  final bool calisiyor;
  final String? aktifDers;
  final bool cevrimici;
  final bool ben;

  const EtutUyesi({
    required this.userId,
    required this.ad,
    required this.katilma,
    required this.tamamlananDk,
    required this.aktifDk,
    required this.calisiyor,
    required this.aktifDers,
    required this.cevrimici,
    required this.ben,
  });

  int get toplamDk => tamamlananDk + aktifDk;

  factory EtutUyesi.fromJson(Map<String, dynamic> j) => EtutUyesi(
        userId: j['user_id'] as String,
        ad: j['ad'] as String? ?? 'Öğrenci',
        katilma: DateTime.tryParse(j['katilma'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        tamamlananDk: (j['tamamlanan_dk'] as num?)?.toInt() ?? 0,
        aktifDk: (j['aktif_dk'] as num?)?.toInt() ?? 0,
        calisiyor: j['calisiyor'] as bool? ?? false,
        aktifDers: j['aktif_ders'] as String?,
        cevrimici: j['cevrimici'] as bool? ?? false,
        ben: j['ben'] as bool? ?? false,
      );
}

/// Sunucu işlemlerinden dönen, kullanıcıya gösterilebilir hata.
class EtutHatasi implements Exception {
  final String mesaj;
  const EtutHatasi(this.mesaj);

  @override
  String toString() => mesaj;
}

class EtutOdasiService {
  EtutOdasiService._();

  static SupabaseClient get _db => Supabase.instance.client;

  static EtutHatasi _hata(Object e) {
    if (e is PostgrestException) {
      // Fonksiyon bulunamadı: migration 17 henüz çalıştırılmamış.
      if (e.code == 'PGRST202' || e.code == '42883') {
        return const EtutHatasi('Etüt odaları sunucuda henüz etkinleştirilmedi.');
      }
      if (e.message.contains('üyesi değilsin')) {
        return const EtutHatasi('Bu odanın üyesi değilsin. Listeden odaya yeniden katılabilirsin.');
      }
      return const EtutHatasi('Sunucu şu an yanıt veremiyor. Biraz sonra tekrar dene.');
    }
    return const EtutHatasi('Bağlantı kurulamadı. İnternetini kontrol edip tekrar dene.');
  }

  static Future<List<EtutOdasi>> odalar() async {
    try {
      final rows = await _db.rpc('etut_odalari_listesi') as List;
      return [for (final r in rows) EtutOdasi.fromJson(Map<String, dynamic>.from(r as Map))];
    } catch (e) {
      throw _hata(e);
    }
  }

  /// 'ok' | 'dolu' | 'yok'
  static Future<String> katil(int odaId) async {
    try {
      return await _db.rpc('etut_odasina_katil', params: {'p_oda_id': odaId}) as String;
    } catch (e) {
      throw _hata(e);
    }
  }

  static Future<void> ayril() async {
    try {
      await _db.rpc('etut_odasindan_ayril');
    } catch (e) {
      throw _hata(e);
    }
  }

  /// Odadaki üyeler (en çok çalışan başta). Çağrı aynı zamanda "odadayım"
  /// nabzı sayılır.
  static Future<List<EtutUyesi>> durum(int odaId) async {
    try {
      final rows = await _db.rpc('etut_odasi_durum', params: {'p_oda_id': odaId}) as List;
      final l = [for (final r in rows) EtutUyesi.fromJson(Map<String, dynamic>.from(r as Map))];
      l.sort((a, b) {
        final c = b.toplamDk.compareTo(a.toplamDk);
        return c != 0 ? c : a.katilma.compareTo(b.katilma);
      });
      return l;
    } catch (e) {
      throw _hata(e);
    }
  }
}
