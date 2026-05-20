// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';
import 'dart:developer';

import 'package:body_builder/src/basic_ui.dart';
import 'package:body_builder/src/body_provider.dart';
import 'package:body_builder/src/body_state.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BodyBuilderConfig {
  static BodyBuilderConfig? _instance;

  static BodyBuilderConfig get instance =>
      _instance ?? const BodyBuilderConfig._();

  final ProgressBuilder? defaultProgressBuilder;
  final ErrorBuilder? defaultErrorBuilder;
  final ChildWrapper? childWrapper;
  final bool debugLogsEnabled;

  const BodyBuilderConfig._({
    this.defaultProgressBuilder,
    this.defaultErrorBuilder,
    this.childWrapper,
    this.debugLogsEnabled = false,
  });
}

class BodyBuilder<T> extends StatefulWidget {
  final Function? builder;
  final CustomBuilder? customBuilder;
  final Iterable<BodyProviderBase<T>> providers;
  final Widget? progressBuilder;
  final ErrorBuilder? errorBuilder;
  final ChildWrapper? childWrapper;
  final Duration? animationDuration;
  final TextEditingController? searchController;
  final ScrollController? scrollController;
  final Duration searchFetchDelay;
  final MergeDataStrategy mergeDataStrategy;

  const BodyBuilder({
    this.animationDuration = const Duration(milliseconds: 150),
    this.searchController,
    this.scrollController,
    required this.providers,
    this.progressBuilder,
    this.errorBuilder,
    this.customBuilder,
    this.childWrapper,
    this.builder,
    this.mergeDataStrategy = MergeDataStrategy.allAtOne,
    this.searchFetchDelay = const Duration(milliseconds: 400),
    super.key,
  })  : assert(
          builder == null || customBuilder == null,
          'Both builders have been provided, but only one can be supported',
        ),
        assert(
          builder != null || customBuilder != null,
          'A valid builder is required',
        ),
        assert(providers.length > 0, 'At least one provider is required');

  static void setDefaultConfig({
    ProgressBuilder? defaultProgressBuilder,
    ErrorBuilder? defaultErrorBuilder,
    ChildWrapper? childWrapper,
    bool debugLogsEnabled = false,
  }) {
    BodyBuilderConfig._instance = BodyBuilderConfig._(
      defaultProgressBuilder: defaultProgressBuilder,
      defaultErrorBuilder: defaultErrorBuilder,
      childWrapper: childWrapper,
      debugLogsEnabled: debugLogsEnabled,
    );
  }

  @override
  BodyBuilderState<T> createState() => BodyBuilderState<T>();
}

class BodyBuilderState<T> extends State<BodyBuilder<T>> {
  StreamSubscription? _subscription;
  StreamSubscription? _delaySubscription;

  late BodyState _state;

  BodyState get state => _state;

  bool get isLoading => _state.isLoading;

  bool get isCache => _state.isCache;

  bool get hasData => _state.hasData;

  bool get hasError => _state.hasError;

  Object? get error => _state.error;

  StackTrace? get errorStack => _state.errorStack;

