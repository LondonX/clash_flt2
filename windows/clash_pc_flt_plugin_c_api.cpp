#include "include/clash_pc_flt/clash_pc_flt_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "clash_pc_flt_plugin.h"

void ClashPcFltPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  clash_pc_flt::ClashPcFltPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
