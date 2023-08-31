import 'clash_proxy.dart';

class ClashProxyGroup extends ClashProxy {
  final List<ClashProxy> proxies;
  const ClashProxyGroup({
    required super.name,
    required super.type,
    required super.history,
    required this.proxies,
  });
}
