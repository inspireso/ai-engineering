# 服务架构详解

## 核心架构模式

| 模式 | 说明 |
|------|------|
| 命令行框架 | Cobra 子命令模式 |
| 服务生命周期 | errgroup 管理多服务并发启动/停止 |
| Context 传递 | 服务依赖通过 context 传递 |
| 优雅关闭 | signal.Notify + context.Cancel |

## 入口点结构

```
main.go
    ↓ 调用
RootCmd (Cobra)
    ↓ 解析配置
run(ctx, cfg)
    ↓ 初始化依赖
初始化 MySQL、Redis、ClickHouse
    ↓ 执行迁移
migration.Migrate(ctx)
    ↓ 创建服务
创建 HTTP、gRPC、Metrics、Platform 服务
    ↓ 并发管理
runInternal(ctx, servers...)
    ↓ errgroup
并发启动 + 优雅关闭
```

## 程序入口

```go
// cmd/main.go
package main

import (
    "github.com/myproject/cmd/commands"
    "os"
)

func main() {
    defer log.Flush()

    rootCmd := commands.RootCmd()
    rootCmd.AddCommand(commands.VersionCmd())

    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

**原则**：
- 保持简洁
- 只做入口调用
- 子命令在 commands/ 目录

## 命令定义

```go
// cmd/commands/root.go
package commands

import (
    "context"
    "github.com/spf13/cobra"
    "github.com/myproject/internal/conf"
)

func RootCmd() *cobra.Command {
    cfg, err := conf.Parse()
    if err != nil {
        log.Fatalf("config error: %v", err)
    }

    return &cobra.Command{
        Use:   "myapp --config=config.yaml",
        Short: "myapp description",
        Run: func(cmd *cobra.Command, args []string) {
            run(cmd.Context(), cfg)
        },
    }
}

func VersionCmd() *cobra.Command {
    return &cobra.Command{
        Use:   "version",
        Short: "print version",
        Run: func(cmd *cobra.Command, args []string) {
            fmt.Println(version.Print("myapp"))
        },
    }
}
```

## 服务运行函数

```go
// cmd/commands/root.go
func run(ctx context.Context, cfg *conf.Bootstrap) {
    fmt.Println(version.Print("myapp"))

    // 初始化 MySQL
    ms, err := mysql.New(cfg.Mysql)
    if err != nil {
        log.Fatalf("mysql error: %v", err)
    }
    defer ms.Close()
    ctx = mysql.NewContext(ctx, ms)

    // 初始化 Redis
    rds := redis.New(cfg.Redis)
    defer rds.Close()
    ctx = redis.NewContext(ctx, rds)

    // 执行数据库迁移
    if err := migration.Migrate(ctx); err != nil {
        log.Fatalf("migration error: %v", err)
    }

    // 收集所有服务
    var servers []conf.ServeLifecycle

    // 创建 Platform 服务
    pfs := platform.New(ctx, cfg)
    servers = append(servers, pfs)
    ctx = platform.NewContext(ctx, pfs)

    // 创建 Metrics 服务
    if cfg.Metrics.Enabled {
        m := metrics.New(cfg.Metrics)
        servers = append(servers, m)
    }

    // 创建 HTTP 服务
    if cfg.Server.Http.Enabled {
        srv, _ := httpserver.New(ctx, cfg)
        servers = append(servers, srv)
    }

    // 创建 gRPC 服务
    if cfg.Server.Grpc.Enabled {
        srv, _ := grpcserver.New(ctx, cfg)
        servers = append(servers, srv)
    }

    // 运行所有服务
    if err := runInternal(ctx, servers...); err != nil {
        fmt.Printf("%+v", err)
    }
}
```

## 服务生命周期接口

```go
// internal/conf/conf.go

type ServeLifecycle interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}
```

**所有服务实现此接口**：
- HTTP Server
- gRPC Server
- Metrics Server
- Platform Service
- Redis Register

## 并发启动与停止

```go
// cmd/commands/root.go
func runInternal(ctx context.Context, servers ...conf.ServeLifecycle) error {
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
    wg.Wait()  // 等待所有服务启动完成

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
        for {
            select {
            case <-ctx.Done():
                return context.Cause(ctx)
            case <-c:
                cancel()
                return nil
            }
        }
    })

    fmt.Println("running...")

    if err := eg.Wait(); err != nil && !errors.Is(err, context.Canceled) {
        return err
    }
    fmt.Println("exit!!!")
    return nil
}
```

**关键点**：
1. `errgroup.WithContext` - 任一服务失败则全部停止
2. `sync.WaitGroup` - 确保所有服务启动后再接受信号
3. `signal.Notify` - 监听 SIGTERM、SIGQUIT、SIGINT
4. 优雅关闭 - 先停止服务，再退出

## Context 依赖注入

```go
// internal/pkg/mysql/mysql.go
package mysql

type contextKey struct{}

func NewContext(ctx context.Context, db *sql.DB) context.Context {
    return context.WithValue(ctx, contextKey{}, db)
}

