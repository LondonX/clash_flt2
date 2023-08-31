#ifndef FLUTTER_PLUGIN_CLASH_PC_FLT_PLUGIN_H_
#define FLUTTER_PLUGIN_CLASH_PC_FLT_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace clash_pc_flt {

class ClashPcFltPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ClashPcFltPlugin();

  virtual ~ClashPcFltPlugin();

  // Disallow copy and assign.
  ClashPcFltPlugin(const ClashPcFltPlugin&) = delete;
  ClashPcFltPlugin& operator=(const ClashPcFltPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace clash_pc_flt

#endif  // FLUTTER_PLUGIN_CLASH_PC_FLT_PLUGIN_H_
