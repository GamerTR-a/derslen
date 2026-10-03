/// Bir topluluğun haftalık çalışma sıralamasındaki tek bir satır.
/// `get_community_leaderboard` RPC'sinin döndürdüğü veriye karşılık gelir.
library;

class LeaderboardEntry {
  final String userId;
  final String name;
  final String? profilePhoto;
  final int totalMinutes;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    this.profilePhoto,
    required this.totalMinutes,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        userId: json['user_id'] as String,
        name: json['name'] as String? ?? 'Öğrenci',
        profilePhoto: json['profile_photo'] as String?,
        totalMinutes: (json['total_minutes'] as num?)?.toInt() ?? 0,
      );
}
