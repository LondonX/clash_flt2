import 'dart:io';

import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:network_tools/network_tools.dart';
import 'package:yaml/yaml.dart';

final _emojiParser = EmojiParser(init: true);
List<int> getPortsInYaml(File yamlFile) {
  final rawYaml = yamlFile.readAsStringSync();
  final emojis = _emojiParser.parseEmojis(rawYaml).toSet();
  var unemojified = rawYaml;
  for (var emoji in emojis) {
    unemojified = unemojified.replaceAll(emoji, "emoji");
  }
  final doc = loadYaml(unemojified);
  final port = doc["port"] as int?;
  final mixedPort = doc["mixed-port"] as int?;
  final socksPort = doc["socks-port"] as int?;
  return [
    if (port != null) port,
    if (mixedPort != null) mixedPort,
    if (socksPort != null) socksPort,
  ];
}

Future<bool> isPortUsed(int port) async {
  return null !=
      await PortScanner.isOpen(
        "127.0.0.1",
        port,
        timeout: const Duration(milliseconds: 200),
      );
}
