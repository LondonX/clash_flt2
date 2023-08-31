// {
//   "history": [],
//   "name": "🇨🇳 CN13 香港高级线路_TR ⚡",
//   "type": "Trojan",
//   "udp": true
// }
class ClashProxy {
  final List<dynamic> history;
  final String name;
  final String type;
  const ClashProxy({
    required this.history,
    required this.name,
    required this.type,
  });

  factory ClashProxy.fromJson(Map<String, dynamic> json) {
    return ClashProxy(
      history: json["history"],
      name: json["name"],
      type: json["type"],
    );
  }
}
