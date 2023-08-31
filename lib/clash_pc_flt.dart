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
  Future<bool> startClash(ClashConfigResolveResult configResolveResult) async {
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
        if (sPort != null)
          _proxyManager.setAsSystemProxy(
            ProxyTypes.socks,
            '127.0.0.1',
            sPort,
          ),
      ]);
      return true;
    } catch (e, stack) {
      _log(e);
      debugPrintStack(stackTrace: stack);
    }
    return false;
  }

  ///
  /// stop system proxy
  ///
  Future<void> stopClash() async {
    await _proxyManager.cleanSystemProxy();
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
