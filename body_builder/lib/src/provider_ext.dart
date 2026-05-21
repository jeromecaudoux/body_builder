import 'dart:developer';

import 'package:body_builder/src/body_builder.dart';
import 'package:body_builder/src/body_provider.dart';
import 'package:body_builder/src/body_state.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

extension ProviderExt on Iterable<BodyProviderBase> { 
  void execute({
    String? query,
    bool allowState = true,
    bool allowCache = true,
    bool allowData = true,
    bool clearData = false,
    bool force = false,
    MergeDataStrategy mergeStrategy = MergeDataStrategy.allAtOne,
  }) {
    for (final provider in this) {
      provider.execute(
        query: query,
        allowState: allowState,
        allowCache: allowCache,
        allowData: allowData,
        clearData: clearData,
        force: force,
      );
    }
  }

  BodyState merge(
    Iterable<BodyState> states,
    MergeDataStrategy strategy,
  ) {
    if (kDebugMode && BodyBuilderConfig.instance.debugLogsEnabled) {
      _debugPrintStates(states);
    }
    bool oneIsLoading = states.any((state) => state.isLoading);
    bool oneIsCache = states.any((state) => state.isCache);
    bool allHaveData = states.every((state) => state.hasData);
    if (allHaveData) {
      if (oneIsCache) {
        return BodyState.cache(states, isLoading: oneIsLoading);
      }
      return BodyState.data(states, isLoading: oneIsLoading);
    }

    BodyState? errorState =
        states.firstWhereOrNull((state) => state.error != null);
    if (errorState != null) {
      return BodyState.error(errorState.error!, errorState.errorStack)
          .copy(data: states, isLoading: oneIsLoading);
    }
    switch (strategy) {
      case MergeDataStrategy.allAtOne:
        return BodyState.loading().copy(
          data: states
              .map((state) => state.copy(clearData: true, isLoading: true))
              .toList(),
        );
      case MergeDataStrategy.oneByOne:
        return BodyState.loading().copy(data: states);
    }
  }

  void _debugPrintStates(Iterable<BodyState<dynamic>> states) {
    log('--- BodyBuilder -> OnEvent Start ---');
    log('Providers: ${map((e) => e.name ?? '${e.runtimeType}')}');
    for (var state in states) {
      log('State: $state');
    }
    log('--- BodyBuilder -> OnEvent End ---');
  }
}
