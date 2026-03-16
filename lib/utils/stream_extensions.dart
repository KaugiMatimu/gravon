import 'dart:async';

extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) async* {
    yield initialValue;
    yield* this;
  }
}
