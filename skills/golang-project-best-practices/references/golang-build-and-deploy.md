# 构建与部署详解

## Makefile 配置

### 完整示例

```makefile
SHELL       = /usr/bin/env bash
GOPROXY     = https://goproxy.cn,direct
BINDIR      := $(CURDIR)/bin
BINNAME     ?= myapp
BINARY_NAME ?= ${BINDIR}/${BINNAME}
BUILD_USER  ?= $(shell whoami)
BUILD_DATE  ?= $(shell date +"%Y-%m-%d %H:%M:%S")
OS          ?= $(shell go env GOHOSTOS)
ARCH        ?= $(shell go env GOHOSTARCH)
GOVERSION   ?= $(shell go version | awk '{print $3}')
GIT_BRANCH  ?= $(shell git symbolic-ref --short -q HEAD)
GIT_COMMIT  ?= $(shell git rev-parse HEAD)
GIT_SHA     ?= $(shell git rev-parse --short HEAD)
GIT_TAG     ?= $(shell git describe --tags --abbrev=0 --exact-match 2>/dev/null)

# Go options
PKG         := ./...
TAGS        :=
TESTS       := .
TESTFLAGS   :=
LDFLAGS     := -w -s
GOFLAGS     :=

ifdef VERSION
    BINARY_VERSION = $(VERSION)
endif
BINARY_VERSION ?= ${GIT_TAG}
BINARY_VERSION ?= ${GIT_BRANCH}

ifneq ($(BINARY_VERSION),)
    LDFLAGS += -X main.Version=${BINARY_VERSION}
endif

LDFLAGS += -X "main.Branch=${GIT_BRANCH}"
LDFLAGS += -X "main.Revision=${GIT_COMMIT}"
LDFLAGS += -X "main.GoVersion=${GOVERSION}"
LDFLAGS += -X "main.BuildUser=${BUILD_USER}"
LDFLAGS += -X "main.BuildDate=${BUILD_DATE}"

.PHONY: all
all: test build

.PHONY: build
build:
    @echo "==> Building ${BINNAME}..."
    GO111MODULE=on go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o '$(BINARY_NAME)-$(OS)-$(ARCH)' './cmd'

.PHONY: test
test:
    @echo "==> Running tests..."
    go test -v $(TESTFLAGS) $(PKG)

.PHONY: lint
lint:
    @echo "==> Running linters..."
    golangci-lint run

.PHONY: clean
clean:
    @go clean
    rm -rf $(BINDIR)

.PHONY: build-cross
build-cross: build-linux build-windows

.PHONY: build-linux
build-linux:
    @echo "==> Building for Linux..."
    CGO_ENABLED=1 GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o "$(BINARY_NAME)-linux-amd64" "./cmd"

.PHONY: build-windows
build-windows:
    @echo "==> Building for Windows..."
    CGO_ENABLED=1 GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -ldflags '$(LDFLAGS)' -o "$(BINARY_NAME)-windows-amd64.exe" "./cmd"

.PHONY: devtools
devtools:
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
    go install github.com/google/gnostic/cmd/protoc-gen-openapi@latest

.PHONY: generate
generate:
    protoc --proto_path=. --proto_path=./third_party \
           --go_out=. --go-grpc_out=./api/v1/ \
           ./api/v1/*.proto

.PHONY: swagger
swagger:
    protoc --proto_path=. --proto_path=./third_party \
           --openapi_out=naming=proto,fq_schema_naming=true:./api/ \
           ./api/v1/*.proto

.PHONY: docker
docker:
    docker build --rm -t myapp:latest .

.PHONY: docker-push
docker-push:
    docker tag myapp:latest ${REGISTRY}/myapp:latest
    docker push ${REGISTRY}/myapp:latest
```

### 常用目标说明

| 目标 | 说明 |
|------|------|
| `make all` | 测试 + 构建 |
| `make build` | 构建当前平台可执行文件 |
| `make test` | 运行测试 |
| `make lint` | 代码检查 |
| `make clean` | 清理构建产物 |
| `make build-cross` | 跨平台构建（Linux + Windows） |
| `make generate` | 生成 protobuf 代码 |
| `make swagger` | 生成 OpenAPI 文档 |
| `make docker` | 构建 Docker 镜像 |

