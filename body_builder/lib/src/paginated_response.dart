abstract class PaginatedBase<T> {
  /// The path of the API request or anything else that will be used in logs
  final String? pPath;

  /// The items of the current page
  final Iterable<T> pItems;

  /// The current page index
  final int pPage;

  /// The last page index
  final int? pLast;

  /// Optional parameter to specify the limit of items per page.
  /// - Must be greater than 0 and default value is 1.
  /// - Used to detect if a page is the last one in addition to [pLast].
  ///  It can be useful when [pLast] is unknown (ex: querying Firestore).
  /// - If not provided (pLimit=1) then a last page will be detected
  /// if [pItems] is empty or if [pPage] is equal to [pLast].
  final int pLimit;

  final int? nbHits;

  const PaginatedBase._({
    this.pPath,
    required this.pItems,
    required this.pPage,
    this.pLast,
    this.pLimit = 1,
    this.nbHits,
  }) : assert(pLimit > 0, 'pLimit must be greater than 0');
}

class SinglePageState<T> extends PaginatedBase<T> {
  const SinglePageState(Iterable<T> items)
      : super._(
          pItems: items,
          pPage: 1,
          pLast: 1,
        );
}

/// This is a simple implementation of [PaginatedBase]
/// Consider directly using [PaginatedBase] instead of this class.
class PaginatedResponse<T> extends PaginatedBase<T> {
  const PaginatedResponse({
    String? path,
    required Iterable<T> items,
    required int page,
    int? lastPage,
    int limit = 1,
    super.nbHits,
  }) : super._(
          pPath: path,
          pItems: items,
          pPage: page,
          pLast: lastPage,
          pLimit: limit,
        );
}
