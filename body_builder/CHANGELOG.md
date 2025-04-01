## 1.0.16

* `LoadMore` may now trigger loadMoreIfNeeded in `didChangeDependencies`

## 1.0.15

* Add `CachedBodyProvider` which can be used along with [cache_annotations](https://pub.dev/packages/cache_annotations)

## 1.0.14

* Fix `BodyState.hasData` which was not working properly when data was null.

## 1.0.13

* `StateProvider.items` is now deprecated. Use `StateProvider.data` instead
* `SimpleStateProvider.onFetch` is now deprecated. Use `SimpleStateProvider.on` instead
* `RelatedStateProvider.onFetch` is now deprecated. Use `RelatedStateProvider.on` instead
* `PaginatedState.onFetch` is now deprecated. Use `PaginatedState.on` instead

## 1.0.12

* Add a new parameter `MergeDataStrategy` to allow different strategies when merging all providers data

## 1.0.11

* Bump `rxdart` and `collection` versions

## 1.0.10

* Fix `setState() called after dispose()` in BodyBuilderState

## 1.0.9

* `onBeforeRefresh` is now a VoidCallback? instead of a ValueChanged<T?>?
* `onRefresh` is now a VoidCallback? instead of a ValueChanged<T?>?
* Fix method `hasData` in `BodyState` when there are more than one provider
* Fix method `clear` in `RelatedPaginatedStates` and `StateProvider`. `notifyListeners` is now called after the clear
  operation

## 1.0.8

* Fix issue with nbHits not being updated when no data are available

## 1.0.6

* `PaginatedBase` and `PaginatedState` now support `nbHits` to help keeping track of a counter.

## 1.0.5

* In `BodyProvider#resolve` in order to avoid being in a situation with no data, `allowData` is now
  set to true (by force) if the state has no data.

## 1.0.4

* Add method `normalizeQuery(String? query)` to `PaginatedState` for more flexible query
  normalization
* Add static getter `Iterable<String> get queries` to `PaginatedState`
* Add method `bool has(T item)` to `DataState`

## 1.0.3

* Add missing calls to `notifyListeners()` in `RelatedStateProvider`

## 1.0.2

* The method `BodyBuilder#_hasMore()` is now public: `BodyBuilder#hasMore()`
* Add parameter `useButton`, `loadMoreBuilder` and `loadMoreLabel` to the widget `LoadMore` to allow
  more customization of the load more button.

## 1.0.1

* Updated the `README.md`to fix the broken links

## 1.0.0

* Initial version of the body builder
