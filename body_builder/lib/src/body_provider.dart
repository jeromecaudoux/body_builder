import 'dart:async';

import 'package:body_builder/body_builder.dart';
import 'package:cache_annotations/annotations.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class DataBuilderParams {
  final String? query;
  final DataState? lastPage;

  const DataBuilderParams({
    this.query,
    this.lastPage,
  });
}

typedef CacheProvider<T> = Future<T?> Function([DataBuilderParams? params]);
typedef DataProvider<T> = Future Function([DataBuilderParams? params]);

abstract class BodyProviderBase<T> {
  final String id = UniqueKey().toString();
  final String? name;

  BodyProviderBase({this.name});

  bool get isPaginated;

  bool hasMore([String? query]);

  Stream<BodyState<T>> listen(String? query);

  void execute({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
    bool clearData = false,
  });
}

class BodyProvider<T> extends BodyProviderBase<T> {
  final StateProvider<T>? state;
  final CacheProvider<T>? cache;
  final DataProvider<T> data;
  final Map<String, BehaviorSubject<BodyState<T>>> _subjects =
      <String, BehaviorSubject<BodyState<T>>>{};
  final Map<String, StreamSubscription<BodyState<T>>> _executions =
      <String, StreamSubscription<BodyState<T>>>{};

  BodyProvider({
    this.state,
    this.cache,
    required this.data,
    super.name,
  });

  @override
  bool get isPaginated => state?.isPaginated == true;

  @override
  bool hasMore([String? query]) => state?.hasMore(query) == true;

  String _queryKey(String? query) => query ?? '';

  void _disposeQueryIfUnused(String? query) {
    final String key = _queryKey(query);
    final BehaviorSubject<BodyState<T>>? subject = _subjects[key];
    if (subject == null || subject.hasListener) {
      return;
    }
    _executions.remove(key)?.cancel();
    subject.close();
    _subjects.remove(key);
  }

  BehaviorSubject<BodyState<T>> _subjectForQuery(String? query) {
    final String key = _queryKey(query);
    return _subjects.putIfAbsent(
      key,
      () => BehaviorSubject<BodyState<T>>.seeded(initialState(query)),
    );
  }

  @override
  Stream<BodyState<T>> listen(String? query) {
    return _subjectForQuery(query).stream.doOnCancel(() {
      _disposeQueryIfUnused(query);
    });
  }

  @override
  void execute({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
    bool clearData = false,
  }) {
    final String key = _queryKey(query);
    final BehaviorSubject<BodyState<T>> subject = _subjectForQuery(query);

    if (clearData) {
      if (state != null) {
        if (!allowState) {
          state!.clear();
        }
        subject.add(subject.value.copy(isLoading: true, clearData: true));
      }
    }
    _executions[key]?.cancel();
    late final StreamSubscription<BodyState<T>> execution;
    execution = resolve(
      query: query,
      allowState: allowState,
      allowCache: allowCache,
      allowData: allowData,
    ).listen(
      (event) {
        if (!subject.isClosed) {
          subject.add(event);
        }
      },
      onError: (Object e, StackTrace s) {
        if (!subject.isClosed) {
          subject.add(BodyState.error(e, s));
        }
      },
      onDone: () {
        if (identical(_executions[key], execution)) {
          _executions.remove(key);
        }
      },
    );
    _executions[key] = execution;
  }

  BodyState<T> initialState(String? query) {
    if (state?.hasData(query) == true) {
      return BodyState.data(state!.data(query));
    }
    return BodyState.loading();
  }

