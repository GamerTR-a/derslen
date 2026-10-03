class Community {
  final int id;
  final String name;
  final String? logoPath;
  final String category;
  final double score;
  final int memberCount;
  final String? description;
  final String? chairmanName;
  final String? chairmanId;
  final DateTime createdAt;

  const Community({
    required this.id,
    required this.name,
    this.logoPath,
    required this.category,
    this.score = 0.0,
    this.memberCount = 0,
    this.description,
    this.chairmanName,
    this.chairmanId,
    required this.createdAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      logoPath: json['logo_path'] as String?,
      category: json['category'] as String? ?? 'Genel',
      score: json['score'] != null ? (json['score'] as num).toDouble() : 0.0,
      memberCount: json['member_count'] != null ? (json['member_count'] as num).toInt() : 0,
      description: json['description'] as String?,
      chairmanName: json['chairman_name'] as String?,
      chairmanId: json['chairman_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_path': logoPath,
      'category': category,
      'score': score,
      'member_count': memberCount,
      'description': description,
      'chairman_name': chairmanName,
      'chairman_id': chairmanId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
