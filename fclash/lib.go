package fclash

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/Dreamacro/clash/adapter"
	"github.com/Dreamacro/clash/adapter/outboundgroup"
	"github.com/Dreamacro/clash/common/observable"
	"github.com/Dreamacro/clash/component/profile/cachefile"
	"github.com/Dreamacro/clash/component/resolver"
	"github.com/Dreamacro/clash/config"
	"github.com/Dreamacro/clash/constant"
	"github.com/Dreamacro/clash/hub"
	"github.com/Dreamacro/clash/hub/executor"
	P "github.com/Dreamacro/clash/listener"
	"github.com/Dreamacro/clash/log"
	"github.com/Dreamacro/clash/tunnel"
	"github.com/Dreamacro/clash/tunnel/statistic"
)

type Client interface {
	Log(message string)
	DelayUpdate(name string, delay int64)
}

var (
	options        []hub.Option
	log_subscriber observable.Subscription
	client Client
)

func ClashInit(home_dir string, c Client) int {
	client = c
	err := config.Init(home_dir)
	if err != nil {
		fmt.Println("clash init failed:", err)
		return -1
	}
	return 0
}

func SetConfig(config_path string) int {
	if _, err := executor.ParseWithPath(config_path); err != nil {
		fmt.Println("config validate failed:", err)
		return -1
	}
	constant.SetConfig(config_path)
	return 0
}

func SetHomeDir(home string) int {
	info, err := os.Stat(home)
	if err == nil && info.IsDir() {
		fmt.Println("GO: set home dir to", home)
		constant.SetHomeDir(home)
		return 0
	} else {
		if err != nil {
			fmt.Println("error:", err)
		}
	}
	return -1
}

func GetConfig() string {
	return constant.Path.Config()
}

func SetExtController(port int) int {
	url := "127.0.0.1:" + strconv.FormatUint(uint64(port), 10)
	options = append(options, hub.WithExternalController(url))
	return 0
}

func ClearExtOptions() {
	options = options[:0]
}

func IsConfigValid(config_path string) int {
	if _, err := executor.ParseWithPath(config_path); err != nil {
		fmt.Println("error reading config:", err)
		return -1
	}
	return 0
}

func GetAllConnections() string {
	snapshot := statistic.DefaultManager.Snapshot()
	data, err := json.Marshal(snapshot)
	if err != nil {
		fmt.Println("Error:", err)
		return ""
	}
	return string(data)
}

func CloseAllConnections() {
	for _, connection := range statistic.DefaultManager.Snapshot().Connections {
		err := connection.Close()
		if err != nil {
			fmt.Println("warning:", err)
		}
	}
}

func CloseConnection(id string) bool {
	connection_id := id
	for _, connection := range statistic.DefaultManager.Snapshot().Connections {
		if connection.ID() == connection_id {
			err := connection.Close()
			if err != nil {
				fmt.Println("warning:", err)
			}
			return true
		}
	}
	return false
}

func ParseOptions() bool {
	err := hub.Parse(options...)
	if err != nil {
		return true
	}
	return false
}

func GetTraffic() string {
	up, down := statistic.DefaultManager.Now()
	traffic := map[string]int64{
		"Up":   up,
		"Down": down,
	}
	data, err := json.Marshal(traffic)
	if err != nil {
		fmt.Println("Error:", err)
		return ""
	}
	return string(data)
}

func StartLog() {
	if log_subscriber != nil {
		log.UnSubscribe(log_subscriber)
		log_subscriber = nil
	}
	log_subscriber = log.Subscribe()
	go func() {
		for elem := range log_subscriber {
			lg := elem
			data, err := json.Marshal(lg)
			if err != nil {
				fmt.Println("Error:", err)
			}
			ret_str := string(data)
			fmt.Println("ClashLog:", ret_str)
			if client != nil {
				client.Log(ret_str)
			}
		}
	}()
}

func StopLog() {
	if log_subscriber != nil {
		log.UnSubscribe(log_subscriber)
		fmt.Println("Logger stopped")
		log_subscriber = nil
	}
}

