# 目录结构详解

## 核心目录

企业级 Go 服务项目的标准目录结构：

```
项目根目录/
├── cmd/                # 入口点
├── internal/           # 内部业务逻辑
├── pkg/                # 公共工具库
├── api/                # API 协议定义
├── configs/            # 配置文件
├── deployments/        # 部署配置
├── third_party/        # 外部依赖
├── docs/               # 项目文档
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
├── README.md
└── LICENSE
```

## cmd 目录

**职责**：程序入口，保持简洁

```
cmd/
├── main.go             # 程序入口
└── commands/           # Cobra 子命令
    ├── root.go         # 根命令
    ├── version.go      # 版本命令
    └── keygen.go       # 其他子命令
```

**原则**：
- 只做初始化和调用
- 不包含业务逻辑
- 业务逻辑委托给 internal

**示例**：

```go
// cmd/main.go
package main

import (
    "github.com/myproject/cmd/commands"
)

func main() {
    rootCmd := commands.RootCmd()
    rootCmd.AddCommand(commands.VersionCmd())
    rootCmd.Execute()
}
```

```go
// cmd/commands/root.go
package commands

import (
    "github.com/spf13/cobra"
    "github.com/myproject/internal/conf"
)

func RootCmd() *cobra.Command {
    cfg, _ := conf.Parse()

    return &cobra.Command{
        Use:   "myapp --config=config.yaml",
        Short: "myapp",
        Run: func(cmd *cobra.Command, args []string) {
            run(cmd.Context(), cfg)
        },
    }
}
```

## internal 目录

**职责**：内部业务逻辑，不可被外部项目引用

```
internal/
├── conf/               # 配置解析
│   ├── conf.go         # 配置加载
│   └── conf.pb.go      # protobuf 生成的配置结构
├── httpserver/         # HTTP 服务
│   ├── server.go       # 服务定义
│   └── router.go       # 路由注册
├── grpcserver/         # gRPC 服务
│   ├── server.go       # 服务定义
├── platform/           # 业务服务实现
│   ├── server.go       # 服务入口
│   └── types/          # 类型定义
├── pkg/                # 内部依赖包
│   ├── mysql/          # MySQL 封装
│   ├── redis/          # Redis 封装
│   ├── clickhouse/     # ClickHouse 封装
│   └── rabbitmq/       # RabbitMQ 封装
├── migration/          # 数据库迁移
│   └── migrate.go      # 迁移入口
│   ├── mysql/*.sql     # MySQL 迁移脚本
│   └── clickhouse/*.sql # ClickHouse 迁移脚本
└── metrics/            # Prometheus 指标
    └── server.go       # 指标服务
```

**原则**：
- 业务逻辑都在此目录
- 子包之间可以互相引用
- 外部项目无法导入（Go 编译器强制）

## pkg 目录

**职责**：可复用的公共工具库，可被外部引用

```
pkg/
├── middleware/         # HTTP 中间件
│   ├── middleware.go   # 注册表
│   ├── cors.go         # CORS 中间件
│   ├── logger.go       # 日志中间件
│   └── metrics.go      # 指标中间件
├── util/               # 工具函数
│   ├── id.go           # ID 生成
│   ├── error.go        # 错误处理
│   ├── rsa.go          # RSA 加密
│   └── number.go       # 数值处理
├── metrics/            # 指标定义
│   └── metrics.go      # Prometheus 指标
└── openapi/            # 第三方 API 封装
    └── exchange/       # 交易所 API
```

**原则**：
- 可被外部项目引用
- 与具体业务无关
- 独立可测试

## api 目录

**职责**：API 协议定义，版本化管理

```
api/
└── v1/                 # API v1 版本
    ├── platform.proto  # 服务定义
    ├── platform.pb.go  # 生成的 Go 代码
    ├── platform_grpc.pb.go  # gRPC 服务代码
    ├── types.go        # 类型扩展
    └── errors.go       # 错误定义
```

**原则**：
- 使用版本化目录（v1、v2）
- protobuf 定义服务
- 生成的代码与手写代码分离
- 跨语言共享定义

## configs 目录

**职责**：配置文件，按环境分离

```
configs/
├── config.yaml         # 开发环境配置
├── config_prod.yaml    # 生产环境配置
└── zap.config.json     # 日志配置
```

**原则**：
- 开发配置在根目录或 configs/
- 生产配置单独文件
- 不包含敏感信息（使用环境变量）

## deployments 目录

**职责**：部署配置文件

```
deployments/
├── docker-compose-test.yaml    # 测试环境
├── docker-compose-prod.yaml    # 生产环境
└── k8s/                        # Kubernetes 配置
    ├── deployment.yaml
    └── service.yaml
```

**原则**：
- Docker Compose 按环境分离
- Kubernetes 配置单独目录
- CI/CD 配置可放根目录（如 .gitlab-ci.yml）

## third_party 目录

**职责**：第三方依赖（如 protobuf）

```
third_party/
└── google/
    └── protobuf/       # Google protobuf 定义
```

**原则**：
- proto 文件的外部依赖
- 不包含 Go 代码
- 编译时引用路径

## docs 目录

**职责**：项目文档

```
docs/
├── README.md           # 详细说明
├── architecture.png    # 架构图
├── assets/             # 文档资源
├── git_flow.md         # Git 规范
└── commit_message.md   # 提交规范
```

**原则**：
- 根 README.md 是入口
- 详细文档在 docs/
- 包含架构图、API 文档

## 其他根目录文件

| 文件 | 用途 |
|------|------|
| `go.mod` | Go 模块定义 |
| `go.sum` | 依赖校验 |
| `Makefile` | 构建脚本 |
| `Dockerfile` | 容器构建 |
| `.gitlab-ci.yml` | CI/CD 配置 |
| `README.md` | 项目入口文档 |
| `LICENSE` | 许可证 |

## 目录命名规范

- 使用小写字母
- 多单词用下划线或直接拼接（不强制）
- 目录名体现职责（如 httpserver、grpcserver）

## 常见问题

### 什么时候用 internal vs pkg？

| 场景 | 目录 |
|------|------|
| 业务逻辑 | internal |
| 数据库访问封装 | internal/pkg |
| HTTP/gRPC 服务 | internal |
| 通用中间件 | pkg |
| 工具函数（可复用） | pkg |
| 第三方 API 封装（可复用） | pkg |

### 迁移脚本放哪里？

- 使用 `internal/migration/` + `embed.FS`
- SQL 文件与代码在同一目录
- 编译时嵌入二进制

### 配置文件放哪里？

- 开发：根目录 `config.yaml` 或 `configs/config.yaml`
- 生产：`configs/config_prod.yaml`
- 通过 `-f` 参数指定路径

### proto 文件生成的代码放哪里？

- 放在 `api/v1/` 同目录
- 使用 `option go_package = ".;v1";`
- 手写扩展文件（types.go、errors.go）也在同目录