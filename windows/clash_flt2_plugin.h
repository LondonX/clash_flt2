#ifndef FLUTTER_PLUGIN_clash_flt2_PLUGIN_H_
#define FLUTTER_PLUGIN_clash_flt2_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace clash_flt2 {

class ClashFlt2Plugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ClashFlt2Plugin();

  virtual ~ClashFlt2Plugin();

  // Disallow copy and assign.
  ClashFlt2Plugin(const ClashFlt2Plugin&) = delete;
  ClashFlt2Plugin& operator=(const ClashFlt2Plugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace clash_flt2

#endif  // FLUTTER_PLUGIN_clash_flt2_PLUGIN_H_
