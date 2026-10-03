class Post {
  final int id;
  final int? communityId;
  final String communityName;
  final String? communityLogo;
  final String? userId;
  final String content;
  final String? imageUrl;
  final int supportCount;
  final double qualityScore;
  final DateTime createdAt;

  const Post({
    required this.id,
    this.communityId,
    required this.communityName,
    this.communityLogo,
    this.userId,
    required this.content,
    this.imageUrl,
    this.supportCount = 0,
    this.qualityScore = 0.0,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: (json['id'] as num).toInt(),
      communityId: json['community_id'] != null ? (json['community_id'] as num).toInt() : null,
      communityName: json['community_name'] as String? ?? 'DersNet Topluluğu',
      communityLogo: json['community_logo'] as String?,
      userId: json['user_id'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      supportCount: json['support_count'] != null ? (json['support_count'] as num).toInt() : 0,
      qualityScore: json['quality_score'] != null ? (json['quality_score'] as num).toDouble() : 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'community_name': communityName,
      'community_logo': communityLogo,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'support_count': supportCount,
      'quality_score': qualityScore,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
