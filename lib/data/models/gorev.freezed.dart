// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gorev.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Gorev {

 String get id; String get baslik; String? get aciklama; String get tarih;// YYYY-MM-DD
 bool get tamamlandi; GorevOncelik get oncelik; String? get ders; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Gorev
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GorevCopyWith<Gorev> get copyWith => _$GorevCopyWithImpl<Gorev>(this as Gorev, _$identity);

  /// Serializes this Gorev to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gorev&&(identical(other.id, id) || other.id == id)&&(identical(other.baslik, baslik) || other.baslik == baslik)&&(identical(other.aciklama, aciklama) || other.aciklama == aciklama)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.tamamlandi, tamamlandi) || other.tamamlandi == tamamlandi)&&(identical(other.oncelik, oncelik) || other.oncelik == oncelik)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,baslik,aciklama,tarih,tamamlandi,oncelik,ders,createdAt,updatedAt);

@override
String toString() {
  return 'Gorev(id: $id, baslik: $baslik, aciklama: $aciklama, tarih: $tarih, tamamlandi: $tamamlandi, oncelik: $oncelik, ders: $ders, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GorevCopyWith<$Res>  {
  factory $GorevCopyWith(Gorev value, $Res Function(Gorev) _then) = _$GorevCopyWithImpl;
@useResult
$Res call({
 String id, String baslik, String? aciklama, String tarih, bool tamamlandi, GorevOncelik oncelik, String? ders, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$GorevCopyWithImpl<$Res>
    implements $GorevCopyWith<$Res> {
  _$GorevCopyWithImpl(this._self, this._then);

  final Gorev _self;
  final $Res Function(Gorev) _then;

/// Create a copy of Gorev
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? baslik = null,Object? aciklama = freezed,Object? tarih = null,Object? tamamlandi = null,Object? oncelik = null,Object? ders = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,aciklama: freezed == aciklama ? _self.aciklama : aciklama // ignore: cast_nullable_to_non_nullable
as String?,tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,oncelik: null == oncelik ? _self.oncelik : oncelik // ignore: cast_nullable_to_non_nullable
as GorevOncelik,ders: freezed == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Gorev].
extension GorevPatterns on Gorev {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gorev value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gorev() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gorev value)  $default,){
final _that = this;
switch (_that) {
case _Gorev():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gorev value)?  $default,){
final _that = this;
switch (_that) {
case _Gorev() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String baslik,  String? aciklama,  String tarih,  bool tamamlandi,  GorevOncelik oncelik,  String? ders,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gorev() when $default != null:
return $default(_that.id,_that.baslik,_that.aciklama,_that.tarih,_that.tamamlandi,_that.oncelik,_that.ders,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String baslik,  String? aciklama,  String tarih,  bool tamamlandi,  GorevOncelik oncelik,  String? ders,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Gorev():
return $default(_that.id,_that.baslik,_that.aciklama,_that.tarih,_that.tamamlandi,_that.oncelik,_that.ders,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String baslik,  String? aciklama,  String tarih,  bool tamamlandi,  GorevOncelik oncelik,  String? ders,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Gorev() when $default != null:
return $default(_that.id,_that.baslik,_that.aciklama,_that.tarih,_that.tamamlandi,_that.oncelik,_that.ders,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gorev extends Gorev {
  const _Gorev({required this.id, required this.baslik, this.aciklama, required this.tarih, this.tamamlandi = false, this.oncelik = GorevOncelik.orta, this.ders, required this.createdAt, required this.updatedAt}): super._();
  factory _Gorev.fromJson(Map<String, dynamic> json) => _$GorevFromJson(json);

@override final  String id;
@override final  String baslik;
@override final  String? aciklama;
@override final  String tarih;
// YYYY-MM-DD
@override@JsonKey() final  bool tamamlandi;
@override@JsonKey() final  GorevOncelik oncelik;
@override final  String? ders;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Gorev
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GorevCopyWith<_Gorev> get copyWith => __$GorevCopyWithImpl<_Gorev>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GorevToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gorev&&(identical(other.id, id) || other.id == id)&&(identical(other.baslik, baslik) || other.baslik == baslik)&&(identical(other.aciklama, aciklama) || other.aciklama == aciklama)&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.tamamlandi, tamamlandi) || other.tamamlandi == tamamlandi)&&(identical(other.oncelik, oncelik) || other.oncelik == oncelik)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,baslik,aciklama,tarih,tamamlandi,oncelik,ders,createdAt,updatedAt);

@override
String toString() {
  return 'Gorev(id: $id, baslik: $baslik, aciklama: $aciklama, tarih: $tarih, tamamlandi: $tamamlandi, oncelik: $oncelik, ders: $ders, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GorevCopyWith<$Res> implements $GorevCopyWith<$Res> {
  factory _$GorevCopyWith(_Gorev value, $Res Function(_Gorev) _then) = __$GorevCopyWithImpl;
@override @useResult
$Res call({
 String id, String baslik, String? aciklama, String tarih, bool tamamlandi, GorevOncelik oncelik, String? ders, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$GorevCopyWithImpl<$Res>
    implements _$GorevCopyWith<$Res> {
  __$GorevCopyWithImpl(this._self, this._then);

  final _Gorev _self;
  final $Res Function(_Gorev) _then;

/// Create a copy of Gorev
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? baslik = null,Object? aciklama = freezed,Object? tarih = null,Object? tamamlandi = null,Object? oncelik = null,Object? ders = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Gorev(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,aciklama: freezed == aciklama ? _self.aciklama : aciklama // ignore: cast_nullable_to_non_nullable
as String?,tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,oncelik: null == oncelik ? _self.oncelik : oncelik // ignore: cast_nullable_to_non_nullable
as GorevOncelik,ders: freezed == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
