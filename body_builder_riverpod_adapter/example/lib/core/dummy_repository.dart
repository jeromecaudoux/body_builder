import 'package:body_builder/body_builder.dart';
import 'package:body_builder_riverpod_adapter/body_builder_riverpod_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State and BodyProvider for the simple state example
final mySimpleProvider = createSimpleStateProvider<String>();

final myBProvider = Provider<BodyProviderBase<String>>(
  (Ref ref) {
    return ref.asBodyProvider(
      mySimpleProvider,
      builder: ([params]) => ref.read(dummyRepProvider).fetchSimple(),
    );
  },
);

/// State and BodyProvider for the simple auto dispose state example
final myAutoDisposeSimpleProvider =
    createAutoDisposeSimpleStateProvider<String>();

final myAutoDisposeBProvider = Provider<BodyProviderBase<String>>(
  (Ref ref) {
    return ref.asBodyProvider(
      myAutoDisposeSimpleProvider,
      builder: ([params]) =>
          ref.read(dummyRepProvider).fetchAutoDisposeSimple(),
    );
  },
);

/// State and BodyProvider for the related simple state example
final myRelatedSimpleProvider =
    createAutoDisposeFamilySimpleStateProvider<int, String>();

final myRelatedSimpleBProvider = Provider.family<BodyProviderBase<String>, int>(
  (Ref ref, int id) {
    return ref.asBodyProvider(
      myRelatedSimpleProvider(id),
      builder: ([params]) => ref.read(dummyRepProvider).fetchRelatedSimple(id),
    );
  },
);

/// State and BodyProvider for the paginated state example
final myPaginatedProvider = createPaginatedStateProvider<String>();

final myPaginatedBProvider = Provider<BodyProviderBase<Iterable<String>>>(
  (Ref ref) {
    return ref.asBodyProvider(
      myPaginatedProvider,
      builder: ([params]) => ref.read(dummyRepProvider).fetchPaginated(params),
    );
  },
);

/// State and BodyProvider for the related paginated state example
final myRelatedPaginatedProvider =
    createFamilyPaginatedStateProvider<int, String>();

final myRelatedPaginatedBProvider =
    Provider.family<BodyProviderBase<Iterable<String>>, int>(
  (Ref ref, int id) {
    return ref.asBodyProvider(
      myRelatedPaginatedProvider(id),
      builder: ([params]) => ref.read(dummyRepProvider).fetchById(id, params),
    );
  },
);

final dummyRepProvider = Provider<DummyRepository>(
  (ref) {
    return DummyRepository();
  },
);

class DummyRepository {
  static const int _itemsPerPage = 2;

  DummyRepository();

  Future<String> fetchSimple() async {
    // You are in charge of updating the state by calling the `on` method
    return await _myFakeApiCall();
  }

  Future<String> fetchAutoDisposeSimple() async {
    return await _myFakeApiCall();
  }

  Future<String> fetchRelatedSimple(int id) async {
    // You are in charge of updating the state by calling the `on` method
    return await _myFakeApiCall(id);
  }

  Future<String> _myFakeApiCall([int? id]) async {
    await Future.delayed(const Duration(seconds: 1));
    DateTime now = DateTime.now();
    debugPrint('--> Doing fake API call.');
    // throw Exception(
    //   'When the code decides to cha-cha, we\'ve got a bug with dance moves!',
    // );
    return '${id == null ? '' : '[$id]'} '
        'Fetch date: ${now.hour}h ${now.minute}m ${now.second}s';
  }

  Future<PaginatedResponse<String>> fetchPaginated(
    DataBuilderParams? params,
  ) async {
    return await _dummyResponse(params, null);
  }

  Future<PaginatedResponse<String>> fetchById(
    int id,
    DataBuilderParams? params,
  ) async {
    return await _dummyResponse(params, id);
  }

  Future<PaginatedResponse<String>> _dummyResponse(
    DataBuilderParams? params, [
    int? id,
  ]) async {
    String? query = params?.query;
    int previousPage = params?.lastPage?.page ?? -1;
    int pageToLoad = previousPage + 1;
    debugPrint('Fetching previousPage=$previousPage, nextPage=$pageToLoad');
    await Future.delayed(const Duration(seconds: 1));

    // return PaginatedResponse<String>(
    //   items: [
    //   ],
    //   page: pageToLoad,
    //   lastPage: 5000,
    // );
    /// Uncomment this to test the error handling mechanism
    // if (previousPage == 2) {
    //   throw Exception(
    //     'When the code decides to cha-cha, we\'ve got a bug with dance moves!',
    //   );
    // }
    return PaginatedResponse<String>(
      items: [
        /// Generate dummy paginated data
        for (int i = 0; i < _itemsPerPage; i++)
          '${id == null ? '' : '[$id]'} Value ${pageToLoad * _itemsPerPage + i} '
              'p=$pageToLoad, ${query?.isNotEmpty == true ? '($query)' : '<empty query>'}',
      ],
      page: pageToLoad,
      lastPage: 5,
    );
  }
}
