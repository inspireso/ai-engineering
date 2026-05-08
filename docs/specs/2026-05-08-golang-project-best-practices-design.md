# Golang 项目最佳实践 Skill 设计文档

## 概述

从企业级 Go 服务项目中提取的最佳实践，整理成模块化的 skill，帮助开发者学习 Go 项目结构组织的最佳实践。

## Skill 结构

```
skills/
├── golang-project-best-practices.md       # 主 skill（入口）
└── references/
    ├── golang-directory-structure.md      # 目录结构详解
    ├── golang-config-management.md        # 配置管理详解
    ├── golang-service-architecture.md     # 服务架构详解
    └── golang-api-design.md               # API 设计详解
```

## 主 Skill 功能

- 简要介绍最佳实践要点
- 根据用户任务引用对应参考文档
- 提供快速检查清单

## 参考文档功能

- 详细代码示例
- 完整实现说明
- 设计决策解释

---

## 模块一：目录结构

### 核心目录

| 目录 | 用途 | 可被外部引用 |
|------|------|-------------|
| `cmd/` | 应用入口点 | 否 |
| `internal/` | 内部业务逻辑 | 否 |
| `pkg/` | 公共工具库 | 是 |
| `api/` | API 协议定义 | 是 |
| `configs/` | 配置文件 | 否 |
| `deployments/` | 部署配置 | 否 |
| `third_party/` | 外部依赖 | 否 |
| `docs/` | 项目文档 | 否 |

### 子目录细分

```
cmd/
├── main.go           # 程序入口
└── commands/         # Cobra 子命令定义

internal/
├── conf/             # 配置解析
├── httpserver/       # HTTP 服务
├── grpcserver/       # gRPC 服务
├── platform/         # 业务服务实现
├── pkg/              # 内部依赖包
│   ├── mysql/
│   ├── redis/
│   └── clickhouse/
└── migration/        # 数据库迁移

pkg/
├── middleware/       # HTTP 中间件
├── util/             # 工具函数
└── openapi/          # 第三方 API 封装

api/
└── v1/               # API 版本化
    ├── *.proto       # protobuf 定义
    ├── *.pb.go       # 生成的代码
    └── types.go      # 类型扩展

configs/
├── config.yaml       # 开发环境配置
├── config_prod.yaml  # 生产环境配置
└── zap.config.json   # 日志配置

deployments/
├── docker-compose-test.yaml
├── docker-compose-prod.yaml
└── docker-compose-*.yaml

third_party/
└── google/           # protobuf 依赖

docs/
├── README.md
├── architecture.png
└── assets/
```

### 目录职责说明

