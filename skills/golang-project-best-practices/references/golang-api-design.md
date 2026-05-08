# API 设计详解

## 双协议支持

| 协议 | 用途 | 特点 |
|------|------|------|
| gRPC | 服务间通信、高性能 | protobuf、stream 支持 |
| HTTP | 前端/管理端访问 | JSON、WebSocket、易调试 |

**推荐：同时支持两种协议**

## API 定义结构

```
api/
└── v1/                 # API 版本
    ├── platform.proto  # 服务定义
    ├── platform.pb.go  # 生成的 Go 代码
    ├── platform_grpc.pb.go  # gRPC 服务代码
    ├── types.go        # 类型扩展
    └── errors.go       # 错误定义
```

**原则**：
- 版本化目录（v1、v2）
- protobuf 定义服务
- 手写扩展与生成代码分离

## Protobuf 定义

### 服务定义

```protobuf
// api/v1/platform.proto
syntax = "proto3";
package myapp.api.v1;

import "google/protobuf/any.proto";

option go_package = ".;v1";

// 交易服务
service ExchangeService {
  // 获取行情
  rpc GetTicker(GetTickerRequest) returns (GetTickerReply);
  // 获取 K 线
  rpc GetKline(GetKlineRequest) returns (GetKlineReply);
  // 下单
  rpc Buy(BuyRequest) returns (BuyReply);
  // 撤单
  rpc Cancel(CancelRequest) returns (CancelReply);
  // 获取持仓
  rpc GetPosition(GetPositionRequest) returns (GetPositionReply);
}

// 数据流服务
service StreamService {
  // 订阅数据流
  rpc Subscribe(stream SubscribeRequest) returns (stream SubscribeReply);
}
```

### 消息定义

```protobuf
// 行情数据
message Ticker {
  int64 timestamp = 1;
  string platform = 2;
  string instrument = 3;
  string last = 4;
  string volume = 5;
}

// 请求消息
message GetTickerRequest {
  string platform = 1;
  string instrument = 2;
}

// 响应消息
message GetTickerReply {
  Ticker ticker = 1;
}

// 流式消息（使用 Any 类型）
message SubscribeRequest {
  int64 id = 1;
  string method = 2;
  google.protobuf.Any params = 3;
}

message SubscribeReply {
  int64 id = 1;
  google.protobuf.Any result = 2;
}
```

### go_package 设置

```protobuf
option go_package = ".;v1";
```

**生成结果**：
- `platform.pb.go` - 消息类型
- `platform_grpc.pb.go` - gRPC 服务
- 都在 `api/v1/` 目录

## 代码生成

### Makefile 配置

```makefile
.PHONY: generate
generate:
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
    protoc --proto_path=. \
           --proto_path=./third_party \
           --go_out=. \
           --go-grpc_out=./api/v1/ \
           ./api/v1/platform.proto
```

### 生成命令

```bash
make generate
```

## HTTP 路由设计

### 路由结构

```go
// internal/httpserver/router.go
package httpserver

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

    // API 分组（版本化）
    apiv1 := r.Group("/api/v1")
    {
        stat := apiv1.Group("/stat")
        api.InitStatRouter(ctx, stat)

        investor := apiv1.Group("/investor")
        api.InitInvestorRouter(ctx, investor)

        strategy := apiv1.Group("/strategy")
        api.InitStrategyRouter(ctx, strategy)
    }

    return r, nil
}
```

### 路由初始化

```go
// internal/httpserver/api/stat.go
package api

func InitStatRouter(ctx context.Context, g *gin.RouterGroup) {
    g.GET("/daily", getDailyStat)
    g.GET("/realtime", getRealtimeStat)
}

func getDailyStat(c *gin.Context) {
    // 从 context 获取服务
    pf := platform.FromContext(c.Request.Context())
    // 调用服务
    result, _ := pf.GetDailyStat(...)
    c.JSON(200, result)
}
```

## 中间件注册表

```go
// pkg/middleware/middleware.go
package middleware

import "github.com/gin-gonic/gin"

var Middlewares = map[string]gin.HandlerFunc{
    "recovery":  gin.Recovery(),
    "metric":    Metric(),
    "secure":    Secure,
    "cors":      Cors(),
    "requestid": RequestID(),
    "logger":    Logger(),
}

func Secure(c *gin.Context) {
    c.Header("X-Frame-Options", "DENY")
    c.Header("X-Content-Type-Options", "nosniff")
    c.Next()
}

func Cors() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Header("Access-Control-Allow-Origin", "*")
        c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE")
        c.Next()
    }
}
```

**优点**：
- 统一注册管理
- 可配置启用/禁用
- 便于添加新中间件

