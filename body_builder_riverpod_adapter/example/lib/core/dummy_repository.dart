import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/body_builder_riverpod_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State and BodyProvider for the simple state example
final mySimpleProvider = createSimpleStateProvider<String>();

final myBProvider = Provider<BodyProvider<String>>(
  (Ref ref) {
    return BodyProvider(
      state: ref.asSimple(mySimpleProvider),
      data: (_) => ref.read(dummyRepProvider).fetchSimple(),
    );
  },
);

/// State and BodyProvider for the related simple state example
final myRelatedSimpleProvider = createFamilySimpleStateProvider<int, String>();

final myRelatedSimpleBProvider = Provider.family<BodyProvider<String>, int>(
  (Ref ref, int id) {
    return BodyProvider(
      state: ref.asFamilySimple(myRelatedSimpleProvider, id),
      data: (query) => ref.read(dummyRepProvider).fetchRelatedSimple(id),
    );
  },
);

/// State and BodyProvider for the paginated state example
final myPaginatedProvider = createPaginatedStateProvider<String>();

final myPaginatedBProvider = Provider<BodyProvider<Iterable<String>>>(
  (Ref ref) {
    return BodyProvider(
      state: ref.asPaginated(myPaginatedProvider),
      data: (query) => ref.read(dummyRepProvider).fetchPaginated(query),
    );
  },
);

/// State and BodyProvider for the related paginated state example
final myRelatedPaginatedProvider =
    createFamilyPaginatedStateProvider<int, String>();

final myRelatedPaginatedBProvider =
    Provider.family<BodyProvider<Iterable<String>>, int>(
  (Ref ref, int id) {
    return BodyProvider(
      state: ref.asFamilyPaginated(myRelatedPaginatedProvider, id),
      data: (query) => ref.read(dummyRepProvider).fetchById(id, query),
    );
  },
);

final dummyRepProvider = Provider<DummyRepository>(
  (ref) => DummyRepository(
    myStateNotifier: ref.read(mySimpleProvider.notifier),
    myPaginatedNotifier: ref.read(myPaginatedProvider.notifier),
    myRelatedPaginatedNotifier: ref.read(myRelatedPaginatedProvider.notifier),
    myRelatedSimpleNotifier: ref.read(myRelatedSimpleProvider.notifier),
  ),
);

class DummyRepository {
  final SimpleNotifier<String> myStateNotifier;
  final PaginatedNotifier<String> myPaginatedNotifier;
  final RelatedPaginatedNotifier<int, String> myRelatedPaginatedNotifier;
  final RelatedSimpleNotifier<int, String> myRelatedSimpleNotifier;
  static const int _itemsPerPage = 10;

  DummyRepository({
    required this.myStateNotifier,
    required this.myPaginatedNotifier,
    required this.myRelatedPaginatedNotifier,
    required this.myRelatedSimpleNotifier,
  });

  Future<String> fetchSimple() async {
    // You are in charge of updating the state by calling the `on` method
    return myStateNotifier.on(await _myFakeApiCall());
  }

  Future<String> fetchRelatedSimple(int id) async {
    // You are in charge of updating the state by calling the `on` method
    return myRelatedSimpleNotifier.byId(id).on(await _myFakeApiCall(id));
  }

  Future<String> _myFakeApiCall([int? id]) async {
    await Future.delayed(const Duration(seconds: 1));
    DateTime now = DateTime.now();
    return '${id == null ? '' : '[$id]'} '
        'Fetch date: ${now.hour}h ${now.minute}m ${now.second}s';
  }

  Future<Iterable<String>> fetchPaginated(String? query) async {
    PaginatedState<String> state = myPaginatedNotifier.pState;
    // Get the previous page from the state (corresponding to the id)
    int previousPage = state.get(query).page;
    // Don't forget to update the state by calling the `on` method
    return state.on(await _dummyResponse(previousPage), query: query);
  }

  Future<Iterable<String>> fetchById(int id, String? query) async {
    // Use the `byId` method to get the state of a specific id
    PaginatedState<String> state = myRelatedPaginatedNotifier.byId(id);
    // Get the previous page from the state (corresponding to the id)
    int previousPage = state.get(query).page;
    // Don't forget to update the state by calling the `on` method
    return state.on(await _dummyResponse(previousPage, id), query: query);
  }

  Future<PaginatedResponse<String>> _dummyResponse(
    int previousPage, [
    int? id,
  ]) async {
    await Future.delayed(const Duration(seconds: 2));

    /// Uncomment this to test the error handling mechanism
    // if (lastPage == 2) {
    //   throw Exception(
    //     'When the code decides to cha-cha, we\'ve got a bug with dance moves!',
    //   );
    // }
    return PaginatedResponse<String>(
      items: [
        /// Generate dummy paginated data
        for (int i = 0; i < _itemsPerPage; i++)
          '${id == null ? '' : '[$id]'} Value ${previousPage * _itemsPerPage + i}',
      ],
      page: previousPage + 1,
      lastPage: 5,
    );
  }
}
