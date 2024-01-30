import 'package:body_builder/body_builder.dart';
import 'package:body_builder/src/paginated_response.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchSamplePage extends StatefulWidget {
  const SearchSamplePage({super.key});

  @override
  State<SearchSamplePage> createState() => _SearchSamplePageState();
}

class _SearchSamplePageState extends State<SearchSamplePage> {
  final TextEditingController _controller = TextEditingController();
  late final SearchSampleState _state;

  @override
  void initState() {
    _state = context.read<SearchSampleState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search sample')),
      body: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search',
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          Expanded(
            child: BodyBuilder<Iterable<String>>(
              searchController: _controller,
              providers: [BodyProvider(state: _state, data: _dataProvider)],
              builder: _buildListView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(Iterable<String> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items found'));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(items.elementAt(index)),
      ),
    );
  }

  Future<Iterable<String>> _dataProvider(String? query) {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => _animals.where((element) =>
          element.toLowerCase().contains(query?.toLowerCase() ?? '')),
    ).then(
      /// - The state will store the data in memory for each query.
      /// The BodyBuilder will then skip the data provider and use the
      /// state's data if the same query is requested again.
      /// - SinglePageState is a here to help when the search response
      /// is not paginated.
      (value) => _state.onFetch(query, SinglePageState(value)),
    );
  }

  List<String> get _animals => [
        'Dog',
        'Cat',
        'Elephant',
        'Lion',
        'Tiger',
        'Giraffe',
        'Monkey',
        'Zebra',
        'Dolphin',
        'Penguin',
        'Koala',
        'Panda',
        'Kangaroo',
        'Rhino',
        'Bear',
        'Fox',
        'Horse',
        'Owl',
        'Penguin',
        'Wolf'
      ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
