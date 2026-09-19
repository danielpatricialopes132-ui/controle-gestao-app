import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get isOnlineStream => _connectivity.onConnectivityChanged.map((results) {
    // onConnectivityChanged in newer versions of connectivity_plus returns a List<ConnectivityResult>
    for (var result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  });

  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    for (var result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnlineStream;
});
