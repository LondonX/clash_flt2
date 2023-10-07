#include "include/clash_flt2/clash_flt2_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "clash_flt2_plugin.h"

void ClashFlt2PluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  clash_flt2::ClashFlt2Plugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
