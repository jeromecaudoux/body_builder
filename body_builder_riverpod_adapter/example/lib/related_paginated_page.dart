import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/core/dummy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RelatedPaginatedPage extends ConsumerStatefulWidget {
  const RelatedPaginatedPage({super.key});

  @override
  ConsumerState<RelatedPaginatedPage> createState() => _PaginatedPageState();
}

class _PaginatedPageState extends ConsumerState<RelatedPaginatedPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  int _userId = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Related paginated'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(myRelatedPaginatedProvider).clear();
              _key.currentState?.retry();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _userId--;
              });
              _key.currentState?.retry(allowState: true);
            },
            icon: const Icon(Icons.remove),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _userId++;
              });
              _key.currentState?.retry(allowState: true);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Text('Current user id: $_userId'),
          Expanded(
            child: BodyBuilder(
              key: _key,
              providers: [ref.read(myRelatedPaginatedBProvider(_userId))],
              builder: _buildListView,
            ),
          ),
        ],
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
}
