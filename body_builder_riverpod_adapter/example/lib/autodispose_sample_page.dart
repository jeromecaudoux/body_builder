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
              isScrollControlled: true,
              builder: (context) => SingleChildScrollView(
                child: SizedBox(
                  key: _key,
                  height: 200,
                  child: BodyBuilder(
                    providers: [ref.watch(myAutoDisposeBProvider)],
                    customBuilder: (BodyState bState) {
                      if (bState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (bState.hasError) {
                        return Center(child: Text(bState.error.toString()));
                      }
                      final String data =
                          bState.byType<String>()?.data ?? 'No data';
                      return Center(child: Text(data));
                    },
                  ),
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
            onPressed: () =>
                ref.read(myAutoDisposeSimpleProvider.notifier).clear(),
            tooltip: 'Clear state value',
            icon: const Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () => _key.currentState?.retry(allowState: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          //_buildBodyBuilder(),
          _buildBodyBuilder(),
        ],
      ),
    );
  }

  Widget _buildBodyBuilder() {
    return Column(
      children: [
        TextButton(
          onPressed: () => ref.invalidate(myAutoDisposeBProvider),
          child: const Text('Invalidate bprovider'),
        ),
        TextButton(
          onPressed: () => ref.invalidate(myAutoDisposeSimpleProvider),
          child: const Text('Invalidate state'),
        ),
        BodyBuilder(
          // key: _key,
          providers: [ref.watch(myAutoDisposeBProvider)],
          builder: (String data) => Center(child: Text(data)),
        ),
        BodyBuilder(
          providers: [ref.watch(myAutoDisposeBProvider)],
          builder: (String data) => Center(child: Text(data)),
        ),
      ],
    );
  }
}