  Stream<BodyState<T>> resolve({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
  }) {
    // Disable state or cache providers if they are not set
    allowState = allowState && state != null;
    allowCache = allowCache && cache != null;
    DataBuilderParams params = DataBuilderParams(query: query);

    final controller = StreamController<BodyState<T>>();
    StreamSubscription<BodyState<T>>? loadSubscription;

    void addStateSnapshot() {
      if (controller.isClosed || state == null) {
        return;
      }
      if (state!.hasData(params.query)) {
        controller.add(BodyState.data(state!.data(params.query)));
        return;
      }
      if (loadSubscription != null) {
        controller.add(BodyState.loading());
        return;
      }
      loadSubscription = _loadAfterState(params, allowCache, true).listen(
        (event) {
          if (!controller.isClosed) {
            controller.add(event);
          }
        },
        onError: controller.addError,
        onDone: () => loadSubscription = null,
      );
    }

    controller.onListen = () {
      state?.addListener(addStateSnapshot);
      loadSubscription = _loadState(
        params: params,
        allowState: allowState,
        allowCache: allowCache,
        allowData: allowData,
      ).listen(
        (event) {
          if (!controller.isClosed) {
            controller.add(event);
          }
        },
        onError: controller.addError,
        onDone: () => loadSubscription = null,
      );
    };

    controller.onCancel = () {
      state?.removeListener(addStateSnapshot);
      loadSubscription?.cancel();
      loadSubscription = null;
      _disposeQueryIfUnused(query);
      if (!controller.isClosed) {
        controller.close();
      }
    };

    return controller.stream;
  }

  Stream<BodyState<T>> _loadState({
    required DataBuilderParams params,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
  }) async* {
    if (!allowState) {
      yield* _loadAfterState(params, allowCache, allowData);
      return;
    }
    if (state?.hasData(params.query) == true) {
      yield BodyState.data(state!.data(params.query));
      return;
    }
    // allowData is set to true (by force) to avoid being in a situation with no data
    yield* _loadAfterState(params, allowCache, true);
  }

  Stream<BodyState<T>> _loadAfterState(
    DataBuilderParams params,
    bool allowCache,
    bool allowData,
  ) async* {
    if (allowCache) {
      yield* _loadCache(params, allowData: allowData);
    } else if (allowData) {
      BodyState<T> bState = initialState(params.query).copy(isLoading: true);
      yield bState;
      yield* _loadData(params);
    }
  }

  Stream<BodyState<T>> _loadCache(
    DataBuilderParams params, {
    bool allowData = true,
  }) async* {
    yield BodyState.loading();
    if (cache == null) {
      if (allowData) {
        yield* _loadData(params);
      }
      return;
    }
    try {
      final T? data = await cache!(params);
      if (data != null) {
        yield BodyState.cache(data, isLoading: allowData);
      }
      if (allowData) {
        yield* _loadData(params);
      }
    } catch (e, s) {
      debugPrint('Failed to load cache: $e\n$s');
      yield BodyState.error(e, s);
    }
  }

  Stream<BodyState<T>> _loadData(DataBuilderParams params) async* {
    try {
      yield BodyState.data(await data(params));
    } catch (e, s) {
      debugPrint('Failed to load data: $e\n$s');
      yield BodyState.error(e, s);
    }
  }
}

class CachedBodyProvider<T> extends BodyProvider<T> {
  final CacheEntry<T> cacheEntry;

  CachedBodyProvider({
    super.state,
    required super.data,
    required this.cacheEntry,
    super.name,
  });

  @override
  Stream<BodyState<T>> _loadAfterState(
    DataBuilderParams params,
    bool allowCache,
    bool allowData,
  ) {
    return _loadCache(params, allowData: allowData);
  }

  @override
  Stream<BodyState<T>> _loadCache(
    DataBuilderParams params, {
    bool allowData = true,
  }) async* {
    yield BodyState.loading();
    try {
      final T? data = await cacheEntry.get();
      if (data != null) {
        yield BodyState.cache(data, isLoading: allowData);
      }
      if (allowData) {
        yield* _loadData(params);
      }
    } catch (e, s) {
      debugPrint('Failed to load cache: $e\n$s');
      yield BodyState.error(e, s);
    }
  }

  @override
  Stream<BodyState<T>> _loadData(DataBuilderParams params) {
    return super._loadData(params).map((BodyState<T> state) {
      if (state.hasData) {
        T? data = state.data;
        if (data == null) {
          cacheEntry.delete();
        } else {
          cacheEntry.set(data);
        }
      }
      return state;
    });
  }
}

/// Strategy to merge data from multiple providers
/// - [allAtOne] - Emit a "loading state" without data until all providers have
/// data. Then emit a "data state" with all providers data
/// - [oneByOne] - A "loading state" is emitted along with the data of each
/// provider until all providers have data. Then emit a "data state" with all
/// providers data.
enum MergeDataStrategy {
  allAtOne,
  oneByOne,
}
