import 'dart:async';

import 'bucket_snapshot.dart';

enum SnapshotEvent {add_field, update}

class SnapshotBloc{
  // Making it a broadcast stream -> read websocket once but use data multiple places.

  // Note this stream stays on irrespective of websocket is connected or not
  // If web socket is connected, this stream received data, else not.
  // TODO: Requires optimization
  // static StreamController<BucketSnapshot> _controller = StreamController.broadcast();
  // static final _stream = _controller.stream;
  // static final _sink = _controller.sink;
  //
  // static Stream<BucketSnapshot> get stream => _stream;
  // static StreamSink<BucketSnapshot> get sink => _sink;
  // static StreamController get controller => _controller;


  StreamController<BucketSnapshot>? _controller;
  StreamSink<BucketSnapshot>? _sink;
  Stream<BucketSnapshot>? _stream;

  Stream<BucketSnapshot> get stream => _stream!;
  StreamSink<BucketSnapshot> get sink => _sink!;

  SnapshotBloc(){
    _controller = StreamController<BucketSnapshot>.broadcast();
    _sink = _controller!.sink;
    _stream = _controller!.stream;
  }

  Future<void> close() async {
    await _controller!.close();
  }
}