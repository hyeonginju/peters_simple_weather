// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forecast_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForecastResult {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastResult);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ForecastResult()';
}


}

/// @nodoc
class $ForecastResultCopyWith<$Res>  {
$ForecastResultCopyWith(ForecastResult _, $Res Function(ForecastResult) __);
}


/// Adds pattern-matching-related methods to [ForecastResult].
extension ForecastResultPatterns on ForecastResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ForecastSuccess value)?  success,TResult Function( ForecastPartialFailure value)?  partialFailure,TResult Function( ForecastFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ForecastSuccess() when success != null:
return success(_that);case ForecastPartialFailure() when partialFailure != null:
return partialFailure(_that);case ForecastFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ForecastSuccess value)  success,required TResult Function( ForecastPartialFailure value)  partialFailure,required TResult Function( ForecastFailure value)  failure,}){
final _that = this;
switch (_that) {
case ForecastSuccess():
return success(_that);case ForecastPartialFailure():
return partialFailure(_that);case ForecastFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ForecastSuccess value)?  success,TResult? Function( ForecastPartialFailure value)?  partialFailure,TResult? Function( ForecastFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ForecastSuccess() when success != null:
return success(_that);case ForecastPartialFailure() when partialFailure != null:
return partialFailure(_that);case ForecastFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( WeatherSnapshot snapshot,  List<HourlyForecast> hourly,  List<DailyForecast> daily)?  success,TResult Function( WeatherSnapshot snapshot,  List<HourlyForecast>? hourly,  List<DailyForecast>? daily)?  partialFailure,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ForecastSuccess() when success != null:
return success(_that.snapshot,_that.hourly,_that.daily);case ForecastPartialFailure() when partialFailure != null:
return partialFailure(_that.snapshot,_that.hourly,_that.daily);case ForecastFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( WeatherSnapshot snapshot,  List<HourlyForecast> hourly,  List<DailyForecast> daily)  success,required TResult Function( WeatherSnapshot snapshot,  List<HourlyForecast>? hourly,  List<DailyForecast>? daily)  partialFailure,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case ForecastSuccess():
return success(_that.snapshot,_that.hourly,_that.daily);case ForecastPartialFailure():
return partialFailure(_that.snapshot,_that.hourly,_that.daily);case ForecastFailure():
return failure(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( WeatherSnapshot snapshot,  List<HourlyForecast> hourly,  List<DailyForecast> daily)?  success,TResult? Function( WeatherSnapshot snapshot,  List<HourlyForecast>? hourly,  List<DailyForecast>? daily)?  partialFailure,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case ForecastSuccess() when success != null:
return success(_that.snapshot,_that.hourly,_that.daily);case ForecastPartialFailure() when partialFailure != null:
return partialFailure(_that.snapshot,_that.hourly,_that.daily);case ForecastFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ForecastSuccess implements ForecastResult {
  const ForecastSuccess({required this.snapshot, required final  List<HourlyForecast> hourly, required final  List<DailyForecast> daily}): _hourly = hourly,_daily = daily;
  

 final  WeatherSnapshot snapshot;
 final  List<HourlyForecast> _hourly;
 List<HourlyForecast> get hourly {
  if (_hourly is EqualUnmodifiableListView) return _hourly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hourly);
}

 final  List<DailyForecast> _daily;
 List<DailyForecast> get daily {
  if (_daily is EqualUnmodifiableListView) return _daily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_daily);
}


/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastSuccessCopyWith<ForecastSuccess> get copyWith => _$ForecastSuccessCopyWithImpl<ForecastSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastSuccess&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._hourly, _hourly)&&const DeepCollectionEquality().equals(other._daily, _daily));
}


@override
int get hashCode => Object.hash(runtimeType,snapshot,const DeepCollectionEquality().hash(_hourly),const DeepCollectionEquality().hash(_daily));

@override
String toString() {
  return 'ForecastResult.success(snapshot: $snapshot, hourly: $hourly, daily: $daily)';
}


}

