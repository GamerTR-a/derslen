// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_blok.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanBlok {

 String get id; String get konu; String? get ders; int get sure;// dakika
 PlanBlokTip get tip; bool get tamamlandi; String? get renk; String? get saat;// HH:MM format
 DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of PlanBlok
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanBlokCopyWith<PlanBlok> get copyWith => _$PlanBlokCopyWithImpl<PlanBlok>(this as PlanBlok, _$identity);

  /// Serializes this PlanBlok to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanBlok&&(identical(other.id, id) || other.id == id)&&(identical(other.konu, konu) || other.konu == konu)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.sure, sure) || other.sure == sure)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.tamamlandi, tamamlandi) || other.tamamlandi == tamamlandi)&&(identical(other.renk, renk) || other.renk == renk)&&(identical(other.saat, saat) || other.saat == saat)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,konu,ders,sure,tip,tamamlandi,renk,saat,createdAt,updatedAt);

@override
String toString() {
  return 'PlanBlok(id: $id, konu: $konu, ders: $ders, sure: $sure, tip: $tip, tamamlandi: $tamamlandi, renk: $renk, saat: $saat, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PlanBlokCopyWith<$Res>  {
  factory $PlanBlokCopyWith(PlanBlok value, $Res Function(PlanBlok) _then) = _$PlanBlokCopyWithImpl;
@useResult
$Res call({
 String id, String konu, String? ders, int sure, PlanBlokTip tip, bool tamamlandi, String? renk, String? saat, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$PlanBlokCopyWithImpl<$Res>
    implements $PlanBlokCopyWith<$Res> {
  _$PlanBlokCopyWithImpl(this._self, this._then);

  final PlanBlok _self;
  final $Res Function(PlanBlok) _then;

/// Create a copy of PlanBlok
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? konu = null,Object? ders = freezed,Object? sure = null,Object? tip = null,Object? tamamlandi = null,Object? renk = freezed,Object? saat = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,konu: null == konu ? _self.konu : konu // ignore: cast_nullable_to_non_nullable
as String,ders: freezed == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String?,sure: null == sure ? _self.sure : sure // ignore: cast_nullable_to_non_nullable
as int,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as PlanBlokTip,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,renk: freezed == renk ? _self.renk : renk // ignore: cast_nullable_to_non_nullable
as String?,saat: freezed == saat ? _self.saat : saat // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanBlok].
extension PlanBlokPatterns on PlanBlok {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanBlok value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanBlok() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanBlok value)  $default,){
final _that = this;
switch (_that) {
case _PlanBlok():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanBlok value)?  $default,){
final _that = this;
switch (_that) {
case _PlanBlok() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String konu,  String? ders,  int sure,  PlanBlokTip tip,  bool tamamlandi,  String? renk,  String? saat,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanBlok() when $default != null:
return $default(_that.id,_that.konu,_that.ders,_that.sure,_that.tip,_that.tamamlandi,_that.renk,_that.saat,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String konu,  String? ders,  int sure,  PlanBlokTip tip,  bool tamamlandi,  String? renk,  String? saat,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PlanBlok():
return $default(_that.id,_that.konu,_that.ders,_that.sure,_that.tip,_that.tamamlandi,_that.renk,_that.saat,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String konu,  String? ders,  int sure,  PlanBlokTip tip,  bool tamamlandi,  String? renk,  String? saat,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PlanBlok() when $default != null:
return $default(_that.id,_that.konu,_that.ders,_that.sure,_that.tip,_that.tamamlandi,_that.renk,_that.saat,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanBlok extends PlanBlok {
  const _PlanBlok({required this.id, required this.konu, this.ders, required this.sure, this.tip = PlanBlokTip.calisma, this.tamamlandi = false, this.renk, this.saat, required this.createdAt, required this.updatedAt}): super._();
  factory _PlanBlok.fromJson(Map<String, dynamic> json) => _$PlanBlokFromJson(json);

@override final  String id;
@override final  String konu;
@override final  String? ders;
@override final  int sure;
// dakika
@override@JsonKey() final  PlanBlokTip tip;
@override@JsonKey() final  bool tamamlandi;
@override final  String? renk;
@override final  String? saat;
// HH:MM format
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of PlanBlok
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanBlokCopyWith<_PlanBlok> get copyWith => __$PlanBlokCopyWithImpl<_PlanBlok>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanBlokToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanBlok&&(identical(other.id, id) || other.id == id)&&(identical(other.konu, konu) || other.konu == konu)&&(identical(other.ders, ders) || other.ders == ders)&&(identical(other.sure, sure) || other.sure == sure)&&(identical(other.tip, tip) || other.tip == tip)&&(identical(other.tamamlandi, tamamlandi) || other.tamamlandi == tamamlandi)&&(identical(other.renk, renk) || other.renk == renk)&&(identical(other.saat, saat) || other.saat == saat)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,konu,ders,sure,tip,tamamlandi,renk,saat,createdAt,updatedAt);

@override
String toString() {
  return 'PlanBlok(id: $id, konu: $konu, ders: $ders, sure: $sure, tip: $tip, tamamlandi: $tamamlandi, renk: $renk, saat: $saat, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PlanBlokCopyWith<$Res> implements $PlanBlokCopyWith<$Res> {
  factory _$PlanBlokCopyWith(_PlanBlok value, $Res Function(_PlanBlok) _then) = __$PlanBlokCopyWithImpl;
@override @useResult
$Res call({
 String id, String konu, String? ders, int sure, PlanBlokTip tip, bool tamamlandi, String? renk, String? saat, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$PlanBlokCopyWithImpl<$Res>
    implements _$PlanBlokCopyWith<$Res> {
  __$PlanBlokCopyWithImpl(this._self, this._then);

  final _PlanBlok _self;
  final $Res Function(_PlanBlok) _then;

/// Create a copy of PlanBlok
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? konu = null,Object? ders = freezed,Object? sure = null,Object? tip = null,Object? tamamlandi = null,Object? renk = freezed,Object? saat = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PlanBlok(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,konu: null == konu ? _self.konu : konu // ignore: cast_nullable_to_non_nullable
as String,ders: freezed == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String?,sure: null == sure ? _self.sure : sure // ignore: cast_nullable_to_non_nullable
as int,tip: null == tip ? _self.tip : tip // ignore: cast_nullable_to_non_nullable
as PlanBlokTip,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,renk: freezed == renk ? _self.renk : renk // ignore: cast_nullable_to_non_nullable
as String?,saat: freezed == saat ? _self.saat : saat // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
