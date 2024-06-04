import 'dart:math';

import 'package:body_builder/src/paginated_response.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef StateConvertor<T, C extends ChangeNotifier> = T? Function(
    C changeNotifier);

abstract class StateProvider<T> extends ChangeNotifier {
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

  T? onFetch(T? item) {
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
    byId(key).onFetch(item);
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

abstract class RelatedPaginatedStates<K, T> extends ChangeNotifier {
  final Map<K, PaginatedState<T>> _states = {};

  Iterable<K> get keys => _states.keys;

  RelatedPaginatedStates();

  PaginatedState<T> byId(K id) => _states[id] ??= PaginatedState<T>();

  void clear() => _states.clear();
}

class PaginatedState<T> extends StateProvider<Iterable<T>> {
  PaginatedState();

  final Map<String, DataState<T>> _states = {};

  @override
  Iterable<T> items([String? query]) => get(normalizeQuery(query)).items;

  @override
  bool hasData([String? query]) => get(normalizeQuery(query)).items.isNotEmpty;

  @override
  bool hasMore([String? query]) => get(normalizeQuery(query)).hasMore;

  int? nbHits(String query) => get(query).nbHits;

  DataState<T> get(String? query) =>
      _states[normalizeQuery(query)] ??= DataState();

  Iterable<T> onFetch(String? query, PaginatedBase<T> response) {
    Iterable<T> items = get(query).onFetch(response);
    notifyListeners();
    return items;
  }

  String normalizeQuery(String? query) => query?.toLowerCase().trim() ?? '';

  @override
  void clear() => _states.clear();

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

  Iterable<T> get items => _items;
  bool get hasMore => _lastPage == 0 || _page < _lastPage;
  int get page => _page;
  int get lastPage => _lastPage;
  int? get nbHits => _nbHits;

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

  Iterable<T> onFetch(PaginatedBase<T> response) {
    if (response.pItems?.isNotEmpty != true) {
      if (_page < _lastPage) {
        debugPrint(
          'Inconsistent pagination of ${typeOf<T>()} detected. Page ${page + 1}'
          ' is empty but the last page should be $_lastPage. '
          'Path: ${response.pPath}',
        );
      }
      // Avoid any loop with the api, force change the last page.
      // We add max(1, x), because 0 will make #hasMore always return true
      _page = max(1, response.pPage!);
      _lastPage = _page;
      return _items;
    }
    if ((response.pPage ?? 0) != _page + 1) {
      // We have received a page that we already got or that is not the next one, skip.
      debugPrint(
        'Inconsistent pagination of ${typeOf<T>()} detected. '
        'The current page is $_page, we expected the next page to be ${_page + 1} '
        'but we got ${response.pPage}. Path: ${response.pPath}',
      );
      return _items;
    }
    _items.removeWhere((e) => response.pItems!.contains(e));
    _items.addAll(response.pItems!);
    _lastPage = response.pLast!;
    _page = response.pPage!;
    _nbHits = response.nbHits;
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
