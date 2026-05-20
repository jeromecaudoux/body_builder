import 'dart:async';

import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/src/adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as rp;

extension BodyProviderRefExt on Ref {
  BodyProviderBase<T> asBodyProvider<T>(
    rp.StateNotifierProvider? state, {
    CacheProvider<T>? cache,
    required DataProvider<T> builder,
    String? name,
  }) {
    return RiverpodBodyProvider<T>(
      ref: this,
      state: state,
      cache: cache,
      builder: builder,
      name: name,
    );
  }
}

class RiverpodBodyProvider<T> extends BodyProviderBase<T> {
  final Ref ref;
  final rp.StateNotifierProvider? state;
  final CacheProvider<T>? cache;
  final DataProvider<T> builder;

  RiverpodBodyProvider({
    required this.ref,
    this.state,
    this.cache,
    required this.builder,
    super.name,
  });

  rp.StateNotifierProvider? get _state {
    if (state == null) return null;
    final provider = state!;
    if (provider is rp.StateNotifierProvider<rp.StateNotifier<T?>, T?>) {
      return provider;
    }
    if (provider is rp
        .StateNotifierProvider<PaginatedDataNotifier, Map<String, DataState>>) {
      return provider;
    }
    throw ArgumentError(
      'Invalid provider type: expected StateNotifierProvider<StateNotifier<T?>, T?> or StateNotifierProvider<PaginatedDataNotifier<T>, DataState<T>>, got ${provider.runtimeType}',
    );
  }

  T? _resolve(rp.StateNotifierProvider? provider, String? query) {
    if (provider == null) return null;
    final pData = ref.read(provider.notifier);
    return _extractData(pData, query);
  }

  T? _extractData(Object? value, String? query) {
    if (value == null) return null;
    if (value is SimpleDataNotifier) return value.data as T?;
    if (value is PaginatedDataNotifier) {
      return value.get(query).items as T?;
    }
    throw ArgumentError(
      'Invalid state type: expected $T? or PaginatedDataNotifier<$T>, got ${value.runtimeType}',
    );
  }

  @override
  BodyState<T> initialState(String? query) {
    if (state != null) {
      final T? data = _resolve(_state, query);
      if (data != null) {
        return BodyState.data(data);
      }
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
    print(
        '-> Resolving data for provider: ${_state.runtimeType}, query: <$query>');
    // Disable state or cache providers if they are not set
    allowState = allowState && state != null;
    allowCache = allowCache && cache != null;

    final controller = StreamController<BodyState<T>>();
    ProviderSubscription<Object?>? stateSubscription;

    Future<void> emitData() async {
      if (controller.isClosed) return;

      BodyState<T> bState = initialState(query).copy(isLoading: allowData);
      controller.add(bState);
      if (allowState) {
        if (!bState.isLoading) {
          return;
        }
      }
      if (!allowData) return;
      DataBuilderParams params = DataBuilderParams(
        query: query,
        lastPage: _lastPageIfPaginated(query),
      );
      final data = await builder(params);
      print('Data fetched for provider: ${_state.runtimeType}. data=$data');
      _updateStateWithData(controller, data, params);
    }

    controller.onListen = () {
      if (state != null) {
        print('Listening to state changes for provider: ${_state.runtimeType}');
        stateSubscription = ref.listen<Object?>(_state!, (previous, next) {
          if (!controller.isClosed) {
            final T? data = _resolve(_state, query);
            if (data == null) {
              controller.add(BodyState.loading());
              unawaited(emitData());
            } else {
              controller.add(BodyState.data(data));
            }
          }
        });
      }

      unawaited(emitData());
    };

    controller.onCancel = () {
      print('Cancelling subscription for provider: ${_state.runtimeType}');
      stateSubscription?.close();
      stateSubscription = null;
      if (!controller.isClosed) {
        controller.close();
      }
    };

    ref.onDispose(() {
      print('Disposing provider: ${_state.runtimeType}');
      stateSubscription?.close();
      stateSubscription = null;
      if (!controller.isClosed) {
        controller.close();
      }
    });

    return controller.stream;
  }

  @override
  bool hasMore([String? query]) {
    if (state == null) return false;
    final provider = _state;
    if (provider == null) return false;
    final pData = ref.read(provider.notifier);
    if (pData is PaginatedDataNotifier) {
      return pData.hasMore(query);
    }
    return false;
  }

  @override
  bool get isPaginated {
    if (state == null) return false;
    final provider = _state;
    if (provider == null) return false;
    final pData = ref.read(provider.notifier);
    return pData is PaginatedDataNotifier;
  }

  DataState? _lastPageIfPaginated(String? query) {
    if (state == null) return null;
    final provider = _state;
    if (provider == null) return null;
    final pData = ref.read(provider.notifier);
    if (pData is PaginatedDataNotifier) {
      return pData.get(query);
    }
    return null;
  }

  void _updateStateWithData(
    StreamController<BodyState<T>> controller,
    dynamic data,
    DataBuilderParams params,
  ) {
    if (controller.isClosed) return;
    try {
      if (_state == null) {
        controller.add(BodyState.data(data));
      } else {
        final notifier = ref.read(_state!.notifier);
        print('Current state for provider: $notifier');
        if (notifier is SimpleDataNotifier<T>) {
          assert(
              data is T, 'Expected data of type $T, got ${data.runtimeType}');
          print('Updating state with data: $data');
          notifier.on(data as T);
        } else if (notifier is PaginatedDataNotifier) {
          print('Updating paginated state with data: $data');
          assert(data is PaginatedBase,
              'Expected data of type PaginatedBase<$T>, got ${data.runtimeType}');
          print('Updating paginated state with data: $data');
          notifier.on(data as PaginatedBase, query: params.query);
        } else {
          throw ArgumentError(
            'Invalid state type: expected SimpleStateNotifier<$T>, got ${notifier.runtimeType}',
          );
        }
      }
    } catch (e, s) {
      debugPrint('Error updating state with data: $e\n$s');
      rethrow;
    }
  }
}
