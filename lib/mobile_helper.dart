import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _mobileChannel = MethodChannel("clash_flt2");

class MobileHelper {
  final ValueNotifier<bool> systemProxyEnabled;
  const MobileHelper({
    required this.systemProxyEnabled,
  });

  init() {
    _mobileChannel.invokeMethod("isRunning").then((data) {
      systemProxyEnabled.value = data as bool;
    });
  }

  Future<bool> startService(int port, int socksPort) async {
    final success = true ==
        await _mobileChannel.invokeMethod(
          "startTun",
          {"port": port, "socksPort": socksPort},
        );
    systemProxyEnabled.value = success;
    return success;
  }

  Future<void> stopService() async {
    await _mobileChannel.invokeMethod("stopTun");
    systemProxyEnabled.value = false;
  }
}
