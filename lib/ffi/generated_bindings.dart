// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

class NativeLibrary {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeLibrary(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeLibrary.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  int clash_init(
    ffi.Pointer<ffi.Char> home_dir,
  ) {
    return _clash_init(
      home_dir,
    );
  }

  late final _clash_initPtr =
      _lookup<ffi.NativeFunction<GoInt Function(ffi.Pointer<ffi.Char>)>>(
          'clash_init');
  late final _clash_init =
      _clash_initPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  int set_config(
    ffi.Pointer<ffi.Char> config_path,
  ) {
    return _set_config(
      config_path,
    );
  }

  late final _set_configPtr =
      _lookup<ffi.NativeFunction<GoInt Function(ffi.Pointer<ffi.Char>)>>(
          'set_config');
  late final _set_config =
      _set_configPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  int set_home_dir(
    ffi.Pointer<ffi.Char> home,
  ) {
    return _set_home_dir(
      home,
    );
  }

  late final _set_home_dirPtr =
      _lookup<ffi.NativeFunction<GoInt Function(ffi.Pointer<ffi.Char>)>>(
          'set_home_dir');
  late final _set_home_dir =
      _set_home_dirPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  ffi.Pointer<ffi.Char> get_config() {
    return _get_config();
  }

  late final _get_configPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_config');
  late final _get_config =
      _get_configPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  int set_ext_controller(
    int port,
  ) {
    return _set_ext_controller(
      port,
    );
  }

  late final _set_ext_controllerPtr =
      _lookup<ffi.NativeFunction<GoInt Function(GoUint64)>>(
          'set_ext_controller');
  late final _set_ext_controller =
      _set_ext_controllerPtr.asFunction<int Function(int)>();

  void clear_ext_options() {
    return _clear_ext_options();
  }

  late final _clear_ext_optionsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('clear_ext_options');
  late final _clear_ext_options =
      _clear_ext_optionsPtr.asFunction<void Function()>();

  int is_config_valid(
    ffi.Pointer<ffi.Char> config_path,
  ) {
    return _is_config_valid(
      config_path,
    );
  }

  late final _is_config_validPtr =
      _lookup<ffi.NativeFunction<GoInt Function(ffi.Pointer<ffi.Char>)>>(
          'is_config_valid');
  late final _is_config_valid =
      _is_config_validPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  ffi.Pointer<ffi.Char> get_all_connections() {
    return _get_all_connections();
  }

  late final _get_all_connectionsPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_all_connections');
  late final _get_all_connections =
      _get_all_connectionsPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  void close_all_connections() {
    return _close_all_connections();
  }

  late final _close_all_connectionsPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('close_all_connections');
  late final _close_all_connections =
      _close_all_connectionsPtr.asFunction<void Function()>();

  int close_connection(
    ffi.Pointer<ffi.Char> id,
  ) {
    return _close_connection(
      id,
    );
  }

  late final _close_connectionPtr =
      _lookup<ffi.NativeFunction<GoUint8 Function(ffi.Pointer<ffi.Char>)>>(
          'close_connection');
  late final _close_connection =
      _close_connectionPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  int parse_options() {
    return _parse_options();
  }

  late final _parse_optionsPtr =
      _lookup<ffi.NativeFunction<GoUint8 Function()>>('parse_options');
  late final _parse_options = _parse_optionsPtr.asFunction<int Function()>();

  ffi.Pointer<ffi.Char> get_traffic() {
    return _get_traffic();
  }

  late final _get_trafficPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_traffic');
  late final _get_traffic =
      _get_trafficPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  void init_native_api_bridge(
    ffi.Pointer<ffi.Void> api,
  ) {
    return _init_native_api_bridge(
      api,
    );
  }

  late final _init_native_api_bridgePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>(
          'init_native_api_bridge');
  late final _init_native_api_bridge = _init_native_api_bridgePtr
      .asFunction<void Function(ffi.Pointer<ffi.Void>)>();

  void start_log(
    int port,
  ) {
    return _start_log(
      port,
    );
  }

  late final _start_logPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.LongLong)>>('start_log');
  late final _start_log = _start_logPtr.asFunction<void Function(int)>();

  void stop_log() {
    return _stop_log();
  }

  late final _stop_logPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('stop_log');
  late final _stop_log = _stop_logPtr.asFunction<void Function()>();

