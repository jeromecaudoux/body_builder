import 'package:body_builder/src/body_state.dart';
import 'package:flutter/material.dart';

typedef CustomBuilder = Widget Function(BodyState state);
typedef ProgressBuilder = Widget Function();
typedef ErrorBuilder = Widget Function(
  dynamic error,
  StackTrace? errorStack,
  VoidCallback onRetry,
);
typedef ChildWrapper<T> = Widget Function(
  Widget child,
  BodyState<T> state,
  VoidCallback onRetry, {
  TextEditingController? searchController,
  ScrollController? scrollController,
});

Type typeOf<T>() => T;
