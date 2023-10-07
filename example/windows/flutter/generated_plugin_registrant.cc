//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <clash_flt2/clash_flt2_plugin_c_api.h>
#include <proxy_manager/proxy_manager_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  ClashFlt2PluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ClashFlt2PluginCApi"));
  ProxyManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ProxyManagerPlugin"));
}
