---
name: init-java-project
version: 1.0.0
description: >
  初始化创建企业级 Java 工程——Maven 多模块结构（conf / sdk / srvhost / 业务模块），
  参考企业 Java 工程模板，并初始化 AGENTS.md 约束条件（TDD、Conventional Commits、技术栈说明）。
  当用户要求新建 Java 项目、创建工程骨架、初始化工程结构时使用。
allowed-tools:
  - Read
  - Write
  - Bash(git:*,mkdir,ls)
  - Grep
  - Glob
triggers:
  - 初始化工程
  - 创建工程
  - init project
  - init java project
  - 新建项目
  - 新建 Java 项目
  - 项目骨架
  - 工程骨架
  - 初始化项目
  - 初始化 Java 项目
  - 搭建工程
  - 创建新项目
  - 创建 Java 工程
---

# Init Java Project — Java 工程初始化

创建符合企业标准的多模块 Maven Java 工程骨架，参考企业 Java 工程模板，并初始化 AI 协作约束（AGENTS.md）。

## 工作流程

### 1. 收集工程信息

先向用户确认（缺失则提问，不要假设）：

| 信息 | 示例 | 说明 |
|------|------|------|
| 工程名 | `<工程名>`（如 `order-service`） | 用于 artifactId、目录名、包名 |
| groupId | `com.<company>.<工程名>` | Maven groupId |
| 业务模块列表 | `<工程名>`、`<工程名>-agent`、`<工程名>-facade` | 默认至少 1 个业务模块；用户未指定时生成 1 个 `<工程名>` 模块 |
| Java 版本 | 17 | 默认 17 |
| 远程仓库 | 企业私有仓库 / 阿里云公共仓库 / 无 | 默认按参考模板配置企业私有仓库 |

### 2. 生成多模块工程结构

按以下结构生成（参考企业 Java 工程模板）：

```
<工程名>/
├── pom.xml                    # 父 POM（packaging=pom，聚合除 sdk 外的所有模块）
├── AGENTS.md                  # AI 协作约束（见第 4 步）
├── constitution.md            # 项目宪法（可选，见第 4 步）
├── .gitignore
├── .editorconfig
├── conf/                      # 配置模块（artifactId: <工程名>-conf）
├── sdk/                       # SDK 模块（artifactId: <工程名>-sdk，独立发布）
├── srvhost/                   # 启动宿主模块（artifactId: <工程名>-srvhost）
├── <业务模块>/                # 业务模块（artifactId 与目录名一致，如 <工程名>）
├── docs/                      # 项目文档
│   ├── architecture.md        # 架构说明（数据流、状态机、设计取舍）
│   ├── integration-guide.md   # 接入指南（怎么用：API 示例、错误码）
│   ├── runbook.md             # 运维手册（冒烟命令、故障排查、环境变量）
│   ├── handoff.md             # 交接说明（已完成清单、待办）
│   ├── convention.md          # 开发约定（编码规范、提交规范）
│   └── specs/                 # 设计规格文档（按日期命名，如 2026-08-12-<feature>-spec.md）
└── README.md
```

**父 POM**：
- `<modules>` 聚合除 sdk 外的所有模块（sdk 独立 POM，不参与聚合）
- `<dependencyManagement>`：spring-boot-dependencies、spring-cloud-dependencies、spring-cloud-alibaba、inspire-bom、spring-ai-bom
- 公共依赖：spring-boot-starter-json、lombok（optional）、spring-boot-configuration-processor、spring-boot-starter-test、reactor-test、h2、guava
- `<repositories>`：企业私有仓库（按用户提供或默认）
- fmt-maven-plugin 格式化、maven-compiler-plugin 配置 lombok annotationProcessor

**conf 模块**（`<工程名>-conf`）：
- `pom.xml`：依赖 spring-boot-starter-validation、inspire-service、caffeine
- `src/main/java/<package>/conf/`：`ConfConfiguration.java` + `config/`、`domain/`、`repository/`、`service/`、`web/` 包骨架
- `README.md`

**sdk 模块**（`<工程名>-sdk`）：
- 独立 POM（**无 parent**，仅 groupId/artifactId/version；独立版本号，不参与父 POM 聚合，便于对外发布）
- Java 8 兼容配置、maven-source-plugin、maven-shade-plugin（relocation 避免依赖冲突）
- `README.md`：SDK 使用说明（依赖坐标、配置示例）