func FromContext(ctx context.Context) *sql.DB {
    return ctx.Value(contextKey{}).(*sql.DB)
}
```

**使用示例**：

```go
// 在 run() 中注入
ctx = mysql.NewContext(ctx, ms)
ctx = redis.NewContext(ctx, rds)
ctx = platform.NewContext(ctx, pfs)

// 在服务中使用
func (s *Server) GetOrder(ctx context.Context, req *Request) (*Reply, error) {
    db := mysql.FromContext(ctx)
    return db.Query(...)
}
```

**优点**：
- 避免全局变量
- 依赖显式传递
- 测试时可替换

## 服务实现示例

### HTTP 服务

```go
// internal/httpserver/server.go
package httpserver

type Server struct {
    *gin.Engine
    addr string
}

func New(ctx context.Context, cfg *conf.Bootstrap) (*Server, error) {
    router, _ := NewRouter(ctx, cfg)
    return &Server{
        Engine: router.(*gin.Engine),
        addr:   cfg.Server.Http.Addr,
    }, nil
}

func (s *Server) Start(ctx context.Context) error {
    log.Infof("[http] server starting on %s", s.addr)
    return s.Run(s.addr)
}

func (s *Server) Stop(ctx context.Context) error {
    log.Info("[http] server stopping")
    return s.Shutdown(ctx)
}
```

### gRPC 服务

```go
// internal/grpcserver/server.go
package grpcserver

type Server struct {
    *grpc.Server
    addr string
}

func New(ctx context.Context, cfg *conf.Bootstrap) (*Server, error) {
    srv := grpc.NewServer()
    pb.RegisterExchangeServiceServer(srv, platform.FromContext(ctx))
    return &Server{Server: srv, addr: cfg.Server.Grpc.Addr}, nil
}

func (s *Server) Start(ctx context.Context) error {
    log.Infof("[grpc] server starting on %s", s.addr)
    lis, _ := net.Listen("tcp", s.addr)
    return s.Server.Serve(lis)
}

func (s *Server) Stop(ctx context.Context) error {
    log.Info("[grpc] server stopping")
    s.GracefulStop()
    return nil
}
```

### Platform 服务

```go
// internal/platform/server.go
package platform

type platformServer struct {
    exchanges map[string]types.Exchange
}

func New(ctx context.Context, cfg *conf.Bootstrap) types.Platform {
    exchanges := make(map[string]types.Exchange)
    for _, p := range cfg.Platforms {
        ex := ctp.NewExchangeService(ctx, p)
        exchanges[p.Name] = ex
    }
    return &platformServer{exchanges: exchanges}
}

func (s *platformServer) Start(ctx context.Context) error {
    eg, ctx := errgroup.WithContext(ctx)
    for name, ex := range s.exchanges {
        name, ex := name, ex
        eg.Go(func() error {
            log.Infof("[platform] starting %s", name)
            return ex.Start(ctx)
        })
    }
    return eg.Wait()
}

func (s *platformServer) Stop(ctx context.Context) error {
    eg, ctx := errgroup.WithContext(ctx)
    for name, ex := range s.exchanges {
        name, ex := name, ex
        eg.Go(func() error {
            log.Infof("[platform] stopping %s", name)
            return ex.Stop(ctx)
        })
    }
    return eg.Wait()
}
```

## 数据库迁移

```go
// internal/migration/migrate.go
package migration

import (
    "embed"
    "github.com/myproject/internal/pkg/mysql"
)

//go:embed mysql/*.sql
var mysqlFS embed.FS

func Migrate(ctx context.Context) error {
    db := mysql.FromContext(ctx)
    return db.Migrate(mysqlFS)
}
```

**原则**：
- 使用 `embed.FS` 嵌入 SQL 文件
- 启动时自动执行迁移
- 支持多数据库类型

## 常见问题

### 服务启动顺序？

- 先初始化依赖（数据库、Redis）
- 后创建服务（HTTP、gRPC）
- 并发启动所有服务

### 如何处理启动失败？

- `errgroup` 自动停止其他服务
- 返回错误，程序退出
- 日志记录失败原因

### 如何添加新服务？

1. 实现 `ServeLifecycle` 接口
2. 在 `run()` 中创建实例
3. 添加到 `servers` 列表

### 如何测试服务启动？

```go
func TestServerStart(t *testing.T) {
    ctx := context.Background()
    cfg := conf.New()

    srv, _ := httpserver.New(ctx, cfg)
    ctx, cancel := context.WithCancel(ctx)

    go srv.Start(ctx)
    time.Sleep(100 * time.Millisecond)
    cancel()
    srv.Stop(ctx)
}
```

## 最佳实践

1. **统一生命周期接口** - 所有服务实现 ServeLifecycle
2. **并发启动** - errgroup 管理多个服务
3. **优雅关闭** - signal.Notify + Shutdown
4. **Context 传依赖** - 避免全局变量
5. **启动时迁移** - embed.FS 嵌入 SQL
6. **失败即退出** - 任一服务失败则全部停止