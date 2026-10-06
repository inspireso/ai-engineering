# Changelog

## 1.2.15 (2026-10-06)

### 新增

- `java-best-practices` skill 完善包结构规范：补充 web/api 层与各层职责、事务边界（@Transactional 仅 service 层显式声明、跨多个 service 用 XxxManager）、领域模型约定（枚举内嵌、模型按需定义）、调度任务（service/task 包）、模块入口（XxxConfiguration 装配类并注册到 AutoConfiguration.imports）
- `java-best-practices` skill 新增「RESTful 接口规约」章节：注解使用（方法级完整路径）、URL/参数 snake_case 与响应字段 lowerCamelCase、模块前缀与 /public/ 标志、标准 HTTP 状态码、错误消息结构与分页返回结构
- `java-best-practices` skill 新增「Redis 规约」章节：key 统一小写字母+下划线分隔、模块前缀冒号分层

### 变更

- `using-inspire-framework` skill 更新：同步 CBC 显式 IV 与定时任务租约、修正示例中重复变量名、补充定时任务租约细节与 @Scheduled 手动调用警示、同步最新代码与契约说明

## 1.2.14 (2026-10-05)

### 新增

- `java-best-practices` skill 新增「包结构与分层」章节：依赖方向单向（下层依赖上层、只能向上依赖、禁止反向与循环依赖），Spring Boot 按 config、domain、repository、service、xxxConfiguration 组织模块；最小可见性（不需要 public 不加 public、优先内部类、定义位置靠近使用位置）
- `java-best-practices` 新增事件驱动规范：优先使用事件驱动模式解耦，`XxxEvents` 定义在 service/event、在 service 中发布、在 service/event/listener 中监听

## 1.2.13 (2026-09-07)

### 新增

- `git-push` skill 新增「合并相同类型的提交（squash）」步骤：推送前将待推送中连续且 type/scope 相同的提交合并为一个，提交信息综合原内容并保持 Conventional Commits 规范；仅处理未推送的本地 commits，不改写已推送历史、不重排提交顺序，合并后核实总 diff 一致

## 1.2.12 (2026-08-20)

### 变更

- `java-best-practices` skill 补充编码规范章节：新增命名规范（类/方法/变量/常量/布尔）、异常处理（捕获/转换/日志）、日期时间（java.time 取代 Date/Calendar）三个章节
- 优化 `java-best-practices` description 触发词，去除冗余表述；修复 Optional 示例类型错误

## 1.2.11 (2026-08-20)

### 新增

- 新增 `java-best-practices` skill：约束 Java 工具类使用优先级（JDK 标准库 → Guava → Spring Framework），独立于 Inspireso Framework，任何 Java 项目均可触发；含分层参考、决策表、Red Flags 完整约束

### 变更

- `using-inspire-framework` 的 `tools-reference.md` 精简为纯 Inspireso 框架工具参考，通用 Java 层移至 `java-best-practices` skill
- `using-inspire-framework` SKILL.md 添加交叉引用指向 `java-best-practices`

## 1.2.10 (2026-08-14)

### 变更

- `using-inspire-framework` skill 中文化：SKILL.md 全文翻译为中文（description 同步），与项目全局中文规范对齐
- `tools-reference.md` 补充常用工具参考：GZips（GZIP 压缩/解压）、StringMaps（Map 与查询字符串转换）、Tokens（登录身份信息提取），及 Serializing 的 XML/字节序列化用法；工具决策表与选择原则同步更新
- 修复 README 目录结构过期引用：VERSION 已废弃，标注 `.claude-plugin/plugin.json` 为唯一版本号来源

## 1.2.9 (2026-07-11)

### 新增

- 新增 `init-java-project` skill：参考企业 Java 工程模板生成 Maven 多模块骨架（conf/sdk/srvhost/业务模块 + docs/），初始化 AGENTS.md 约束（TDD、Conventional Commits、技术栈说明）与可选 constitution.md；经实际编译验证（4 模块 + sdk 独立编译全部 SUCCESS）
- `init-java-project` 补全模块包结构：AutoConfiguration.imports 自动装配机制（conf/sdk/业务模块）、service/exceptions（异常类 + Errors 错误码）、service/event + listener（KeyResolver 事件 + AbstractListener 监听器）、web/api（Controller）、docs/ 四份核心文档骨架

## 1.2.8 (2026-07-11)

### 新增

- 新增 `sync-docs` skill：合并 neat-freak 全部能力（尺寸体检、记忆毕业、变更影响矩阵、跨项目对齐）的知识库洁癖级同步——支持 55 个自然语言触发词，按应用层/插件工程两类项目提供变更模式速览
- 新增 `git-push` skill：简化版 release——合并远程分支到本地、代码审查、用户确认后推送，含推送前必须确认、不使用 force 等安全护栏
- 新增 Stop hook：会话结束时检测 git 变更，提醒同步文档（同会话只提醒一次）

## 1.2.7 (2026-06-27)

### 新增

- 新增 `database-design-best-practices` skill：提炼自飞书文档，泛化至 MySQL/PostgreSQL/Oracle 的数据库设计规范——涵盖字符集配置、建表规约、索引设计、SQL 编写、ORM 映射、Red Flags 合理化借口对照表及检查清单。经 4 轮 subagent 跨数据库测试（建表设计、SQL 编写、DDL 审查、压力场景）验证

