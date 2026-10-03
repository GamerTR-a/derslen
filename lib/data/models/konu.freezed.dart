// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'konu.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Konu {

 String get id; String get ders; SinavAlani get alan; String get baslik; bool get tamamlandi; bool get zayif;
/// Create a copy of Konu
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KonuCopyWith<Konu> get copyWith => _$KonuCopyWithImpl<Konu>(this as Konu, _$identity);

  /// Serializes this Konu to a JSON map.
  Map<String, dynamic> toJson();




@override
String toString() {
  return 'Konu(id: $id, ders: $ders, alan: $alan, baslik: $baslik, tamamlandi: $tamamlandi, zayif: $zayif)';
}


}

/// @nodoc
abstract mixin class $KonuCopyWith<$Res>  {
  factory $KonuCopyWith(Konu value, $Res Function(Konu) _then) = _$KonuCopyWithImpl;
@useResult
$Res call({
 String id, String ders, SinavAlani alan, String baslik, bool tamamlandi, bool zayif
});




}
/// @nodoc
class _$KonuCopyWithImpl<$Res>
    implements $KonuCopyWith<$Res> {
  _$KonuCopyWithImpl(this._self, this._then);

  final Konu _self;
  final $Res Function(Konu) _then;

/// Create a copy of Konu
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ders = null,Object? alan = null,Object? baslik = null,Object? tamamlandi = null,Object? zayif = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,alan: null == alan ? _self.alan : alan // ignore: cast_nullable_to_non_nullable
as SinavAlani,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,zayif: null == zayif ? _self.zayif : zayif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Konu].
extension KonuPatterns on Konu {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Konu value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Konu() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Konu value)  $default,){
final _that = this;
switch (_that) {
case _Konu():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Konu value)?  $default,){
final _that = this;
switch (_that) {
case _Konu() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ders,  SinavAlani alan,  String baslik,  bool tamamlandi,  bool zayif)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Konu() when $default != null:
return $default(_that.id,_that.ders,_that.alan,_that.baslik,_that.tamamlandi,_that.zayif);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ders,  SinavAlani alan,  String baslik,  bool tamamlandi,  bool zayif)  $default,) {final _that = this;
switch (_that) {
case _Konu():
return $default(_that.id,_that.ders,_that.alan,_that.baslik,_that.tamamlandi,_that.zayif);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ders,  SinavAlani alan,  String baslik,  bool tamamlandi,  bool zayif)?  $default,) {final _that = this;
switch (_that) {
case _Konu() when $default != null:
return $default(_that.id,_that.ders,_that.alan,_that.baslik,_that.tamamlandi,_that.zayif);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Konu extends Konu {
  const _Konu({required this.id, required this.ders, required this.alan, required this.baslik, this.tamamlandi = false, this.zayif = false}): super._();
  factory _Konu.fromJson(Map<String, dynamic> json) => _$KonuFromJson(json);

@override final  String id;
@override final  String ders;
@override final  SinavAlani alan;
@override final  String baslik;
@override@JsonKey() final  bool tamamlandi;
@override@JsonKey() final  bool zayif;

/// Create a copy of Konu
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KonuCopyWith<_Konu> get copyWith => __$KonuCopyWithImpl<_Konu>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KonuToJson(this, );
}



@override
String toString() {
  return 'Konu(id: $id, ders: $ders, alan: $alan, baslik: $baslik, tamamlandi: $tamamlandi, zayif: $zayif)';
}


}

/// @nodoc
abstract mixin class _$KonuCopyWith<$Res> implements $KonuCopyWith<$Res> {
  factory _$KonuCopyWith(_Konu value, $Res Function(_Konu) _then) = __$KonuCopyWithImpl;
@override @useResult
$Res call({
 String id, String ders, SinavAlani alan, String baslik, bool tamamlandi, bool zayif
});




}
/// @nodoc
class __$KonuCopyWithImpl<$Res>
    implements _$KonuCopyWith<$Res> {
  __$KonuCopyWithImpl(this._self, this._then);

  final _Konu _self;
  final $Res Function(_Konu) _then;

/// Create a copy of Konu
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ders = null,Object? alan = null,Object? baslik = null,Object? tamamlandi = null,Object? zayif = null,}) {
  return _then(_Konu(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,alan: null == alan ? _self.alan : alan // ignore: cast_nullable_to_non_nullable
as SinavAlani,baslik: null == baslik ? _self.baslik : baslik // ignore: cast_nullable_to_non_nullable
as String,tamamlandi: null == tamamlandi ? _self.tamamlandi : tamamlandi // ignore: cast_nullable_to_non_nullable
as bool,zayif: null == zayif ? _self.zayif : zayif // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
