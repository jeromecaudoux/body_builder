import 'dart:async';
import 'dart:developer';

import 'package:body_builder/body_builder.dart';
import 'package:cache_annotations/annotations.dart';
import 'package:collection/collection.dart';
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

  BodyState<T> initialState(String? query);

  Stream<BodyState<T>> resolve({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
  });
}

class BodyProvider<T> extends BodyProviderBase<T> {
  final StateProvider<T>? state;
  final CacheProvider<T>? cache;
  final DataProvider<T> data;

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

  @override
  BodyState<T> initialState(String? query) {
    if (state?.hasData(query) == true) {
      return BodyState.data(state!.data(query));
    }
    return BodyState.loading();
  }

  @override
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
      state!.addListener(addStateSnapshot);
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

    controller.onCancel = () async {
      state?.removeListener(addStateSnapshot);
      await loadSubscription?.cancel();
      loadSubscription = null;
      if (!controller.isClosed) {
        await controller.close();
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

extension ProviderExt on Iterable<BodyProviderBase> {
  BodyState initialState(
    String? query, {
    required MergeDataStrategy mergeStrategy,
  }) {
    return _merge(
      map((state) => state.initialState(query).copy(providerName: state.name)),
      mergeStrategy,
    ).copy(combinedStates: true);
  }

  Stream<BodyState> resolve({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
    MergeDataStrategy mergeStrategy = MergeDataStrategy.allAtOne,
  }) {
    return Rx.combineLatest(
      map(
        (provider) => provider
            .resolve(
              query: query,
              allowState: allowState,
              allowCache: allowCache,
              allowData: allowData,
            )
            .map((BodyState event) => event.copy(providerName: provider.name)),
      ),
      (Iterable<BodyState> states) => _merge(states, mergeStrategy),
    ).map((event) {
      BodyState bState = event.copy(combinedStates: true);
      if (kDebugMode && BodyBuilderConfig.instance.debugLogsEnabled) {
        log('--- ProviderExt -> resolved -> Start ---');
        log('Merged state: $bState');
        log('--- ProviderExt -> resolved -> End ---');
      }
      return bState;
    });
  }

  BodyState _merge(
    Iterable<BodyState> states,
    MergeDataStrategy strategy,
  ) {
    if (kDebugMode && BodyBuilderConfig.instance.debugLogsEnabled) {
      _debugPrintStates(states);
    }
    bool oneIsLoading = states.any((state) => state.isLoading);
    bool oneIsCache = states.any((state) => state.isCache);
    bool allHaveData = states.every((state) => state.hasData);
    if (allHaveData) {
      if (oneIsCache) {
        return BodyState.cache(states, isLoading: oneIsLoading);
      }
      return BodyState.data(states, isLoading: oneIsLoading);
    }

    BodyState? errorState =
        states.firstWhereOrNull((state) => state.error != null);
    if (errorState != null) {
      return BodyState.error(errorState.error!, errorState.errorStack)
          .copy(data: states, isLoading: oneIsLoading);
    }
    switch (strategy) {
      case MergeDataStrategy.allAtOne:
        return BodyState.loading().copy(
          data: states
              .map((state) => state.copy(clearData: true, isLoading: true))
              .toList(),
        );
      case MergeDataStrategy.oneByOne:
        return BodyState.loading().copy(data: states);
    }
  }

  void _debugPrintStates(Iterable<BodyState<dynamic>> states) {
    log('--- BodyBuilder -> OnEvent Start ---');
    log('Providers: ${map((e) => e.name ?? '${e.runtimeType}')}');
    for (var state in states) {
      log('State: $state');
    }
    log('--- BodyBuilder -> OnEvent End ---');
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