## 1.2.6 (2026-06-27)

### 变更

- 完善 `release` 命令发布流程：经 4 轮独立 review 迭代，补全测试构建环节、失败中止/回滚策略、分支角色声明、tag 预检/复核、推送原子性等安全护栏，支持 main 分支直接发版
- `release` 命令合并冲突改为尝试解决而非直接终止
- `release` 命令精简为意图级约束——各步骤描述目标与约束，大模型已有的通用知识不强制指定
- 补充 `tools-reference` 加密 API 参考文档（对称/非对称/国密算法详解及场景推荐）

## 1.2.5 (2026-06-23)

### 变更

- 泛化 `release` 命令的版本号规则，按项目类型（Maven / npm / Claude plugin）分类执行版本号变更
- 废弃冗余的 `VERSION` 文件，Claude plugin 以 `.claude-plugin/plugin.json` 的 `version` 字段为唯一版本源
- 将 `git-commit` skill 文案中文化，统一项目文档风格

## 1.2.4 (2026-06-22)

### 新增

- 添加 `git-commit` skill：基于 Conventional Commits 规范的 git 提交技能（自动分析 diff、智能暂存、生成规范提交信息）

## 1.2.3 (2026-06-22)

### 变更

- 增强 `release` 命令发布流程：
  - 新增执行 `/simplify` 简化代码步骤
  - 新增 Java Maven 项目版本号检测与建议规则（SNAPSHOT 去后缀发版 / release 版 patch+1）
  - 版本号变更单独提交
  - `target` 参数改为 `branch`（指定合并源分支，默认自动检测 main/master）
  - 添加 `argument-hint` 参数提示
- 为 `review`、`qa` 命令添加 `argument-hint` 参数提示

## 1.2.2 (2026-05-27)

### 变更

- 优化 `golang-project-best-practices` skill 安全性：
  - 将内部 IP 地址替换为 localhost
  - 将硬编码密码改为环境变量注入方式
  - 将项目名称通用化（myapp → app，myproject → example/project）

## 1.2.1 (2026-05-10)

### 新增

- 添加 `golang-project-best-practices` skill：Go 项目最佳实践指南
  - 目录结构详解（cmd/internal/pkg/api 目录规划）
  - 配置管理详解（Viper + Protobuf 配置方案）
  - 服务架构详解（Cobra + errgroup 服务生命周期）
  - API 设计详解（gRPC + HTTP 双协议、protobuf 定义）
  - 构建部署详解（Makefile、Dockerfile、CI/CD 配置）

- 添加 `using-inspire-framework` skill 参考文档：
  - `tools-reference.md`：工具使用优先级参考（JDK → Guava → Spring → Inspireso）

### 变更

- 项目目录调整：从 `docs/ai/ai-engineering/` 移动到 `ai-engineering/`
- 修复 `.claude/settings.local.json` JSON 格式错误（数组末尾多余逗号）

## 1.2.0 (2026-05-08)

### 新增

- 添加 `using-inspire-framework` skill：Inspireso Framework 开发指南
  - 实体设计（AbstractObject/AuditableObject、继承策略）
  - 服务层（BaseService、事务、缓存）
  - 动态查询（AbstractCriteria、@FilterPart）
  - 事件系统（KeyResolver、AbstractListener）
  - 参考文档和测试结果

## 1.1.1 (2026-05-07)

### 变更

- 更新 `settings.json` 权限配置：添加 `./mvnw`、`git commit`、`curl` 到 allow 列表
- 精简 ask 列表：仅保留敏感文件读取、删除命令、git push

## 1.1.0 (2026-05-05)

### 新增

- 添加 `tdd-feature` skill：TDD 功能实现（RED→GREEN→REFACTOR 三阶段工作流）

### 变更

- 简化 `README.md` 安装说明：突出 marketplace 安装方式，移除冗余备选方案
- 更新版本号至 1.1.0
- 更新 `.gitignore` 添加 `.DS_Store` 忽略规则

## 1.0.0 (2026-04-26)

### 新增

- 添加 `.claude-plugin/plugin.json` 插件清单文件
- 添加 `settings.json` 项目权限和安全护栏配置
- 添加 `hooks/hooks.json` 插件 hooks 配置（PreToolUse/PostToolUse/UserPromptSubmit）
- 添加 `commands/` 目录（qa、review、release 命令）
- 添加 `skills/` 目录（doc-gen、refactor-analysis、review-fix-pipeline 技能）
- 添加 `hooks/` 目录（pre-tool-use、post-tool-use、user-prompt-submit 脚本）

### 变更

- 重构目录结构：`shared/` → `commands/`、`hooks/`、`skills/` 顶层目录
- 修复 `hooks.json` 结构：添加顶层 `hooks` 包装对象
- 修复 `plugin.json`：移除冗余的 `hooks` 引用（标准位置自动加载）
- 更新 `install.sh` 和 `upgrade.sh` 适配新目录结构
- 更新 `README.md` 文档
- 更新 `release.md` 命令：添加 git 提交步骤
