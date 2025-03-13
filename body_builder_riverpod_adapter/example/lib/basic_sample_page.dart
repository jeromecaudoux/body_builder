import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/core/dummy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BasicBodyBuilderPage extends ConsumerStatefulWidget {
  const BasicBodyBuilderPage({super.key});

  @override
  ConsumerState<BasicBodyBuilderPage> createState() =>
      _BasicBodyBuilderPageState();
}

class _BasicBodyBuilderPageState extends ConsumerState<BasicBodyBuilderPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic'),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(myStateProvider.notifier)
                .on('Value changed elsewhere'),
            tooltip: 'Change state value',
            icon: const Icon(Icons.rocket_launch),
          ),
          IconButton(
            onPressed: () => _key.currentState?.retry(allowState: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BodyBuilder(
        key: _key,
        providers: [ref.read(myBProvider)],
        builder: (String data) => Center(child: Text(data)),
      ),
    );
  }
}
