import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/body_builder_riverpod_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myStateProvider = createSimpleStateProvider<String>();
final myPaginatedProvider = createPaginatedStateProvider<String>();

final myBProvider = Provider<BodyProvider<String>>(
  (Ref ref) {
    return BodyProvider(
      state: ref.asSimple(myStateProvider),
      data: (_) => ref.read(dummyRepProvider).fetchSingleData(),
    );
  },
);

final myPaginatedBProvider = Provider<BodyProvider<Iterable<String>>>(
  (Ref ref) {
    return BodyProvider(
      state: ref.asPaginated(myPaginatedProvider),
      data: (query) => ref.read(dummyRepProvider).fetchPaginatedData(query),
    );
  },
);

final dummyRepProvider = Provider<DummyRepository>(
  (ref) => DummyRepository(
    myStateNotifier: ref.read(myStateProvider.notifier),
    myPaginatedNotifier: ref.read(myPaginatedProvider.notifier),
  ),
);

class DummyRepository {
  final SimpleNotifier<String> myStateNotifier;
  final PaginatedNotifier<String> myPaginatedNotifier;
  static const int _itemsPerPage = 10;

  DummyRepository({
    required this.myStateNotifier,
    required this.myPaginatedNotifier,
  });

  Future<String> fetchSingleData() async {
    return myStateNotifier.on(await _myFakeApiCall());
  }

  Future<String> _myFakeApiCall() async {
    await Future.delayed(const Duration(seconds: 3));
    DateTime now = DateTime.now();
    return 'Fetch date: ${now.hour}h ${now.minute}m ${now.second}s';
  }

  Future<Iterable<String>> fetchPaginatedData(String? query) {
    PaginatedState<String> state = myPaginatedNotifier.pState;
    return Future.delayed(const Duration(seconds: 2), () {
      int previousPage = state.get(query).page;

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
            'Value ${previousPage * _itemsPerPage + i}',
        ],
        page: previousPage + 1,
        lastPage: 5,
      );
    }).then((response) => state.on(response, query: query));
  }
}
