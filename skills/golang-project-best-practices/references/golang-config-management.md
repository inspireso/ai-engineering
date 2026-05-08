# 配置管理详解

## 方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| Viper + YAML | 灵活、热更新、多格式 | 无类型约束 | 通用 |
| Viper + Protobuf | 类型安全、可生成代码 | 需额外 proto 文件 | 大型项目 |
| 环境变量 + 结构体 | 简单直接 | 不支持复杂配置 | 小型项目 |

**推荐方案：Viper + Protobuf**（类型安全 + 灵活）

## 配置结构定义

使用 protobuf 定义配置类型：

```protobuf
// internal/conf/conf.proto
syntax = "proto3";
package conf;

option go_package = ".;conf";

message Bootstrap {
  Metrics metrics = 1;
  Server server = 2;
  MySQL_Config mysql = 3;
  Redis_Config redis = 4;
}

message Metrics {
  bool enabled = 1;
  string addr = 2;
  string path = 3;
}

message Server {
  Http http = 1;
  Grpc grpc = 2;
}

message Server_Http {
  string addr = 1;
  bool tls = 2;
  bool enabled = 3;
}

message Server_Grpc {
  string addr = 1;
  bool tls = 2;
  bool enabled = 3;
  string network = 4;
}
```

## 配置加载实现

```go
// internal/conf/conf.go

package conf

import (
    "github.com/fsnotify/fsnotify"
    "github.com/pkg/errors"
    "github.com/spf13/pflag"
    "github.com/spf13/viper"
)

var configVar string

func Parse() (*Bootstrap, error) {
    cfg := New()
    err := cfg.Parse()
    return cfg, err
}

func New() *Bootstrap {
    // 注册命令行参数
    pflag.StringVarP(&configVar, "config", "f", "", "config file path")
    _ = viper.BindPFlags(pflag.CommandLine)

    // 返回默认配置
    return &Bootstrap{
        Metrics: &Metrics{
            Enabled: true,
            Addr:    "0.0.0.0:9191",
            Path:    "/metrics",
        },
        Server: &Server{
            Http: &Server_Http{
                Addr:    ":8080",
                Enabled: true,
            },
            Grpc: &Server_Grpc{
                Addr:    ":50051",
                Enabled: true,
                Network: "tcp",
            },
        },
        // ... 其他默认配置
    }
}

func (cfg *Bootstrap) Parse() error {
    pflag.Parse()
    viper.AutomaticEnv()  // 支持环境变量

    // 配置文件路径
    if len(configVar) > 0 {
        viper.SetConfigFile(configVar)
    } else {
        viper.SetConfigName("config")
        viper.SetConfigType("yaml")
        viper.AddConfigPath("./configs")
        viper.AddConfigPath("/etc/myapp/")
        viper.AddConfigPath(".")
    }

    // 读取配置
    if err := viper.ReadInConfig(); err != nil {
        return errors.Errorf("read config failed: %v", err)
    }

    // 解析到结构体
    if err := viper.Unmarshal(cfg); err != nil {
        return errors.Errorf("unmarshal failed: %v", err)
    }

    // 热更新监听
    viper.WatchConfig()
    viper.OnConfigChange(func(e fsnotify.Event) {
        viper.Unmarshal(cfg)
    })

    return nil
}
```

## 配置文件组织

```
configs/
├── config.yaml         # 开发环境（默认）
├── config_prod.yaml    # 生产环境
└── zap.config.json     # 日志配置
```

**YAML 配置示例**：

```yaml
# configs/config.yaml
metrics:
  enabled: true
  addr: :9191

server:
  http:
    enabled: true
    addr: 0.0.0.0:8080
  grpc:
    enabled: true
    addr: 0.0.0.0:8081

redis:
  prefix: myapp
  addr: 192.168.1.12:6379
  poolSize: 10
  database: 0

mysql:
  addr: 192.168.1.10:3306
  database: myapp
  user: myapp
  password: ${MYSQL_PASSWORD}  # 环境变量注入
```

## 加载优先级

```
命令行参数 (-f config.yaml)
    ↓
环境变量 (VIPER_*, 自动映射)
    ↓
配置文件 (config.yaml)
    ↓
默认值 (New() 函数)
```

**优先级规则**：
- 命令行最高
- 环境变量覆盖配置文件
- 配置文件覆盖默认值

## 多环境配置

**方式一：多配置文件**

```bash
# 开发环境
./myapp -f configs/config.yaml

# 生产环境
./myapp -f configs/config_prod.yaml
```

**方式二：环境变量 + 基础配置**

```yaml
# config.yaml 基础配置
mysql:
  addr: ${MYSQL_ADDR}
  password: ${MYSQL_PASSWORD}
```

```bash
export MYSQL_ADDR="prod.db:3306"
export MYSQL_PASSWORD="prod_password"
./myapp
```

## 配置热更新

```go
viper.WatchConfig()
viper.OnConfigChange(func(e fsnotify.Event) {
    // 配置变化时重新解析
    if err := viper.Unmarshal(cfg); err != nil {
        log.Errorf("config reload failed: %v", err)
        return
    }
    log.Info("config reloaded")

    // 触发服务重配置（可选）
    // 如重新创建连接池、调整日志级别等
})
```

**适用场景**：
- 日志级别调整
- 连接池参数调整
- 功能开关切换

**不适用场景**：
- 服务地址变更（需要重启）
- TLS 配置变更（需要重启）

## 数据源配置

### MySQL

```go
func (x *MySQL_Config) GetDataSource() string {
    return fmt.Sprintf("%s:%s@tcp(%s)/%s?parseTime=true&loc=Local",
        x.User, x.Password, x.Addr, x.Database)
}
```

### Redis

```go
func (x *Redis_Config) ParseDialTimeout() time.Duration {
    return MustParseDuration(x.DialTimeout, 3*time.Second)
}
```

### 连接池

```go
type ConnPool struct {
    PoolSize        int32  `json:"poolSize"`
    MaxOpenConns    int32  `json:"maxOpenConns"`
    MinIdleConns    int32  `json:"minIdleConns"`
    ConnMaxLifetime string `json:"connMaxLifetime"`
    ConnMaxIdleTime string `json:"connMaxIdleTime"`
}

func MustParseDuration(d string, defaultValue time.Duration) time.Duration {
    duration, err := time.ParseDuration(d)
    if err != nil {
        return defaultValue
    }
    return duration
}
```

## 常见问题

### 如何注入敏感信息？

使用环境变量：

```yaml
mysql:
  password: ${MYSQL_PASSWORD}
```

```bash
export MYSQL_PASSWORD="secret"
./myapp
```

### 如何验证配置？

```go
func (cfg *Bootstrap) Validate() error {
    if cfg.Server.Http.Addr == "" {
        return errors.New("http addr required")
    }
    return nil
}
```

### 如何处理复杂配置？

使用 protobuf 定义嵌套结构：

```protobuf
message Bootstrap {
  repeated Platform platforms = 1;  // 列表配置
}
```

### 如何支持多租户？

配置文件命名区分：

```bash
./myapp -f configs/tenant_a.yaml
./myapp -f configs/tenant_b.yaml
```

## 最佳实践

1. **提供默认值** - New() 函数设置合理的默认配置
2. **类型安全** - 使用 protobuf 或结构体定义配置
3. **多环境分离** - configs/ 目录按环境存放
4. **敏感信息环境变量** - 密码、密钥使用 ${VAR} 注入
5. **热更新谨慎** - 只更新可动态调整的配置
6. **配置验证** - 启动时验证必填字段
7. **配置路径可配** - 支持 `-f` 指定配置文件