---
name: golang-project-best-practices
description: Use when organizing Go project structure, creating enterprise-level Go services, or asking about Go directory conventions and architecture patterns. Triggers for questions about cmd/internal/pkg/api directory layout, configuration management, service lifecycle, HTTP/gRPC API design, Makefile/Dockerfile configuration, or CI/CD setup.
---

# Golang 项目最佳实践

## 概述

企业级 Go 服务项目的结构组织最佳实践，涵盖目录规划、配置管理、服务架构、API 设计四个核心模块。

## 核心原则

1. **cmd 只放入口** - 保持简洁，不做业务逻辑
2. **internal 是私有边界** - 不可被外部项目引用
3. **pkg 是公共资产** - 可复用的工具库
4. **api 要版本化** - v1、v2 分离，便于演进

## 快速参考

### 目录结构

| 目录 | 用途 | 外部可引用 |
|------|------|-----------|
| `cmd/` | 入口点 + 子命令 | 否 |
| `internal/` | 业务逻辑、数据库、服务 | 否 |
| `pkg/` | 公共工具、中间件 | 是 |
| `api/v1/` | protobuf 定义 | 是 |
| `configs/` | 环境配置文件 | 否 |
| `deployments/` | Docker/K8s 配置 | 否 |
| `third_party/` | proto 外部依赖 | 否 |
| `docs/` | 项目文档 | 否 |

### internal 子目录

```
internal/
├── conf/          # 配置解析
├── httpserver/    # HTTP 服务
├── grpcserver/    # gRPC 服务
├── platform/      # 业务服务实现
├── pkg/           # 内部依赖（mysql/redis/clickhouse）
└── migration/     # 数据库迁移（embed.FS）
```

### 配置管理

| 方案 | 特点 |
|------|------|
| Viper + YAML | 灵活、热更新 |
| Viper + Protobuf | 类型安全、可生成 |
| 环境变量 | 简单直接 |

加载顺序：命令行参数 → 环境变量 → 配置文件 → 默认值

### 服务生命周期

```go
type ServeLifecycle interface {
    Start(ctx context.Context) error
    Stop(ctx context.Context) error
}
```

并发管理：`errgroup.WithContext(ctx)` + `signal.Notify`

### API 设计

- gRPC：服务间通信、stream 支持
- HTTP：前端访问、JSON/WebSocket
- 版本化：`api/v1/`、`api/v2/`
- 中间件：注册表模式统一管理

## 模块详解

根据任务类型查阅对应参考文档：

| 模块 | 文档 | 适用场景 |
|------|------|----------|
| 目录结构 | references/golang-directory-structure.md | 创建新项目、规划目录 |
| 配置管理 | references/golang-config-management.md | 配置加载、多环境支持 |
| 服务架构 | references/golang-service-architecture.md | 入口设计、服务生命周期 |
| API 设计 | references/golang-api-design.md | HTTP/gRPC、protobuf、中间件 |
| 构建部署 | references/golang-build-and-deploy.md | Makefile、Dockerfile、CI/CD |

## 常见错误

| 错误 | 正确做法 |
|------|----------|
| cmd 包含业务逻辑 | cmd 只做初始化和调用 |
| internal 被外部引用 | internal 是私有边界 |
| API 不版本化 | 使用 api/v1、api/v2 |
| 配置硬编码 | 使用 Viper + 多环境文件 |
| 全局变量传依赖 | Context + FromContext/NewContext |
| 服务串行启动 | errgroup 并发管理 |
| 缺少部署目录 | deployments/ 包含 Docker/K8s |
| Makefile 缺少目标 | 添加 build、test、generate、docker |
| Dockerfile 单阶段 | 多阶段构建，非 root 用户 |
| README 内容缺失 | 包含简介、快速开始、目录结构 |

## 检查清单

### 目录结构

- [ ] `cmd/` 只有 main.go 和 commands/
- [ ] `internal/` 包含所有业务代码
- [ ] `pkg/` 只有可复用公共代码
- [ ] `api/` 使用版本化目录
- [ ] `configs/` 按环境分离
- [ ] `deployments/` 有部署配置
- [ ] `docs/` 有项目文档

### 配置管理

- [ ] 结构化配置定义
- [ ] 提供默认值
- [ ] 支持多环境
- [ ] 配置路径可自定义

### 服务架构

- [ ] Cobra 命令行框架
- [ ] ServeLifecycle 接口
- [ ] errgroup 并发管理
- [ ] 优雅关闭（signal.Notify）

### API 设计

- [ ] gRPC + HTTP 双协议
- [ ] API 版本化
- [ ] 中间件注册表
- [ ] 统一错误处理

### 构建部署

- [ ] Makefile（build、test、generate、docker）
- [ ] Dockerfile 多阶段构建
- [ ] Docker Compose 环境配置
- [ ] README 项目文档
- [ ] CI/CD 流程配置