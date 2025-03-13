import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/src/state_notifiers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide StateProvider;

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
    RelatedPaginatedStates<K, T>> createRelatedPaginatedStateProvider<K, T>() {
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
      ([String? query]) => read(listenable.notifier).get,
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
    Map<VoidCallback, ProviderSubscription> listeners = {};
    PaginatedState<T> pState = read(listenable.notifier).pState;
    return ExternalStateProvider<Iterable<T>>.from(
      pState.data,
      onClear: pState.clear,
      externalHasMore: pState.hasMore,
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen(listenable, (_, __) => listener());
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }

  ExternalStateProvider<Iterable<T>> asFamilyPaginated<K, T>(
    StateNotifierProvider<RelatedPaginatedNotifier<K, T>,
            RelatedPaginatedStates<K, T>?>
        listenable,
    K id,
  ) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    PaginatedState<T> pState = read(listenable.notifier).rpState.byId(id);
    return ExternalStateProvider<Iterable<T>>.from(
      pState.data,
      onClear: pState.clear,
      externalHasMore: pState.hasMore,
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen(listenable, (_, __) => listener());
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }

  ExternalStateProvider<T> asFamilySimple<K, T>(
    StateNotifierProvider<RelatedSimpleNotifier<K, T>,
            RelatedStateProvider<K, T>?>
        listenable,
    K id,
  ) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    SimpleStateProvider<T> state = read(listenable.notifier).rsState.byId(id);
    return ExternalStateProvider.from(
      state.data,
      onClear: state.clear,
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen(listenable, (_, __) => listener());
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }
}
