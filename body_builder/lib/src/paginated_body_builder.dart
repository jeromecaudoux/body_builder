// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:body_builder/src/body_builder.dart';
import 'package:body_builder/src/body_provider.dart';
import 'package:body_builder/src/body_state.dart';
import 'package:body_builder/src/state_provider.dart';
import 'package:body_builder/src/typedefs_child_body_builder.dart';
import 'package:flutter/material.dart';

@Deprecated('Use providers instead')
typedef SearchableCacheProvider<T> = Future<T?> Function(String query);
@Deprecated('Use providers instead')
typedef SearchableDataProvider<T> = Future<T> Function(String query);

@Deprecated('Use BodyBuilder instead')
class PaginatedBodyBuilder<T> extends StatefulWidget {
  final TextEditingController? searchController;
  final Function? builder;
  @Deprecated('Use builder with a CustomChildBuilder instead')
  final DeprecatedCustomBuilder<T>? customBuilder;
  @Deprecated('Use providers instead')
  final StateProvider? stateProvider;
  @Deprecated('Use providers instead')
  final Function? cacheProvider;
  @Deprecated('Use providers instead')
  final Function? dataProvider;
  final Iterable<BodyProvider<T>>? providers;
  final Widget? progressBuilder;
  final ScrollController? scrollController;
  final bool showAppBarOnDefaultLoadingAndPlaceholder;
  @Deprecated('Not used anymore, use childWrapper instead')
  final bool toastEnabled;
  final bool placeHolderImage;
  @Deprecated('Not used anymore')
  final bool placeHolderTopSpace;
  final Duration? animationDuration;
  final VoidCallback? onRefresh;

  const PaginatedBodyBuilder({
    this.searchController,
    this.showAppBarOnDefaultLoadingAndPlaceholder = false,
    this.toastEnabled = false,
    @Deprecated('Not used anymore') this.placeHolderTopSpace = true,
    this.placeHolderImage = true,
    this.animationDuration = const Duration(milliseconds: 150),
    @Deprecated('Use providers instead') this.stateProvider,
    @Deprecated('Use providers instead') this.cacheProvider,
    @Deprecated('Use providers instead') this.dataProvider,
    this.providers,
    this.progressBuilder,
    this.scrollController,
    @Deprecated('Use builder with a CustomChildBuilder instead')
    this.customBuilder,
    this.builder,
    this.onRefresh,
    super.key,
  })  : assert(
          builder == null || customBuilder == null,
          'Both builders have been provided, but only one can be supported',
        ),
        assert(
          builder != null || customBuilder != null,
          'A valid builder is required',
        );

  @override
  State<PaginatedBodyBuilder<T>> createState() =>
      PaginatedBodyBuilderState<T>();
}

class PaginatedBodyBuilderState<T> extends State<PaginatedBodyBuilder<T>> {
  final GlobalKey<PaginatedBodyBuilderState<T>> _key = GlobalKey();

  bool get hasError => _key.currentState?.hasError == true;

  Object? get error => _key.currentState?.error;

  StackTrace? get errorStack => _key.currentState?.errorStack;

  bool get hasData => _key.currentState?.hasData == true;

  bool get isCache => _key.currentState?.isCache == true;

  bool get isLoading => _key.currentState?.isLoading == true;

  @override
  Widget build(BuildContext context) => BodyBuilder<T>(
        key: _key,
        showAppBarOnLoadingAndPlaceholder:
            widget.showAppBarOnDefaultLoadingAndPlaceholder,
        placeHolderImage: widget.placeHolderImage,
        animationDuration: widget.animationDuration,
        stateProvider: widget.stateProvider,
        cacheProvider: widget.cacheProvider != null
            ? (String? query) async =>
                (await widget.cacheProvider!(query)) as T?
            : null,
        dataProvider: widget.dataProvider != null
            ? (String? query) async => (await widget.dataProvider!(query)) as T
            : null,
        providers: widget.providers,
        progressBuilder: widget.progressBuilder,
        customBuilder: widget.customBuilder != null
            ? _deprecatedCustomBuilderSupport
            : null,
        scrollController: widget.scrollController,
        builder: widget.builder,
        onBeforeRefresh: widget.onRefresh,
        searchController: widget.searchController,
      );

  Widget _deprecatedCustomBuilderSupport(BodyState state) {
    return widget.customBuilder!(
      state.isLoading,
      state.error,
      state.data as T?,
    );
  }

  void fetch({
    bool allowState = false,
    bool allowCache = false,
    bool clearData = false,
    bool ignoreLoading = false,
  }) =>
      _key.currentState?.fetch(
        allowState: allowState,
        allowCache: allowCache,
        clearData: clearData,
        ignoreLoading: ignoreLoading,
      );

  void loadMoreIfNeeded() => _key.currentState?.loadMoreIfNeeded();
}
