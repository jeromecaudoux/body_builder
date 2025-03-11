final class BodyState<T> {
  // UI state values
  final bool isCache;
  final T? data;
  final bool isLoading;
  final Object? error;
  final StackTrace? errorStack;

  // Contextual values
  final bool combinedStates;
  final String? providerName;

  BodyState._({
    this.data,
    this.isCache = false,
    this.isLoading = false,
    this.error,
    this.errorStack,
    this.combinedStates = false,
    this.providerName,
  });

  BodyState<H> copy<H>({
    H? data,
    bool? isCache,
    bool? isLoading,
    Object? error,
    StackTrace? errorStack,
    bool? combinedStates,
    String? providerName,
  }) {
    return BodyState._(
      data: (data ?? this.data) as H?,
      isCache: isCache ?? this.isCache,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      errorStack: errorStack ?? this.errorStack,
      combinedStates: combinedStates ?? this.combinedStates,
      providerName: providerName ?? this.providerName,
    );
  }

  BodyState<U> cast<U>() => copy(data: data as U?);

  bool get hasData {
    if (combinedStates) {
      return (data as Iterable?)?.every((state) => state.hasData) ?? false;
    }
    return data != null;
  }

  bool get hasError => error != null;

  BodyState<H>? byName<H>(String name) =>
      where<H>((state) => state.providerName == name);

  BodyState<H>? byType<H>() => where<H>((state) => state.data is H);

  BodyState<H>? where<H>(bool Function(BodyState) test) {
    if (combinedStates && data != null) {
      for (BodyState state in data as Iterable) {
        if (test(state)) {
          return state.cast<H>();
        }
      }
    }
    return null;
  }

  BodyState.loading() : this._(isLoading: true);

  BodyState.cache(T data, {bool isLoading = false})
      : this._(data: data, isCache: true, isLoading: isLoading);

  // null is a valid value if loading is false and error is not null
  BodyState.data(T? data, {bool isLoading = false})
      : this._(data: data, isLoading: isLoading);

  BodyState.error(Object error, StackTrace? stackTrace)
      : this._(error: error, errorStack: stackTrace);

  @override
  String toString() {
    return 'BodyState{providerName: $providerName, combinedStates: $combinedStates, '
        'isCache: $isCache, isLoading: $isLoading, error: ${error != null}, '
        'data: $data}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyState &&
          runtimeType == other.runtimeType &&
          isCache == other.isCache &&
          data == other.data &&
          isLoading == other.isLoading &&
          error == other.error &&
          errorStack == other.errorStack;

  @override
  int get hashCode =>
      isCache.hashCode ^
      data.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      errorStack.hashCode;
}
