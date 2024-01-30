import 'dart:math';

import 'package:body_builder/src/paginated_response.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef StateConvertor<T, C extends ChangeNotifier> = T? Function(
  C changeNotifier,
);

abstract class StateProvider<T> extends ChangeNotifier {
  T? items([String? query]);

  bool hasData([String? query]);

  bool hasMore([String? query]) => false;

  void clear() => throw UnimplementedError();
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

  SimpleStateProvider<T> byId(K id) {
    if (!_states.containsKey(id)) {
      _states[id] = SimpleStateProvider<T>();
    }
    return _states[id]!;
  }

  void clear() {
    for (final SimpleStateProvider<T> state in _states.values) {
      state.clear();
    }
    _states.clear();
  }
}

abstract class RelatedPaginatedStates<K, T> extends ChangeNotifier {
  final Map<K, PaginatedState<T>> _states = {};

  RelatedPaginatedStates();

  PaginatedState<T> byId(K id) => _states[id] ??= PaginatedState<T>();

  void clear() => _states.clear();
}

class PaginatedState<T> extends StateProvider<Iterable<T>> {
  PaginatedState();

  final Map<String, DataState<T>> _states = {};

  @override
  Iterable<T> items([String? query]) => get(_toKey(query)).items;

  @override
  bool hasData([String? query]) => get(_toKey(query)).items.isNotEmpty;

  @override
  bool hasMore([String? query]) => get(_toKey(query)).hasMore;

  DataState<T> get(String? query) => _states[_toKey(query)] ??= DataState();

  Iterable<T> onFetch(String? query, PaginatedBase<T> response) =>
      get(query).onFetch(response);

  String _toKey(String? query) => query?.toLowerCase().trim() ?? '';

  @override
  void clear() => _states.clear();

  void add(String query, T item) {
    get(query).remove(item);
    get(query).insert(0, item);
    notifyListeners();
  }

  void removeWhere(String query, bool Function(T element) test) {
    get(query).removeWhere(test);
    notifyListeners();
  }

  void remove([String? query]) => _states.remove(_toKey(query));

  T? where(bool Function(T) test) =>
      _states.values.expand((element) => element.items).firstWhereOrNull(test);
}

class DataState<T> {
  DataState();

  final List<T> _items = [];
  int _page = 0;
  int _lastPage = 0;

  Iterable<T> get items => _items;

  bool get hasMore => _lastPage == 0 || _page < _lastPage;

  int get page => _page;

  T add(T item) {
    _items.add(item);
    return item;
  }

  T insert(int index, T item) {
    _items.insert(index, item);
    return item;
  }

  void remove(T item) => _items.remove(item);

  void removeWhere(bool Function(T element) test) => _items.removeWhere(test);

  T updateOrAdd(T item) {
    _items.remove(item);
    add(item);
    return item;
  }

  T updateOrAddFirst(T item) {
    remove(item);
    _items.insert(0, item);
    return item;
  }

  void update(T item) {
    final int index = _items.indexWhere((element) => element == item);

    if (index >= 0) {
      _items[index] = item;
    }
  }

  Iterable<T> onFetch(PaginatedBase<T> response) {
    if (response.items?.isNotEmpty != true) {
      if (_page < _lastPage) {
        debugPrint(
          'Inconsistent pagination of ${typeOf<T>()} detected. Page ${page + 1}'
          ' is empty but the last page should be $_lastPage. '
          'Path: ${response.path}',
        );
      }
      // Avoid any loop with the api, force change the last page.
      // We add max(1, x), because 0 will make #hasMore always return true
      _page = max(1, response.currentPage!);
      _lastPage = _page;
      return _items;
    }
    if ((response.currentPage ?? 0) != _page + 1) {
      // We have received a page that we already got or that is not the next one, skip.
      debugPrint(
        'Inconsistent pagination of ${typeOf<T>()} detected. '
        'The current page is $_page, we expected the next page to be ${_page + 1} '
        'but we got ${response.currentPage}. Path: ${response.path}',
      );
      return _items;
    }
    _items.removeWhere((e) => response.items!.contains(e));
    _items.addAll(response.items!);
    _lastPage = response.lastPage!;
    _page = response.currentPage!;
    return _items;
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
