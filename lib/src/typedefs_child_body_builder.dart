import 'package:body_builder/src/body_state.dart';
import 'package:flutter/material.dart';

@Deprecated('Use CustomChildBuilder instead')
typedef DeprecatedCustomBuilder<T> = Widget Function(
  // ignore: avoid_positional_boolean_parameters
  bool isLoading,
  dynamic error,
  T? data,
);
typedef CustomBuilder = Widget Function(BodyState state);
typedef ProgressBuilder = Widget Function({
  bool showAppBar,
});
typedef ErrorBuilder = Widget Function(
  dynamic error,
  StackTrace? errorStack,
  VoidCallback onRetry, {
  bool showAppBar,
  bool placeHolderImage,
});
typedef ChildWrapper<T> = Widget Function(
  Widget child,
  BodyState<T> state,
  VoidCallback onRetry,
);

Type typeOf<T>() => T;
