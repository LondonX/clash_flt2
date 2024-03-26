import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clash_flt2/entity/clash_config_resolve_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'clash_flt2_impl.dart';
import 'utils.dart';

const _channel = MethodChannel("clash_flt2");

///
/// ClashFlt implementation on iOS without FlutterFFI
/// see also [ClashFlt2FFI]
///
class ClashFlt2IOS extends ClashFlt2 {
  static final instance = ClashFlt2IOS._();
  ClashFlt2IOS._();

  @override
  void closeAllConnections() {
    _channel.invokeMethod("closeAllConnections");
  }

  @override
  Future<bool> closeConnection(String connectionId) async {
    return await _channel.invokeMethod(
      "closeConnection",
      {"connectionId": connectionId},
    );
  }

  @override
  Future<Map<String, dynamic>> getConnections() async {
    final json = await _channel.invokeMethod<String>("getAllConnections");
    return json == null ? {} : jsonDecode(json);
  }

  @override
  void init() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  @override
  Future<bool> selectProxy(String groupName, String proxyName) async {
    return 0 ==
        await _channel.invokeMethod(
          "changeProxy",
          {
            "selectorName": groupName,
            "proxyName": proxyName,
          },
        );
  }

  @override
  Future<ClashConfigResolveResult?> setConfig(
    File yamlFile,
    Directory clashHome,
  ) async {
    final config = await yamlFile.readAsString();
    final generalConfig = config.resolveGeneralConfigs();
    final port = generalConfig["port"] as int?;
    final socksPort = generalConfig["socks-port"] as int?;
    final mixedPort = generalConfig["mixed-port"] as int?;
    final configShadow = config.replaceGeneralConfigValue({
      if (port != null) "port": 0,
      if (socksPort != null) "socks-port": 0,
      if (mixedPort != null) "mixed-port": 0,
    });
    final shadowConfigFile = File("${yamlFile.parent.path}/config_shadow.yaml");
    await shadowConfigFile.writeAsString(configShadow, flush: true);

    await _channel.invokeMethod("setConfig", {
      "configPath": yamlFile.path,
      "shadowConfigPath": shadowConfigFile.path,
    });
    await _channel.invokeMethod("setHomeDir", {"home": clashHome.path});
    await _channel.invokeMethod("clashInit", {"homeDir": clashHome.path});
    await _channel.invokeMethod("parseOptions");
    final configsJson = await _channel.invokeMethod<String>("getConfigs");
    final proxiesJson = await _channel.invokeMethod<String>("getProxies");
    final configs = jsonDecode(configsJson!);
    final proxies = jsonDecode(proxiesJson!);
    final mode = tunnelModeByName(configs["mode"]!);
    tunnelMode.value = mode;
    return ClashConfigResolveResult(
      httpPort: port.takeIf((v) => v != 0),
      socksPort: socksPort.takeIf((v) => v != 0),
      mixedPort: mixedPort.takeIf((v) => v != 0),
      proxyGroups: buildProxyGroups(proxies),
    );
  }

  @override
  Future<void> setTunnelMode(TunnelMode mode) async {
    await _channel.invokeMethod("setTunMode", {"s": mode.name});
    final resultString = await _channel.invokeMethod("getTunMode");
    final result = tunnelModeByName(resultString);
    assert(result == mode,
        "mode is not supported by clash core. resultString: $resultString");
    tunnelMode.value = mode;
  }

  @override
  void startLogging() {
    addLog(
      "[ClashFlt2]Logs from PacketTunnel will sink to logStream, you may see them in Console.app.",
    );
    _channel.invokeMethod("startLog");
  }

  @override
  Future<bool> startSystemProxy(
    ClashConfigResolveResult configResolveResult,
  ) async {
    if (true ==
        await _channel.invokeMethod(
          "startSystemProxy",
          {
            "port": configResolveResult.httpPort ?? 0,
            "socksPort": configResolveResult.socksPort ?? 0,
          },
        )) {
      systemProxyEnabled.value = true;
      _checkRunning();
      return true;
    }
    return false;
  }

  @override
  void stopLogging() {
    _channel.invokeMethod("stopLog");
  }

  @override
  Future<void> stopSystemProxy() async {
    _runningCheck?.cancel();
    await _channel.invokeMethod("stopSystemProxy");
    systemProxyEnabled.value = false;
  }

  Timer? _runningCheck;
  _checkRunning() async {
    _runningCheck?.cancel();
    _runningCheck = Timer.periodic(const Duration(seconds: 1), (timer) async {
      systemProxyEnabled.value =
          true == await _channel.invokeMethod("isRunning");
    });
  }

  @override
  Future<void> testDelay(
    Set<String> proxyNames, {
    Duration timeout = const Duration(seconds: 5),
    String url = "https://www.google.com/generate_204",
  }) async {
    const chunkSize = 10;
    const chunkInterval = Duration(seconds: 1);

    final chunks = <Set<String>>[];
    List<String> inputList = [...proxyNames];
    for (var i = 0; i < inputList.length; i += chunkSize) {
      final endIndex = min(inputList.length - 1, i + chunkSize);
      var chunk = inputList.sublist(i, endIndex);
      chunks.add(Set.from(chunk));
    }
    for (var chunk in chunks) {
      await Future.wait(
        chunk.map(
          (proxyName) => _channel.invokeMethod(
            "asyncTestDelay",
            {
              "proxyName": proxyName,
              "url": url,
              "timeout": timeout.inMilliseconds,
            },
          ),
        ),
      );
      await Future.delayed(chunkInterval);
    }
    // wait for last chunk to finish
    await Future.delayed(timeout - chunkInterval);
  }

  @override
  @protected
  Future<String?> getTrafficJson() async {
    return await _channel.invokeMethod("getTraffic");
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    final args = Map<String, dynamic>.from(call.arguments);
    switch (call.method) {
      case "onDelayUpdate":
        final name = args["name"] as String;
        final delay = args["delay"] as int;
        delayOf(name).value = delay;
        break;
      case "onLogReceived":
        final message = args["message"] as String;
        addLog(message);
        break;
    }
  }
}