  int change_proxy(
    ffi.Pointer<ffi.Char> selector_name,
    ffi.Pointer<ffi.Char> proxy_name,
  ) {
    return _change_proxy(
      selector_name,
      proxy_name,
    );
  }

  late final _change_proxyPtr = _lookup<
      ffi.NativeFunction<
          ffi.Long Function(
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>>('change_proxy');
  late final _change_proxy = _change_proxyPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  int change_config_field(
    ffi.Pointer<ffi.Char> s,
  ) {
    return _change_config_field(
      s,
    );
  }

  late final _change_config_fieldPtr =
      _lookup<ffi.NativeFunction<ffi.Long Function(ffi.Pointer<ffi.Char>)>>(
          'change_config_field');
  late final _change_config_field =
      _change_config_fieldPtr.asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  void async_test_delay(
    ffi.Pointer<ffi.Char> proxy_name,
    ffi.Pointer<ffi.Char> url,
    int timeout,
    int port,
  ) {
    return _async_test_delay(
      proxy_name,
      url,
      timeout,
      port,
    );
  }

  late final _async_test_delayPtr = _lookup<
      ffi.NativeFunction<
          ffi.Void Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
              ffi.Long, ffi.LongLong)>>('async_test_delay');
  late final _async_test_delay = _async_test_delayPtr.asFunction<
      void Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, int, int)>();

  ffi.Pointer<ffi.Char> get_proxies() {
    return _get_proxies();
  }

  late final _get_proxiesPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_proxies');
  late final _get_proxies =
      _get_proxiesPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  ffi.Pointer<ffi.Char> get_providers() {
    return _get_providers();
  }

  late final _get_providersPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_providers');
  late final _get_providers =
      _get_providersPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  ffi.Pointer<ffi.Char> get_configs() {
    return _get_configs();
  }

  late final _get_configsPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'get_configs');
  late final _get_configs =
      _get_configsPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();
}

final class __mbstate_t extends ffi.Union {
  @ffi.Array.multi([128])
  external ffi.Array<ffi.Char> __mbstate8;

  @ffi.LongLong()
  external int _mbstateL;
}

final class __darwin_pthread_handler_rec extends ffi.Struct {
  external ffi
      .Pointer<ffi.NativeFunction<ffi.Void Function(ffi.Pointer<ffi.Void>)>>
      __routine;

  external ffi.Pointer<ffi.Void> __arg;

  external ffi.Pointer<__darwin_pthread_handler_rec> __next;
}

final class _opaque_pthread_attr_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([56])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_cond_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([40])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_condattr_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([8])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_mutex_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([56])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_mutexattr_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([8])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_once_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([8])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_rwlock_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([192])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_rwlockattr_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  @ffi.Array.multi([16])
  external ffi.Array<ffi.Char> __opaque;
}

final class _opaque_pthread_t extends ffi.Struct {
  @ffi.Long()
  external int __sig;

  external ffi.Pointer<__darwin_pthread_handler_rec> __cleanup_stack;

  @ffi.Array.multi([8176])
  external ffi.Array<ffi.Char> __opaque;
}

final class _GoString_ extends ffi.Struct {
  external ffi.Pointer<ffi.Char> p;

  @ptrdiff_t()
  external int n;
}

typedef ptrdiff_t = __darwin_ptrdiff_t;
typedef __darwin_ptrdiff_t = ffi.Long;

final class GoInterface extends ffi.Struct {
  external ffi.Pointer<ffi.Void> t;

  external ffi.Pointer<ffi.Void> v;
}

final class GoSlice extends ffi.Struct {
  external ffi.Pointer<ffi.Void> data;

  @GoInt()
  external int len;

  @GoInt()
  external int cap;
}

typedef GoInt = GoInt64;
typedef GoInt64 = ffi.LongLong;
typedef GoUint64 = ffi.UnsignedLongLong;
typedef GoUint8 = ffi.UnsignedChar;

const int __DARWIN_ONLY_64_BIT_INO_T = 0;

const int __DARWIN_ONLY_UNIX_CONFORMANCE = 1;

const int __DARWIN_ONLY_VERS_1050 = 0;

const int __DARWIN_UNIX03 = 1;

const int __DARWIN_64_BIT_INO_T = 1;

const int __DARWIN_VERS_1050 = 1;

const int __DARWIN_NON_CANCELABLE = 0;

