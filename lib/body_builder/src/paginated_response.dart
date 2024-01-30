mixin class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  String? path;

  /// The items of the current page
  Iterable<T>? items;

  /// The current page index
  int? currentPage;

  /// The last page index
  int? lastPage;
}

class SinglePageState<T> with PaginatedBase<T> {
  final Iterable<T> data;

  @override
  Iterable<T>? get items => data;
  @override
  int? get currentPage => 1;
  @override
  int? get lastPage => 1;

  SinglePageState(this.data);
}
