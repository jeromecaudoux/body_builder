import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/src/state_notifiers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' hide StateProvider;

StateNotifierProvider<SimpleNotifier<T>, T?> createSimpleStateProvider<T>() {
  return StateNotifierProvider<SimpleNotifier<T>, T?>((ref) {
    return SimpleNotifier<T>(null);
  });
}

StateNotifierProvider<RelatedSimpleNotifier<K, T>, RelatedStateProvider<K, T>?>
    createFamilySimpleStateProvider<K, T>() {
  return StateNotifierProvider<RelatedSimpleNotifier<K, T>,
      RelatedStateProvider<K, T>?>((ref) {
    return RelatedSimpleNotifier<K, T>();
  });
}

StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>>
    createPaginatedStateProvider<T>() {
  return StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>>((ref) {
    return PaginatedNotifier<T>();
  });
}

StateNotifierProvider<RelatedPaginatedNotifier<K, T>,
    RelatedPaginatedStates<K, T>> createFamilyPaginatedStateProvider<K, T>() {
  return StateNotifierProvider<RelatedPaginatedNotifier<K, T>,
      RelatedPaginatedStates<K, T>>((ref) {
    return RelatedPaginatedNotifier<K, T>();
  });
}

extension RefExt on Ref {
  ExternalStateProvider<T> asSimple<T>(
    StateNotifierProvider<SimpleNotifier<T>, T?> listenable,
  ) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    return ExternalStateProvider.from(
      ([String? query]) => read(listenable.notifier).data,
      onClear: () => read(listenable.notifier).clear(),
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen(listenable, (_, __) => listener());
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }

  ExternalStateProvider<Iterable<T>> asPaginated<T>(
    StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>?> listenable,
  ) {
    return _createStateProvider(
      () => read(listenable.notifier).pState,
      listenable,
      isPaginated: true,
    );
  }

  ExternalStateProvider<T> asFamilySimple<K, T>(
    StateNotifierProvider<RelatedSimpleNotifier<K, T>,
            RelatedStateProvider<K, T>?>
        listenable,
    K id,
  ) {
    StateProvider<T> pState() => read(listenable.notifier).byId(id);
    return ExternalStateProvider<T>.from(
      ([String? query]) => pState().data(query),
      onClear: () => pState().clear(),
      onAddListener: (VoidCallback listener) => pState().addListener(listener),
      onRemoveListener: (VoidCallback listener) =>
          pState().removeListener(listener),
    );
  }

  ExternalStateProvider<Iterable<T>> asFamilyPaginated<K, T>(
    StateNotifierProvider<RelatedPaginatedNotifier<K, T>,
            RelatedPaginatedStates<K, T>?>
        listenable,
    K id,
  ) {
    return _createStateProvider(
      () => read(listenable.notifier).byId(id),
      listenable,
      isPaginated: true,
    );
  }

  ExternalStateProvider<T> _createStateProvider<T>(
    StateProvider<T> Function() pState,
    StateNotifierProvider listenable, {
    bool isPaginated = false,
  }) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    return ExternalStateProvider<T>.from(
      ([String? query]) => pState().data(query),
      onClear: () => pState().clear(),
      externalHasMore:
          !isPaginated ? null : ([String? query]) => pState().hasMore(query),
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen(listenable, (_, __) => listener());
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }
}
