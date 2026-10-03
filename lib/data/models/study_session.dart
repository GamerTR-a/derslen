/// Çalışma Oturumu Modeli — sunucu tarafında doğrulanan pomodoro/odak
/// oturumları. `public.study_sessions` tablosuna karşılık gelir.
library;

class StudySession {
  final String id;
  final String label;
  final int plannedMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? actualMinutes;
  final int starsAwarded;
  final bool interrupted;

  const StudySession({
    required this.id,
    required this.label,
    required this.plannedMinutes,
    required this.startedAt,
    this.endedAt,
    this.actualMinutes,
    this.starsAwarded = 0,
    this.interrupted = false,
  });

  bool get tamamlandi => endedAt != null;

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        label: json['label'] as String,
        plannedMinutes: (json['planned_minutes'] as num).toInt(),
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at'] as String) : null,
        actualMinutes: (json['actual_minutes'] as num?)?.toInt(),
        starsAwarded: (json['stars_awarded'] as num?)?.toInt() ?? 0,
        interrupted: json['interrupted'] as bool? ?? false,
      );
}
