// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gunluk_checkin.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GunlukCheckin {

 String get tarih;// YYYY-MM-DD
 int get enerji;// 1-5
 int get odak;// 1-5
 int get stres;// 1-5
 DateTime get createdAt;
/// Create a copy of GunlukCheckin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GunlukCheckinCopyWith<GunlukCheckin> get copyWith => _$GunlukCheckinCopyWithImpl<GunlukCheckin>(this as GunlukCheckin, _$identity);

  /// Serializes this GunlukCheckin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GunlukCheckin&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.enerji, enerji) || other.enerji == enerji)&&(identical(other.odak, odak) || other.odak == odak)&&(identical(other.stres, stres) || other.stres == stres)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tarih,enerji,odak,stres,createdAt);

@override
String toString() {
  return 'GunlukCheckin(tarih: $tarih, enerji: $enerji, odak: $odak, stres: $stres, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $GunlukCheckinCopyWith<$Res>  {
  factory $GunlukCheckinCopyWith(GunlukCheckin value, $Res Function(GunlukCheckin) _then) = _$GunlukCheckinCopyWithImpl;
@useResult
$Res call({
 String tarih, int enerji, int odak, int stres, DateTime createdAt
});




}
/// @nodoc
class _$GunlukCheckinCopyWithImpl<$Res>
    implements $GunlukCheckinCopyWith<$Res> {
  _$GunlukCheckinCopyWithImpl(this._self, this._then);

  final GunlukCheckin _self;
  final $Res Function(GunlukCheckin) _then;

/// Create a copy of GunlukCheckin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tarih = null,Object? enerji = null,Object? odak = null,Object? stres = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,enerji: null == enerji ? _self.enerji : enerji // ignore: cast_nullable_to_non_nullable
as int,odak: null == odak ? _self.odak : odak // ignore: cast_nullable_to_non_nullable
as int,stres: null == stres ? _self.stres : stres // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GunlukCheckin].
extension GunlukCheckinPatterns on GunlukCheckin {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GunlukCheckin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GunlukCheckin() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GunlukCheckin value)  $default,){
final _that = this;
switch (_that) {
case _GunlukCheckin():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GunlukCheckin value)?  $default,){
final _that = this;
switch (_that) {
case _GunlukCheckin() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tarih,  int enerji,  int odak,  int stres,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GunlukCheckin() when $default != null:
return $default(_that.tarih,_that.enerji,_that.odak,_that.stres,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tarih,  int enerji,  int odak,  int stres,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _GunlukCheckin():
return $default(_that.tarih,_that.enerji,_that.odak,_that.stres,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tarih,  int enerji,  int odak,  int stres,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _GunlukCheckin() when $default != null:
return $default(_that.tarih,_that.enerji,_that.odak,_that.stres,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GunlukCheckin extends GunlukCheckin {
  const _GunlukCheckin({required this.tarih, required this.enerji, required this.odak, required this.stres, required this.createdAt}): super._();
  factory _GunlukCheckin.fromJson(Map<String, dynamic> json) => _$GunlukCheckinFromJson(json);

@override final  String tarih;
// YYYY-MM-DD
@override final  int enerji;
// 1-5
@override final  int odak;
// 1-5
@override final  int stres;
// 1-5
@override final  DateTime createdAt;

/// Create a copy of GunlukCheckin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GunlukCheckinCopyWith<_GunlukCheckin> get copyWith => __$GunlukCheckinCopyWithImpl<_GunlukCheckin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GunlukCheckinToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GunlukCheckin&&(identical(other.tarih, tarih) || other.tarih == tarih)&&(identical(other.enerji, enerji) || other.enerji == enerji)&&(identical(other.odak, odak) || other.odak == odak)&&(identical(other.stres, stres) || other.stres == stres)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tarih,enerji,odak,stres,createdAt);

@override
String toString() {
  return 'GunlukCheckin(tarih: $tarih, enerji: $enerji, odak: $odak, stres: $stres, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$GunlukCheckinCopyWith<$Res> implements $GunlukCheckinCopyWith<$Res> {
  factory _$GunlukCheckinCopyWith(_GunlukCheckin value, $Res Function(_GunlukCheckin) _then) = __$GunlukCheckinCopyWithImpl;
@override @useResult
$Res call({
 String tarih, int enerji, int odak, int stres, DateTime createdAt
});




}
/// @nodoc
class __$GunlukCheckinCopyWithImpl<$Res>
    implements _$GunlukCheckinCopyWith<$Res> {
  __$GunlukCheckinCopyWithImpl(this._self, this._then);

  final _GunlukCheckin _self;
  final $Res Function(_GunlukCheckin) _then;

/// Create a copy of GunlukCheckin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tarih = null,Object? enerji = null,Object? odak = null,Object? stres = null,Object? createdAt = null,}) {
  return _then(_GunlukCheckin(
tarih: null == tarih ? _self.tarih : tarih // ignore: cast_nullable_to_non_nullable
as String,enerji: null == enerji ? _self.enerji : enerji // ignore: cast_nullable_to_non_nullable
as int,odak: null == odak ? _self.odak : odak // ignore: cast_nullable_to_non_nullable
as int,stres: null == stres ? _self.stres : stres // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
