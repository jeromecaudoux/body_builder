import 'package:body_builder/body_builder.dart';
import 'package:flutter_riverpod/legacy.dart' hide StateProvider;
import 'package:collection/collection.dart';

class SimpleDataNotifier<T> extends StateNotifier<T?> {
  SimpleDataNotifier(super.state);

  T? get data => state;

  void on(T data) => state = data;

  void clear() => state = null;

  @override
  bool updateShouldNotify(T? old, T? current) {
    bool should = super.updateShouldNotify(old, current) ||
        (old == current && old == null);
    return should;
  }
}

class PaginatedDataNotifier<T>
    extends StateNotifier<Map<String, DataState<T>>> {
  PaginatedDataNotifier() : super({});

  Iterable<String> get keys => state.keys;

  Iterable<T> data([String? query]) => get(query).items;

  bool hasData([String? query]) => get(query).items.isNotEmpty;

  bool hasMore([String? query]) => get(query).hasMore;

  int? nbHits(String query) => get(query).nbHits;

  DataState<T> get(String? query) =>
      state[normalizeQuery(query)] ??= DataState();

  @Deprecated('Use "on" instead')
  Iterable<T> onFetch(String? query, PaginatedBase<T> response) =>
      on(response, query: query);

  Iterable<T> on(PaginatedBase<T> response, {String? query}) {
    Iterable<T> items = get(query).on(response);
    state = state;
    return items;
  }

  String normalizeQuery(String? query) => query?.toLowerCase().trim() ?? '';

  void clear() => state = {};

  T add(String query, T item) {
    get(query).remove(item);
    get(query).insert(0, item);
    state = state;
    return item;
  }

  void removeItemWhere(bool Function(T element) test, {String? query}) {
    if (query != null) {
      get(query).removeWhere(test);
    } else {
      for (final DataState<T> state in state.values) {
        state.removeWhere(test);
      }
    }
    state = state;
  }

  bool removeItem(T item, {String? query}) {
    if (query != null) {
      return get(query).remove(item);
    }
    bool removed = false;
    for (final DataState<T> s in state.values) {
      if (s.remove(item)) {
        state = state;
        removed = true;
      }
    }
    return removed;
  }

  bool updateItem(T item, {bool addIfMissing = true, bool addFirst = true}) {
    bool updated = false;
    for (final DataState<T> s in state.values) {
      if (s.update(item, addIfMissing: addIfMissing, addFirst: addFirst)) {
        updated = true;
      }
    }
    state = state;
    return updated;
  }

  void remove([String? query]) {
    state.remove(normalizeQuery(query));
    state = state;
  }

  T? itemWhere(bool Function(T) test) =>
      state.values.expand((element) => element.items).firstWhereOrNull(test);

  @override
  bool updateShouldNotify(
    Map<String, DataState<T>> old,
    Map<String, DataState<T>> current,
  ) {
    return true;
  }
}

StateNotifierProvider<SimpleDataNotifier<T>, T?>
    createSimpleStateProvider<T>() {
  return StateNotifierProvider<SimpleDataNotifier<T>, T?>((ref) {
    return SimpleDataNotifier<T>(null);
  });
}

StateNotifierProviderFamily<SimpleDataNotifier<T>, T?, K>
    createFamilySimpleStateProvider<K, T>() {
  return StateNotifierProvider.family<SimpleDataNotifier<T>, T?, K>(
    (ref, id) => SimpleDataNotifier<T>(null),
  );
}

StateNotifierProvider<PaginatedDataNotifier<T>, Map<String, DataState<T>>>
    createPaginatedStateProvider<T>() {
  return StateNotifierProvider<PaginatedDataNotifier<T>,
      Map<String, DataState<T>>>((ref) {
    return PaginatedDataNotifier<T>();
  });
}

StateNotifierProvider<PaginatedDataNotifier<T>, Map<String, DataState<T>>>
    createPaginatedDataStateProvider<T>() {
  return StateNotifierProvider<PaginatedDataNotifier<T>,
      Map<String, DataState<T>>>((ref) {
    return PaginatedDataNotifier<T>();
  });
}

StateNotifierProviderFamily<PaginatedDataNotifier<T>, Map<String, DataState<T>>,
    K> createFamilyPaginatedStateProvider<K, T>() {
  return StateNotifierProvider.family<PaginatedDataNotifier<T>,
      Map<String, DataState<T>>, K>(
    (ref, id) => PaginatedDataNotifier<T>(),
  );
}

/* AutoDispose versions */
StateNotifierProvider<SimpleDataNotifier<T>, T?>
    createAutoDisposeSimpleStateProvider<T>() {
  return StateNotifierProvider.autoDispose<SimpleDataNotifier<T>, T?>((ref) {
    return SimpleDataNotifier<T>(null);
  });
}

StateNotifierProviderFamily<SimpleDataNotifier<T>, T?, K>
    createAutoDisposeFamilySimpleStateProvider<K, T>() {
  return StateNotifierProvider.autoDispose.family<SimpleDataNotifier<T>, T?, K>(
    (ref, id) => SimpleDataNotifier<T>(null),
  );
}

StateNotifierProvider<PaginatedDataNotifier<T>, Map<String, DataState<T>>>
    createAutoDisposePaginatedStateProvider<T>() {
  return StateNotifierProvider.autoDispose<PaginatedDataNotifier<T>,
      Map<String, DataState<T>>>((ref) {
    return PaginatedDataNotifier<T>();
  });
}

StateNotifierProviderFamily<PaginatedDataNotifier<T>, Map<String, DataState<T>>,
    K> createAutoDisposeFamilyPaginatedStateProvider<K, T>() {
  return StateNotifierProvider.autoDispose
      .family<PaginatedDataNotifier<T>, Map<String, DataState<T>>, K>(
    (ref, id) => PaginatedDataNotifier<T>(),
  );
}
