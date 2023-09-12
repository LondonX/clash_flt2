import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:clash_pc_flt/clash_pc_flt.dart';
import 'package:clash_pc_flt_example/proxy_selector_view.dart';
import 'package:clash_pc_flt_example/sensitive_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var _isDownloading = false;
  File? _yamlFile;
  File? _mmdbFile;
  ProxySelection? _proxySelection;
  ClashConfigResolveResult? _configResolveResult;
  var _changingClashState = false;

  _downloadYamlFile() async {
    setState(() {
      _isDownloading = true;
    });
    final resp = await GetConnect().get(yamlUrl);
    setState(() {
      _isDownloading = false;
    });
    if (!resp.isOk) return;
    final appSupportDir = await getApplicationSupportDirectory();
    final clashHomeDir = Directory("${appSupportDir.path}/clash_home");
    final yamlFile = File("${clashHomeDir.path}/config2.yaml");
    await yamlFile.create(recursive: true);
    await yamlFile.writeAsString(resp.bodyString!);
    setState(() {
      _yamlFile = yamlFile;
    });
  }

  _saveMmdb() async {
    if (_yamlFile == null) return;
    final data = await rootBundle.load("assets/Country.mmdb");
    final mmdbFile = File("${_yamlFile!.parent.path}/Country.mmdb");
    await mmdbFile.create(recursive: true);
    await mmdbFile.writeAsBytes(data.buffer.asUint8List());
    setState(() {
      _mmdbFile = mmdbFile;
    });
  }

  _setConfig() async {
    if (_yamlFile == null || _mmdbFile == null) return;
    final result = ClashPcFlt.instance.setConfig(_yamlFile!, _yamlFile!.parent);
    setState(() {
      _configResolveResult = result;
    });
  }

  _selectProxy() async {
    if (_configResolveResult == null) return;
    final selection = await ProxySelectorView.start(
      context,
      configResolveResult: _configResolveResult!,
    );
    if (selection == null) return;
    ClashPcFlt.instance.selectProxy(selection.group.name, selection.proxy);
    setState(() {
      _proxySelection = selection;
    });
  }

  _toggleRunning(bool shouldRun) async {
    setState(() {
      _changingClashState = true;
    });
    if (shouldRun) {
      await ClashPcFlt.instance.startSystemProxy(_configResolveResult!);
    } else {
      await ClashPcFlt.instance.stopSystemProxy();
    }
    setState(() {
      _changingClashState = false;
    });
  }

  Timer? _trafficUpdating;

  ///
  /// traffic updating can be called before [ClashPcFlt.instance.init]
  ///
  _startTrafficUpdating() {
    _trafficUpdating = Timer.periodic(const Duration(seconds: 1), (timer) {
      ClashPcFlt.instance.updateTraffic();
    });
  }

  _showAlert(String content) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(content)),
      );
  }

  @override
  void initState() {
    ClashPcFlt.instance.init();
    _startTrafficUpdating();
    super.initState();
  }

  @override
  void dispose() {
    _trafficUpdating?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Clash PC Flt"),
      ),
      body: ListView(
        children: [
          _buildStringListTile(
            context,
            title: "1. Download yaml file",
            subtitle: _isDownloading
                ? "Downloading"
                : _yamlFile == null
                    ? null
                    : "Downloaded ${_yamlFile!.path}",
            onTap: _downloadYamlFile,
          ),
          _buildStringListTile(
            context,
            title: "2. Save Country.mmdb into clash home",
            subtitle: _mmdbFile == null ? null : "Saved at: ${_mmdbFile!.path}",
            onTap: _yamlFile == null ? null : _saveMmdb,
          ),
          _buildStringListTile(
            context,
            title: "3. ClashPcFlt.instance.setConfig",
            subtitle: """
port: ${_configResolveResult?.httpPort ?? "No config set"}
socks-port: ${_configResolveResult?.socksPort ?? "No config set"}
mixed-port: ${_configResolveResult?.mixedPort ?? "No config set"}
proxy-groups: ${_configResolveResult?.proxyGroups.length ?? "No config set"}
""",
            onTap: _yamlFile == null || _mmdbFile == null ? null : _setConfig,
          ),
          _buildStringListTile(
            context,
            title: "4. ClashPcFlt.instance.selectProxy",
            subtitle: _proxySelection == null
                ? null
                : "${_proxySelection!.group.name}/${_proxySelection!.proxy}",
            onTap: _configResolveResult == null ? null : _selectProxy,
          ),
          ValueListenableBuilder(
            valueListenable: ClashPcFlt.instance.systemProxyEnabled,
            builder: (context, systemProxyEnabled, widget) {
              return SwitchListTile(
                title:
                    const Text("5. ClashPcFlt.instance.startClash/stopClash"),
                value: systemProxyEnabled,
                onChanged: _changingClashState
                    ? null
                    : _proxySelection == null
                        ? null
                        : _toggleRunning,
              );
            },
          ),
          ListTile(
            title: const Text("6. ClashPcFlt.instance.setTunnelMode"),
            enabled: _configResolveResult != null,
            subtitle: ValueListenableBuilder(
              valueListenable: ClashPcFlt.instance.tunnelMode,
              builder: (context, tunnelMode, widget) {
                return Row(
                  children: TunnelMode.values.map((e) {
                    return Expanded(
                      child: RadioListTile<TunnelMode?>(
                        value: e,
                        groupValue: tunnelMode,
                        onChanged: _configResolveResult == null
                            ? null
                            : (value) {
                                if (value == null) return;
                                ClashPcFlt.instance.setTunnelMode(value);
                              },
                        title: Text(e.name),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          ListTile(
            title: const Text("ClashPcFlt.instance.traffic"),
            subtitle: ValueListenableBuilder(
              valueListenable: ClashPcFlt.instance.traffic,
              builder: (context, traffic, widget) {
                return Text(
                  """
Total: up: ${_trafficReadable(traffic.totalUpload)} down: ${_trafficReadable(traffic.totalDownload)}
Current: up: ${_trafficReadable(traffic.currentUpload)}/s down: ${_trafficReadable(traffic.currentDownload)}/s
""",
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStringListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Function()? onTap,
  }) {
    return _buildListTile(
      context,
      title: title,
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    Widget? subtitle,
    Function()? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

String _trafficReadable(int traffic) {
  if (traffic < 1024) return "${traffic}B";
  if (traffic < pow(1024, 2)) {
    return "${(traffic / pow(1024, 1)).toStringAsFixed(1)}KB";
  }
  return "${(traffic / pow(1024, 2)).toStringAsFixed(1)}MB";
}
