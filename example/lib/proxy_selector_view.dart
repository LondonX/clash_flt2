import 'package:flutter/material.dart';

import 'package:clash_pc_flt/clash_pc_flt.dart';
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
