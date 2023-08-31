//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <clash_pc_flt/clash_pc_flt_plugin_c_api.h>
#include <proxy_manager/proxy_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ClashPcFltPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ClashPcFltPluginCApi"));
  ProxyManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ProxyManagerPlugin"));
}