1. **cmd/** - 程序入口，保持简洁，只做初始化和调用
2. **internal/** - 核心业务逻辑，不可被其他项目引用
3. **pkg/** - 可复用的公共代码，可被外部引用
4. **api/** - API 定义独立，便于版本管理和跨语言使用
5. **configs/** - 配置文件按环境分离
6. **deployments/** - 部署文件集中管理
7. **third_party/** - 外部依赖集中存放
8. **docs/** - 文档集中存放

---

## 模块二：配置管理

### 配置方案对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| Viper + YAML | 灵活、支持热更新、多格式 | 无类型约束 |
| Viper + Protobuf | 类型安全、可生成代码 | 需额外 proto 文件 |
| 环境变量 + 结构体 | 简单直接 | 不支持复杂配置 |

**推荐方案：Viper + Protobuf**

### 核心实现要点

1. **配置结构定义**：使用 protobuf 定义配置类型
2. **默认值设置**：`New()` 函数提供默认配置
3. **多环境支持**：`configs/` 目录区分环境
4. **热更新**：`viper.WatchConfig()` 监听配置变化
5. **命令行参数**：`pflag` 支持 `-f config.yaml` 指定配置文件

### 配置加载流程

```
命令行参数 → 环境变量 → 配置文件 → 默认值
```

### 配置文件路径优先级

1. `-f` 指定的路径
2. `./config/`
3. `/etc/<app-name>/`
4. 当前目录

### 配置代码结构

```go
// internal/conf/conf.go

func Parse() (*Bootstrap, error) {
    cfg := New()              // 默认配置
    err := cfg.Parse()        // 加载配置文件
    return cfg, err
}

func New() *Bootstrap {
    pflag.StringVarP(&configVar, "config", "f", "", "config file path")
    return &Bootstrap{
        Metrics: &Metrics{...},
        Server: &Server{...},
        Redis: &Redis_Config{...},
        MySQL: &MySQL_Config{...},
    }
}

func (cfg *Bootstrap) Parse() error {
    pflag.Parse()
    viper.AutomaticEnv()      // 支持环境变量

    if len(configVar) > 0 {
        viper.SetConfigFile(configVar)
    } else {
        viper.SetConfigName("config")
        viper.AddConfigPath("./config")
        viper.AddConfigPath("/etc/<app>/")
        viper.AddConfigPath(".")
    }

    viper.ReadInConfig()
    viper.Unmarshal(cfg)
    viper.WatchConfig()       // 热更新
    return nil
}
```

---

## 模块三：服务架构

### 核心架构模式

| 模式 | 说明 |
|------|------|
| 命令行框架 | Cobra 子命令模式 |
| 服务生命周期 | errgroup 管理多服务并发启动/停止 |
| Context 传递 | 服务依赖通过 context 传递 |
| 优雅关闭 | signal.Notify + context.Cancel |

### 入口点结构

```
main.go
  ↓
RootCmd (Cobra)
  ↓
run(ctx, cfg)
  ↓
初始化依赖（MySQL、Redis等）
  ↓
创建服务（HTTP、gRPC、Metrics）
  ↓
runInternal(ctx, servers...)
  ↓
errgroup 管理启动/停止
```

### 服务生命周期接口

```go
type ServeLifecycle interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}
```

### 并发启动模式

```go
func runInternal(ctx context.Context, servers ...ServeLifecycle) error {
    ctx, cancel := context.WithCancel(ctx)
    eg, ctx := errgroup.WithContext(ctx)
    wg := sync.WaitGroup{}

    // 启动所有服务
    for _, srv := range servers {
        srv := srv
        wg.Add(1)
        eg.Go(func() error {
            wg.Done()
            return srv.Start(ctx)
        })
    }
    wg.Wait()

    // 停止所有服务
    for _, srv := range servers {
        srv := srv
        eg.Go(func() error {
            <-ctx.Done()
            return srv.Stop(ctx)
        })
    }

    // 信号监听
    c := make(chan os.Signal, 1)
    signal.Notify(c, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGINT)
    eg.Go(func() error {
        select {
        case <-ctx.Done():
            return context.Cause(ctx)
        case <-c:
            cancel()
            return nil
        }
    })

    return eg.Wait()
}
```

### 依赖注入模式

```go
// 通过 context 传递依赖
func NewContext(ctx context.Context, db *sql.DB) context.Context {
    return context.WithValue(ctx, contextKey{}, db)
}

func FromContext(ctx context.Context) *sql.DB {
    return ctx.Value(contextKey{}).(*sql.DB)
}

// 使用示例
ctx = mysql.NewContext(ctx, ms)
ctx = redis.NewContext(ctx, rds)
ctx = platform.NewContext(ctx, pfs)
```

---

## 模块四：API 设计

### 双协议支持

| 协议 | 用途 | 特点 |
|------|------|------|
| gRPC | 服务间通信、高性能 | protobuf、stream 支持 |
| HTTP | 前端/管理端访问 | JSON、WebSocket、易调试 |

### API 定义结构

```
api/
└── v1/
    ├── platform.proto      # 服务定义
    ├── platform.pb.go      # 生成的 Go 代码
    ├── platform_grpc.pb.go # 生成的 gRPC 代码
    ├── types.go            # 手写的类型扩展
    └── errors.go           # 统一的错误定义
```

### protobuf 设计要点

1. **版本化路径**：`api/v1/`、`api/v2/` 便于演进
2. **go_package 设置**：`option go_package = ".;v1";`
3. **命名规范**：服务名、方法名、消息名遵循 proto 规范
4. **Any 类型**：用于灵活的参数传递

### HTTP 路由设计

```go
func NewRouter(ctx context.Context, cfg *conf.Bootstrap) (http.Handler, error) {
    r := gin.New()

    // 注册中间件
    for name, mw := range middleware.Middlewares {
        r.Use(mw)
    }

    // 基础路由
    r.GET("/", ok)
    r.GET("/info", info)
    r.GET("/ws", ws)

    // API 分组
    apiv1 := r.Group("/api/v1")
    {
        stat := apiv1.Group("/stat")
        api.InitStatRouter(ctx, stat)

        investor := apiv1.Group("/investor")
        api.InitInvestorRouter(ctx, investor)
    }

    return r, nil
}
```

### 中间件注册表

```go
var Middlewares = map[string]gin.HandlerFunc{
    "recovery":  gin.Recovery(),
    "metric":    Metric(),
    "secure":    Secure,
    "cors":      Cors(),
    "requestid": RequestID(),
    "logger":    Logger(),
}
```

### 错误处理

```go
type Error struct {
    Message string        `json:"message"`
    Args    []interface{} `json:"args"`
    Cause   error         `json:"-"`
}

// gRPC 错误映射
func InternalError(msg string) error {
    return status.Error(codes.Internal, msg)
}

func InvalidArgumentError(msg string) error {
    return status.Error(codes.InvalidArgument, msg)
}
```

---

## 检查清单

### 目录结构检查

- [ ] `cmd/` 目录只包含入口代码
- [ ] `internal/` 包含所有业务逻辑
- [ ] `pkg/` 只包含可复用的公共代码
- [ ] `api/` 使用版本化目录
- [ ] `configs/` 按环境分离配置文件
- [ ] `deployments/` 包含部署配置
- [ ] `docs/` 包含项目文档

### 配置管理检查

- [ ] 使用结构化配置（protobuf 或 struct）
- [ ] 提供默认配置值
- [ ] 支持多环境配置
- [ ] 支持热更新（可选）
- [ ] 配置路径可自定义

### 服务架构检查

- [ ] 使用 Cobra 命令行框架
- [ ] 实现 ServeLifecycle 接口
- [ ] 使用 errgroup 管理并发
- [ ] 支持优雅关闭
- [ ] Context 传递依赖

### API 设计检查

- [ ] gRPC + HTTP 双协议支持
- [ ] API 版本化
- [ ] protobuf 定义规范
- [ ] HTTP 路由分组
- [ ] 中间件统一注册
- [ ] 统一错误处理

---

## 触发条件

用户询问以下内容时触发此 skill：

- 如何组织 Go 项目结构
- Go 项目目录最佳实践
- 企业级 Go 服务架构
- Go 项目配置管理
- Go API 设计最佳实践
- 创建/初始化 Go 项目

---

## 实现计划

1. 创建主 skill 文件 `golang-project-best-practices.md`
2. 创建 references 目录
3. 编写四个参考文档：
   - `golang-directory-structure.md`
   - `golang-config-management.md`
   - `golang-service-architecture.md`
   - `golang-api-design.md`
4. 添加代码示例到各文档
5. 添加检查清单到主 skill