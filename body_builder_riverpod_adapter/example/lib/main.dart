import 'package:body_builder/body_builder.dart';
import 'package:body_builder_example/paginated_page.dart';
import 'package:body_builder_example/related_paginated_page.dart';
import 'package:body_builder_example/related_simple_page.dart';
import 'package:body_builder_example/simple_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  BodyBuilder.setDefaultConfig(debugLogsEnabled: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        home: const MyHomePage(title: 'Body Builder with riverpod - Example'),
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
                    builder: (context) => const SimplePage(),
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
                    builder: (context) => const RelatedSimplePage(),
                  ),
                );
              },
              child: const Text('Related simple example'),
            ),
            const Divider(),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaginatedPage(),
                  ),
                );
              },
              child: const Text('Pagination example'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RelatedPaginatedPage(),
                  ),
                );
              },
              child: const Text('Related Pagination example'),
            ),
          ],
        ),
      ),
    );
  }
}
