## 2.0.2

* Pagination > Fix an issue when PaginatedBase is empty on the first page.

## 2.0.1

* RiverpodBodyProvider > Add missing try catch fwhile executing the builder.
* BodyBuilder > Add new OnStateChanged parameter.

## 2.0.0

* **Breaking Changes !**
* riverpod > Better support for riverpod. Impl `ref.asBodyProvider`.
* riverpod > New riverpod states to make things easier: `createSimpleStateProvider, createFamilySimpleStateProvider, createPaginatedStateProvider, createPaginatedDataStateProvider, createFamilyPaginatedStateProvider, createAutoDisposeSimpleStateProvider, createAutoDisposeFamilySimpleStateProvider, createAutoDisposePaginatedStateProvider, createAutoDisposeFamilyPaginatedStateProvider`.
* riverpod > The state is updated within the body provider. No need to update it on your side anymore.
* BodyProvider > Concurrent loading are now handled correctly to avoid calling multiple times the data loader at the same time. Works only if you reuse the same instance of a body provider.
* ChildWrapper > Search and scroll controller are now passed as parameter if you wish to add your own pull to refresh or more.
* Pull To Refresh > Removed, use child wrapper instead.

## 1.1.3

* riverpod > Add missing state notify to each states data change

## 1.1.2

* riverpod > Add support for auto dispose state

## 1.1.0

* Bump dependencies versions
* Bump `flutter_riverpod` from ^2.6.1 to ^3.0.3

## 1.0.1

* Fix state events not emitted with `asFamilySimple`

## 1.0.0

* Initial version of the body_builder_riverpod_adapter package.
* Add `createSimpleStateProvider<T>`, the equivalent of `SimpleStateProvider<T>` for Riverpod.
* Add `createPaginatedStateProvider<T>`, the equivalent of `PaginatedState<T>` for Riverpod.
* Add `createFamilySimpleStateProvider<K, T>`, the equivalent of `RelatedStateProvider<K, T>` for Riverpod.
* Add `createFamilyPaginatedStateProvider<K, T>`, the equivalent of `RelatedPaginatedStates<K, T>` for Riverpod.

