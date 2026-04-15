import 'package:body_builder/body_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

class SimpleNotifier<T> extends StateNotifier<T?> {
  SimpleNotifier(super.state);

  T? get data => state;

  T on(T value) {
    if (!mounted) {
      debugPrint('StateNotifier is not mounted, skipping state update');
      return value;
    }
    state = value;
    return value;
  }

  void clear() {
    if (!mounted) return;
    state = null;
  }

  @override
  bool updateShouldNotify(T? old, T? current) {
    return true;
  }
}

class RelatedSimpleNotifier<K, T>
    extends StateNotifier<RelatedStateProvider<K, T>> {
  RelatedSimpleNotifier() : super(RelatedStateProvider<K, T>());

  RelatedStateProvider<K, T> get rsState => state;

  SimpleStateProvider<T> byId(K id) => rsState.byId(id);

  T? data(K id) => byId(id).data();

  T on(K id, T item) {
    byId(id).on(item);
    if (mounted) {
      state = rsState; // Trigger state update
    }
    return item;
  }

  void clear() {
    for (final key in rsState.keys) {
      byId(key).clear();
    }
    if (mounted) {
      state = rsState; // Trigger state update
    }
  }

  T? where(bool Function(T?) test) => rsState.where(test);

  @override
  bool updateShouldNotify(
      RelatedStateProvider<K, T> old,
      RelatedStateProvider<K, T> current,
      ) {
    return true;
  }
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(PaginatedState<T>());

  PaginatedState<T> get pState => state;

  Iterable<T> data([String? query]) => pState.data(query);

  bool hasData([String? query]) => pState.hasData(query);

  bool hasMore([String? query]) => pState.hasMore(query);

  int? nbHits(String query) => pState.nbHits(query);

  Iterable<T> on(PaginatedBase<T> response, {String? query}) {
    final items = pState.on(response, query: query);
    if (mounted) {
      state = pState; // Trigger state update
    }
    return items;
  }

  void clear() {
    pState.clear();
    if (mounted) {
      state = pState; // Trigger state update
    }
  }

  @override
  bool updateShouldNotify(PaginatedState<T> old, PaginatedState<T> current) {
    return true;
  }
}

class RelatedPaginatedNotifier<K, T>
    extends StateNotifier<RelatedPaginatedStates<K, T>> {
  RelatedPaginatedNotifier() : super(RelatedPaginatedStates<K, T>());

  RelatedPaginatedStates<K, T> get rpState => state;

  PaginatedState<T> byId(K id) => rpState.byId(id);

  void clear() {
    rpState.clear();
    if (mounted) {
      state = rpState; // Trigger state update
    }
  }

  @override
  bool updateShouldNotify(
      RelatedPaginatedStates<K, T> old,
      RelatedPaginatedStates<K, T> current,
      ) {
    return true;
  }
}