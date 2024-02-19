import 'dart:math';

import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const int _providerCount = 20;

class MultiProversPage extends StatefulWidget {
  const MultiProversPage({super.key});

  @override
  State<MultiProversPage> createState() => _MultiProversPageState();
}

class _MultiProversPageState extends State<MultiProversPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  bool _forceThrowError = false;
  late final MultiProviderSampleState _state;

  @override
  void initState() {
    _state = context.read<MultiProviderSampleState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BodyBuilder(
        key: _key,
        providers: [
          for (var i = 0; i < _providerCount; i++)
            BodyProvider(
              name: 'Provider $i',
              state: _state.byId(i),
              cache: (_) => _cacheProvider(i),
              data: (_) => _dataProvider(i),
            )
        ],
        customBuilder: _buildBody,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Multi providers'),
      actions: [
        IconButton(
          onPressed: () {
            _forceThrowError = true;
            _key.currentState?.retry();
          },
          icon: const Icon(Icons.bug_report),
        ),
        IconButton(
          onPressed: () {
            _forceThrowError = false;
            _key.currentState?.retry();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildBody(BodyState state) {
    if (state.isLoading && !state.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      children: [
        for (var i = 0; i < _providerCount; i++)
          _buildListTile(i, state.byName<String>('Provider $i')!),
      ],
    );
  }

  Widget _buildListTile(int index, BodyState<String> state) {
    return ListTile(
      title: Text(
        state.data ?? 'No data',
        style: state.hasError
            ? const TextStyle(color: Colors.red)
            : state.isCache
                ? const TextStyle(color: Colors.blue)
                : null,
      ),
      subtitle: Text('Provider $index'),
      trailing: state.isLoading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ) : state.hasError
              ? const Icon(Icons.error, color: Colors.red)
              : const Icon(Icons.check, color: Colors.green),
    );
  }

  Future<String> _cacheProvider(int id) {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => 'Value from cache: $id',
    );
  }

  Future<String> _dataProvider(int id) {
    return Future.delayed(
      Duration(milliseconds: 1500 + (5000 * Random().nextDouble()).toInt()),
      () => 'Value from your API: $id',
    ).then((value) {
      if (_forceThrowError && Random().nextBool()) {
        throw Exception(
            'Looks like the software is salsa-ing its way into a glitchy performance!');
      }
      return _state.byId(id).onFetch(value)!;
    });
  }
}
