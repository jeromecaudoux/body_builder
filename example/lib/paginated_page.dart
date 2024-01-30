import 'package:body_builder/body_builder/body_builder.dart';
import 'package:body_builder/body_builder/src/paginated_response.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const int _itemsPerPage = 10;

class PaginatedPage extends StatefulWidget {
  const PaginatedPage({super.key});

  @override
  State<PaginatedPage> createState() => _PaginatedPageState();
}

class _PaginatedPageState extends State<PaginatedPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  late final PaginatedSampleState _state;

  @override
  void initState() {
    _state = context.read<PaginatedSampleState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paginated'),
        actions: [
          IconButton(
            onPressed: () {
              _state.clear();
              _key.currentState?.retry(allowState: false);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BodyBuilder(
        key: _key,
        providers: [BodyProvider(state: _state, data: _dataProvider)],
        builder: _buildListView,
      ),
    );
  }

  Widget _buildListView(Iterable<String> items) {
    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          /// - This widget will trigger [BodyBuilderState.loadMoreIfNeeded]
          /// when it is displayed on screen.
          /// - It has a simple error handling mechanism with a retry button and
          /// circular progress indicator.
          return LoadMore(_key);
        }
        return ListTile(title: Text(items.elementAt(index)));
      },
    );
  }

  /// - If you want to paginate your data, you have to use [PaginatedResponse]
  /// along with a [PaginatedState] implementation
  /// - [_state.onFetch] is called to concat the new data to the previously
  /// fetched ones and returns the complete list of items
  /// - [_state.onFetch] will check the value [PaginatedResponse.currentPage]
  /// and what we already got from the previous [PaginatedResponse] to know if
  /// we should ignore or concat data.
  ///
  /// Example: if the last currentPage was 1, we expect the next one to be 2.
  /// Any other value will result in the [PaginatedResponse] to be ignored.
  Future<Iterable<String>> _dataProvider(String? query) {
    return Future.delayed(const Duration(seconds: 2), () {
      /// The first page must be 1. the default value is 0 so you can always
      /// pass "lastPage + 1" to [PaginatedResponse].
      int lastPage = _state.get(query ?? '').page;

      /// Uncomment this to test the error handling mechanism
      // if (page == 2) {
      //   throw Exception(
      //     'When the code decides to cha-cha, we\'ve got a bug with dance moves!',
      //   );
      // }
      return PaginatedResponse<String>(
        [
          /// Generate dummy paginated data
          for (int i = 0; i < _itemsPerPage; i++)
            'Value ${lastPage * _itemsPerPage + i}',
        ],
        lastPage + 1,
        5,
      );
    }).then((response) => _state.onFetch(query ?? '', response));
  }
}

/// This is a simple implementation of [PaginatedBase]
/// Override [items], [currentPage] and [lastPage] to implement your own logic
class PaginatedResponse<T> with PaginatedBase<T> {
  final List<T> _items;
  final int _currentPage;
  final int _lastPage;

  @override
  List<T>? get items => _items;
  @override
  int? get currentPage => _currentPage;
  @override
  int? get lastPage => _lastPage;

  PaginatedResponse(this._items, this._currentPage, this._lastPage);
}
