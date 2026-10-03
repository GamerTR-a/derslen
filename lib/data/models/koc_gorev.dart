import 'package:flutter/material.dart';

enum GorevDurumu { pending, completed, approved, delayed }

class KocGorev {
  final String id;
  final String studentId;
  final String coachId;
  final String studentName;
  final String gradeClass; // e.g. "12. Sınıf"
  final String branch;     // e.g. "Eşit Ağırlık"
  final String subject;    // e.g. "Tarih", "Matematik"
  final String topic;      // e.g. "Kurtuluş Savaşı"
  final String? coachNote; // e.g. "Kronolojiye dikkat et, tarih sıralaması soruluyor."
  final int? questionCount;// e.g. 30
  final int? durationMinutes; // e.g. 45
  final String? bookInfo;  // e.g. "AYT Matematik Soru Bankası sf 42-58"
  final DateTime taskDate;
  final GorevDurumu status;
  final DateTime createdAt;

  const KocGorev({
    required this.id,
    required this.studentId,
    required this.coachId,
    required this.studentName,
    this.gradeClass = '12. Sınıf',
    this.branch = 'Eşit Ağırlık',
    required this.subject,
    required this.topic,
    this.coachNote,
    this.questionCount,
    this.durationMinutes,
    this.bookInfo,
    required this.taskDate,
    this.status = GorevDurumu.pending,
    required this.createdAt,
  });

  bool get isApproved => status == GorevDurumu.approved;
  bool get isCompleted => status == GorevDurumu.completed || isApproved;
  bool get isDelayed => status == GorevDurumu.delayed;

  Color get subjectColor {
    switch (subject.toLowerCase()) {
      case 'matematik':
      case 'geometri':
        return const Color(0xFFE5B842);
      case 'fizik':
      case 'kimya':
      case 'biyoloji':
        return const Color(0xFF4CAF50);
      case 'tarih':
      case 'coğrafya':
      case 'edebiyat':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  factory KocGorev.fromJson(Map<String, dynamic> json) {
    GorevDurumu parseStatus(String? s) {
      switch (s) {
        case 'completed': return GorevDurumu.completed;
        case 'approved': return GorevDurumu.approved;
        case 'delayed': return GorevDurumu.delayed;
        default: return GorevDurumu.pending;
      }
    }

    return KocGorev(
      id: json['id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      coachId: json['coach_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? 'Öğrenci',
      gradeClass: json['grade_class'] as String? ?? '12. Sınıf',
      branch: json['branch'] as String? ?? 'Eşit Ağırlık',
      subject: json['subject'] as String? ?? 'Genel',
      topic: json['topic'] as String? ?? '',
      coachNote: json['coach_note'] as String?,
      questionCount: json['question_count'] != null ? (json['question_count'] as num).toInt() : null,
      durationMinutes: json['duration_minutes'] != null ? (json['duration_minutes'] as num).toInt() : null,
      bookInfo: json['book_info'] as String?,
      taskDate: json['task_date'] != null
          ? DateTime.parse(json['task_date'] as String)
          : DateTime.now(),
      status: parseStatus(json['status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'coach_id': coachId,
      'student_name': studentName,
      'grade_class': gradeClass,
      'branch': branch,
      'subject': subject,
      'topic': topic,
      'coach_note': coachNote,
      'question_count': questionCount,
      'duration_minutes': durationMinutes,
      'book_info': bookInfo,
      'task_date': taskDate.toIso8601String(),
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  KocGorev copyWith({
    String? id,
    String? studentId,
    String? coachId,
    String? studentName,
    String? gradeClass,
    String? branch,
    String? subject,
    String? topic,
    String? coachNote,
    int? questionCount,
    int? durationMinutes,
    String? bookInfo,
    DateTime? taskDate,
    GorevDurumu? status,
    DateTime? createdAt,
  }) {
    return KocGorev(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      coachId: coachId ?? this.coachId,
      studentName: studentName ?? this.studentName,
      gradeClass: gradeClass ?? this.gradeClass,
      branch: branch ?? this.branch,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      coachNote: coachNote ?? this.coachNote,
      questionCount: questionCount ?? this.questionCount,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bookInfo: bookInfo ?? this.bookInfo,
      taskDate: taskDate ?? this.taskDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
