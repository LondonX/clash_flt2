import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:proxy_manager/proxy_manager.dart';

import 'ffi/generated_bindings.dart';
import 'entity/clash_config_resolve_result.dart';
import 'utils.dart';

export 'entity/clash_config_resolve_result.dart';
export 'entity/clash_proxy_group.dart';

late NativeLibrary clashFFI;
const mobileChannel = MethodChannel("FClashPlugin");

class ClashPcFlt {
  static final instance = ClashPcFlt._();

  final _proxyManager = ProxyManager();

  final _logReceiver = ReceivePort();
  late final logStream = _logReceiver.asBroadcastStream();

  final _systemProxyEnabled = StreamController<bool>();
  late final systemProxyEnabled =
      _systemProxyEnabled.stream.asBroadcastStream();

  final _tunnelMode = StreamController<TunnelMode>();
  late final tunnelMode = _tunnelMode.stream.asBroadcastStream();

  final _delayPool = <String, ValueNotifier<int>>{};
  ValueNotifier<int> delayOf(String proxyName) {
    return _delayPool[proxyName] ??= ValueNotifier(-1);
  }

  ClashPcFlt._();

  ///
  /// load libs
  ///
  Future<void> init() async {
    final String libFileName;
    if (Platform.isWindows) {
      libFileName = "libclash.dll";
    } else if (Platform.isMacOS) {
      libFileName = "libclash.dylib";
    } else {
      libFileName = "libclash.so";
    }
    final lib = ffi.DynamicLibrary.open(libFileName);
    clashFFI = NativeLibrary(lib);
    clashFFI.init_native_api_bridge(ffi.NativeApi.initializeApiDLData);
  }

  ///
  /// init clash and set configs
  ///
  ClashConfigResolveResult? setConfig(File yamlFile, Directory clashHome) {
    clashFFI.set_config(yamlFile.path.toNativeUtf8().cast());
    clashFFI.set_home_dir(clashHome.path.toNativeUtf8().cast());
    clashFFI.clash_init(clashHome.path.toNativeUtf8().cast());
    clashFFI.parse_options();
    final configsJson = clashFFI.get_configs().cast<Utf8>().toDartString();
    final configs = jsonDecode(configsJson);
    final proxiesJson = clashFFI.get_proxies().cast<Utf8>().toDartString();
    final proxies = jsonDecode(proxiesJson);
    final modeString = configs["mode"] as String?;
    final mode = findTunnelMode(modeString);
    assert(mode != null, "mode is not the one of enum TunnelMode.");
    _tunnelMode.add(mode!);
    return ClashConfigResolveResult(
      httpPort: (configs["port"] as int).takeIf((v) => v != 0),
      socksPort: (configs["socks-port"] as int).takeIf((v) => v != 0),
      mixedPort: (configs["mixed-port"] as int).takeIf((v) => v != 0),
      proxyGroups: buildProxyGroups(proxies),
    );
  }

  ///
  /// select proxy group and proxy
  ///
  bool selectProxy(String groupName, String proxyName) {
    final ret = clashFFI.change_proxy(
        groupName.toNativeUtf8().cast(), proxyName.toNativeUtf8().cast());
    return ret == 0;
  }

  ///
  /// start system proxy
  ///
  Future<bool> startSystemProxy(
      ClashConfigResolveResult configResolveResult) async {
    final hPort = configResolveResult.httpPort ?? configResolveResult.mixedPort;
    final sPort =
        configResolveResult.socksPort ?? configResolveResult.mixedPort;
    try {
      await Future.wait([
        if (hPort != null)
          _proxyManager.setAsSystemProxy(
            ProxyTypes.http,
            '127.0.0.1',
            hPort,
          ),
        if (hPort != null)
          _proxyManager.setAsSystemProxy(
            ProxyTypes.https,
            '127.0.0.1',
            hPort,
          ),
        //Windows is NOT support socks
        if (sPort != null && !Platform.isWindows)
          _proxyManager.setAsSystemProxy(
            ProxyTypes.socks,
            '127.0.0.1',
            sPort,
          ),
      ]);
      _systemProxyEnabled.add(true);
      return true;
    } catch (e, stack) {
      _log(e);
      debugPrintStack(stackTrace: stack);
    }
    _systemProxyEnabled.add(false);
    return false;
  }

