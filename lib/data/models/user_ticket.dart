class UserTicket {
  final String id;
  final String userId;
  final String type; // 'complaint', 'request', 'suggestion'
  final String subject;
  final String description;
  final String status; // 'open', 'in_progress', 'resolved', 'closed'
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserTicket({
    required this.id,
    required this.userId,
    required this.type,
    required this.subject,
    required this.description,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> validTypes = ['complaint', 'request', 'suggestion'];
  static const List<String> validStatuses = ['open', 'in_progress', 'resolved', 'closed'];

  factory UserTicket.fromJson(Map<String, dynamic> json) {
    return UserTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'request',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      adminNotes: json['admin_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'subject': subject,
      'description': description,
      'status': status,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'complaint':
        return 'Şikayet';
      case 'suggestion':
        return 'Öneri';
      case 'request':
      default:
        return 'Talep';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'İşlemde';
      case 'resolved':
        return 'Çözüldü';
      case 'closed':
        return 'Kapalı';
      case 'open':
      default:
        return 'Açık';
    }
  }
}
