// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'net_kaydi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NetKaydi {

 String get id; String get tarih;// YYYY-MM-DD
 SinavAlani get alan; String get ders; int get dogru; int get yanlis; int get bos; String? get denemeAdi; DateTime get createdAt;
/// Create a copy of NetKaydi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NetKaydiCopyWith<NetKaydi> get copyWith => _$NetKaydiCopyWithImpl<NetKaydi>(this as NetKaydi, _$identity);

  /// Serializes this NetKaydi to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NetKaydi&&(identical(other.id, id) || other.id == id)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.alan, alan) || other.alan == alan)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.dogru, dogru) || other.dogru == dogru)&&(identical(other.yanlis, yanlis) || other.yanlis == yanlis)&&(identical(other.bos, bos) || other.bos == bos)&&(identical(other.denemeAdi, denemeAdi) || other.denemeAdi == denemeAdi)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tarih,alan,ders,dogru,yanlis,bos,denemeAdi,createdAt);

@override
String toString() {
  return 'NetKaydi(id: $id, tarih: $tarih, alan: $alan, ders: $ders, dogru: $dogru, yanlis: $yanlis, bos: $bos, denemeAdi: $denemeAdi, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $NetKaydiCopyWith<$Res>  {
  factory $NetKaydiCopyWith(NetKaydi value, $Res Function(NetKaydi) _then) = _$NetKaydiCopyWithImpl;
@useResult
$Res call({
 String id, String tarih, SinavAlani alan, String ders, int dogru, int yanlis, int bos, String? denemeAdi, DateTime createdAt
});




}
/// @nodoc
class _$NetKaydiCopyWithImpl<$Res>
    implements $NetKaydiCopyWith<$Res> {
  _$NetKaydiCopyWithImpl(this._self, this._then);

  final NetKaydi _self;
  final $Res Function(NetKaydi) _then;

/// Create a copy of NetKaydi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tarih = null,Object? alan = null,Object? ders = null,Object? dogru = null,Object? yanlis = null,Object? bos = null,Object? denemeAdi = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,alan: null == alan ? _self.alan : alan // ignore: cast_nullable_to_non_nullable
as SinavAlani,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,dogru: null == dogru ? _self.dogru : dogru // ignore: cast_nullable_to_non_nullable
as int,yanlis: null == yanlis ? _self.yanlis : yanlis // ignore: cast_nullable_to_non_nullable
as int,bos: null == bos ? _self.bos : bos // ignore: cast_nullable_to_non_nullable
as int,denemeAdi: freezed == denemeAdi ? _self.denemeAdi : denemeAdi // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NetKaydi].
extension NetKaydiPatterns on NetKaydi {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NetKaydi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NetKaydi() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NetKaydi value)  $default,){
final _that = this;
switch (_that) {
case _NetKaydi():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NetKaydi value)?  $default,){
final _that = this;
switch (_that) {
case _NetKaydi() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tarih,  SinavAlani alan,  String ders,  int dogru,  int yanlis,  int bos,  String? denemeAdi,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NetKaydi() when $default != null:
return $default(_that.id,_that.tarih,_that.alan,_that.ders,_that.dogru,_that.yanlis,_that.bos,_that.denemeAdi,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tarih,  SinavAlani alan,  String ders,  int dogru,  int yanlis,  int bos,  String? denemeAdi,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _NetKaydi():
return $default(_that.id,_that.tarih,_that.alan,_that.ders,_that.dogru,_that.yanlis,_that.bos,_that.denemeAdi,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tarih,  SinavAlani alan,  String ders,  int dogru,  int yanlis,  int bos,  String? denemeAdi,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _NetKaydi() when $default != null:
return $default(_that.id,_that.tarih,_that.alan,_that.ders,_that.dogru,_that.yanlis,_that.bos,_that.denemeAdi,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NetKaydi extends NetKaydi {
  const _NetKaydi({required this.id, required this.tarih, required this.alan, required this.ders, this.dogru = 0, this.yanlis = 0, this.bos = 0, this.denemeAdi, required this.createdAt}): super._();
  factory _NetKaydi.fromJson(Map<String, dynamic> json) => _$NetKaydiFromJson(json);

@override final  String id;
@override final  String tarih;
// YYYY-MM-DD
@override final  SinavAlani alan;
@override final  String ders;
@override@JsonKey() final  int dogru;
@override@JsonKey() final  int yanlis;
@override@JsonKey() final  int bos;
@override final  String? denemeAdi;
@override final  DateTime createdAt;

/// Create a copy of NetKaydi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NetKaydiCopyWith<_NetKaydi> get copyWith => __$NetKaydiCopyWithImpl<_NetKaydi>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NetKaydiToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NetKaydi&&(identical(other.id, id) || other.id == id)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.alan, alan) || other.alan == alan)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.dogru, dogru) || other.dogru == dogru)&&(identical(other.yanlis, yanlis) || other.yanlis == yanlis)&&(identical(other.bos, bos) || other.bos == bos)&&(identical(other.denemeAdi, denemeAdi) || other.denemeAdi == denemeAdi)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tarih,alan,ders,dogru,yanlis,bos,denemeAdi,createdAt);

@override
String toString() {
  return 'NetKaydi(id: $id, tarih: $tarih, alan: $alan, ders: $ders, dogru: $dogru, yanlis: $yanlis, bos: $bos, denemeAdi: $denemeAdi, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NetKaydiCopyWith<$Res> implements $NetKaydiCopyWith<$Res> {
  factory _$NetKaydiCopyWith(_NetKaydi value, $Res Function(_NetKaydi) _then) = __$NetKaydiCopyWithImpl;
@override @useResult
$Res call({
 String id, String tarih, SinavAlani alan, String ders, int dogru, int yanlis, int bos, String? denemeAdi, DateTime createdAt
});




}
/// @nodoc
class __$NetKaydiCopyWithImpl<$Res>
    implements _$NetKaydiCopyWith<$Res> {
  __$NetKaydiCopyWithImpl(this._self, this._then);

  final _NetKaydi _self;
  final $Res Function(_NetKaydi) _then;

/// Create a copy of NetKaydi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tarih = null,Object? alan = null,Object? ders = null,Object? dogru = null,Object? yanlis = null,Object? bos = null,Object? denemeAdi = freezed,Object? createdAt = null,}) {
  return _then(_NetKaydi(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,alan: null == alan ? _self.alan : alan // ignore: cast_nullable_to_non_nullable
as SinavAlani,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,dogru: null == dogru ? _self.dogru : dogru // ignore: cast_nullable_to_non_nullable
as int,yanlis: null == yanlis ? _self.yanlis : yanlis // ignore: cast_nullable_to_non_nullable
as int,bos: null == bos ? _self.bos : bos // ignore: cast_nullable_to_non_nullable
as int,denemeAdi: freezed == denemeAdi ? _self.denemeAdi : denemeAdi // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
