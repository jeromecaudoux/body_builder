import 'package:body_builder/body_builder/body_builder.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BasicBodyBuilderPage extends StatefulWidget {
  const BasicBodyBuilderPage({super.key});

  @override
  State<BasicBodyBuilderPage> createState() => _BasicBodyBuilderPageState();
}

class _BasicBodyBuilderPageState extends State<BasicBodyBuilderPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  late final BasicSampleState _state;

  @override
  void initState() {
    _state = context.read<BasicSampleState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic'),
        actions: [
          IconButton(
            onPressed: () => _state.onFetch('Value changed in state!'),
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
        providers: [
          BodyProvider(
            state: _state,
            cache: _cacheProvider,
            data: _dataProvider,
          )
        ],
        builder: (String data) => Center(child: Text(data)),
      ),
    );
  }

  Future<String> _cacheProvider(String? query) {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => 'Value from cache',
    );
  }

  Future<String> _dataProvider(String? query) {
    return Future.delayed(
      const Duration(seconds: 2),
      () => 'Value from your API',
    ).then((value) => _state.onFetch(value)!);
  }
}
