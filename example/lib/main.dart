import 'package:body_builder/body_builder/body_builder.dart';
import 'package:body_builder_example/basic_sample_page.dart';
import 'package:body_builder_example/custom_builder_page.dart';
import 'package:body_builder_example/multi_providers_page.dart';
import 'package:body_builder_example/paginated_page.dart';
import 'package:body_builder_example/states.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  BodyBuilder.setDefaultConfig(debugLogsEnabled: false);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BasicSampleState()),
        ChangeNotifierProvider(create: (_) => MultiProviderSampleState()),
        ChangeNotifierProvider(create: (_) => PaginatedSampleState()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        home: const MyHomePage(title: 'Body Builder - Example'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BasicBodyBuilderPage(),
                  ),
                );
              },
              child: const Text('Basic example'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomBuilderPage(),
                  ),
                );
              },
              child: const Text('Custom builder example'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MultiProversPage(),
                  ),
                );
              },
              child: const Text('Multi providers example'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaginatedPage(),
                  ),
                );
              },
              child: const Text('Paginated example'),
            ),
            FilledButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('TO-DO')),
                );
              },
              child: const Text('Search example'),
            ),
            const Divider(),
            FilledButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.orange),
              ),
              onPressed: () {
                context.read<BasicSampleState>().clear();
                context.read<MultiProviderSampleState>().clear();
                context.read<PaginatedSampleState>().clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All states cleared!')),
                );
              },
              child: const Text('Clear states'),
            ),
          ],
        ),
      ),
    );
  }
}
