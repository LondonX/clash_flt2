import 'package:flutter/material.dart';

import 'package:clash_flt2/clash_flt2.dart';
import 'package:get/get.dart';

class ProxySelectorView extends StatefulWidget {
  final ClashConfigResolveResult configResolveResult;
  const ProxySelectorView({
    Key? key,
    required this.configResolveResult,
  }) : super(key: key);

  static Future<ProxySelection?> start(
    BuildContext context, {
    required ClashConfigResolveResult configResolveResult,
  }) async {
    return await Get.to(
      () => ProxySelectorView(configResolveResult: configResolveResult),
    );
  }

  @override
  State<ProxySelectorView> createState() => _ProxySelectorViewState();
}

class _ProxySelectorViewState extends State<ProxySelectorView>
    with TickerProviderStateMixin {
  List<ClashProxyGroup> get _displayGroups =>
      widget.configResolveResult.proxyGroups
          .where((group) => group.proxies.isNotEmpty)
          .toList();

  late final _tab = TabController(
    length: _displayGroups.length,
    vsync: this,
  );

  var _testing = false;
  _testDelay() async {
    setState(() {
      _testing = true;
    });
    final allProxies = <String>{};
    for (var group in _displayGroups) {
      allProxies.addAll(group.proxies.map((e) => e.name));
    }
    await ClashFlt2.instance.testDelay(allProxies);
    setState(() {
      _testing = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select proxy"),
        bottom: TabBar(
          tabs: _displayGroups
              .map(
                (group) => Tab(
                  text: "${group.name}\n${group.type}",
                ),
              )
              .toList(),
          controller: _tab,
        ),
        actions: [
          _testing
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(),
                  ),
                )
              : IconButton(
                  onPressed: _testDelay,
                  icon: const Icon(Icons.speed),
                ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: _displayGroups
            .map(
              (group) => ListView.builder(
                itemCount: group.proxies.length,
                itemBuilder: (context, index) {
                  final proxy = group.proxies[index];
                  return ListTile(
                    title: Text(proxy.name),
                    subtitle: ValueListenableBuilder(
                      valueListenable: ClashFlt2.instance.delayOf(proxy.name),
                      builder: (context, delay, child) {
                        return Text(
                          "ClashFlt2.instance.delayOf(proxy.name): $delay",
                          style: TextStyle(
                            color: delay == -1
                                ? Colors.grey
                                : delay < 500
                                    ? Colors.green
                                    : delay < 1000
                                        ? Colors.amber
                                        : Colors.red,
                          ),
                        );
                      },
                    ),
                    onTap: group.type == "Selector"
                        ? () {
                            Navigator.of(context).pop(
                              ProxySelection(group: group, proxy: proxy.name),
                            );
                          }
                        : null,
                    enabled: group.type == "Selector",
                  );
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class ProxySelection {
  final ClashProxyGroup group;
  final String proxy;
  const ProxySelection({
    required this.group,
    required this.proxy,
  });
}
