import 'dart:async';

import 'package:body_builder/body_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BodyProvider emits updates when state changes', () async {
    final state = SimpleStateProvider<String>();
    final completer = Completer<String>();
    final provider = BodyProvider<String>(
      state: state,
      data: (_) => completer.future,
    );

    final iterator = StreamIterator(provider.resolve());

    expect(await iterator.moveNext(), true);
    expect(iterator.current, BodyState<String>.loading());

    state.on('local');

    expect(await iterator.moveNext(), true);
    expect(iterator.current.data, 'local');
    expect(iterator.current.isLoading, false);

    completer.complete('remote');
    await iterator.cancel();
  });
}
