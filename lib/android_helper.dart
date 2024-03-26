import 'dart:io';

import 'package:clash_flt2/clash_flt2_impl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _mobileChannel = MethodChannel("clash_flt2");

class AndroidHelper {
  final ValueNotifier<bool> systemProxyEnabled;
  AndroidHelper({required this.systemProxyEnabled});

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
  }

  void setMode(TunnelMode mode) {
    _args["mode"] = mode.name;
  }

  void selectProxy(String groupName, String proxyName) {
    _args["groupName"] = groupName;
    _args["proxyName"] = proxyName;
  }
}