### 版本信息注入

```go
// cmd/commands/version.go
package commands

var (
    Version   = "unknown"
    Branch    = "unknown"
    Revision  = "unknown"
    GoVersion = "unknown"
    BuildUser = "unknown"
    BuildDate = "unknown"
)

func VersionCmd() *cobra.Command {
    return &cobra.Command{
        Use:   "version",
        Short: "Print version information",
        Run: func(cmd *cobra.Command, args []string) {
            fmt.Printf("Version:    %s\n", Version)
            fmt.Printf("Branch:     %s\n", Branch)
            fmt.Printf("Revision:   %s\n", Revision)
            fmt.Printf("GoVersion:  %s\n", GoVersion)
            fmt.Printf("BuildUser:  %s\n", BuildUser)
            fmt.Printf("BuildDate:  %s\n", BuildDate)
        },
    }
}
```

## Dockerfile 编写

### 多阶段构建

```dockerfile
# Build stage
FROM golang:1.22 AS builder

ENV GOPROXY="https://goproxy.cn,direct"
ENV CGO_ENABLED=1

WORKDIR /src
ADD . /src

RUN make build

# Deploy stage
FROM debian:bookworm-slim

# 安装运行依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建非 root 用户
RUN groupadd -g 1001 app && \
    useradd -u 1001 -g app --no-create-home app

# 复制构建产物
COPY --from=builder /src/bin/myapp-* /opt/myapp/myapp
COPY --from=builder /src/configs/* /opt/myapp/config/

# 设置权限
RUN chown -R app:app /opt/myapp

WORKDIR /opt/myapp
USER app

EXPOSE 8080 8081 9191

HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["/opt/myapp/myapp"]
```

### 最佳实践

| 实践 | 说明 |
|------|------|
| 多阶段构建 | builder 阶段编译，deploy 阶段只包含运行文件 |
| 非 root 用户 | 安全性，避免容器逃逸 |
| 精简基础镜像 | debian:bookworm-slim 或 alpine |
| HEALTHCHECK | 容器健康检查 |
| 单层 COPY | 减少镜像层数 |

### Alpine 版本（更小）

```dockerfile
FROM golang:1.22-alpine AS builder

ENV GOPROXY="https://goproxy.cn,direct"
ENV CGO_ENABLED=0

RUN apk add --no-cache git make

WORKDIR /src
ADD . /src
RUN make build

FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -g 1001 app && \
    adduser -u 1001 -G app -D app

COPY --from=builder /src/bin/myapp-* /opt/myapp/myapp
COPY --from=builder /src/configs/* /opt/myapp/config/

RUN chown -R app:app /opt/myapp

WORKDIR /opt/myapp
USER app

EXPOSE 8080 8081 9191

CMD ["/opt/myapp/myapp"]
```

## Docker Compose 配置

### 开发环境

```yaml
# deployments/docker-compose-dev.yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
      - "8081:8081"
      - "9191:9191"
    volumes:
      - ./configs:/opt/myapp/config
    environment:
      - APP_ENV=dev
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.0
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root123
      MYSQL_DATABASE: myapp
      MYSQL_USER: myapp
      MYSQL_PASSWORD: myapp123
    volumes:
      - mysql_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  mysql_data:
  redis_data:
```

### 生产环境

```yaml
# deployments/docker-compose-prod.yaml
version: "3.8"

services:
  app:
    image: ${REGISTRY}/myapp:${VERSION}
    ports:
      - "8080:8080"
      - "8081:8081"
      - "9191:9191"
    environment:
      - APP_ENV=prod
      - MYSQL_ADDR=${MYSQL_ADDR}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - REDIS_ADDR=${REDIS_ADDR}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2'
          memory: 512M
        reservations:
          cpus: '1'
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: always
```

## README 模板

