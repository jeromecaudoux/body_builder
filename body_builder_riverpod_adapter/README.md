
# body_builder_riverpod_adapter

`body_builder_riverpod_adapter` bridges `body_builder` with `flutter_riverpod`.
It lets you create Riverpod state notifiers and plug them into `BodyBuilder`
through `ref.asBodyProvider(...)`.

## Installation

Add dependencies:

```yaml
dependencies:
  body_builder: ^2.0.3
  body_builder_riverpod_adapter: ^2.0.3
  flutter_riverpod: ^3.0.3
```

## Quick Start

```dart
import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/body_builder_riverpod_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mySimpleProvider = createSimpleStateProvider<String>();

final myBodyProvider = Provider<BodyProviderBase<String>>((ref) {
  return ref.asBodyProvider(
    mySimpleProvider,
    builder: ([params]) async {
      // Return the data expected by BodyBuilder.
      return 'hello';
    },
  );
});
```

Then consume it in `BodyBuilder`:

```dart
BodyBuilder(
  providers: [ref.watch(myBodyProvider)],
  builder: (String data) => Text(data),
)
```

## Available State Helpers

- `createSimpleStateProvider<T>()`
- `createFamilySimpleStateProvider<K, T>()`
- `createPaginatedStateProvider<T>()`
- `createPaginatedDataStateProvider<T>()`
- `createFamilyPaginatedStateProvider<K, T>()`
- `createAutoDisposeSimpleStateProvider<T>()`
- `createAutoDisposeFamilySimpleStateProvider<K, T>()`
- `createAutoDisposePaginatedStateProvider<T>()`
- `createAutoDisposeFamilyPaginatedStateProvider<K, T>()`

## Usage Patterns

### Simple State

```dart
final simpleStateProvider = createSimpleStateProvider<String>();

final simpleBodyProvider = Provider<BodyProviderBase<String>>((ref) {
  return ref.asBodyProvider(
    simpleStateProvider,
    builder: ([params]) => ref.read(repoProvider).fetchSimple(),
  );
});
```

### Family Simple State

```dart
final familySimpleStateProvider =
    createAutoDisposeFamilySimpleStateProvider<int, String>();

final familySimpleBodyProvider = Provider.family<BodyProviderBase<String>, int>(
  (ref, id) {
    return ref.asBodyProvider(
      familySimpleStateProvider(id),
      builder: ([params]) => ref.read(repoProvider).fetchRelatedSimple(id),
    );
  },
);
```

### Paginated State

```dart
final paginatedStateProvider = createPaginatedStateProvider<String>();

final paginatedBodyProvider =
    Provider<BodyProviderBase<Iterable<String>>>((ref) {
  return ref.asBodyProvider(
    paginatedStateProvider,
    builder: ([params]) => ref.read(repoProvider).fetchPaginated(params),
  );
});
```

### Family Paginated State

```dart
final familyPaginatedStateProvider =
    createFamilyPaginatedStateProvider<int, String>();

final familyPaginatedBodyProvider =
    Provider.family<BodyProviderBase<Iterable<String>>, int>((ref, id) {
  return ref.asBodyProvider(
    familyPaginatedStateProvider(id),
    builder: ([params]) => ref.read(repoProvider).fetchById(id, params),
  );
});
```

### Refresh, Invalidate

`BodyBuilder` listens to the adapter state stream.

- If you update the notifier state, `BodyBuilder` displays the new value directly.
- If you invalidate the Riverpod state provider, the state is reset and `BodyBuilder` runs the loader again.

```dart
final key = GlobalKey<BodyBuilderState>();

BodyBuilder(
  key: key,
  providers: [ref.watch(myBodyProvider)],
  builder: (String data) => Text(data),
);

// 1) Update state only: UI updates immediately without forcing a new fetch.
ref.read(mySimpleProvider.notifier).on('Updated elsewhere');

// 2) Force a reload from the data builder.
key.currentState?.retry(allowState: false);

// 3) Invalidate provider: clears state and triggers data loading again.
ref.invalidate(mySimpleProvider);

```

## Notes

- `ref.asBodyProvider(...)` is the single adapter entry point for simple and paginated states.
- For family providers, pass the resolved provider instance (for example `myFamilyProvider(id)`).
- The adapter updates supported notifier state internally after successful fetches.

## Example App

- Simple: https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/simple_page.dart
- Auto dispose: https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/autodispose_sample_page.dart
- Related simple: https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/related_simple_page.dart
- Paginated: https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/paginated_page.dart
- Related paginated: https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/related_paginated_page.dart

## Issues

If you find a bug or want a feature, open an issue:
https://github.com/jeromecaudoux/body_builder/issues
