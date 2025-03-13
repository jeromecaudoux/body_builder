import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomBuilderPage extends StatefulWidget {
  const CustomBuilderPage({super.key});

  @override
  State<CustomBuilderPage> createState() => _CustomBuilderPageState();
}

class _CustomBuilderPageState extends State<CustomBuilderPage> {
  final GlobalKey<BodyBuilderState> _key = GlobalKey();
  bool _forceThrowError = false;
  late final BasicSampleState _state;

  @override
  void initState() {
    _state = context.read<BasicSampleState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BodyBuilder(
        key: _key,
        providers: [
          BodyProvider(
            name: 'my-provider',
            state: _state,
            cache: _cacheProvider,
            data: _dataProvider,
          )
        ],
        customBuilder: _buildBody,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Custom builder'),
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
            _key.currentState?.retry();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildBody(BodyState state) {
    if (state.hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(state.error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          ElevatedButton(
            // you can trigger a retry by using a GlobalKey like this
            onPressed: () => _key.currentState?.retry(),
            child: const Text('Retry'),
          ),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: CircularProgressIndicator(),
            ),
          // You can get the BodyState associated to your provider
          // by using #byName, #byType or #where methods
          Text(state.byName('my-provider')?.data ?? 'No data'),
          // Text(state.byType<String>()?.data ?? 'No data'),
          // Text(
          //   state
          //           .where<String>(
          //               (state) => state.providerName?.contains('my') == true)
          //           ?.data ??
          //       'No data',
          // ),
        ],
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
    ).then((value) {
      if (_forceThrowError) {
        _forceThrowError = false;
        throw Exception(
            'When the software starts breakdancing, it\'s a bug break!');
      }
      return _state.on(value);
    });
  }
}
