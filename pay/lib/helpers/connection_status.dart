import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// Call ConnectionStatus().initialize() ONCE in main(), then use ConnectionStatus().isOnline or subscribe.
class ConnectionStatus {
  static final ConnectionStatus _instance = ConnectionStatus._internal();
  factory ConnectionStatus() => _instance;
  ConnectionStatus._internal();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Stream<bool> get statusStream => _controller.stream;
  bool get isOnline => _isOnline;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void initialize() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final nowOnline = results.any((c) => c != ConnectivityResult.none);
      if (_isOnline != nowOnline) {
        _isOnline = nowOnline;
        _controller.add(_isOnline);
      }
    });
    // Set initial/first value too
    Connectivity().checkConnectivity().then((conn) {
      final nowOnline = conn != ConnectivityResult.none;
      _isOnline = nowOnline;
      _controller.add(_isOnline);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
