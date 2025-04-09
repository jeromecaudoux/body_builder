// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:body_builder/src/basic_ui.dart';
import 'package:body_builder/src/body_provider.dart';
import 'package:body_builder/src/body_state.dart';
import 'package:body_builder/src/state_provider.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  @Deprecated('Use providers instead')
  final StateProvider? stateProvider;
  @Deprecated('Use providers instead')
  final Function? cacheProvider;
  @Deprecated('Use providers instead')
  final Function? dataProvider;
  final Iterable<BodyProvider<T>>? providers;
  final Widget? progressBuilder;
  final ErrorBuilder? errorBuilder;
  final ChildWrapper? childWrapper;
  final bool showAppBarOnLoadingAndPlaceholder;
  final bool fetchDataOnState;
  final bool listenState;
  final bool placeHolderImage;
  final bool clearDataOnRefresh;
  final Duration? animationDuration;
  final TextEditingController? searchController;
  final ScrollController? scrollController;
  final VoidCallback? onBeforeRefresh;
  final Duration searchFetchDelay;
  final MergeDataStrategy mergeDataStrategy;

  const BodyBuilder({
    this.showAppBarOnLoadingAndPlaceholder = false,
    this.placeHolderImage = true,
    this.listenState = true,
    this.clearDataOnRefresh = true,
    this.fetchDataOnState = false,
    this.animationDuration = const Duration(milliseconds: 150),
    this.searchController,
    this.scrollController,
    @Deprecated('Use providers instead') this.stateProvider,
    @Deprecated('Use providers instead') this.cacheProvider,
    @Deprecated('Use providers instead') this.dataProvider,
    this.providers,
    this.progressBuilder,
    this.errorBuilder,
    this.customBuilder,
    this.childWrapper,
    this.builder,
    this.onBeforeRefresh,
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
        assert(
          (providers?.length ?? 0) > 0 || dataProvider != null,
          'At least one provider is required',
        );

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
  final RefreshController _refreshController = RefreshController();
  StreamSubscription? _subscription;
  StreamSubscription? _delaySubscription;

  Iterable<BodyProvider<T>> get providers {
    if (widget.dataProvider != null) {
      return [
        // todo remove this shit asap lol
        BodyProvider(
          name: 'SupportDeprecatedBodyProvider',
          state: widget.stateProvider as StateProvider<T>?,
          cache: widget.cacheProvider != null
              ? (String? query) async {
                  if (widget.cacheProvider is! CacheProvider) {
                    return (await widget.cacheProvider?.call()) as T?;
                  }
                  return (await widget.cacheProvider?.call(query)) as T?;
                }
              : null,
          data: (String? query) async {
            if (widget.dataProvider is! DataProvider) {
              return (await widget.dataProvider?.call()) as T;
            }
            return (await widget.dataProvider!(query)) as T;
          },
        ),
      ];
    }
    return widget.providers!;
  }

  BodyState _state = BodyState.loading();

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
    _startListeningStateProviders();
    fetch(allowState: true, allowCache: true, ignoreLoading: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _buildMainContent();
    if (widget.scrollController == null) {
      return _wrapForAnimations(child);
    }
    child = SmartRefresher(
      header: const WaterDropHeader(),
      onRefresh: _onRefresh,
      controller: _refreshController,
      scrollController: widget.scrollController,
      child: _buildMainContent(),
    );

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
    return progressBuilder(
      showAppBar: widget.showAppBarOnLoadingAndPlaceholder,
    );
  }

  Widget _buildError() {
    ErrorBuilder? errorBuilder = widget.errorBuilder ??
        BodyBuilderConfig._instance?.defaultErrorBuilder ??
        buildDefaultErrorPlaceholder;
    return errorBuilder(
      _state.error!,
      _state.errorStack,
      retry,
      showAppBar: widget.showAppBarOnLoadingAndPlaceholder,
      placeHolderImage: widget.placeHolderImage,
    );
  }

  Future<void> _onStateChanged() async {
    if (widget.fetchDataOnState == true) {
      fetch(allowState: true, allowCache: false, allowData: true);
      return;
    }
    return fetch(
      allowState: true,
      allowCache: false,
      allowData: false,
      clearData: false,
    );
  }

  /// Will re-execute the providers.
  /// If [waitNextFrame] is true, the fetch will be executed on the next frame.
  /// Otherwise it will be executed immediately.
  /// [waitNextFrame] is useful when you want to call [retry] just after a
  /// [setState] call, without having to worry about the providers not being
  /// updated (at the next rebuild).
  void retry({bool allowState = false, bool waitNextFrame = true}) {
    task() => fetch(
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

  Future<void> fetch({
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
        _state = BodyState.loading();
      });
    }
    if (allowState && _initialState()) {
      // nothing to do, initial state has data
      return;
    }
    _subscription?.cancel();
    _stopListeningStateProviders();
    try {
      _subscription = providers
          .resolve(
            query: widget.searchController?.text ?? '',
            allowState: allowState,
            allowCache: allowCache,
            allowData: allowData,
            mergeStrategy: widget.mergeDataStrategy,
          )
          .listen(_onState, onError: _onError);
      await _subscription?.asFuture();
      _refreshController.refreshCompleted();
    } catch (e, s) {
      _refreshController.refreshFailed();
      _onError(e, s);
      debugPrint('Failed to fetch data: $e\n$s\nFrom:\n${StackTrace.current}');
    } finally {
      _startListeningStateProviders();
    }
  }

  bool _initialState() {
    if (!mounted) {
      return true;
    }
    BodyState? state =
        providers.initialState(widget.searchController?.text ?? '');
    if (state.hasData) {
      setState(() {
        _state = state;
      });
      return !state.isLoading && !state.isCache && !state.hasError;
    }
    return false;
  }

  void _onError(e, s) {
    // Big error, probably inside the body builder logic
    // Just print it and send an error to the UI
    debugPrint('Failed to resolve provider(s): $e\n$s');
    setState(() {
      _state = BodyState.error(e, s);
    });
  }

  void _onState(BodyState state) {
    if (_state.hasData && !state.hasData) {
      // If we got an error are if we are loading a new page then
      // we want to keep the last data
      // To clear the data you should call fetch with clearData = true
      state = state.copy(data: _state.data, isCache: _state.isCache);
    }
    setState(() {
      _state = state;
    });
  }

  void _onRefresh() {
    if (widget.onBeforeRefresh != null) {
      widget.onBeforeRefresh?.call();
    } else {
      providers
          .map((e) => e.state)
          .whereType<StateProvider>()
          .forEach((StateProvider provider) {
        provider.clear();
      });
    }
    fetch(ignoreLoading: true, clearData: widget.clearDataOnRefresh);
  }

  void _startListeningStateProviders() {
    if (widget.listenState) {
      for (final BodyProvider provider in providers) {
        provider.state?.addListener(_onStateChanged);
      }
    }
  }

  void _stopListeningStateProviders() {
    if (widget.listenState) {
      for (final BodyProvider provider in providers) {
        provider.state?.removeListener(_onStateChanged);
      }
    }
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
        fetch(
          allowState: allowState,
          allowCache: allowCache,
          clearData: clearData,
          ignoreLoading: true,
        );
      }
    });
  }

  void loadMoreIfNeeded() {
    if (hasMore()) {
      fetch();
    }
  }

  bool hasMore() {
    Iterable<BodyProvider> result = providers.where((e) => e.isPaginated);
    assert(
      result.length == 1,
      'Found ${result.length} paginated providers, expected 1.',
    );
    return result.first.state?.hasMore(widget.searchController?.text ?? '') ==
        true;
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(delayedFetch);
    _subscription?.cancel();
    _refreshController.dispose();
    _stopListeningStateProviders();
    super.dispose();
  }
}