func ChangeProxy(selector_name string, proxy_name string) int64 {
	proxies := tunnel.Proxies()
	proxy := proxies[selector_name]
	if proxy == nil {
		return -1
	}
	adapter_proxy := proxy.(*adapter.Proxy)
	selector, ok := adapter_proxy.ProxyAdapter.(*outboundgroup.Selector)
	if !ok {
		// not selector
		return -1
	}
	if err := selector.Set(proxy_name); err != nil {
		fmt.Println("", err)
		return -1
	}
	cachefile.Cache().SetSelected(selector_name, proxy_name)
	return 0
}

type configSchema struct {
	Port        *int               `json:"port"`
	SocksPort   *int               `json:"socks-port"`
	RedirPort   *int               `json:"redir-port"`
	TProxyPort  *int               `json:"tproxy-port"`
	MixedPort   *int               `json:"mixed-port"`
	AllowLan    *bool              `json:"allow-lan"`
	BindAddress *string            `json:"bind-address"`
	Mode        *tunnel.TunnelMode `json:"mode"`
	LogLevel    *log.LogLevel      `json:"log-level"`
	IPv6        *bool              `json:"ipv6"`
}

func pointerOrDefault(p *int, def int) int {
	if p != nil {
		return *p
	}

	return def
}

func ChangeConfigField(s string) int64 {
	general := &configSchema{}
	if err := json.Unmarshal([]byte(s), general); err != nil {
		fmt.Println(err)
		return -1
	}
	// copy from clash source code
	if general.AllowLan != nil {
		P.SetAllowLan(*general.AllowLan)
	}

	if general.BindAddress != nil {
		P.SetBindAddress(*general.BindAddress)
	}

	ports := P.GetPorts()
	ports.MixedPort = pointerOrDefault(general.MixedPort, ports.MixedPort)
	ports.SocksPort = pointerOrDefault(general.SocksPort, ports.SocksPort)
	ports.RedirPort = pointerOrDefault(general.RedirPort, ports.RedirPort)
	ports.TProxyPort = pointerOrDefault(general.TProxyPort, ports.TProxyPort)
	ports.MixedPort = pointerOrDefault(general.MixedPort, ports.MixedPort)

	tcpIn := tunnel.TCPIn()
	udpIn := tunnel.UDPIn()
	P.ReCreatePortsListeners(*ports, tcpIn, udpIn)

	if general.Mode != nil {
		tunnel.SetMode(*general.Mode)
	}

	if general.LogLevel != nil {
		log.SetLevel(*general.LogLevel)
	}

	if general.IPv6 != nil {
		resolver.DisableIPv6 = !*general.IPv6
	}
	return 0
}

func AsyncTestDelay(proxy_name string, url string, timeout int64) {
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), time.Millisecond*time.Duration(timeout))
		defer cancel()
		proxies := tunnel.Proxies()
		proxy := proxies[proxy_name]
		if proxy == nil {
			client.DelayUpdate(proxy_name, -1)
			return
		}
		delay, _, err := proxy.URLTest(ctx, url)
		if err != nil || delay == 0 {
			client.DelayUpdate(proxy_name, -1)
			return
		}
		client.DelayUpdate(proxy_name, int64(delay))
	}()
}

func GetProxies() string {
	proxies := tunnel.Proxies()
	data, err := json.Marshal(proxies)
	if err != nil {
		return ""
	}
	return string(data)
}

func GetProviders() string {
	providers := tunnel.Providers()
	data, err := json.Marshal(providers)
	if err != nil {
		return ""
	}
	return string(data)
}

func GetConfigs() string {
	general := executor.GetGeneral()
	data, err := json.Marshal(general)
	if err != nil {
		return ""
	}
	return string(data)
}

func SetTunMode(s string) {
	mode_str := s
	mode, _ := tunnel.ModeMapping[mode_str]
	tunnel.SetMode(mode)
}

func GetTunMode() string {
	return tunnel.Mode().String()
}

func main() {
	fmt.Println("hello fclash")
}
