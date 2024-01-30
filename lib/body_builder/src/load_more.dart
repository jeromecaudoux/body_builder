import 'package:body_builder/body_builder/src/body_builder.dart';
import 'package:flutter/material.dart';

class LoadMore extends StatefulWidget {
  final GlobalKey<BodyBuilderState>? bodyBuilderKey;
  final bool showSpinner;
  final String errorMessage;

  const LoadMore(
    this.bodyBuilderKey, {
    super.key,
    this.showSpinner = true,
    this.errorMessage = 'Failed to load more',
  });

  @override
  State<LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<LoadMore> {
  @override
  void initState() {
    widget.bodyBuilderKey?.currentState?.loadMoreIfNeeded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    BodyBuilderState? state = widget.bodyBuilderKey?.currentState;
    if (state == null) {
      return const SizedBox.shrink();
    }
    if (state.hasError == true) {
      return _buildPlaceholder(state, context);
    }
    if (state.isLoading == true && !state.isCache && widget.showSpinner) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPlaceholder(BodyBuilderState state, BuildContext context) {
    return GestureDetector(
      onTap: state.loadMoreIfNeeded,
      child: ColoredBox(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const Icon(Icons.refresh_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
