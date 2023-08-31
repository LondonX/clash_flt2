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
