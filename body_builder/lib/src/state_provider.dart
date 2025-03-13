import 'dart:math';

import 'package:body_builder/src/paginated_response.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef StateConvertor<T, C extends ChangeNotifier> = T? Function(
    C changeNotifier);

abstract class StateProvider<T> extends ChangeNotifier {
  bool get isPaginated => false;

  T? items([String? query]);

  bool hasData([String? query]);

  bool hasMore([String? query]) => false;

  void clear() {}
}

class SimpleStateProvider<T> extends StateProvider<T> {
  SimpleStateProvider();

  T? _item;

  @override
  T? items([String? query]) => _item;

  @override
  bool hasData([String? query]) => _item != null;

  @Deprecated('Use "on" instead')
  T? onFetch(T? item) {
    if (item == null) {
      clear();
      return null;
    }
    return on(item);
  }

  T on(T item) {
    _item = item;
    notifyListeners();
    return item;
  }

  @override
  void clear() {
    _item = null;
    notifyListeners();
  }
}

abstract class RelatedStateProvider<K, T> extends ChangeNotifier {
  final Map<K, SimpleStateProvider<T>> _states = {};

  RelatedStateProvider();

  Iterable<K> get keys => _states.keys;

  SimpleStateProvider<T> byId(K id) {
    if (!_states.containsKey(id)) {
      _states[id] = SimpleStateProvider<T>();
    }
    return _states[id]!;
  }

  T onFetch(K key, T item) {
    byId(key).on(item);
    notifyListeners();
    return item;
  }

  void clear() {
    for (final SimpleStateProvider<T> state in _states.values) {
      state.clear();
    }
    _states.clear();
    notifyListeners();
  }

  T? where(bool Function(T?) test) =>
      _states.values.firstWhereOrNull((state) => test(state._item))?._item;
}

class RelatedPaginatedStates<K, T> extends ChangeNotifier {
  final Map<K, PaginatedState<T>> _states = {};

  Iterable<K> get keys => _states.keys;

  RelatedPaginatedStates();

  PaginatedState<T> byId(K id) => _states[id] ??= PaginatedState<T>();

  void clear() {
    _states.clear();
    notifyListeners();
  }
}

class PaginatedState<T> extends StateProvider<Iterable<T>> {
  PaginatedState();

  final Map<String, DataState<T>> _states = {};

  @override
  bool get isPaginated => true;

  @override
  Iterable<T> items([String? query]) => get(normalizeQuery(query)).items;

  @override
  bool hasData([String? query]) => get(normalizeQuery(query)).items.isNotEmpty;

  @override
  bool hasMore([String? query]) => get(normalizeQuery(query)).hasMore;

  int? nbHits(String query) => get(query).nbHits;

  DataState<T> get(String? query) =>
      _states[normalizeQuery(query)] ??= DataState();

  @Deprecated('Use "on" instead')
  Iterable<T> onFetch(String? query, PaginatedBase<T> response) =>
      on(response, query: query);

  Iterable<T> on(PaginatedBase<T> response, {String? query}) {
    Iterable<T> items = get(query).on(response);
    notifyListeners();
    return items;
  }

  String normalizeQuery(String? query) => query?.toLowerCase().trim() ?? '';

  @override
  void clear() {
    _states.clear();
    notifyListeners();
  }

  T add(String query, T item) {
    get(query).remove(item);
    get(query).insert(0, item);
    notifyListeners();
    return item;
  }

  Iterable<String> get keys => _states.keys;

  void removeItemWhere(bool Function(T element) test, {String? query}) {
    if (query != null) {
      get(query).removeWhere(test);
    } else {
      for (final DataState<T> state in _states.values) {
        state.removeWhere(test);
      }
    }
    notifyListeners();
  }

  bool removeItem(T item, {String? query}) {
    if (query != null) {
      return get(query).remove(item);
    }
    bool removed = false;
    for (final DataState<T> state in _states.values) {
      if (state.remove(item)) {
        notifyListeners();
        removed = true;
      }
    }
    return removed;
  }

  bool updateItem(T item, {bool addIfMissing = true, bool addFirst = true}) {
    bool updated = false;
    for (final DataState<T> state in _states.values) {
      if (state.update(item, addIfMissing: addIfMissing, addFirst: addFirst)) {
        updated = true;
      }
    }
    notifyListeners();
    return updated;
  }

  void remove([String? query]) {
    _states.remove(normalizeQuery(query));
    notifyListeners();
  }

  T? itemWhere(bool Function(T) test) =>
      _states.values.expand((element) => element.items).firstWhereOrNull(test);
}

class DataState<T> {
  DataState();

  final List<T> _items = [];
  int _page = 0;
  int _lastPage = 0;
  int? _nbHits;
  PaginatedBase<T>? _lastResponse;

  Iterable<T> get items => _items;
  bool get hasMore => _lastPage == 0 || _page < _lastPage;
  int get page => _page;
  int get lastPage => _lastPage;
  int? get nbHits => _nbHits;
  PaginatedBase<T>? get lastResponse => _lastResponse;

