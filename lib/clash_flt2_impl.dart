import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'entity/clash_traffic.dart';
import 'entity/clash_config_resolve_result.dart';

import 'clash_flt2_ffi.dart';
import 'clash_flt2_ios.dart';

abstract class ClashFlt2 {
  static ClashFlt2 get instance =>
      Platform.isIOS ? ClashFlt2IOS.instance : ClashFlt2FFI.instance;

  final _logController = StreamController<String>();
  late final logStream = _logController.stream;

  ///
  /// readonly, is currently system proxy
  ///
  final systemProxyEnabled = ValueNotifier(false);

  ///
  /// readonly, tunnel mode in rule, global, direct
  /// see [TunnelMode]
  ///
  final tunnelMode = ValueNotifier(TunnelMode.values.first);

  ///
  /// readonly, current and total traffic
  ///
  final traffic = ValueNotifier(ClashTraffic.zero);

  ///
  /// load libs
  ///
  void init();

  ///
  /// init clash and set configs
  ///
  FutureOr<ClashConfigResolveResult?> setConfig(
      File yamlFile, Directory clashHome);

  ///
  /// select proxy group and proxy
  ///
  FutureOr<bool> selectProxy(String groupName, String proxyName);

  ///
  /// start system proxy
  /// return true if start successful
  ///
  Future<bool> startSystemProxy(ClashConfigResolveResult configResolveResult);

  ///
  /// stop system proxy
  ///
  Future<void> stopSystemProxy();

  ///
  /// set tunnel in global, rule, direct mode
  /// see [TunnelMode]
  ///
  FutureOr<void> setTunnelMode(TunnelMode mode);

  ///
  /// get current clash connections
  ///
  FutureOr<Map<String, dynamic>> getConnections();

  ///
  /// close all clash connections
  ///
  void closeAllConnections();

  ///
  /// close certain clash connection by connectionId.
  /// you can get connectionId by calling [getConnections].
  ///
  FutureOr<bool> closeConnection(String connectionId);

  ///
  /// get traffic through clash
  ///
  @protected
  FutureOr<String?> getTrafficJson();

  ///
  /// start clash logging
  /// logs will pollute into [logStream]
  /// see [stopLogging]
  ///
  void startLogging();

  ///
  /// stop clash logging
  /// see [startLogging]
  ///
  void stopLogging();

  ///
  /// test delay of given [proxyNames]
  /// the result can be listen with [delayOf]
  ///
  Future<void> testDelay(
    Set<String> proxyNames, {
    Duration timeout = const Duration(seconds: 5),
    String url = "https://www.google.com/generate_204",
  });

  final _delayPool = <String, ValueNotifier<int>>{};
  ValueNotifier<int> delayOf(String proxyName) {
    return _delayPool[proxyName] ??= ValueNotifier(-1);
  }

  @protected
  void addLog(String message) {
    _logController.add(message);
  }

  Future<void> updateTraffic() async {
    final trafficJson = await getTrafficJson();
    if (trafficJson == null) return;
    final json = jsonDecode(trafficJson);
    final currentUp = json["Up"] as int;
    final currentDown = json["Down"] as int;
    totalUp += currentUp;
    totalDown += currentDown;
    traffic.value = ClashTraffic(
      totalUpload: totalUp,
      totalDownload: totalDown,
      currentUpload: currentUp,
      currentDownload: currentDown,
    );
  }

  @protected
  var totalUp = 0;
  @protected
  var totalDown = 0;
  void resetTraffic() {
    totalUp = 0;
    totalDown = 0;
    traffic.value = ClashTraffic.zero;
  }
}

enum TunnelMode {
  rule,
  global,
  direct,
}

TunnelMode tunnelModeByName(String name) {
  for (var tunnelMode in TunnelMode.values) {
    if (tunnelMode.name.toLowerCase() == name.toLowerCase()) {
      return tunnelMode;
    }
  }
  throw FlutterError("mode($name) is not the one of enum TunnelMode.");
}
