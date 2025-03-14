import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/core/dummy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RelatedSimplePage extends ConsumerStatefulWidget {
  const RelatedSimplePage({super.key});

  @override
  ConsumerState<RelatedSimplePage> createState() => _PaginatedPageState();
}

class _PaginatedPageState extends ConsumerState<RelatedSimplePage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  int _userId = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Related simple'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(myRelatedSimpleProvider)?.clear();
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
              providers: [ref.read(myRelatedSimpleBProvider(_userId))],
              builder: _buildListView,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(String data) {
    return Center(child: Text(data));
  }
}
