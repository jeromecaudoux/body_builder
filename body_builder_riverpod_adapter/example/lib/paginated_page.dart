import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/core/dummy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaginatedPage extends ConsumerStatefulWidget {
  const PaginatedPage({super.key});

  @override
  ConsumerState<PaginatedPage> createState() => _PaginatedPageState();
}

class _PaginatedPageState extends ConsumerState<PaginatedPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paginated'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(myPaginatedProvider).clear();
              _key.currentState?.retry();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BodyBuilder(
        key: _key,
        providers: [ref.read(myPaginatedBProvider)],
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
}
