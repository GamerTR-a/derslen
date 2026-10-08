import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_ticket.dart';
import '../../data/models/post.dart';
import '../../data/models/community.dart';
import '../../data/models/auth_user.dart';
import '../../data/models/study_session.dart';
import '../../data/models/leaderboard_entry.dart';
import '../../data/models/coach_student.dart';
import '../../data/models/exam_result.dart';
import '../../data/models/koc_gorev.dart';

class SupabaseDataService {
  static SupabaseClient get _db => Supabase.instance.client;

  static String? get currentUserId {
    try {
      return _db.auth.currentUser?.id;
    } catch (_) {
      return null; // Supabase yapılandırılmamış (geliştirme derlemesi)
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // 1. TALEP VE ŞİKAYET SİSTEMİ (TICKET SYSTEM)
  // ═════════════════════════════════════════════════════════════════════

  /// Yeni Talep / Şikayet / Öneri Oluştur
  static Future<void> createTicket({
    required String type,
    required String subject,
    required String description,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');
    if (!UserTicket.validTypes.contains(type)) {
      throw ArgumentError('Geçersiz talep türü: $type');
    }

    try {
      await _db.from('user_tickets').insert({
        'user_id': uid,
        'type': type,
        'subject': subject.trim(),
        'description': description.trim(),
        'status': 'open',
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('Günlük talep')) throw Exception(e.message);
      rethrow;
    }
  }

  /// Kullanıcının Kendi Taleplerini Getir
  static Future<List<UserTicket>> getUserTickets() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final response = await _db
        .from('user_tickets')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (response as List).map((json) => UserTicket.fromJson(json)).toList();
  }

  /// Admin İçin Tüm Talepleri Getir
  static Future<List<UserTicket>> getAllTickets({String? statusFilter}) async {
    var query = _db.from('user_tickets').select();
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }

    final response = await query.order('created_at', ascending: false);
    return (response as List).map((json) => UserTicket.fromJson(json)).toList();
  }

  /// Admin: Talep Durumunu ve Notunu Güncelle
  static Future<void> updateTicketStatus({
    required String ticketId,
    required String status,
    String? adminNotes,
  }) async {
    if (!UserTicket.validStatuses.contains(status)) {
      throw ArgumentError('Geçersiz talep durumu: $status');
    }

    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (adminNotes != null) {
      updateData['admin_notes'] = adminNotes;
    }

    await _db.from('user_tickets').update(updateData).eq('id', ticketId);
  }

  // ═════════════════════════════════════════════════════════════════════
  // 2. GÖNDERİ PAYLAŞIMI VE AKIŞ (POST ARCHITECTURE)
  // ═════════════════════════════════════════════════════════════════════

  /// Yeni Gönderi Paylaş. Topluluk adı/logosu sunucuda `communities`
  /// kaydından doldurulur; dış görsel bağlantısı kabul edilmez ve içerik
  /// kelime filtresinden geçer (bkz. supabase_migrations/15).
  static Future<void> createPost({
    required String content,
    int? communityId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');

    try {
      await _db.from('posts').insert({
        'user_id': uid,
        'community_id': communityId,
        'community_name': 'DersNet Topluluğu',
        'content': content.trim(),
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('kurallarına uymayan')) {
        throw Exception('Gönderin topluluk kurallarına uymayan ifadeler içeriyor.');
      }
      if (e.message.contains('Çok sık')) {
        throw Exception('Çok sık gönderi paylaşıyorsun, biraz sonra tekrar dene.');
      }
      throw Exception('Gönderi paylaşılamadı. Lütfen tekrar dene.');
    }
  }

  /// Gönderi şikâyet sebepleri (sunucudaki CHECK listesiyle aynı).
  static const Map<String, String> sikayetSebepleri = {
    'uygunsuz': 'Uygunsuz içerik',
    'taciz': 'Zorbalık / taciz',
    'spam': 'Spam / reklam',
    'kisisel_bilgi': 'Kişisel bilgi paylaşımı',
    'diger': 'Diğer',
  };

  /// Bir gönderiyi şikâyet eder. 3 farklı şikâyette gönderi otomatik gizlenir.
  static Future<void> reportPost({required int postId, required String reason}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');
    try {
      await _db.from('post_reports').insert({'post_id': postId, 'reporter_id': uid, 'reason': reason});
    } on PostgrestException catch (e) {
      // Aynı gönderiyi ikinci kez şikâyet etmek (PK ihlali) başarı sayılır.
      if (e.code == '23505') return;
      throw Exception('Şikâyet gönderilemedi.');
    }
  }

  /// Kullanıcıyı engeller: gönderileri akışta görünmez, seni dürtemez.
  static Future<void> blockUser(String blockedId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');
    try {
      await _db.from('user_blocks').insert({'blocker_id': uid, 'blocked_id': blockedId});
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw Exception('Kullanıcı engellenemedi.');
    }
  }

  /// Kendi gönderini siler.
  static Future<void> deleteOwnPost(int postId) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');
    await _db.from('posts').delete().eq('id', postId).eq('user_id', uid);
  }

  /// Tüm Gönderileri Listele
  static Future<List<Post>> getPosts({int limit = 30}) async {
    final response = await _db
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => Post.fromJson(json)).toList();
  }

  // ═════════════════════════════════════════════════════════════════════
  // 3. TOPLULUK VE YETKİ YÜKSELTME (ROLE ELEVATION)
  // ═════════════════════════════════════════════════════════════════════

  /// Tüm Toplulukları Getir
  static Future<List<Community>> getCommunities() async {
    final response = await _db.from('communities').select().order('name');
    return (response as List).map((json) => Community.fromJson(json)).toList();
  }

  /// Başkan Atama (Yetki Yükseltme: student -> baskan)
  static Future<void> assignChairman({
    required String userId,
    required String userName,
    required int communityId,
  }) async {
    // 1. Önceki başkanlığı varsa temizle
    await _db
        .from('communities')
        .update({'chairman_id': null, 'chairman_name': null})
        .eq('chairman_id', userId);

    // 2. Yeni topluluğa bağla
    await _db.from('communities').update({
      'chairman_id': userId,
      'chairman_name': userName,
    }).eq('id', communityId);

    // 3. Rolü baskan yap
    await _db.from('profiles').update({'role': 'baskan'}).eq('id', userId);
  }

  /// Başkanlığı Geri Alma
  static Future<void> removeChairman({
    required int communityId,
    required String chairmanId,
  }) async {
    await _db.from('communities').update({
      'chairman_id': null,
      'chairman_name': null,
    }).eq('id', communityId);

    await _db
        .from('profiles')
        .update({'role': 'student'})
        .eq('id', chairmanId)
        .eq('role', 'baskan');
  }

  /// Rol Değiştirme (Admin yetkisi gerektirir)
  static Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _db.from('profiles').update({'role': role}).eq('id', userId);
  }

  // ═════════════════════════════════════════════════════════════════════
  // 4. ADMİN PANENİ VE İSTATİSTİKLER (ADMIN DASHBOARD)
  // ═════════════════════════════════════════════════════════════════════

  /// Admin Dashboard İstatistikleri
  static Future<Map<String, int>> getAdminDashboardStats() async {
    final results = await Future.wait([
      _db.from('profiles').select('id'),
      _db.from('communities').select('id'),
      _db.from('user_tickets').select('id'),
      _db.from('posts').select('id'),
      _db.from('user_tickets').select('id').eq('status', 'open'),
    ]);

    return {
      'users': (results[0] as List).length,
      'communities': (results[1] as List).length,
      'tickets': (results[2] as List).length,
      'posts': (results[3] as List).length,
      'open_tickets': (results[4] as List).length,
    };
  }

  /// Tüm Kullanıcıları Listele (Admin arama için)
  static Future<List<LiseAuthUser>> getAllUsers({String query = ''}) async {
    var req = _db.from('profiles').select();
    if (query.trim().isNotEmpty) {
      req = req.ilike('name', '%${query.trim()}%');
    }
    final response = await req.order('created_at', ascending: false).limit(50);

    return (response as List).map((json) {
      return LiseAuthUser(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Kullanıcı',
        email: '',
        role: json['role'] as String? ?? 'student',
        grade: json['grade'] as String?,
        department: (json['department'] is List) ? (json['department'] as List).join(', ') : json['department'] as String?,
        xp: json['xp'] != null ? (json['xp'] as num).toInt() : 0,
        profilePhoto: json['profile_photo'] as String?,
        isAdmin: json['role'] == 'admin',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      );
    }).toList();
  }

  // ═════════════════════════════════════════════════════════════════════
  // XP / ROZET SİSTEMİ
  // ═════════════════════════════════════════════════════════════════════

  /// Kazanılan bir rozetin XP ödülünü sunucudan talep eder. Tutar sunucudaki
  /// `badge_catalog`'dan okunur ve her rozet kullanıcı başına yalnızca bir kez
  /// XP verir (bkz. supabase_migrations/15 `award_badge_xp`). Çevrimdışıyken
  /// başarısız olursa yutulur; rozetin kendisi yine yerelde kazanılmış sayılır.
  static Future<void> awardBadgeXp(String badgeId) async {
    if (currentUserId == null) return;
    try {
      await _db.rpc('award_badge_xp', params: {'p_badge_id': badgeId});
    } catch (_) {
      // XP güncellenemezse yut.
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // ÇALIŞMA OTURUMLARI VE YILDIZ CÜZDANI (bkz. supabase_schema.sql §10, §8)
  // ═════════════════════════════════════════════════════════════════════

  /// Yeni bir çalışma (pomodoro) oturumu başlatır. Süre `started_at` olarak
  /// sunucuda damgalanır; tamamlanınca yıldız ödülü bu damgaya göre hesaplanır.
  /// Oturum id'sini döner; oturum oluşturulamazsa (örn. çevrimdışı) null döner.
  static Future<String?> startStudySession({
    required String label,
    required int plannedMinutes,
  }) async {
    final uid = currentUserId;
    if (uid == null) return null;
    try {
      final row = await _db
          .from('study_sessions')
          .insert({
            'user_id': uid,
            'label': label,
            'planned_minutes': plannedMinutes.clamp(1, 240),
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      return null;
    }
  }

  /// Bir oturumu bitirir; sunucu gerçek süreyi ölçüp yıldız verir.
  /// Döndürülen değer: (gerçekleşenDakika, kazanılanYıldız).
  ///
  /// [focusMinutes] gerçekten odaklanılan (duraklatmalar hariç) dakikadır;
  /// sunucu bunu kendi ölçtüğü süreyle sınırlar. 0 verilirse seans yıldızsız
  /// ve süresiz kapatılır ("vazgeç").
  static Future<(int actualMinutes, int starsAwarded)> completeStudySession(
    String sessionId, {
    int? focusMinutes,
  }) async {
    List rows;
    try {
      rows = await _db.rpc('complete_study_session', params: {
        'p_session_id': sessionId,
        'p_focus_minutes': ?focusMinutes,
      }) as List;
    } on PostgrestException catch (e) {
      // Sunucuda 18 numaralı migration henüz kurulmadıysa fonksiyon tek
      // parametrelidir; eski imzayla yeniden denenir.
      final eskiImza = e.code == 'PGRST202' || e.message.contains('Could not find the function');
      if (focusMinutes == null || !eskiImza) rethrow;
      rows = await _db.rpc('complete_study_session', params: {'p_session_id': sessionId}) as List;
    }
    if (rows.isEmpty) return (0, 0);
    final row = rows.first as Map<String, dynamic>;
    return (
      (row['actual_minutes'] as num?)?.toInt() ?? 0,
      (row['stars_awarded'] as num?)?.toInt() ?? 0,
    );
  }

  /// Kullanıcının güncel yıldız bakiyesi. Cüzdan hiç oluşturulmamışsa 0 döner.
  static Future<int> getWalletBalance() async {
    final uid = currentUserId;
    if (uid == null) return 0;
    try {
      final row = await _db
          .from('wallets')
          .select('balance')
          .eq('user_id', uid)
          .maybeSingle();
      return (row?['balance'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Bahçe mağazasından ürün satın alır; fiyat sunucudaki `garden_items`
  /// kataloğundan okunur (bkz. supabase_schema.sql §13). Yeni bakiyeyi döner.
  /// [purchaseId] idempotency anahtarıdır — tekrar gönderimde yıldız düşülmez.
  static Future<int> buyGardenItem({required String itemId, required String purchaseId}) async {
    if (currentUserId == null) throw Exception('Oturum açılmamış.');
    try {
      final result = await _db.rpc('buy_garden_item', params: {
        'p_item_id': itemId,
        'p_purchase_id': purchaseId,
      });
      return (result as num).toInt();
    } on PostgrestException catch (e) {
      if (e.message.contains('Insufficient')) throw Exception('Yeterli yıldızın yok.');
      throw Exception('Satın alma şu an yapılamıyor.');
    }
  }

  /// Kullanıcının bu haftaki kendi çalışma oturumları.
  static Future<List<StudySession>> getMyWeeklyStudySessions() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      return await getStudentWeeklyStudySessions(uid);
    } catch (_) {
      return [];
    }
  }

  /// Bugün tamamlanan çalışma oturumlarını (en yeniden en eskiye) getirir.
  static Future<List<StudySession>> getTodayStudySessions() async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      // Yerel gün başlangıcı, saat dilimi bilgisiyle (aksi hâlde gün UTC'ye göre kesilir).
      final simdi = DateTime.now();
      final startOfDay = DateTime(simdi.year, simdi.month, simdi.day).toUtc().toIso8601String();
      final response = await _db
          .from('study_sessions')
          .select()
          .eq('user_id', uid)
          .gte('started_at', startOfDay)
          .order('started_at', ascending: false);
      return (response as List)
          .map((json) => StudySession.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // DENEME NORMALİZASYONU / ANONİM KARŞILAŞTIRMA (bkz. supabase_schema.sql §11)
  // ═════════════════════════════════════════════════════════════════════

  /// Bir deneme sonucunu, o denemeyi çözen diğer kullanıcılarla anonim
  /// karşılaştırma yapılabilmesi için sunucuya gönderir. Ağ hatası olursa
  /// sessizce yutulur — bu, denemenin yerel kaydını (net_provider) etkilemez,
  /// sadece topluluk karşılaştırması o an için eksik kalır.
  static Future<void> submitExamResult({
    required String denemeAdi,
    required String alan, // 'TYT' | 'AYT'
    required String ders,
    required int dogru,
    required int yanlis,
    required int bos,
  }) async {
    if (currentUserId == null) return;
    try {
      await _db.rpc('submit_exam_result', params: {
        'p_deneme_adi': denemeAdi,
        'p_alan': alan,
        'p_ders': ders,
        'p_dogru': dogru,
        'p_yanlis': yanlis,
        'p_bos': bos,
      });
    } catch (_) {
      // Karşılaştırma verisi gönderilemezse yut; yerel kayıt zaten yapıldı.
    }
  }

  /// Bir denemenin ders bazlı topluluk ortalaması/standart sapmasını getirir.
  /// Katılımcı yoksa veya bir hata olursa katilimciSayisi=0 döner.
  static Future<ExamBenchmark> getExamBenchmark({
    required String denemeAdi,
    required String alan,
    required String ders,
  }) async {
    try {
      final rows = await _db.rpc('get_exam_benchmark', params: {
        'p_deneme_adi': denemeAdi,
        'p_alan': alan,
        'p_ders': ders,
      }) as List;
      if (rows.isEmpty) return const ExamBenchmark(katilimciSayisi: 0, ortalamaNet: 0, standartSapma: 0);
      final row = rows.first as Map<String, dynamic>;
      return ExamBenchmark(
        katilimciSayisi: (row['katilimci_sayisi'] as num?)?.toInt() ?? 0,
        ortalamaNet: (row['ortalama_net'] as num?)?.toDouble() ?? 0,
        standartSapma: (row['standart_sapma'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return const ExamBenchmark(katilimciSayisi: 0, ortalamaNet: 0, standartSapma: 0);
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // GRUPLAR / ÇALIŞMA ODALARI (bkz. supabase_schema.sql §12)
  // ═════════════════════════════════════════════════════════════════════

  /// Kullanıcının üye olduğu toplulukların id'leri.
  static Future<Set<int>> getMyCommunityIds() async {
    final uid = currentUserId;
    if (uid == null) return {};
    try {
      final rows = await _db.from('community_members').select('community_id').eq('user_id', uid);
      return (rows as List).map((r) => (r['community_id'] as num).toInt()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<bool> joinCommunity(int communityId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      await _db.from('community_members').insert({'community_id': communityId, 'user_id': uid});
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> leaveCommunity(int communityId) async {
    final uid = currentUserId;
    if (uid == null) return false;
    try {
      await _db.from('community_members').delete().eq('community_id', communityId).eq('user_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Bir topluluğun son [days] gündeki odak dakikasına göre sıralaması.
  /// Kullanıcı o topluluğun üyesi değilse boş liste döner.
  static Future<List<LeaderboardEntry>> getCommunityLeaderboard(
    int communityId, {
    int days = 7,
  }) async {
    try {
      final rows = await _db.rpc('get_community_leaderboard', params: {
        'p_community_id': communityId,
        'p_days': days,
      }) as List;
      return rows.map((r) => LeaderboardEntry.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Bir üyeyi dürter. Başarılıysa null, başarısızsa kullanıcıya gösterilebilecek
  /// bir hata metni (örn. saatlik limit) döner.
  static Future<String?> sendNudge({required int communityId, required String toUserId}) async {
    try {
      await _db.rpc('send_nudge', params: {
        'p_community_id': communityId,
        'p_to_user_id': toUserId,
      });
      return null;
    } on PostgrestException catch (e) {
      // Yalnızca sunucunun kullanıcıya yönelik uyarıları (RAISE EXCEPTION)
      // gösterilir; iç hata metinleri gösterilmez.
      final kullaniciMesaji = e.code == 'P0001' && !e.message.contains('Unauthorized');
      return kullaniciMesaji ? e.message : 'Dürtme gönderilemedi.';
    } catch (e) {
      return 'Dürtme gönderilemedi.';
    }
  }

  /// Bu toplulukta, kullanıcının henüz görmediği dürtmeleri (kim, ne zaman) getirir.
  static Future<List<Map<String, dynamic>>> getUnseenNudges(int communityId) async {
    final uid = currentUserId;
    if (uid == null) return [];
    try {
      final rows = await _db
          .from('nudges')
          .select('from_user_id, created_at, profiles!nudges_from_user_id_fkey(name)')
          .eq('community_id', communityId)
          .eq('to_user_id', uid)
          .eq('seen', false)
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> markNudgesSeen(int communityId) async {
    try {
      await _db.rpc('mark_nudges_seen', params: {'p_community_id': communityId});
    } catch (_) {
      // Görüldü işaretlenemezse sessizce yut; kritik değil.
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // KOÇ ↔ ÖĞRENCİ İLİŞKİSİ (bkz. supabase_schema.sql §9)
  // ═════════════════════════════════════════════════════════════════════

  /// Koç, öğrencinin uygulamaya gireceği tek kullanımlık bir davet kodu üretir.
  /// Yalnızca rolü 'baskan'/'coach'/'admin' olan kullanıcılar çağırabilir
  /// (aksi halde RPC sunucuda hata fırlatır).
  static Future<String> createCoachInvite() async {
    try {
      final result = await _db.rpc('create_coach_invite');
      return result as String;
    } on PostgrestException catch (e) {
      if (e.message.contains('Çok fazla')) throw Exception(e.message);
      if (e.message.contains('Only coaches')) throw Exception('Davet kodu yalnızca koç hesaplarıyla oluşturulabilir.');
      throw Exception('Davet kodu oluşturulamadı. Lütfen tekrar dene.');
    }
  }

  /// Öğrenci, koçundan aldığı davet kodunu girerek ilişkiyi aktive eder.
  static Future<void> acceptCoachInvite(String inviteCode) async {
    final sonuc = await _db.rpc('accept_coach_invite', params: {'p_invite_code': inviteCode.trim().toUpperCase()});
    switch (sonuc) {
      case 'ok':
        return;
      case 'rate_limited':
        throw Exception('Çok fazla hatalı deneme yaptın. Bir saat sonra tekrar dene.');
      case 'self':
        throw Exception('Kendi davet kodunu kullanamazsın.');
      default:
        throw Exception('Kod geçersiz, kullanılmış ya da süresi dolmuş (kodlar 48 saat geçerlidir).');
    }
  }

  /// Koç veya öğrenci, mevcut bir ilişkiyi sonlandırır.
  static Future<void> endCoachRelationship(String relationshipId) async {
    await _db.rpc('end_coach_relationship', params: {'p_relationship_id': relationshipId});
  }

  /// Giriş yapan koçun aktif öğrenci listesini, her öğrencinin görev
  /// sayaçlarıyla (bekleyen onay / geciken / tamamlanan / toplam) birlikte getirir.
  static Future<List<CoachStudent>> getMyStudents() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final relations = await _db
        .from('coach_students')
        .select('id, student_id, profiles!coach_students_student_id_fkey(name, grade, department)')
        .eq('coach_id', uid)
        .eq('status', 'active');

    final students = (relations as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final department = profile?['department'];
      return CoachStudent(
        relationshipId: row['id'] as String,
        studentId: row['student_id'] as String,
        name: profile?['name'] as String? ?? 'Öğrenci',
        grade: profile?['grade'] as String?,
        department: department is List ? department.join(', ') : department as String?,
      );
    }).toList();

    if (students.isEmpty) return students;

    // Bu koça ait tüm görevlerin durumlarını tek sorguda çekip öğrenci
    // bazında client-side grupluyoruz (N+1 sorgudan kaçınmak için).
    final taskRows = await _db
        .from('koc_tasks')
        .select('student_id, status')
        .eq('coach_id', uid);

    final counts = <String, Map<String, int>>{};
    for (final row in (taskRows as List)) {
      final studentId = row['student_id'] as String;
      final status = row['status'] as String;
      final c = counts.putIfAbsent(studentId, () => {'pending': 0, 'completed': 0, 'approved': 0, 'delayed': 0, 'total': 0});
      c[status] = (c[status] ?? 0) + 1;
      c['total'] = (c['total'] ?? 0) + 1;
    }

    return students.map((s) {
      final c = counts[s.studentId];
      if (c == null) return s;
      return s.copyWithTaskCounts(
        pendingApproval: c['completed'] ?? 0,
        delayed: c['delayed'] ?? 0,
        completedCount: (c['completed'] ?? 0) + (c['approved'] ?? 0),
        totalCount: c['total'] ?? 0,
      );
    }).toList();
  }

  /// Koçun, kendi tüm öğrencilerine atadığı görevleri (en yeniden en eskiye)
  /// öğrenci adıyla birlikte getirir — "Genel Bakış" canlı akışı için.
  static Future<List<KocGorev>> getRecentTasksForMyStudents({int limit = 15}) async {
    final uid = currentUserId;
    if (uid == null) return [];

    final rows = await _db
        .from('koc_tasks')
        .select('*, profiles!koc_tasks_student_id_fkey(name)')
        .eq('coach_id', uid)
        .order('task_date', ascending: false)
        .limit(limit);

    return (rows as List).map((row) {
      final profile = row['profiles'] as Map<String, dynamic>?;
      final json = Map<String, dynamic>.from(row);
      json['student_name'] = profile?['name'] as String? ?? 'Öğrenci';
      return KocGorev.fromJson(json);
    }).toList();
  }

  /// Belirli bir öğrenciye yeni bir ödev/görev atar (yalnızca koç çağırabilir;
  /// RLS aktif koç-öğrenci ilişkisi olmadan INSERT'e izin vermez).
  static Future<void> createCoachTask({
    required String studentId,
    required String subject,
    required String topic,
    String? coachNote,
    int? questionCount,
    int? durationMinutes,
    String? bookInfo,
    DateTime? taskDate,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Oturum açılmamış.');

    await _db.from('koc_tasks').insert({
      'student_id': studentId,
      'coach_id': uid,
      'subject': subject,
      'topic': topic,
      'coach_note': coachNote,
      'question_count': questionCount,
      'duration_minutes': durationMinutes,
      'book_info': bookInfo,
      'task_date': (taskDate ?? DateTime.now()).toIso8601String().split('T').first,
    });
  }

  /// Bir görevin durumunu günceller. Öğrenci yalnızca kendi görevini
  /// 'completed' yapabilir; koç 'approved'/'delayed' gibi durumlara da geçirebilir
  /// (RLS bu ayrımı sunucuda zaten zorunlu kılar).
  static Future<void> updateTaskStatus({required String taskId, required String status}) async {
    await _db.from('koc_tasks').update({'status': status}).eq('id', taskId);
  }

  /// Belirli bir öğrencinin, verilen tarih için atanmış görevlerini getirir.
  /// `studentId` kendisiyse (öğrenci) veya aktif koçuysa RLS erişime izin verir.
  static Future<List<KocGorev>> getTasksForStudent(String studentId, {DateTime? onDate}) async {
    var query = _db.from('koc_tasks').select().eq('student_id', studentId);
    if (onDate != null) {
      query = query.eq('task_date', onDate.toIso8601String().split('T').first);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List).map((json) => KocGorev.fromJson(json)).toList();
  }

  /// Bir öğrencinin bu haftaki (Pazartesi'den bugüne) çalışma oturumlarını getirir.
  /// Koç için: yalnızca aktif ilişkili öğrenci verisi RLS ile okunabilir.
  static Future<List<StudySession>> getStudentWeeklyStudySessions(String studentId) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));

    final rows = await _db
        .from('study_sessions')
        .select()
        .eq('user_id', studentId)
        .gte('started_at', startOfWeek.toIso8601String())
        .order('started_at', ascending: false);

    return (rows as List).map((json) => StudySession.fromJson(json)).toList();
  }

  /// Bir öğrencinin deneme sonuçlarını (en yeniden en eskiye) getirir.
  static Future<List<ExamResult>> getStudentExamHistory(String studentId, {int limit = 20}) async {
    final rows = await _db
        .from('exam_results')
        .select()
        .eq('user_id', studentId)
        .order('submitted_at', ascending: false)
        .limit(limit);

    return (rows as List).map((json) => ExamResult.fromJson(json)).toList();
  }
}

/// Bulut asistanı çağrısının başarısız olma nedeni (Edge Function `hata` alanı).
class AsistanHatasi implements Exception {
  /// 'no_consent' | 'limit' | 'busy' | 'unauthorized' | 'config' | 'upstream' | 'server' | 'network'
  final String kod;
  const AsistanHatasi(this.kod);

  @override
  String toString() => 'AsistanHatasi($kod)';
}

/// Koç asistanının bulut (Claude) yanıtları — bkz. supabase/functions/koc-asistan
/// ve supabase_migrations/16_koc_asistani.sql.
class AsistanBulutServisi {
  AsistanBulutServisi._();

  static SupabaseClient? get _db {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// (açık rıza verildi mi, bugün kalan mesaj hakkı). Ulaşılamazsa null.
  static Future<(bool onay, int kalan)?> durum() async {
    final db = _db;
    if (db == null || db.auth.currentUser == null) return null;
    try {
      final rows = await db.rpc('asistan_durum') as List;
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      return (r['onay'] == true, (r['kalan'] as num?)?.toInt() ?? 0);
    } catch (_) {
      return null;
    }
  }

  static Future<void> onayVer() async => _db?.rpc('asistan_onay_ver');

  static Future<void> onayGeriAl() async => _db?.rpc('asistan_onay_geri_al');

  /// Soruyu, öğrencinin çalışma özetini ve son sohbet turlarını gönderir;
  /// asistanın yanıt metnini döner. [kaynaklar] cihazdaki notlardan soruyla
  /// eşleşen kart/rehber metinleridir; yanıtın bunlara dayanması istenir.
  static Future<String> sor({
    required String mesaj,
    required Map<String, dynamic> baglam,
    required List<Map<String, String>> gecmis,
    List<String> kaynaklar = const [],
  }) async {
    final db = _db;
    if (db == null || db.auth.currentUser == null) throw const AsistanHatasi('unauthorized');
    try {
      final yanit = await db.functions.invoke('koc-asistan', body: {
        'mesaj': mesaj,
        'baglam': baglam,
        'gecmis': gecmis,
        if (kaynaklar.isNotEmpty) 'kaynaklar': kaynaklar,
      });
      final data = yanit.data;
      if (data is Map && data['yanit'] is String) return data['yanit'] as String;
      throw const AsistanHatasi('server');
    } on FunctionException catch (e) {
      final details = e.details;
      final kod = details is Map && details['hata'] is String ? details['hata'] as String : 'server';
      throw AsistanHatasi(kod);
    } on AsistanHatasi {
      rethrow;
    } catch (_) {
      throw const AsistanHatasi('network');
    }
  }
}

/// Bir denemenin topluluk genelindeki ders bazlı ortalama/standart sapması.
/// [MIN_KATILIMCI]'nın altındaki sonuçlar istatistiksel olarak güvenilir
/// sayılmaz; UI bu durumda "yetersiz veri" göstermelidir.
class ExamBenchmark {
  static const int minKatilimci = 5;

  final int katilimciSayisi;
  final double ortalamaNet;
  final double standartSapma;

  const ExamBenchmark({
    required this.katilimciSayisi,
    required this.ortalamaNet,
    required this.standartSapma,
  });

  bool get yeterliVeri => katilimciSayisi >= minKatilimci;

  /// Kullanıcının netinin topluluğa göre kaç standart sapma üstünde/altında
  /// olduğu (z-skoru). Standart sapma sıfırsa (herkes aynı neti yaptıysa) 0.
  double zSkoru(double kullaniciNeti) {
    if (standartSapma <= 0) return 0;
    return (kullaniciNeti - ortalamaNet) / standartSapma;
  }
}
