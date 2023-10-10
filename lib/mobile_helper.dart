import 'dart:io';

import 'package:clash_flt2/clash_flt2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _mobileChannel = MethodChannel("clash_flt2");

class MobileHelper {
  final ValueNotifier<bool> systemProxyEnabled;
  MobileHelper({required this.systemProxyEnabled});

  final _args = <String, dynamic>{};

  init() {
    _mobileChannel.invokeMethod("isRunning").then((data) {
      systemProxyEnabled.value = data as bool;
    });
  }

  Future<bool> startService(int port, int socksPort) async {
    final success = true ==
        await _mobileChannel.invokeMethod(
          "startTun",
          {"port": port, "socksPort": socksPort, ..._args},
        );
    systemProxyEnabled.value = success;
    return success;
  }

  Future<void> stopService() async {
    await _mobileChannel.invokeMethod("stopTun");
    systemProxyEnabled.value = false;
  }

  void setConfig(File yamlFile, Directory clashHome) {
    _args["yamlFile"] = yamlFile.path;
    _args["clashHome"] = clashHome.path;
    _updateIos();
  }

  void setMode(TunnelMode mode) {
    _args["mode"] = mode.name;
    _updateIos();
  }

  void selectProxy(String groupName, String proxyName) {
    _args["groupName"] = groupName;
    _args["proxyName"] = proxyName;
    _updateIos();
  }

  void _updateIos() {
    if (!Platform.isIOS) return;
    _mobileChannel.invokeMethod("update", _args);
  }

  Future<String?> getTrafficIos() async {
    if (!Platform.isIOS) return null;
    return await _mobileChannel.invokeMethod("getTraffic");
  }
}
