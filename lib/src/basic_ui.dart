import 'package:flutter/material.dart';

Widget defaultProgressBuilder({
  bool showAppBar = false,
}) {
  Widget child = const Padding(
    padding: EdgeInsets.all(32),
    child: Center(child: CircularProgressIndicator()),
  );
  if (showAppBar) {
    child = Column(
      children: [
        AppBar(),
        Expanded(child: child),
      ],
    );
  }
  return child;
}

Widget buildDefaultErrorPlaceholder(
  dynamic error,
  StackTrace? errorStack,
  VoidCallback onRetry, {
  bool showAppBar = false,
  bool placeHolderImage = true,
}) {
  Widget child = ScrollConfiguration(
    behavior: const MaterialScrollBehavior().copyWith(overscroll: false),
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SimpleErrorPlaceholder(
          error,
          errorStack,
          onRetry,
          placeHolderImage: placeHolderImage,
        ),
      ),
    ),
  );
  if (showAppBar) {
    child = Column(
      children: [
        AppBar(),
        Expanded(child: child),
      ],
    );
  }
  return child;
}

class SimpleErrorPlaceholder extends StatelessWidget {
  final Object? error;
  final StackTrace? errorStack;
  final VoidCallback onRetry;
  final bool placeHolderImage;

  const SimpleErrorPlaceholder(
    this.error,
    this.errorStack,
    this.onRetry, {
    this.placeHolderImage = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (placeHolderImage) _getErrorImage(),
        const SizedBox(height: 8),
        _getErrorTitle(),
        const SizedBox(height: 20),
        FilledButton(onPressed: onRetry, child: const Text('Try Again')),
      ],
    );
  }

  Widget _getErrorImage() {
    return const Icon(
      Icons.error_outline,
      color: Colors.red,
      size: 50,
    );
  }

  Widget _getErrorTitle() {
    return const Text('Error');
  }
}
