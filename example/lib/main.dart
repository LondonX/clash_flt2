import 'dart:io';

import 'package:clash_pc_flt/clash_pc_flt.dart';
import 'package:clash_pc_flt_example/proxy_selector_view.dart';
import 'package:clash_pc_flt_example/sensitive_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _isDownloading = false;
  File? _yamlFile;
  File? _mmdbFile;
  ProxySelection? _proxySelection;
  ClashConfigResolveResult? _configResolveResult;
  var _changingClashState = false;
  var _clashRunning = false;

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

  _setConfig() {
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
      _clashRunning = shouldRun;
    });
    final bool operationSuccess;
    if (shouldRun) {
      operationSuccess =
          await ClashPcFlt.instance.startSystemProxy(_configResolveResult!);
    } else {
      await ClashPcFlt.instance.stopSystemProxy();
      operationSuccess = true;
    }
    setState(() {
      _changingClashState = false;
      if (!operationSuccess) {
        _clashRunning = !_clashRunning;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Clash PC Flt"),
        ),
        body: ListView(
          children: [
            _buildListTile(
              context,
              title: "1. Download yaml file",
              subtitle: _isDownloading
                  ? "Downloading"
                  : _yamlFile == null
                      ? null
                      : "Downloaded ${_yamlFile!.path}",
              onTap: _downloadYamlFile,
            ),
            _buildListTile(
              context,
              title: "2. Save Country.mmdb into clash home",
              subtitle:
                  _mmdbFile == null ? null : "Saved at: ${_mmdbFile!.path}",
              onTap: _yamlFile == null ? null : _saveMmdb,
            ),
            _buildListTile(
              context,
              title: "3. ClashPcFlt.instance.init",
              onTap: ClashPcFlt.instance.init,
            ),
            _buildListTile(
              context,
              title: "4. ClashPcFlt.instance.setConfig",
              subtitle: """
(http/https)port: ${_configResolveResult?.httpPort ?? "No config set"}
socks-port: ${_configResolveResult?.socksPort ?? "No config set"}
mixed-port: ${_configResolveResult?.mixedPort ?? "No config set"}
proxy-groups: ${_configResolveResult?.proxyGroups.length ?? "No config set"}
""",
              onTap: _yamlFile == null || _mmdbFile == null ? null : _setConfig,
            ),
            _buildListTile(
              context,
              title: "5. ClashPcFlt.instance.selectProxy",
              subtitle: _proxySelection == null
                  ? null
                  : "${_proxySelection!.group.name}/${_proxySelection!.proxy}",
              onTap: _configResolveResult == null ? null : _selectProxy,
            ),
            SwitchListTile(
              title: const Text("6. ClashPcFlt.instance.startClash/stopClash"),
              value: _clashRunning,
              onChanged: _changingClashState
                  ? null
                  : _proxySelection == null
                      ? null
                      : _toggleRunning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    Function()? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}