## 错误处理

### 错误类型

```go
// api/v1/errors.go
package v1

type Error struct {
    Message string        `json:"message"`
    Args    []interface{} `json:"args"`
    Cause   error         `json:"-"`
}

func New(message string, args ...interface{}) *Error {
    return &Error{Message: message, Args: args}
}

func (e *Error) WithCause(cause error) *Error {
    err := Clone(e)
    err.Cause = cause
    return err
}
```

### gRPC 错误映射

```go
// api/v1/errors.go

import "google.golang.org/grpc/status"
import "google.golang.org/grpc/codes"

func InternalError(msg string) error {
    return status.Error(codes.Internal, msg)
}

func InvalidArgumentError(msg string) error {
    return status.Error(codes.InvalidArgument, msg)
}

func NotFoundError(msg string) error {
    return status.Error(codes.NotFound, msg)
}
```

### HTTP 错误响应

```go
func handleError(c *gin.Context, err error) {
    if se := new(v1.Error); errors.As(err, &se) {
        c.JSON(400, gin.H{
            "code":    se.Message,
            "message": fmt.Sprintf(se.Message, se.Args...),
        })
        return
    }

    c.JSON(500, gin.H{
        "code":    "internal_error",
        "message": err.Error(),
    })
}
```

## 类型扩展

```go
// api/v1/types.go
package v1

import "time"

// 扩展 protobuf 生成的类型
func (t *Ticker) ParseTimestamp() time.Time {
    return time.UnixMilli(t.Timestamp)
}

func (t *Ticker) FormatInstrument() string {
    return FormatPlatform(t.Platform) + ":" + t.Instrument
}
```

**原则**：
- protobuf 定义基础结构
- types.go 添加辅助方法
- 不修改生成的代码

## gRPC 服务实现

```go
// internal/platform/server.go
package platform

type platformServer struct {
    pb.UnimplementedExchangeServiceServer
    exchanges map[string]types.Exchange
}

func (s *platformServer) GetTicker(ctx context.Context, req *pb.GetTickerRequest) (*pb.GetTickerReply, error) {
    ex, ok := s.exchanges[req.Platform]
    if !ok {
        return nil, pb.InvalidArgumentError("platform not found: " + req.Platform)
    }

    ticker, err := ex.GetTicker(ctx, req.Instrument)
    if err != nil {
        return nil, pb.InternalErrorWrap(err)
    }

    return &pb.GetTickerReply{Ticker: ticker}, nil
}
```

## WebSocket 支持

```go
// internal/httpserver/router.go

var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
}

func ws(c *gin.Context) {
    conn, _ := upgrader.Upgrade(c.Writer, c.Request, nil)
    defer conn.Close()

    for {
        mt, message, err := conn.ReadMessage()
        if err != nil {
            break
        }
        conn.WriteMessage(mt, message)
    }
}
```

## Swagger/OpenAPI 生成

```makefile
.PHONY: swagger
swagger:
    go install github.com/google/gnostic/cmd/protoc-gen-openapi@latest
    protoc --proto_path=. \
           --proto_path=./third_party \
           --openapi_out=naming=proto,fq_schema_naming=true:./api/ \
           ./api/v1/platform.proto
```

生成 `api/v1/openapi.yaml`，用于 API 文档。

## 常见问题

### 如何处理版本演进？

- v1 保持稳定
- 新功能在 v2
- 旧版本标记 deprecated

```protobuf
service ExchangeService {
  rpc GetTicker(GetTickerRequest) returns (GetTickerReply) [deprecated = true];
}
```

### 如何处理大消息？

- 使用 stream（流式）
- 分页返回
- 压缩传输

### 如何处理认证？

```go
// 中间件认证
auth := r.Group("/api/v1")
auth.Use(authMiddleware)
{
    auth.GET("/private", privateHandler)
}

// 无认证
public := r.Group("/api/v1")
{
    public.GET("/public", publicHandler)
}
```

### 如何测试 API？

```go
func TestGetTicker(t *testing.T) {
    req := &pb.GetTickerRequest{
        Platform:   "ctp.future",
        Instrument: "au2408",
    }
    reply, err := client.GetTicker(ctx, req)
    assert.NoError(t, err)
    assert.NotNil(t, reply.Ticker)
}
```

## 最佳实践

1. **版本化 API** - v1、v2 目录分离
2. **双协议支持** - gRPC + HTTP
3. **中间件注册表** - 统一管理
4. **统一错误处理** - Error 类型 + gRPC status
5. **类型扩展分离** - types.go 不修改生成代码
6. **Swagger 文档** - protoc-gen-openapi 生成
7. **认证分组** - 路由分组 + 中间件