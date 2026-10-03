/// Deneme Sonucu Modeli — `public.exam_results` tablosuna karşılık gelir.
/// Öğrencinin kendi deneme netlerini gönderdiği (`submit_exam_result` RPC)
/// ve koçun (aktif ilişkili öğrencisi için) okuyabildiği satırlar.
library;

class ExamResult {
  final String id;
  final String denemeAdi;
  final String alan; // 'TYT' | 'AYT'
  final String ders;
  final int dogru;
  final int yanlis;
  final int bos;
  final double net;
  final DateTime submittedAt;

  const ExamResult({
    required this.id,
    required this.denemeAdi,
    required this.alan,
    required this.ders,
    required this.dogru,
    required this.yanlis,
    required this.bos,
    required this.net,
    required this.submittedAt,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
        id: json['id'] as String,
        denemeAdi: json['deneme_adi'] as String,
        alan: json['alan'] as String,
        ders: json['ders'] as String,
        dogru: (json['dogru'] as num).toInt(),
        yanlis: (json['yanlis'] as num).toInt(),
        bos: (json['bos'] as num).toInt(),
        net: (json['net'] as num).toDouble(),
        submittedAt: DateTime.parse(json['submitted_at'] as String),
      );
}
