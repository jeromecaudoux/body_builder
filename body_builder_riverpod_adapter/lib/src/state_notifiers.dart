import 'package:body_builder/body_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide StateProvider;

class SimpleNotifier<T> extends StateNotifier<T?> {
  SimpleNotifier(super.state);

  T? get get => state;

  T? onFetch(T? value) {
    state = value;
    return value;
  }
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(PaginatedState<T>());

  PaginatedState<T> get pState => state;
}

class RelatedPaginatedNotifier<K, T>
    extends StateNotifier<RelatedPaginatedStates<K, T>> {
  RelatedPaginatedNotifier() : super(RelatedPaginatedStates<K, T>());

  RelatedPaginatedStates<K, T> get rpState => state;
}
