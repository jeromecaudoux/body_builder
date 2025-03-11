import 'package:body_builder/src/body_builder.dart';
import 'package:flutter/material.dart';

typedef LoadMoreBuilder = Widget Function(VoidCallback loadMore);

class LoadMore extends StatefulWidget {
  final GlobalKey<BodyBuilderState>? bodyBuilderKey;
  final bool showSpinner;
  final String errorMessage;
  final bool useButton;
  final LoadMoreBuilder? loadMoreBuilder;
  final String? loadMoreLabel;

  const LoadMore(
    this.bodyBuilderKey, {
    super.key,
    this.showSpinner = true,
    this.useButton = false,
    this.loadMoreLabel,
    this.loadMoreBuilder,
    this.errorMessage = 'Failed to load more',
  }) : assert(
          !useButton || (loadMoreBuilder != null || loadMoreLabel != null),
          'loadMoreBuilder or loadMoreLabel must be provided when useButton is true',
        );

  @override
  State<LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<LoadMore> {
  @override
  void initState() {
    if (!widget.useButton) {
      widget.bodyBuilderKey?.currentState?.loadMoreIfNeeded();
    }
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
    if (state.hasMore() && widget.useButton) {
      return _buildButton(state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildButton(BodyBuilderState state) {
    if (widget.loadMoreBuilder != null) {
      return widget.loadMoreBuilder!(state.loadMoreIfNeeded);
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: state.loadMoreIfNeeded,
        child: Text(widget.loadMoreLabel ?? 'Load more'),
      ),
    );
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