const String __DARWIN_SUF_64_BIT_INO_T = '\$INODE64';

const String __DARWIN_SUF_1050 = '\$1050';

const String __DARWIN_SUF_EXTSN = '\$DARWIN_EXTSN';

const int __DARWIN_C_ANSI = 4096;

const int __DARWIN_C_FULL = 900000;

const int __DARWIN_C_LEVEL = 900000;

const int __STDC_WANT_LIB_EXT1__ = 1;

const int __DARWIN_NO_LONG_LONG = 0;

const int _DARWIN_FEATURE_64_BIT_INODE = 1;

const int _DARWIN_FEATURE_ONLY_UNIX_CONFORMANCE = 1;

const int _DARWIN_FEATURE_UNIX_CONFORMANCE = 3;

const int __has_ptrcheck = 0;

const int __DARWIN_NULL = 0;

const int __PTHREAD_SIZE__ = 8176;

const int __PTHREAD_ATTR_SIZE__ = 56;

const int __PTHREAD_MUTEXATTR_SIZE__ = 8;

const int __PTHREAD_MUTEX_SIZE__ = 56;

const int __PTHREAD_CONDATTR_SIZE__ = 8;

const int __PTHREAD_COND_SIZE__ = 40;

const int __PTHREAD_ONCE_SIZE__ = 8;

const int __PTHREAD_RWLOCK_SIZE__ = 192;

const int __PTHREAD_RWLOCKATTR_SIZE__ = 16;

const int __DARWIN_WCHAR_MAX = 2147483647;

const int __DARWIN_WCHAR_MIN = -2147483648;

const int __DARWIN_WEOF = -1;

const int _FORTIFY_SOURCE = 2;

const int NULL = 0;

const int USER_ADDR_NULL = 0;

const int __WORDSIZE = 64;

const int INT8_MAX = 127;

const int INT16_MAX = 32767;

const int INT32_MAX = 2147483647;

const int INT64_MAX = 9223372036854775807;

const int INT8_MIN = -128;

const int INT16_MIN = -32768;

const int INT32_MIN = -2147483648;

const int INT64_MIN = -9223372036854775808;

const int UINT8_MAX = 255;

const int UINT16_MAX = 65535;

const int UINT32_MAX = 4294967295;

const int UINT64_MAX = -1;

const int INT_LEAST8_MIN = -128;

const int INT_LEAST16_MIN = -32768;

const int INT_LEAST32_MIN = -2147483648;

const int INT_LEAST64_MIN = -9223372036854775808;

const int INT_LEAST8_MAX = 127;

const int INT_LEAST16_MAX = 32767;

const int INT_LEAST32_MAX = 2147483647;

const int INT_LEAST64_MAX = 9223372036854775807;

const int UINT_LEAST8_MAX = 255;

const int UINT_LEAST16_MAX = 65535;

const int UINT_LEAST32_MAX = 4294967295;

const int UINT_LEAST64_MAX = -1;

const int INT_FAST8_MIN = -128;

const int INT_FAST16_MIN = -32768;

const int INT_FAST32_MIN = -2147483648;

const int INT_FAST64_MIN = -9223372036854775808;

const int INT_FAST8_MAX = 127;

const int INT_FAST16_MAX = 32767;

const int INT_FAST32_MAX = 2147483647;

const int INT_FAST64_MAX = 9223372036854775807;

const int UINT_FAST8_MAX = 255;

const int UINT_FAST16_MAX = 65535;

const int UINT_FAST32_MAX = 4294967295;

const int UINT_FAST64_MAX = -1;

const int INTPTR_MAX = 9223372036854775807;

const int INTPTR_MIN = -9223372036854775808;

const int UINTPTR_MAX = -1;

const int INTMAX_MAX = 9223372036854775807;

const int UINTMAX_MAX = -1;

const int INTMAX_MIN = -9223372036854775808;

const int PTRDIFF_MIN = -9223372036854775808;

const int PTRDIFF_MAX = 9223372036854775807;

const int SIZE_MAX = -1;

const int RSIZE_MAX = 9223372036854775807;

const int WCHAR_MAX = 2147483647;

const int WCHAR_MIN = -2147483648;

const int WINT_MIN = -2147483648;

const int WINT_MAX = 2147483647;

const int SIG_ATOMIC_MIN = -2147483648;

const int SIG_ATOMIC_MAX = 2147483647;
