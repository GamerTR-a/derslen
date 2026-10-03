// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flash_kart.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlashKart {

 String get id; String get ders; String get unite; String get on; String get arka; String? get ipucu;
/// Create a copy of FlashKart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlashKartCopyWith<FlashKart> get copyWith => _$FlashKartCopyWithImpl<FlashKart>(this as FlashKart, _$identity);

  /// Serializes this FlashKart to a JSON map.
  Map<String, dynamic> toJson();




@override
String toString() {
  return 'FlashKart(id: $id, ders: $ders, unite: $unite, on: $on, arka: $arka, ipucu: $ipucu)';
}


}

/// @nodoc
abstract mixin class $FlashKartCopyWith<$Res>  {
  factory $FlashKartCopyWith(FlashKart value, $Res Function(FlashKart) _then) = _$FlashKartCopyWithImpl;
@useResult
$Res call({
 String id, String ders, String unite, String on, String arka, String? ipucu
});




}
/// @nodoc
class _$FlashKartCopyWithImpl<$Res>
    implements $FlashKartCopyWith<$Res> {
  _$FlashKartCopyWithImpl(this._self, this._then);

  final FlashKart _self;
  final $Res Function(FlashKart) _then;

/// Create a copy of FlashKart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ders = null,Object? unite = null,Object? on = null,Object? arka = null,Object? ipucu = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,unite: null == unite ? _self.unite : unite // ignore: cast_nullable_to_non_nullable
as String,on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as String,arka: null == arka ? _self.arka : arka // ignore: cast_nullable_to_non_nullable
as String,ipucu: freezed == ipucu ? _self.ipucu : ipucu // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlashKart].
extension FlashKartPatterns on FlashKart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlashKart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlashKart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlashKart value)  $default,){
final _that = this;
switch (_that) {
case _FlashKart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlashKart value)?  $default,){
final _that = this;
switch (_that) {
case _FlashKart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ders,  String unite,  String on,  String arka,  String? ipucu)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlashKart() when $default != null:
return $default(_that.id,_that.ders,_that.unite,_that.on,_that.arka,_that.ipucu);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ders,  String unite,  String on,  String arka,  String? ipucu)  $default,) {final _that = this;
switch (_that) {
case _FlashKart():
return $default(_that.id,_that.ders,_that.unite,_that.on,_that.arka,_that.ipucu);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ders,  String unite,  String on,  String arka,  String? ipucu)?  $default,) {final _that = this;
switch (_that) {
case _FlashKart() when $default != null:
return $default(_that.id,_that.ders,_that.unite,_that.on,_that.arka,_that.ipucu);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FlashKart extends FlashKart {
  const _FlashKart({required this.id, required this.ders, required this.unite, required this.on, required this.arka, this.ipucu}): super._();
  factory _FlashKart.fromJson(Map<String, dynamic> json) => _$FlashKartFromJson(json);

@override final  String id;
@override final  String ders;
@override final  String unite;
@override final  String on;
@override final  String arka;
@override final  String? ipucu;

/// Create a copy of FlashKart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlashKartCopyWith<_FlashKart> get copyWith => __$FlashKartCopyWithImpl<_FlashKart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlashKartToJson(this, );
}



@override
String toString() {
  return 'FlashKart(id: $id, ders: $ders, unite: $unite, on: $on, arka: $arka, ipucu: $ipucu)';
}


}

/// @nodoc
abstract mixin class _$FlashKartCopyWith<$Res> implements $FlashKartCopyWith<$Res> {
  factory _$FlashKartCopyWith(_FlashKart value, $Res Function(_FlashKart) _then) = __$FlashKartCopyWithImpl;
@override @useResult
$Res call({
 String id, String ders, String unite, String on, String arka, String? ipucu
});




}
/// @nodoc
class __$FlashKartCopyWithImpl<$Res>
    implements _$FlashKartCopyWith<$Res> {
  __$FlashKartCopyWithImpl(this._self, this._then);

  final _FlashKart _self;
  final $Res Function(_FlashKart) _then;

/// Create a copy of FlashKart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ders = null,Object? unite = null,Object? on = null,Object? arka = null,Object? ipucu = freezed,}) {
  return _then(_FlashKart(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ders: null == ders ? _self.ders : ders // ignore: cast_nullable_to_non_nullable
as String,unite: null == unite ? _self.unite : unite // ignore: cast_nullable_to_non_nullable
as String,on: null == on ? _self.on : on // ignore: cast_nullable_to_non_nullable
as String,arka: null == arka ? _self.arka : arka // ignore: cast_nullable_to_non_nullable
as String,ipucu: freezed == ipucu ? _self.ipucu : ipucu // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
