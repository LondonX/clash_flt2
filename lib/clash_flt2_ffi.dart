import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';

import 'package:clash_flt2/android_helper.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:proxy_manager/proxy_manager.dart';

import 'entity/clash_config_resolve_result.dart';
import 'ffi/generated_bindings.dart';

import 'utils.dart';
import 'clash_flt2_impl.dart';

late NativeLibrary clashFFI;
const mobileChannel = MethodChannel("FClashPlugin");

///
/// ClashFlt implementation with FlutterFFI
/// not support on iOS due to App Store policy
/// see also [ClashFlt2IOS]
///
class ClashFlt2FFI extends ClashFlt2 {
  static final instance = ClashFlt2FFI._();

  final _proxyManager = ProxyManager();
  late final _mobileHelper = Platform.isAndroid
      ? AndroidHelper(systemProxyEnabled: systemProxyEnabled)
      : null;

  final _logReceiver = ReceivePort();

  ClashFlt2FFI._() : super() {
    _logReceiver.asBroadcastStream().listen((event) {
      if (event is! String) return;
      addLog(event);
    });
  }

  @override
  void init() {
    _mobileHelper?.init();
    final String libFileName;
    if (Platform.isWindows) {
      libFileName = "libclash.dll";
    } else if (Platform.isMacOS) {
      libFileName = "libclash.dylib";
    } else if (Platform.isIOS) {
      throw FlutterError(
        "FlutterFFI cannot be used on iOS due to App Store policy",
      );
      // libFileName = "libclash-ios.dylib";
    } else {
      // Android / Linux
      libFileName = "libclash.so";
    }
    final lib = ffi.DynamicLibrary.open(libFileName);
    clashFFI = NativeLibrary(lib);
    clashFFI.init_native_api_bridge(ffi.NativeApi.initializeApiDLData);
  }

  ///
  /// init clash and set configs
  ///
  @override
  ClashConfigResolveResult? setConfig(File yamlFile, Directory clashHome) {
    clashFFI.set_config(yamlFile.path.toNativeUtf8().cast());
    clashFFI.set_home_dir(clashHome.path.toNativeUtf8().cast());
    clashFFI.clash_init(clashHome.path.toNativeUtf8().cast());
    clashFFI.parse_options();
    final configsJson = clashFFI.get_configs().cast<Utf8>().toDartString();
    final proxiesJson = clashFFI.get_proxies().cast<Utf8>().toDartString();
    final configs = jsonDecode(configsJson);
    final proxies = jsonDecode(proxiesJson);
    final mode = tunnelModeByName(configs["mode"] as String);
    tunnelMode.value = mode;
    _mobileHelper?.setConfig(yamlFile, clashHome);
    _mobileHelper?.setMode(mode);
    return ClashConfigResolveResult(
      httpPort: (configs["port"] as int?).takeIf((v) => v != 0),
      socksPort: (configs["socks-port"] as int?).takeIf((v) => v != 0),
      mixedPort: (configs["mixed-port"] as int?).takeIf((v) => v != 0),
      proxyGroups: buildProxyGroups(proxies),
    );
  }

  ///
  /// select proxy group and proxy
  ///
  @override
  bool selectProxy(String groupName, String proxyName) {
    final ret = 0 ==
        clashFFI.change_proxy(
            groupName.toNativeUtf8().cast(), proxyName.toNativeUtf8().cast());
    if (ret) {
      _mobileHelper?.selectProxy(groupName, proxyName);
    }
    return ret;
  }

  ///
  /// start system proxy
  /// return true if start successful
  ///
  @override
  Future<bool> startSystemProxy(
    ClashConfigResolveResult configResolveResult,
  ) async {
    final mPort = configResolveResult.mixedPort;
    final hPort = mPort ?? configResolveResult.httpPort;
    final sPort = mPort ?? configResolveResult.socksPort;
    try {
      if (Platform.isAndroid) {
        return await _mobileHelper!.startService(
          hPort ?? 0,
          sPort ?? 0,
          mPort ?? 0,
        );
      }
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
      systemProxyEnabled.value = true;
      return true;
    } catch (e, stack) {
      _log(e);
      debugPrintStack(stackTrace: stack);
    }
    systemProxyEnabled.value = false;
    return false;
  }

  ///
  /// stop system proxy
  ///
  @override
  Future<void> stopSystemProxy() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await _mobileHelper?.stopService();
      return;
    }
    if (!systemProxyEnabled.value) return;
    await _proxyManager.cleanSystemProxy();
    systemProxyEnabled.value = false;
  }

  ///
  /// set tunnel in global, rule, direct mode
  /// see [TunnelMode]
  ///
  @override
  void setTunnelMode(TunnelMode mode) {
    final modeString = mode.name;
    clashFFI.set_tun_mode(modeString.toNativeUtf8().cast());
    final resultString = clashFFI.get_tun_mode().cast<Utf8>().toDartString();
    final result = tunnelModeByName(resultString);
    assert(result == mode,
        "mode is not supported by clash core. resultString: $resultString");
    _mobileHelper?.setMode(result);
    tunnelMode.value = result;
  }

  ///
  /// get current clash connections
  ///
  @override
  Map<String, dynamic> getConnections() {
    String connections =
        clashFFI.get_all_connections().cast<Utf8>().toDartString();
    return jsonDecode(connections);
  }

  ///
  /// close all clash connections
  ///
  @override
  void closeAllConnections() {
    clashFFI.close_all_connections();
  }

  ///
  /// close certain clash connection by connectionId.
  /// you can get connectionId by calling [getConnections].
  ///
  @override
  bool closeConnection(String connectionId) {
    final id = connectionId.toNativeUtf8().cast<ffi.Char>();
    return clashFFI.close_connection(id) == 1;
  }

  ///
  /// get traffic through clash
  ///
  @override
  @protected
  String? getTrafficJson() {
    return clashFFI.get_traffic().cast<Utf8>().toDartString();
  }

  StreamSubscription? _logging;

  ///
  /// start clash logging
  /// logs will pollute into [logStream]
  /// see [stopLogging]
  ///
  @override
  void startLogging() {
    if (!kReleaseMode) {
      _logging = logStream.listen((event) {
        _log("logStream: $event");
      });
    }
    final nativePort = _logReceiver.sendPort.nativePort;
    clashFFI.start_log(nativePort);
  }

  ///
  /// stop clash logging
  /// see [startLogging]
  ///
  @override
  void stopLogging() {
    _logging?.cancel();
    clashFFI.stop_log();
  }

  ///
  /// test delay of given [proxyNames]
  ///
  @override
  Future<void> testDelay(
    Set<String> proxyNames, {
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
  print("[ClashFlt2FFI]$object");
}
