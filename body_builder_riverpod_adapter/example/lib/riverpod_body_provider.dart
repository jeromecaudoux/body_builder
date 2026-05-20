import 'dart:async';

import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/body_builder_riverpod_adapter.dart';
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
    if (provider
        is rp.StateNotifierProvider<PaginatedNotifier, PaginatedState>) {
      return provider;
    }
    throw ArgumentError(
      'Invalid provider type: expected StateNotifierProvider<StateNotifier<T?>, T?> or StateNotifierProvider<PaginatedNotifier, PaginatedState>, got ${provider.runtimeType}',
    );
  }

  T? _resolve(rp.StateNotifierProvider? provider) {
    if (provider == null) return null;
    final pData = ref.read(provider);
    return _extractData(pData);
  }

  T? _extractData(Object? value) {
    if (value == null) return null;
    if (value is T?) return value as T?;
    if (value is PaginatedState) {
      return value.hasData() ? value.data() as T? : null;
    }
    throw ArgumentError(
      'Invalid state type: expected $T? or PaginatedState<$T>, got ${value.runtimeType}',
    );
  }

  @override
  BodyState<T> initialState(String? query) {
    if (state != null) {
      final T? data = _resolve(_state);
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
    // Disable state or cache providers if they are not set
    allowState = allowState && state != null;
    allowCache = allowCache && cache != null;

    final controller = StreamController<BodyState<T>>();
    ProviderSubscription<Object?>? stateSubscription;

    Future<void> emitData() async {
      try {
        if (controller.isClosed) return;

        BodyState<T> bState = initialState(query).copy(isLoading: allowData);
        controller.add(bState);
        if (allowState) {
          if (!bState.isLoading) {
            return;
          }
        }
        if (!allowData) return;
        final data = await builder(query);
        if (!controller.isClosed) {
          controller.add(BodyState.data(data));
        }
      } catch (e, s) {
        if (!controller.isClosed) {
          controller.add(BodyState.error(e, s));
        }
      }
    }

    controller.onListen = () {
      if (state != null) {
        stateSubscription = ref.listen<Object?>(_state!, (previous, next) {
          if (!controller.isClosed) {
            final T? data = _extractData(next);
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
      stateSubscription?.close();
      stateSubscription = null;
      if (!controller.isClosed) {
        controller.close();
      }
    };

    ref.onDispose(() {
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
    final pData = ref.read(provider);
    if (pData is PaginatedState) {
      return pData.hasMore(query);
    }
    return false;
  }

  @override
  bool get isPaginated {
    if (state == null) return false;
    final provider = _state;
    if (provider == null) return false;
    final pData = ref.read(provider);
    return pData is PaginatedState;
  }
}