  ///
  /// stop system proxy
  ///
  Future<void> stopSystemProxy() async {
    await _proxyManager.cleanSystemProxy();
    _systemProxyEnabled.add(false);
  }

  void setTunnelMode(TunnelMode mode) {
    final modeString = mode.name;
    clashFFI.set_tun_mode(modeString.toNativeUtf8().cast());
    final resultString = clashFFI.get_tun_mode().cast<Utf8>().toDartString();
    final result = findTunnelMode(resultString);
    assert(result != null, "mode is not the one of enum TunnelMode.");
    _tunnelMode.add(result!);
  }

  ///
  /// get current clash connections
  /// key is connectionId, TODO what is value
  ///
  Map<String, dynamic> getConnections() {
    String connections =
        clashFFI.get_all_connections().cast<Utf8>().toDartString();
    return jsonDecode(connections);
  }

  ///
  /// close all clash connections
  ///
  void closeAllConnections() {
    clashFFI.close_all_connections();
  }

  ///
  /// close certain clash connection by connectionId.
  /// you can get connectionId by calling [getConnections].
  ///
  bool closeConnection(String connectionId) {
    final id = connectionId.toNativeUtf8().cast<ffi.Char>();
    return clashFFI.close_connection(id) == 1;
  }

  ///
  /// get traffic through clash
  ///
  String getTraffic() {
    String traffic = clashFFI.get_traffic().cast<Utf8>().toDartString();
    return traffic;
  }

  ///
  /// start clash logging
  /// logs will pollute into [logStream]
  ///
  void startLogging() {
    if (!kReleaseMode) {
      logStream.listen((event) {
        _log("logStream: $event");
      });
    }
    final nativePort = _logReceiver.sendPort.nativePort;
    clashFFI.start_log(nativePort);
  }

  Future<void> testDelay(
    Iterable<String> proxyNames, {
    Duration timeout = const Duration(seconds: 5),
    String url = "https://www.google.com",
  }) async {
    await Future.wait(
      proxyNames.map(
        (proxyName) async {
          final delay = await _testDelay(
            proxyName,
            timeout.inMilliseconds,
            url,
          );
          delayOf(proxyName).value = delay;
        },
      ),
    );
  }

  Future<int> _testDelay(String proxyName, int timeout, String url) async {
    try {
      final completer = Completer<int>();
      final receiver = ReceivePort();
      clashFFI.async_test_delay(proxyName.toNativeUtf8().cast(),
          url.toNativeUtf8().cast(), timeout, receiver.sendPort.nativePort);
      final subs = receiver.listen((message) {
        if (!completer.isCompleted) {
          completer.complete(json.decode(message)['delay']);
        }
      });
      // 5s timeout, we add 1s
      Future.delayed(const Duration(seconds: 6), () {
        if (!completer.isCompleted) {
          completer.complete(-1);
        }
        subs.cancel();
      });
      return completer.future;
    } catch (e) {
      return -1;
    }
  }
}

_log(Object? object) {
  if (kReleaseMode) return;
  // ignore: avoid_print
  print("[ClashPcFlt]$object");
}

extension _Ext<T> on T {
  T? takeIf(bool Function(T v) condition) {
    if (condition.call(this)) return this;
    return null;
  }
}

enum TunnelMode {
  global,
  rule,
  direct,
}

TunnelMode? findTunnelMode(String? mode) {
  if (mode == null) return null;
  for (var tunnelMode in TunnelMode.values) {
    if (tunnelMode.name.toLowerCase() == mode.toLowerCase()) {
      return tunnelMode;
    }
  }
  return null;
}
