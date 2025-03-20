import 'dart:async';
import 'dart:developer';

import 'package:body_builder/body_builder.dart';
import 'package:cache_annotations/annotations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

typedef CacheProvider<T> = Future<T?> Function(String? query);
typedef DataProvider<T> = Future<T> Function(String? query);

abstract class BodyProviderBase<T> {
  final String? name;

  const BodyProviderBase({this.name});

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

  const BodyProvider({
    this.state,
    this.cache,
    required this.data,
    super.name,
  });

  bool get isPaginated => state?.isPaginated == true;

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
  }) async* {
    // Disable state or cache providers if they are not set
    allowState = allowState && state != null;
    allowCache = allowCache && cache != null;

    yield* _loadState(
      query: query,
      allowState: allowState,
      allowCache: allowCache,
      allowData: allowData,
    );
  }

  Stream<BodyState<T>> _loadState({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
  }) async* {
    if (!allowState) {
      yield* _loadAfterState(query, allowCache, allowData);
      return;
    }
    if (state?.hasData(query) == true) {
      yield BodyState.data(state!.data(query));
      return;
    }
    // allowData is set to true (by force) to avoid being in a situation with no data
    yield* _loadAfterState(query, allowCache, true);
  }

  Stream<BodyState<T>> _loadAfterState(
    String? query,
    bool allowCache,
    bool allowData,
  ) async* {
    if (allowCache) {
      yield* _loadCache(query, allowData: allowData);
    } else if (allowData) {
      // #loading is emitted here only and not inside _loadData to avoid
      // clearing the data from cache between the cache and data providers
      yield BodyState.loading();
      yield* _loadData(query);
    }
  }

  Stream<BodyState<T>> _loadCache(
    String? query, {
    bool allowData = true,
  }) async* {
    yield BodyState.loading();
    if (cache == null) {
      if (allowData) {
        yield* _loadData(query);
      }
      return;
    }
    try {
      final T? data = await cache!(query);
      if (data != null) {
        yield BodyState.cache(data, isLoading: allowData);
      }
      if (allowData) {
        yield* _loadData(query);
      }
    } catch (e, s) {
      debugPrint('Failed to load cache: $e\n$s');
      yield BodyState.error(e, s);
    }
  }

  Stream<BodyState<T>> _loadData(String? query) async* {
    try {
      yield BodyState.data(await data(query));
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
    String? query,
    bool allowCache,
    bool allowData,
  ) {
    return _loadCache(query, allowData: allowData);
  }

  @override
  Stream<BodyState<T>> _loadCache(
    String? query, {
    bool allowData = true,
  }) async* {
    yield BodyState.loading();
    try {
      final T? data = await cacheEntry.get();
      if (data != null) {
        yield BodyState.cache(data, isLoading: allowData);
      }
      if (allowData) {
        yield* _loadData(query);
      }
    } catch (e, s) {
      debugPrint('Failed to load cache: $e\n$s');
      yield BodyState.error(e, s);
    }
  }

  @override
  Stream<BodyState<T>> _loadData(String? query) {
    return super._loadData(query).map((BodyState<T> state) {
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
    MergeDataStrategy mergeStrategy = MergeDataStrategy.allAtOne,
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
    ).map((event) => event.copy(combinedStates: true));
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
          .copy(data: states);
    }
    switch (strategy) {
      case MergeDataStrategy.allAtOne:
        return BodyState.loading();
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
