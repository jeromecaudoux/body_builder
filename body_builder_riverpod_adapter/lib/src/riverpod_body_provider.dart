import 'dart:async';

import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/src/adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as rp;
import 'package:rxdart/rxdart.dart';

extension BodyProviderRefExt on Ref {
  BodyProviderBase<T> asBodyProvider<T>(
    rp.StateNotifierProvider? state, {
    required DataProvider<T> builder,
    String? name,
  }) {
    return RiverpodBodyProvider<T>(
      ref: this,
      state: state,
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
  final Map<String, BehaviorSubject<BodyState<T>>> _subjects =
      <String, BehaviorSubject<BodyState<T>>>{};
  final Map<String, StreamSubscription<BodyState<T>>> _executions =
      <String, StreamSubscription<BodyState<T>>>{};

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
      Iterable items = value.get(query).items;
      return items.isNotEmpty ? items as T? : null;
    }
    throw ArgumentError(
      'Invalid state type: expected $T? or PaginatedDataNotifier<$T>, got ${value.runtimeType}',
    );
  }

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
      if (_state != null && !allowState) {
        ref.invalidate(_state!);
        return;
      } else {
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
      (BodyState<T> event) {
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
    if (state != null) {
      final T? data = _resolve(_state, query);
      if (data != null) {
        return BodyState.data(data);
      }
    }
    return BodyState.loading();
  }

  Stream<BodyState<T>> resolve({
    String? query,
    bool allowState = true,
    bool allowCache = false,
    bool allowData = true,
  }) {
    // Disable state or cache providers if they are not set
    allowState = allowState && state != null;

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
      _updateStateWithData(controller, data, params);
    }

    controller.onListen = () {
      if (state != null) {
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
      stateSubscription?.close();
      stateSubscription = null;
      _disposeQueryIfUnused(query);

      if (!controller.isClosed) {
        controller.close();
      }
    };

    ref.onDispose(() {
      stateSubscription?.close();
      stateSubscription = null;
      for (final sub in _executions.values) {
        sub.cancel();
      }
      for (final subject in _subjects.values) {
        subject.close();
      }
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
        if (notifier is SimpleDataNotifier<T>) {
          assert(
              data is T, 'Expected data of type $T, got ${data.runtimeType}');
          notifier.on(data as T);
        } else if (notifier is PaginatedDataNotifier) {
          assert(data is PaginatedBase,
              'Expected data of type PaginatedBase<$T>, got ${data.runtimeType}');
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
