import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/core/dummy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoDisposeSimplePage extends ConsumerStatefulWidget {
  const AutoDisposeSimplePage({super.key});

  @override
  ConsumerState<AutoDisposeSimplePage> createState() =>
      _AutoDisposeSimplePageState();
}

class _AutoDisposeSimplePageState extends ConsumerState<AutoDisposeSimplePage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic auto dispose'),
        actions: [
          IconButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (context) => SizedBox(
                height: 200,
                child: BodyBuilder(
                  providers: [ref.read(myAutoDisposeBProvider)],
                  builder: (String data) => Center(child: Text(data)),
                ),
              ),
            ),
            tooltip: 'Show value in dialog',
            icon: const Icon(Icons.remove_red_eye_sharp),
          ),
          IconButton(
            onPressed: () => ref
                .read(myAutoDisposeSimpleProvider.notifier)
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
        providers: [ref.read(myAutoDisposeBProvider)],
        builder: (String data) => Center(child: Text(data)),
      ),
    );
  }
}
