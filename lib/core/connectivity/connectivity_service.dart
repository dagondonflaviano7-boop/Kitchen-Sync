import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  final InternetConnection _internet;
  ConnectivityService(
      {Connectivity? connectivity, InternetConnection? internet})
      : _connectivity = connectivity ?? Connectivity(),
        _internet = internet ?? InternetConnection();
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.asyncMap((states) async {
        if (states.every((s) => s == ConnectivityResult.none)) return false;
        return await _internet.hasInternetAccess;
      }).distinct();
  Future<bool> get isOnline async {
    final states = await _connectivity.checkConnectivity();
    if (states.every((s) => s == ConnectivityResult.none)) return false;
    return await _internet.hasInternetAccess;
  }
}
