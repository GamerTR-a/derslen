/// Görev Modeli
library;

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/app_constants.dart';

part 'gorev.freezed.dart';
part 'gorev.g.dart';

@freezed
abstract class Gorev with _$Gorev {
  const factory Gorev({
    required String id,
    required String baslik,
    String? aciklama,
    required String tarih, // YYYY-MM-DD
    @Default(false) bool tamamlandi,
    @Default(GorevOncelik.orta) GorevOncelik oncelik,
    String? ders,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Gorev;

  factory Gorev.fromJson(Map<String, dynamic> json) => _$GorevFromJson(json);

  const Gorev._();

  /// Öncelik etiketi
  String get oncelikEtiketi {
    switch (oncelik) {
      case GorevOncelik.dusuk:
        return 'Düşük';
      case GorevOncelik.orta:
        return 'Orta';
      case GorevOncelik.yuksek:
        return 'Yüksek';
    }
  }

  /// Öncelik rengi
  int get oncelikRenk {
    switch (oncelik) {
      case GorevOncelik.dusuk:
        return 0xFF10B981; // green
      case GorevOncelik.orta:
        return 0xFFF59E0B; // amber
      case GorevOncelik.yuksek:
        return 0xFFEF4444; // red
    }
  }

  /// Bugünkü görev mi?
  bool get isToday {
    final today = DateTime.now();
    final taskDate = DateTime.parse(tarih);
    return taskDate.year == today.year &&
        taskDate.month == today.month &&
        taskDate.day == today.day;
  }

  /// Geçmiş bir görev mi?
  bool get isPast {
    final today = DateTime.now();
    final taskDate = DateTime.parse(tarih);
    return taskDate.isBefore(DateTime(today.year, today.month, today.day));
  }
}