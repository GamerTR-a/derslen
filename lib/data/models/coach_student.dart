/// Bir koçun öğrenci listesindeki tek bir satır — `public.coach_students`
/// (aktif ilişki) ile `public.profiles` join'inin istemci tarafında
/// birleştirilmiş hali. Ayrıca o öğrenciye ait `koc_tasks` özet sayaçlarını
/// (bekleyen onay / geciken / tamamlanan) taşır.
library;

class CoachStudent {
  final String relationshipId; // coach_students.id
  final String studentId; // profiles.id
  final String name;
  final String? grade;
  final String? department;
  final int pendingApproval;
  final int delayed;
  final int completedCount;
  final int totalCount;

  const CoachStudent({
    required this.relationshipId,
    required this.studentId,
    required this.name,
    this.grade,
    this.department,
    this.pendingApproval = 0,
    this.delayed = 0,
    this.completedCount = 0,
    this.totalCount = 0,
  });

  CoachStudent copyWithTaskCounts({
    required int pendingApproval,
    required int delayed,
    required int completedCount,
    required int totalCount,
  }) {
    return CoachStudent(
      relationshipId: relationshipId,
      studentId: studentId,
      name: name,
      grade: grade,
      department: department,
      pendingApproval: pendingApproval,
      delayed: delayed,
      completedCount: completedCount,
      totalCount: totalCount,
    );
  }
}