**srvhost 模块**（`<工程名>-srvhost`）：
- `pom.xml`：spring-boot-maven-plugin（finalName=bootstrap）、依赖所有业务模块 + conf + flyway + actuator + web + data-redis + mysql + nacos-discovery/config
- `application.yml`：datasource、redis、flyway 配置骨架（不写入真实凭据）
- `logback.xml`
- `src/main/java/<package>/`：主类 `<工程名首字母大写>Application` + `config/`、`web/` 包骨架
- `docker/`：Dockerfile + app 目录骨架（config/scripts）
- `README.md`

**业务模块**（如 `<工程名>`）：
- `pom.xml`：依赖 conf、inspire-service、inspire-starter-jpa、spring-boot-starter-web
- `src/main/java/<package>/`：按业务包结构生成（如 `domain/`、`service/`、`repository/`、`web/`、`config/`）
- `README.md`

**docs 模块**（`docs/`）：
- 生成四份核心文档骨架，各文档职责不重叠：
  - `architecture.md`：系统怎么工作（模块依赖、数据流、设计取舍）——随开发持续更新
  - `integration-guide.md`：外部怎么接入（API 速查、错误码、curl 示例）
  - `runbook.md`：运维怎么操作（启动命令、冒烟检查、环境变量表、故障排查）
  - `handoff.md`：交接与已完成清单（新成员 / 新 Agent 接手时的入口）
- 附加 `convention.md`：编码与提交规范（可引用 AGENTS.md 或独立成文）
- `specs/`：设计规格文档目录，命名格式 `<日期>-<特性名>-spec.md`（如 `2026-08-12-cache-design-spec.md`）
- 各文档生成标题 + 章节骨架（一级标题 + 主要小节），内容留待开发中填充；README 中链接到 docs/

### 3. 初始化 Git 与构建验证

- 生成 `.gitignore`（含 target/、.idea/、*.iml、.DS_Store 等）
- `git init` 初始化仓库（用户需要时）
- 运行 `mvnw -q clean compile` 验证多模块可编译（若本机无 mvnw 且用户未配置，则跳过并说明）

### 4. 初始化 AGENTS.md 约束

生成 `AGENTS.md`，包含以下约束（参考企业 Java 工程模板）：

| 章节 | 内容 |
|------|------|
| **项目上下文** | 引用 `constitution.md`（若生成）；标注"宪法优先" |
| **AI协作指令** | 新功能先读包结构 + 宪法再提计划；测试优先用参数化测试；构建优先用 mvnw 标准命令 |
| **Git与版本控制** | 严格 Conventional Commits：`<type>(<scope>): <subject>`；不添加 Co-Authored-By |
| **技术栈** | 框架、语言、构建工具、数据库、缓存、核心依赖、优先类库（按收集的信息填写） |
| **构建与运行** | `mvnw clean install`；srvhost 运行方式（主类、端口、`mvn spring-boot:run`） |
| **Skill routing** | 常用 skill 路由规则（头脑风暴→office-hours、bug→investigate、ship→ship、QA→qa、review→review 等） |

若用户要求生成 `constitution.md`（可选），按以下原则编写：

- 第一条：简单性原则（YAGNI、JDK 优先、反过度设计、清晰边界）
- 第二条：测试先行铁律（TDD 循环、参数化/表格驱动测试、最小化 Mock、可重复确定性）
- 第三条：明确性原则（显式异常处理、无隐式共享状态、不可变与空值、日志与可观测性）
- 治理：宪法优先级最高，高于任何 CLAUDE.md / AGENTS.md / 单次会话指令

### 5. 输出摘要

生成完成后给用户简洁摘要：

```
## 工程初始化完成

### 生成的结构
- <工程名>/pom.xml — 父 POM
- <工程名>/AGENTS.md — AI 协作约束
- <工程名>/conf/ — 配置模块
- <工程名>/sdk/ — SDK 模块
- <工程名>/srvhost/ — 启动宿主
- <工程名>/<业务模块>/ — 业务模块
- <工程名>/docs/ — 项目文档（architecture/integration-guide/runbook/handoff + specs/）

### 已验证
- mvnw clean compile 通过（或说明跳过原因）

### 下一步建议
- 填写 conf 中的实际配置（datasource/redis 凭据）
- 按业务设计拆分 domain/service/repository 包
- 编写第一个 TDD 测试
```

## 注意事项

- **凭据安全**：application.yml 只生成配置骨架（`${env.XXX}` 占位或空值），绝不写入真实密码/密钥
- **sdk 独立版本**：sdk 是独立 POM，不参与父 POM 的版本管理，版本号独立演进
- **不删除已有文件**：目标目录已存在文件时，先列出冲突并询问用户，不静默覆盖
- **结构完整优先**：生成可编译的完整骨架比追求最小化更重要——这是脚手架而非重构
