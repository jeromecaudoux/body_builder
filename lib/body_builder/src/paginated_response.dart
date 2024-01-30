mixin class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  String? path;
  /// The items of the current page
  List<T>? items;
  /// The current page index
  int? currentPage;
  /// The last page index
  int? lastPage;
}
