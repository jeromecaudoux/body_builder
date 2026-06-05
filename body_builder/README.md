**body_builder** is a lightweight Flutter package to load UI data from state, cache, and remote sources with a consistent lifecycle.

<img src="https://raw.githubusercontent.com/jeromecaudoux/body_builder/main/body_builder/files/sample.gif" width="300" />

## How It Works

1. Create one or more `BodyProvider`s.
2. Pass them to a `BodyBuilder`.
3. Render data with `builder` or full state with `customBuilder`.

```dart
final myProvider = BodyProvider<String>(
  state: myState,
  cache: ([params]) => loadFromCache(params?.query),
  data: ([params]) => loadFromApi(params?.query),
);

BodyBuilder<String>(
  providers: [myProvider],
  builder: (data) => Text(data),
);
```

[See provider example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/example/lib/basic_sample_page.dart)

[See Riverpod adapter example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder_riverpod_adapter/example/lib/simple_page.dart)

## BodyProvider

`BodyProvider` describes how data is loaded for one source.

```dart
class BodyProvider<T> extends BodyProviderBase<T> {
  BodyProvider({
    this.state,
    this.cache,
    required this.data,
    super.name,
  });
}
```

- `state`: optional `StateProvider<T>` already holding data, useful to avoid excesive calls of `data`.
- `cache`: optional function called before `data`.
- `data`: required function that returns your latest value.
- `name`: optional name, useful with `BodyState.byName`.

Both `cache` and `data` receive optional `DataBuilderParams`:

```dart
class DataBuilderParams {
  final String? query;
  final DataState? lastPage;
}
```

Use `query` for search and `lastPage` for pagination-aware requests.

### CachedBodyProvider

Use `CachedBodyProvider` when working with `cache_annotations`.

```dart
CachedBodyProvider<User>(
  state: userState,
  cacheEntry: userCacheEntry,
  data: ([params]) => fetchUser(params?.query),
);
```

It reads from `cacheEntry` first and writes successful `data` results back to cache.

## State Providers

### SimpleStateProvider<T>

For a single value.

```dart
class UserState extends SimpleStateProvider<User> {}

final userState = UserState();
final provider = BodyProvider<User>(
  state: userState,
  data: ([params]) => api.fetchUser().then(userState.on),
);
```

### PaginatedState<T>

For paginated lists (query-aware).

```dart
class FollowersState extends PaginatedState<String> {}

final followersState = FollowersState();

Future<Iterable<String>> loadFollowers([DataBuilderParams? params]) {
  int previousPage = params?.lastPage?.page ?? -1;
  int pageToLoad = previousPage + 1; // First page to load will be 0

  return Future.delayed(const Duration(seconds: 1), () {
    return PaginatedResponse<String>(
      items: List.generate(10, (i) => 'Follower ${pageToLoad * 10 + i}'),
      page: pageToLoad,
      lastPage: 5,
    );
  }).then((response) => followersState.on(response, query: params?.query));
}
```

[See pagination example](https://github.com/jeromecaudoux/body_builder/blob/main/body_builder/example/lib/paginated_page.dart)

### RelatedStateProvider<K, T>

Map of `SimpleStateProvider<T>` by key.

```dart
class UserByIdStates extends RelatedStateProvider<String, User> {}

final users = UserByIdStates();

BodyProvider<User>(
  state: users.byId('123'),
  data: ([params]) => api.fetchUser('123').then((u) => users.on('123', u)),
);
```

### RelatedPaginatedStates<K, T>

Map of `PaginatedState<T>` by key.

## BodyBuilder

Use `GlobalKey<BodyBuilderState>` when you want to trigger retries manually.

```dart
final key = GlobalKey<BodyBuilderState>();

BodyBuilder<String>(
  key: key,
  providers: [myProvider],
  builder: (data) => Text(data),
);

// Force reload and ignore current state value
key.currentState?.retry(allowState: false);
```

### Constructor Parameters

| Name | Type | Details |
|---|---|---|
| `providers*` | `Iterable<BodyProviderBase<T>>` | Providers used to resolve data. Must not be empty. |
| `builder*` | `Function?` | Data builder. Mutually exclusive with `customBuilder`. Up to 9 provider values when combined. |
| `customBuilder*` | `CustomBuilder?` | Receives the merged `BodyState` and lets you render loading/error/data manually. |
| `progressBuilder` | `Widget?` | Custom progress widget. |
| `errorBuilder` | `ErrorBuilder?` | Custom error widget with retry callback. |
| `childWrapper` | `ChildWrapper?` | Wraps the final child and exposes state/retry/search/scroll. Can be used to implement pull-to-refresh. |
| `animationDuration` | `Duration?` | Transition duration between states (`0` disables animation). |
| `searchController` | `TextEditingController?` | Enables query-based reloads on text changes. |
| `searchFetchDelay` | `Duration` | Debounce applied when `searchController` changes. |
| `scrollController` | `ScrollController?` | Forwarded to `childWrapper` for custom scroll integrations. |
| `mergeDataStrategy` | `MergeDataStrategy` | `allAtOne` or `oneByOne` behavior when multiple providers are used. |
| `onStateChanged` | `void Function(BodyState? previous, BodyState next)?` | Called whenever merged state changes. |

### retry and reload

`BodyBuilderState` exposes:

- `retry({bool allowState = false, bool waitNextFrame = true})`
- `reload({bool allowState = false, bool allowCache = false, bool allowData = true, bool clearData = false, bool force = false, bool ignoreLoading = false})`
- `loadMoreIfNeeded()` and `hasMore()` for paginated flows.

## LoadMore

`LoadMore` can auto-trigger the next page when visible, or show a button.

```dart
LoadMore(_bKey)
```

## builder, customBuilder and BodyState

When you have a fixed number of providers, `builder` receives each provider value as positional args (up to 9):

```dart
BodyBuilder(
  providers: [p1, p2, p3],
  builder: (String data1, int data2, User data3) => const SizedBox.shrink(),
);
```

For dynamic provider counts, use `customBuilder`:

```dart
BodyBuilder(
  providers: [p1, p2],
  customBuilder: (state) {
    final user = state.byType<User>()?.data;
    final count = state.byName<int>('counter')?.data;
    return Text('user=$user count=$count');
  },
);
```

`BodyState<T>` contains:

- `bool isCache`
- `T? data`
- `bool isLoading`
- `dynamic error`
- `StackTrace? errorStack`
- `String? providerName`

## Global Defaults

You can configure default progress/error wrappers once. You can also set a default `childWrapper`, which is the recommended way to add pull-to-refresh behavior:

```dart
BodyBuilder.setDefaultConfig(
  defaultProgressBuilder: () => const Center(child: CircularProgressIndicator()),
  defaultErrorBuilder: (error, stack, retry) => Center(
    child: TextButton(onPressed: retry, child: const Text('Retry')),
  ),
  childWrapper: (child, state, onRetry, {searchController, scrollController}) {
    if (scrollController != null) {
      ...
    }
    return child;
  },
  debugLogsEnabled: false,
);
```

## More Details

<img src="https://raw.githubusercontent.com/jeromecaudoux/body_builder/main/body_builder/files/diagram.jpg" width="600" />

## Additional Information

If you find a bug or want a feature, please open an issue:
https://github.com/jeromecaudoux/body_builder/issues