  T add(T item) {
    _items.add(item);
    _incrementCount(1);
    return item;
  }

  T insert(int index, T item) {
    _items.insert(index, item);
    _incrementCount(1);
    return item;
  }

  bool remove(T item) {
    bool removed = _items.remove(item);
    if (removed) {
      _incrementCount(-1);
    }
    return removed;
  }

  void removeWhere(bool Function(T element) test) {
    int startLength = _items.length;
    _items.removeWhere(test);
    _incrementCount(startLength - _items.length);
  }

  bool has(T item) => _items.contains(item);

  bool update(T item, {bool addIfMissing = true, bool addFirst = true}) {
    final int index = _items.indexWhere((element) => element == item);

    if (index >= 0) {
      _items[index] = item;
      return true;
    }
    if (addIfMissing) {
      if (addFirst) {
        _items.insert(0, item);
      } else {
        _items.add(item);
      }
      _incrementCount(1);
    }
    return false;
  }

  @Deprecated('Use "on" instead')
  Iterable<T> onFetch(PaginatedBase<T> response) => on(response);

  Iterable<T> on(PaginatedBase<T> response) {
    if (response.pPage != _page + 1) {
      // We have received a page that we already got or that is not the next one, skip.
      debugPrint(
        'Inconsistent pagination of ${typeOf<T>()} detected. '
        'The current page is $_page, we expected the next page to be ${_page + 1} '
        'but we got ${response.pPage}. Path: ${response.pPath}',
      );
      return _items;
    }

    if (response.pItems.length < response.pLimit) {
      // We found the last page
      if (hasMore) {
        debugPrint(
          'Inconsistent pagination of ${typeOf<T>()} detected. Page ${page + 1}'
          ' has less elements than expected (${response.pLimit}). '
          'The last page should be ${_lastPage == 0 ? '"undefined"' : '$_lastPage'}. '
          'Path: ${response.pPath}',
        );
      }
      // Avoid any loop with the api, force change the last page.
      // We add max(1, x), because 0 will make #hasMore always return true
      _page = max(1, response.pPage);
      _lastPage = _page;
      if (response.pItems.isNotEmpty) {
        _items.removeWhere((e) => response.pItems.contains(e));
        _items.addAll(response.pItems);
        _nbHits = response.nbHits;
        _lastResponse = response;
      }
      return _items;
    }

    _items.removeWhere((e) => response.pItems.contains(e));
    _items.addAll(response.pItems);
    _lastPage = response.pLast ?? 1000;
    _page = response.pPage;
    _nbHits = response.nbHits;
    _lastResponse = response;
    return _items;
  }

  void _incrementCount(int count) {
    setItemsCount((_nbHits ?? 0) + count);
  }

  void setItemsCount(int? count) {
    _nbHits = count == null ? null : max(0, count);
  }
}

class CustomStateProvider<T, C extends ChangeNotifier>
    extends StateProvider<T> {
  final C changeNotifier;
  final StateConvertor<T, C> convertor;

  CustomStateProvider({required this.changeNotifier, required this.convertor});

  @override
  void addListener(VoidCallback listener) =>
      changeNotifier.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      changeNotifier.removeListener(listener);

  @override
  T? items([String? query]) => convertor(changeNotifier);

  @override
  bool hasData([String? query]) => convertor(changeNotifier) != null;

  @override
  bool hasMore([String? query]) => changeNotifier is PaginatedState
      ? (changeNotifier as PaginatedState).hasMore(query)
      : false;
}

extension ChangeNotifierExt<C extends ChangeNotifier> on C {
  StateProvider<T> map<T>(StateConvertor<T, C> state) =>
      CustomStateProvider<T, C>(changeNotifier: this, convertor: state);
}

typedef ExternalStateData<T> = T? Function([String? query]);
typedef ExternalHasMore<T> = bool Function([String? query]);

class ExternalStateProvider<T> extends StateProvider<T> {
  final ExternalStateData externalData;
  final ExternalHasMore? externalHasMore;
  final VoidCallback? onClear;
  final ValueChanged<VoidCallback>? onAddListener;
  final ValueChanged<VoidCallback>? onRemoveListener;

  ExternalStateProvider.from(
    this.externalData, {
    this.externalHasMore,
    this.onClear,
    this.onAddListener,
    this.onRemoveListener,
  }) {
    assert(
      onAddListener == null || onRemoveListener != null,
      'onRemoveListener must be provided if onAddListener is provided',
    );
  }

  @override
  bool get isPaginated => externalHasMore != null;

  @override
  void addListener(VoidCallback listener) => onAddListener?.call(listener);

  @override
  void removeListener(VoidCallback listener) =>
      onRemoveListener?.call(listener);

  @override
  T? items([String? query]) => externalData(query);

  @override
  bool hasMore([String? query]) => externalHasMore?.call(query) ?? false;

  @override
  bool hasData([String? query]) {
    T? data = items(query);
    return isPaginated ? (data as Iterable?)?.isNotEmpty == true : data != null;
  }

  @override
  void clear() => onClear?.call();
}
