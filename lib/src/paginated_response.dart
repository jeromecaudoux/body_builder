abstract class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  String? path;

  /// The items of the current page
  Iterable<T>? items;

  /// The current page index
  int? currentPage;

  /// The last page index
  int? lastPage;
}

class SinglePageState<T> extends PaginatedBase<T> {
  @override
  int? get currentPage => 1;
  @override
  int? get lastPage => 1;

  SinglePageState(Iterable<T>? items) {
    this.items = items;
  }
}