  @override
  void initState() {
    widget.searchController?.addListener(delayedFetch);
    reload(allowState: true, allowCache: true, ignoreLoading: true);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant BodyBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool providersChanged = !listEquals(
      oldWidget.providers.map((e) => e.id).toList(),
      widget.providers.map((e) => e.id).toList(),
    );
    if (providersChanged) {
      reload(allowState: true, allowCache: true, ignoreLoading: true);
    } else if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController?.removeListener(delayedFetch);
      widget.searchController?.addListener(delayedFetch);
    } else if (oldWidget.scrollController != widget.scrollController) {
      // No need to listen to scrollController changes, as we read it directly when needed (in loadMoreIfNeeded)
    }
  }

  bool _initialState() {
    if (!mounted) {
      return true;
    }
    try {
      BodyState? state = widget.providers.initialState(
        widget.searchController?.text ?? '',
        mergeStrategy: widget.mergeDataStrategy,
      );

      if (kDebugMode && BodyBuilderConfig.instance.debugLogsEnabled) {
        log('--- _initialState -> resolved -> Start ---');
        log('Merged state: $state');
        log('--- _initialState -> resolved -> End ---');
      }
      setState(() {
        _state = state;
      });
      return !state.isLoading && !state.isCache && !state.hasError;
    } catch (e, s) {
      debugPrint('Failed to get initial state: $e\n$s');
      _state = BodyState.error(e, s);
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildMainContent();
    if (widget.scrollController == null) {
      return _wrapForAnimations(child);
    }
    ChildWrapper? childWrapper =
        widget.childWrapper ?? BodyBuilderConfig._instance?.childWrapper;
    return childWrapper?.call(child, _state, retry) ?? child;
  }

  Widget _wrapForAnimations(Widget child) {
    return (widget.animationDuration?.inMilliseconds ?? 0) == 0
        ? child
        : AnimatedSwitcher(
            duration: widget.animationDuration!,
            child: child,
          );
  }

  Widget _buildMainContent() {
    if (widget.customBuilder != null) {
      return widget.customBuilder!(_state);
    }
    if (!_state.hasData) {
      if (_state.hasError) {
        return _buildError();
      }
      return _buildProgressIndicator();
    }
    if (_state.combinedStates) {
      switch (_state.data.length) {
        case 1:
          return widget.builder!.call(_at(0));
        case 2:
          return widget.builder!.call(_at(0), _at(1));
        case 3:
          return widget.builder!.call(_at(0), _at(1), _at(2));
        case 4:
          return widget.builder!.call(_at(0), _at(1), _at(2), _at(3));
        case 5:
          return widget.builder!.call(_at(0), _at(1), _at(2), _at(3), _at(4));
        case 6:
          return widget.builder!
              .call(_at(0), _at(1), _at(2), _at(3), _at(4), _at(5));
        case 7:
          return widget.builder!
              .call(_at(0), _at(1), _at(2), _at(3), _at(4), _at(5), _at(6));
        case 8:
          return widget.builder!.call(
              _at(0), _at(1), _at(2), _at(3), _at(4), _at(5), _at(6), _at(7));
        case 9:
          return widget.builder!.call(_at(0), _at(1), _at(2), _at(3), _at(4),
              _at(5), _at(6), _at(7), _at(8));
        default:
          throw Exception(
            'Unsupported number of states: ${_state.data.length}',
          );
      }
    }
    return widget.builder!.call(_state.data as T?);
  }

  dynamic _at(int index) {
    assert(_state.combinedStates, 'A combined state is required');
    assert(
      index < _state.data?.length,
      'Index $index is out of bounds, max is ${_state.data?.length - 1}',
    );
    return _state.data?.elementAt(index).data;
  }

  Widget _buildProgressIndicator() {
    if (widget.progressBuilder != null) {
      return widget.progressBuilder!;
    }
    ProgressBuilder? progressBuilder =
        BodyBuilderConfig._instance?.defaultProgressBuilder ??
            defaultProgressBuilder;
    return progressBuilder();
  }

  Widget _buildError() {
    ErrorBuilder? errorBuilder = widget.errorBuilder ??
        BodyBuilderConfig._instance?.defaultErrorBuilder ??
        buildDefaultErrorPlaceholder;
    return errorBuilder(_state.error!, _state.errorStack, retry);
  }

  /// Will re-execute the providers.
  /// If [waitNextFrame] is true, the fetch will be executed on the next frame.
  /// Otherwise it will be executed immediately.
  /// [waitNextFrame] is useful when you want to call [retry] just after a
  /// [setState] call, without having to worry about the providers not being
  /// updated (at the next rebuild).
  void retry({bool allowState = false, bool waitNextFrame = true}) {
    task() => reload(
          allowState: allowState,
          allowCache: true,
          allowData: true,
          clearData: true,
        );
    if (waitNextFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          task();
        }
      });
    } else {
      task();
    }
  }

  bool _clearDataUntilLoadingStop = false;
  Future<void> reload({
    bool allowState = false,
    bool allowCache = false,
    bool allowData = true,
    bool clearData = false,
    bool ignoreLoading = false,
  }) async {
    if (!ignoreLoading && _state.isLoading) {
      return;
    }
    if (clearData) {
      setState(() {
        _clearDataUntilLoadingStop = true;
        _state = _state.copy(isLoading: true, clearData: true);
      });
    }
    if (allowState && _initialState()) {
      // nothing to do, initial state has data
      return;
    }
    _subscription?.cancel();
    try {
      _subscription = widget.providers
          .resolve(
            query: widget.searchController?.text ?? '',
            allowState: allowState,
            allowCache: allowCache,
            allowData: allowData,
            mergeStrategy: widget.mergeDataStrategy,
          )
          .listen(_onState, onError: _onError);
      await _subscription?.asFuture();
    } catch (e, s) {
      _onError(e, s);
      debugPrint('Failed to fetch data: $e\n$s\nFrom:\n${StackTrace.current}');
    }
  }

  void _onError(Object e, StackTrace s) {
    // Big error, probably inside the body builder logic
    // Just print it and send an error to the UI
    debugPrint('Failed to resolve provider(s): $e\n$s');
    setState(() {
      _state = _state.copy(
        error: e,
        errorStack: s,
        clearData: true,
        isLoading: false,
      );
    });
  }

  void _onState(BodyState state) {
    setState(() {
      _state = state.copy(
        clearData: _clearDataUntilLoadingStop && state.isLoading,
      );
      if (_clearDataUntilLoadingStop && !_state.isLoading) {
        _clearDataUntilLoadingStop = false;
      }
    });
  }

  void delayedFetch({
    bool allowState = true,
    bool allowCache = true,
    bool clearData = true,
  }) {
    _delaySubscription?.cancel();
    _delaySubscription =
        Future.delayed(widget.searchFetchDelay).asStream().listen((event) {
      if (mounted) {
        reload(
          allowState: allowState,
          allowCache: allowCache,
          clearData: clearData,
          ignoreLoading: true,
        );
      }
    });
  }

  Future<void> loadMoreIfNeeded() {
    if (hasMore()) {
      return reload();
    }
    return Future.value();
  }

  bool hasMore() {
    Iterable<BodyProviderBase> result =
        widget.providers.where((e) => e.isPaginated);
    assert(
      result.length == 1,
      'Found ${result.length} paginated providers, expected 1.',
    );
    return result.first.hasMore(widget.searchController?.text ?? '');
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(delayedFetch);
    _subscription?.cancel();
    super.dispose();
  }
}
