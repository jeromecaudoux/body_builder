abstract class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  final String? pPath;

  /// The items of the current page
  final Iterable<T>? pItems;

  /// The current page index
  final int? pPage;

  /// The last page index
  final int? pLast;

  final int? nbHits;

  const PaginatedBase._({
    this.pPath,
    this.pItems,
    this.pPage,
    this.pLast,
    this.nbHits,
  });
}

class SinglePageState<T> extends PaginatedBase<T> {
  @override
  int? get pPage => 1;
  @override
  int? get pLast => 1;

  const SinglePageState(Iterable<T>? items) : super._(pItems: items);
}

/// This is a simple implementation of [PaginatedBase]
/// Consider directly using [PaginatedBase] instead of this class.
/// Override [pItems], [pPage] and [pLast] with your own logic
class PaginatedResponse<T> extends PaginatedBase<T> {
  final List<T> _items;
  final int _currentPage;
  final int _lastPage;

  @override
  List<T>? get pItems => _items;
  @override
  int? get pPage => _currentPage;
  @override
  int? get pLast => _lastPage;

  const PaginatedResponse(this._items, this._currentPage, this._lastPage)
      : super._();
}