/// @nodoc
abstract mixin class $ForecastSuccessCopyWith<$Res> implements $ForecastResultCopyWith<$Res> {
  factory $ForecastSuccessCopyWith(ForecastSuccess value, $Res Function(ForecastSuccess) _then) = _$ForecastSuccessCopyWithImpl;
@useResult
$Res call({
 WeatherSnapshot snapshot, List<HourlyForecast> hourly, List<DailyForecast> daily
});




}
/// @nodoc
class _$ForecastSuccessCopyWithImpl<$Res>
    implements $ForecastSuccessCopyWith<$Res> {
  _$ForecastSuccessCopyWithImpl(this._self, this._then);

  final ForecastSuccess _self;
  final $Res Function(ForecastSuccess) _then;

/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshot = null,Object? hourly = null,Object? daily = null,}) {
  return _then(ForecastSuccess(
snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as WeatherSnapshot,hourly: null == hourly ? _self._hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyForecast>,daily: null == daily ? _self._daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>,
  ));
}


}

/// @nodoc


class ForecastPartialFailure implements ForecastResult {
  const ForecastPartialFailure({required this.snapshot, final  List<HourlyForecast>? hourly, final  List<DailyForecast>? daily}): _hourly = hourly,_daily = daily;
  

 final  WeatherSnapshot snapshot;
 final  List<HourlyForecast>? _hourly;
 List<HourlyForecast>? get hourly {
  final value = _hourly;
  if (value == null) return null;
  if (_hourly is EqualUnmodifiableListView) return _hourly;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<DailyForecast>? _daily;
 List<DailyForecast>? get daily {
  final value = _daily;
  if (value == null) return null;
  if (_daily is EqualUnmodifiableListView) return _daily;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastPartialFailureCopyWith<ForecastPartialFailure> get copyWith => _$ForecastPartialFailureCopyWithImpl<ForecastPartialFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastPartialFailure&&(identical(other.snapshot, snapshot) || other.snapshot == snapshot)&&const DeepCollectionEquality().equals(other._hourly, _hourly)&&const DeepCollectionEquality().equals(other._daily, _daily));
}


@override
int get hashCode => Object.hash(runtimeType,snapshot,const DeepCollectionEquality().hash(_hourly),const DeepCollectionEquality().hash(_daily));

@override
String toString() {
  return 'ForecastResult.partialFailure(snapshot: $snapshot, hourly: $hourly, daily: $daily)';
}


}

/// @nodoc
abstract mixin class $ForecastPartialFailureCopyWith<$Res> implements $ForecastResultCopyWith<$Res> {
  factory $ForecastPartialFailureCopyWith(ForecastPartialFailure value, $Res Function(ForecastPartialFailure) _then) = _$ForecastPartialFailureCopyWithImpl;
@useResult
$Res call({
 WeatherSnapshot snapshot, List<HourlyForecast>? hourly, List<DailyForecast>? daily
});




}
/// @nodoc
class _$ForecastPartialFailureCopyWithImpl<$Res>
    implements $ForecastPartialFailureCopyWith<$Res> {
  _$ForecastPartialFailureCopyWithImpl(this._self, this._then);

  final ForecastPartialFailure _self;
  final $Res Function(ForecastPartialFailure) _then;

/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snapshot = null,Object? hourly = freezed,Object? daily = freezed,}) {
  return _then(ForecastPartialFailure(
snapshot: null == snapshot ? _self.snapshot : snapshot // ignore: cast_nullable_to_non_nullable
as WeatherSnapshot,hourly: freezed == hourly ? _self._hourly : hourly // ignore: cast_nullable_to_non_nullable
as List<HourlyForecast>?,daily: freezed == daily ? _self._daily : daily // ignore: cast_nullable_to_non_nullable
as List<DailyForecast>?,
  ));
}


}

/// @nodoc


class ForecastFailure implements ForecastResult {
  const ForecastFailure(this.message);
  

 final  String message;

/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForecastFailureCopyWith<ForecastFailure> get copyWith => _$ForecastFailureCopyWithImpl<ForecastFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForecastFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ForecastResult.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $ForecastFailureCopyWith<$Res> implements $ForecastResultCopyWith<$Res> {
  factory $ForecastFailureCopyWith(ForecastFailure value, $Res Function(ForecastFailure) _then) = _$ForecastFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ForecastFailureCopyWithImpl<$Res>
    implements $ForecastFailureCopyWith<$Res> {
  _$ForecastFailureCopyWithImpl(this._self, this._then);

  final ForecastFailure _self;
  final $Res Function(ForecastFailure) _then;

/// Create a copy of ForecastResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ForecastFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
