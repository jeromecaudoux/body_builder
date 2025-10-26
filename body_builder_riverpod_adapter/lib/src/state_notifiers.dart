import 'package:body_builder/body_builder.dart';
import 'package:flutter_riverpod/legacy.dart';

class SimpleNotifier<T> extends StateNotifier<T?> {
  SimpleNotifier(super.state);

  T? get data => state;

  T on(T value) {
    state = value;
    return value;
  }

  void clear() => state = null;
}

class RelatedSimpleNotifier<K, T>
    extends StateNotifier<RelatedStateProvider<K, T>> {
  RelatedSimpleNotifier() : super(RelatedStateProvider<K, T>());

  RelatedStateProvider<K, T> get rsState => state;

  SimpleStateProvider<T> byId(K id) => rsState.byId(id);

  T? data(K id) => byId(id).data();

  T on(K id, T item) => byId(id).on(item);

  void clear() {
    for (final key in rsState.keys) {
      byId(key).clear();
    }
  }

  T? where(bool Function(T?) test) => rsState.where(test);
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(PaginatedState<T>());

  PaginatedState<T> get pState => state;

  Iterable<T> data([String? query]) => pState.data(query);

  bool hasData([String? query]) => pState.hasData(query);

  bool hasMore([String? query]) => pState.hasMore(query);

  int? nbHits(String query) => pState.nbHits(query);

  Iterable<T> on(PaginatedBase<T> response, {String? query}) =>
      pState.on(response, query: query);

  void clear() => pState.clear();
}

class RelatedPaginatedNotifier<K, T>
    extends StateNotifier<RelatedPaginatedStates<K, T>> {
  RelatedPaginatedNotifier() : super(RelatedPaginatedStates<K, T>());

  RelatedPaginatedStates<K, T> get rpState => state;

  PaginatedState<T> byId(K id) => rpState.byId(id);

  void clear() => rpState.clear();
}