```markdown
# MyApp

## 简介

基于 gRPC 实现的服务端应用，提供 xxx 功能。

### 架构图

![architecture](./docs/assets/architecture.png)

## 功能

- **核心功能**
  - [x] 功能 A
  - [x] 功能 B
  - [ ] 功能 C（计划中）

## 快速开始

### 本地运行

\`\`\`shell
go mod tidy
go run cmd/main.go
\`\`\`

### Docker 运行

\`\`\`shell
docker compose -f deployments/docker-compose-dev.yaml up -d
\`\`\`

## 编译

\`\`\`shell
# 当前平台
make build

# 跨平台
make build-cross
\`\`\`

## 目录结构

\`\`\`
.
├── cmd/                    # 入口点
├── internal/               # 内部业务逻辑
├── pkg/                    # 公共工具库
├── api/v1/                 # API 定义
├── configs/                # 配置文件
├── deployments/            # 部署配置
├── third_party/            # 外部依赖
└── docs/                   # 项目文档
\`\`\`

## API 文档

### gRPC 接口

详见 [api/v1/platform.proto](./api/v1/platform.proto)

### HTTP 接口

Swagger 文档：`/api/v1/openapi.yaml`

## 配置说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| server.http.addr | HTTP 地址 | :8080 |
| server.grpc.addr | gRPC 地址 | :8081 |
| mysql.addr | MySQL 地址 | localhost:3306 |
| redis.addr | Redis 地址 | localhost:6379 |

## 规范

- [提交规范](docs/commit_message.md)
- [分支规范](docs/git_flow.md)

## 许可证

MIT License。详见 [LICENSE](./LICENSE)。
```

## CI/CD 配置

### GitLab CI

```yaml
# .gitlab-ci.yml
image: docker:latest

variables:
  CI_REGISTRY_IMAGE: "$CI_REGISTRY/myapp:${CI_COMMIT_SHA}"

stages:
  - lint
  - test
  - build
  - deploy

lint:
  stage: lint
  image: golangci/golangci-lint:latest
  script:
    - golangci-lint run

test:
  stage: test
  image: golang:1.22
  script:
    - go test -v ./...

build:
  stage: build
  script:
    - docker build --rm -t "$CI_REGISTRY_IMAGE" .
    - docker push "$CI_REGISTRY_IMAGE"

deploy:test:
  stage: deploy
  script:
    - envsubst < deployments/docker-compose-test.yaml > /tmp/docker-compose.yaml
    - scp /tmp/docker-compose.yaml $DEPLOY_DESTINATION:$DEPLOY_PATH/docker-compose.yaml
    - ssh $DEPLOY_DESTINATION "cd $DEPLOY_PATH && docker compose up -d"
  when: manual
  only:
    - /^v\d+\..*$/

deploy:prod:
  stage: deploy
  script:
    - envsubst < deployments/docker-compose-prod.yaml > /tmp/docker-compose.yaml
    - scp /tmp/docker-compose.yaml $DEPLOY_DESTINATION:$DEPLOY_PATH/docker-compose.yaml
    - ssh $DEPLOY_DESTINATION "cd $DEPLOY_PATH && docker compose up -d"
  when: manual
  only:
    - /^v\d+\..*$/
```

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: golangci/golangci-lint-action@v3

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - run: go test -v ./...

  build:
    runs-on: ubuntu-latest
    needs: [lint, test]
    steps:
      - uses: actions/checkout@v4
      - run: make build

  docker:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ secrets.REGISTRY }}
          username: ${{ secrets.REGISTRY_USER }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ secrets.REGISTRY }}/myapp:latest
```

## 检查清单

### Makefile

- [ ] build 目标（当前平台）
- [ ] test 目标
- [ ] lint 目标
- [ ] generate 目标（protobuf）
- [ ] build-cross 目标（可选）
- [ ] docker 目标
- [ ] 版本信息注入

### Dockerfile

- [ ] 多阶段构建
- [ ] 非 root 用户
- [ ] 精简基础镜像
- [ ] HEALTHCHECK
- [ ] 暴露端口声明

### Docker Compose

- [ ] 开发环境配置
- [ ] 生产环境配置
- [ ] 依赖服务（MySQL、Redis）
- [ ] 健康检查

### README

- [ ] 项目简介
- [ ] 快速开始指南
- [ ] 目录结构说明
- [ ] API 文档引用
- [ ] 配置说明表格
- [ ] 许可证声明

### CI/CD

- [ ] lint 阶段
- [ ] test 阶段
- [ ] build 阶段
- [ ] deploy 阶段（手动触发）
- [ ] 版本发布规则