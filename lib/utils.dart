import 'entity/clash_proxy.dart';
import 'entity/clash_proxy_group.dart';

const _groupTypes = [
  "Relay",
  "Selector",
  "Fallback",
  "URLTest",
  "LoadBalance",
  "Direct",
  "Reject",
]; // https://github.com/Dreamacro/clash/blob/e5f2396f810a778792cc305d3cee293b5a677c25/constant/adapters.go#L148C13-L148C13

List<ClashProxyGroup> buildProxyGroups(Map<String, dynamic> proxies) {
  final results = <ClashProxyGroup>[];
  final groupedProxyNames = <String, List<String>>{};
  final allProxies = <ClashProxy>[];
  for (var name in proxies.keys) {
    final proxyJson = proxies[name];
    final proxy = ClashProxy.fromJson(proxyJson);
    if (_groupTypes.contains(proxy.type)) {
      // is proxy group
      final names = groupedProxyNames[name] ??= [];
      names.addAll((proxyJson["all"] as List?)?.map((e) => e as String) ?? []);
      results.add(
        ClashProxyGroup(name: name, type: proxy.type, proxies: [], history: []),
      );
    }
    allProxies.add(proxy);
  }
  for (var group in results) {
    final names = groupedProxyNames[group.name] ?? [];
    final groupProxies = names
        .map((name) => allProxies.firstWhere((proxy) => proxy.name == name));
    group.proxies.addAll(groupProxies);
  }
  return results;
}

extension ClashConfigExt on String {
  String replaceGeneralConfigValue(Map<String, Object> replacement) {
    List<String> lines = split('\n');
    for (int i = 0; i < lines.length; i++) {
      for (var key in replacement.keys) {
        final newValue = replacement[key];
        if (lines[i].startsWith('$key:')) {
          lines[i] = '$key: $newValue';
        }
      }
    }
    return lines.join('\n');
  }

  Map<String, dynamic> resolveGeneralConfigs() {
    Map<String, dynamic> result = {};
    List<String> lines = split('\n');
    for (String line in lines) {
      if (line.startsWith(" ")) continue;
      List<String> parts = line.split(': ');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        final intV = int.tryParse(value);
        result[key] = intV ?? value;
      }
    }
    return result;
  }

  Map<String, String> resolveInitArg() {
    final index = indexOf(":");
    return {
      substring(0, index): substring(index + 1),
    };
  }
}

extension LxExt<T> on T {
  T? takeIf(bool Function(T v) condition) {
    if (condition.call(this)) return this;
    return null;
  }
}
