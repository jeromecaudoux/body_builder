abstract class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  String? pPath;

  /// The items of the current page
  Iterable<T>? pItems;

  /// The current page index
  int? pPage;

  /// The last page index
  int? pLast;

  int? nbHits;
}

class SinglePageState<T> extends PaginatedBase<T> {
  @override
  int? get pPage => 1;
  @override
  int? get pLast => 1;

  SinglePageState(Iterable<T>? items) {
    pItems = items;
  }
}
