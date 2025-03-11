import 'package:body_builder/body_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide StateProvider;

StateNotifierProvider<SimpleNotifier<T>, T?> createStateNotifierProvider<T>() {
  return StateNotifierProvider<SimpleNotifier<T>, T?>((ref) {
    return SimpleNotifier<T>(null);
  });
}

StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>>
    createPaginatedStateNotifierProvider<T>() {
  return StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>>((ref) {
    return PaginatedNotifier<T>();
  });
}

class SimpleNotifier<T> extends StateNotifier<T?> {
  SimpleNotifier(super.state);

  T? get get => state;

  T? onFetch(T? value) {
    state = value;
    return value;
  }
}

class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(PaginatedState<T>());

  PaginatedState<T> get pState => state;
}

extension RefExt on Ref {
  ExternalStateProvider<T> asSimple<T>(
    StateNotifierProvider<SimpleNotifier<T>, T?> listenable,
  ) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    return ExternalStateProvider.from(
      ([String? query]) => read(listenable.notifier).get,
      onClear: () => read(listenable.notifier).onFetch(null),
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen<T?>(
          listenable,
          (T? previous, T? next) => listener(),
        );
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }

  ExternalStateProvider<Iterable<T>> asPaginated<T>(
    StateNotifierProvider<PaginatedNotifier<T>, PaginatedState<T>?> listenable,
  ) {
    Map<VoidCallback, ProviderSubscription> listeners = {};
    return ExternalStateProvider<Iterable<T>>.from(
      ([String? query]) => read(listenable.notifier).pState.items(query),
      onClear: () => read(listenable.notifier).pState.clear(),
      externalHasMore: ([String? query]) =>
          read(listenable.notifier).pState.hasMore(query),
      onAddListener: (VoidCallback listener) {
        listeners[listener]?.close();
        listeners[listener] = listen<PaginatedState<T>?>(
          listenable,
          (PaginatedState<T>? previous, PaginatedState<T>? next) => listener(),
        );
      },
      onRemoveListener: (VoidCallback listener) => listeners[listener]?.close(),
    );
  }
}
